# Codebook and browse acceptance

Goal: finish variable inspection with codebook() and browse(), preserving approved console presentation and all existing work. Starting HEAD73adb15; worktree clean.

- [x] Read AGENTS/DEVELOPMENT/current source/tests and scope next two functions.
- [x] Add 100 numbered meaningful cases per function, plus targeted defect regressions.
- [x] Reproduce grouped/SPSS/structured-column counts and shared-selector evaluation issues before minimal fixes.
- [x] Document exact outputs, missing-value/structured-column semantics, grouping and headless browsing; regenerate only relevant help in isolation.
- [x] Run fresh installed acceptance, full suite/build/check, and independent final validation.
- [x] Generate actual-output catalogue; update status/problem/task/progress/index and commit locally.

Constraints: protected launcher for all R, child LC_ALL/LANG=C. No dependencies/exports added, unrelated fixes, artifact deletion, push/merge/release. codebook is a whole-dataset inventory: ignore row grouping before selection; structured columns count complete observed rows, not cells. SPSS user missing excluded from count and uniques. List identities follow existing is.na semantics. Browse viewer behavior can be stubbed for delivery checks but must not be described as actual GUI validation.

Execution ledger:
- Baseline regressions reproduced grouped errors, SPSS/list unique contamination, structured-cell n counts and selector callbacks evaluated three times. Cached successful branches and common original-value masks fix those causes; baseline error/name checks remain preserved.
- Codebook implementation reviewed before mapping change. Structured columns count complete rows, list NULL/empty identities remain present, and grouped inventory is global. Mis-entered matrix fixture corrected to its intended three complete rows.
- Fresh installed acceptance: 297 blocks/985 expectations, including 200 numbered scenarios/817 expectations; zero failures/errors/uncaptured warnings/skips. Source parsing and actual-output examples pass; 97 R/test/help files match the fresh source.
- Direct warning replay/discard/error and select-first side-effect boundaries are tested. Failed selection can still execute callbacks before fallback; docs recommend precomputation for randomness/side effects. No actual GUI rendering claim.
- Independent final QA found no material issue; isolated help generation/examples pass. Four fixture-only warnings removed. Full check remains in progress.
- Final full suite: 2996 blocks/16213 passes, zero failures/errors, 15 warnings and one old skip elsewhere. Check launcher exit 0; Status OK with no check errors/warnings/notes. Catalogue/tracking updated; local commit follows reviewed staging.
