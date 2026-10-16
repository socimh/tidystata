# Codebook and browse acceptance

Verified 2026-10-16, statart 0.2.0.9000, Windows R 4.6.0.

**100 numbered scenarios pass for codebook and 100 for browse.**
The functions have separate matrices: 200 distinct scenario definitions/executions. Previous tests remain.
Finite tests do not prove every possible input/platform or establish a code-coverage percentage.

## Results

| Scope | Blocks | Passing expectations | Failures | Errors | Uncaptured warnings | Skips |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| Numbered matrix | 200 | 817 | 0 | 0 | 0 | 0 |
| Codebook/browse acceptance and retained shared-selector checks | 297 | 985 | 0 | 0 | 0 | 0 |
| Full package | 2996 | 16213 | 0 | 0 | 15 | 1 |

Standalone elapsed: 8.75 seconds. Fresh native installation and source build pass.
R CMD check --no-manual: **Status: OK**, zero check errors, warnings or notes.
Remaining full-suite diagnostics are outside this codebook/browse/shared-selector acceptance scope.

## Reproduced defects and fixes

- codebook on grouped/rowwise inputs could fail while reshaping group keys and statistics. It now ungroups before selection
  and creates one inventory row per selected column. It describes the whole input, not separate group summaries.
- SPSS user-missing codes and scalar missing list elements could inflate unique counts despite being excluded from n.
  Counts and uniques now use the same original-column missingness mask before any distinct counting.
- Matrix and nested-dataframe n previously counted measured cells rather than observations. Both counts now describe complete rows;
  rows with any missing component are excluded, and row identities determine uniqueness.
- A per-column implementation avoids the previous across/reshape failures for Unicode names. Existing rejection of duplicate,
  empty or missing selected names is explicitly preserved so label alignment cannot become ambiguous.
- Shared s_select probed both selection and transformation, then repeated the successful branch. It now caches the first success.
  Successful selection callbacks and predicates are not repeated; fallback computation is not rerun. Successful warnings are replayed once,
  failed-branch warnings are discarded as before, and both underlying errors remain available if neither branch works.
- Four legacy wide-matrix fixtures now request minimal names before assigning their intended names, removing fixture-only warnings.
- An initial hand-entered structured-count fixture contained two complete rows while its comment specified three.
  The fixture was corrected to the intended rows; production counts were not changed to accommodate the fixture.
  A new warning assertion was also corrected to recognize dplyr's normal wrapper while requiring one warning.

## Contracts and boundaries

- codebook returns an ungrouped tibble, ordered by selection: variable, optional label, type, n, unique.
  Types and units are preserved in the inventory; input values, labels, attributes and grouping are unchanged.
  Empty/all-missing columns retain zero-count rows; selecting no columns returns the typed empty inventory.
- The inventory ignores row grouping before selection. Unlike the names helpers, omitted grouping keys are not automatically reinserted.
  With no selection, grouping columns remain ordinary variables. Use summ/tabstat for group-specific numeric summaries.
- List elements are whole identities: scalar NA/NaN are missing, while NULL, empty vectors and nested values remain elements.
  Matrix/dataframe columns count complete observed rows, not individual cells. SPSS missingness follows the original is.na method.
- browse returns the viewed/selected data invisibly with its dataframe class and grouping preserved; it does not return a name vector.
  Headless R opens no viewer. The report explicitly prints returned values for readability.
  GUI handoff, error propagation and a single viewer call are tested with stubs. A real interactive viewer was not visually validated.
- Selection remains first, followed by data masking only after a failed selection. A failed selection can still execute user code before fallback.
  This is not a global exactly-once guarantee for arbitrary callbacks. Precompute random or side-effecting columns with mutate, then select their names.
  Numeric selection failures can remain valid computed constants; sequential computed-name overwrite follows existing transmute semantics.
- s_select changed as required shared support; its retained tests and direct warning/error/evaluation regressions are included.
  This pass provides numbered acceptance for codebook/browse, not a separate 100-case sign-off for every selector/type helper.
- Optional haven/units/hms/bit64/data.table paths ran here. Absent Suggests may cause ordinary testthat skips elsewhere;
  the standalone runner rejects all skips, failures, errors or uncaptured warnings.
- Independent QA found no material remaining issue. These two functions are locally accepted within the documented/headless scope.
  Real viewer validation, minimum R 4.1 and other platforms remain unverified. Next function family: conversion.
- The approved console PDF is unchanged. No dependencies, exports, datasets or native artifacts changed.
  No artifact deletion, push, merge, publication or release.

## Numbered cases

### codebook

Source: [test-codebook-coverage.R](../../tests/testthat/test-codebook-coverage.R).

| ID | Scenario | Status | Passing expectations |
| --- | --- | --- | ---: |
| 001 | integer storage and repeated values | PASS | 8 |
| 002 | doubles exclude ordinary missing values | PASS | 8 |
| 003 | logical values count both observed states | PASS | 8 |
| 004 | character blanks are observed distinct values | PASS | 8 |
| 005 | Unicode character values retain identity | PASS | 8 |
| 006 | factor counts omit unused levels | PASS | 8 |
| 007 | ordered factors preserve their type | PASS | 8 |
| 008 | complex missing values are excluded | PASS | 8 |
| 009 | raw zero is observed | PASS | 8 |
| 010 | all missing numeric columns retain a row | PASS | 8 |
| 011 | NaN is missing | PASS | 8 |
| 012 | infinities are observed distinct values | PASS | 8 |
| 013 | signed zeros have one identity | PASS | 8 |
| 014 | singleton observation | PASS | 8 |
| 015 | typed zero-row columns retain type and zero counts | PASS | 8 |
| 016 | no columns return the fixed empty schema | PASS | 8 |
| 017 | zero-column data frame with rows remains empty | PASS | 8 |
| 018 | all unique values have unique count equal to n | PASS | 8 |
| 019 | repetition changes n but not unique count | PASS | 8 |
| 020 | mixed storage reports in input column order | PASS | 8 |
| 021 | leap dates use observed date identity | PASS | 8 |
| 022 | datetime fractions count separate instants | PASS | 8 |
| 023 | timezone does not change instant counts | PASS | 8 |
| 024 | duration includes its declared unit | PASS | 8 |
| 025 | all missing duration retains unit metadata | PASS | 8 |
| 026 | hms reports seconds and missingness | PASS | 8 |
| 027 | measured units are displayed without conversion | PASS | 8 |
| 028 | empty measured vector retains unit | PASS | 8 |
| 029 | integer64 identity survives values above double precision | PASS | 8 |
| 030 | deterministic wider data agree with base counts | PASS | 7 |
| 031 | numeric haven labels do not merge value codes | PASS | 8 |
| 032 | character haven labels preserve raw identities | PASS | 8 |
| 033 | tagged missing codes are all excluded | PASS | 8 |
| 034 | SPSS discrete user missing codes are excluded from unique | PASS | 8 |
| 035 | SPSS multiple missing codes are excluded | PASS | 8 |
| 036 | SPSS missing range includes its endpoints | PASS | 8 |
| 037 | SPSS range and discrete exclusions compose | PASS | 8 |
| 038 | SPSS all user missing has no observed identities | PASS | 8 |
| 039 | SPSS character missing code is omitted | PASS | 8 |
| 040 | one variable label adds the ordered label column | PASS | 9 |
| 041 | mixed labels use NA for unlabelled variables | PASS | 9 |
| 042 | empty string label is treated as absent metadata | PASS | 8 |
| 043 | Unicode and multiline labels are unchanged | PASS | 9 |
| 044 | unselected labels do not add a label column | PASS | 2 |
| 045 | labelled empty column retains its label | PASS | 9 |
| 046 | value labels and variable labels remain distinct | PASS | 9 |
| 047 | labelled source is not mutated | PASS | 3 |
| 048 | measured source is not mutated | PASS | 9 |
| 049 | all missing labelled source retains type and metadata | PASS | 9 |
| 050 | list column label describes the whole variable | PASS | 9 |
| 051 | bare selection returns only requested variable | PASS | 2 |
| 052 | positive positions preserve requested order | PASS | 1 |
| 053 | negative selection omits specified columns | PASS | 1 |
| 054 | starts_with selects matching names | PASS | 1 |
| 055 | ends_with selects matching names | PASS | 1 |
| 056 | where selects numeric storage types | PASS | 1 |
| 057 | all_of supports programmatic selection order | PASS | 1 |
| 058 | absent any_of selection has fixed empty schema | PASS | 2 |
| 059 | renamed selection retains original label | PASS | 2 |
| 060 | computed column counts transformed values | PASS | 3 |
| 061 | logical computed columns retain logical type | PASS | 3 |
| 062 | multiple computed columns follow expression order | PASS | 3 |
| 063 | programmatic unquoting selects a column | PASS | 2 |
| 064 | data pronoun computes without column ambiguity | PASS | 3 |
| 065 | environment pronoun is available in computation | PASS | 3 |
| 066 | no-match prefix returns an empty result | PASS | 2 |
| 067 | explicit everything matches omitted selection | PASS | 1 |
| 068 | repeated selection does not duplicate variables | PASS | 2 |
| 069 | accepted computation is not rerun | PASS | 3 |
| 070 | filtering and selection compose in a pipeline | PASS | 3 |
| 071 | existing groups do not partition the codebook | PASS | 8 |
| 072 | multiple groups still yield one row per variable | PASS | 8 |
| 073 | grouped factor includes only observed levels | PASS | 8 |
| 074 | zero-row grouped data retain all variables | PASS | 8 |
| 075 | missing grouping keys are counted as missing data | PASS | 8 |
| 076 | rowwise data are summarized as whole columns | PASS | 8 |
| 077 | rowwise identifier remains an ordinary variable | PASS | 8 |
| 078 | grouped selection omits keys and preserves input | PASS | 3 |
| 079 | row permutation leaves codebook counts invariant | PASS | 1 |
| 080 | duplicating rows doubles n and preserves unique | PASS | 2 |
| 081 | list duplicate vectors count one identity | PASS | 8 |
| 082 | NULL and empty vectors remain list elements | PASS | 8 |
| 083 | nested list structure is compared by identity | PASS | 8 |
| 084 | empty list column keeps one metadata row | PASS | 8 |
| 085 | matrix columns count complete row observations | PASS | 8 |
| 086 | partial-missing matrix rows are incomplete observations | PASS | 8 |
| 087 | nested data frame uses complete-row identity | PASS | 8 |
| 088 | all incomplete nested rows have zero counts | PASS | 8 |
| 089 | base data frame returns tibble and preserves row names | PASS | 9 |
| 090 | data.table input returns tibble without mutation | PASS | 9 |
| 091 | metadata-like input names do not collide | PASS | 8 |
| 092 | Unicode non-syntactic names remain exact | PASS | 8 |
| 093 | reserved value name carries a variable label | PASS | 9 |
| 094 | NULL is rejected as non-data-frame input | PASS | 1 |
| 095 | atomic vector input is rejected | PASS | 1 |
| 096 | list input is rejected despite named columns | PASS | 1 |
| 097 | absent bare selection errors | PASS | 1 |
| 098 | out-of-range positional selection errors | PASS | 1 |
| 099 | invalid computed output size errors | PASS | 1 |
| 100 | codebook integrates labelled survey preparation | PASS | 5 |

### browse

Source: [test-browse-coverage.R](../../tests/testthat/test-browse-coverage.R).

| ID | Scenario | Status | Passing expectations |
| --- | --- | --- | ---: |
| 001 | tibble returns unchanged and invisibly | PASS | 2 |
| 002 | base data frame class and row names survive | PASS | 2 |
| 003 | data.table no-selection identity | PASS | 2 |
| 004 | zero-row typed input | PASS | 2 |
| 005 | zero-column input retains row count | PASS | 2 |
| 006 | completely empty tibble | PASS | 2 |
| 007 | single row input | PASS | 2 |
| 008 | single column input | PASS | 2 |
| 009 | wide input preserves every name | PASS | 2 |
| 010 | large input does not truncate returned rows | PASS | 2 |
| 011 | bare column selection | PASS | 2 |
| 012 | selection reorders columns | PASS | 2 |
| 013 | inclusive column range | PASS | 2 |
| 014 | negative selection | PASS | 2 |
| 015 | integer position selection | PASS | 2 |
| 016 | everything selection | PASS | 2 |
| 017 | starts_with selector | PASS | 2 |
| 018 | ends_with selector | PASS | 2 |
| 019 | contains selector | PASS | 2 |
| 020 | regular expression selector | PASS | 2 |
| 021 | numeric type predicate | PASS | 2 |
| 022 | character type predicate | PASS | 2 |
| 023 | predicate sees observed column contents | PASS | 2 |
| 024 | rename existing selected column | PASS | 2 |
| 025 | duplicate selections retain first position | PASS | 2 |
| 026 | all_of respects external vector order | PASS | 2 |
| 027 | any_of ignores unknown external names | PASS | 2 |
| 028 | unmatched helper yields zero columns | PASS | 2 |
| 029 | explicit NULL yields zero columns | PASS | 2 |
| 030 | negative everything yields zero columns | PASS | 2 |
| 031 | computed arithmetic column | PASS | 2 |
| 032 | computed logical column retains missing values | PASS | 2 |
| 033 | computed scalar recycles to row count | PASS | 2 |
| 034 | sequential computations see preceding columns | PASS | 2 |
| 035 | computed character transformation | PASS | 2 |
| 036 | computed row index | PASS | 2 |
| 037 | data pronoun accesses a column | PASS | 2 |
| 038 | environment pronoun accesses an external constant | PASS | 2 |
| 039 | empty computed numeric column | PASS | 2 |
| 040 | computed missing replacement | PASS | 2 |
| 041 | grouped no-selection object preserves metadata | PASS | 2 |
| 042 | explicit grouped selection retains key | PASS | 3 |
| 043 | grouped calculation uses group denominators | PASS | 2 |
| 044 | multiple grouping keys survive | PASS | 2 |
| 045 | unused factor group levels remain | PASS | 2 |
| 046 | rowwise no-selection identity | PASS | 2 |
| 047 | rowwise selected columns preserve rowwise class | PASS | 2 |
| 048 | rowwise list computations return one value per row | PASS | 2 |
| 049 | missing grouping key is retained | PASS | 2 |
| 050 | empty grouped data preserves groups | PASS | 2 |
| 051 | factor levels and ordering survive selection | PASS | 2 |
| 052 | Date values retain class | PASS | 2 |
| 053 | datetime timezone and fractions survive | PASS | 2 |
| 054 | difftime units survive selection | PASS | 2 |
| 055 | logical missing and observed values unchanged | PASS | 2 |
| 056 | complex column retains real and imaginary values | PASS | 2 |
| 057 | raw column bytes survive selection | PASS | 2 |
| 058 | nonfinite numeric values are not formatted away | PASS | 2 |
| 059 | nested list column identities survive | PASS | 2 |
| 060 | matrix column shape and dimnames survive | PASS | 2 |
| 061 | nested data-frame column survives | PASS | 2 |
| 062 | haven labels and tagged missing values survive | PASS | 2 |
| 063 | SPSS user-missing metadata survives | PASS | 2 |
| 064 | units metadata survives | PASS | 2 |
| 065 | integer64 exact values survive | PASS | 2 |
| 066 | variable label attribute survives selection | PASS | 2 |
| 067 | dataset custom attribute survives no selection | PASS | 2 |
| 068 | base selection preserves custom row names | PASS | 2 |
| 069 | data.table selection retains class without input mutation | PASS | 4 |
| 070 | selection never modifies original labels or names | PASS | 2 |
| 071 | spaces in column names | PASS | 2 |
| 072 | punctuation in column names | PASS | 2 |
| 073 | Unicode names selected programmatically | PASS | 2 |
| 074 | Unicode cell contents are not transliterated | PASS | 2 |
| 075 | reserved-looking names selected explicitly | PASS | 2 |
| 076 | embracing wrapper supports column selection | PASS | 2 |
| 077 | forwarded dots preserve selector order | PASS | 2 |
| 078 | injected expression performs computation | PASS | 2 |
| 079 | dynamic output name works | PASS | 2 |
| 080 | spliced selection expressions | PASS | 2 |
| 081 | unknown bare column errors clearly | PASS | 1 |
| 082 | all_of rejects missing requested column | PASS | 1 |
| 083 | out of range scalar falls back to data masking | PASS | 2 |
| 084 | incompatible computed length errors | PASS | 1 |
| 085 | duplicate output name uses sequential data-mask overwrite | PASS | 2 |
| 086 | computed expression failure remains informative | PASS | 1 |
| 087 | atomic input with selection errors | PASS | 1 |
| 088 | duplicate input names reject selection | PASS | 1 |
| 089 | filter then browse then model preparation | PASS | 2 |
| 090 | browse feeds grouped research summaries | PASS | 2 |
| 091 | browse feeds a base regression pipeline | PASS | 2 |
| 092 | browse feeds joins without changing keys | PASS | 2 |
| 093 | browse feeds long reshaping | PASS | 2 |
| 094 | input and successful all_of selector evaluate once | PASS | 3 |
| 095 | resolved data-mask computation executes once | PASS | 2 |
| 096 | type predicate executes once per column | PASS | 2 |
| 097 | single computed warning is preserved | PASS | 3 |
| 098 | viewer forwarding stub receives unchanged input once | PASS | 3 |
| 099 | viewer forwarding stub receives selected data once | PASS | 3 |
| 100 | viewer forwarding stub error propagates | PASS | 2 |

## Actual installed-package output

```text
Inventory and labels
codebook(d)
# A tibble: 4 x 5
  variable label                      type          n unique
  <chr>    <chr>                      <chr>     <int>  <int>
1 id       <NA>                       integer       4      4
2 region   <NA>                       character     4      2
3 age      <NA>                       double        3      3
4 income   Annual income in thousands double        3      3

Selected and renamed variables
codebook(d, earnings = income, age)
# A tibble: 2 x 5
  variable label                      type       n unique
  <chr>    <chr>                      <chr>  <int>  <int>
1 earnings Annual income in thousands double     3      3
2 age      <NA>                       double     3      3

Computed variables
codebook(d, high_income = income >= 50)
# A tibble: 1 x 4
  variable    type        n unique
  <chr>       <chr>   <int>  <int>
1 high_income logical     3      2

Grouped input remains one global inventory
codebook(dplyr::group_by(d, region))
# A tibble: 4 x 5
  variable label                      type          n unique
  <chr>    <chr>                      <chr>     <int>  <int>
1 id       <NA>                       integer       4      4
2 region   <NA>                       character     4      2
3 age      <NA>                       double        3      3
4 income   Annual income in thousands double        3      3

SPSS user-missing values excluded
codebook(spss)
# A tibble: 1 x 4
  variable type             n unique
  <chr>    <chr>        <int>  <int>
1 x        double+label     2      1

Structured columns count complete rows
codebook(structured)
# A tibble: 1 x 4
  variable type       n unique
  <chr>    <chr>  <int>  <int>
1 pair     double     3      2

Headless browse: explicitly print the returned data
browse(d, id, income)
# A tibble: 4 x 2
     id income
  <int>  <dbl>
1     1     32
2     2     48
3     3     55
4     4     NA

Browse visibility
withVisible(browse(d, age))$visible
[1] FALSE

Browse in a downstream pipeline
dplyr::mutate(browse(d, id, income), scaled = income/10)
# A tibble: 4 x 3
     id income scaled
  <int>  <dbl>  <dbl>
1     1     32    3.2
2     2     48    4.8
3     3     55    5.5
4     4     NA   NA
```

## Reproduce

Run `python .opencode/workflows/verify_package.py --check --prefix .opencode/results/codebook-browse-accepted`.
The workflow saves the fresh installed library path in codebook-browse-accepted-paths.json and uses the protected launcher.
For focused tests only, use `--filter "^codebook|^browse|^complex_tb$|^s_select$"` without --check.
Run `.opencode/tests/verify_codebook_browse.R <fresh-library-path> .opencode/results/codebook-browse-accepted` through the protected launcher
with child LC_ALL=C/LANG=C; capture combined stdout/stderr as codebook-browse-accepted-examples.log.
Regenerate this catalogue with `python .opencode/workflows/summarize_codebook_browse.py` after both runs.

Evidence: [full suite](../results/codebook-browse-accepted.csv), [diagnostics](../results/codebook-browse-accepted-details.csv),
[standalone cases](../results/codebook-browse-accepted-scenarios.csv), [actual output](../results/codebook-browse-accepted-examples.log),
[package check](../results/codebook-browse-accepted-check.log).
