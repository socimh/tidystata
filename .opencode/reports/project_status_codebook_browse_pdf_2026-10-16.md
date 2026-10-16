# Codebook and browse console PDF

Created 2026-10-16, statart 0.2.0.9000, Windows R 4.6.0.

[Open the ten-page PDF](../results/codebook-browse-showcase/statart_codebook_browse_console.pdf)

Ten selected examples show setup, default inventory, selected/renamed/computed columns,
SPSS/list missingness, structured/empty columns, grouped inventory, browse visibility,
browse in a pipeline, s_select and a dictionary-driven summary/CSV workflow.

Canonical authoring source: [build_codebook_browse_pdf.py](../workflows/build_codebook_browse_pdf.py).
Generated R input: [showcase_codebook_browse.R](../demos/showcase_codebook_browse.R).
Style is reused from the previously approved four-page showcase; that PDF is unchanged.

Protected execution: exit0, ten sections, no unexpected warnings/messages.
Counts, uniqueness, browse visibility, pipeline rows, selected variables and exported CSV
readback are asserted. PDF text checks require ten pages with complete input/output panels;
all rendered pages are visually reviewed for spacing, glyphs, clipping and legibility.

Console output is actual plain text. Headless browse opens no viewer; assigned returns
are explicitly printed. This is not a GUI screenshot or real viewer validation.
No package functions, dependencies, exports or accepted test results changed.

Regenerate with `python .opencode/workflows/build_codebook_browse_pdf.py` after the fresh
library is available in codebook-browse-accepted-paths.json. `--render-only` reuses captures.
Intermediate captures, Typst source, PNGs and execution logs remain preserved locally.
