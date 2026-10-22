"""Exercise verification exit codes using a real temporary R package."""
import importlib.util
import os
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest
from unittest.mock import patch

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / ".opencode/workflows"))
from r_process import r_command, r_environment


class CommandTests(unittest.TestCase):
    def test_candidate_library_keeps_normal_user_library(self):
        with patch.dict(os.environ, {"R_LIBS_USER": "normal-user", "R_LIBS": "existing"}):
            env = r_environment(libraries=["candidate", "tools"])
            self.assertEqual(env["R_LIBS_USER"], "normal-user")
            self.assertEqual(env["R_LIBS"], os.pathsep.join(["candidate", "tools", "existing"]))

    def test_non_windows_uses_r_directly(self):
        self.assertEqual(r_command(["Rscript", "a.R"], platform="posix"),
                         ["Rscript", "a.R"])

    def test_windows_requires_verified_launcher(self):
        with self.assertRaisesRegex(RuntimeError, "TIDYSTATA_R_LAUNCHER"):
            r_command(["Rscript", "a.R"], platform="nt",
                      environ={"TIDYSTATA_R_LAUNCHER": "/absent/launcher.py"})

    def test_configured_launcher_preserves_argument_boundaries(self):
        with tempfile.TemporaryDirectory() as temporary:
            launcher = Path(temporary) / "protected launcher.py"
            launcher.write_text("# fixture", encoding="utf-8")
            command = r_command(["Rscript", "script with spaces.R"], platform="nt",
                                environ={"TIDYSTATA_R_LAUNCHER": str(launcher)})
            self.assertEqual(command[:2], [sys.executable, str(launcher)])
            self.assertEqual(command[-3:], ["--", "Rscript", "script with spaces.R"])


class RunnerTests(unittest.TestCase):
    def test_expected_conditions_and_unexpected_warning(self):
        cases = {
            "pass": ('testthat::expect_true(TRUE)', 0),
            "expected": ('testthat::expect_warning(warning("fixture"), "fixture")', 0),
            "warning": ('warning("fixture"); testthat::expect_true(TRUE)', 1),
            "failure": ('testthat::expect_true(FALSE)', 1),
            "error": ('stop("fixture")', 1),
        }
        with tempfile.TemporaryDirectory(prefix="tidystata-runner-test-") as temporary:
            base = Path(temporary)
            package = base / "fixture"
            (package / "R").mkdir(parents=True)
            tests = package / "tests/testthat"
            tests.mkdir(parents=True)
            (package / "DESCRIPTION").write_text(
                "Package: auditfixture\nTitle: Verification Fixture\nVersion: 0.0.1\n"
                "Description: Temporary verification fixture.\nLicense: MIT\n"
                "Authors@R: person('Test', 'Author', email='test@example.com', "
                "role=c('aut', 'cre'))\nConfig/testthat/edition: 3\n",
                encoding="utf-8",
            )
            (package / "NAMESPACE").write_text("", encoding="utf-8")
            for name, (body, expected) in cases.items():
                with self.subTest(name=name):
                    (tests / "test-fixture.R").write_text(
                        'testthat::test_that("fixture", {' + body + '})\n',
                        encoding="utf-8",
                    )
                    prefix = base / name
                    command = ["Rscript", str(ROOT / ".opencode/workflows/run_suite.R"),
                               str(package), str(prefix)]
                    if os.name == "nt":
                        launcher = os.environ.get("TIDYSTATA_R_LAUNCHER", "C:/Users/socimh/.codex/scripts/run_r_safe.py")
                        command = [sys.executable, launcher, "--", *command]
                    env = os.environ.copy()
                    if os.name == "nt":
                        env.update(LC_ALL="C", LANG="C")
                    result = subprocess.run(command, capture_output=True, text=True,
                                            encoding="utf-8", errors="replace", env=env)
                    self.assertEqual(result.returncode, expected, result.stdout + result.stderr)
                    self.assertTrue(prefix.with_suffix(".csv").is_file())
                    self.assertTrue(Path(str(prefix) + "-details.csv").is_file())


if __name__ == "__main__":
    unittest.main()
