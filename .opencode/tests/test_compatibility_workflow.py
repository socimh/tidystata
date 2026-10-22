"""Offline checks for the remote compatibility handoff and hosted launcher."""
import json
import importlib.util
import os
from pathlib import Path
import re
import subprocess
import sys
import tempfile
import unittest
from types import SimpleNamespace
from unittest.mock import patch

ROOT = Path(__file__).resolve().parents[2]
LAUNCHER = ROOT / ".opencode/workflows/run_r_safe.py"
sys.path.insert(0, str(ROOT / ".opencode/workflows"))
SPEC = importlib.util.spec_from_file_location(
    "ci_check", ROOT / ".opencode/workflows/ci_check.py")
CI = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(CI)


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

    def test_windows_check_has_portable_protection_and_retained_diagnostics(self):
        workflow = (ROOT / ".github/workflows/R-CMD-check.yaml").read_text(encoding="utf-8")
        self.assertIn("python .opencode/workflows/ci_check.py", workflow)
        self.assertIn("runner.os == 'Windows'", workflow)
        self.assertIn("always()", workflow)
        self.assertIn("actions/upload-artifact@v4", workflow)
        self.assertNotIn("C:/Users/", workflow)


class HostedCheckTests(unittest.TestCase):
    def test_failed_check_is_propagated_without_parsing_stale_logs(self):
        with tempfile.TemporaryDirectory() as temporary, \
                patch.object(CI, "DESTINATION", Path(temporary)), \
                patch.object(CI.subprocess, "check_output", side_effect=["commit\n", ""]), \
                patch.object(CI.subprocess, "run", return_value=SimpleNamespace(returncode=17)) as run:
            self.assertEqual(CI.main(), 17)
            self.assertEqual(run.call_count, 1)
            self.assertEqual(
                Path(run.call_args.kwargs["env"]["TIDYSTATA_R_LAUNCHER"]), LAUNCHER)
            if os.name == "nt":
                self.assertIn("run_r_safe.py", run.call_args.args[0][1])
            receipt = json.loads((Path(temporary) / "source.json").read_text(encoding="utf-8"))
            self.assertEqual(receipt["git_commit"], "commit")

    def test_successful_process_still_requires_complete_condition_audit(self):
        with tempfile.TemporaryDirectory() as temporary, \
                patch.object(CI, "DESTINATION", Path(temporary)), \
                patch.object(CI.subprocess, "check_output", side_effect=["commit\n", ""]), \
                patch.object(CI.subprocess, "run", side_effect=[
                    SimpleNamespace(returncode=0), SimpleNamespace(returncode=1)]) as run:
            (Path(temporary) / "native-status.txt").write_text("0\n", encoding="utf-8")
            self.assertEqual(CI.main(), 1)
            self.assertEqual(run.call_count, 2)
            self.assertIn("parse_check_result.R", " ".join(run.call_args.args[0]))


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
