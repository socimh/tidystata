# 03-generated-and-results-files.md

## Source-of-truth rule

* Never manually edit generated files or result artifacts unless explicitly asked.
* Fix the source, then regenerate the output.

## R package generated files

* If docs are generated from roxygen, do not hand-edit `man/*.Rd` or `NAMESPACE`.
* Update source comments and regenerate docs instead.

## Result artifacts

* Do not patch derived outputs just to make them look correct.
* Avoid manual edits to generated directories such as `results/`, `output/`, `tables/`, `figures/`, `cache/`, or similar.
* Avoid manual edits to generated `.csv`, `.tsv`, `.xlsx`, `.rds`, `.RData`, snapshots, or benchmark outputs when they are derived from scripts/functions.

## When uncertain

* If unclear whether a file is generated, inspect how it is produced.
* Prefer the source-first path.

## Final output

After editing:

1. list files changed
2. summarize what rules were added
3. do not edit unrelated files
