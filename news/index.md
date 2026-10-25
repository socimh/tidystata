# Changelog

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
  [`pwcorr()`](https://socimh.github.io/tidystata/reference/pwcorr.md)
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
  [`print_all()`](https://socimh.github.io/tidystata/reference/special-print.md)
  accepts `width`; malformed
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
