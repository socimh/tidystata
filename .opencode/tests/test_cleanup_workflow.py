"""Exercise lean source staging and current demo reports with temporary fixtures."""
import importlib.util
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[2]
WORKFLOWS = ROOT / ".opencode/workflows"
sys.path.insert(0, str(WORKFLOWS))
from r_process import r_command, r_environment


def load_verifier():
    spec = importlib.util.spec_from_file_location(
        "cleanup_verifier", WORKFLOWS / "verify_package.py"
    )
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


class SourceStagingTests(unittest.TestCase):
    def test_source_copy_omits_local_artifacts_but_keeps_verification_inputs(self):
        verifier = load_verifier()
        retained = {
            "R/fixture.R", "tests/testthat/test-fixture.R",
            ".opencode/demos/demo_fixture.R", ".opencode/workflows/run_suite.R",
            "inst/docs/example.txt", "src/fixture.cpp",
        }
        excluded = {
            ".git/config", ".Rproj.user/state", ".Rhistory",
            "docs/index.html", "extra_functions/retired.R",
            ".opencode/tools/library/pkg/DESCRIPTION",
            ".opencode/notes/screenshot.png", ".opencode/results/old.log",
            ".opencode/workflows/__pycache__/fixture.pyc", "src/fixture.o",
            "src/statart.dll", ".Rd2pdf50804/Rd2.tex",
        }
        with tempfile.TemporaryDirectory(prefix="statart-staging-fixture-") as temporary:
            base = Path(temporary)
            root, workspace = base / "repository", base / "workspace"
            root.mkdir()
            for name in retained | excluded:
                path = root / name
                path.parent.mkdir(parents=True, exist_ok=True)
                path.write_text("fixture", encoding="utf-8")
            shutil.copytree(root, workspace / "statart", ignore=verifier.source_copy_ignore(root))
            actual = {
                path.relative_to(workspace / "statart").as_posix()
                for path in (workspace / "statart").rglob("*") if path.is_file()
            }
            self.assertEqual(actual, retained)


class CurrentReportTests(unittest.TestCase):
    def test_index_reads_stable_reports_and_ignores_history_and_reviews(self):
        with tempfile.TemporaryDirectory(prefix="statart-report-fixture-") as temporary:
            root = Path(temporary)
            demos, reports = root / ".opencode/demos", root / ".opencode/reports"
            demos.mkdir(parents=True)
            reports.mkdir()
            (root / "DESCRIPTION").write_text("Package: fixture\nVersion: 1.2.3\n", encoding="utf-8")
            for name in ("browse", "containers"):
                (demos / f"demo_{name}.R").write_text("# fixture\n", encoding="utf-8")
                (reports / f"report_{name}.md").write_text(
                    "# Current report\n**Status:** PASS\n## Example 1\n", encoding="utf-8"
                )
                (reports / f"report_{name}_1.2.3.md").write_text(
                    "# Previous report\n**Status:** FAIL\n", encoding="utf-8"
                )
            (reports / "readiness-review.md").write_text("# Old review\n", encoding="utf-8")
            env = r_environment()
            env["STATART_REPORT_DIR"] = str(reports)
            result = subprocess.run(
                r_command(["Rscript", WORKFLOWS / "generate_demo_reports.R", "--index-only"]),
                cwd=root, env=env, capture_output=True, text=True,
                encoding="utf-8", errors="replace",
            )
            self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
            index = (reports / "INDEX.md").read_text(encoding="utf-8")
            self.assertIn("[View](report_browse.md)", index)
            self.assertIn("[View](report_containers.md)", index)
            self.assertIn("Table container preservation", index)
            self.assertNotIn("report_browse_1.2.3.md", index)
            self.assertNotIn("readiness-review.md", index)
            self.assertNotIn("Historical reports", index)
            (reports / "report_browse.md").write_text(
                "# Current report\n**Status:** FAIL\n", encoding="utf-8"
            )
            failed = subprocess.run(
                r_command(["Rscript", WORKFLOWS / "generate_demo_reports.R", "--index-only"]),
                cwd=root, env=env, capture_output=True, text=True,
                encoding="utf-8", errors="replace",
            )
            self.assertEqual(failed.returncode, 1, failed.stdout + failed.stderr)
            self.assertIn("| browse | Browse data | 0 | FAIL |", (reports / "INDEX.md").read_text(encoding="utf-8"))


if __name__ == "__main__":
    unittest.main()
