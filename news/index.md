# Changelog

## tidystata 0.4.0

- [`findit()`](https://socimh.github.io/tidystata/reference/findit.md)
  and the bilingual Stata-to-R reference correct advanced statistical
  mappings and omit pairs without a close R counterpart. Bayesian
  examples use explicit posterior summaries and fitted-model prediction
  methods; IPW examples estimate treatment effects with joint
  uncertainty.

- The bilingual Stata-to-R reference opens as smaller subject chapters
  within the package website, with chapter navigation and expandable
  alternatives.

- [`findit()`](https://socimh.github.io/tidystata/reference/findit.md)
  customizes catalogue examples from Stata text enclosed in backticks or
  strings, including `` findit(`tab sex region`, row) `` and
  `findit("tab sex region, row")`. New
  [`findit_selection()`](https://socimh.github.io/tidystata/reference/findit_selection.md)
  and
  [`findit_clip()`](https://socimh.github.io/tidystata/reference/findit_selection.md)
  look up one command from the source editor or clipboard and print the
  result. The selection helper is registered as the Find Stata
  equivalent addin.

- [`findit()`](https://socimh.github.io/tidystata/reference/findit.md)
  omits built-in package labels and unnecessary namespace prefixes from
  printed examples, retaining qualification for conflicting names.
  Returned code and package metadata are preserved. Moving averages use
  `zoo::rollapply()` with partial windows and nonmissing values.

- [`destring()`](https://socimh.github.io/tidystata/reference/type_conversion.md)
  and
  [`tostring()`](https://socimh.github.io/tidystata/reference/type_conversion.md)
  ignore AsIs wrappers on non-character input.
  [`tostring()`](https://socimh.github.io/tidystata/reference/type_conversion.md)
  writes measured values and durations without exponents in their
  existing units; its help clarifies that large numeric IDs can lose
  digits.

- [`as_character()`](https://socimh.github.io/tidystata/reference/type_conversion.md)
  is now an exact alias of
  [`tostring()`](https://socimh.github.io/tidystata/reference/type_conversion.md),
  converting stored codes to text without reading value labels. Use
  [`decode()`](https://socimh.github.io/tidystata/reference/type_conversion.md)
  for the previous label-reading behavior. New
  [`encode()`](https://socimh.github.io/tidystata/reference/type_conversion.md)
  creates labelled integer codes from character categories, or preserves
  factor codes and levels as value labels. Re-encoding decoded text
  assigns fresh codes and need not restore old codes.

- [`destring()`](https://socimh.github.io/tidystata/reference/type_conversion.md)
  accepts non-breaking spaces and drops input names from `problems()`.
  [`destring()`](https://socimh.github.io/tidystata/reference/type_conversion.md),
  [`tostring()`](https://socimh.github.io/tidystata/reference/type_conversion.md)
  and
  [`decode()`](https://socimh.github.io/tidystata/reference/type_conversion.md)
  now reject data frames instead of returning one value per column.

- `pct()` is removed; use
  [`pc()`](https://socimh.github.io/tidystata/reference/std.md) for
  percentages of a total.
  [`findit()`](https://socimh.github.io/tidystata/reference/findit.md)
  distinguishes z-scores, total shares and percentile ranks, with
  executable examples using
  [`dplyr::percent_rank()`](https://dplyr.tidyverse.org/reference/percent_rank.html)
  on 0-1 and 0-100 scales.

- [`as_dummy()`](https://socimh.github.io/tidystata/reference/as_dummy.md)
  ([`tab_gen()`](https://socimh.github.io/tidystata/reference/as_dummy.md))
  supports `.names = "label"` for value-label names. The default
  `"value"` uses original values (raw codes for labelled vectors), while
  `"index"` uses consecutive category numbers.

- [`corr()`](https://socimh.github.io/tidystata/reference/corr.md),
  [`pwcorr()`](https://socimh.github.io/tidystata/reference/corr.md) and
  [`spearman()`](https://socimh.github.io/tidystata/reference/corr.md)
  share one help page and a dedicated correlation section in the website
  reference, with guidance on their different defaults and supported
  options.

- Head/tail preview omission markers align with printed numeric decimal
  points, or the last significand digit when no decimal is displayed.
  Row-number markers align with the last digit; other column types keep
  centered markers. Unicode output uses vertical ellipses, with periods
  as the fallback.

- [`findit()`](https://socimh.github.io/tidystata/reference/findit.md)
  separates family browsing from specific queries, retains at most ten
  ambiguous candidates, and prefers matching tidystata helpers before
  tidyverse and other implementations. Row recipes now use
  [`row_mean()`](https://socimh.github.io/tidystata/reference/row_egen.md)
  and related helpers; footers distinguish relevant results from broader
  operations. About 90 common data-management lookups that previously
  offered only base R, such as `tabstat`, `isid`, `misstable`, `sort`,
  `keep`/`drop if` and `egen` summaries, now recommend tidystata or
  tidyverse code and keep base R as an alternative. `drop if` and
  `replace ... if` recipes use dplyr 1.2’s
  [`filter_out()`](https://dplyr.tidyverse.org/reference/filter.html)
  and
  [`replace_when()`](https://dplyr.tidyverse.org/reference/case-and-replace-when.html),
  with notes for older dplyr. Negated conditions such as
  `keep if !missing(x)` no longer match their opposite.

- [`summ()`](https://socimh.github.io/tidystata/reference/summ.md) and
  [`tabstat()`](https://socimh.github.io/tidystata/reference/summ.md)
  report omitted non-numeric columns and the `*`/`**`/ `***` markers for
  labelled, factor and retained non-numeric variables as messages rather
  than warnings; silence them with
  [`suppressMessages()`](https://rdrr.io/r/base/message.html). Entirely
  missing columns and skipped date statistics still warn.

- [`summ()`](https://socimh.github.io/tidystata/reference/summ.md) and
  [`tabstat()`](https://socimh.github.io/tidystata/reference/summ.md)
  reuse native scratch storage for numerical summaries, weighted
  statistics and grouped distinct counts, reducing temporary allocation.
  Large two-column categorical tabulations use bounded native counting
  when a dense integer, logical or factor key is available. Other
  tabulations retain the general counting path. Public interfaces and
  statistical rules are unchanged.

- [`pwcorr()`](https://socimh.github.io/tidystata/reference/corr.md),
  [`corr()`](https://socimh.github.io/tidystata/reference/corr.md) and
  [`spearman()`](https://socimh.github.io/tidystata/reference/corr.md)
  compute every variable pair natively instead of allocating a row mask
  and subsets for each pair. Pearson and Spearman results, including
  p-values, are identical; Spearman tables on 100,000 rows and 30
  variables take seconds instead of a minute, and temporary allocation
  falls from gigabytes to megabytes. Integer, logical and labelled
  columns are read without conversion; SPSS-labelled columns are still
  converted so that their user-missing codes are excluded. Native
  correlation calculations preserve R’s intermediate rounding on Apple
  Silicon builds.

- Row functions such as
  [`row_max()`](https://socimh.github.io/tidystata/reference/row_egen.md)
  and
  [`row_sum()`](https://socimh.github.io/tidystata/reference/row_egen.md),
  and
  [`summ()`](https://socimh.github.io/tidystata/reference/summ.md)/[`tabstat()`](https://socimh.github.io/tidystata/reference/summ.md),
  read integer, logical and numeric labelled columns in place rather
  than copying them to doubles. Row functions also accept the same
  vector more than once, as Stata’s `egen rowmax(x x)` does.

- [`var_type()`](https://socimh.github.io/tidystata/reference/var_type.md)
  retains full primary class names when `abbr = FALSE` and the display
  label is a default class abbreviation, including S4 and S7 classes.
  Custom display labels and compact output are preserved;
  [`codebook()`](https://socimh.github.io/tidystata/reference/codebook.md)
  uses the improved descriptive labels.

- [`as_dummy()`](https://socimh.github.io/tidystata/reference/as_dummy.md)
  ([`tab_gen()`](https://socimh.github.io/tidystata/reference/as_dummy.md))
  expands ordered factors instead of failing with an internal type
  error.

- [`cut_length()`](https://socimh.github.io/tidystata/reference/cut.md)
  reports infinite values and empty input with a clear error; `NaN`
  counts as missing.
  [`cut_breaks()`](https://socimh.github.io/tidystata/reference/cut.md)
  returns an empty ordered factor for empty input without base-R range
  warnings.

- [`mvdecode()`](https://socimh.github.io/tidystata/reference/na_conversion.md),
  [`mvencode()`](https://socimh.github.io/tidystata/reference/na_conversion.md),
  [`na_if_value()`](https://socimh.github.io/tidystata/reference/na_conversion.md)
  and
  [`value_if_na()`](https://socimh.github.io/tidystata/reference/na_conversion.md)
  report a value whose type does not match `x` with an error naming `mv`
  or `value`.

- [`tostring()`](https://socimh.github.io/tidystata/reference/type_conversion.md)
  writes at most 15 significant digits for very large or small numbers,
  instead of platform-dependent extra digits.
  [`tostring()`](https://socimh.github.io/tidystata/reference/type_conversion.md)
  and the interval labels of
  [`xtile()`](https://socimh.github.io/tidystata/reference/cut.md),
  [`cut_length()`](https://socimh.github.io/tidystata/reference/cut.md)
  and
  [`cut_breaks()`](https://socimh.github.io/tidystata/reference/cut.md)
  use a decimal point whatever `options(OutDec)` says.

- [`summ()`](https://socimh.github.io/tidystata/reference/summ.md),
  [`tabstat()`](https://socimh.github.io/tidystata/reference/summ.md),
  [`tab2()`](https://socimh.github.io/tidystata/reference/tab.md),
  [`fre2()`](https://socimh.github.io/tidystata/reference/tab.md),
  [`codebook()`](https://socimh.github.io/tidystata/reference/codebook.md),
  [`browse()`](https://socimh.github.io/tidystata/reference/browse.md),
  [`ds()`](https://socimh.github.io/tidystata/reference/names.md),
  [`variables()`](https://socimh.github.io/tidystata/reference/variables.md),
  [`variables_search()`](https://socimh.github.io/tidystata/reference/variables.md)
  and
  [`select_or_transmute()`](https://socimh.github.io/tidystata/reference/select_or_transmute.md)
  reject objects that are not data frames, such as dbplyr lazy tables
  and arrow tables, with the same `.data` error as
  [`tab()`](https://socimh.github.io/tidystata/reference/tab.md);
  [`ds()`](https://socimh.github.io/tidystata/reference/names.md),
  [`variables()`](https://socimh.github.io/tidystata/reference/variables.md)
  and
  [`variables_search()`](https://socimh.github.io/tidystata/reference/variables.md)
  previously listed the object’s internal components.

- New stress tests check every exported function against adversarial
  column types, shapes and containers, plus invariants for row order,
  grouping, weights and round trips.

- New
  [`stata_recode()`](https://socimh.github.io/tidystata/reference/stata_recode.md)
  (alias
  [`recode()`](https://socimh.github.io/tidystata/reference/stata_recode.md))
  recodes numeric values with Stata’s `recode` rules inside
  [`mutate()`](https://dplyr.tidyverse.org/reference/mutate.html):
  `1:5 ~ 1` selects the closed range 1 to 5, including decimals;
  `c(1, 3:5)` combines values and ranges; `min`, `max` and `NA` select
  the ends and missing values. The first matching rule wins, unmatched
  values are kept unless `.default` replaces them, and named rules label
  the new codes. The
  [`recode()`](https://socimh.github.io/tidystata/reference/stata_recode.md)
  alias and the superseded
  [`dplyr::recode()`](https://dplyr.tidyverse.org/reference/recode.html)
  mask each other, depending on attach order;
  [`stata_recode()`](https://socimh.github.io/tidystata/reference/stata_recode.md)
  always works. `findit("recode")` lists the new examples. Matching now
  uses C++ without per-rule row masks or expanded scalar defaults,
  reducing allocation on large vectors while retaining ordered rules,
  numeric types, value labels and SPSS/tagged missing-value handling.
  Integer input stays integer when every code and `.default` is a whole
  number, so `1:5 ~ 1` keeps an integer variable’s storage type, as in
  Stata.

- [`summ()`](https://socimh.github.io/tidystata/reference/summ.md) and
  [`tabstat()`](https://socimh.github.io/tidystata/reference/summ.md)
  retain defined weighted skewness and kurtosis when fractional
  frequency weights total at most one, without grouped square-root
  warnings. Weighted means and shape statistics avoid overflow from
  large finite weights; reported frequency totals and weighted sums keep
  their scale.

- [`as_dummy()`](https://socimh.github.io/tidystata/reference/as_dummy.md)
  preserves generated indicators that replace removed source names in
  data.table inputs. It reports an error when removing every column
  would discard rows from a data.table, with guidance to retain a
  column.

- [`misstable()`](https://socimh.github.io/tidystata/reference/misstable.md)
  applies structured-column missingness to list-backed matrices instead
  of indexing their cell masks as rows.

- Function help and migration guidance clarify missing-key ordering,
  duplicate identities, grouped assertions, panel units, binning
  boundaries and weights, signed standardisation, and Spearman’s
  small-sample p-values. Bilingual
  [`findit()`](https://socimh.github.io/tidystata/reference/findit.md)
  descriptions distinguish variable labels from value labels.

- [`pwcorr()`](https://socimh.github.io/tidystata/reference/corr.md) and
  [`spearman()`](https://socimh.github.io/tidystata/reference/corr.md)
  preserve very small nonzero p-values under Sidak adjustment. Weighted
  [`pwcorr()`](https://socimh.github.io/tidystata/reference/corr.md) and
  [`corr()`](https://socimh.github.io/tidystata/reference/corr.md)
  retain defined correlations when unequal weights make the variance
  product underflow.

- Rename the persistent preview helpers to
  [`preview()`](https://socimh.github.io/tidystata/reference/preview.md)
  and
  [`unpreview()`](https://socimh.github.io/tidystata/reference/preview.md),
  with
  [`preview_headtail()`](https://socimh.github.io/tidystata/reference/preview.md)
  and
  [`preview_interval()`](https://socimh.github.io/tidystata/reference/preview.md)
  shortcuts. Remove the former preview names and row-slicing helpers
  without compatibility aliases. Head/tail output marks an omitted
  middle with aligned dots; interval output retains its compact layout.
  Persistent previews and one-time printers have separate help topics.

- New
  [`spearman()`](https://socimh.github.io/tidystata/reference/corr.md)
  computes Spearman rank correlations like Stata’s `spearman`: one
  common complete sample by default, `.pairwise = TRUE` for
  `spearman, pw`, and Stata 18’s beta-approximation p-values. The
  Spearman p-values of `pwcorr(.method = "spearman")` now use the same
  method instead of the t approximation of earlier Stata versions, so
  they change slightly.

- [`pwcorr()`](https://socimh.github.io/tidystata/reference/corr.md)
  gains `.listwise` (Stata’s `pwcorr, listwise`) and `.adjust`
  (`"bonferroni"` or `"sidak"`, Stata’s options of the same names).

- [`ds()`](https://socimh.github.io/tidystata/reference/names.md),
  [`summ()`](https://socimh.github.io/tidystata/reference/summ.md), and
  [`tabstat()`](https://socimh.github.io/tidystata/reference/summ.md)
  accept `.type = "tibble"` to return one tibble regardless of the
  input’s table class or preview settings. Summary families combine as
  in table output; existing defaults are unchanged.

- [`findit()`](https://socimh.github.io/tidystata/reference/findit.md)
  refreshes bilingual function descriptions and notes for current
  contracts, with reverse lookup descriptions for every tidystata
  function.

- Shared help pages compare related functions and aliases in opening
  bullets. Grouping, labels, cutting edge cases and examples reflect
  current behavior.

- [`isid()`](https://socimh.github.io/tidystata/reference/keys.md)
  confirms successful key checks with a message while returning the
  original data invisibly. Use
  [`suppressMessages()`](https://rdrr.io/r/base/message.html) for silent
  execution. `.missing` replaces `.missok` without an alias; update
  existing calls. Empty strings, including empty-string factor values,
  are rejected by default; `.missing = TRUE` allows them and other
  missing values but still requires unique key combinations.

- [`capture()`](https://socimh.github.io/tidystata/reference/capture.md)
  returns the expression’s result on success and invisible `NULL` on
  error, replacing its previous `TRUE`/`FALSE` result. It preserves
  successful visibility and evaluates once. Caught errors emit a failure
  message by default that chains the original error, keeping its call
  and bullets; `quiet = TRUE` suppresses it along with warnings and
  messages from the expression. Printed output is retained. Put
  assignments inside
  [`capture()`](https://socimh.github.io/tidystata/reference/capture.md)
  to preserve existing objects on failure. Existing Boolean uses must be
  updated.

- [`corr()`](https://socimh.github.io/tidystata/reference/corr.md)
  calculates Pearson correlations on a common complete-case sample, like
  Stata’s `corr` (`correlate`), with tidy selection, computed columns,
  groups, weights, and long or wide tibble output.

## tidystata 0.3.2

- [`assert()`](https://socimh.github.io/tidystata/reference/assert.md)
  protects input columns from internal-name collisions and rejects
  matrix conditions instead of reporting nonexistent row numbers.

- [`summ()`](https://socimh.github.io/tidystata/reference/summ.md)
  excludes zero-weight observations from weighted arithmetic, scales
  large analytic weights safely, and avoids overflow when averaging
  percentile boundaries. Weighted percentiles retain their values for
  large finite weights. Datetimes with an empty timezone attribute are
  accepted. Summary and tabulation help distinguish analytic weights
  from survey-design inference.

- [`summ()`](https://socimh.github.io/tidystata/reference/summ.md), the
  tabulation family and
  [`pwcorr()`](https://socimh.github.io/tidystata/reference/corr.md)
  retain a grouping column when it is also the weight column in an
  implicit all-column selection.

- [`stata_merge()`](https://socimh.github.io/tidystata/reference/stata_merge.md)
  retains shared non-key values on using-only rows while preserving
  master values, including missing values, on matched rows.

- [`cut_length()`](https://socimh.github.io/tidystata/reference/cut.md)
  and
  [`cut_breaks()`](https://socimh.github.io/tidystata/reference/cut.md)
  omit SPSS user-missing values before computing intervals. Binning
  functions reject `integer64` inputs with an explicit-conversion
  message instead of reading their underlying payloads.

- [`row_min()`](https://socimh.github.io/tidystata/reference/row_egen.md)
  and
  [`row_max()`](https://socimh.github.io/tidystata/reference/row_egen.md)
  recognize `.data[[column]]` inputs in one-row groups and keep `.env`
  scalars from filling otherwise all-missing rows.

- [`tostring()`](https://socimh.github.io/tidystata/reference/type_conversion.md)
  writes numbers in full, as Stata does: 100000 gives `"100000"`, not
  `"1e+05"`.
  [`destring()`](https://socimh.github.io/tidystata/reference/type_conversion.md)
  reads labelled text like plain text, so `ignore`, its warning and
  [`readr::problems()`](https://readr.tidyverse.org/reference/problems.html)
  apply, and rejects a doubled sign such as `"-$-5"`.

- [`misstable()`](https://socimh.github.io/tidystata/reference/misstable.md)
  counts SPSS user-missing codes and ranges. List columns use the
  established summary rule: scalar `NA` elements are missing and `NULL`
  elements are observed values. Grouping names that collide with its
  result columns give a clear error.

- [`row_min()`](https://socimh.github.io/tidystata/reference/row_egen.md)/[`row_max()`](https://socimh.github.io/tidystata/reference/row_egen.md)
  treat `.values` columns as columns in one-row groups, and a missing
  constant makes rows missing when `na.rm = FALSE`, as in
  [`pmin()`](https://rdrr.io/r/base/Extremes.html).

- [`stata_merge()`](https://socimh.github.io/tidystata/reference/stata_merge.md)
  keeps the master key when `using` has a non-key column of the same
  name;
  [`cut_breaks()`](https://socimh.github.io/tidystata/reference/cut.md)
  warns when the default median does not split the values and rejects
  missing breaks and all-missing input.

- Fixes: [`tab2()`](https://socimh.github.io/tidystata/reference/tab.md)
  and [`fre2()`](https://socimh.github.io/tidystata/reference/tab.md) no
  longer tabulate grouping or weight columns without `.by`, keep factor
  order around blank headers and compute Cramer’s V for large 2 x 2
  tables; `summ(.missing = FALSE)` accepts weight vectors;
  [`as_dummy()`](https://socimh.github.io/tidystata/reference/as_dummy.md)
  handles columns without observed values;
  [`is_first()`](https://socimh.github.io/tidystata/reference/is_first.md)
  accepts [`pick()`](https://dplyr.tidyverse.org/reference/pick.html);
  malformed
  [`varlist()`](https://socimh.github.io/tidystata/reference/varlist.md)
  ranges, `NA` positions and `var_type(abbr = NA)` give clear errors;
  [`pc()`](https://socimh.github.io/tidystata/reference/std.md) is
  missing for an infinite total; the timer no longer prints `60.00s`.

## tidystata 0.3.1

- [`findit()`](https://socimh.github.io/tidystata/reference/findit.md)
  corrects audited statistical mappings, missing-value handling and
  estimator defaults, with explicit bilingual qualifications and
  command-specific sources. Name substitution, documented abbreviations,
  row-number queries, by-prefix options and Chinese chart questions work
  while example anchors stay stable. Earlier curated examples show their
  notes in compact output too.

- Add a searchable English/Chinese Stata-to-R reference book, generated
  from the
  [`findit()`](https://socimh.github.io/tidystata/reference/findit.md)
  catalogue, with chapter navigation and a matching-page language
  switch. A dedicated pkgdown navigation link opens the book on the
  author’s website.

- Expand the bilingual
  [`findit()`](https://socimh.github.io/tidystata/reference/findit.md)
  reference with executable, source-linked examples and selected
  alternative R approaches. The generated guide provides an alphabetical
  command index, subject tables and a package-sorted R index.

- Keep concise defaults while showing qualifications and sources on
  explicit expansion. Stable example IDs allow several R answers for the
  same Stata code.

- Respect package-qualified R queries, avoid unrelated word-fragment
  matches, and explain known gaps and unrepresented option combinations.

- [`findit()`](https://socimh.github.io/tidystata/reference/findit.md)
  shows a single clear default, retaining alternatives for ambiguous
  inputs. Comma-separated variable names and hints customize catalogue
  examples, as in `findit(tab, sex, region)` and `findit(tab, gen)`; all
  matches remain available through `print(n = Inf)`.

## tidystata 0.3.0

- Renamed from statart to tidystata, with a focus on data exploration
  and preparation. Legacy import/export, regression and plotting
  wrappers are removed.
- [`findit()`](https://socimh.github.io/tidystata/reference/findit.md)
  translates Stata commands, R function names and plain questions into
  working examples, with English and Chinese guides. In consoles with
  colour, the Stata and R code retain automatic console colours. Results
  start with compact example blocks, omit redundant function notes and
  count remaining examples explicitly.
- Expanded tabulation and summaries include cross-tables, weights,
  correlations, missing-value reports and grouped calculations.
- Added key checks, duplicate handling, Stata-style merges, panel
  operators, variable transformations and persistent table previews.
- Statistical conventions follow Stata and are checked against its
  output. Tables preserve the input container; missing values and labels
  are handled consistently. See the articles and function reference for
  details.
- Faster row calculations and grouped aggregation, with fewer required
  dependencies. Requires R 4.1.0 and dplyr 1.1.4 or later; flextable is
  optional.

## tidystata 0.2.0

- Initial CRAN submission.
