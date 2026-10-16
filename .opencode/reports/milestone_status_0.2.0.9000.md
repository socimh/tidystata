# First milestone: implementation and remaining baseline

Version: **0.2.0.9000**. Local implementation of the approved exploration
and preparation scope; no release or publication was performed.

## Implemented

- Retired read_data, write_data, esttab, and codebook_detail; preserved
  implementations, original help, dedicated tests and demo in extra_functions.
- Reduced Imports from 33 to 13; retained cpp11/Rfast and all other exports.
- Made formatting optional; fre/fre2 default to tibbles and fre1 to a list.
- Fixed character conversion, attribute labels/search, grouped keys and totals,
  atomic row results/missingness/input preservation, and stable quantile ties.
- Added reliable isolated build/test/report commands with failure exit status.
- Regenerated namespace/help/README; refreshed website reference configuration.

## Focused acceptance

[622 milestone scenarios](milestone_contracts_0.2.0.9000.md) passed, with
4,098 passing expectations and zero failed expectations, errors, warnings,
or skips. The standalone scenario runner returns a nonzero status on failure.
A separate required-dependencies-only library smoke test passed, including
the actionable error for explicitly requested, unavailable flextable output.
All ten active demos passed and their versioned reports preserve actual output.

## Full retained suite

The full suite is **not passing**. These categories have different counting
units and must not be added together as a number of test cases.

| Measure | Count |
| --- | ---: |
| Test blocks | 1,358 |
| Passing expectations | 5,129 |
| Failed expectations | 94 |
| Error blocks | 22 |
| Warnings | 54 |
| Skipped blocks | 1 |

New failing test identities relative to the original baseline: **1**;
unexplained after environmental triage: **0**.
The original baseline had 134 failed expectations and 38 error blocks across
789 blocks. Functions were retired and regression scenarios added, so total
test counts are not directly comparable as a completion percentage.

| File | Failed expectations | Error blocks | Warnings |
| --- | ---: | ---: | ---: |
| test-browse.R | 1 | 0 | 1 |
| test-complex_tb.R | 0 | 7 | 1 |
| test-cut.R | 0 | 0 | 10 |
| test-fre.R | 6 | 2 | 7 |
| test-fre1.R | 4 | 0 | 2 |
| test-fre2.R | 24 | 2 | 3 |
| test-names.R | 2 | 0 | 2 |
| test-s_match.R | 0 | 0 | 2 |
| test-s_select.R | 0 | 0 | 2 |
| test-s_try.R | 4 | 0 | 6 |
| test-s_type.R | 0 | 2 | 0 |
| test-summ.R | 0 | 4 | 6 |
| test-tab.R | 19 | 1 | 1 |
| test-tab1.R | 4 | 1 | 1 |
| test-tab2.R | 27 | 3 | 9 |
| test-timer.R | 3 | 0 | 1 |

Remaining discrepancies include invalid labelled/tibble/sample fixtures,
cross-tabulation expectations for an extra count column, category-name
collisions, summary/date contracts, and name/type/utility expectations.
Not every failed test is a source defect. Triage these in milestone two.
The additional timer identity checks system.time(Sys.sleep(0.05)) against
a strict 0.04 lower bound before examining statart output. Both timer source
and its test file are byte-identical to the baseline. A 30-iteration base-R
probe reproduced a below-threshold result, and a focused timer rerun returned
only its two original failures. This is an environmental/floating-point timing
fixture flake, not an unexplained package regression; it remains recorded.

## Package checking and independent review

Fresh source installation and tarball build succeeded. R CMD check --no-manual
passed all non-test stages, including dependency declarations, namespace/load
checks, help, code/documentation consistency, compiled code and examples. It
finished with **one ERROR at tests**, reflecting the retained-suite failures.
Repository-index access warnings occurred in the restricted-network environment.
The inherited invalid Windows locale was corrected only in child processes.

The independent reviewer reproduced two important regressions: reserved
variable group keys were overwritten in combined output, and row dispatch
rejected general dataframe expressions inside mutate. Both now have RED-to-GREEN
regression coverage, including exactly-once evaluation of dataframe producers.
The reviewer also verified archive byte identity, exclusion of development/
archive files from the tarball, both datasets, 13 Imports and 40 exports.
Original datasets, DLL and object files were preserved.

## Evidence and limits

- [Final suite results](../results/milestone-retained-final.csv).
- [Failure/warning details](../results/milestone-retained-final-details.csv).
- [Package check log](../results/milestone-verification-check.log).
- [Required-dependency smoke](../results/milestone-minimal-final-minimal.log).
- [Base-R timing probe](../results/milestone-timing-probe.txt) and
  [timer-only recheck](../results/milestone-timer-recheck.csv).
- [Historical baseline](project_status_2026-10-15.md) and its preserved
  [raw evidence](../results/baseline-0.2.0.json).

No R-version matrix, manual PDF, full built website, online CI, or release
validation was performed. The declared R 4.1 minimum was not exercised here.
Git metadata is absent, so no commit was possible. See
[DEVELOPMENT.md](../../DEVELOPMENT.md) and [MIGRATION.md](../../MIGRATION.md).
