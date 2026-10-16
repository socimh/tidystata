# Problems and issues

## Current verified state (2026-10-16)

The complete suite passes: 5,922 expectations, zero failures/errors, 27 test
warnings and one skipped block across 1,468 blocks. Fresh installation/build
and R CMD check --no-manual pass with Status: OK. Earlier required-dependency
smoke evidence remains valid; dependencies and exports did not change.
See [summary acceptance evidence](reports/project_status_summ_tabstat_acceptance_2026-10-16.md).

summ() and tabstat() are locally accepted release candidates: 142 blocks and
454 expectations with zero failures/errors/warnings/skips. Fixed SPSS missing
masks, reserved grouping/measured names, grouped .by override, compact datetime
formatting, empty .name behavior and the approved counts-only nonnumeric policy.
Large integer64 conversion warnings are now visible. The standalone runner
passes 86 scenarios and 388 expectations; independent review found no remaining
material defects in the reviewed summary scope.

## Repository organization resolved (2026-10-16)

- Six historical scripts/release notes are preserved in extra_functions/development-history. The interactive Build_Package.R scratchpad is absent from the new source tarball; the archive is build-excluded.
- make clean now removes no files. All prior artifacts remain preserved. See [cleanup verification](reports/project_status_cleanup_2026-10-16.md).
- Older esttab tooling/duplicate notes remain historical. Optional generated-artifact deletion is deferred pending an exact approved list.

## Remaining follow-up

- Replace the empty cut_length interval-width test; its skip is missing coverage.
- Capture remaining intentional warning paths explicitly and repair legacy matrix-name fixtures outside summaries. The summary family now has no uncaptured warnings. Test warnings are separate from package-check warnings (zero).
- Verify the declared R 4.1 minimum and other platforms before publishing.
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
