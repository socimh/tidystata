# Changelog

## tidystata 0.3.0

### Breaking changes

- The package is renamed from statart to tidystata. Use
  [`library(tidystata)`](https://github.com/socimh/tidystata) and
  `tidystata::` in place of
  [`library(statart)`](https://rdrr.io/r/base/library.html) and
  `statart::`.

- The bundled `starwars` dataset is removed; use
  [`dplyr::starwars`](https://dplyr.tidyverse.org/reference/starwars.html).
  dplyr 1.1.4 or later is now required, so every supported dplyr ships
  the same data. `lifeexp` is rebuilt from World Bank World Development
  Indicators (CC BY 4.0) with the same columns, labels and countries;
  its values are the World Bank’s current 1998 figures, and `safewater`
  is now the 2000 share using safely managed drinking water. See the
  installed `DATA-PROVENANCE.md`.

- tidystata now focuses on exploring and preparing data. `read_data()`,
  `write_data()`, `esttab()`, `codebook_detail()`, `tidy_coef()`, the
  regression wrappers (`regress()`, `regress_data()`, `regress_coef()`,
  `regress_stat()`) and the plotting helpers (`s_plot()`, `s_ggsave()`)
  are removed. `s_time()` is renamed to
  [`timer()`](https://socimh.github.io/tidystata/reference/timer.md).
  The [migration
  guide](https://socimh.github.io/tidystata/articles/migration.html)
  lists direct alternatives.

- R 4.1.0 or later is now required. Persistent preview formatting
  requires tibble \>= 3.2.0 and pillar \>= 1.9.0, as dplyr \>= 1.1.4
  does. readr \>= 1.4.0 is required for scientific notation and parsing
  diagnostics in
  [`as_numeric()`](https://socimh.github.io/tidystata/reference/type_conversion.md)
  and
  [`destring()`](https://socimh.github.io/tidystata/reference/type_conversion.md).

- Required dependencies fall from 33 to 16 packages. Rich table output
  now needs the optional flextable package, and `Rfast` is no longer
  used.

- Table-producing helpers preserve a base data.frame, tibble or
  data.table input container, including empty results and tables inside
  list outputs. Summaries and inventories are ungrouped. Newly
  constructed tables do not keep arbitrary subclass metadata.

- [`fre()`](https://socimh.github.io/tidystata/reference/tab.md) and
  [`fre2()`](https://socimh.github.io/tidystata/reference/tab.md)
  default to `.type = "auto"`. Request `.type = "tibble"` for a tibble
  or `.type = "flextable"` for rich output. An empty selection in
  `fre2(..., .type = "flextable")` is now an error instead of silently
  returning a tibble.

- [`summ()`](https://socimh.github.io/tidystata/reference/summ.md) and
  [`tabstat()`](https://socimh.github.io/tidystata/reference/summ.md)
  sort `.by` groups like
  [`tab()`](https://socimh.github.io/tidystata/reference/tab.md)
  (`.sort = TRUE`: factor levels, ascending keys, missing keys last) and
  drop the `name` column when exactly one variable is summarised
  (`.name = FALSE`). Use `.sort = FALSE` or `.name = TRUE` for the
  previous layout.

- [`summ()`](https://socimh.github.io/tidystata/reference/summ.md) and
  [`tabstat()`](https://socimh.github.io/tidystata/reference/summ.md)
  return calendar spread statistics (`sd`, `se`, `mad`, `iqr`) as
  `difftime` columns with one unit per column, so rows can be compared
  and used in arithmetic. `.duration_format` no longer affects the
  output. With `.type = "table"`, calendar spreads are numbers in days
  (Dates) or seconds, the unit is appended to `type` (for example
  `"date [days]"`), and numeric values in shared text columns are
  rounded to seven significant digits.

- [`xtile()`](https://socimh.github.io/tidystata/reference/cut.md)
  (formerly
  [`cut_quantile()`](https://socimh.github.io/tidystata/reference/cut.md))
  follows Stata’s `xtile` rule: equal values stay in the same group and
  distinct values are never merged, so a 0/1 dummy gives two groups.
  When ties leave fewer than `n` groups, occupied groups are numbered
  consecutively with a warning. Untied data give the same results as
  before. Inside a grouped data mask without `labels`, it returns
  integer codes, because group-specific interval labels cannot be
  combined.

- [`s_select()`](https://socimh.github.io/tidystata/reference/s_select.md),
  and therefore
  [`tab()`](https://socimh.github.io/tidystata/reference/tab.md),
  [`summ()`](https://socimh.github.io/tidystata/reference/summ.md) and
  related functions, computes expressions that use columns instead of
  first trying them as selections: `half = y / x` previously selected
  column `y`. Named constants (`one = 1`) create constant columns, and
  misspelled or out-of-range selections are an error listing every
  unmatched name. Computed expressions run once.

- [`timer()`](https://socimh.github.io/tidystata/reference/timer.md)
  reports the elapsed time on failure by default (`on_error = TRUE`);
  the original error object and call are untouched.

- [`row_min()`](https://socimh.github.io/tidystata/reference/row_egen.md)
  and
  [`row_max()`](https://socimh.github.io/tidystata/reference/row_egen.md)
  keep the common input type: logical inputs return logical values and
  integer inputs return integers, instead of always returning doubles.
  They also support character values, ordered factors and calendar,
  duration, measured, labelled and `integer64` values. Numeric constants
  behave as in [`pmin()`](https://rdrr.io/r/base/Extremes.html) and
  [`pmax()`](https://rdrr.io/r/base/Extremes.html): `row_min(x, 0.5)`
  caps `x`, and constants never fill all-missing rows.

- [`mvdecode()`](https://socimh.github.io/tidystata/reference/na_conversion.md)
  (formerly
  [`na_if_value()`](https://socimh.github.io/tidystata/reference/na_conversion.md))
  treats several codes as a set, like Stata’s `mv(-98 -99)`, instead of
  comparing them elementwise as
  [`dplyr::na_if()`](https://dplyr.tidyverse.org/reference/na_if.html)
  does. A single code works as before.

- Enumerated options (`.type`, `.wt_type`, `.group_order`, `method`,
  `unit`, `relationship`, `style`) are checked with
  [`rlang::arg_match()`](https://rlang.r-lib.org/reference/arg_match.html),
  so they must be spelled in full. A mistyped value suggests the
  intended one.

### Lifecycle changes

- Functions carry their Stata names, and the earlier names stay as quiet
  aliases on the same help pages:
  [`xtile()`](https://socimh.github.io/tidystata/reference/cut.md)
  ([`cut_quantile()`](https://socimh.github.io/tidystata/reference/cut.md)),
  [`capture()`](https://socimh.github.io/tidystata/reference/capture.md)
  ([`s_try()`](https://socimh.github.io/tidystata/reference/capture.md)),
  `ds(.type = "table")`
  ([`ds_as_column()`](https://socimh.github.io/tidystata/reference/names.md),
  [`names_as_column()`](https://socimh.github.io/tidystata/reference/names.md)),
  [`mvdecode()`](https://socimh.github.io/tidystata/reference/na_conversion.md)
  and
  [`mvencode()`](https://socimh.github.io/tidystata/reference/na_conversion.md)
  ([`na_if_value()`](https://socimh.github.io/tidystata/reference/na_conversion.md),
  [`value_if_na()`](https://socimh.github.io/tidystata/reference/na_conversion.md)),
  and
  [`destring()`](https://socimh.github.io/tidystata/reference/type_conversion.md)
  and
  [`decode()`](https://socimh.github.io/tidystata/reference/type_conversion.md)
  ([`as_numeric()`](https://socimh.github.io/tidystata/reference/type_conversion.md),
  [`as_character()`](https://socimh.github.io/tidystata/reference/type_conversion.md)).
  New aliases are
  [`pct()`](https://socimh.github.io/tidystata/reference/std.md) for
  [`pc()`](https://socimh.github.io/tidystata/reference/std.md),
  [`xtab()`](https://socimh.github.io/tidystata/reference/tab.md) for
  [`tab2()`](https://socimh.github.io/tidystata/reference/tab.md),
  [`s_tag()`](https://socimh.github.io/tidystata/reference/is_first.md)
  for
  [`is_first()`](https://socimh.github.io/tidystata/reference/is_first.md)
  and
  [`tab_gen()`](https://socimh.github.io/tidystata/reference/as_dummy.md)
  for
  [`as_dummy()`](https://socimh.github.io/tidystata/reference/as_dummy.md).

- [`s_match()`](https://socimh.github.io/tidystata/reference/tidystata-deprecated.md),
  [`s_type()`](https://socimh.github.io/tidystata/reference/tidystata-deprecated.md)
  and
  [`s_unit()`](https://socimh.github.io/tidystata/reference/tidystata-deprecated.md)
  are deprecated in favour of
  [`varlist()`](https://socimh.github.io/tidystata/reference/varlist.md),
  [`var_type()`](https://socimh.github.io/tidystata/reference/var_type.md)
  and
  [`var_unit()`](https://socimh.github.io/tidystata/reference/var_type.md).
  They still work, with a lifecycle warning.

- Arguments follow one naming rule: options after a `...` that takes
  columns or expressions are dotted, and functions without `...` use
  plain names.
  [`destring()`](https://socimh.github.io/tidystata/reference/type_conversion.md),
  [`decode()`](https://socimh.github.io/tidystata/reference/type_conversion.md),
  [`var_type()`](https://socimh.github.io/tidystata/reference/var_type.md),
  [`var_unit()`](https://socimh.github.io/tidystata/reference/var_type.md),
  [`na_if_value()`](https://socimh.github.io/tidystata/reference/na_conversion.md),
  [`value_if_na()`](https://socimh.github.io/tidystata/reference/na_conversion.md)
  and [`timer()`](https://socimh.github.io/tidystata/reference/timer.md)
  take `x` (not `.x`);
  [`capture()`](https://socimh.github.io/tidystata/reference/capture.md)
  and
  [`set_seed()`](https://socimh.github.io/tidystata/reference/set_seed.md)
  take `x` (not `.fn`); `var_type(abbr)`, `timer(on_error)`,
  `na_if_value(value)` and `value_if_na(value)` drop their dots;
  [`s_merge()`](https://socimh.github.io/tidystata/reference/s_merge.md)
  takes `keep`, `assert`, `generate` and `report`; and
  [`varlist()`](https://socimh.github.io/tidystata/reference/varlist.md)
  takes `ignore_case`. The old names keep working with a deprecation
  warning.

- [`summ()`](https://socimh.github.io/tidystata/reference/summ.md) and
  [`tabstat()`](https://socimh.github.io/tidystata/reference/summ.md)
  replace `.na.rm` with `.missing` (with the opposite value, default
  `TRUE`), matching
  [`is_first()`](https://socimh.github.io/tidystata/reference/is_first.md)
  and
  [`row_nvals()`](https://socimh.github.io/tidystata/reference/row_egen.md),
  and replace `.mode` with `.type` (same `"list"` and `"table"` values).

### New features

#### Coming from Stata

- New
  [`findit()`](https://socimh.github.io/tidystata/reference/findit.md)
  gives the R equivalent of a Stata command: the tidystata function
  where one exists, and the standard package otherwise. Type one word
  bare (`findit(reg)`) or quote longer code
  (`findit("merge 1:1 id, keep(match)")`). Stata’s minimum abbreviations
  work, and unmatched text falls back to a keyword search. R function
  names work too (`findit(left_join)`), listing the Stata idioms they
  replace.
  [`findit()`](https://socimh.github.io/tidystata/reference/findit.md)
  alone lists all of about 410 idioms. New “Coming from Stata” articles,
  in English and Chinese, show the entries by topic.

#### Tabulation

- New [`tab2()`](https://socimh.github.io/tidystata/reference/tab.md)
  cross-tabulates two variables, like Stata’s `tab x y`, and
  [`fre2()`](https://socimh.github.io/tidystata/reference/tab.md) adds
  the total row and column. With three or more variables it returns
  every pairwise table as a named list, as Stata’s `tab2` does. `.by`
  returns one cross-table per group, like `by g: tab x y`.

- `tab2(.chi2 = TRUE)` reports Pearson’s chi-square, its p-value and
  Cramer’s V, like `tab x y, chi2 V`, and stores them in
  `attr(x, "chi2")`.

- [`tab()`](https://socimh.github.io/tidystata/reference/tab.md) and
  [`tab1()`](https://socimh.github.io/tidystata/reference/tab.md) gain
  `.total`: `tab(.total = TRUE)` equals
  [`fre()`](https://socimh.github.io/tidystata/reference/tab.md) and
  `tab1(.total = TRUE)` equals
  [`fre1()`](https://socimh.github.io/tidystata/reference/tab.md).

- [`tab()`](https://socimh.github.io/tidystata/reference/tab.md),
  [`tab1()`](https://socimh.github.io/tidystata/reference/tab.md),
  [`fre()`](https://socimh.github.io/tidystata/reference/tab.md),
  [`fre1()`](https://socimh.github.io/tidystata/reference/tab.md),
  [`tab2()`](https://socimh.github.io/tidystata/reference/tab.md),
  [`summ()`](https://socimh.github.io/tidystata/reference/summ.md) and
  [`tabstat()`](https://socimh.github.io/tidystata/reference/summ.md)
  gain `.wt` and `.wt_type`, like Stata’s `[fweight]` and `[aweight]`.
  Weighted summaries follow Stata’s formulas, including its weighted
  percentile rule.
  [`xtile()`](https://socimh.github.io/tidystata/reference/cut.md) gains
  `wt` for weighted cutpoints.

- [`fre()`](https://socimh.github.io/tidystata/reference/tab.md),
  [`tab1()`](https://socimh.github.io/tidystata/reference/tab.md) and
  [`fre1()`](https://socimh.github.io/tidystata/reference/tab.md) accept
  atomic vectors, like
  [`tab()`](https://socimh.github.io/tidystata/reference/tab.md).

- Grouped frequencies gain `.group_order = "frequency"`, independent of
  within-group `.desc` sorting.

#### Summaries

- New
  [`pwcorr()`](https://socimh.github.io/tidystata/reference/pwcorr.md)
  returns a tidy table of pairwise correlations with `n` and p-values,
  like `pwcorr, sig obs`, with `.method = "spearman"`, `.by`, weights
  and `.wide = TRUE` for Stata’s lower-triangle matrix.

- New
  [`misstable()`](https://socimh.github.io/tidystata/reference/misstable.md)
  summarises missing values by variable, like `misstable summarize`, or
  missing patterns with `.patterns = TRUE`.

- [`summ()`](https://socimh.github.io/tidystata/reference/summ.md) and
  [`tabstat()`](https://socimh.github.io/tidystata/reference/summ.md)
  accept any percentile `p0` to `p100` (including decimals such as
  `p2.5`), the aliases `missing`, `p25`, `p50` and `p75`, and a numeric
  `sum`. Only requested statistics are calculated.

- [`summ()`](https://socimh.github.io/tidystata/reference/summ.md) and
  [`tabstat()`](https://socimh.github.io/tidystata/reference/summ.md)
  gain `.sort` and `.drop_empty`. With `.keep_all = TRUE`, character and
  list columns keep counts and unique values. `hms` times of day form
  their own `time` family.

#### Checking and combining data

- New [`isid()`](https://socimh.github.io/tidystata/reference/keys.md)
  checks that columns uniquely identify the rows, like Stata’s `isid`.

- New
  [`duplicates_report()`](https://socimh.github.io/tidystata/reference/keys.md),
  [`duplicates_tag()`](https://socimh.github.io/tidystata/reference/keys.md),
  [`duplicates_list()`](https://socimh.github.io/tidystata/reference/keys.md)
  and
  [`duplicates_drop()`](https://socimh.github.io/tidystata/reference/keys.md)
  follow Stata’s `duplicates` subcommands.

- New
  [`assert()`](https://socimh.github.io/tidystata/reference/assert.md),
  like Stata’s `assert`, checks conditions on every row and returns the
  data invisibly, so it fits in a pipe.

- New
  [`s_merge()`](https://socimh.github.io/tidystata/reference/s_merge.md)
  joins like Stata’s `merge`: it checks the key relationship (`"1:1"`,
  `"m:1"`, `"1:m"`), prints a matched/unmatched report and adds a
  `.merge` factor, with `keep`, `assert` and `generate` options.

#### Generating variables

- New [`std()`](https://socimh.github.io/tidystata/reference/std.md) and
  [`pc()`](https://socimh.github.io/tidystata/reference/std.md), like
  Stata’s `egen std()` and `egen pc()`, use each group’s statistics in
  grouped
  [`mutate()`](https://dplyr.tidyverse.org/reference/mutate.html) or
  with `.by`.

- New
  [`as_dummy()`](https://socimh.github.io/tidystata/reference/as_dummy.md)
  creates one 0/1 column per observed category, like
  `tabulate x, generate(x_)`.

- New
  [`is_first()`](https://socimh.github.io/tidystata/reference/is_first.md),
  like `egen tag()`, flags the first row of each group.

- New
  [`s_lag()`](https://socimh.github.io/tidystata/reference/panel.md),
  [`s_lead()`](https://socimh.github.io/tidystata/reference/panel.md)
  and
  [`s_diff()`](https://socimh.github.io/tidystata/reference/panel.md),
  like Stata’s `L.x`, `F.x` and `D.x` after `xtset`, find values by time
  rather than row position, so gaps give missing values. They support
  `Date`s by period (`unit`), date-times, tsibble and zoo period classes
  and ordered factors.

- New
  [`row_nvals()`](https://socimh.github.io/tidystata/reference/row_egen.md),
  like egenmore’s `egen rownvals()`, counts distinct values in each row.

- New
  [`tostring()`](https://socimh.github.io/tidystata/reference/type_conversion.md),
  like Stata’s `tostring`, gives values as text, keeping codes rather
  than value labels.

- [`xtile()`](https://socimh.github.io/tidystata/reference/cut.md) gains
  `method = "rank"` for balanced groups that may split ties.

#### Selecting and previewing

- New
  [`preview_table()`](https://socimh.github.io/tidystata/reference/special-print.md)
  keeps a full table while displaying head/tail or evenly spaced rows;
  the setting persists through supported dplyr and tidyr operations.
  [`unpreview_table()`](https://socimh.github.io/tidystata/reference/special-print.md)
  removes it.

- New
  [`print_all()`](https://socimh.github.io/tidystata/reference/special-print.md),
  like Stata’s `list`, prints every row and column. New
  [`s_print()`](https://socimh.github.io/tidystata/reference/special-print.md)
  prints the first and last rows, evenly spaced rows or every row
  through one `style` argument.

- [`print_headtail()`](https://socimh.github.io/tidystata/reference/special-print.md),
  [`print_interval()`](https://socimh.github.io/tidystata/reference/special-print.md),
  [`slice_headtail()`](https://socimh.github.io/tidystata/reference/special-print.md)
  and
  [`slice_interval()`](https://socimh.github.io/tidystata/reference/special-print.md)
  are restored and accept `sf` data.

- [`ds()`](https://socimh.github.io/tidystata/reference/names.md) gains
  `.type = "table"`, returning the names as a one-column table.

- `set_seed(123)` also works on its own, like `set seed 123`.

- [`variables_search()`](https://socimh.github.io/tidystata/reference/variables.md)
  also searches variable labels.

### Minor improvements and bug fixes

- [`tab()`](https://socimh.github.io/tidystata/reference/tab.md),
  [`tab1()`](https://socimh.github.io/tidystata/reference/tab.md),
  [`fre()`](https://socimh.github.io/tidystata/reference/tab.md) and
  [`fre1()`](https://socimh.github.io/tidystata/reference/tab.md) check
  that `.desc` is `TRUE` or `FALSE` before tabulating; a vector or `NA`
  previously failed inside the sorting step, and aborted R 4.1.
  [`row_var()`](https://socimh.github.io/tidystata/reference/row_egen.md)
  now matches [`stats::var()`](https://rdrr.io/r/stats/cor.html) exactly
  on platforms without extended precision, such as Apple Silicon.

- The plain example scripts and the migration guide are no longer
  installed with the package. The scripts are in the repository’s
  `examples/` folder and the guide is the website’s [Migration
  guide](https://socimh.github.io/tidystata/articles/migration.html)
  article.

- SPSS user-defined missing codes and ranges
  ([`haven::labelled_spss()`](https://haven.tidyverse.org/reference/labelled_spss.html))
  are treated as missing throughout: in
  [`pwcorr()`](https://socimh.github.io/tidystata/reference/pwcorr.md),
  [`misstable()`](https://socimh.github.io/tidystata/reference/misstable.md),
  [`std()`](https://socimh.github.io/tidystata/reference/std.md),
  [`pc()`](https://socimh.github.io/tidystata/reference/std.md),
  `is_first(.missing = FALSE)`,
  [`as_dummy()`](https://socimh.github.io/tidystata/reference/as_dummy.md),
  the panel operators,
  [`codebook()`](https://socimh.github.io/tidystata/reference/codebook.md)
  and
  [`mvencode()`](https://socimh.github.io/tidystata/reference/na_conversion.md),
  as [`summ()`](https://socimh.github.io/tidystata/reference/summ.md)
  and [`tab()`](https://socimh.github.io/tidystata/reference/tab.md)
  already did.

- Errors, warnings and messages use cli. Errors name the function you
  called, describe the problem in one sentence and give hints as
  bullets. Code that matched the old wording may need updating; results
  are unchanged.

- Examples, vignettes and README use the native pipe `|>`. `%>%` is
  still exported.

- [`pwcorr()`](https://socimh.github.io/tidystata/reference/pwcorr.md)
  excludes zero-weight values, avoids overflow with very large weights
  or scales, and rejects explicitly selected matrix or array columns.
  Analytic weights in tabulations and summaries normalize safely within
  each group.

- [`duplicates_list()`](https://socimh.github.io/tidystata/reference/keys.md)
  preserves grouping and errors when `.row` or `.dup_group` already
  exists.

- [`summ()`](https://socimh.github.io/tidystata/reference/summ.md) and
  [`tabstat()`](https://socimh.github.io/tidystata/reference/summ.md)
  keep numeric and logical columns with no observed values, including
  zero-row inputs; combine numeric and calendar summaries in
  `.type = "table"` without type conflicts; display datetimes in their
  own time zone and infinite Dates as `Inf`/`-Inf`; skip calendar
  variables with a warning when `sum`, `skew` or `kurtosis` is
  requested; and rename grouping keys that collide with summary columns,
  with a message.

- A piped vector (`x |> summ()`) is named `value`. `.by` given a
  computed expression explains that it selects columns, instead of
  “object not found”.

- [`tab()`](https://socimh.github.io/tidystata/reference/tab.md),
  [`tab1()`](https://socimh.github.io/tidystata/reference/tab.md),
  [`fre()`](https://socimh.github.io/tidystata/reference/tab.md) and
  [`fre1()`](https://socimh.github.io/tidystata/reference/tab.md)
  calculate statistics and totals within each group, keep missing group
  keys and place missing categories last. An explicit `.by` replaces
  inherited groups. List columns are counted, and selecting no variables
  returns an empty result.

- [`tab2()`](https://socimh.github.io/tidystata/reference/tab.md) and
  [`fre2()`](https://socimh.github.io/tidystata/reference/tab.md) order
  columns by value or factor level with missing last, support blank
  column categories, keep categories that match variable names and
  report ambiguous name collisions;
  [`fre2()`](https://socimh.github.io/tidystata/reference/tab.md)
  rejects a column category `"total"`.

- [`codebook()`](https://socimh.github.io/tidystata/reference/codebook.md)
  returns one inventory of the selected columns even for grouped input,
  and counts missing list elements and structured columns consistently.

- Row helpers return vectors consistently, handle empty and all-missing
  rows, use sample variance and standard deviation, keep calendar,
  duration and measured units where arithmetic is defined, and can use
  grouping columns inside grouped
  [`mutate()`](https://dplyr.tidyverse.org/reference/mutate.html).
  [`row_mean()`](https://socimh.github.io/tidystata/reference/row_egen.md),
  [`row_median()`](https://socimh.github.io/tidystata/reference/row_egen.md),
  [`row_var()`](https://socimh.github.io/tidystata/reference/row_egen.md),
  [`row_sd()`](https://socimh.github.io/tidystata/reference/row_egen.md),
  [`row_min()`](https://socimh.github.io/tidystata/reference/row_egen.md),
  [`row_max()`](https://socimh.github.io/tidystata/reference/row_egen.md)
  and
  [`row_sum()`](https://socimh.github.io/tidystata/reference/row_egen.md)
  accept `na.rm`.

- [`var_type()`](https://socimh.github.io/tidystata/reference/var_type.md)
  recognizes measured vectors, and
  [`var_unit()`](https://socimh.github.io/tidystata/reference/var_type.md)
  returns their units, including compound units such as `m/s`. Custom
  and structured type descriptions are kept instead of truncated.

- [`destring()`](https://socimh.github.io/tidystata/reference/type_conversion.md)
  parses character input while keeping its length and missing positions
  and exposing parsing warnings.
  [`decode()`](https://socimh.github.io/tidystata/reference/type_conversion.md)
  handles labelled vectors without value labels, including tagged
  missing values.

- [`varlist()`](https://socimh.github.io/tidystata/reference/varlist.md)
  combines space-separated numeric-range patterns correctly and gives a
  direct error for non-character patterns.

- [`cut_length()`](https://socimh.github.io/tidystata/reference/cut.md)
  rejects invalid interval counts before calculating breaks. Help
  clarifies that a scalar
  [`cut_breaks()`](https://socimh.github.io/tidystata/reference/cut.md)
  value is an interior cutpoint.

- [`s_select()`](https://socimh.github.io/tidystata/reference/s_select.md)
  returns the first successful operation without rerunning it and keeps
  its warnings.

- [`na_if_value()`](https://socimh.github.io/tidystata/reference/na_conversion.md)
  and
  [`value_if_na()`](https://socimh.github.io/tidystata/reference/na_conversion.md)
  give actionable messages when required arguments are missing;
  [`value_if_na()`](https://socimh.github.io/tidystata/reference/na_conversion.md)
  fills SPSS user-missing codes.

- [`browse()`](https://socimh.github.io/tidystata/reference/browse.md)
  returns the viewed data invisibly with their class preserved.

- Optional data.table operations explain the missing dependency when
  needed.

- Two vignettes cover a short workflow and the output-container,
  grouping and missing-value conventions.

### Performance

Results are unchanged; only the time taken to compute them is shorter.

- Row helpers are 2-5 times faster on large data (for example,
  [`row_unique()`](https://socimh.github.io/tidystata/reference/row_egen.md)
  on 1,000,000 rows fell from about 300 ms to 55 ms), and
  [`row_sum()`](https://socimh.github.io/tidystata/reference/row_egen.md)
  and
  [`row_mean()`](https://socimh.github.io/tidystata/reference/row_egen.md)
  no longer copy the columns into a matrix.

- [`summ()`](https://socimh.github.io/tidystata/reference/summ.md) with
  many groups is much faster: `.detail = TRUE` over 10,000 groups fell
  from about 1,060 ms to 240 ms.

- [`tab()`](https://socimh.github.io/tidystata/reference/tab.md),
  [`fre()`](https://socimh.github.io/tidystata/reference/tab.md) and
  [`tab2()`](https://socimh.github.io/tidystata/reference/tab.md) with
  many groups are faster, especially with weights (weighted
  [`tab()`](https://socimh.github.io/tidystata/reference/tab.md) over
  10,000 groups: 200 ms to 80 ms).

- [`s_merge()`](https://socimh.github.io/tidystata/reference/s_merge.md),
  [`destring()`](https://socimh.github.io/tidystata/reference/type_conversion.md),
  [`pwcorr()`](https://socimh.github.io/tidystata/reference/pwcorr.md),
  grouped
  [`xtile()`](https://socimh.github.io/tidystata/reference/cut.md) and
  [`codebook()`](https://socimh.github.io/tidystata/reference/codebook.md)
  also do less work.

## tidystata 0.2.0

- Initial CRAN submission.
