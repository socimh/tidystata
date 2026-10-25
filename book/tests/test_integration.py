"""Exercise safe preservation and idempotent personal-site preparation."""
import importlib.util
from pathlib import Path
import sys
import tempfile
import unittest
from unittest import mock

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
import integrate


class IntegrationTests(unittest.TestCase):
    def test_personal_source_changes_are_idempotent(self):
        config = ('project:\n  type: website\n  output-dir: docs\n'
                  '  resources:\n    - "!private-backups/**"\n'
                  '  post-render: bash _restore-preserved.sh\n'
                  'website:\n  navbar:\n    left:\n      - text: Books\n'
                  '        menu:\n          - text: "Claude Code 指南"\n'
                  '            href: https://www.socimh.com/cc-guide/\n')
        source = {"_quarto.yml": config, "books.qmd": '---\ntitle: "Books"\n---\n\nExisting book.\n',
                  "software.qmd": '---\ntitle: "Software"\n---\n\nExisting software.\n', ".gitignore": ".quarto/\n",
                  "render-site.sh": '#!/usr/bin/env bash\ncd "$(dirname "$0")"\nquarto render\n(cd zh && quarto render)\n',
                  "zh/_quarto.yml": 'website:\n            href: https://www.socimh.com/cc-guide/\n',
                  "zh/books.qmd": '---\ntitle: "著作"\n---\n原有著作\n',
                  "zh/software.qmd": '---\ntitle: "软件"\n---\n原有软件\n'}
        patched = integrate.patch_sources(source)
        self.assertEqual(patched, integrate.patch_sources(patched))
        self.assertIn("Existing book.", patched["books.qmd"])
        self.assertIn("Existing software.", patched["software.qmd"])
        self.assertIn("_preserve-embedded.py save", patched["_quarto.yml"])
        self.assertIn("_preserve-embedded.py restore", patched["_quarto.yml"])
        self.assertEqual(patched["_quarto.yml"].count("href: stata-to-r/index.html"), 1)
        self.assertEqual(patched["render-site.sh"].count("quarto render --no-clean"), 2)
        self.assertLess(patched["render-site.sh"].index("_preserve-embedded.py save"),
                        patched["render-site.sh"].index("quarto render --no-clean"))
        self.assertIn("href: ../stata-to-r/zh/index.html", patched["zh/_quarto.yml"])
        self.assertIn("原有著作", patched["zh/books.qmd"])
        self.assertIn("原有软件", patched["zh/software.qmd"])

    def test_preservation_restores_book_slides_and_domain_without_deletion(self):
        spec = importlib.util.spec_from_file_location("preservation", Path(__file__).resolve().parents[1] / "preserve-embedded.py")
        preservation = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(preservation)
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            originals = {"CNAME": b"www.socimh.com\n", "cc-guide/index.html": b"old book",
                         "slides/deck.html": b"slides", "zh/index.html": b"Chinese site",
                         "stata-to-r/zh/index.html": "参考手册".encode("utf-8")}
            for relative, content in originals.items():
                path = root / "docs" / relative
                path.parent.mkdir(parents=True, exist_ok=True)
                path.write_bytes(content)
            preservation.preserve(root, "save")
            # Simulate one missing output without deleting an artifact.
            moved = root / "retained-original.html"
            (root / "docs/stata-to-r/zh/index.html").rename(moved)
            (root / "docs/zh/index.html").rename(root / "retained-chinese.html")
            new = root / "docs/new.html"
            new.write_text("new page", encoding="utf-8")
            for _ in range(2):
                preservation.preserve(root, "restore")
                for relative, content in originals.items():
                    self.assertEqual((root / "docs" / relative).read_bytes(), content)
                self.assertEqual(new.read_text(encoding="utf-8"), "new page")
            self.assertTrue(moved.is_file())

    def test_fresh_checkout_without_cache_restores_tracked_outputs(self):
        spec = importlib.util.spec_from_file_location("preservation", Path(__file__).resolve().parents[1] / "preserve-embedded.py")
        preservation = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(preservation)
        files = {"docs/CNAME": b"www.socimh.com", "docs/zh/index.html": b"Chinese site",
                 "docs/stata-to-r/index.html": b"new book"}
        def git_read(command, **kwargs):
            if "ls-files" in command:
                return mock.Mock(returncode=0, stdout="\0".join(files).encode() + b"\0")
            return mock.Mock(returncode=0, stdout=files[command[-1][1:]])
        with tempfile.TemporaryDirectory() as temporary, mock.patch("subprocess.run", side_effect=git_read):
            root = Path(temporary)
            # Quarto cleans before the pre-render hook; fresh output is empty.
            preservation.preserve(root, "save")
            preservation.preserve(root, "restore")
            for relative, content in files.items():
                self.assertEqual((root / relative).read_bytes(), content)

    def test_preparation_rejects_an_edit_during_rendering(self):
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            personal, book = root / "personal", root / "book"
            personal.mkdir()
            (book / "zh").mkdir(parents=True)
            for name in ("index.html", "zh/index.html"):
                (book / name).write_text("book", encoding="utf-8")
            source = {"_quarto.yml": 'project:\n  resources:\n    - "!private-backups/**"\n  post-render: bash _restore-preserved.sh\nwebsite:\n            href: https://www.socimh.com/cc-guide/\n',
                      "books.qmd": '---\ntitle: "Books"\n---\nOriginal books\n',
                      "software.qmd": '---\ntitle: "Software"\n---\nOriginal software\n', ".gitignore": ""}
            for name, text in source.items():
                (personal / name).write_text(text, encoding="utf-8")
            calls = []
            def fake_render(command, cwd, log, environment):
                calls.append(command)
                (cwd / "docs").mkdir(exist_ok=True)
                for name in ("books.html", "software.html"):
                    (cwd / "docs" / name).write_text(integrate.BOOK_PATH, encoding="utf-8")
                if len(calls) == 1:
                    (personal / "books.qmd").write_text(source["books.qmd"] + "New user edit\n", encoding="utf-8")
            with self.assertRaisesRegex(ValueError, "changed during preparation"):
                integrate.prepare(personal, book, root / "staging", fake_render, lambda x, y: x, {})
            self.assertIn("New user edit", (personal / "books.qmd").read_text(encoding="utf-8"))


if __name__ == "__main__":
    unittest.main()
