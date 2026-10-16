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
* R 4.1.0 or later is now required.

## Improvements and fixes

* Reduce required imports to 13 packages. Rich formatting with `flextable` is
  optional; import/export and model-formatting dependencies are no longer
  required. Preserve the existing C++ and `Rfast` row-calculation backend.
* Extract variable labels directly from column attributes and search labels in
  `variables_search()`.
* Parse character inputs in `as_numeric()` while preserving length and missing
  positions and exposing parsing warnings.
* Calculate grouped one-way tabulation statistics and totals within each group,
  retaining missing group keys and placing missing categories last.
* Make row summaries return atomic vectors consistently, handle empty and missing
  rows, and use sample variance and standard deviation.

# statart 0.2.0

* Initial CRAN submission.
