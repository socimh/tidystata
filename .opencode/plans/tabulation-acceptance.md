# Tabulation acceptance implementation plan

> For agentic workers: execute the test-first checks below and preserve evidence.

**Goal:** Review tab/tab1/tab2 and fre/fre1/fre2 as the next function family after summaries.
**Architecture:** Keep public APIs and existing tests. Use three paired 100-case matrices with independent base-R/manual oracles, plus targeted regressions for reproduced defects. Existing code remains authoritative for documented presentation policies, not numeric correctness.
**Tech stack:** R/testthat, protected Windows R launcher, isolated native build, Python reporting.
**Spec:** Maintainer request to proceed function by function; DEVELOPMENT.md and existing tabulation help; approved list-identity and empty-selection policies.

## Constraints
- Work in D:/R/statart on the existing development branch; preserve all files/artifacts.
- No push, merge, release, new dependencies or exports.
- All R execution uses the protected launcher with child LC_ALL/LANG=C.
- Generated help/reports/index must come from inspected source scripts.
- Acceptance is local Windows R 4.6.0 evidence, not a universal correctness claim.

## Review focus
- Counts and missing-value denominators, including missing grouping keys.
- Explicit grouping overrides and inherited grouping must not leak unwanted columns.
- List identities and classed values must preserve counts and input data.
- Reserved names, category labels and empty selections must follow documented boundaries.
- Marginal/subtotal rows must not overwrite observed categories.

## Tasks
- [x] Read guidance, source, tracking, existing tests and verify clean working tree.
- [x] Add 100 numbered cases each for tab/fre (joint), tab1/fre1 (one-way), tab2/fre2 (cross); QA delegates own joint/cross test files.
- [x] Run cases against baseline; reproduce any failures and trace causes before minimal fixes.
- [x] Verify regressions and retained tabulation suite, explicitly asserting expected warnings.
- [x] Update source documentation for behavior changes and regenerate shared help.
- [x] Generate standalone real-output acceptance evidence and readable case catalogue.
- [x] Run fresh full package suite/build/check and independent final validation.
- [x] Update status/problem/task/progress/report index, inspect staged files and commit locally.

## Execution ledger
- Starting HEAD e09dafe; worktree clean. Prior summary results retained.
- Baseline joint057 and one-way058 fail for inherited grouping leakage; four empty-.by regressions also fail before the fix. Label-free tagged missing conversion reproduces haven na_tag(NULL) failure.
- Corrected fixture/oracle assumptions separately: NULL ordering, SPSS raw identity and cross missing-name rendering. Frequency float-label ambiguity remains documented presentation, not merged counts.
- Green fresh installed acceptance: 897 blocks/8258 expectations; numbered600/7547. Full suite2274/14255 with22warnings/1oldskip elsewhere; install/build/check launcher0 and Status OK.
- Narrowly assert known Windows C-locale native-encoding diagnostics; no locale mutation or broad renaming refactor. Other warnings remain visible.
- Final independent review: no material issues; added empty-.by coverage and removed the temporary source-overlay path from the final runner. Input files match the fresh checked source.
- Generated the evidence catalogue and refreshed tracking/index; local commit follows reviewed staging. No external action.
