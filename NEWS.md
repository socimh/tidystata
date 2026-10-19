# statart 0.2.0.9000

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
