"""The audit accepts complete artifacts and rejects missing local resources."""
import json
import hashlib
from pathlib import Path
import sys
import tempfile
import unittest

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
import validate


class ValidationTests(unittest.TestCase):
    def test_complete_artifact_passes_and_missing_asset_fails(self):
        with tempfile.TemporaryDirectory() as temporary:
            site = Path(temporary)
            for lang in ("en", "zh"):
                root = site if lang == "en" else site / "zh"
                root.mkdir(exist_ok=True)
                for name in ("index", "stata-index", "r-index"):
                    other = ("zh/" if lang == "en" else "../") + name + ".html"
                    example = ('<div id="example-a" data-example-id="a">'
                               '<pre class="r"><code>x &lt;- 1</code></pre>'
                               '<pre class="stata"><code><span class="kw">gen</span> x = 1</code></pre></div>') if name == "index" else ""
                    text = f'<a id="language-toggle" href="{other}">Language</a>{example}'
                    text += '<script src="reference.js"></script>'
                    (root / (name + ".html")).write_text(text, encoding="utf-8")
                (root / "reference.js").write_text("// local asset", encoding="utf-8")
                (root / "search.json").write_text(json.dumps([{"text": "ivreghdfe tabulate dplyr analytic missing 缺失"}]), encoding="utf-8")
            manifest = {"examples": {"a": "index.html#example-a"}, "chapters": [], "example_count": 1}
            manifest["code_hashes"] = {"a": {"r": hashlib.sha256(b"x <- 1").hexdigest(),
                                              "stata": hashlib.sha256(b"gen x = 1").hexdigest()}}
            self.assertEqual(validate.audit(site, manifest)["examples_per_edition"], 1)
            # The two editions must highlight the same code identically.
            zh_index = site / "zh/index.html"
            original = zh_index.read_text(encoding="utf-8")
            zh_index.write_text(original.replace('<span class="kw">gen</span> x', '<span class="kw">gen</span> <span class="fu">x</span>'), encoding="utf-8")
            with self.assertRaisesRegex(ValueError, "highlighting differs"):
                validate.audit(site, manifest)
            zh_index.write_text(original.replace('<span class="kw">gen</span>', 'gen'), encoding="utf-8")
            with self.assertRaisesRegex(ValueError, "Stata command not highlighted: zh/a"):
                validate.audit(site, manifest)
            zh_index.write_text(original, encoding="utf-8")
            # Move rather than delete even disposable verification artifacts.
            (site / "zh/reference.js").rename(site / "retained.js")
            with self.assertRaisesRegex(ValueError, "Broken local link"):
                validate.audit(site, manifest)


if __name__ == "__main__":
    unittest.main()
