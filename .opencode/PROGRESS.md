# Progress Log

Last 3 entries only. Full history: .opencode/PROGRESS_ARCHIVE.md

## 2026-10-16 - Selective Console PDF for Review
- **Changes**: Built a four-page PDF with fictional input data, summ/tabstat, tab/fre2 console output and a joined research pipeline with CSV export. Kept the showcase selective per maintainer clarification. Saved the canonical builder and generated runnable R input script; preserved captures, rendering sources and PNGs locally.
- **Verification**: Protected R launcher exit0; four sections execute without unexpected warnings/messages. Regional means/counts and eight-row preservation asserted; CSV values/shape pass readback. Four-page PDF text checks pass and all rendered pages visually reviewed. Package logic unchanged; prior accepted test/check baseline remains valid without a new full-suite claim.
- **Next**: Maintainer reviews appearance before output changes. Updated status, task, problem and report-index records. No push, merge, release or artifact deletion.

## 2026-10-16 - Tabulation Acceptance Complete
- **Changes**: Added 100 numbered scenarios each for tab/fre, tab1/fre1 and tab2/fre2 (600 executions); preserved all previous coverage. Fixed explicit grouping overrides, including empty .by, and character conversion of label-free tagged missing values. Corrected five unnamed-matrix fixtures. Regenerated source-based help and documented denominators and display/locale limits.
- **Verification**: All tabulation/shared conversion regressions: 897 blocks/8258 passing expectations, zero failures/errors/uncaptured warnings/skips. Numbered cases: 600 executions/7547 expectations. Fresh full suite: 2274 blocks/14255 passes, zero failures/errors, 22 warnings and one pre-existing empty cut skip elsewhere. Protected native install/build/check exit0; R CMD check Status OK. Standalone installed runner passes and captures real output.
- **Review/scope**: Independent QA and final review found no material remaining defects; 60 R/test files match fresh verification source byte-for-byte. Frequency labels may coincide while counts remain separate; Windows C-locale non-ASCII name diagnostics are narrowly asserted and documented. Summary acceptance retained. Next: variable inspection. No dependencies/exports/data/native artifacts changed; no push, merge, release or deletion.

## 2026-10-16 - 100 Scenarios for Each Summary Function
- **Changes**: Added 100 numbered scenario definitions, independently exercised through summ and tabstat (200 new blocks), preserving all previous tests. Added a readable per-case catalogue and enforced IDs 001-100 in the standalone runner. Independent review replaced an overlapping logical case and added exact tiny-value checks; fixtures use portable Unicode escapes.
- **Verification**: Numbered matrix: 200 executions/770 expectations. Standalone: 286 scenarios/1158 expectations. All summary tests: 342 blocks/1224 expectations with zero failures/errors/warnings/skips. Fresh full suite: 1668 blocks/6692 passes, zero failures/errors, 27 warnings and one pre-existing empty skip elsewhere. Protected install/build/check exit0; R CMD check Status OK.
- **Scope**: No production behavior, exports, dependencies, datasets or native artifacts changed. Both functions remain locally accepted release candidates; minimum-R/other-platform validation remains. No push, merge, release or artifact deletion.
