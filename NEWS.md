# tidystata 0.3.0

## Breaking changes

* The package is renamed from statart to tidystata. Use `library(tidystata)`
  and `tidystata::` in place of `library(statart)` and `statart::`.

* The bundled `starwars` dataset is removed; use `dplyr::starwars`. dplyr
  1.1.4 or later is now required, so every supported dplyr ships the same
  data. `lifeexp` is rebuilt from World Bank World Development Indicators
  (CC BY 4.0) with the same columns, labels and countries; its values are the
  World Bank's current 1998 figures, and `safewater` is now the 2000 share
  using safely managed drinking water. See the installed `DATA-PROVENANCE.md`.

* tidystata now focuses on exploring and preparing data. `read_data()`,
  `write_data()`, `esttab()`, `codebook_detail()`, `tidy_coef()`, the
  regression wrappers (`regress()`, `regress_data()`, `regress_coef()`,
  `regress_stat()`) and the plotting helpers (`s_plot()`, `s_ggsave()`) are
  removed. `s_time()` is renamed to `timer()`. The
  [migration guide](https://socimh.github.io/tidystata/articles/migration.html)
  lists direct alternatives.

* R 4.1.0 or later is now required. Persistent preview formatting requires
  tibble >= 3.2.0 and pillar >= 1.9.0, as dplyr >= 1.1.4 does.

* Required dependencies fall from 33 to 16 packages. Rich table output now
  needs the optional flextable package, and `Rfast` is no longer used.

* Table-producing helpers preserve a base data.frame, tibble or data.table
  input container, including empty results and tables inside list outputs.
  Summaries and inventories are ungrouped. Newly constructed tables do not keep
  arbitrary subclass metadata.

* `fre()` and `fre2()` default to `.type = "auto"`. Request
  `.type = "tibble"` for a tibble or `.type = "flextable"` for rich output.
  An empty selection in `fre2(..., .type = "flextable")` is now an error
  instead of silently returning a tibble.

* `summ()` and `tabstat()` sort `.by` groups like `tab()` (`.sort = TRUE`:
  factor levels, ascending keys, missing keys last) and drop the `name` column
  when exactly one variable is summarised (`.name = FALSE`). Use
  `.sort = FALSE` or `.name = TRUE` for the previous layout.

* `summ()` and `tabstat()` return calendar spread statistics (`sd`, `se`,
  `mad`, `iqr`) as `difftime` columns with one unit per column, so rows can be
  compared and used in arithmetic. `.duration_format` no longer affects the
  output. With `.type = "table"`, calendar spreads are numbers in days (Dates)
  or seconds, the unit is appended to `type` (for example `"date [days]"`),
  and numeric values in shared text columns are rounded to seven significant
  digits.

* `xtile()` (formerly `cut_quantile()`) follows Stata's `xtile` rule: equal
  values stay in the same group and distinct values are never merged, so a 0/1
  dummy gives two groups. When ties leave fewer than `n` groups, occupied
  groups are numbered consecutively with a warning. Untied data give the same
  results as before. Inside a grouped data mask without `labels`, it returns
  integer codes, because group-specific interval labels cannot be combined.

* `s_select()`, and therefore `tab()`, `summ()` and related functions,
  computes expressions that use columns instead of first trying them as
  selections: `half = y / x` previously selected column `y`. Named constants
  (`one = 1`) create constant columns, and misspelled or out-of-range
  selections are an error listing every unmatched name. Computed expressions
  run once.

* `timer()` reports the elapsed time on failure by default (`on_error = TRUE`);
  the original error object and call are untouched.

* `row_min()` and `row_max()` keep the common input type: logical inputs
  return logical values and integer inputs return integers, instead of
  always returning doubles. They also support character values, ordered
  factors and calendar, duration, measured, labelled and `integer64` values.
  Numeric constants behave as in `pmin()` and `pmax()`: `row_min(x, 0.5)` caps
  `x`, and constants never fill all-missing rows.

* `mvdecode()` (formerly `na_if_value()`) treats several codes as a set, like
  Stata's `mv(-98 -99)`, instead of comparing them elementwise as
  `dplyr::na_if()` does. A single code works as before.

* Enumerated options (`.type`, `.wt_type`, `.group_order`, `method`, `unit`,
  `relationship`, `style`) are checked with `rlang::arg_match()`, so they must
  be spelled in full. A mistyped value suggests the intended one.

## Lifecycle changes

* Functions carry their Stata names, and the earlier names stay as quiet
  aliases on the same help pages: `xtile()` (`cut_quantile()`), `capture()`
  (`s_try()`), `ds(.type = "table")` (`ds_as_column()`, `names_as_column()`),
  `mvdecode()` and `mvencode()` (`na_if_value()`, `value_if_na()`), and
  `destring()` and `decode()` (`as_numeric()`, `as_character()`). New aliases
  are `pct()` for `pc()`, `xtab()` for `tab2()`, `s_tag()` for `is_first()`
  and `tab_gen()` for `as_dummy()`.

* `s_match()`, `s_type()` and `s_unit()` are deprecated in favour of
  `varlist()`, `var_type()` and `var_unit()`. They still work, with a
  lifecycle warning.

* Arguments follow one naming rule: options after a `...` that takes columns
  or expressions are dotted, and functions without `...` use plain names.
  `destring()`, `decode()`, `var_type()`, `var_unit()`, `na_if_value()`,
  `value_if_na()` and `timer()` take `x` (not `.x`); `capture()` and
  `set_seed()` take `x` (not `.fn`); `var_type(abbr)`, `timer(on_error)`,
  `na_if_value(value)` and `value_if_na(value)` drop their dots;
  `s_merge()` takes `keep`, `assert`, `generate` and `report`; and
  `varlist()` takes `ignore_case`. The old names keep working with a
  deprecation warning.

* `summ()` and `tabstat()` replace `.na.rm` with `.missing` (with the opposite
  value, default `TRUE`), matching `is_first()` and `row_nvals()`, and replace
  `.mode` with `.type` (same `"list"` and `"table"` values).

## New features

### Coming from Stata

* New `findit()` gives the R equivalent of a Stata command: the tidystata
  function where one exists, and the standard package otherwise. Type one
  word bare (`findit(reg)`) or quote longer code
  (`findit("merge 1:1 id, keep(match)")`). Stata's minimum abbreviations
  work, and unmatched text falls back to a keyword search. R function names
  work too (`findit(left_join)`), listing the Stata idioms they replace.
  `findit()` alone lists all of about 410 idioms. New "Coming from Stata"
  articles, in English and Chinese, show the entries by topic.

### Tabulation

* New `tab2()` cross-tabulates two variables, like Stata's `tab x y`, and
  `fre2()` adds the total row and column. With three or more variables it
  returns every pairwise table as a named list, as Stata's `tab2` does. `.by`
  returns one cross-table per group, like `by g: tab x y`.

* `tab2(.chi2 = TRUE)` reports Pearson's chi-square, its p-value and
  Cramer's V, like `tab x y, chi2 V`, and stores them in `attr(x, "chi2")`.

* `tab()` and `tab1()` gain `.total`: `tab(.total = TRUE)` equals `fre()` and
  `tab1(.total = TRUE)` equals `fre1()`.

* `tab()`, `tab1()`, `fre()`, `fre1()`, `tab2()`, `summ()` and `tabstat()`
  gain `.wt` and `.wt_type`, like Stata's `[fweight]` and `[aweight]`.
  Weighted summaries follow Stata's formulas, including its weighted
  percentile rule. `xtile()` gains `wt` for weighted cutpoints.

* `fre()`, `tab1()` and `fre1()` accept atomic vectors, like `tab()`.

* Grouped frequencies gain `.group_order = "frequency"`, independent of
  within-group `.desc` sorting.

### Summaries

* New `pwcorr()` returns a tidy table of pairwise correlations with `n` and
  p-values, like `pwcorr, sig obs`, with `.method = "spearman"`, `.by`,
  weights and `.wide = TRUE` for Stata's lower-triangle matrix.

* New `misstable()` summarises missing values by variable, like
  `misstable summarize`, or missing patterns with `.patterns = TRUE`.

* `summ()` and `tabstat()` accept any percentile `p0` to `p100` (including
  decimals such as `p2.5`), the aliases `missing`, `p25`, `p50` and `p75`, and
  a numeric `sum`. Only requested statistics are calculated.

* `summ()` and `tabstat()` gain `.sort` and `.drop_empty`. With
  `.keep_all = TRUE`, character and list columns keep counts and unique
  values. `hms` times of day form their own `time` family.

### Checking and combining data

* New `isid()` checks that columns uniquely identify the rows, like Stata's
  `isid`.

* New `duplicates_report()`, `duplicates_tag()`, `duplicates_list()` and
  `duplicates_drop()` follow Stata's `duplicates` subcommands.

* New `assert()`, like Stata's `assert`, checks conditions on every row and
  returns the data invisibly, so it fits in a pipe.

* New `s_merge()` joins like Stata's `merge`: it checks the key relationship
  (`"1:1"`, `"m:1"`, `"1:m"`), prints a matched/unmatched report and adds a
  `.merge` factor, with `keep`, `assert` and `generate` options.

### Generating variables

* New `std()` and `pc()`, like Stata's `egen std()` and `egen pc()`, use each
  group's statistics in grouped `mutate()` or with `.by`.

* New `as_dummy()` creates one 0/1 column per observed category, like
  `tabulate x, generate(x_)`.

* New `is_first()`, like `egen tag()`, flags the first row of each group.

* New `s_lag()`, `s_lead()` and `s_diff()`, like Stata's `L.x`, `F.x` and
  `D.x` after `xtset`, find values by time rather than row position, so gaps
  give missing values. They support `Date`s by period (`unit`), date-times,
  tsibble and zoo period classes and ordered factors.

* New `row_nvals()`, like egenmore's `egen rownvals()`, counts distinct values
  in each row.

* New `tostring()`, like Stata's `tostring`, gives values as text, keeping
  codes rather than value labels.

* `xtile()` gains `method = "rank"` for balanced groups that may split ties.

### Selecting and previewing

* New `preview_table()` keeps a full table while displaying head/tail or
  evenly spaced rows; the setting persists through supported dplyr and tidyr
  operations. `unpreview_table()` removes it.

* New `print_all()`, like Stata's `list`, prints every row and column.
  New `s_print()` prints the first and last rows, evenly spaced rows or every
  row through one `style` argument.

* `print_headtail()`, `print_interval()`, `slice_headtail()` and
  `slice_interval()` are restored and accept `sf` data.

* `ds()` gains `.type = "table"`, returning the names as a one-column table.

* `set_seed(123)` also works on its own, like `set seed 123`.

* `variables_search()` also searches variable labels.

## Minor improvements and bug fixes

* `tab()`, `tab1()`, `fre()` and `fre1()` check that `.desc` is `TRUE` or
  `FALSE` before tabulating; a vector or `NA` previously failed inside the
  sorting step, and aborted R 4.1. `row_var()` now matches `stats::var()`
  exactly on platforms without extended precision, such as Apple Silicon.

* The plain example scripts and the migration guide are no longer installed
  with the package. The scripts are in the repository's `examples/` folder
  and the guide is the website's
  [Migration guide](https://socimh.github.io/tidystata/articles/migration.html)
  article.

* SPSS user-defined missing codes and ranges (`haven::labelled_spss()`) are
  treated as missing throughout: in `pwcorr()`, `misstable()`, `std()`, `pc()`,
  `is_first(.missing = FALSE)`, `as_dummy()`, the panel operators,
  `codebook()` and `mvencode()`, as `summ()` and `tab()` already did.

* Errors, warnings and messages use cli. Errors name the function you called,
  describe the problem in one sentence and give hints as bullets. Code that
  matched the old wording may need updating; results are unchanged.

* Examples, vignettes and README use the native pipe `|>`. `%>%` is still
  exported.

* `pwcorr()` excludes zero-weight values, avoids overflow with very large
  weights or scales, and rejects explicitly selected matrix or array columns.
  Analytic weights in tabulations and summaries normalize safely within each
  group.

* `duplicates_list()` preserves grouping and errors when `.row` or
  `.dup_group` already exists.

* `summ()` and `tabstat()` keep numeric and logical columns with no observed
  values, including zero-row inputs; combine numeric and calendar summaries
  in `.type = "table"` without type conflicts; display datetimes in their own
  time zone and infinite Dates as `Inf`/`-Inf`; skip calendar variables with a
  warning when `sum`, `skew` or `kurtosis` is requested; and rename grouping
  keys that collide with summary columns, with a message.

* A piped vector (`x |> summ()`) is named `value`. `.by` given a computed
  expression explains that it selects columns, instead of "object not found".

* `tab()`, `tab1()`, `fre()` and `fre1()` calculate statistics and totals
  within each group, keep missing group keys and place missing categories
  last. An explicit `.by` replaces inherited groups. List columns are
  counted, and selecting no variables returns an empty result.

* `tab2()` and `fre2()` order columns by value or factor level with missing
  last, support blank column categories, keep categories that match variable
  names and report ambiguous name collisions; `fre2()` rejects a column
  category `"total"`.

* `codebook()` returns one inventory of the selected columns even for
  grouped input, and counts missing list elements and structured columns
  consistently.

* Row helpers return vectors consistently, handle empty and all-missing rows,
  use sample variance and standard deviation, keep calendar, duration and
  measured units where arithmetic is defined, and can use grouping columns
  inside grouped `mutate()`. `row_mean()`, `row_median()`, `row_var()`,
  `row_sd()`, `row_min()`, `row_max()` and `row_sum()` accept `na.rm`.

* `var_type()` recognizes measured vectors, and `var_unit()` returns their
  units, including compound units such as `m/s`. Custom and structured type
  descriptions are kept instead of truncated.

* `destring()` parses character input while keeping its length and missing
  positions and exposing parsing warnings. `decode()` handles labelled vectors
  without value labels, including tagged missing values.

* `varlist()` combines space-separated numeric-range patterns correctly and
  gives a direct error for non-character patterns.

* `cut_length()` rejects invalid interval counts before calculating breaks.
  Help clarifies that a scalar `cut_breaks()` value is an interior cutpoint.

* `s_select()` returns the first successful operation without rerunning it
  and keeps its warnings.

* `na_if_value()` and `value_if_na()` give actionable messages when required
  arguments are missing; `value_if_na()` fills SPSS user-missing codes.

* `browse()` returns the viewed data invisibly with their class preserved.

* Optional data.table operations explain the missing dependency when needed.

* Two vignettes cover a short workflow and the output-container, grouping and
  missing-value conventions.

## Performance

Results are unchanged; only the time taken to compute them is shorter.

* Row helpers are 2-5 times faster on large data (for example, `row_unique()`
  on 1,000,000 rows fell from about 300 ms to 55 ms), and `row_sum()` and
  `row_mean()` no longer copy the columns into a matrix.

* `summ()` with many groups is much faster: `.detail = TRUE` over 10,000
  groups fell from about 1,060 ms to 240 ms.

* `tab()`, `fre()` and `tab2()` with many groups are faster, especially with
  weights (weighted `tab()` over 10,000 groups: 200 ms to 80 ms).

* `s_merge()`, `destring()`, `pwcorr()`, grouped `xtile()` and `codebook()`
  also do less work.

# tidystata 0.2.0

* Initial CRAN submission.
