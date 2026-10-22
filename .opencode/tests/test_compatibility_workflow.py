"""Offline checks for the remote compatibility matrix and the local R launcher."""
import json
import os
from pathlib import Path
import re
import subprocess
import sys
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[2]
LAUNCHER = ROOT / ".opencode/workflows/run_r_safe.py"


class CompatibilityWorkflowTests(unittest.TestCase):
    def test_os_matrix_and_manual_trigger_are_preserved(self):
        workflow = (ROOT / ".github/workflows/R-CMD-check.yaml").read_text(encoding="utf-8")
        rows = re.findall(r"- \{os:\s*([^,]+),\s*r: '([^']+)'", workflow)
        self.assertEqual(set(rows), {
            ("macos-latest", "release"), ("windows-latest", "release"),
            ("ubuntu-latest", "devel"), ("ubuntu-latest", "release"),
            ("ubuntu-latest", "oldrel-1"), ("ubuntu-22.04", "4.1"),
        })
        self.assertEqual(len(rows), 6)
        self.assertIn("  workflow_dispatch:", workflow)

    def test_every_runner_uses_the_standard_package_check(self):
        # Hosted runners need no crash-dialog protection; the launcher is for
        # local Windows runs only.
        workflow = (ROOT / ".github/workflows/R-CMD-check.yaml").read_text(encoding="utf-8")
        self.assertIn("r-lib/actions/check-r-package@v2", workflow)
        self.assertNotIn("runner.os", workflow)
        self.assertNotIn("ci_check.py", workflow)
        self.assertNotIn("C:/Users/", workflow)


class HostedLauncherTests(unittest.TestCase):
    def launch(self, code, expected):
        with tempfile.TemporaryDirectory(prefix="tidystata-launcher-test-") as temporary:
            result = subprocess.run(
                [sys.executable, str(LAUNCHER), "--log-directory", temporary,
                 "--", sys.executable, "-c", code],
                capture_output=True, encoding="utf-8", errors="replace",
                env={key: value for key, value in os.environ.items()
                     if key != "PROCESSOR_ARCHITECTURE"},
            )
            self.assertEqual(result.returncode, expected, result.stdout + result.stderr)
            paths = list(Path(temporary).glob("*.status.json"))
            self.assertEqual(len(paths), 1)
            receipt = json.loads(paths[0].read_text(encoding="utf-8"))
            self.assertEqual(receipt["exit_code"], expected)
            self.assertFalse(receipt["timeout"])
            self.assertEqual(receipt["cwd"], str(Path.cwd()))
            self.assertEqual(len(list(Path(temporary).glob("*.out.log"))), 1)
            self.assertEqual(len(list(Path(temporary).glob("*.err.log"))), 1)
            return result, receipt

    def test_actual_child_exit_and_streams_are_retained(self):
        result, _ = self.launch(
            'import sys; print("stdout fixture"); print("stderr fixture", file=sys.stderr); sys.exit(17)', 17)
        self.assertIn("stdout fixture", result.stdout)
        self.assertIn("stderr fixture", result.stderr)

    @unittest.skipUnless(os.name == "nt", "Windows environment and error-mode probe")
    def test_missing_architecture_and_child_error_mode_are_repaired(self):
        result, receipt = self.launch(
            'import ctypes, os; print(os.environ["PROCESSOR_ARCHITECTURE"]); '
            'assert ctypes.windll.kernel32.GetErrorMode() & 2', 0)
        self.assertIn(receipt["processor_architecture"], ("x86", "ARM", "AMD64", "ARM64"))
        self.assertIn(receipt["processor_architecture"], result.stdout)


if __name__ == "__main__":
    unittest.main()
