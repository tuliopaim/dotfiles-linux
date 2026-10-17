#!/usr/bin/env python3
"""Query Portfolio on demand. Production is the default; --database selects a local file."""

import argparse
from contextlib import contextmanager
from datetime import datetime, timezone
import json
from pathlib import Path
import sqlite3
import subprocess
import sys
import tempfile
import time


MAX_SQL_BYTES = 32_768
MAX_OUTPUT_BYTES = 200_000
MAX_VALUE_BYTES = 1_000_000

# SQLite's backup API includes committed WAL data and produces a consistent copy.
# Only this temporary backup is written; the application's database is read-only.
BACKUP_JS = """
import { DatabaseSync, backup } from 'node:sqlite';
import { mkdtempSync, readFileSync, rmSync, statSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
const directory = mkdtempSync(join(tmpdir(), 'portfolio-skill-'));
let db;
try {
    db = new DatabaseSync('/app/data/portfolio-tracker.db', { readOnly: true });
    const destination = join(directory, 'snapshot.db');
    await backup(db, destination);
    if (statSync(destination).size > 64 * 1024 * 1024)
        throw new Error('Database exceeds the 64 MiB snapshot limit');
    process.stdout.write(readFileSync(destination));
} finally {
    if (db) db.close();
    rmSync(directory, { recursive: true, force: true });
}
"""


@contextmanager
def database_file(local_path):
    if local_path:
        path = Path(local_path).expanduser().resolve(strict=True)
        yield path, {"kind": "local", "database": str(path)}
        return

    command = [
        "kubectl", "--request-timeout=10s", "exec", "--namespace=default",
        "deployment/portfolio-tracker", "--container=portfolio-tracker", "--",
        "node", "--no-warnings", "--input-type=module", "-e", BACKUP_JS,
    ]
    try:
        result = subprocess.run(command, capture_output=True, timeout=30, check=False)
    except FileNotFoundError as error:
        raise ValueError("Production access requires kubectl on homelab; run this helper over SSH, or use --database PATH") from error
    except subprocess.TimeoutExpired as error:
        raise ValueError("Production snapshot timed out after 30 seconds") from error
    if result.returncode:
        raise ValueError("Production snapshot failed: " + result.stderr.decode(errors="replace").strip()[:2000])
    if not result.stdout.startswith(b"SQLite format 3\x00"):
        raise ValueError("Production snapshot did not return a SQLite database")
    with tempfile.TemporaryDirectory(prefix="portfolio-skill-") as directory:
        path = Path(directory) / "snapshot.db"
        path.write_bytes(result.stdout)
        yield path, {
            "kind": "production", "namespace": "default",
            "deployment": "portfolio-tracker", "database": "/app/data/portfolio-tracker.db",
        }


def authorize(action, first, second, database, trigger):
    if action in (sqlite3.SQLITE_SELECT, sqlite3.SQLITE_RECURSIVE):
        return sqlite3.SQLITE_OK
    # SQLite can omit the database name for optimized reads such as COUNT(*).
    # ATTACH and creation of temporary objects remain denied separately.
    if action == sqlite3.SQLITE_READ and database in (None, "main"):
        return sqlite3.SQLITE_OK
    if action == sqlite3.SQLITE_FUNCTION and (second or "").lower() not in {
        "load_extension", "readfile", "writefile", "edit", "fts3_tokenizer",
    }:
        return sqlite3.SQLITE_OK
    return sqlite3.SQLITE_DENY


def query(path, sql, params, limit=200, timeout=5):
    """Execute one statement; authorizer denies writes, ATTACH, and PRAGMA."""
    if not sql.strip():
        raise ValueError("Provide a SQL statement as an argument or on stdin")
    if len(sql.encode("utf-8")) > MAX_SQL_BYTES:
        raise ValueError("SQL exceeds the 32 KiB limit")
    if not 1 <= limit <= 1000:
        raise ValueError("Row limit must be between 1 and 1000")
    if not 0 < timeout <= 30:
        raise ValueError("Query timeout must be greater than 0 and at most 30 seconds")
    if not isinstance(params, (list, dict)):
        raise ValueError("Parameters must be a JSON object or array")

    deadline = time.monotonic() + timeout
    connection = sqlite3.connect(path.as_uri() + "?mode=ro", uri=True, timeout=timeout)
    try:
        connection.execute("PRAGMA query_only = ON")
        connection.execute("PRAGMA trusted_schema = OFF")
        connection.setlimit(sqlite3.SQLITE_LIMIT_LENGTH, MAX_VALUE_BYTES)
        connection.setlimit(sqlite3.SQLITE_LIMIT_SQL_LENGTH, MAX_SQL_BYTES)
        connection.setlimit(sqlite3.SQLITE_LIMIT_COLUMN, 100)
        connection.set_authorizer(authorize)
        connection.set_progress_handler(lambda: time.monotonic() >= deadline, 1000)
        cursor = connection.execute(sql, params)
        if cursor.description is None:
            raise ValueError("Only queries returning rows are supported")
        columns = [column[0] for column in cursor.description]
        rows = []
        size = len(json.dumps(columns).encode("utf-8"))
        truncated = False
        for row in cursor:
            if len(rows) == limit:
                truncated = True
                break
            encoded = json.dumps(row, ensure_ascii=False, allow_nan=False)
            size += len(encoded.encode("utf-8"))
            if size > MAX_OUTPUT_BYTES:
                raise ValueError("Result exceeds 200 KB; select fewer columns or rows")
            rows.append(list(row))
        return {"columns": columns, "rows": rows, "row_count": len(rows), "truncated": truncated}
    except sqlite3.OperationalError as error:
        if time.monotonic() >= deadline:
            raise ValueError("Query timed out; narrow the query") from error
        raise
    finally:
        connection.close()


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--database", metavar="PATH", help="Read a local SQLite file instead of production")
    commands = parser.add_subparsers(dest="command", required=True)
    schema = commands.add_parser("schema", help="Show current CREATE statements, optionally for selected tables")
    schema.add_argument("tables", nargs="*")
    statement = commands.add_parser("query", help="Run one read-only statement, from argument or stdin")
    statement.add_argument("sql", nargs="?")
    statement.add_argument("--params", default="{}", help="Bound parameters as a JSON object or array")
    statement.add_argument("--limit", type=int, default=200, help="Maximum returned rows, 1–1000 (default 200)")
    statement.add_argument("--timeout", type=float, default=5, help="Query execution timeout, at most 30 seconds")
    args = parser.parse_args()

    try:
        if args.command == "schema":
            sql = "SELECT name, type, sql FROM sqlite_schema WHERE type IN ('table', 'view') AND name NOT LIKE 'sqlite_%'"
            params = args.tables
            if params:
                sql += " AND name IN (" + ",".join("?" for _ in params) + ")"
            sql += " ORDER BY name"
            limit, timeout = 200, 5
        else:
            sql = args.sql if args.sql is not None else sys.stdin.read(MAX_SQL_BYTES + 1)
            params = json.loads(args.params)
            limit, timeout = args.limit, args.timeout
        with database_file(args.database) as (path, source):
            result = query(path, sql, params, limit, timeout)
            result["source"] = source
            result["queried_at_utc"] = datetime.now(timezone.utc).isoformat()
        print(json.dumps(result, ensure_ascii=False, allow_nan=False))
        return 0
    except (ValueError, OSError, sqlite3.Error, TypeError, OverflowError) as error:
        print(json.dumps({"error": str(error)}, ensure_ascii=False), file=sys.stderr)
        return 1


if __name__ == "__main__":
    sys.exit(main())
