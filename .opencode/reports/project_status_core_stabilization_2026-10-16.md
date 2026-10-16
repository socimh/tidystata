# Core stabilization verification

Verified 2026-10-16. Version 0.2.0.9000; 13 required Imports; 40 exports. No push, merge or release.

## Agreed behavior and repairs

- Retain numeric/logical columns with no observations, including zero-row inputs: n/unique are zero and statistics are NA. Grouped empty inputs do not invent groups.
- Accept missing/p25/p50/p75 alongside miss_n/q1/median/q3; preserve requested names/order and support numeric sum. Calendar sum is explicitly unsupported. Mixed calendar/numeric table statistics use compatible text columns while counts stay numeric; list-mode numeric statistics stay numeric.
- Preserve substring searches and explicitly test anchored complete-name matching.
- Count list-column identities without flattening. No selected variables yield empty tables; tab1/fre1 retain list defaults. Invalid nonempty cross-table arity still errors.
- Fix original-variable/category name collisions, preserve n/...tmp categories and reject fre2 column category total before it overwrites counts.
- Recognize units metadata before interpreting pillar display strings, including empty/all-missing measured vectors.

## Fresh verification

| Measure | Result |
| --- | ---: |
| Test blocks | 1410 |
| Passing expectations | 5617 |
| Failed expectations | 0 |
| Error blocks | 0 |
| Test warnings | 33 |
| Skipped blocks | 1 |

Fresh native installation, source build, and R CMD check --no-manual all passed. Check status is OK: zero check errors, warnings or notes. A first check exposed five unbound selection names; using explicit all_of selections removed that NOTE in this final run. The required-dependency-only smoke check also passed.

The 33 test warnings are distinct from package-check warnings. They include expected conversion/metadata/invalid-input warnings and legacy matrix-name fixtures. The single skipped block is the pre-existing empty cut_length interval-width test; it still needs a real assertion. No tests were removed or disabled. The test-only stage had five failed expectations and ten errors across 1,358 blocks; this stage adds 52 regression blocks and clears all remaining failures/errors.

| Modified family | Verified blocks | Passing expectations |
| --- | ---: | ---: |
| Summary/statistics | 84 | 149 |
| Tabulation/frequency | 291 | 695 |
| Types/units | 39 | 74 |
| Names/search | 38 | 58 |
| Prior milestone contracts | 622 | 4098 |

Sources: [full summary](../results/stabilization-core-clean.csv), [warning/skip details](../results/stabilization-core-clean-details.csv), [test log](../results/stabilization-core-clean-tests.log), [build log](../results/stabilization-core-clean-build.log), [package check](../results/stabilization-core-clean-check.log), [required-dependency smoke](../results/stabilization-core-minimal-minimal.log).

Read-only package review found no material introduced defects; focused probes also verified grouped empty summaries, nested lists, and empty flextable output. Generated help/README were rebuilt from source. Original datasets and native build artifacts were preserved.

## Actual output examples

Captured through the protected launcher using .opencode/tests/show_core_stabilization.R and a fresh installation.

```text
SUMMARY ALIASES AND SUM
# A tibble: 1 x 6
  name  type      n missing   sum   p50
  <chr> <chr> <int>   <int> <dbl> <dbl>
1 x     dbl       2       1     4     2

ZERO-OBSERVATION SUMMARY
# A tibble: 1 x 8
  name  type      n unique   min  mean    sd   max
  <chr> <chr> <int>  <int> <dbl> <dbl> <dbl> <dbl>
1 x     dbl       0      0    NA    NA    NA    NA

CROSS-TABLE CATEGORY MATCHING ROW VARIABLE
# A tibble: 3 x 4
  `row \\ col` other   row total
  <chr>        <int> <int> <int>
1 A                1     1     2
2 B                0     1     1
3 total            1     2     3

EMPTY VARIABLE SELECTION
# A tibble: 0 x 5
# i 5 variables: n <int>, percent <dbl>, cum <dbl>, valid <dbl>, valid_cum <dbl>

LIST-COLUMN COUNTS
# A tibble: 2 x 6
  value         n percent   cum valid valid_cum
  <list>    <int>   <dbl> <dbl> <dbl>     <dbl>
1 <int [2]>     2    66.7  66.7  66.7      66.7
2 <int [2]>     1    33.3 100    33.3     100

SUBSTRING AND ANCHORED SEARCH
# A tibble: 3 x 1
  name
  <chr>
1 x1
2 x2
3 x10
# A tibble: 2 x 1
  name
  <chr>
1 x1
2 x2

MEASURED TYPE AND UNIT
   type    unit
"units"   "m/s"
```

## Remaining limits

- Exercise the declared R 4.1 minimum and other platforms before publishing. This validation used Windows R 4.6.0; no online CI or release was performed.
- Replace the empty cut_length test and tighten expected-warning handling/legacy matrix fixtures separately.
- Ambiguous combined-header or literal-NA/missing-category pivot labels still error explicitly. A row value total remains alongside the appended total row, so callers should use the final row for the marginal total.
- Four regenerated README console lines contain pillar trailing spaces; generated output was not manually patched.

Regenerate this report with python .opencode/workflows/summarize_core_stabilization.py after running the protected final verification workflow.
