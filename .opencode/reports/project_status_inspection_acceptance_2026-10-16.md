# Names and variable metadata acceptance

Verified 2026-10-16, statart 0.2.0.9000, Windows R 4.6.0.

**100 numbered scenarios pass independently for each of ds, ds_as_column, names_as_column, variables and variables_search.**
The three name helpers share one 100-case selection matrix; metadata and search each have their own 100-case matrix.
This is 300 scenario definitions and 500 function/scenario executions. Previous tests remain.
Finite tests do not prove every possible input/platform or establish a code-coverage percentage.

## Results

| Scope | Blocks | Passing expectations | Failures | Errors | Uncaptured warnings | Skips |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| Numbered matrix | 500 | 1084 | 0 | 0 | 0 | 0 |
| All inspection acceptance and retained names tests | 548 | 1169 | 0 | 0 | 0 | 0 |
| Full package | 2784 | 15366 | 0 | 0 | 19 | 1 |

Standalone elapsed: 7.52 seconds. Fresh native installation and source build pass.
R CMD check --no-manual: **Status: OK**, zero check errors, warnings or notes.
Remaining full-suite diagnostics are outside this inspection acceptance scope.

## Changes and preserved behavior

- variables_search now validates a single non-missing character query. Invalid types, zero-length, vector and NA queries error clearly;
  they previously failed in lower-level functions or silently recycled/returned no matches. The empty string still matches all variables.
- The shared range translator now returns valid letter ranges before attempting numeric conversion.
  This removes the spurious NAs-introduced warning for variables_search and s_match without changing their matches.
  Dedicated regressions failed against the baseline and pass against the fresh fixed installation.
- No behavior changes were needed in ds, ds_as_column, names_as_column or variables.
  Two legacy wide-matrix fixtures now request minimal names before assigning their intended column names, eliminating fixture-only warnings.
- Source help now documents existing-column tidyselect inputs, exact return containers, grouping retention, labels and search limits.
  Misleading data-masking wording was corrected; no computed-column feature was added.
- Source-based help was regenerated in an isolated directory and help examples executed successfully.
  No unrelated generated help files were changed.

## Contracts and boundaries

- ds returns a character vector. The two column aliases return an identical one-column tibble named name.
  Expected names are explicit fixture values; full vector/tibble identity checks include order, container and column type.
- Selectors, renames and grouping-key retention follow dplyr::select. Grouped empty selections can retain keys;
  ungroup first when the varlist must exclude them. Input rows, values, attributes and grouping remain unchanged.
- variables returns name plus a label column only if at least one selected variable has a usable scalar label attribute.
  Missing, empty or multivalue labels become NA; nonempty scalar labels are coerced to character.
  Selection and renaming preserve label alignment. Names/metadata remain available even with no observations.
- Search is case-insensitive and matches substrings of names or variable labels, never cell contents or value-label maps.
  Explicit anchors require a complete name/label match. Existing * / ? / ~ wildcards and a single letter/numeric range remain supported.
  Anchored numeric ranges, alternation, Unicode, selection-before-search and label-only matches have independent checks.
  This translated language is not a general-purpose regex interface; multiple ranges and malformed patterns remain errors.
- Queries containing several search alternatives can use the existing alternation syntax in one string; query vectors are not supported.
- Optional data.table coverage ran here; absent Suggests can cause ordinary testthat skips elsewhere.
  The standalone runner rejects every skip, failure, error or uncaptured warning.
- The previously approved console PDF is unchanged. These five helpers are locally accepted release candidates within these boundaries.
  codebook and browse are the next inspection pass. Minimum R 4.1 and other platforms remain unverified publication gates.
- No dependencies, exports, datasets or native artifacts changed. The early QA graphics probe artifact was preserved in ignored results,
  outside package tests. No deletion, push, merge, publication or release.

## Numbered cases

### ds / ds_as_column / names_as_column

Source: [test-inspection-coverage-names.R](../../tests/testthat/test-inspection-coverage-names.R).

| ID | Scenario | Status | Passing expectations (ds/ds_as_column/names_as_column) |
| --- | --- | --- | ---: |
| 001 | [schema] default listing preserves input column order | PASS | 1/1/1 |
| 002 | [schema] base data frames ignore row-name identities | PASS | 1/1/1 |
| 003 | [empty] zero observations retain the complete typed schema | PASS | 1/1/1 |
| 004 | [empty] positive row count without columns has no names | PASS | 1/1/1 |
| 005 | [empty] zero rows and zero columns produce a typed empty result | PASS | 1/1/1 |
| 006 | [schema] a single column is retained without scalar simplification | PASS | 1/1/1 |
| 007 | [schema] wide inputs retain every exact name in source order | PASS | 1/1/1 |
| 008 | [types] matrix and nested-frame columns remain single variables | PASS | 1/1/1 |
| 009 | [types] labels and custom column attributes do not replace names | PASS | 2/2/2 |
| 010 | [grouping] default listing keeps original position of grouping columns | PASS | 1/1/1 |
| 011 | [grouping] omitted group keys are restored before selected variables | PASS | 2/2/2 |
| 012 | [grouping] multiple omitted group keys retain grouping declaration order | PASS | 2/2/2 |
| 013 | [grouping] explicit exclusion cannot remove a grouping key | PASS | 2/2/2 |
| 014 | [grouping] explicitly selected keys respect requested selection order | PASS | 1/1/1 |
| 015 | [grouping] everything does not move a grouping key already selected | PASS | 1/1/1 |
| 016 | [grouping] renaming a grouping key returns its new name | PASS | 1/1/1 |
| 017 | [grouping] an empty selection on grouped data retains only the keys | PASS | 2/2/2 |
| 018 | [grouping] type selection retains a nonnumeric grouping key | PASS | 2/2/2 |
| 019 | [grouping] rowwise data without identifier keys allow ordinary selection | PASS | 1/1/1 |
| 020 | [grouping] rowwise identifier keys are restored when omitted | PASS | 2/2/2 |
| 021 | [selection] a bare column name selects exactly that variable | PASS | 1/1/1 |
| 022 | [selection] a literal string selects a named column | PASS | 1/1/1 |
| 023 | [selection] a literal string vector specifies output order | PASS | 1/1/1 |
| 024 | [selection] a positive integer selects by position | PASS | 1/1/1 |
| 025 | [selection] a vector of positions preserves the requested permutation | PASS | 1/1/1 |
| 026 | [selection] a named range includes both endpoints | PASS | 1/1/1 |
| 027 | [selection] a reverse range reverses selected source order | PASS | 1/1/1 |
| 028 | [selection] negative names remove columns without reordering the remainder | PASS | 1/1/1 |
| 029 | [selection] negative positions exclude nonadjacent columns | PASS | 1/1/1 |
| 030 | [selection] a concatenation of bare names sets explicit order | PASS | 1/1/1 |
| 031 | [selection] repeated selections do not duplicate names | PASS | 1/1/1 |
| 032 | [rename] a renamed repeated source has one selected output name | PASS | 1/1/1 |
| 033 | [rename] renaming a single column returns only the replacement | PASS | 1/1/1 |
| 034 | [rename] multiple renamed selections preserve argument order | PASS | 1/1/1 |
| 035 | [rename] renamed variables followed by everything are not duplicated | PASS | 1/1/1 |
| 036 | [rename] named all_of mappings rename and reorder programmatically | PASS | 1/1/1 |
| 037 | [rename] named any_of mappings ignore absent sources and retain aliases | PASS | 1/1/1 |
| 038 | [programmatic] all_of follows external name order | PASS | 1/1/1 |
| 039 | [programmatic] any_of drops unknown names without changing known order | PASS | 1/1/1 |
| 040 | [empty] all_of accepts an empty character selection | PASS | 1/1/1 |
| 041 | [empty] any_of with no existing names returns no variables | PASS | 1/1/1 |
| 042 | [empty] an explicit empty integer selection returns no variables | PASS | 1/1/1 |
| 043 | [empty] NULL is an empty tidyselect specification | PASS | 1/1/1 |
| 044 | [empty] excluding everything yields no names | PASS | 1/1/1 |
| 045 | [helpers] starts_with is case insensitive by default | PASS | 1/1/1 |
| 046 | [helpers] starts_with can enforce case-sensitive matching | PASS | 2/2/2 |
| 047 | [helpers] ends_with uses case insensitive suffix matching | PASS | 1/1/1 |
| 048 | [helpers] ends_with can enforce case-sensitive suffix matching | PASS | 1/1/1 |
| 049 | [helpers] contains treats punctuation literally rather than as regex | PASS | 1/1/1 |
| 050 | [helpers] matches accepts anchored regular expressions | PASS | 1/1/1 |
| 051 | [helpers] regex matching respects explicit case sensitivity | PASS | 2/2/2 |
| 052 | [helpers] helper vectors combine matches in helper-pattern order | PASS | 1/1/1 |
| 053 | [helpers] num_range matches only requested numeric suffixes | PASS | 1/1/1 |
| 054 | [helpers] num_range width distinguishes zero-padded suffixes | PASS | 1/1/1 |
| 055 | [types] numeric predicates include integers but exclude dates and logicals | PASS | 1/1/1 |
| 056 | [types] integer predicates distinguish stored integer columns | PASS | 1/1/1 |
| 057 | [types] logical predicates keep all-missing and observed logical columns | PASS | 1/1/1 |
| 058 | [types] character predicates do not include factor columns | PASS | 1/1/1 |
| 059 | [types] factor predicates recognize ordered and unordered categories | PASS | 1/1/1 |
| 060 | [types] inheritance predicates distinguish dates from datetimes | PASS | 1/1/1 |
| 061 | [types] list predicates keep list and nested-frame columns | PASS | 1/1/1 |
| 062 | [types] custom predicates can select by variable attributes | PASS | 1/1/1 |
| 063 | [composition] intersection combines name and type predicates | PASS | 1/1/1 |
| 064 | [composition] union combines disjoint predicates in source order | PASS | 1/1/1 |
| 065 | [composition] complement excludes every matching helper variable | PASS | 1/1/1 |
| 066 | [composition] an exclusion refines a previously selected helper set | PASS | 1/1/1 |
| 067 | [composition] overlapping helpers deduplicate at first occurrence | PASS | 1/1/1 |
| 068 | [helpers] last_col addresses the actual final variable | PASS | 1/1/1 |
| 069 | [helpers] last_col supports offsets from the final variable | PASS | 1/1/1 |
| 070 | [programmatic] spliced selection expressions retain expression order | PASS | 1/1/1 |
| 071 | [programmatic] embracing forwards a caller selection into each entry point | PASS | 1/1/1 |
| 072 | [programmatic] injected symbols select variables without string parsing | PASS | 1/1/1 |
| 073 | [programmatic] all_of resolves an enclosing function argument | PASS | 1/1/1 |
| 074 | [programmatic] all_of avoids ambiguity with a same-named data column | PASS | 1/1/1 |
| 075 | [programmatic] conditional selection uses explicit caller decisions | PASS | 2/2/2 |
| 076 | [names] Unicode names retain their exact code points and order | PASS | 1/1/1 |
| 077 | [names] Unicode names support strict programmatic reordering | PASS | 1/1/1 |
| 078 | [names] names with spaces support literal tidyselect syntax | PASS | 1/1/1 |
| 079 | [names] punctuation in names is preserved by strict string selection | PASS | 1/1/1 |
| 080 | [names] pronoun-like column names are addressable with all_of | PASS | 1/1/1 |
| 081 | [names] long variable names are not truncated | PASS | 2/2/2 |
| 082 | [names] default listing reports duplicate raw names without repairing them | PASS | 1/1/1 |
| 083 | [errors] tidyselect rejects ambiguous duplicated source names | PASS | 1/1/1 |
| 084 | [names] leading and trailing spaces are significant in strict selection | PASS | 1/1/1 |
| 085 | [names] case-distinct names remain separate under exact selection | PASS | 1/1/1 |
| 086 | [preservation] renaming selections leave source data and attributes unchanged | PASS | 2/2/2 |
| 087 | [preservation] grouped selection leaves keys and group metadata unchanged | PASS | 3/3/3 |
| 088 | [classes] data table selection does not modify names or keys by reference | PASS | 3/3/3 |
| 089 | [classes] a data-frame subclass produces the standard names result | PASS | 2/2/2 |
| 090 | [pipeline] names extracted from a selection can drive a later mutate | PASS | 5/5/5 |
| 091 | [selection] negative selection of all named columns yields no variables | PASS | 1/1/1 |
| 092 | [empty] helpers on a zero-column frame return no variables | PASS | 2/2/2 |
| 093 | [errors] an unknown bare column reports the missing variable | PASS | 1/1/1 |
| 094 | [errors] strict all_of reports unknown requested names | PASS | 1/1/1 |
| 095 | [errors] a positive out-of-bounds index reports absent positions | PASS | 1/1/1 |
| 096 | [errors] an out-of-bounds negative index is rejected | PASS | 1/1/1 |
| 097 | [composition] signed tidyselect vectors apply exclusion after inclusion | PASS | 1/1/1 |
| 098 | [errors] logical selection is rejected rather than recycled across columns | PASS | 1/1/1 |
| 099 | [errors] renaming distinct sources to a duplicate name is rejected | PASS | 1/1/1 |
| 100 | [errors] selection requires data-frame input rather than an atomic scalar | PASS | 1/1/1 |

### variables

Source: [test-inspection-coverage-metadata.R](../../tests/testthat/test-inspection-coverage-metadata.R).

| ID | Scenario | Status | Passing expectations (variables) |
| --- | --- | --- | ---: |
| 001 | label attribute on integer column | PASS | 5 |
| 002 | label attribute on double column | PASS | 5 |
| 003 | label attribute on logical column | PASS | 5 |
| 004 | label attribute on character column | PASS | 5 |
| 005 | label attribute on complex column | PASS | 5 |
| 006 | label attribute on raw column | PASS | 5 |
| 007 | label attribute on factor column | PASS | 5 |
| 008 | label attribute on ordered column | PASS | 5 |
| 009 | label attribute on date column | PASS | 5 |
| 010 | label attribute on datetime column | PASS | 5 |
| 011 | label attribute on difftime column | PASS | 5 |
| 012 | label attribute on list column | PASS | 5 |
| 013 | label attribute on nested_list column | PASS | 5 |
| 014 | label attribute on matrix column | PASS | 5 |
| 015 | label attribute on nested_frame column | PASS | 5 |
| 016 | label attribute on all_missing column | PASS | 5 |
| 017 | label attribute on nan column | PASS | 5 |
| 018 | label attribute on infinite column | PASS | 5 |
| 019 | label attribute on empty_numeric column | PASS | 5 |
| 020 | label attribute on empty_character column | PASS | 5 |
| 021 | label attribute on empty_list column | PASS | 5 |
| 022 | label attribute on singleton column | PASS | 5 |
| 023 | label attribute on named column | PASS | 5 |
| 024 | label attribute on as_is column | PASS | 5 |
| 025 | label attribute on classed_numeric column | PASS | 5 |
| 026 | normalize absent label attribute | PASS | 4 |
| 027 | normalize empty label attribute | PASS | 4 |
| 028 | normalize missing label attribute | PASS | 4 |
| 029 | normalize multi label attribute | PASS | 4 |
| 030 | normalize zero_length label attribute | PASS | 4 |
| 031 | normalize integer label attribute | PASS | 5 |
| 032 | normalize double label attribute | PASS | 5 |
| 033 | normalize logical label attribute | PASS | 5 |
| 034 | normalize date label attribute | PASS | 5 |
| 035 | normalize named label attribute | PASS | 5 |
| 036 | normalize whitespace label attribute | PASS | 5 |
| 037 | normalize newline label attribute | PASS | 5 |
| 038 | normalize unicode label attribute | PASS | 5 |
| 039 | normalize punctuation label attribute | PASS | 5 |
| 040 | normalize literal_na label attribute | PASS | 5 |
| 041 | tidyselect one aligns labels | PASS | 5 |
| 042 | tidyselect reorder aligns labels | PASS | 5 |
| 043 | tidyselect negative aligns labels | PASS | 5 |
| 044 | tidyselect range aligns labels | PASS | 5 |
| 045 | tidyselect starts aligns labels | PASS | 5 |
| 046 | tidyselect ends aligns labels | PASS | 5 |
| 047 | tidyselect contains aligns labels | PASS | 4 |
| 048 | tidyselect matches aligns labels | PASS | 5 |
| 049 | tidyselect numeric aligns labels | PASS | 5 |
| 050 | tidyselect character aligns labels | PASS | 4 |
| 051 | tidyselect logical aligns labels | PASS | 5 |
| 052 | tidyselect all_of aligns labels | PASS | 5 |
| 053 | tidyselect any_of aligns labels | PASS | 4 |
| 054 | tidyselect empty aligns labels | PASS | 4 |
| 055 | tidyselect no_match aligns labels | PASS | 4 |
| 056 | tidyselect rename aligns labels | PASS | 5 |
| 057 | tidyselect rename_multiple aligns labels | PASS | 5 |
| 058 | tidyselect repeated aligns labels | PASS | 5 |
| 059 | tidyselect positions aligns labels | PASS | 5 |
| 060 | tidyselect boolean aligns labels | PASS | 5 |
| 061 | base data frame returns tibble metadata | PASS | 5 |
| 062 | data.table is inspected without modification | PASS | 5 |
| 063 | grouped selection retains grouping variable | PASS | 6 |
| 064 | rowwise tibble retains all names | PASS | 5 |
| 065 | zero-row labelled columns remain visible | PASS | 5 |
| 066 | zero-column base data frame is empty metadata | PASS | 4 |
| 067 | positive-row zero-column tibble is empty metadata | PASS | 4 |
| 068 | non-syntactic names remain verbatim | PASS | 4 |
| 069 | Unicode names remain verbatim | PASS | 4 |
| 070 | reserved output names do not replace metadata | PASS | 5 |
| 071 | label-like attribute is not partially matched | PASS | 4 |
| 072 | value label map does not become variable label | PASS | 4 |
| 073 | haven variable label is independent of value labels | PASS | 5 |
| 074 | SPSS missing metadata preserves variable label | PASS | 5 |
| 075 | long labels are not truncated | PASS | 5 |
| 076 | mixed valid and invalid labels yield explicit NA | PASS | 5 |
| 077 | one label shared by several columns remains repeated | PASS | 5 |
| 078 | column values are never mistaken for metadata | PASS | 4 |
| 079 | dataset-level label does not label each column | PASS | 4 |
| 080 | nonstandard column attributes are preserved | PASS | 5 |
| 081 | custom row names do not appear as variables | PASS | 4 |
| 082 | negative zero position selects no columns | PASS | 4 |
| 083 | reversed tidyselect range reverses metadata order | PASS | 5 |
| 084 | selection union keeps first appearance order | PASS | 5 |
| 085 | selection complement preserves remaining labels | PASS | 5 |
| 086 | reject missing_name selection | PASS | 2 |
| 087 | reject all_of_missing selection | PASS | 2 |
| 088 | reject out_of_bounds selection | PASS | 2 |
| 089 | reject duplicate_new_names selection | PASS | 2 |
| 090 | reject computed_numeric selection | PASS | 2 |
| 091 | reject computed_log selection | PASS | 2 |
| 092 | reject computed_character selection | PASS | 2 |
| 093 | reject row_predicate selection | PASS | 2 |
| 094 | reject nonexistent_rename selection | PASS | 2 |
| 095 | reject fractional_position selection | PASS | 2 |
| 096 | metadata joins to research dictionaries by name | PASS | 2 |
| 097 | renamed selection can form a presentation dictionary | PASS | 2 |
| 098 | metadata is invariant to research row filtering | PASS | 1 |
| 099 | wide dictionary retains 250 labels in column order | PASS | 5 |
| 100 | row binding does not expand the metadata table | PASS | 1 |

### variables_search

Source: [test-inspection-coverage-metadata.R](../../tests/testthat/test-inspection-coverage-metadata.R).

| ID | Scenario | Status | Passing expectations (variables_search) |
| --- | --- | --- | ---: |
| 001 | pattern substring | PASS | 3 |
| 002 | pattern uppercase | PASS | 3 |
| 003 | pattern mixed_case | PASS | 3 |
| 004 | pattern exact | PASS | 3 |
| 005 | pattern prefix | PASS | 3 |
| 006 | pattern suffix | PASS | 3 |
| 007 | pattern missing | PASS | 3 |
| 008 | pattern empty | PASS | 3 |
| 009 | pattern all_star | PASS | 3 |
| 010 | pattern star_zero | PASS | 3 |
| 011 | pattern star_prefix | PASS | 3 |
| 012 | pattern star_suffix | PASS | 3 |
| 013 | pattern question_exact | PASS | 3 |
| 014 | pattern question_substring | PASS | 3 |
| 015 | pattern double_question | PASS | 3 |
| 016 | pattern tilde_nonempty | PASS | 3 |
| 017 | pattern tilde_suffix | PASS | 3 |
| 018 | pattern combination | PASS | 3 |
| 019 | pattern numeric_single | PASS | 3 |
| 020 | pattern numeric_multi | PASS | 3 |
| 021 | pattern numeric_substring | PASS | 3 |
| 022 | pattern numeric_anchor | PASS | 3 |
| 023 | pattern numeric_zero | PASS | 3 |
| 024 | pattern numeric_suffix | PASS | 3 |
| 025 | pattern alphabet | PASS | 3 |
| 026 | pattern capital_range | PASS | 3 |
| 027 | pattern alternation | PASS | 3 |
| 028 | pattern grouped_alternation | PASS | 3 |
| 029 | pattern regex_dot | PASS | 3 |
| 030 | pattern literal_dot | PASS | 3 |
| 031 | pattern literal_plus | PASS | 3 |
| 032 | pattern literal_parentheses | PASS | 3 |
| 033 | pattern literal_dollar | PASS | 3 |
| 034 | pattern literal_caret | PASS | 3 |
| 035 | pattern literal_braces | PASS | 3 |
| 036 | pattern literal_pipe | PASS | 3 |
| 037 | pattern spaces | PASS | 3 |
| 038 | pattern hyphen | PASS | 3 |
| 039 | pattern unicode | PASS | 3 |
| 040 | pattern utf8_question | PASS | 3 |
| 041 | label label_only | PASS | 4 |
| 042 | label label_case | PASS | 4 |
| 043 | label label_exact | PASS | 4 |
| 044 | label label_prefix | PASS | 4 |
| 045 | label label_suffix | PASS | 4 |
| 046 | label label_wildcard | PASS | 4 |
| 047 | label label_question | PASS | 4 |
| 048 | label label_tilde | PASS | 4 |
| 049 | label label_range | PASS | 4 |
| 050 | label label_unicode | PASS | 4 |
| 051 | label missing_label_name_match | PASS | 4 |
| 052 | label empty_label_name_match | PASS | 4 |
| 053 | label name_label_union | PASS | 4 |
| 054 | label duplicate_label | PASS | 4 |
| 055 | label metadata_output | PASS | 4 |
| 056 | selection reorder | PASS | 3 |
| 057 | selection exclude_match | PASS | 3 |
| 058 | selection include_label | PASS | 3 |
| 059 | selection empty | PASS | 3 |
| 060 | selection starts | PASS | 3 |
| 061 | selection where_numeric | PASS | 3 |
| 062 | selection negative | PASS | 3 |
| 063 | selection rename_name | PASS | 3 |
| 064 | selection rename_label | PASS | 3 |
| 065 | selection original_name_gone | PASS | 3 |
| 066 | selection all_of | PASS | 3 |
| 067 | selection any_of | PASS | 3 |
| 068 | selection intersection | PASS | 3 |
| 069 | selection reverse_range | PASS | 3 |
| 070 | selection duplicate | PASS | 3 |
| 071 | reject empty query | PASS | 1 |
| 072 | reject vector query | PASS | 1 |
| 073 | reject missing query | PASS | 1 |
| 074 | reject integer query | PASS | 1 |
| 075 | reject double query | PASS | 1 |
| 076 | reject logical query | PASS | 1 |
| 077 | reject list query | PASS | 1 |
| 078 | reject null query | PASS | 1 |
| 079 | reject factor query | PASS | 1 |
| 080 | reject vector_with_na query | PASS | 1 |
| 081 | decreasing numeric range rejects clearly | PASS | 1 |
| 082 | two numeric ranges reject rather than mis-match | PASS | 1 |
| 083 | invalid regex rejects visibly | PASS | 1 |
| 084 | invalid alphabetical range rejects visibly | PASS | 1 |
| 085 | unknown selected variable rejects visibly | PASS | 1 |
| 086 | computed variable selection is unsupported | PASS | 1 |
| 087 | empty base dataset returns empty tibble | PASS | 3 |
| 088 | zero-row dataset still searches metadata | PASS | 3 |
| 089 | cell contents are not searchable metadata | PASS | 3 |
| 090 | value label map is not searchable variable metadata | PASS | 3 |
| 091 | missing-only labels leave name matching usable | PASS | 3 |
| 092 | blank-only labels leave name matching usable | PASS | 3 |
| 093 | data.table search returns tibble without mutation | PASS | 3 |
| 094 | grouped input uses metadata without row grouping | PASS | 3 |
| 095 | base frame search retains label column | PASS | 4 |
| 096 | numeric variable label is coerced before matching | PASS | 4 |
| 097 | programmatic query and all_of form a dictionary pipeline | PASS | 2 |
| 098 | search result names select downstream research columns | PASS | 2 |
| 099 | wide label search agrees with independent base substring oracle | PASS | 3 |
| 100 | row permutation and duplication cannot change metadata matches | PASS | 1 |

## Actual installed-package output

```text
Select variable names
ds(d, tidyselect::starts_with("income"))
[1] "income"     "income_net"

Names as a table
names_as_column(d, age, income)
# A tibble: 2 x 1
  name
  <chr>
1 age
2 income

Alias with column selection
ds_as_column(d, region, id)
# A tibble: 2 x 1
  name
  <chr>
1 region
2 id

Variable list and labels
variables(d)
# A tibble: 5 x 2
  name       label
  <chr>      <chr>
1 id         <NA>
2 income     Annual household income
3 income_net <NA>
4 age        Respondent age in years
5 region     <NA>

Search labels, ignoring case
variables_search(d, "HOUSEHOLD")
# A tibble: 1 x 2
  name   label
  <chr>  <chr>
1 income Annual household income

Substring default
variables_search(d, "income")
# A tibble: 2 x 2
  name       label
  <chr>      <chr>
1 income     Annual household income
2 income_net <NA>

Explicit complete-name match
variables_search(d, "^income$")
# A tibble: 1 x 2
  name   label
  <chr>  <chr>
1 income Annual household income

Renamed variable retains its label
variables(d, earnings = income)
# A tibble: 1 x 2
  name     label
  <chr>    <chr>
1 earnings Annual household income

Feed a discovered varlist into a later summary
summ(d, tidyselect::all_of(ds(d, income, income_net)))
# A tibble: 2 x 8
  name       type      n unique   min  mean    sd   max
  <chr>      <chr> <int>  <int> <dbl> <dbl> <dbl> <dbl>
1 income     dbl       2      2    32    40 11.3     48
2 income_net dbl       2      2    28    35  9.90    42
```

## Reproduce

Run `python .opencode/workflows/verify_package.py --check --prefix .opencode/results/inspection-accepted`.
The workflow saves the fresh installed library path in inspection-accepted-paths.json and invokes the protected launcher.
For focused tests only, use `--filter "^names$|^inspection-"` without --check.
Run `.opencode/tests/verify_inspection.R <fresh-library-path> .opencode/results/inspection-accepted` through the protected launcher
with child LC_ALL=C/LANG=C; capture combined stdout/stderr as inspection-accepted-examples.log.
Regenerate this report with `python .opencode/workflows/summarize_inspection.py` after both runs.

Evidence: [full suite](../results/inspection-accepted.csv), [diagnostics](../results/inspection-accepted-details.csv),
[standalone cases](../results/inspection-accepted-scenarios.csv), [actual output](../results/inspection-accepted-examples.log),
[package check](../results/inspection-accepted-check.log).
