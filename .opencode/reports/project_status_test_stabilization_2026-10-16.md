# Test fixture and assertion stabilization

Verified 2026-10-16 on branch test/stabilize-fixtures. Production source, datasets, archives and dependencies are unchanged in this stage.

## Fresh full-suite result

| Measure | Previous retained evidence | After test repairs |
| --- | ---: | ---: |
| Test blocks | 1358 | 1358 |
| Passing expectations | 5129 | 5357 |
| Failed expectations | 94 | 5 |
| Error blocks | 22 | 10 |
| Warnings | 54 | 33 |
| Skipped blocks | 1 | 1 |

Fresh native installation passed. The full test runner correctly exited 1 because unresolved failures remain. No new failing/erroring test identities appeared; the remaining identities were all in the prior evidence. Counts use distinct units and are not combined into test-case totals.

## Repairs and evidence

- Fixed all 11 fixture-construction failures: labelled_spss for user-defined missing values, explicit vector lengths, and replacement when repeatedly sampling small populations. Newly reached survey/clinical assertions now check actual columns and nonmissing counts.
- Corrected 77 incorrect-expectation identities, plus the timing fixture: totals use actual measured columns and exact labels; missing-label indexing is explicit; computed variables are tabulated rather than treated as filters; percentage metadata and cross-table marginals are checked; Date totals use character labels; explicit NA factor levels differ from missing codes.
- Utility assertions now reflect successful evaluations of warnings/NULL/FALSE, class-preserving pipelines, local warning assignment, and timer output instead of base sleep thresholds.
- All scenarios remain. Five pivot collision calls and the units error remain unmasked. Three tab input-policy assertions, two search matching assertions and summary-statistic/missing-input cases still require decisions.
- Focused utility tests pass (119 expectations, 82 blocks, five existing warnings). Cross-tables have 225 passing expectations and five known errors across 92 blocks. Complex/type fixtures have 90 passing expectations and the units error across 61 blocks.

Sources: [full summary](../results/stabilization-tests-full.csv), [remaining details](../results/stabilization-tests-full-details.csv), [runner log](../results/stabilization-tests-full-tests.log). Historical triage remains in [the saved-failure report](project_status_failure_triage_2026-10-16.md).

## Remaining failures and errors

| File | Test | Kind |
| --- | --- | --- |
| test-fre2.R | fre2: factor with NA level | error |
| test-fre2.R | fre2: factor with unused levels | error |
| test-names.R | variables_search: single character with ? | failure |
| test-names.R | variables_search: numeric range | failure |
| test-s_type.R | s_unit: units object | error |
| test-summ.R | summ: all available statistics | error |
| test-summ.R | tabstat: custom statistics | error |
| test-summ.R | summ: all NA variable handling | error |
| test-summ.R | summ: empty data frame with columns | error |
| test-tab.R | tab: deeply nested list columns should fail gracefully | failure |
| test-tab.R | tab: starts_with with no matches | failure |
| test-tab.R | tab: gracefully handle data.frame with no columns | failure |
| test-tab2.R | tab2: factor with NA level | error |
| test-tab2.R | tab2: special whitespace characters | error |
| test-tab2.R | tab2: factor with unused levels | error |

## Next stage

Repair original-variable/category name collisions and units type detection using focused regressions. Maintainer chose zero-observation rows with n=0/NA statistics, both statistic naming styles, and sum for the upcoming summary pass. No package release/readiness claim is made; R CMD check was not repeated in this test-only stage.
