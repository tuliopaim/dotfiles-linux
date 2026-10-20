#!/usr/bin/env python3
"""Run with: python3 scripts/tests/net-watch.test.py"""

import contextlib
import datetime as dt
import importlib.machinery
import importlib.util
import io
import json
from pathlib import Path
import subprocess
import sys
import tempfile
import time
import unittest
from unittest.mock import patch


sys.dont_write_bytecode = True
loader = importlib.machinery.SourceFileLoader("net_watch", str(Path(__file__).parents[1] / "net-watch"))
spec = importlib.util.spec_from_loader(loader.name, loader)
watch = importlib.util.module_from_spec(spec)
loader.exec_module(watch)


class RecorderTests(unittest.TestCase):
    def test_launchd_restart_retries_transient_failure_with_a_deadline(self):
        with patch.object(watch, "command", side_effect=[(5, "", "not removed yet"), (0, "", "")]) as cmd, \
                patch.object(watch.time, "sleep"):
            watch.start_service(Path("recorder.plist"))
            self.assertEqual(cmd.call_count, 2)
        with patch.object(watch, "command", return_value=(5, "", "still unavailable")), \
                patch.object(watch.time, "monotonic", side_effect=[0, 6]):
            with self.assertRaisesRegex(RuntimeError, "still unavailable"):
                watch.start_service(Path("recorder.plist"))

    def test_repeated_fatal_errors_replace_one_bounded_diagnostic(self):
        with tempfile.TemporaryDirectory() as directory:
            args = ["net-watch", "--data-dir", directory, "run"]
            with patch.object(sys, "argv", args), contextlib.redirect_stderr(io.StringIO()):
                for message in ["first crash " * 10000, "latest crash " * 10000]:
                    with patch.object(watch, "run", side_effect=RuntimeError(message)):
                        self.assertEqual(watch.main(), 1)
            files = list(Path(directory).iterdir())
            self.assertEqual([p.name for p in files], ["last-error.txt"])
            self.assertLessEqual(files[0].stat().st_size, 1000)
            self.assertTrue(files[0].read_text().startswith("latest crash"))

    def test_recorder_writes_private_samples_prevents_duplicates_and_stops(self):
        with tempfile.TemporaryDirectory() as directory:
            data = Path(directory)
            args = [sys.executable, str(Path(__file__).parents[1] / "net-watch"),
                    "--data-dir", directory, "run", "--interval", "5"]
            process = subprocess.Popen(args, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
            try:
                deadline = time.monotonic() + 15
                records = []
                while time.monotonic() < deadline:
                    records = list(watch.records_since(data, dt.datetime.min.replace(tzinfo=dt.timezone.utc)))
                    if len(records) >= 2:
                        break
                    time.sleep(.1)
                self.assertGreaterEqual(len(records), 2)
                self.assertEqual((data / "latest.json").stat().st_mode & 0o777, 0o600)
                duplicate = subprocess.run(args, capture_output=True, text=True, timeout=3)
                self.assertEqual(duplicate.returncode, 1)
                self.assertIn("already running", duplicate.stderr)
                process.terminate()
                process.communicate(timeout=5)
                self.assertEqual(process.returncode, 0)
            finally:
                if process.poll() is None:
                    process.kill()
                    process.communicate()

    def test_hung_probe_is_bounded(self):
        start = time.monotonic()
        code, _, error = watch.command([sys.executable, "-c", "import time; time.sleep(10)"], .1)
        self.assertEqual(code, 124)
        self.assertIn("timed out", error)
        self.assertLess(time.monotonic() - start, 2)

    def test_local_connectivity_is_preserved_when_wan_and_dns_fail(self):
        def fake_command(args, timeout=2):
            if args[0] == "/sbin/route":
                return 0, "gateway: 192.0.2.1\ninterface: en0\n", ""
            if args[0] == "/usr/sbin/netstat":
                return 0, ("Name Mtu Network Address Ipkts Ierrs Ibytes Opkts Oerrs Obytes Coll\n"
                           "en0 1500 <Link#1> 00:00:00:00:00:01 10 0 1000 10 0 500 0\n"), ""
            if args[-1] == "192.0.2.2":
                return 0, "64 bytes from 192.0.2.2: icmp_seq=0 ttl=64 time=2.35 ms", ""
            if args[0] == "/usr/bin/curl":
                return 28, "000 0.000000 0.000000 0.000000 3.000000", "Operation timed out"
            return 124, "", "timed out"

        with patch.object(watch, "command", side_effect=fake_command), \
                patch.object(watch.socket, "create_connection"):
            record, counters = watch.sample("192.0.2.2")
        self.assertEqual(counters, (1000, 500))
        self.assertTrue(record["probes"]["router_tcp"]["ok"])
        self.assertTrue(record["probes"]["lan_peer"]["ok"])
        for name in ["google_v4", "cloudflare_v4", "cloudflare_v6", "system_dns",
                     "direct_dns", "https_v4", "https_v6"]:
            self.assertFalse(record["probes"][name]["ok"], name)

    def test_no_default_route_still_records_wan_probes(self):
        with patch.object(watch, "command", return_value=(1, "", "no route")):
            record, counters = watch.sample(deep=False)
        self.assertIsNone(counters)
        self.assertEqual(record["network"]["error"], "no route")
        self.assertNotIn("router_tcp", record["probes"])
        self.assertFalse(record["probes"]["google_v4"]["ok"])

    def test_traffic_ignores_sleep_and_counter_resets(self):
        self.assertEqual(watch.traffic((0, 0), (1250000, 2500000), 10),
                         {"rx_mbps": 1.0, "tx_mbps": 2.0})
        self.assertIsNone(watch.traffic((100, 100), (1, 1), 10))
        self.assertIsNone(watch.traffic((0, 0), (1000000, 1000000), 600))

    def test_ipv6_history_keeps_old_and_current_prefixes_and_deprecation(self):
        def fake_command(args, timeout=2):
            if args[0] == "/usr/sbin/scutil":
                return 0, ("IPv6 network interface information\n en0: flags\n"
                           " address : 2001:4860:1::10\n"), ""
            if args[0] == "/sbin/route":
                return 0, "gateway: fe80::1%en0\ninterface: en0\n", ""
            return 0, ("inet6 2001:4860:1::10 prefixlen 64 autoconf secured \n"
                       "inet6 2001:4860:1::11 prefixlen 64 autoconf temporary \n"
                       "inet6 2001:4860:2::10 prefixlen 64 autoconf deprecated \n"), ""
        with patch.object(watch, "command", side_effect=fake_command):
            state = watch.ipv6_state("en0")
        self.assertEqual(state["ipv6_primary_prefix"], "2001:4860:1::/64")
        self.assertEqual(state["ipv6_prefixes"], [
            {"prefix": "2001:4860:1::/64", "deprecated": False},
            {"prefix": "2001:4860:2::/64", "deprecated": True}])

    def test_rotation_retention_and_latest_preserve_evidence(self):
        with tempfile.TemporaryDirectory() as directory:
            data = Path(directory)
            (data / "2026-10-01.jsonl").write_text("old\n")
            (data / "2026-10-01.jsonl.1").write_text("old\n")
            (data / "2026-10-10.jsonl").write_text("keep\n")
            (data / "notes.txt").write_text("keep\n")
            first = {"time": "2026-10-16T10:00:00+00:00", "host": "test", "probes": {}}
            second = {**first, "time": "2026-10-16T10:00:10+00:00"}
            watch.write_record(data, first, limit=100)
            watch.write_record(data, second, limit=100)
            self.assertFalse((data / "2026-10-01.jsonl").exists())
            self.assertFalse((data / "2026-10-01.jsonl.1").exists())
            self.assertTrue((data / "2026-10-10.jsonl").exists())
            self.assertTrue((data / "notes.txt").exists())
            self.assertEqual(json.loads((data / "latest.json").read_text()), second)
            self.assertEqual(json.loads((data / "2026-10-16.jsonl.1").read_text()), first)

    def test_status_reports_failures_and_tolerates_partial_last_line(self):
        now = dt.datetime.now(dt.timezone.utc)
        record = {"time": now.isoformat(), "host": "test", "gap_s": 600,
                  "probes": {"lan_peer": {"ok": True, "ms": 2.5},
                             "system_dns": {"ok": False, "error": "timed out"}}}
        with tempfile.TemporaryDirectory() as directory:
            data = Path(directory)
            watch.write_record(data, record)
            with (data / (now.date().isoformat() + ".jsonl")).open("a") as stream:
                stream.write('{"time":')
            output = io.StringIO()
            with contextlib.redirect_stdout(output):
                self.assertEqual(watch.status(data, 1), 0)
            self.assertIn("1/1 failed", output.getvalue())
            self.assertIn("Sampling gaps: 1", output.getvalue())
            self.assertIn("sleep/stopped recorder", output.getvalue())


if __name__ == "__main__":
    unittest.main()
