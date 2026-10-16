"""Guard scope boundaries without requiring formatter/R installation."""

import importlib.util
from pathlib import Path
import tempfile
import subprocess
import unittest

SCRIPT = Path(__file__).resolve().parents[1] / "workflows/check_style.py"
SPEC = importlib.util.spec_from_file_location("check_style", SCRIPT)
CHECK = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(CHECK)


class StyleScopeTests(unittest.TestCase):
    def test_new_sources_preserves_unicode_filenames(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            def git(*args):
                return subprocess.run(["git", *args], cwd=root, check=True,
                                      capture_output=True)
            git("init", "-q")
            (root / "README").write_text("fixture\n", encoding="utf-8")
            git("add", "README")
            git("-c", "user.name=Style Test", "-c", "user.email=style@example.invalid",
                "commit", "-qm", "baseline")
            name = "R/\u5206\u6790.R"
            (root / "R").mkdir()
            (root / name).write_text("x <- 1\n", encoding="utf-8")
            git("add", "--", name)
            self.assertEqual(CHECK.new_sources(root, "HEAD"), {name})

    def test_valid_handwritten_source(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            (root / "source.R").write_text("x <- 1\n", encoding="utf-8")
            self.assertEqual(CHECK.checked_files(root, {"files": ["source.R"]}), ["source.R"])

    def test_rejects_missing_external_duplicate_generated_and_archive_paths(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            for name in ("R/cpp11.R", "extra_functions/old.R", "source.R"):
                path = root / name
                path.parent.mkdir(parents=True, exist_ok=True)
                path.write_text("x <- 1\n", encoding="utf-8")
            for paths in ([], ["missing.R"], ["../outside.R"], ["source.R"] * 2,
                          ["R/cpp11.R"], ["extra_functions/old.R"],
                          ["R\\cpp11.R"], ["extra_functions\\old.R"],
                          ["./R/cpp11.R"], ["R/CPP11.R"]):
                with self.subTest(paths=paths), self.assertRaises(ValueError):
                    CHECK.checked_files(root, {"files": paths})


if __name__ == "__main__":
    unittest.main()
