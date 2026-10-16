# 100 scenarios for summ and tabstat

Verified 2026-10-16, version 0.2.0.9000, Windows R 4.6.0.

**All 100 numbered scenarios pass for each function: 200 function/scenario executions.**
The previous acceptance tests remain. This expands test coverage without changing package behavior.

A scenario is one named test block; an expectation is an assertion inside it.
The two functions run the same scenario separately. This is 100 distinct scenario definitions,
not 200 different definitions and not a code-coverage percentage. No finite suite proves
correctness for every input, platform or dependency version.

## Results

| Scope | Blocks | Passing expectations | Failures | Errors | Warnings | Skips |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| Numbered matrix | 200 | 770 | 0 | 0 | 0 | 0 |
| Standalone acceptance, including retained checks | 286 | 1158 | 0 | 0 | 0 | 0 |
| All summary tests | 342 | 1224 | 0 | 0 | 0 | 0 |
| Full package | 1668 | 6692 | 0 | 0 | 27 | 1 |

Standalone elapsed time: 18.98 seconds. Fresh install/source build pass;
R CMD check --no-manual: **Status: OK**, zero check errors, warnings or notes.
Uncaptured warnings and the empty cut_length skip belong to other function families.

## Test sources and independent references

- [001-050: numeric values, invariants, grouping and names](../../tests/testthat/test-summ-coverage-numeric.R)
- [051-100: classes, types, calendars, selection and errors](../../tests/testthat/test-summ-coverage-structure.R)
- [Earlier acceptance regressions](../../tests/testthat/test-summ-acceptance.R)
- [SPSS missingness and numerical references](../../tests/testthat/test-summ-missing-statistics.R)
- [Shared summary contracts](../../tests/testthat/test-summ-contracts.R)
- [Retained summary tests](../../tests/testthat/test-summ.R)
- [Standalone runner](../tests/verify_summ_tabstat.R)

The numerical oracle uses documented base-R statistics, not statart helpers.
Closed-form references test the 10,000-row mean/sum/sample SD. Metamorphic cases test
permutation, duplication, translation and negative scaling. Group results use explicit
expected values or independently calculated subsets. Calendar and invalid-input cases
assert documented values, classes, diagnostics and input preservation.

Independent review removed an overlapping logical case in favor of grouped logical
proportions, and tightened exact extrema/nonzero checks for tiny magnitudes.
Unicode names use ASCII Unicode escapes so Windows shell/locale conversion cannot
collapse distinct names. No production defect was identified in this expansion.

## Scenario catalogue

Each row below is executed independently through both public entry points.

| ID | Area | Expected behavior checked | summ | tabstat |
| ---: | --- | --- | --- | --- |
| 001 | numeric | positive integers | PASS (2) | PASS (2) |
| 002 | numeric | all negative values | PASS (2) | PASS (2) |
| 003 | numeric | mixed signs | PASS (2) | PASS (2) |
| 004 | numeric | constant nonzero values | PASS (2) | PASS (2) |
| 005 | numeric | constant zero values | PASS (2) | PASS (2) |
| 006 | numeric | singleton observation | PASS (2) | PASS (2) |
| 007 | numeric | zero observations | PASS (2) | PASS (2) |
| 008 | numeric | entirely NA values | PASS (3) | PASS (3) |
| 009 | numeric | entirely NaN values | PASS (3) | PASS (3) |
| 010 | numeric | mixed NA and NaN only | PASS (3) | PASS (3) |
| 011 | numeric | partially missing values | PASS (2) | PASS (2) |
| 012 | numeric | positive infinity | PASS (2) | PASS (2) |
| 013 | numeric | negative infinity | PASS (2) | PASS (2) |
| 014 | numeric | both infinities | PASS (2) | PASS (2) |
| 015 | numeric | signed zeros | PASS (2) | PASS (2) |
| 016 | numeric | fractional values | PASS (2) | PASS (2) |
| 017 | numeric | tiny nonzero values | PASS (2) | PASS (2) |
| 018 | numeric | large offset with small spread | PASS (2) | PASS (2) |
| 019 | numeric | very large magnitudes | PASS (2) | PASS (2) |
| 020 | numeric | near-minimum positive magnitudes | PASS (6) | PASS (6) |
| 021 | numeric | integer storage boundaries | PASS (2) | PASS (2) |
| 022 | numeric | missing values at both ends | PASS (2) | PASS (2) |
| 023 | numeric | repeated values and ties | PASS (2) | PASS (2) |
| 024 | numeric | logical zero-one values | PASS (2) | PASS (2) |
| 025 | invariant | row permutations preserve statistics | PASS (1) | PASS (1) |
| 026 | invariant | duplicating rows doubles counts and sum | PASS (5) | PASS (5) |
| 027 | invariant | translation shifts location but preserves spread | PASS (3) | PASS (3) |
| 028 | invariant | negative scaling reverses extrema | PASS (4) | PASS (4) |
| 029 | numeric | two-point sample SD uses n minus one | PASS (2) | PASS (2) |
| 030 | numeric | two-point percentiles interpolate with type seven | PASS (1) | PASS (1) |
| 031 | numeric | geometric values retain asymmetric moments | PASS (1) | PASS (1) |
| 032 | size | ten thousand integers match closed-form references | PASS (4) | PASS (4) |
| 033 | grouping | single groups preserve first appearance and counts | PASS (4) | PASS (4) |
| 034 | grouping | two grouping keys retain missing combinations | PASS (4) | PASS (4) |
| 035 | grouping | missing key removal affects every selected key | PASS (3) | PASS (3) |
| 036 | grouping | all-missing measured groups remain present | PASS (4) | PASS (4) |
| 037 | grouping | numeric grouping keys preserve missing keys | PASS (2) | PASS (2) |
| 038 | grouping | unused factor levels do not invent observations | PASS (3) | PASS (3) |
| 039 | grouping | existing multi-key grouping uses both keys | PASS (3) | PASS (3) |
| 040 | grouping | explicit regrouping replaces existing groups | PASS (3) | PASS (3) |
| 041 | grouping | dropping all missing keys yields typed empty output | PASS (4) | PASS (4) |
| 042 | grouping | multiple measured columns retain within-group identity | PASS (4) | PASS (4) |
| 043 | names | multiple reserved grouping keys preserve their values | PASS (4) | PASS (4) |
| 044 | names | reserved grouping repair avoids unused input names | PASS (2) | PASS (2) |
| 045 | names | Unicode measured names and grouping values survive | PASS (3) | PASS (3) |
| 046 | names | non-syntactic column names retain literal identity | PASS (3) | PASS (3) |
| 047 | names | numeric summary names do not overwrite group identifiers | PASS (3) | PASS (3) |
| 048 | preservation | input variable labels and attributes remain unchanged | PASS (3) | PASS (3) |
| 049 | numeric | cancellation-prone values match base R arithmetic | PASS (3) | PASS (3) |
| 050 | size | deterministic many-group summaries match independent subsets | PASS (69) | PASS (69) |
| 051 | classes | base data frames regain their class in table mode | PASS (4) | PASS (4) |
| 052 | classes | tibble output retains ordered measured names | PASS (3) | PASS (3) |
| 053 | classes | data table output preserves input without reference mutation | PASS (4) | PASS (4) |
| 054 | vectors | named vector elements do not become measured columns | PASS (5) | PASS (5) |
| 055 | vectors | inline vector expressions retain a meaningful name | PASS (3) | PASS (3) |
| 056 | types | grouped logical proportions use observed group denominators | PASS (6) | PASS (6) |
| 057 | types | factor statistics use declared level codes | PASS (5) | PASS (5) |
| 058 | types | ordered factors preserve unused level positions | PASS (6) | PASS (6) |
| 059 | types | haven labels do not replace numerical values | PASS (6) | PASS (6) |
| 060 | types | tagged missing values are excluded from observed counts | PASS (5) | PASS (5) |
| 061 | types | SPSS missing ranges and codes follow original missingness | PASS (6) | PASS (6) |
| 062 | types | difftime statistics use the original hour unit | PASS (5) | PASS (5) |
| 063 | types | measured vectors retain their declared unit scale | PASS (5) | PASS (5) |
| 064 | types | small integer64 values convert without precision loss | PASS (5) | PASS (5) |
| 065 | retained | text counts distinguish empty strings from missing values | PASS (6) | PASS (6) |
| 066 | retained | list identities preserve element order and vector contents | PASS (6) | PASS (6) |
| 067 | calendar | dates return readable locations and correct counts | PASS (5) | PASS (5) |
| 068 | calendar | fractional date means omit fractional days from display | PASS (4) | PASS (4) |
| 069 | calendar | long date spreads use day units | PASS (3) | PASS (3) |
| 070 | calendar | compact date spreads include standard error | PASS (4) | PASS (4) |
| 071 | calendar | non UTC datetime inputs are displayed as UTC instants | PASS (4) | PASS (4) |
| 072 | calendar | datetime locations omit seconds across minute boundaries | PASS (3) | PASS (3) |
| 073 | calendar | long datetime spreads format minutes and seconds | PASS (3) | PASS (3) |
| 074 | calendar | compact datetime spreads use scaled hours | PASS (3) | PASS (3) |
| 075 | output | heterogeneous list mode preserves statistic types by family | PASS (6) | PASS (6) |
| 076 | output | heterogeneous table mode formats shared locations but not counts | PASS (5) | PASS (5) |
| 077 | empty | zero row calendar columns retain missing formatted locations | PASS (9) | PASS (9) |
| 078 | empty | empty grouped mixed tables retain schema without invented groups | PASS (4) | PASS (4) |
| 079 | selection | tidyselect helpers choose only matching names | PASS (2) | PASS (2) |
| 080 | selection | negative selection omits the excluded measured variable | PASS (2) | PASS (2) |
| 081 | selection | programmatic selection supports non syntactic and Unicode names | PASS (2) | PASS (2) |
| 082 | selection | data masking computes expressions rather than filtering rows | PASS (5) | PASS (5) |
| 083 | selection | renamed selected variables use their requested output names | PASS (3) | PASS (3) |
| 084 | statistics | duplicate requests deduplicate while aliases coexist in order | PASS (6) | PASS (6) |
| 085 | output | name false retains variable identity when several variables are measured | PASS (2) | PASS (2) |
| 086 | validation | unknown statistics fail without returning a partial selection | PASS (1) | PASS (1) |
| 087 | validation | missing statistic names are rejected before calculation | PASS (1) | PASS (1) |
| 088 | validation | selection of an absent variable provides a useful selection error | PASS (1) | PASS (1) |
| 089 | validation | invalid output modes are rejected | PASS (1) | PASS (1) |
| 090 | validation | invalid duration formats are rejected even for numeric input | PASS (1) | PASS (1) |
| 091 | validation | logical controls reject numeric truth values | PASS (2) | PASS (2) |
| 092 | validation | matrix columns fail rather than flattening observations | PASS (2) | PASS (2) |
| 093 | validation | data frame columns fail rather than silently expanding variables | PASS (2) | PASS (2) |
| 094 | validation | unsupported only selections warn and fail with keep all disabled | PASS (2) | PASS (2) |
| 095 | validation | selecting no measured variables raises a clear error | PASS (1) | PASS (1) |
| 096 | validation | calendar sums are explicitly unsupported | PASS (1) | PASS (1) |
| 097 | validation | datetime skew is explicitly unsupported | PASS (1) | PASS (1) |
| 098 | validation | date kurtosis is explicitly unsupported | PASS (1) | PASS (1) |
| 099 | calendar | date percentile aliases share correctly formatted calendar values | PASS (7) | PASS (7) |
| 100 | retained | NULL and nested list values are counted without flattening | PASS (6) | PASS (6) |

Parentheses show passing expectations in that scenario, not additional scenarios.

## Evidence and reuse

- [Full-suite results](../results/summ-100-reviewed.csv)
- [Warning and skip details](../results/summ-100-reviewed-details.csv)
- [All acceptance scenario results](../results/summ-100-reviewed-scenarios.csv)
- [Protected package-check log](../results/summ-100-reviewed-check.log)
- [Per-case PASS output and actual function examples](../results/summ-100-reviewed-examples.log)

Run from the repository root:

```powershell
python .opencode/workflows/verify_package.py --check --prefix .opencode/results/summ-100-reviewed
python C:/Users/socimh/.codex/scripts/run_r_safe.py -- Rscript .opencode/tests/verify_summ_tabstat.R <fresh-library> .opencode/results/summ-100-reviewed
python .opencode/workflows/summarize_summ_100.py
```

Use the fresh library path recorded in the paths JSON. Capture the standalone runner's
combined stdout/stderr as UTF-8 in the linked examples log, including the protected
launcher exit line, before regenerating this report. The runner enforces IDs 001-100
exactly once per function and exits nonzero for a failed/warning/skipped scenario.
Type-specific cases need the optional Suggests data.table, units and bit64 installed;
ordinary testthat runs skip them if absent, but acceptance requires all cases to execute.

## Readiness boundary

Both functions remain locally accepted release candidates. Exact Stata equivalence,
arbitrary integer precision and full calendar precision are not promised; see
[the accepted contracts and limits](project_status_summ_tabstat_acceptance_2026-10-16.md).
The declared R 4.1 minimum and other platforms still need validation before publishing.
No push, merge, release or artifact deletion was performed.
