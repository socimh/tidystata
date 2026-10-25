"""Stata highlighting assigns the same role to the same syntax everywhere."""
from pathlib import Path
import sys
import unittest

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
import highlight
import reference

ROOT = Path(__file__).resolve().parents[2]


def tagged(code):
    return ["".join(t if c is None else f"[{c}:{t}]" for c, t in line)
            for line in highlight.stata_spans(code.split("\n"))]


class HighlightTests(unittest.TestCase):
    def test_roles(self):
        self.assertEqual(tagged("bysort g (t): generate y = x[_n-1]"),
                         ["[kw:bysort] g (t): [kw:generate] y = x[_n-[dv:1]]"])
        self.assertEqual(tagged('merge 1:1 id using "a.dta", keep(match)'),
                         ['[kw:merge] [dv:1]:[dv:1] id [qu:using] [st:"a.dta"], [fu:keep](match)'])
        self.assertEqual(tagged("quietly estat hettest, rhs"),
                         ["[kw:quietly] [kw:estat] [kw:hettest], [fu:rhs]"])
        self.assertEqual(tagged("twoway (scatter y x, mcolor(red)) || lfit y x"),
                         ["[kw:twoway] ([kw:scatter] y x, [fu:mcolor](red)) || [kw:lfit] y x"])
        self.assertEqual(tagged("foreach v of varlist x {\n  replace `v' = 0 // zero\n}"),
                         ["[kw:foreach] v of varlist x {",
                          "  [kw:replace] [mc:`v'] = [dv:0] [co:// zero]", "}"])

    def test_every_catalogue_example_keeps_text_and_starts_with_a_command(self):
        for row in reference.read_csv(ROOT / "inst/extdata/stata-to-r.csv"):
            lines = row["stata"].split("\n")
            spans = highlight.stata_spans(lines)
            self.assertEqual(["".join(t for _, t in line) for line in spans], lines)
            first = next(c for c, t in spans[0] if not t.isspace())
            self.assertEqual(first, "kw", row["stata"])

    def test_rendered_lines_keep_anchors(self):
        page = ('<pre class="sourceCode stata code-with-copy"><code class="sourceCode stata">'
                '<span id="cb1-1"><a href="#cb1-1" aria-hidden="true" tabindex="-1"></a>'
                '<span class="fu">y</span> &amp; x</span></code></pre>')
        self.assertIn('<a href="#cb1-1" aria-hidden="true" tabindex="-1"></a><span class="kw">y</span> &amp; x</span>',
                      highlight.rehighlight(page))


if __name__ == "__main__":
    unittest.main()
