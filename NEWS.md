# statart 0.3.0

* `pwcorr()` rejects explicitly selected matrix or array columns and skips them
  during automatic selection, rather than silently correlating only part of them.

* `duplicates_list()` preserves grouping and errors when `.row` or `.dup_group`
  already exists, preventing the returned metadata from replacing user columns.

* `pwcorr()` excludes zero-weight values from arithmetic and handles very large
  finite weights and variable scales without intermediate overflow. Analytic
  weights in tabulations and summaries normalize safely within each group even
  when their unscaled sum overflows.

* `pwcorr()`, `misstable()`, `std()`, `pc()`, `is_first(.missing = FALSE)`,
  `as_dummy()` and the panel operators (`s_lag()`, `s_lead()`, `s_diff()`)
  now treat SPSS user-defined missing codes and ranges
  (`haven::labelled_spss()`) as missing, as `summ()` and `tab()` already did.
  Previously the codes were used as ordinary values.

* `var_type()` and `var_unit()` are now the primary names, following the
  naming rule for functions without a Stata counterpart. `s_type()` and
  `s_unit()` are deprecated: they still work, with a lifecycle warning.

* Arguments follow one naming rule: options after a `...` that takes columns
  or expressions are dotted, and functions without `...` use plain names. Renamed arguments
  keep working with a lifecycle deprecation warning:
  `destring()`, `decode()`, `var_type()`, `var_unit()`, `na_if_value()`,
  `value_if_na()` and `timer()` take `x` (not `.x`); `capture()` and
  `set_seed()` take `x` (not `.fn`); `var_type(abbr)`, `timer(on_error)`,
  `na_if_value(value)` and `value_if_na(value)` drop their dots;
  `s_merge()` takes `keep`, `assert`, `generate` and `report`; and
  `varlist()` takes `ignore_case`. See MIGRATION for the full table.

* `summ()` and `tabstat()` replace `.na.rm` with `.missing` (with the opposite
  value, default `TRUE`), matching `is_first()` and `row_nvals()`: missing
  grouping keys form their own group unless `.missing = FALSE`. `.mode`
  becomes `.type`, with the same `"list"` and `"table"` values.

* `tab2()`, `fre2()` and `xtab()` gain `.by`, returning one cross-table per
  group in a list named like `"g = a"`, as Stata's `by g: tab x y`.

* Enumerated options (`.type`, `.wt_type`, `.group_order`, `method`, `unit`,
  `relationship`, `style`) are checked with `rlang::arg_match()`: they must be
  spelled in full, and a mistyped value suggests the intended one.

* `s_match()` now signals a lifecycle deprecation warning instead of a
  once-per-session message. lifecycle moves from Suggests to Imports.

* Errors, warnings and messages now use cli, as in the tidyverse. Errors name
  the function you called (for example ``Error in `summ()`:``), describe the
  problem in one sentence, and give hints as `i` bullets. Argument checks
  report what was supplied, as in "`n` must be a whole number larger than or
  equal to 1, not the number 0.". Code that matched the old wording of these
  messages may need updating; results are unchanged.

## Speed (2026-10-20)

Results are unchanged; only the time taken to compute them is shorter.

- Row helpers are 2-5 times faster: `row_max()`, `row_min()`, `row_median()`,
  `row_var()`, `row_sd()`, `row_unique()` and `row_nvals()` on 1,000,000 rows
  fell from about 300 ms to 55-115 ms. `row_sum()` and `row_mean()` no longer
  copy the columns into a matrix.
- Row helpers and `xtile()` no longer spend about 5 ms per call outside
  `mutate()` checking whether they are inside a dplyr verb.
- `summ()` with many small groups is faster: `.detail = TRUE` over 10,000
  groups fell from about 1,060 to 240 ms, and the default statistics by about
  20%.
- `tab()`, `fre()` and `tab2()` with many groups are faster, especially with
  weights (weighted `tab()` over 10,000 groups: 200 to 80 ms).
- `s_merge()` (170 to 70 ms for 1,000,000 rows), `destring()` (250 to 85 ms),
  `pwcorr()` (about 40% faster) and grouped `xtile()` (about 35% faster) also
  do less work.

## Stata names and aliases (2026-10-20)

- Functions now carry their Stata names, with the earlier names kept as quiet
  aliases on the same help pages: `mvdecode()`/`mvencode()` (aliases
  `na_if_value()`/`value_if_na()`), `destring()`/`decode()` (aliases
  `as_numeric()`/`as_character()`), `pc()` (alias `pct()`, which clashes
  with `gt::pct()`), and `tab2()`/`fre2()` (alias `xtab()`). Further
  aliases: `s_tag()` for `is_first()`, `tab_gen()` for `as_dummy()`,
  and `cut_quantile()`, `s_try()` and `names_as_column()` without a notice.
- `tab2()` and `fre2()` with three or more variables return every pairwise
  table as a named list, as Stata's `tab2` does; with `.chi2 = TRUE`, each
  test is headed "-> tabulation of x by y".
- `mvdecode()` treats several codes as a set, like `mv(-98 -99)`. This also
  applies to `na_if_value()`, which used to compare a vector of codes
  elementwise, as `dplyr::na_if()` does; a single code works as before.
- New `tostring()`, like Stata's `tostring`: values as text, keeping codes
  rather than value labels (`decode()` gives the labels).
- New `row_nvals()`, like egenmore's `egen rownvals()`: distinct values in
  each row, ignoring missing values unless `.missing = TRUE`, when it equals
  `row_unique()`.
- New `s_print()` prints the first and last rows, evenly spaced rows or every
  row through one `style` argument.
- `ds()` gains `.type = "table"`, which returns the names as a one-column
  table; `ds_as_column()` and `names_as_column()` are aliases for it.
- `set_seed(123)` also works alone, like `set seed 123`; the pipe form
  `x %>% set_seed(123)` is unchanged.
- `findit()` entries use these names, and the R-function table describes
  each alias.

## Assertions, first-row flags and full listings (2026-10-19)

- New `assert()`, like Stata's `assert`: checks conditions on every row (with
  `.by` or groups for `n()`, `mean()` and similar), stops with the number of
  contradictions and the first failing rows, and otherwise returns the data
  invisibly so it fits in a pipe. Missing results count as contradictions.
- New `is_first()`, like `egen tag()`: `TRUE` for the first row of each
  distinct combination of its arguments, or of each group when called
  without arguments in grouped `mutate()`. Rows with missing keys are `FALSE`
  unless `.missing = TRUE`.
- New `print_all()`, like Stata's `list`: prints every row and column of a
  data frame, tibble, data.table, grouped or sf table and returns it
  invisibly.

## Panel lags, leads and differences (2026-10-19)

- New `s_lag()`, `s_lead()` and `s_diff()` for `mutate()`, like Stata's
  `L.x`, `F.x` and `D.x` after `xtset`. Values are found by time, not row
  position, so gaps give missing values and row order does not matter.
  Supply the panel with `.by` or `group_by()` and the time with `time =`;
  `delta` mirrors `xtset, delta()`, and `unit = "month"`, `"quarter"`,
  `"week"` or `"year"` compares `Date`s by whole periods like `%tm`/`%tq`.
  Date-times (with `"second"` to `"year"` units, on the local clock),
  tsibble's `yearweek`/`yearmonth`/`yearquarter` and zoo's
  `yearmon`/`yearqtr`, and ordered factors such as survey waves (level
  order, so an unused level is a gap) also work as `time`. `s_diff(x, 2)` is `D2.x`, and
  `s_diff()` of dates gives a `difftime`. Results were checked against
  StataNow 19.

## Standardising, percentages and dummies (2026-10-19)

- New `std()` and `pc()` for `mutate()`, like Stata's `egen std()` and
  `egen pc()`: `std()` returns a plain standardised vector (with optional
  `mean` and `sd`), and `pc()` a percentage of the total (or a proportion
  with `prop = TRUE`). In grouped `mutate()` or with `.by`, each group uses
  its own statistics, like `by g: egen`.
- New `as_dummy()`: one 0/1 column per observed category, placed after its
  source, like `tabulate x, generate(x_)`. Missing values give missing
  indicators; columns carry Stata-style labels such as `"sex==male"`.
  `.names = "index"` numbers the columns and `.remove = TRUE` drops the
  source. The input container (data.table, grouped, sf) is kept.

## Aggregation internals (2026-10-19)

- Frequency tables calculate percentages and cumulative values on count vectors,
  with cumulative sums restarted within each group. Cross-tabulations fill a
  preallocated rectangle when display headers are unambiguous.
- Summaries share type, unit, missingness and group preparation across families.
  Weighted requests now skip unrequested medians, quantiles and spreads, and
  combine requested percentiles into one sorting pass per variable/group.
- Public interfaces, aliases, statistical definitions and dependencies are
  unchanged. Existing native routines are retained; no new C++ is added.

## Correlations, missing values and chi-square (2026-10-19)

- New `pwcorr()`: a tidy table of pairwise correlations with `n` and the
  p-value for each pair, like Stata's `pwcorr, sig obs`. It supports
  `.method = "spearman"`, `.by`, frequency and analytic weights (`.wt`), and
  `.wide = TRUE` for Stata's lower-triangle matrix.
- New `misstable()`: missing values by variable, like `misstable summarize`,
  or missing patterns with `.patterns = TRUE`, like `misstable patterns`.
  Supports `.by`; `.all = TRUE` also lists complete variables.
- `tab2()` gains `.chi2 = TRUE`, like `tab x y, chi2 V`: Pearson's chi-square,
  its p-value and Cramer's V are printed and stored in `attr(x, "chi2")`
  (and added as a flextable footer). It matches
  `chisq.test(correct = FALSE)`.

## Weights (2026-10-19)

- `tab()`, `tab1()`, `fre()`, `fre1()`, `tab2()`, `summ()` and `tabstat()`
  gain `.wt` and `.wt_type`, like Stata's `[fweight]` and `[aweight]`.
  Frequency weights (default) count each row `w` times, as in
  `dplyr::count(wt =)`, and allow non-integer weights. Analytic weights,
  suited to sampling weights, are rescaled within each group to sum to the
  number of rows, so counts stay on the sample scale.
- Weighted summaries follow Stata's formulas: the mean is `sum(w * x) / W`,
  the variance uses `W - 1`, and percentiles, `median`, `iqr` and `mad` use
  Stata's weighted percentile rule. `unique`, `miss_n` and `valid_pct` stay
  unweighted row counts.
- `xtile()` gains `wt` for weighted cutpoints, as in Stata's `xtile [w]`.
- Rows with missing weights are excluded with a message; negative weights are
  an error. When no variables are selected, the weight column is not itself
  tabulated or summarised.

## Coming from Stata (2026-10-19)

- New `findit()` gives the R equivalent of a Stata command: the statart
  function where one exists, and the standard package otherwise (fixest,
  modelsummary, tidyr, binsreg, srvyr and others). Type one word bare
  (`findit(reg)`) or quote longer Stata code
  (`findit("merge 1:1 id, keep(match)")`); Stata's minimum abbreviations
  work, extra words rank the closest idioms first, and unmatched text falls
  back to a keyword search with suggestions. `findit()` alone lists every
  entry. Results print the Stata line and task above the full R code.
- The entries live in `inst/extdata/stata-to-r.csv`, with English and Chinese
  descriptions. New website articles, "Coming from Stata" in English and
  Chinese, show them by topic, and the "where to find the rest" section of
  MIGRATION.md points to `findit()`.
- Coverage was checked against the Stata Training cheat sheets (data
  processing, transformation, analysis, programming, visualisation) and the
  Stata 17-18 table commands, then widened to about 410 idioms and 250 Stata
  commands and functions. It now includes `collapse`, `levelsof`, `egen`
  functions, `generate` functions such as `cond()`, `inlist()` and
  `inrange()`, string and date functions, basic tests, multinomial, ordered,
  count, quantile, multilevel and selection models, postestimation,
  `dtable`/`etable`/`putexcel`, causal methods (`teffects`, `didregress`,
  `csdid`, `rdrobust`, `synth`), multiple imputation, a new survival section,
  survey subpopulations and more graph types. External entries remain text
  only; statart gains no dependencies.
- `findit()` also accepts R function names, so beginners need not know which
  is which: `findit(left_join)`, `findit(lm())` or `findit(dplyr::left_join)`
  describe the function and list the Stata idioms it replaces. Words that are
  both, such as `log`, `round` or `summ`, show the Stata command and the R
  function under separate headings. Results gain a `match` column. A new
  `inst/extdata/r-functions.csv` describes about 600 R functions in one
  English and one Chinese line each: every function in the entries, plus
  common ones a Stata user meets (dplyr, tidyr, stringr, forcats, lubridate,
  purrr, base and stats, ggplot2, haven, labelled, janitor and model
  packages). Functions that no entry uses yet, such as `findit(n_distinct)`,
  print their description and a related Stata command. Both articles end
  with an index of these functions.

## Cross-tabulation and merging (2026-10-19)

- `tab2()` cross-tabulates two variables, like Stata's `tab x y`, and
  `fre2()` (`tab2(.total = TRUE)`) adds the total row and column.
- `tab()` and `tab1()` gain `.total`; `tab(.total = TRUE)` equals `fre()` and
  `tab1(.total = TRUE)` equals `fre1()`. `fre()` and `fre1()` stay as
  shortcuts.
- New `s_merge()` joins like Stata's `merge`: it requires and checks the key
  relationship (`"1:1"`, `"m:1"`, `"1:m"`), prints a matched/unmatched report,
  adds a `.merge` factor (Stata's `_merge`), and supports `.keep`, `.assert`
  and `.generate`. Values from `.data` win for shared non-key columns.
- R sources are now plain ASCII: information glyphs in messages use escapes,
  removing a non-ASCII portability warning from package checks.

## Stata names and key checks (2026-10-19)

- New `isid()` checks that columns uniquely identify the rows, like Stata's
  `isid`; it returns the data invisibly or errors with the number of repeated
  keys, and `.missok` allows missing key values.
- New `duplicates_report()`, `duplicates_tag()`, `duplicates_list()` and
  `duplicates_drop()` follow Stata's `duplicates` subcommands. Dropping on a
  subset of columns errors when the removed rows differ elsewhere, unless
  `.force = TRUE`.
- New Stata names: `cut_quantile()` is now `xtile()` and `s_try()` is now
  `capture()`, with the old names kept as aliases. `s_match()` is now
  `varlist()`; `s_match()` remains as a deprecated alias with a
  once-per-session notice.

## Metadata and distinct-counting performance (2026-10-19)

- Expand only recognized type abbreviations; preserve custom and structured
  pillar descriptions instead of truncating or rewriting their names. Empty or
  missing descriptions fall back to the class. Numeric-looking prefixes no
  longer confer summary support, and haven conversion requires a haven class.
- Use direct storage-type detection for plain vectors and direct unit metadata
  where available. Extend exact type/unit coverage across empty, missing,
  classed, structured, custom S3/vctrs, S4 and optional-package inputs.
- Assemble codebooks once, avoid redundant identity construction for single-group
  distinct counts, and vectorize cross-table totals while preserving integer
  storage and safe promotion for large totals. No dependency or native kernel
  is added.

## Aggregation performance (2026-10-19)

- Reduce per-category overhead in one-way and joint tabulations by using the
  existing native grouping routine directly, preserving category order and
  separate NA/NaN identities. Explicit legacy locale options retain dplyr counting.
- Dispatch summary statistics once per variable and reuse observed group slices.
  Existing statistical routines, requested-statistic calculation, missingness,
  output contracts and dependencies are unchanged. Gains are largest with many
  groups; repeated-call and allocation benchmarks cover small, large and wide data.

## Repository cleanup (2026-10-19)

- Consolidate current development status and backlog in DEVELOPMENT.md, retain
  active regression tests and current demo reports, and remove superseded
  documents, obsolete tooling and accumulated build results after a verified
  external backup. Package APIs, dependencies and datasets are unchanged.
- Retired wrappers and historical archives are no longer included in the source
  checkout. The maintainer's verified external backup and tracked Git versions
  retain earlier implementations; MIGRATION.md documents supported alternatives.
  Earlier entries below describe their original milestones and storage locations.
- Current migration/help and the latest follow-up entries supersede older
  descriptions of changed defaults and binning or duration representations.

## PROBLEMS2 low-severity follow-up (2026-10-19)

- **Breaking:** calendar spread statistics (`sd`, `se`, `mad`, `iqr`) in
  `summ()`/`tabstat()` are `difftime` columns with one unit per column (days
  for Dates; for datetimes and times, the unit that fits the median spread),
  so rows are comparable and usable in arithmetic. Sub-day Date spreads are no
  longer rounded to `0d`. `.duration_format` no longer affects output.
- **Breaking:** in `.mode = "table"`, calendar spreads are numbers in days
  (Dates) or seconds, with the unit appended to `type` (`"date [days]"`), and
  numeric values in shared text columns are rounded to seven significant
  digits.
- `hms` times of day are summarised in a `time` family: locations display as
  `hh:mm:ss` and spreads are durations, instead of raw seconds.
- **Breaking:** `cut_quantile()` returns integer codes inside a grouped data
  mask (such as `group_by() |> mutate()`) when labels are not given, because
  group-specific interval labels cannot be combined. It also accepts logical
  vectors and `labels = TRUE`.
- `fre()`, `tab1()` and `fre1()` accept atomic vectors, like `tab()`.
- A piped vector (`x %>% summ()`) is named `value` rather than `.`.
- `.by` given a computed expression explains that it selects columns and
  suggests creating the column first, instead of "object not found".
- Row helpers can use grouping columns inside grouped `mutate()`.
- `slice_headtail()`, `slice_interval()`, `print_headtail()`,
  `print_interval()` and `preview_table()` accept `sf` data.

## Validation readiness

- Long calendar-duration summaries use singular units for values such as
  `1 day` and `1 second`, while retaining plural units for other values.
- Infinite Date summaries display `Inf` and `-Inf` distinctly from missing
  values; underlying values and returned classes are preserved.
- `na_if_value()` gives an actionable message when required arguments are
  omitted, consistent with `value_if_na()`.

## PROBLEMS2 follow-up review (2026-10-18)

An independent review found that several PROBLEMS2 scenarios still gave
silent wrong results or kept the complained-about default. Changes:

- **Breaking:** `summ()` and `tabstat()` sort `.by` groups like `tab()`
  (`.sort = TRUE`: factor levels, ascending keys, missing keys last) and hide
  the `name` column when exactly one variable is summarised (`.name = FALSE`).
  Use `.sort = FALSE` or `.name = TRUE` for the previous layout.
- **Breaking:** `timer()` reports elapsed time on failure by default
  (`.on_error = TRUE`); the original error object and call are untouched.
- **Breaking:** `cut_quantile()` follows Stata's `xtile` rule, so distinct
  values are never merged: a 0/1 dummy gives two groups, and occupied groups
  are numbered consecutively. Untied data give the same results as before.
- **Breaking:** `s_select()` (and therefore `tab()`, `summ()` and related
  functions) computes expressions that use columns instead of first trying
  them as selections; `half = y / x` previously selected column `y`. Named
  constants (`one = 1`) create constant columns, and misspelled or
  out-of-range selections error, listing every unmatched name, instead of
  evaluating a same-named object or a literal. Computed expressions run once.
- `row_min()` and `row_max()` treat numeric constants like `pmin()`/`pmax()`:
  `row_min(x, 0.5)` caps `x`, and constants never fill all-missing rows.
  `row_mean()`, `row_median()`, `row_var()`, `row_sd()`, `row_min()` and
  `row_max()` accept `na.rm`; count helpers reject it instead of treating it
  as a data column.
- Spatial aggregation keeps grouping columns added after geometry, as in
  `st_read()` data modified with `mutate()`.
- `tab2()`/`fre2()` order columns by value or factor level with missing last,
  and reject `.by`, `.desc` and `.group_order`. Stacked labelled variables keep
  their own labels. Reserved-name rename messages share one wording, and
  `tab1()`/`fre1()` rename only grouping keys that actually collide.
- Grouped `summ()`/`tabstat()` and `fre(.by)` are much faster. Datetimes are
  displayed in their own time zone. Calendar variables are skipped with a
  warning when `sum`, `skew` or `kurtosis` is requested with numeric ones, and
  `tabstat(.detail = TRUE)` returns detail statistics.
- `value_if_na()` fills SPSS user-missing codes.

## Second R Packages review

- `s_match()` now combines space-separated numeric-range patterns without
  malformed regular expressions or silently omitting matches. Each pattern
  continues to match complete names; explicit `vars` supports standalone calls.
- Help clarifies that a scalar `cut_breaks()` value is an interior cutpoint,
  with observed endpoints included, rather than a requested interval count.
- Large-input tests check their results independently of elapsed wall time;
  performance measurements remain separate from ordinary correctness gates.

## Historical PROBLEMS2 repairs

- Summary and frequency aggregation exclude spatial geometry before selection,
  preventing incorrect counts and duplicate geometry summaries.
- Cross-tabs support blank column categories and consistent logical axis order;
  stacked one-variable tables handle incompatible ordered factors.
- `row_sum()` consumes `na.rm` as a validated argument. Row extrema accept
  explicit `.values` constants without changing numeric column selectors.
- Summary statistics calculate only requested dependencies, accept arbitrary
  `p0` through `p100` percentiles, and offer `.sort` and `.drop_empty` controls.
- Quantile cuts offer an explicit balanced `method = "rank"` that may split ties.
  Existing tie-preserving boundaries remain the default.
- `tab()` accepts atomic vectors; `ds()` can select from character inventories.
  Grouped frequencies offer `.group_order = "frequency"` independently of
  within-group `.desc` sorting.
- `timer(.on_error = TRUE)` reports failed elapsed time while preserving the
  original error. Missing replacement arguments receive actionable diagnostics.
- The historical audit records every source note and screenshot, representative
  labelled-data checks, real output examples, and migrations for retired APIs.

## R Packages textbook alignment

- `cut_length()` now rejects invalid interval counts before calculating breaks;
  valid positive whole-number counts retain their previous results.
- `s_match()` gives a direct diagnostic for noncharacter patterns. Optional
  data.table operations explain the missing dependency when requested.
- Unexpected test warnings now fail verification. Tests isolate session/RNG
  state and assert intentional warnings; timer formatting has fixed-value tests.
- Two installed workflow vignettes and installed migration/provenance documents
  explain containers, grouping, missing values, and local-source installation.
- Package help is consolidated and native scaffolding is archived. Explicit
  row names are preserved by slicing; automatic names follow dplyr behavior.
- Release verification includes source bundles, vignettes and the PDF manual.
  Dataset redistribution and supported-platform evidence remain release gates.


## Breaking changes

* Focus the package on data exploration and preparation. `read_data()`,
  `write_data()`, `esttab()`, and `codebook_detail()` are no longer exported.
  Their source, dedicated tests, and documentation are preserved in the
  repository's `extra_functions/` archive. See `MIGRATION.md` in the repository
  for direct alternatives.
* Relative to the GitHub 0.2.0 baseline, `s_time()` becomes `timer()`;
  regression wrappers, `tidy_coef()`, and plotting helpers are also removed
  from the active namespace and preserved
  as archived or reworked source. The local `tidy_coef()` to `esttab()` transition
  preceded the four-wrapper retirement. See the complete mapping in MIGRATION.md.
* Table-producing helpers preserve base data.frame, tibble, and data.table input
  containers, including empty results and tables inside existing list outputs.
  Summaries and inventories are ungrouped; statistical conventions are unchanged.
  Newly constructed tables do not preserve arbitrary subclass metadata.
* `fre()` and `fre2()` default to `.type = "auto"`. Request `.type = "tibble"`
  explicitly for a tibble or `.type = "flextable"` for optional rich formatting.
  An empty selection in `fre2(..., .type = "flextable")` now errors clearly
  instead of silently returning a tibble.
* `cut_quantile()` keeps equal values together. Duplicate quantile cutpoints
  reduce the number of intervals with a warning; custom labels must match that
  effective number. Exact equivalence to Stata's `xtile` is not promised.
* `row_min()` and `row_max()` now preserve the compatible common input type:
  logical inputs return logical values and integer inputs return integers,
  rather than always returning doubles. They also support character values,
  ordered factors, calendar, duration, measured, labelled, and `integer64`
  values without converting them to numeric indicators. Ordered factors cannot
  be mixed with other types for extrema. Unsupported orderings or incompatible
  combinations error explicitly.
* R 4.1.0 or later is now required.
* Persistent preview formatting requires tibble >= 3.1.0 and pillar >= 1.8.0,
  the versions providing the public table-formatting extension hooks used here.

## Improvements and fixes

* Preserve the underlying base data.frame, tibble, or data.table container in
  previews and row slices. Preview wrapping and unwrapping copy data.tables
  before changing metadata. Printing uses a temporary tibble, and base
  data-frame row names are retained. Supported external dplyr/tidyr operations
  retain their own container and grouping rules while carrying preview settings.

* Add `preview_table()` to retain a full table while displaying head/tail or
  approximately evenly spaced rows. Its settings persist through supported
  data manipulation, including grouping, summaries, left-table joins,
  first-input row binding, and pivots. `unpreview_table()`, `as_tibble()`, and
  `as.data.frame()` explicitly return ordinary tables.
* Restore `print_headtail()`, `print_interval()`, `slice_headtail()`, and
  `slice_interval()` as reviewed implementations. Print helpers return the
  original input invisibly; slice helpers return actual subsets. `n` is the
  total row budget, accepts positive integers or `Inf`, and selects each row at
  most once. Head/tail selection gives the head the extra row for odd budgets;
  `n = 1` selects the first row. The original implementation remains archived.

* Make `codebook()` return a global inventory of selected columns even for
  grouped input, without reinserting unselected grouping keys. Count SPSS
  user-missing values and scalar missing list elements consistently; structured
  columns count complete rows. Preserve Unicode names during inventory creation.
* Return the first successful `s_select()` operation without rerunning it or
  probing data masking after successful selection. Preserve warnings from the
  successful operation. Document fallback evaluation and precomputation for
  expressions with side effects.
* Correct `browse()` help: the viewed data are returned invisibly with their
  data-frame class preserved, and the interactive viewer is omitted in batch use.

* Reduce required imports from 33 to 12 packages. Rich formatting with
  `flextable` is optional; import/export and model-formatting dependencies are
  no longer required. Use cpp11-registered C++ row kernels and base R compiled
  row means/sums; remove the `Rfast` dependency. Native median and centered
  sample-variance/SD kernels avoid the reproduced overflow/cancellation defects.
* Extract variable labels directly from column attributes and search labels in
  `variables_search()`.
* Require a single non-missing character query in `variables_search()`; an
  empty query still matches all selected variables. Clarify tidyselect inputs,
  name-vector versus name-table outputs, conditional variable-label columns,
  grouping-column retention and the supported search pattern language.
* Avoid a spurious numeric-conversion warning for valid letter-range searches
  in `variables_search()` and `s_match()`.
* Parse character inputs in `as_numeric()` while preserving length and missing
  positions and exposing parsing warnings.
* Calculate grouped one-way tabulation statistics and totals within each group,
  retaining missing group keys and placing missing categories last.
* Make explicit `.by` replace inherited groups in `tab()`, `tab1()`, `fre()`
  and `fre1()`, including a zero-column grouping selection. Document percentage
  denominators and display-label ambiguity in frequency totals. Handle labelled
  vectors without value labels in `as_character()`, including tagged missing
  values, without attempting factor conversion.
* Make row summaries return vectors consistently, handle empty and missing
  rows, and use sample variance and standard deviation. Plain numeric/logical
  and numeric labelled arithmetic returns doubles, with tagged and SPSS
  missingness applied before conversion. Calendar means/medians retain class;
  duration means/medians/sums/SD retain duration units. Compatible measured
  arithmetic on linear zero-origin scales normalizes units and variance returns
  squared units. Offset scales support mean/median only; sums and dispersion
  require explicit conversion to a zero-origin unit. Nonlinear scales require
  explicit conversion before arithmetic. Measured arithmetic uses the public
  units >= 1.0.0 scale API. Calendar sums and dispersion, duration variance, and
  `integer64` arithmetic require explicit conversion. Distinct and missing-value counts return integers; distinct counts
  retain compatible value identities, including list/complex values. Missing
  counts use original `is.na()` rules; `NULL` and empty list elements remain
  observed. Common-type conversions for extrema/distinct counts reject
  conflicting SPSS definitions that change observed missingness. All row helpers
  require one-dimensional columns.
* Retain numeric and logical columns with no observed values in `summ()` and
  `tabstat()`, including zero-row inputs. `n` and `unique` are zero; summary
  statistics, including `sum`, are `NA`; missing counts reflect the input rows.
* Accept `.stat` aliases `missing`, `p25`, `p50`, and `p75`, retaining requested
  names and order alongside canonical names. Add numeric `sum` and report
  unsupported statistics clearly. Calendar dates and datetimes do not support
  `sum`, `skew`, or `kurtosis`.
* Combine numeric and calendar summaries in `.mode = "table"` without type
  conflicts, including retained all-missing numeric columns. Shared formatted
  statistic columns become character; count columns remain numeric. Default
  list mode preserves numeric statistic types in the numeric summary.
* Make `summ()`/`tabstat()` retain counts and unique values for character/list
  columns with `.keep_all = TRUE`, with numeric statistics set to `NA`. Exclude
  SPSS user-missing codes before conversion. Repair reserved grouping-key and
  measured-column names, honor explicit `.by` over existing groups, and handle
  single-variable names in empty grouped output and compact datetime spreads.
  Clarify numeric conventions and calendar output in the shared help.
* Allow list columns in one-way frequency counts. Selections with no variables
  return empty results, including empty lists for the default `tab1()`/`fre1()`
  output. Matrix columns remain unsupported.
* Preserve cross-tabulation categories matching original variable names or
  internal counting/pivot names. Report ambiguous output-name collisions clearly;
  `fre2()` rejects the column category `"total"` before it can overwrite totals.
* Recognize measured vectors in `s_type()` and return their units in `s_unit()`,
  including compound units such as `m/s`, empty vectors, and all-missing vectors.

# statart 0.2.0

* Initial CRAN submission.
