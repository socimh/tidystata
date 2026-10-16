# Saved failure triage and repair queue

Prepared 2026-10-16 from the 2026-10-15 retained-suite evidence. No full-suite rerun or function fixes are implied.

## Evidence and counting

The saved suite contains 94 failed expectations and 22 error blocks across 104 distinct file/test identities. The 116 failure/error detail rows reconcile with those two measures; identities can contain multiple failed expectations. Warnings (54) and skips (one) remain separate and are not classified as failures here.

Sources: [summary](../results/milestone-retained-final.csv), [details](../results/milestone-retained-final-details.csv), and [milestone report](milestone_status_0.2.0.9000.md).

Classifications use saved messages plus source/test inspection. Likely defects require focused reproduction; Contract review is an explicit unresolved decision, not a confirmed source bug. No tests are disabled or changed by this report.

| Classification | Distinct test identities |
| --- | ---: |
| Contract review | 8 |
| Environmental flake | 1 |
| Incorrect expectation | 77 |
| Invalid fixture | 11 |
| Likely implementation defect | 7 |

## Source review findings

A read-only package QA review traced all identities to current tests and sources. Invalid fixtures fail before statart is called. The 77 incorrect expectations account for 88 failed expectations and one test-side error; 11 fixture identities account for 11 errors; seven likely defects account for seven errors; eight contract decisions account for five failures and three errors; the flake accounts for one failure.

- Five tab2/fre2 pivot collisions occur in R/tab-helpers.R:329-350 when category names duplicate the row variable name.
- Empty summary input reaches a NaN predicate in R/summ-helpers.R:67-72 and :124-129. Units handling reaches an NA conditional in R/s_type.R:17-29.
- Summary decisions: all-missing input, aliases missing/p25/p50/p75 versus miss_n/q1/median/q3, and support for sum. Search decisions: whole-name versus substring regex matching. Tabulation decisions: list columns and empty selections/dataframes.
- Stale expectations include an extra n column in cross-tables, missing percentage/cumulative metadata in dimension counts, Date classes after textual Total rows, invalid Total-row matching, nonexistent result$x access, and a warning test assigning result with <<-.
- Four s_try expressions succeed or warn rather than error; mtcars pipelines preserve data.frame class. Boolean tab arguments create measured values rather than filtering observations.

## Repair order

1. Repair definite fixture construction and incorrect expectations in small reviewed batches. Preserve scenarios and distinguish assertions from intended behavior. Run only affected test files initially.
2. Summaries: settle empty/all-missing data, supported statistics, and date/duration output contracts; reproduce the empty predicate failure.
3. Tabulation/frequencies: settle cross-table dimensions and count-column policy, totals and types, then fix pivot name collisions. Many saved expectations assume an extra n column; do not add one solely to satisfy those tests.
4. Names/types/utilities: resolve regex expectations, units handling, warning capture, and timing fixtures. Treat warning behavior separately from error behavior.
5. Run broader regression/check validation once affected families pass; retain the 622 focused scenarios as regression coverage.

## Complete identity inventory

| File | Test | Detail rows | Classification | Next action |
| --- | --- | ---: | --- | --- |
| test-browse.R | browse: works in dplyr pipeline | 1 | Incorrect expectation | Input is mtcars/data.frame; do not require tibble class from a class-preserving pipeline. |
| test-complex_tb.R | codebook: clinical trial data | 1 | Invalid fixture | Repair construction before calling statart; preserve the intended scenario. |
| test-complex_tb.R | codebook: difftime and hms time variables | 1 | Invalid fixture | Repair construction before calling statart; preserve the intended scenario. |
| test-complex_tb.R | codebook: extreme numeric values | 1 | Invalid fixture | Repair construction before calling statart; preserve the intended scenario. |
| test-complex_tb.R | codebook: haven labelled variables with complex labels | 1 | Invalid fixture | Repair construction before calling statart; preserve the intended scenario. |
| test-complex_tb.R | codebook: logical variables with NA | 1 | Invalid fixture | Repair construction before calling statart; preserve the intended scenario. |
| test-complex_tb.R | codebook: survey data simulation | 1 | Invalid fixture | Repair construction before calling statart; preserve the intended scenario. |
| test-complex_tb.R | codebook: where() with complex predicate | 1 | Invalid fixture | Repair construction before calling statart; preserve the intended scenario. |
| test-fre.R | fre: Total with missing values included | 1 | Incorrect expectation | Match the grand Total label exactly; broad Total matching also selects Valid Total. |
| test-fre.R | fre: boolean expression as computed variable | 1 | Incorrect expectation | Source/test review identifies a mismatch in dimensions/metadata, totals, classes, selection, NA handling or local warning capture; reproduce before repairing assertions. |
| test-fre.R | fre: demographic breakdown with grouping | 1 | Incorrect expectation | Source/test review identifies a mismatch in dimensions/metadata, totals, classes, selection, NA handling or local warning capture; reproduce before repairing assertions. |
| test-fre.R | fre: five variables with tibble output | 1 | Incorrect expectation | Source/test review identifies a mismatch in dimensions/metadata, totals, classes, selection, NA handling or local warning capture; reproduce before repairing assertions. |
| test-fre.R | fre: haven labelled with NA values | 1 | Invalid fixture | Repair construction before calling statart; preserve the intended scenario. |
| test-fre.R | fre: mixed variable types with Total | 1 | Incorrect expectation | Source/test review identifies a mismatch in dimensions/metadata, totals, classes, selection, NA handling or local warning capture; reproduce before repairing assertions. |
| test-fre.R | fre: multiple variables with tibble output | 1 | Incorrect expectation | Source/test review identifies a mismatch in dimensions/metadata, totals, classes, selection, NA handling or local warning capture; reproduce before repairing assertions. |
| test-fre.R | fre: survey frequency distribution | 1 | Incorrect expectation | Source/test review identifies a mismatch in dimensions/metadata, totals, classes, selection, NA handling or local warning capture; reproduce before repairing assertions. |
| test-fre1.R | fre1: .desc applied to all variables in list | 1 | Incorrect expectation | Check actual frequency counts; .desc sorts frequency, not category value. |
| test-fre1.R | fre1: Date variables with Total | 1 | Incorrect expectation | Source/test review identifies a mismatch in dimensions/metadata, totals, classes, selection, NA handling or local warning capture; reproduce before repairing assertions. |
| test-fre1.R | fre1: POSIXct datetime with Total | 1 | Incorrect expectation | Source/test review identifies a mismatch in dimensions/metadata, totals, classes, selection, NA handling or local warning capture; reproduce before repairing assertions. |
| test-fre1.R | fre1: haven labelled variables | 1 | Incorrect expectation | Source/test review identifies a mismatch in dimensions/metadata, totals, classes, selection, NA handling or local warning capture; reproduce before repairing assertions. |
| test-fre2.R | fre2: .flip=TRUE swaps dimensions | 2 | Incorrect expectation | Source/test review identifies a mismatch in dimensions/metadata, totals, classes, selection, NA handling or local warning capture; reproduce before repairing assertions. |
| test-fre2.R | fre2: 10x10 cross-tabulation with totals | 1 | Incorrect expectation | Source/test review identifies a mismatch in dimensions/metadata, totals, classes, selection, NA handling or local warning capture; reproduce before repairing assertions. |
| test-fre2.R | fre2: Date vs character | 1 | Incorrect expectation | Source/test review identifies a mismatch in dimensions/metadata, totals, classes, selection, NA handling or local warning capture; reproduce before repairing assertions. |
| test-fre2.R | fre2: Total row sum equals grand total | 1 | Incorrect expectation | Source/test review identifies a mismatch in dimensions/metadata, totals, classes, selection, NA handling or local warning capture; reproduce before repairing assertions. |
| test-fre2.R | fre2: all identical values | 1 | Incorrect expectation | Source/test review identifies a mismatch in dimensions/metadata, totals, classes, selection, NA handling or local warning capture; reproduce before repairing assertions. |
| test-fre2.R | fre2: clinical trial contingency table | 1 | Incorrect expectation | Source/test review identifies a mismatch in dimensions/metadata, totals, classes, selection, NA handling or local warning capture; reproduce before repairing assertions. |
| test-fre2.R | fre2: defect analysis by shift | 2 | Incorrect expectation | Source/test review identifies a mismatch in dimensions/metadata, totals, classes, selection, NA handling or local warning capture; reproduce before repairing assertions. |
| test-fre2.R | fre2: demographic breakdown with totals | 1 | Incorrect expectation | Source/test review identifies a mismatch in dimensions/metadata, totals, classes, selection, NA handling or local warning capture; reproduce before repairing assertions. |
| test-fre2.R | fre2: emoji as values | 1 | Incorrect expectation | Source/test review identifies a mismatch in dimensions/metadata, totals, classes, selection, NA handling or local warning capture; reproduce before repairing assertions. |
| test-fre2.R | fre2: everything() with two columns | 1 | Incorrect expectation | Source/test review identifies a mismatch in dimensions/metadata, totals, classes, selection, NA handling or local warning capture; reproduce before repairing assertions. |
| test-fre2.R | fre2: factor with NA level | 1 | Likely implementation defect | Resolve pivot category/row-name collisions without silently losing categories. |
| test-fre2.R | fre2: factor with unused levels | 1 | Likely implementation defect | Resolve pivot category/row-name collisions without silently losing categories. |
| test-fre2.R | fre2: highly concentrated data | 2 | Incorrect expectation | Source/test review identifies a mismatch in dimensions/metadata, totals, classes, selection, NA handling or local warning capture; reproduce before repairing assertions. |
| test-fre2.R | fre2: logical vs numeric | 1 | Incorrect expectation | Source/test review identifies a mismatch in dimensions/metadata, totals, classes, selection, NA handling or local warning capture; reproduce before repairing assertions. |
| test-fre2.R | fre2: ordered factor vs regular factor | 1 | Incorrect expectation | Source/test review identifies a mismatch in dimensions/metadata, totals, classes, selection, NA handling or local warning capture; reproduce before repairing assertions. |
| test-fre2.R | fre2: product sales by region | 1 | Incorrect expectation | Source/test review identifies a mismatch in dimensions/metadata, totals, classes, selection, NA handling or local warning capture; reproduce before repairing assertions. |
| test-fre2.R | fre2: row var few levels, column var all unique | 1 | Incorrect expectation | Source/test review identifies a mismatch in dimensions/metadata, totals, classes, selection, NA handling or local warning capture; reproduce before repairing assertions. |
| test-fre2.R | fre2: single row dataset | 2 | Incorrect expectation | Source/test review identifies a mismatch in dimensions/metadata, totals, classes, selection, NA handling or local warning capture; reproduce before repairing assertions. |
| test-fre2.R | fre2: survey cross-tab with totals | 1 | Incorrect expectation | Source/test review identifies a mismatch in dimensions/metadata, totals, classes, selection, NA handling or local warning capture; reproduce before repairing assertions. |
| test-fre2.R | fre2: time series cross-tab with totals | 1 | Incorrect expectation | Source/test review identifies a mismatch in dimensions/metadata, totals, classes, selection, NA handling or local warning capture; reproduce before repairing assertions. |
| test-fre2.R | fre2: unicode in both dimensions | 1 | Incorrect expectation | Source/test review identifies a mismatch in dimensions/metadata, totals, classes, selection, NA handling or local warning capture; reproduce before repairing assertions. |
| test-fre2.R | fre2: uniformly distributed data | 1 | Incorrect expectation | Source/test review identifies a mismatch in dimensions/metadata, totals, classes, selection, NA handling or local warning capture; reproduce before repairing assertions. |
| test-names.R | variables_search: numeric range | 1 | Contract review | Decide supported statistics/all-missing, search matching, list input or empty selection semantics before editing. |
| test-names.R | variables_search: single character with ? | 1 | Contract review | Decide supported statistics/all-missing, search matching, list input or empty selection semantics before editing. |
| test-s_try.R | s_try: NULL input errors | 1 | Incorrect expectation | These expressions succeed or warn; s_try detects errors, not false results or warnings. |
| test-s_try.R | s_try: accessing non-existent column | 1 | Incorrect expectation | These expressions succeed or warn; s_try detects errors, not false results or warnings. |
| test-s_try.R | s_try: checking if function exists | 1 | Incorrect expectation | These expressions succeed or warn; s_try detects errors, not false results or warnings. |
| test-s_try.R | s_try: invalid operation returns FALSE | 1 | Incorrect expectation | These expressions succeed or warn; s_try detects errors, not false results or warnings. |
| test-s_type.R | s_type: ETL pipeline type checking | 1 | Invalid fixture | Repair construction before calling statart; preserve the intended scenario. |
| test-s_type.R | s_unit: units object | 1 | Likely implementation defect | Valid edge input reaches an NA conditional/predicate; reproduce narrowly before fixing. |
| test-summ.R | summ: all NA variable handling | 1 | Contract review | Decide supported statistics/all-missing, search matching, list input or empty selection semantics before editing. |
| test-summ.R | summ: all available statistics | 1 | Contract review | Decide supported statistics/all-missing, search matching, list input or empty selection semantics before editing. |
| test-summ.R | summ: empty data frame with columns | 1 | Likely implementation defect | Valid edge input reaches an NA conditional/predicate; reproduce narrowly before fixing. |
| test-summ.R | tabstat: custom statistics | 1 | Contract review | Decide supported statistics/all-missing, search matching, list input or empty selection semantics before editing. |
| test-tab.R | tab: all combinations of NA patterns | 1 | Incorrect expectation | Source/test review identifies a mismatch in dimensions/metadata, totals, classes, selection, NA handling or local warning capture; reproduce before repairing assertions. |
| test-tab.R | tab: boolean expression creating all FALSE | 1 | Incorrect expectation | The API tabulates computed variables; filtering requires a separate filter step. |
| test-tab.R | tab: boolean with %in% operator | 1 | Incorrect expectation | The API tabulates computed variables; filtering requires a separate filter step. |
| test-tab.R | tab: boolean with OR and AND combined | 2 | Incorrect expectation | The API tabulates computed variables; filtering requires a separate filter step. |
| test-tab.R | tab: boolean with is.na() function | 2 | Incorrect expectation | The API tabulates computed variables; filtering requires a separate filter step. |
| test-tab.R | tab: cascading NAs - each row has NA in different column | 1 | Incorrect expectation | Source/test review identifies a mismatch in dimensions/metadata, totals, classes, selection, NA handling or local warning capture; reproduce before repairing assertions. |
| test-tab.R | tab: deeply nested list columns should fail gracefully | 1 | Contract review | Decide supported statistics/all-missing, search matching, list input or empty selection semantics before editing. |
| test-tab.R | tab: everything() with hidden columns | 1 | Incorrect expectation | Source/test review identifies a mismatch in dimensions/metadata, totals, classes, selection, NA handling or local warning capture; reproduce before repairing assertions. |
| test-tab.R | tab: factor with NA level explicitly set | 1 | Incorrect expectation | An explicit NA factor level differs from a missing factor code. |
| test-tab.R | tab: five variables with complex interactions | 1 | Incorrect expectation | Source/test review identifies a mismatch in dimensions/metadata, totals, classes, selection, NA handling or local warning capture; reproduce before repairing assertions. |
| test-tab.R | tab: gracefully handle data.frame with no columns | 1 | Contract review | Decide supported statistics/all-missing, search matching, list input or empty selection semantics before editing. |
| test-tab.R | tab: group where grouping variable has many NA levels | 1 | Incorrect expectation | Source/test review identifies a mismatch in dimensions/metadata, totals, classes, selection, NA handling or local warning capture; reproduce before repairing assertions. |
| test-tab.R | tab: group with empty groups after filtering | 1 | Incorrect expectation | The API tabulates computed variables; filtering requires a separate filter step. |
| test-tab.R | tab: haven labelled with NA value labelled | 1 | Invalid fixture | Repair construction before calling statart; preserve the intended scenario. |
| test-tab.R | tab: many columns selected | 1 | Incorrect expectation | Source/test review identifies a mismatch in dimensions/metadata, totals, classes, selection, NA handling or local warning capture; reproduce before repairing assertions. |
| test-tab.R | tab: many grouping variables with complex hierarchy | 1 | Incorrect expectation | Source/test review identifies a mismatch in dimensions/metadata, totals, classes, selection, NA handling or local warning capture; reproduce before repairing assertions. |
| test-tab.R | tab: starts_with with no matches | 1 | Contract review | Decide supported statistics/all-missing, search matching, list input or empty selection semantics before editing. |
| test-tab.R | tab: where() with complex predicate | 1 | Incorrect expectation | Source/test review identifies a mismatch in dimensions/metadata, totals, classes, selection, NA handling or local warning capture; reproduce before repairing assertions. |
| test-tab1.R | tab1: .desc=TRUE applied to all variables | 2 | Incorrect expectation | Check actual frequency counts; .desc sorts frequency, not category value. |
| test-tab1.R | tab1: factor with NA vs character with NA | 1 | Incorrect expectation | An explicit NA factor level differs from a missing factor code. |
| test-tab1.R | tab1: frequency ties handling in sorting | 1 | Incorrect expectation | Check actual frequency counts; .desc sorts frequency, not category value. |
| test-tab1.R | tab1: where() selection with complex predicate | 1 | Invalid fixture | Repair construction before calling statart; preserve the intended scenario. |
| test-tab2.R | tab2: 10x10 cross-tabulation | 2 | Incorrect expectation | Source/test review identifies a mismatch in dimensions/metadata, totals, classes, selection, NA handling or local warning capture; reproduce before repairing assertions. |
| test-tab2.R | tab2: 50x5 cross-tabulation | 1 | Incorrect expectation | Source/test review identifies a mismatch in dimensions/metadata, totals, classes, selection, NA handling or local warning capture; reproduce before repairing assertions. |
| test-tab2.R | tab2: 5x50 cross-tabulation | 1 | Incorrect expectation | Source/test review identifies a mismatch in dimensions/metadata, totals, classes, selection, NA handling or local warning capture; reproduce before repairing assertions. |
| test-tab2.R | tab2: Date vs character | 1 | Incorrect expectation | Source/test review identifies a mismatch in dimensions/metadata, totals, classes, selection, NA handling or local warning capture; reproduce before repairing assertions. |
| test-tab2.R | tab2: all identical values | 2 | Incorrect expectation | Source/test review identifies a mismatch in dimensions/metadata, totals, classes, selection, NA handling or local warning capture; reproduce before repairing assertions. |
| test-tab2.R | tab2: both variables all unique | 1 | Incorrect expectation | Source/test review identifies a mismatch in dimensions/metadata, totals, classes, selection, NA handling or local warning capture; reproduce before repairing assertions. |
| test-tab2.R | tab2: clinical trial data | 2 | Incorrect expectation | Source/test review identifies a mismatch in dimensions/metadata, totals, classes, selection, NA handling or local warning capture; reproduce before repairing assertions. |
| test-tab2.R | tab2: demographic breakdown | 1 | Incorrect expectation | Source/test review identifies a mismatch in dimensions/metadata, totals, classes, selection, NA handling or local warning capture; reproduce before repairing assertions. |
| test-tab2.R | tab2: emoji as values | 1 | Incorrect expectation | Source/test review identifies a mismatch in dimensions/metadata, totals, classes, selection, NA handling or local warning capture; reproduce before repairing assertions. |
| test-tab2.R | tab2: everything() with two columns | 1 | Incorrect expectation | Source/test review identifies a mismatch in dimensions/metadata, totals, classes, selection, NA handling or local warning capture; reproduce before repairing assertions. |
| test-tab2.R | tab2: factor with NA level | 1 | Likely implementation defect | Resolve pivot category/row-name collisions without silently losing categories. |
| test-tab2.R | tab2: factor with unused levels | 1 | Likely implementation defect | Resolve pivot category/row-name collisions without silently losing categories. |
| test-tab2.R | tab2: flip with many levels | 1 | Incorrect expectation | Source/test review identifies a mismatch in dimensions/metadata, totals, classes, selection, NA handling or local warning capture; reproduce before repairing assertions. |
| test-tab2.R | tab2: logical vs numeric | 1 | Incorrect expectation | Source/test review identifies a mismatch in dimensions/metadata, totals, classes, selection, NA handling or local warning capture; reproduce before repairing assertions. |
| test-tab2.R | tab2: mixed numeric classes (integer vs double) | 1 | Incorrect expectation | Source/test review identifies a mismatch in dimensions/metadata, totals, classes, selection, NA handling or local warning capture; reproduce before repairing assertions. |
| test-tab2.R | tab2: numeric row, character column | 1 | Incorrect expectation | Source/test review identifies a mismatch in dimensions/metadata, totals, classes, selection, NA handling or local warning capture; reproduce before repairing assertions. |
| test-tab2.R | tab2: row var all unique, column var few levels | 1 | Incorrect expectation | Source/test review identifies a mismatch in dimensions/metadata, totals, classes, selection, NA handling or local warning capture; reproduce before repairing assertions. |
| test-tab2.R | tab2: row var few levels, column var all unique | 1 | Incorrect expectation | Source/test review identifies a mismatch in dimensions/metadata, totals, classes, selection, NA handling or local warning capture; reproduce before repairing assertions. |
| test-tab2.R | tab2: single row dataset | 2 | Incorrect expectation | Source/test review identifies a mismatch in dimensions/metadata, totals, classes, selection, NA handling or local warning capture; reproduce before repairing assertions. |
| test-tab2.R | tab2: special whitespace characters | 1 | Likely implementation defect | Resolve pivot category/row-name collisions without silently losing categories. |
| test-tab2.R | tab2: survey cross-tabulation | 1 | Incorrect expectation | Source/test review identifies a mismatch in dimensions/metadata, totals, classes, selection, NA handling or local warning capture; reproduce before repairing assertions. |
| test-tab2.R | tab2: time series cross-tab | 1 | Incorrect expectation | Source/test review identifies a mismatch in dimensions/metadata, totals, classes, selection, NA handling or local warning capture; reproduce before repairing assertions. |
| test-tab2.R | tab2: two character variables | 1 | Incorrect expectation | Source/test review identifies a mismatch in dimensions/metadata, totals, classes, selection, NA handling or local warning capture; reproduce before repairing assertions. |
| test-tab2.R | tab2: two numeric variables | 2 | Incorrect expectation | Source/test review identifies a mismatch in dimensions/metadata, totals, classes, selection, NA handling or local warning capture; reproduce before repairing assertions. |
| test-tab2.R | tab2: unicode characters in both dimensions | 1 | Incorrect expectation | Source/test review identifies a mismatch in dimensions/metadata, totals, classes, selection, NA handling or local warning capture; reproduce before repairing assertions. |
| test-timer.R | timer: handles warnings in expression | 1 | Incorrect expectation | Source/test review identifies a mismatch in dimensions/metadata, totals, classes, selection, NA handling or local warning capture; reproduce before repairing assertions. |
| test-timer.R | timer: timing is reasonable compared to system.time | 1 | Environmental flake | Saved base-R probe reproduced the strict elapsed-time threshold failure. |
| test-timer.R | timer: works with multiple pipes | 1 | Incorrect expectation | Input is mtcars/data.frame; do not require tibble class from a class-preserving pipeline. |

## Reproduction

Regenerate this report with `python .opencode/workflows/triage_saved_failures.py`. It reads saved CSV files only. For subsequent targeted R checks, use the protected workflows in DEVELOPMENT.md and retain fresh results under a new prefix.
