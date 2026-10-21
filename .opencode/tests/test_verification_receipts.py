"""Keep current-run evidence separate from retained artifacts."""
import hashlib
import io
import json
from pathlib import Path
import subprocess
import sys
import tarfile
import tempfile
import unittest
from unittest.mock import patch

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "workflows"))
import verify_package as verify


class ReceiptTests(unittest.TestCase):
    def fixture(self, root):
        (root / "R").mkdir()
        (root / "DESCRIPTION").write_text("Package: statart\nVersion: 1.0\n", encoding="utf-8")
        return root / ".opencode/workflows/verify_package.py"

    def test_full_staged_digest_covers_non_code_inputs(self):
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp)
            self.fixture(root)
            previous = verify.source_identity(root)[0]
            for name in ["tests/testthat/_snaps/output.md", "data/example.rda",
                         "inst/examples/example.R", ".opencode/workflows/run_suite.R"]:
                path = root / name
                path.parent.mkdir(parents=True, exist_ok=True)
                path.write_bytes(b"fixture")
                current = verify.source_identity(root)[0]
                self.assertNotEqual(previous, current)
                previous = current

    def test_failed_install_and_exception_invalidate_stale_success(self):
        for outcome in [subprocess.CompletedProcess([], 17), RuntimeError("fixture")]:
            with self.subTest(outcome=outcome), tempfile.TemporaryDirectory() as temp:
                root = Path(temp)
                script = self.fixture(root)
                prefix = root / "result"
                receipt = root / "result-paths.json"
                receipt.write_text('{"status":"passed","run_id":"old"}', encoding="utf-8")
                stale = root / "result.csv"
                stale.write_text("stale", encoding="utf-8")
                kwargs = {"side_effect": outcome} if isinstance(outcome, Exception) else {"return_value": outcome}
                with patch.object(verify, "__file__", str(script)), \
                     patch.object(sys, "argv", ["verify", "--prefix", str(prefix)]), \
                     patch.object(verify, "r_command", side_effect=lambda command, **kw: command), \
                     patch.object(verify.subprocess, "run", **kwargs):
                    if isinstance(outcome, Exception):
                        with self.assertRaisesRegex(RuntimeError, "fixture"):
                            verify.main()
                    else:
                        self.assertEqual(verify.main(), 17)
                record = json.loads(receipt.read_text(encoding="utf-8"))
                self.assertEqual(record["status"], "failed")
                self.assertNotEqual(record["run_id"], "old")
                self.assertNotIn(str(stale), record["current_outputs"])
                self.assertTrue(stale.exists())
                self.assertEqual(record["stages"][-1]["status"], "failed")

    def test_development_check_skips_only_vignettes_and_manual(self):
        class Checked(Exception):
            pass

        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp)
            script = self.fixture(root)

            def run(command, cwd, **kwargs):
                command = list(map(str, command))
                if "build" in command:
                    self.assertIn("--no-build-vignettes", command)
                    (Path(cwd) / "statart_1.0.tar.gz").write_bytes(b"fixture")
                    return subprocess.CompletedProcess(command, 0)
                if "check" in command:
                    self.assertIn("--ignore-vignettes", command)
                    self.assertIn("--no-manual", command)
                    self.assertNotIn("--no-tests", command)
                    self.assertNotIn("--no-examples", command)
                    raise Checked()
                self.fail("Unexpected stage before the native check")

            with patch.object(verify, "__file__", str(script)), \
                 patch.object(sys, "argv", ["verify", "--check", "--prefix", str(root / "result")]), \
                 patch.object(verify, "r_command", side_effect=lambda command, **kw: command), \
                 patch.object(verify.subprocess, "run", side_effect=run):
                with self.assertRaises(Checked):
                    verify.main()

    def test_release_runs_check_then_candidate_snapshots_without_preliminary_suite(self):
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp)
            script = self.fixture(root)
            prefix = root / "result"
            names = []
            def run(command, cwd, env, **kwargs):
                command = list(map(str, command))
                if "build" in command:
                    archive = Path(cwd) / "statart_1.0.tar.gz"
                    with tarfile.open(archive, "w:gz") as bundle:
                        content = (root / "DESCRIPTION").read_bytes()
                        entry = tarfile.TarInfo("statart/DESCRIPTION")
                        entry.size = len(content)
                        bundle.addfile(entry, io.BytesIO(content))
                if any(x.endswith("parse_check_result.R") for x in command):
                    Path(command[-1]).write_text('{"counts":{},"notes":[]}', encoding="utf-8")
                if "check" in command:
                    self.assertNotIn("NOT_CRAN", env)
                    self.assertNotIn("--no-tests", command)
                    self.assertNotIn("--ignore-vignettes", command)
                if any(x.endswith("run_suite.R") for x in command):
                    Path(command[-4] + ".csv").write_text(
                        'passed,failed,error,warning,skipped\n2,0,FALSE,0,0\n', encoding="utf-8")
                    self.assertEqual(command[-1], "snapshots")
                    self.assertTrue(env["STATART_TEST_LIBRARY"].endswith("bundle-library"))
                names.append(command)
                return subprocess.CompletedProcess(command, 0)
            with patch.object(verify, "__file__", str(script)), \
                 patch.object(sys, "argv", ["verify", "--release", "--prefix", str(prefix)]), \
                 patch.object(verify, "r_command", side_effect=lambda command, **kw: command), \
                 patch.object(verify.subprocess, "run", side_effect=run):
                self.assertEqual(verify.main(), 0)
            record = json.loads((root / "result-paths.json").read_text(encoding="utf-8"))
            self.assertEqual([stage["name"] for stage in record["stages"]],
                             ["stage", "build", "check", "check-result", "bundle-install", "snapshots", "resources"])
            installation = json.loads((root / "result-installation.json").read_text(encoding="utf-8"))
            self.assertEqual(installation["source_sha256"], record["source_sha256"])
            self.assertEqual(installation["run_id"], record["run_id"])
            self.assertEqual(record["suite"]["blocks"], 1)
            self.assertEqual(record["suite"]["totals"], dict(passed=2, failed=0, error=0, warning=0, skipped=0))
            self.assertEqual(record["mode"], "release")
            self.assertEqual(record["filter"], "")
            self.assertIsNone(record["shuffle_seed"])
            parsed = json.loads((root / "result-check-result.json").read_text(encoding="utf-8"))
            self.assertEqual(parsed["source_sha256"], record["source_sha256"])


if __name__ == "__main__":
    unittest.main()
