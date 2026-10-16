# Problems and issues

## Current baseline after first milestone

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

## Stabilization triage (2026-10-16)

The [complete saved-failure inventory](reports/project_status_failure_triage_2026-10-16.md)
accounts for all 104 failing/erroring identities. Eleven fixtures fail before
statart is reached; 77 identities have incorrect expectations. Seven likely
implementation defects need focused reproduction, eight need explicit behavior
decisions, and one is a reproduced environmental timing flake. No fixes applied.

Git setup and comparison are complete. NEWS/MIGRATION now document the full
upstream API transition. The artifact allowlist retains selected evidence while
preserving other generated results locally. The earlier tracked-only comparison had 26 whitespace findings; the full staged
checkpoint also exposes whitespace in newly included historical files (895 findings
before excluding four scratch files). This preparation pass does not reformat
existing code or generated reports. The full suite and package check remain failing.

## First milestone resolved

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

## Historical resolutions before scope reduction

The following notes are historical claims and do not override the current test baseline.

## Resolved Issues ✓

### Summary Statistics (summ) - All Fixed v0.2.x

| ID | Resolution |
|----|------------|
| 3.1 | Inf/-Inf now shown in min/max correctly |
| 3.2 | Dates/datetimes now formatted as strings |
| 3.3 | as_numeric() called once per var; faster |
| 3.4 | Added .na.rm arg (default FALSE) |
| 3.5 | Added .name arg (default TRUE) |

### Tabulation (tab, tab1, fre) - All Fixed v0.2.x

| ID | Resolution |
|----|------------|
| 2.1 | tab1()/fre1() now support expressions |
| 2.2 | fre() ~10x faster (add_total rewritten) |
| 2.3 | Missing values at bottom of each group |
| 2.4 | .n renaming documented (known behaviour) |
| 2.5 | .desc now sorts non-NA desc, NA last |

### Helper Functions - All Fixed v0.2.x

| ID | Resolution |
|----|------------|
| 4.1 | cut_quantile() rank-based fallback for ties |
| 4.2 | row_min/max/mean/sum return plain vectors |
| 4.3 | codebook() Hmisc warning suppressed |

### Feature Requests - Fixed

| Feature | Resolution |
|---------|------------|
| timer() output | Compact format: 1m5s, 0.05s |
| s_select errors | Shows exact column name + both error messages |

### Estimation Tables (esttab) - All Fixed v0.2.0

| ID | Version | Resolution |
|----|---------|------------|
| 1.1 | v0.2.0 | lmer p-value fallback |
| 1.2 | v0.2.0 | Graceful broom errors |
| 1.3 | v0.2.0 | glue-style format arg |
| 1.4 | v0.2.0 | stats arg with Stata aliases |
| 1.5 | v0.2.0 | Simplified output |

### Visualization (s_plot) - Moved to extra_functions/
