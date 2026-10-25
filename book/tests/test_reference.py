"""Content and integration invariants for the generated reference book."""
import json
from pathlib import Path
import sys
import tempfile
import unittest

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
import reference

ROOT = Path(__file__).resolve().parents[2]


class ReferenceTests(unittest.TestCase):
    def test_both_editions_preserve_every_exact_example_and_same_anchors(self):
        rows = reference.read_csv(ROOT / "inst/extdata/stata-to-r.csv")
        metadata = {
            row["id"]: {"priority": i, "meaning": row["command"], "preferred": i == 0}
            for i, row in enumerate(rows)
        }
        with tempfile.TemporaryDirectory() as temporary:
            manifest = reference.generate(ROOT, Path(temporary), metadata)
            self.assertEqual(len(manifest["examples"]), len(rows))
            self.assertEqual(len({x["section"] for x in manifest["chapters"]}),
                             len({x["section"] for x in rows}))
            for lang in ("en", "zh"):
                config = json.loads((Path(temporary) / lang / "_quarto.yml").read_text(encoding="utf-8"))
                self.assertEqual(config["lang"], lang)
                files = list((Path(temporary) / lang).glob("*.qmd"))
                text = "\n".join(p.read_text(encoding="utf-8") for p in files)
                for row in rows:
                    self.assertEqual(text.count(f'data-example-id="{row["id"]}"'), 1)
                    self.assertIn("\n" + row["r"] + "\n", text)
                    self.assertIn("\n" + row["stata"] + "\n", text)
                self.assertEqual(set(manifest["examples"]), {x["id"] for x in rows})

    def test_variants_keep_qualifications_and_plain_code_visible_to_indexer(self):
        rows = [dict(id="a", command="tabulate", stata="tabulate x", r="tab(data, x)",
                     package="tidystata", task="Frequency", task_zh="频数", detail="",
                     detail_zh="", section="Explore", section_zh="探索"),
                dict(id="b", command="tabulate", stata="tabulate x, missing",
                     r="tab(data, x, .missing = TRUE)", package="tidystata",
                     task="Missing values", task_zh="缺失值", detail="Count missing values.",
                     detail_zh="统计缺失值。", section="Explore", section_zh="探索")]
        provenance = {x["id"]: dict(equivalence="qualified", approach="preferred",
                     validation="executed", source="https://www.stata.com/",
                     r_source="https://socimh.github.io/tidystata/") for x in rows}
        metadata = {"a": dict(priority=0, meaning="tab", preferred=True),
                    "b": dict(priority=1, meaning="tab", preferred=False)}
        text = reference.render_chapter(rows, provenance, metadata, "en", "Explore")
        self.assertLess(text.index('data-example-id="a"'), text.index("<details"))
        self.assertGreater(text.index('data-example-id="b"'), text.index("<details"))
        self.assertIn("Count missing values.", text)
        self.assertIn("```r\ntab(data, x, .missing = TRUE)\n```", text)
        self.assertIn("https://www.stata.com/", text)
        self.assertNotIn("# Explore", text)
        self.assertNotIn("status-badge", text)
        self.assertIn("[Stata]{.col-label}", text)
        self.assertIn("{.visually-hidden}`` tidystata ``]{.col-label}", text)
        self.assertIn("::: {.example-note .status-qualified}\n\n[Differs from Stata](index.qmd#example-labels", text)
        self.assertIn('){.caveat-tag} Count missing values.', text)

    def test_only_qualified_notes_carry_the_caveat_tag(self):
        row = dict(id="a", stata="sort x", r="arrange(data, x)", package="dplyr",
                   task="Sort", task_zh="排序", detail="Ties keep order.", detail_zh="")
        meta = dict(equivalence="equivalent", source="https://www.stata.com/",
                    r_source="https://dplyr.tidyverse.org/")
        self.assertNotIn("caveat-tag", reference.render_example(row, {"a": meta}, "en"))
        meta["equivalence"] = "qualified"
        self.assertIn("{.caveat-tag} Ties keep order.", reference.render_example(row, {"a": meta}, "en"))

    def test_leading_heading_is_dropped_once(self):
        self.assertEqual(reference.drop_heading("# Start\n\nBody\n\n# Next\n"), "Body\n\n# Next\n")
        self.assertEqual(reference.drop_heading("Body\n# Not first\n"), "Body\n# Not first\n")

    def test_distinct_default_meanings_remain_expanded(self):
        metadata = {"long": dict(priority=0, meaning="long", preferred=True),
                    "wide": dict(priority=0, meaning="wide", preferred=True),
                    "other": dict(priority=1, meaning="other", preferred=False)}
        selected = reference.visible_examples([{"id": k} for k in metadata], metadata)
        self.assertEqual([x["id"] for x in selected], ["long", "wide"])

    def test_slug_is_safe_and_deterministic(self):
        self.assertEqual(reference.slug("Files and import/export"), "files-and-import-export")
        self.assertEqual(reference.slug("Panel and time series"), "panel-and-time-series")


if __name__ == "__main__":
    unittest.main()
