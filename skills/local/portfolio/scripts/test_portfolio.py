"""Run with: python3 -B -m unittest discover -s scripts -p 'test_*.py' -v"""

import hashlib
import json
from pathlib import Path
import shutil
import sqlite3
import subprocess
import sys
import tempfile
import time
import unittest

import portfolio


class PortfolioTests(unittest.TestCase):
    def setUp(self):
        self.directory = tempfile.TemporaryDirectory()
        self.addCleanup(self.directory.cleanup)
        self.database = Path(self.directory.name) / "portfolio #1?.db"
        with sqlite3.connect(self.database) as connection:
            connection.executescript("""
                CREATE TABLE FinanceEntries (
                    Id INTEGER PRIMARY KEY, Month TEXT, Description TEXT, Amount TEXT
                );
                INSERT INTO FinanceEntries VALUES
                    (1, '2026-10-01', 'Café', '72.50'),
                    (2, '2026-10-01', 'Mercado', '100.01'),
                    (3, '2026-09-01', 'Earlier month', '2.00');
            """)

    def read(self, sql, params=None, **options):
        return portfolio.query(self.database, sql, {} if params is None else params, **options)

    def test_preserves_decimal_text_and_binds_parameters(self):
        result = self.read(
            "SELECT Description, Amount FROM FinanceEntries WHERE Month = :month ORDER BY Id",
            {"month": "2026-10-01"},
        )
        self.assertEqual(result["columns"], ["Description", "Amount"])
        self.assertEqual(result["rows"], [["Café", "72.50"], ["Mercado", "100.01"]])
        self.assertFalse(result["truncated"])
        self.assertEqual(self.read("SELECT ?", ["'; DROP TABLE FinanceEntries; --"])["row_count"], 1)

    def test_reports_truncation_only_when_more_rows_exist(self):
        sql = "SELECT Id FROM FinanceEntries ORDER BY Id"
        self.assertEqual(self.read(sql, limit=2)["rows"], [[1], [2]])
        self.assertTrue(self.read(sql, limit=2)["truncated"])
        self.assertFalse(self.read(sql, limit=3)["truncated"])
        self.assertEqual(self.read("SELECT Id FROM FinanceEntries WHERE 0")["row_count"], 0)

    def test_denies_mutations_and_keeps_database_identical(self):
        attached = Path(self.directory.name) / "attached.db"
        before = hashlib.sha256(self.database.read_bytes()).hexdigest()
        statements = [
            "DELETE FROM FinanceEntries",
            "UPDATE FinanceEntries SET Amount = '0' RETURNING Id",
            "INSERT INTO FinanceEntries VALUES (4, '2026-10-01', 'Injected', '1')",
            "DROP TABLE FinanceEntries",
            "CREATE TABLE injected (Id INTEGER)",
            "ALTER TABLE FinanceEntries ADD COLUMN Injected TEXT",
            "WITH ids AS (SELECT 1) DELETE FROM FinanceEntries WHERE Id IN ids RETURNING Id",
            "EXPLAIN DELETE FROM FinanceEntries",
            "PRAGMA query_only = OFF",
            "PRAGMA user_version = 99",
            "PRAGMA table_info(FinanceEntries)",
            "VACUUM",
            "ATTACH DATABASE :path AS other",
            "SELECT load_extension('missing')",
            "SELECT 1; DELETE FROM FinanceEntries",
        ]
        for statement in statements:
            with self.subTest(sql=statement):
                with self.assertRaises((sqlite3.Error, ValueError)):
                    self.read(statement, {"path": str(attached)})
        self.assertFalse(attached.exists())
        self.assertEqual(self.read("SELECT COUNT(*) FROM FinanceEntries")["rows"], [[3]])
        self.assertEqual(hashlib.sha256(self.database.read_bytes()).hexdigest(), before)

    def test_reads_committed_wal_without_immutable_shortcut(self):
        with sqlite3.connect(self.database) as writer:
            writer.execute("PRAGMA journal_mode = WAL")
            writer.execute("PRAGMA wal_autocheckpoint = 0")
            writer.execute("INSERT INTO FinanceEntries VALUES (4, '2026-10-01', 'WAL', '0.01')")
            writer.commit()
            self.assertTrue(Path(str(self.database) + "-wal").exists())
            self.assertEqual(self.read("SELECT Amount FROM FinanceEntries WHERE Id = 4")["rows"], [["0.01"]])

    @unittest.skipUnless(shutil.which("node"), "Node 22.16+ is needed to exercise the production exporter")
    def test_production_exporter_captures_committed_wal(self):
        with sqlite3.connect(self.database) as writer:
            writer.execute("PRAGMA journal_mode = WAL")
            writer.execute("PRAGMA wal_autocheckpoint = 0")
            writer.execute("INSERT INTO FinanceEntries VALUES (4, '2026-10-01', 'WAL', '0.01')")
            writer.commit()
            code = portfolio.BACKUP_JS.replace("'/app/data/portfolio-tracker.db'", json.dumps(str(self.database)))
            exported = subprocess.run(
                ["node", "--no-warnings", "--input-type=module", "-e", code],
                capture_output=True, timeout=10, check=False,
            )
            self.assertEqual(exported.returncode, 0, exported.stderr.decode())
            snapshot = Path(self.directory.name) / "snapshot.db"
            snapshot.write_bytes(exported.stdout)
            self.assertEqual(portfolio.query(snapshot, "SELECT Amount FROM FinanceEntries WHERE Id = 4", {})["rows"], [["0.01"]])

    def test_interrupts_expensive_queries(self):
        started = time.monotonic()
        with self.assertRaisesRegex(ValueError, "timed out"):
            self.read("""
                WITH RECURSIVE numbers(n) AS (
                    VALUES(1) UNION ALL SELECT n + 1 FROM numbers
                ) SELECT sum(n) FROM numbers
            """, timeout=0.01)
        self.assertLess(time.monotonic() - started, 2)

    def test_bounds_query_results_and_values(self):
        with self.assertRaisesRegex(ValueError, "200 KB"):
            self.read("SELECT printf('%0200001d', 1)")
        with self.assertRaises(sqlite3.Error):
            self.read("SELECT zeroblob(2000000)")
        with self.assertRaisesRegex(ValueError, "32 KiB"):
            self.read("SELECT 1 -- " + "x" * portfolio.MAX_SQL_BYTES)
        for options in ({"limit": 0}, {"limit": 1001}, {"timeout": 0}, {"timeout": 31}):
            with self.subTest(options=options), self.assertRaises(ValueError):
                self.read("SELECT 1", **options)

    def test_missing_database_is_not_created(self):
        missing = Path(self.directory.name) / "missing.db"
        with self.assertRaises(sqlite3.Error):
            portfolio.query(missing, "SELECT 1", {})
        self.assertFalse(missing.exists())

    def cli(self, *arguments, sql=None):
        return subprocess.run(
            [sys.executable, str(Path(portfolio.__file__)), "--database", str(self.database), *arguments],
            input=sql, capture_output=True, text=True, check=False,
        )

    def test_cli_reads_schema_and_stdin_with_source(self):
        result = self.cli("schema", "FinanceEntries")
        self.assertEqual(result.returncode, 0, result.stderr)
        schema = json.loads(result.stdout)
        self.assertEqual(schema["rows"][0][0], "FinanceEntries")
        self.assertIn("CREATE TABLE", schema["rows"][0][2])
        result = self.cli("query", "--params", '{"id":1}', sql="SELECT Amount FROM FinanceEntries WHERE Id = :id")
        self.assertEqual(result.returncode, 0, result.stderr)
        data = json.loads(result.stdout)
        self.assertEqual(data["rows"], [["72.50"]])
        self.assertEqual(data["source"], {"kind": "local", "database": str(self.database)})
        self.assertIn("queried_at_utc", data)

    def test_cli_errors_without_printing_partial_results(self):
        for arguments in (("query", "DELETE FROM FinanceEntries"), ("query", "SELECT 1", "--params", "null")):
            with self.subTest(arguments=arguments):
                result = self.cli(*arguments)
                self.assertNotEqual(result.returncode, 0)
                self.assertEqual(result.stdout, "")
                self.assertIn("error", json.loads(result.stderr))


if __name__ == "__main__":
    unittest.main()
