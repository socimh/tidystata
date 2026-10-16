# Tabulation function acceptance

Verified 2026-10-16, statart 0.2.0.9000, Windows R 4.6.0.

**100 numbered scenarios pass independently for each of tab, fre, tab1, fre1, tab2 and fre2.**
Three paired matrices contain 300 distinct scenario definitions and 600 function/scenario executions.
All previous tests remain. Finite tests do not prove correctness for every possible input.

## Results

| Scope | Blocks | Passing expectations | Failures | Errors | Uncaptured warnings | Skips |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| Numbered matrix | 600 | 7547 | 0 | 0 | 0 | 0 |
| All tabulation tests and shared conversion regressions | 897 | 8258 | 0 | 0 | 0 | 0 |
| Full package | 2274 | 14255 | 0 | 0 | 22 | 1 |

Standalone elapsed: 67.81 seconds. Parsing, fresh native installation and source build pass.
R CMD check --no-manual: **Status: OK**, zero check errors, warnings or notes.
Remaining full-suite diagnostics belong to other families; test warnings and package-check warnings are separate.

## Reproduced defects and fixes

- Explicit .by on an already grouped input retained an old group key and split counts incorrectly.
  tab, fre, tab1 and fre1 now extract explicit groups from ungrouped data, then ungroup before preparation.
  Inherited grouping still applies when .by is omitted. Joint case 057 and one-way case 058 fail on the baseline and pass after the fix.
- Frequency rendering failed for haven_labelled vectors containing tagged missing values without value labels.
  as_character now uses ordinary character conversion when labels are absent, avoiding haven::as_factor calling na_tag(NULL).
  One-way case 092 and direct shared-helper regressions reproduce the baseline error and pass after the fix.
- An initial NULL-list fixture assumed first-appearance sorting; it now verifies identity-associated counts.
  Test-oracle corrections preserve raw SPSS identities and distinguish literal column name NA from missing row values.

## Verified contracts and limitations

- Counts use whole measured-row identities (joint), individual values (one-way), or two-dimensional cells (cross).
  Base-R match/tabulate/table and explicit arithmetic provide independent oracles. Permutation and duplication checks add invariants.
- percent/cum are percentages 0-100 within each group. valid uses observations with no missing measured fields;
  missing group keys remain groups and are not themselves a reason to exclude a measurement. Empty selections retain established containers.
- fre/fre1 insert synthetic rows whose cum is NA; observed categories, including Total, remain separate.
  Frequency presentation converts a measured value key to character for labels (wide joint tables use a separate total column).
  Distinct original values can display the same text, such as 0.1 + 0.2 and 0.3. Counts remain separate; use tab/tab1 to retain original types.
- Cross-table combined-header collisions and literal NA alongside missing column categories remain explicit errors.
  fre2 reserves the column category total. An observed row category total remains alongside the final marginal row; identify the final row by position.
- Windows LC_CTYPE=C causes R/dplyr native-encoding warnings for some non-ASCII column names.
  The affected cases narrowly assert those exact diagnostics while checking preserved names/counts; other warnings remain visible.
  This is not a claim that execution emits no warnings in every locale. UTF-8 locale behavior and other platforms remain release checks.
- Optional data.table/units/integer64/formatting paths depend on installed Suggests. They ran here; ordinary testthat runs may skip absent packages.
  The standalone acceptance runner rejects any skips, failures, errors or uncaptured warnings.
- No dependencies, exports, datasets or native artifacts changed. No push, merge, publication or release.
  These six functions are locally accepted release candidates within the documented boundaries; minimum R 4.1 and other platforms remain unverified.

## Numbered cases

### tab / fre

Source: [test-tab-coverage-joint.R](../../tests/testthat/test-tab-coverage-joint.R).

| ID | Scenario | tab | fre | Passing expectations (tab/fre) |
| --- | --- | --- | --- | ---: |
| 001 | repeated positive integers | PASS | PASS | 15/20 |
| 002 | negative and positive numeric values | PASS | PASS | 14/19 |
| 003 | nonintegral categories | PASS | PASS | 14/19 |
| 004 | all categories equal | PASS | PASS | 14/19 |
| 005 | singleton category | PASS | PASS | 14/19 |
| 006 | zero-row numeric input | PASS | PASS | 6/6 |
| 007 | all unique categories | PASS | PASS | 14/19 |
| 008 | logical proportions | PASS | PASS | 14/19 |
| 009 | logical categories with missing | PASS | PASS | 14/22 |
| 010 | empty strings and whitespace | PASS | PASS | 14/19 |
| 011 | case-sensitive text identity | PASS | PASS | 14/19 |
| 012 | Unicode category identities | PASS | PASS | 14/19 |
| 013 | control characters remain distinct | PASS | PASS | 14/19 |
| 014 | literal NA versus missing text | PASS | PASS | 14/22 |
| 015 | signed infinities | PASS | PASS | 14/19 |
| 016 | NA and NaN retain separate categories | PASS | PASS | 14/21 |
| 017 | signed zero shares identity | PASS | PASS | 14/19 |
| 018 | adjacent floating point categories | PASS | PASS | 14/7 |
| 019 | extremely small categories | PASS | PASS | 14/19 |
| 020 | large exact integer-valued doubles | PASS | PASS | 14/19 |
| 021 | all missing numeric categories | PASS | PASS | 14/19 |
| 022 | all missing text categories | PASS | PASS | 14/19 |
| 023 | one observed and missing category | PASS | PASS | 14/19 |
| 024 | two observed categories and missing | PASS | PASS | 14/22 |
| 025 | multiple distinct missing patterns | PASS | PASS | 14/21 |
| 026 | missingness in first measured variable | PASS | PASS | 14/24 |
| 027 | missingness in last measured variable | PASS | PASS | 14/24 |
| 028 | every row incomplete across columns | PASS | PASS | 14/21 |
| 029 | valid row denominator differs from category count | PASS | PASS | 14/22 |
| 030 | three-way complete-case denominator | PASS | PASS | 14/24 |
| 031 | factor keeps observed levels only | PASS | PASS | 15/20 |
| 032 | ordered factor categories | PASS | PASS | 15/20 |
| 033 | factor missing value | PASS | PASS | 14/22 |
| 034 | Date categories span leap day | PASS | PASS | 14/19 |
| 035 | Date missingness | PASS | PASS | 14/19 |
| 036 | UTC datetimes | PASS | PASS | 14/19 |
| 037 | difftime categories in hours | PASS | PASS | 14/22 |
| 038 | numeric labelled values render labels in fre | PASS | PASS | 14/22 |
| 039 | SPSS user-missing codes exclude valid denominator | PASS | PASS | 14/22 |
| 040 | SPSS missing range excludes valid denominator | PASS | PASS | 14/24 |
| 041 | two groups independent denominators | PASS | PASS | 19/29 |
| 042 | missing group key remains a real group | PASS | PASS | 24/39 |
| 043 | all missing group keys | PASS | PASS | 14/22 |
| 044 | numeric grouping keys | PASS | PASS | 19/29 |
| 045 | logical grouping keys | PASS | PASS | 24/39 |
| 046 | factor groups with unused levels | PASS | PASS | 19/29 |
| 047 | Date grouping keys | PASS | PASS | 19/29 |
| 048 | multiple grouping keys | PASS | PASS | 24/39 |
| 049 | multiple missing grouping-key patterns | PASS | PASS | 29/49 |
| 050 | all-missing measured values in one group | PASS | PASS | 19/29 |
| 051 | singleton groups | PASS | PASS | 34/59 |
| 052 | grouped joint missingness | PASS | PASS | 19/39 |
| 053 | Unicode group keys | PASS | PASS | 19/29 |
| 054 | grouped zero-row input | PASS | PASS | 6/6 |
| 055 | descending frequency inside each group | PASS | PASS | 23/39 |
| 056 | existing grouping inherited when by omitted | PASS | PASS | 19/29 |
| 057 | explicit by overrides pre-existing grouping | PASS | PASS | 19/29 |
| 058 | group key selected also is counted only as key | PASS | PASS | 18/28 |
| 059 | different group sizes and valid denominators | PASS | PASS | 19/32 |
| 060 | three grouping keys | PASS | PASS | 24/39 |
| 061 | starts_with selection | PASS | PASS | 13/18 |
| 062 | negative selection | PASS | PASS | 13/18 |
| 063 | numeric column positions | PASS | PASS | 13/18 |
| 064 | where numeric selection | PASS | PASS | 13/18 |
| 065 | renamed selected column | PASS | PASS | 13/18 |
| 066 | logical computed expression | PASS | PASS | 13/21 |
| 067 | numeric computed expression | PASS | PASS | 13/18 |
| 068 | computed categories alongside original column | PASS | PASS | 13/18 |
| 069 | non-syntactic column names | PASS | PASS | 14/19 |
| 070 | Unicode variable name | PASS | PASS | 14/19 |
| 071 | count output name is safely renamed | PASS | PASS | 14/19 |
| 072 | percentage output names are safely renamed | PASS | PASS | 14/19 |
| 073 | reserved group key remains a key after rename | PASS | PASS | 19/29 |
| 074 | reserved metadata names are safely renamed | PASS | PASS | 14/19 |
| 075 | reserved-name collision rejects ambiguous rename | PASS | PASS | 2/2 |
| 076 | literal Total category remains distinguishable | PASS | PASS | 13/21 |
| 077 | literal subtotal labels remain categories | PASS | PASS | 13/21 |
| 078 | descending counts keep missing values last | PASS | PASS | 16/24 |
| 079 | descending frequency tie retains exact counts | PASS | PASS | 16/21 |
| 080 | descending joint missing categories | PASS | PASS | 16/26 |
| 081 | list vectors are whole categories | PASS | PASS | 14/19 |
| 082 | list order is part of identity | PASS | PASS | 14/19 |
| 083 | list NULL and empty vector differ | PASS | PASS | 14/19 |
| 084 | nested list identities | PASS | PASS | 14/19 |
| 085 | list scalar missing values | PASS | PASS | 14/22 |
| 086 | five measured variables retain joint counts | PASS | PASS | 14/19 |
| 087 | six measured variables use separate total label | PASS | PASS | 14/22 |
| 088 | six measured variables with group key | PASS | PASS | 19/29 |
| 089 | no selected columns returns typed empty table | PASS | PASS | 5/5 |
| 090 | no selected columns preserves empty group schema | PASS | PASS | 5/5 |
| 091 | base data.frame input returns tibble | PASS | PASS | 13/18 |
| 092 | column labels and input attributes preserved | PASS | PASS | 14/19 |
| 093 | row permutation preserves joint frequencies | PASS | PASS | 14/22 |
| 094 | duplicating rows doubles counts with same percentages | PASS | PASS | 16/24 |
| 095 | deterministic 1000-row grouped survey | PASS | PASS | 34/73 |
| 096 | matrix columns reject unsupported structure | PASS | PASS | 1/1 |
| 097 | missing selected column errors | PASS | PASS | 1/1 |
| 098 | duplicate column names reject ambiguous inputs | PASS | PASS | 1/1 |
| 099 | NULL input is invalid | PASS | PASS | 1/1 |
| 100 | missing grouping column errors | PASS | PASS | 1/1 |

### tab1 / fre1

Source: [test-tab-coverage-oneway.R](../../tests/testthat/test-tab-coverage-oneway.R).

| ID | Scenario | tab1 | fre1 | Passing expectations (tab1/fre1) |
| --- | --- | --- | --- | ---: |
| 001 | positive integers | PASS | PASS | 12/16 |
| 002 | negative integers | PASS | PASS | 12/16 |
| 003 | mixed signs | PASS | PASS | 12/16 |
| 004 | one observation | PASS | PASS | 12/16 |
| 005 | constant nonzero | PASS | PASS | 12/16 |
| 006 | constant zero | PASS | PASS | 12/16 |
| 007 | all unique | PASS | PASS | 12/16 |
| 008 | unbalanced categories | PASS | PASS | 12/16 |
| 009 | fractional values | PASS | PASS | 12/16 |
| 010 | very small distinct values | PASS | PASS | 12/16 |
| 011 | very large values | PASS | PASS | 12/16 |
| 012 | integer storage endpoints | PASS | PASS | 12/16 |
| 013 | positive infinity | PASS | PASS | 12/16 |
| 014 | negative infinity | PASS | PASS | 12/16 |
| 015 | both infinities | PASS | PASS | 12/16 |
| 016 | NA at both ends | PASS | PASS | 12/17 |
| 017 | single observed value and missing | PASS | PASS | 12/16 |
| 018 | multiple observed values and missing | PASS | PASS | 12/17 |
| 019 | all numeric NA | PASS | PASS | 12/16 |
| 020 | empty doubles | PASS | PASS | 5/5 |
| 021 | empty integers | PASS | PASS | 5/5 |
| 022 | logical balance | PASS | PASS | 12/16 |
| 023 | logical missing | PASS | PASS | 12/17 |
| 024 | all logical missing | PASS | PASS | 12/16 |
| 025 | empty logicals | PASS | PASS | 5/5 |
| 026 | text repeated | PASS | PASS | 12/16 |
| 027 | text missing | PASS | PASS | 12/17 |
| 028 | empty strings are values | PASS | PASS | 12/17 |
| 029 | whitespace is significant | PASS | PASS | 12/16 |
| 030 | literal NA versus missing | PASS | PASS | 12/17 |
| 031 | case sensitive categories | PASS | PASS | 12/16 |
| 032 | punctuation categories | PASS | PASS | 12/16 |
| 033 | Unicode categories | PASS | PASS | 12/16 |
| 034 | empty text | PASS | PASS | 5/5 |
| 035 | all text missing | PASS | PASS | 12/16 |
| 036 | factor order and unused levels | PASS | PASS | 12/16 |
| 037 | factor missing | PASS | PASS | 12/17 |
| 038 | ordered factor | PASS | PASS | 12/16 |
| 039 | empty factor retains levels | PASS | PASS | 5/5 |
| 040 | all missing factor | PASS | PASS | 12/16 |
| 041 | leap day dates | PASS | PASS | 12/16 |
| 042 | dates with missing | PASS | PASS | 12/17 |
| 043 | empty dates | PASS | PASS | 5/5 |
| 044 | UTC datetime | PASS | PASS | 12/16 |
| 045 | datetime missing | PASS | PASS | 12/17 |
| 046 | empty datetime | PASS | PASS | 5/5 |
| 047 | difftime hours | PASS | PASS | 12/16 |
| 048 | descending frequency numeric | PASS | PASS | 13/18 |
| 049 | descending frequency text | PASS | PASS | 13/18 |
| 050 | ten thousand observations | PASS | PASS | 12/16 |
| 051 | base data frame returns list of tibbles | PASS | PASS | 3/3 |
| 052 | tibble output variable ordering | PASS | PASS | 2/2 |
| 053 | mixed numeric character table | PASS | PASS | 3/3 |
| 054 | integer double table is compatible | PASS | PASS | 2/2 |
| 055 | all factor table with different levels | PASS | PASS | 2/2 |
| 056 | group missing keys retained | PASS | PASS | 10/13 |
| 057 | inherited group matches explicit grouping | PASS | PASS | 1/1 |
| 058 | explicit group overrides existing grouping | PASS | PASS | 1/1 |
| 059 | multiple group keys use within-key denominator | PASS | PASS | 2/2 |
| 060 | factor group unused levels produce no phantom rows | PASS | PASS | 11/14 |
| 061 | numeric grouping keys retained | PASS | PASS | 11/14 |
| 062 | zero-row grouped selection | PASS | PASS | 2/2 |
| 063 | no measured variables list | PASS | PASS | 1/1 |
| 064 | no measured variables table | PASS | PASS | 2/2 |
| 065 | group-only selection is empty | PASS | PASS | 2/2 |
| 066 | starts_with selection | PASS | PASS | 1/1 |
| 067 | negative selection | PASS | PASS | 1/1 |
| 068 | programmatic all_of selection | PASS | PASS | 1/1 |
| 069 | renamed selected variable | PASS | PASS | 2/2 |
| 070 | computed logical expression | PASS | PASS | 1/1 |
| 071 | computed arithmetic expression | PASS | PASS | 1/1 |
| 072 | data pronoun expression | PASS | PASS | 1/1 |
| 073 | environment pronoun expression | PASS | PASS | 1/1 |
| 074 | nonsyntactic column names | PASS | PASS | 1/1 |
| 075 | Unicode column names | PASS | PASS | 1/1 |
| 076 | reserved measured name is renamed | PASS | PASS | 3/3 |
| 077 | reserved value group is renamed | PASS | PASS | 2/2 |
| 078 | reserved name with occupied dotted destination errors | PASS | PASS | 2/2 |
| 079 | matrix column rejected | PASS | PASS | 1/1 |
| 080 | nested data frame column rejected | PASS | PASS | 1/1 |
| 081 | invalid output type rejected | PASS | PASS | 1/1 |
| 082 | missing selected column rejected | PASS | PASS | 1/1 |
| 083 | missing grouping column rejected | PASS | PASS | 1/1 |
| 084 | NA descending flag rejected | PASS | PASS | 1/1 |
| 085 | vector descending flag rejected | PASS | PASS | 1/1 |
| 086 | list values count complete identities | PASS | PASS | 2/2 |
| 087 | nested lists count without flattening | PASS | PASS | 1/1 |
| 088 | NULL list entries remain categories | PASS | PASS | 3/3 |
| 089 | variable labels and input attributes preserved | PASS | PASS | 2/2 |
| 090 | labelled numeric values use original frequencies | PASS | PASS | 2/2 |
| 091 | SPSS user missing excluded from valid denominator | PASS | PASS | 3/3 |
| 092 | tagged missing values retain count mass | PASS | PASS | 3/3 |
| 093 | data table input unchanged | PASS | PASS | 3/3 |
| 094 | grouped descending order within each group | PASS | PASS | 2/2 |
| 095 | permutation preserves counts and order | PASS | PASS | 1/1 |
| 096 | duplication doubles counts preserves percentages | PASS | PASS | 4/4 |
| 097 | observed Total label is retained alongside marginal row | PASS | PASS | 2/2 |
| 098 | measured variables keep distinct missing denominators | PASS | PASS | 2/2 |
| 099 | grouped table includes variable identity and independent totals | PASS | PASS | 4/4 |
| 100 | two variables with equal values remain separate | PASS | PASS | 2/2 |

### tab2 / fre2

Source: [test-tab-coverage-cross.R](../../tests/testthat/test-tab-coverage-cross.R).

| ID | Scenario | tab2 | fre2 | Passing expectations (tab2/fre2) |
| --- | --- | --- | --- | ---: |
| 001 | balanced character grid | PASS | PASS | 12/16 |
| 002 | asymmetric repeated cells | PASS | PASS | 12/16 |
| 003 | single observed pair | PASS | PASS | 12/16 |
| 004 | one row category | PASS | PASS | 12/16 |
| 005 | one column category | PASS | PASS | 12/16 |
| 006 | diagonal absent cells | PASS | PASS | 12/16 |
| 007 | integer row categories | PASS | PASS | 12/16 |
| 008 | double column categories | PASS | PASS | 12/16 |
| 009 | logical in both dimensions | PASS | PASS | 12/16 |
| 010 | partially missing rows | PASS | PASS | 12/16 |
| 011 | partially missing columns | PASS | PASS | 12/16 |
| 012 | missing values in both dimensions | PASS | PASS | 12/16 |
| 013 | entirely missing rows | PASS | PASS | 12/16 |
| 014 | entirely missing columns | PASS | PASS | 12/16 |
| 015 | both dimensions entirely missing | PASS | PASS | 12/16 |
| 016 | NaN and NA are separate row identities | PASS | PASS | 12/16 |
| 017 | NaN and NA are separate column identities | PASS | PASS | 12/16 |
| 018 | positive and negative infinities | PASS | PASS | 12/16 |
| 019 | signed zero is one category | PASS | PASS | 12/16 |
| 020 | large magnitude numeric rows | PASS | PASS | 12/16 |
| 021 | tiny distinct numeric rows | PASS | PASS | 12/16 |
| 022 | row factors retain unused levels | PASS | PASS | 12/16 |
| 023 | column factors exclude unobserved categories | PASS | PASS | 12/16 |
| 024 | ordered factors in both dimensions | PASS | PASS | 12/16 |
| 025 | factor missing codes | PASS | PASS | 12/16 |
| 026 | Date row class | PASS | PASS | 12/16 |
| 027 | Date column labels | PASS | PASS | 12/16 |
| 028 | POSIXct row timestamps | PASS | PASS | 12/16 |
| 029 | difftime hour categories | PASS | PASS | 12/16 |
| 030 | complex row identities | PASS | PASS | 12/16 |
| 031 | non-ASCII row categories | PASS | PASS | 12/16 |
| 032 | non-ASCII column categories | PASS | PASS | 12/16 |
| 033 | emoji categories | PASS | PASS | 12/16 |
| 034 | whitespace row categories remain distinct | PASS | PASS | 12/16 |
| 035 | punctuation column labels | PASS | PASS | 12/16 |
| 036 | literal NA row category and missing row | PASS | PASS | 12/16 |
| 037 | column categories equal original variable names | PASS | PASS | 12/16 |
| 038 | factor with an explicit NA level | PASS | PASS | 12/16 |
| 039 | integer boundaries | PASS | PASS | 12/16 |
| 040 | leading zeros in character categories | PASS | PASS | 12/16 |
| 041 | flip rectangular data and margins | PASS | PASS | 12/16 |
| 042 | flip mixed missing categories | PASS | PASS | 12/16 |
| 043 | flip numeric and logical domains | PASS | PASS | 12/16 |
| 044 | flip factors with unused levels | PASS | PASS | 12/16 |
| 045 | permuting observations preserves cells | PASS | PASS | 12/16 |
| 046 | replicating observations triples every count | PASS | PASS | 12/16 |
| 047 | deterministic 10000-row dense grid | PASS | PASS | 12/16 |
| 048 | high-cardinality sparse cells | PASS | PASS | 12/16 |
| 049 | highly unbalanced observations | PASS | PASS | 12/16 |
| 050 | filtered complete observations use filtered denominator | PASS | PASS | 12/16 |
| 051 | numeric positions select two variables | PASS | PASS | 12/16 |
| 052 | contiguous range selection | PASS | PASS | 12/16 |
| 053 | negative selection excludes extra columns | PASS | PASS | 12/16 |
| 054 | all_of programmatic character selection | PASS | PASS | 12/16 |
| 055 | starts_with helper | PASS | PASS | 12/16 |
| 056 | where helper selects character columns | PASS | PASS | 12/16 |
| 057 | renaming both selected variables | PASS | PASS | 12/16 |
| 058 | selection order determines dimensions | PASS | PASS | 12/16 |
| 059 | computed logical category | PASS | PASS | 12/16 |
| 060 | computed arithmetic category | PASS | PASS | 12/16 |
| 061 | non-syntactic input names | PASS | PASS | 12/16 |
| 062 | Unicode input names with explicit C-locale diagnostics | PASS | PASS | 13/17 |
| 063 | reserved count variable renamed with notice | PASS | PASS | 13/17 |
| 064 | reserved total variable renamed with notice | PASS | PASS | 13/17 |
| 065 | two reserved names renamed together | PASS | PASS | 13/17 |
| 066 | reserved rename target collision errors | PASS | PASS | 2/2 |
| 067 | combined header category collision errors | PASS | PASS | 1/1 |
| 068 | literal NA versus missing column collision errors | PASS | PASS | 1/1 |
| 069 | column total reserved only for frequency margins | PASS | PASS | 12/1 |
| 070 | flipping moves total column category into rows | PASS | PASS | 12/16 |
| 071 | literal Total column is case-sensitive | PASS | PASS | 12/16 |
| 072 | dotted and numeric-looking column categories | PASS | PASS | 12/16 |
| 073 | observed row named total is not conflated with margin | PASS | PASS | 13/17 |
| 074 | reserved names after flip use renamed header | PASS | PASS | 13/17 |
| 075 | literal NA column without actual missing is valid | PASS | PASS | 12/16 |
| 076 | zero-row character input returns empty table | PASS | PASS | 4/4 |
| 077 | zero-row typed input preserves row key class | PASS | PASS | 5/5 |
| 078 | empty tidyselect selection returns zero columns | PASS | PASS | 2/2 |
| 079 | explicit zero integer selection is empty | PASS | PASS | 1/1 |
| 080 | zero-column data frame returns empty table | PASS | PASS | 1/1 |
| 081 | one selected variable errors | PASS | PASS | 1/1 |
| 082 | three selected variables error | PASS | PASS | 1/1 |
| 083 | unknown variable selection errors | PASS | PASS | 1/1 |
| 084 | numeric constant expression becomes second category | PASS | PASS | 12/16 |
| 085 | NULL input errors | PASS | PASS | 1/1 |
| 086 | atomic input errors | PASS | PASS | 1/1 |
| 087 | matrix measured column errors | PASS | PASS | 1/1 |
| 088 | missing flip flag errors | PASS | PASS | 1/1 |
| 089 | multi-element flip flag errors | PASS | PASS | 1/1 |
| 090 | computed category wrong size errors | PASS | PASS | 1/1 |
| 091 | base data frame input is preserved | PASS | PASS | 13/17 |
| 092 | tibble attributes and variable labels are preserved | PASS | PASS | 13/17 |
| 093 | pre-grouped input is ungrouped without mutation | PASS | PASS | 14/18 |
| 094 | rowwise input produces global cross counts | PASS | PASS | 13/17 |
| 095 | data.table input is not changed by reference | PASS | PASS | 13/17 |
| 096 | labelled numeric rows use labels only in frequency rows | PASS | PASS | 12/16 |
| 097 | labelled numeric columns remain numeric category names | PASS | PASS | 12/16 |
| 098 | units row values retain native class or displayed values | PASS | PASS | 12/16 |
| 099 | integer64 values are counted without floating conversion | PASS | PASS | 12/16 |
| 100 | list row values are counted by complete identity | PASS | PASS | 12/16 |

## Actual installed-package output

```text
Joint counts
tab(d, x, y)
# A tibble: 3 x 7
      x y         n percent   cum valid valid_cum
  <dbl> <chr> <int>   <dbl> <dbl> <dbl>     <dbl>
1     1 a         1      25    25  33.3      33.3
2     2 b         2      50    75  66.7     100
3    NA a         1      25   100  NA        NA

Joint frequency totals
fre(d, x, y)
# A tibble: 5 x 7
      x y               n percent   cum valid valid_cum
  <dbl> <chr>       <int>   <dbl> <dbl> <dbl>     <dbl>
1     1 a               1      25    25  33.3      33.3
2     2 b               2      50    75  66.7     100
3    NA Valid Total     3      75    NA 100        NA
4    NA a               1      25   100  NA        NA
5    NA Total           4     100    NA  NA        NA

One-way tables
tab1(d, x, y)
$x
# A tibble: 3 x 6
  value     n percent   cum valid valid_cum
  <dbl> <int>   <dbl> <dbl> <dbl>     <dbl>
1     1     1      25    25  33.3      33.3
2     2     2      50    75  66.7     100
3    NA     1      25   100  NA        NA

$y
# A tibble: 2 x 6
  value     n percent   cum valid valid_cum
  <chr> <int>   <dbl> <dbl> <dbl>     <dbl>
1 a         2      50    50    50        50
2 b         2      50   100    50       100


Grouped one-way frequencies
fre1(d, x, .by = g, .type = "tibble")
# A tibble: 7 x 8
  variable g     value           n percent   cum valid valid_cum
  <chr>    <chr> <chr>       <int>   <dbl> <dbl> <dbl>     <dbl>
1 x        A     1               1    33.3  33.3    50        50
2 x        A     2               1    33.3  66.7    50       100
3 x        A     Valid Total     2    66.7  NA     100        NA
4 x        A     <NA>            1    33.3 100      NA        NA
5 x        A     Total           3   100    NA      NA        NA
6 x        <NA>  2               1   100   100     100       100
7 x        <NA>  Total           1   100    NA      NA        NA

Cross table
tab2(d, x, y)
# A tibble: 3 x 3
  `x \\ y`     a     b
     <dbl> <int> <int>
1        1     1     0
2        2     0     2
3       NA     1     0

Cross table with margins
fre2(d, x, y)
# A tibble: 4 x 4
  `x \\ y`     a     b total
  <chr>    <int> <int> <int>
1 1            1     0     1
2 2            0     2     2
3 <NA>         1     0     1
4 total        2     2     4

Explicit grouping overrides inherited group
tab(dplyr::group_by(d, y), x, .by = g)
# A tibble: 4 x 7
  g         x     n percent   cum valid valid_cum
  <chr> <dbl> <int>   <dbl> <dbl> <dbl>     <dbl>
1 A         1     1    33.3  33.3    50        50
2 A         2     1    33.3  66.7    50       100
3 A        NA     1    33.3 100      NA        NA
4 <NA>      2     1   100   100     100       100

Empty selection
fre(d, tidyselect::starts_with("absent"))
# A tibble: 0 x 5
# i 5 variables: n <int>, percent <dbl>, cum <dbl>, valid <dbl>, valid_cum <dbl>
```

## Reproduce and inspect

Run `python .opencode/workflows/verify_package.py --check --prefix .opencode/results/tabulation-accepted` from the repository root.
For tabulation only, use `--filter "^(tab|fre)"` without --check.
The workflow invokes the protected launcher and saves the fresh library path in tabulation-accepted-paths.json.
Run `.opencode/tests/verify_tabulation.R <fresh-library-path> .opencode/results/tabulation-accepted` through the protected launcher
with child LC_ALL=C and LANG=C. Capture combined stdout/stderr as tabulation-accepted-examples.log, including launcher exit status.
Regenerate this catalogue using `python .opencode/workflows/summarize_tabulation.py` after both runs.

Evidence: [full suite](../results/tabulation-accepted.csv), [diagnostics](../results/tabulation-accepted-details.csv),
[standalone cases](../results/tabulation-accepted-scenarios.csv), [output](../results/tabulation-accepted-examples.log),
[package check](../results/tabulation-accepted-check.log).
