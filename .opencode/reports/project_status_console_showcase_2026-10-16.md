# Selective console showcase

Created 2026-10-16 for visual review; package 0.2.0.9000.

[Open the four-page PDF](../results/console-showcase/statart_console_showcase.pdf)

The PDF shows a shared fictional survey, summ/tabstat numeric summaries,
tab and fre2 category tables, and a joined respondent-level pipeline with CSV export.
Examples are selective; this is not an exhaustive function catalogue.

Input source: [.opencode/demos/showcase_console.R](../demos/showcase_console.R).
Canonical authoring source: [build_console_showcase.py](../workflows/build_console_showcase.py).
The R script is generated from the authoring source. Edit that source, then regenerate.

Verification: protected R launcher exit0; all four sections execute without unexpected
warnings/messages. The join preserves eight rows, regional counts/means are independently
asserted, and exported CSV values/shape are verified after readback.
The PDF has four pages, input/output panels stay together, text extraction passes,
and all four rendered pages were visually reviewed for clipping, spacing and legibility.

No package functions, dependencies, exports or previous test results changed.
The accepted package baseline remains 14255 passing expectations, 22 unrelated warnings,
one existing empty skip, and R CMD check Status OK. No new full-suite claim is made.

Regenerate with `python .opencode/workflows/build_console_showcase.py` after
creating the fresh installed library using verify_package.py with prefix
`.opencode/results/tabulation-accepted`. Rendering only can use `--render-only`.
Generated console captures, Typst source, PNGs and logs remain preserved locally.
