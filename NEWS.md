# statart 0.2.0.9000

## Breaking changes

* Focus the package on data exploration and preparation. `read_data()`,
  `write_data()`, `esttab()`, and `codebook_detail()` are no longer exported.
  Their source, dedicated tests, and documentation are preserved in the
  repository's `extra_functions/` archive. See `MIGRATION.md` in the repository
  for direct alternatives.
* Relative to the GitHub 0.2.0 baseline, `s_time()` becomes `timer()`;
  regression wrappers, `tidy_coef()`, plotting helpers, and special printing/
  slicing helpers are also removed from the active namespace and preserved
  as archived or reworked source. The local `tidy_coef()` to `esttab()` transition
  preceded the four-wrapper retirement. See the complete mapping in MIGRATION.md.
* `fre()` and `fre2()` now return tibbles by default. `fre1()` returns a list of
  tibbles. Request `.type = "flextable"` explicitly for optional rich formatting.
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

## Improvements and fixes

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
