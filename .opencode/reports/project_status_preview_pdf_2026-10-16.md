# Persistent preview console PDF

[Open the ten-page PDF](../results/preview-showcase/statart_preview_console.pdf)

Ten selected pages pair executable R inputs with actual current console output.
Topics: default head/tail, intervals, editing, tabulation, summaries, pivots,
joins, one-time printing, real slicing, and removing/overriding the preview.

Canonical authoring source: .opencode/workflows/build_preview_pdf.py.
Generated input: .opencode/demos/showcase_previews.R.
Protected R execution exited zero; all ten sections passed assertions for
row preservation, counts, subsets and persistent class behavior, without
unexpected warnings or messages. Text checks confirm ten complete pages.
Rendered pages are visually inspected before delivery.

Package code and existing PDFs are unchanged. Package-wide acceptance remains
3,106 blocks/16,992 expectations and R CMD check Status: OK from the prior task.
This task verifies the showcase; it does not rerun or expand the full suite.

Regenerate: python .opencode/workflows/build_preview_pdf.py.
Uses the verified installation referenced by preview-final-paths.json.
Intermediate captures, rendered pages and logs remain preserved locally.
