# Progress Log

Last 3 entries only. Full history: .opencode/PROGRESS_ARCHIVE.md

## 2026-10-16 - Ten-Page Persistent Preview PDF
- **Changes**: Added a canonical Python showcase builder, generated R scripts and a ten-page PDF using the approved console-panel style. Selected examples cover both preview styles, data edits, tabulation, summaries, pivots, joins, one-time printers, actual subsets, overrides and removal.
- **Verification**: Protected R exit zero; ten sections run without unexpected diagnostics, with full-row/count/class/subset assertions. Ten PDF pages have complete input/output panels, no replacement glyphs, and visual inspection of every page. Existing PDFs and package code are unchanged; prior full-suite results are not rerun or expanded.
- **Next**: Maintainer reviews the PDF. Intermediate captures/renders remain preserved; local commit only, no publication.

## 2026-10-16 - Persistent Table Previews
- **Changes**: Added opt-in preview_table/unpreview_table and restored four print/slice helpers. Complete data retains a preview policy through supported base/dplyr/tidyr pipelines. Added public pillar formatting, accurate current row positions, explicit conversion boundaries, 46 exports and tibble >=3.1.0/pillar >=1.8.0 API floors; Imports remain 12. Original archived source and PDFs preserved.
- **Verification**: New 27 blocks/318 expectations and full 3,106 blocks/16,992 expectations pass with zero failures/errors/uncaptured warnings/skips. Fresh installed dispatch, native install/source build/R CMD check Status OK, required-only smoke, twelve demos and 96-file style checks pass. All 112 package/test/help files match checked source; tarball contains final code/tests/help/registration/NEWS/dependency floors. Eight selective examples include scripts and console output.
- **Review/limits**: Independent QA/review found grouped rename, pivot selector, footer, duplicate-name and dependency-floor issues; all fixed with failing/passing regression evidence. Fixed report trimming that removed literal trailing t. Minimum R/dependencies and other platforms remain unverified; console formatting does not target GUI/HTML. Local commit only; no push, merge or release.

## 2026-10-16 - Row Types and Stable Native Statistics
- **Changes**: Preserved common logical/integer/classed extrema and exact integer64 identities; retained meaningful calendar/duration/physical-unit arithmetic with explicit incompatible/scale errors. Applied original SPSS masks and guarded missingness/order metadata. Added stable cpp11 median/variance/SD kernels, regenerated registrations/help and removed unused Rfast (12 Imports; required-only graph 33 including statart). Added 26 contract blocks/185 expectations and selective console examples.
- **Verification**: Fresh full 3,079 blocks/16,674 expectations, zero failures/errors/uncaptured warnings/skips; native install/build/R CMD check Status OK. Required-only smoke, eleven demos, 92 style/parse/lint files and three Python workflow tests pass. 109 source/package files match checked copy, tarball has final row help/dependency fields, 40 interfaces/24 representative outputs remain compatible, both PDFs unchanged. Observed RED tests before type, metadata and numerical fixes.
- **Review/limits**: Independent QA/review found and resolved SPSS metadata and ordered-factor coercion hazards. Actual R4.1/other-platform/compiler and oldest dependency validation remain pending. No artifact deletion or external publication action; local checkpoint only.
