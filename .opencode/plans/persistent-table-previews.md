# Persistent table previews

Approved specification: opt-in preview_table(.data, style = c("headtail", "interval"), n = 10), unpreview_table(.data), and restoration of print_headtail, print_interval, slice_headtail, slice_interval. Full data remains stored; default first five and last five; n is a total positive integer or Inf; odd head gets extra row; interval n=1 selects first. Short tables never duplicate.

Support plain data frames and ordinary/grouped/rowwise tibbles. Preserve display settings through base table edits, common dplyr verbs, grouping, summaries, joins (left settings), bind_rows (first settings), and both tidyr pivots. Explicit tibble/data.frame conversion removes settings. Lists, lazy tables and unsupported container subclasses need explicit conversion/mapping.

Use public pillar formatting and valid display views; report full dimensions separately. No stored row positions, no data coercion for display. Keep archived source intact; active implementation in R/special-print.R. Restore old one-time printers with invisible original returns and real subset helpers.

## Execution ledger

- Baseline: f1c5ee4; clean test/stabilize-fixtures branch. Existing in-place development workflow retained as explicitly requested for D:/R/statart.
- Reviewed source, constructor, pillar and dplyr extension contracts. QA reviewer independently designing tests.
- Pending: RED tests; implementation; focused tests; docs/demo; full verification; final review; local commit.
- Ruling: retain all intermediate artifacts, overriding skill cleanup advice, per repository preservation rules.

- RED: absent API; then grouped rename, pivot selector scope, footer width/limit/n=1, and duplicate/empty-name printing failures reproduced through protected R.
- Implemented all six public functions, valid display views, qualified S3 registration, preservation methods and explicit conversion boundaries.
- Focused source and installed verification: 27 blocks/318 expectations, zero issues. 96-file Air/parse/lintr checks pass. Twelve demos and required-only smoke pass.
- Review: public hooks require tibble >=3.1.0 and pillar >=1.8.0; declared both without adding dependencies. Default summary/tabulation output remains unchanged.
- Ruling: use exported new_pillar_shaft_simple() for row positions, avoiding internal pillar shaft classes; no custom shaft is needed.
- Full suite/build/check running; final tracking/report/commit pending.

- Full suite: protected exit 0; 3,106 blocks/16,992 expectations, zero failures/errors/warnings/skips. Final check has passed all non-test stages and is finishing tests.
- Documentation report: eight examples, nine executable input blocks and eight console blocks; fixed and verified pre-existing report trim bug that removed literal trailing t.
- Preservation: 112 package/test/help files match the fresh checked source; tarball includes final new code/tests/help/namespace/NEWS and both dependency floors. Archive and existing PDFs unchanged.

- Final: R CMD check protected exit 0, Status: OK. Acceptance report generated from passing logs/CSV; tracking updated; final diff/local commit next.

- Final independent release-auditor review: no material remaining findings; counts, registration, API floors and documented limits agree. All planned implementation/verification/documentation work complete; local checkpoint records this ledger.
