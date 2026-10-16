# Problems and issues

## Current verified state (2026-10-16)

The complete suite passes: 16,213 expectations, zero failures/errors, 15 test
warnings and one skipped block across 2,996 blocks. Fresh installation/build
and R CMD check --no-manual pass with Status: OK. Earlier required-dependency
smoke evidence remains valid; dependencies and exports did not change.
See [codebook/browse acceptance and current evidence](reports/project_status_codebook_browse_acceptance_2026-10-16.md). The previous
[summary catalogue](reports/project_status_summ_tabstat_100_scenarios_2026-10-16.md) remains valid.

summ() and tabstat() are locally accepted release candidates: 342 blocks and
1,224 expectations with zero failures/errors/warnings/skips. Fixed SPSS missing
masks, reserved grouping/measured names, grouped .by override, compact datetime
formatting, empty .name behavior and the approved counts-only nonnumeric policy.
Large integer64 conversion warnings are now visible. The standalone runner
passes 286 scenarios and 1,158 expectations, including all 100 numbered cases for each function; independent review found no remaining
material defects in the reviewed summary scope. This coverage expansion changed no package behavior; finite tests do not prove every possible input/platform.

## Codebook and browse acceptance resolved (2026-10-16)

- codebook and browse pass 100 numbered scenarios each: 200 cases/817 expectations. All acceptance, retained inventory/browse and shared-selector checks pass: 297 blocks/985 expectations, zero failures/errors/uncaptured warnings/skips.
- codebook now inventories grouped/rowwise input globally, excluding unselected group keys. SPSS user-missing values and scalar missing list elements use the same mask for n/unique. Matrices/nested data frames count complete observed rows, not cells. Per-column processing handles Unicode names; duplicate/empty/missing selected names remain errors.
- s_select returns the first successful operation without unnecessary probing/reruns, preserves successful warnings once and retains both failure diagnostics. A failed selection can still execute user code before fallback; precompute random/side-effecting columns with mutate. Separate selector/type acceptance remains ahead.
- browse returns selected data invisibly; help is corrected. Headless behavior and stubbed viewer forwarding/errors pass, but actual GUI rendering is not verified. The approved console PDF is unchanged.
- Four fixture-only naming warnings removed. Source help regenerated in isolation and examples pass. Independent QA found no material remaining issue; current R/tests/help match the final fresh source. Next: conversion helpers.

## Names and metadata acceptance resolved (2026-10-16)

- ds, ds_as_column, names_as_column, variables and variables_search each pass 100 numbered scenarios (500 executions/1084 expectations). All inspection acceptance plus retained names tests pass: 548 blocks/1169 expectations, zero failures/errors/uncaptured warnings/skips.
- variables_search now requires one non-missing character query; zero-length/vector/NA/noncharacter queries error clearly, and the empty string still matches all selected variables. Substring, case-insensitive label/name matching, wildcards and anchors remain unchanged.
- Valid letter ranges no longer trigger numeric conversion warnings in the shared translator; independent ds/s_match and variables_search regressions reproduce the old warning and pass after the fix.
- No behavior fixes were required for the three names helpers or variables. Grouping-key retention, tidyselect-only existing-column inputs and conditional label columns are documented. Two unnamed-matrix fixtures no longer emit incidental warnings.
- Source help regenerated in isolation; current R/tests/help match the fresh verification copy byte-for-byte. Independent review found no material remaining issue. The later conversion/row/binning/selector/utility families still need acceptance; minimum-R/other-platform gates remain.

## Tabulation acceptance resolved (2026-10-16)

- tab, tab1, tab2, fre, fre1 and fre2 each pass 100 numbered scenarios. All retained tabulation tests plus shared conversion regressions pass: 897 blocks/8258 expectations, zero failures/errors/uncaptured warnings/skips.
- Explicit .by now replaces inherited grouping, including empty selections; missing keys and within-group denominators are preserved. A labelled vector without value labels no longer breaks frequency rendering when it contains tagged missing values.
- Five unnamed-matrix fixtures now explicitly allow minimal names before assigning their intended names, eliminating five fixture-only warnings.
- Frequency display labels may coincide for distinct original values or synthetic totals. Rows/counts remain separate; use tab/tab1 for original types. Identify fre2 marginal totals by final row position.
- Some non-ASCII column names under Windows LC_CTYPE=C emit native-encoding warnings from R/dplyr. Tests narrowly assert those diagnostics and verify names/counts; this limitation remains. Other warning types stay visible. UTF-8 locales and other platforms remain unverified.
- Independent review found no material remaining defects in this scope. Local acceptance does not imply universal input/platform correctness or permission to publish.

## Repository organization resolved (2026-10-16)

- Six historical scripts/release notes are preserved in extra_functions/development-history. The interactive Build_Package.R scratchpad is absent from the new source tarball; the archive is build-excluded.
- make clean now removes no files. All prior artifacts remain preserved. See [cleanup verification](reports/project_status_cleanup_2026-10-16.md).
- Older esttab tooling/duplicate notes remain historical. Optional generated-artifact deletion is deferred pending an exact approved list.

## Remaining follow-up

- The new [ten-page codebook/browse PDF](reports/project_status_codebook_browse_pdf_2026-10-16.md) shows current outputs and scripts for maintainer review. All ten sections execute cleanly and all pages are visually checked; package behavior is unchanged.
- The maintainer approved the selective [console showcase](reports/project_status_console_showcase_2026-10-16.md). Its appearance is preserved; no output redesign is pending.
- Replace the empty cut_length interval-width test; its skip is missing coverage.
- Capture remaining intentional warning paths explicitly and repair legacy matrix-name fixtures outside summaries. The accepted summary, tabulation and inspection checks now have no uncaptured warnings. Test warnings are separate from package-check warnings (zero).
- Verify the declared R 4.1 minimum and other platforms before publishing; manually validate interactive viewer rendering.
- Combined-header and literal-NA/missing-category cross-table collisions error explicitly; fre2 column category total must be recoded. An observed row label total remains alongside the final marginal row; callers should distinguish the final row.
- Four regenerated README console lines retain pillar trailing spaces; no generated output was manually patched.

## Historical status (superseded by current verification)

### Latest test-only stabilization

Fresh full suite: **five failed expectations, ten error blocks, 33 warnings, one skip**, with 5,357 passing expectations across 1,358 blocks. All remaining failure/error identities were present in the previous baseline. See [current evidence](reports/project_status_test_stabilization_2026-10-16.md).

### Historical baseline after first milestone

Full retained suite: **94 failed expectations, 22 error blocks, 54 warnings,
one skip**, with 5,129 passing expectations across 1,358 blocks. These are
different counting units. No unexplained new failure identities relative to the
original baseline were found. See [milestone status](reports/milestone_status_0.2.0.9000.md).

R CMD check passes every non-test stage and ends with one ERROR at tests.
This is not release-ready. The 622 targeted milestone scenarios all pass.

| Area | Next action |
| --- | --- |
| Invalid fixtures | Correct labelled_spss construction, incompatible tibble lengths, sampling, and other fixture errors separately from source changes. |
| Summary/date contracts | Resolve unsupported statistics, all-missing/empty summaries, and date output contracts. |
| Cross-tabulation | Many tests incorrectly assume an extra n column; independently settle shape and category-name collision behavior before changing code. |
| Names, types and utilities | Review remaining browse/names/s_type/s_try/timer discrepancies and selector evaluation. |
| Compatibility | Exercise the minimum R version and multiple platforms; current validation used R 4.6.0 on Windows. |
| Git history | Resolved 2026-10-15: fetched socimh/statart and established master tracking origin/master; all 537 existing file hashes preserved. |

### Stabilization triage (2026-10-16)

The [complete saved-failure inventory](reports/project_status_failure_triage_2026-10-16.md)
accounts for all 104 failing/erroring identities. Eleven fixtures fail before
statart is reached; 77 identities have incorrect expectations. Seven likely
implementation defects need focused reproduction, eight need explicit behavior
decisions, and one is a reproduced environmental timing flake. Those classifications are historical. The 2026-10-16 test-only pass repaired the invalid fixtures and incorrect expectations, retaining the source defects and unresolved contracts.

Git setup and comparison are complete. NEWS/MIGRATION now document the full
upstream API transition. The artifact allowlist retains selected evidence while
preserving other generated results locally. The earlier tracked-only comparison had 26 whitespace findings; the full staged
checkpoint also exposes whitespace in newly included historical files (895 findings
before excluding four scratch files). This preparation pass does not reformat
existing code or generated reports. The full suite and package check remain failing.

### First milestone resolved

- Four isolated wrappers retired with source/tests/help/demo preserved outside builds.
- Required Imports reduced to 13; optional formatting no longer affects default result types.
- Character conversion preserves length, values, missing positions and parser diagnostics.
- Variable labels extracted directly, with attribute-label search corrected.
- Grouped tab1/fre1 retain keys, including missing/reserved keys, and calculate group totals correctly.
- Row helpers return atomic vectors, ignore missing values appropriately, preserve inputs,
  and accept selected or computed dataframes inside mutate.
- Quantile bins keep equal values together and report collapsed cutpoints.
- Test/demo commands use protected fresh builds, propagate failures and preserve historical reports.

The SAS export mismatch and estimation-table issues now belong to archived
unsupported code, not the active package. Import/export, PCA and regression
extensions are outside the chosen core scope.

### Historical resolutions before scope reduction

The following notes are historical claims and do not override the current test baseline.

### Resolved Issues ✓

#### Summary Statistics (summ) - All Fixed v0.2.x

| ID | Resolution |
|----|------------|
| 3.1 | Inf/-Inf now shown in min/max correctly |
| 3.2 | Dates/datetimes now formatted as strings |
| 3.3 | as_numeric() called once per var; faster |
| 3.4 | Added .na.rm arg (default FALSE) |
| 3.5 | Added .name arg (default TRUE) |

#### Tabulation (tab, tab1, fre) - All Fixed v0.2.x

| ID | Resolution |
|----|------------|
| 2.1 | tab1()/fre1() now support expressions |
| 2.2 | fre() ~10x faster (add_total rewritten) |
| 2.3 | Missing values at bottom of each group |
| 2.4 | .n renaming documented (known behaviour) |
| 2.5 | .desc now sorts non-NA desc, NA last |

#### Helper Functions - All Fixed v0.2.x

| ID | Resolution |
|----|------------|
| 4.1 | cut_quantile() rank-based fallback for ties |
| 4.2 | row_min/max/mean/sum return plain vectors |
| 4.3 | codebook() Hmisc warning suppressed |

#### Feature Requests - Fixed

| Feature | Resolution |
|---------|------------|
| timer() output | Compact format: 1m5s, 0.05s |
| s_select errors | Shows exact column name + both error messages |

#### Estimation Tables (esttab) - All Fixed v0.2.0

| ID | Version | Resolution |
|----|---------|------------|
| 1.1 | v0.2.0 | lmer p-value fallback |
| 1.2 | v0.2.0 | Graceful broom errors |
| 1.3 | v0.2.0 | glue-style format arg |
| 1.4 | v0.2.0 | stats arg with Stata aliases |
| 1.5 | v0.2.0 | Simplified output |

#### Visualization (s_plot) - Moved to extra_functions/
