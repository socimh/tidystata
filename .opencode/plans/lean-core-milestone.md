# Lean core milestone

Approved in conversation on 2026-10-15. Implement locally; no push or release.

## Contract

- Retire only read_data, write_data, esttab, and codebook_detail. Preserve their
  code, dedicated tests/demos/help in extra_functions; exclude the archive from
  builds and active discovery. Keep all other helper exports and datasets.
- Version 0.2.0.9000; 13 Imports: magrittr, tidyselect, dplyr >= 1.1.0, tidyr,
  tibble, stringr, vctrs, rlang, haven, purrr, pillar, readr, Rfast. Keep cpp11.
- fre/fre2 default to tibbles; fre1 defaults to a list. Explicit flextable is
  optional, with an actionable error if unavailable and no silent fallback.
- Extract variable label attributes directly; preserve conditional label-column
  omission and make variables_search search labels from the result metadata.
- Fix character as_numeric parsing and length preservation; retain supported
  factor, labelled, date/time, and logical conversion semantics.
- Preserve tab1/fre1 group keys and compute percentages/totals per group. Missing
  keys are groups; only measured-variable missingness affects valid percentages.
- All row helpers return atomic vectors with one entry per input row. Keep the
  C++/Rfast backend. Ignore NA/NaN in numeric summaries; all-missing gives NA except
  sum=0. Sample variance/SD needs two observations. Unique counts missing once.
  Zero rows return empty vectors; NULL/zero columns error. Do not mutate input.
- Quantile bins use unique type-7 cutpoints, keep ties together, warn when
  cutpoints collapse, and preserve missing positions. Constant/empty/all-missing
  inputs and invalid n error. Labels match effective intervals; labels=FALSE
  retains base cut's integer-code convention.
- Regenerate source-derived help, namespace, README, and report index. Archive
  historical generated documents before replacements. Update development notes.

## Verification

Write and observe priority regressions fail first. Fresh native build, focused
tests, minimal dependency smoke test, optional formatting test, built-package
contents, full retained suite, and R CMD check follow implementation. Meet local
20-scenario function report rules. Targeted tests must pass; classify every new
full-suite failure against the baseline. Existing unrelated failures may remain
for milestone two and must be reported explicitly.

## Execution ledger

- Preflight: no Git metadata; use a source snapshot and isolated build copies.
  Snapshot: `%TEMP%/statart-milestone-before-idqqdd4s` (397 file hashes).
- Shared interfaces: metadata/archive edits precede namespace regeneration;
  tab/fre use grouping helpers, conversion and formatting; row wrappers share
  input validation and native registrations. Keep those interfaces coordinated.
- Baseline: prior fresh build had 1,046 passing expectations, 134 failed
  expectations, 38 error blocks, 59 warnings, and one skip over 789 blocks.
- Task 1: complete. Retired sources/tests/demos/help preserved; 13 Imports and
  40 exports verified; archive and development files excluded from built package.
- Task 2: complete. Grouping, label extraction/search and optional formatting
  covered by the focused scenario suite and required-dependencies-only smoke.
- Task 3: complete. Conversion and tie probes observed RED then GREEN; fresh
  native build verifies row shapes, missingness, and input preservation.
- Task 4: focused verification complete: 622 scenarios, 4,098 expectations,
  zero failures/errors/warnings/skips. Full suite and R CMD check run; package
  installation, dependencies, help, compiled code and examples pass. Remaining
  baseline failures are recorded rather than labelled a clean release check.
- Final review: independent r-release-auditor found two important regressions.
  Both were reproduced RED and fixed GREEN: combined output reserves the
  `variable` grouping key; row dispatch accepts general dataframe expressions
  inside mutate and evaluates dataframe producers once. Review regression file
  passes; full retained suite after fixes has no unexplained new failure identities (one unchanged timing fixture is flaky).
- Ruling: build/test in temporary copies instead of a Git worktree because this
  checkout has no Git metadata. Original data/DLL/object hashes are unchanged;
  commits, pushes, publication and release remain outside this task.
- Ruling: preserve usable infinite quantile boundaries from prior behavior;
  reject only unusable cutpoints, invalid counts and empty/all-missing/constant
  inputs. This avoids an unrequested restriction on otherwise valid inputs.
- Environment: child-process LC_ALL=C resolves unsupported inherited C.UTF-8
  locale warnings during R CMD check. Machine/startup configuration is unchanged.
