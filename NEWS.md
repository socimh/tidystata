# tidystata 0.4.1

* Shorter, task-focused help, with editor and clipboard lookup guidance under
  `findit()`.
* Clearer README examples and frequency-table headings.
* Removed the unused `lifecycle` dependency.

# tidystata 0.4.0

* Added `corr()`, `spearman()`, `encode()` and Stata-style `stata_recode()`
  (`recode()`). `pwcorr()` gains listwise deletion and p-value adjustments;
  Spearman p-values now use Stata 18's beta approximation.
* `findit()` accepts Stata text, improves matching and statistical examples,
  and adds editor/clipboard helpers. The bilingual reference uses smaller chapters.
* Breaking changes: `as_character()` now aliases `tostring()`; use `decode()`
  for labels. `pct()` is removed; use `pc()`. Preview helpers become `preview()`
  and `unpreview()`, with head/tail and interval shortcuts; former names and
  row-slicing helpers are removed without aliases.
* `isid()` replaces `.missok` with `.missing` and rejects empty strings by
  default. `capture()` returns the result or invisible `NULL`, replacing Booleans.
* Added label-based dummy names and `.type = "tibble"` for `ds()`, `summ()` and
  `tabstat()`. Summary annotations now use messages.
* Faster, leaner calculations; fixes for weights, missing values, conversions,
  binning, dummy variables and input validation. Clearer help and previews.

# tidystata 0.3.2

* Fixed weighted summaries, percentile overflow and grouping/weight-column
  selection in summaries, tabulations and correlations.
* `stata_merge()` preserves master keys and matched values, retaining shared
  values on using-only rows.
* Binning handles SPSS missing values and rejects `integer64`; row extrema
  handle one-row groups and missing constants correctly.
* `tostring()` avoids scientific notation; `destring()` handles labelled text
  and rejects doubled signs. `misstable()` counts SPSS missing values.
* Fixed assertion collisions, factor ordering, Cramer's V, empty dummy inputs,
  selection validation and other edge cases.

# tidystata 0.3.1

* Added a searchable bilingual Stata-to-R reference with source-linked examples,
  alternative approaches and command/package indexes.
* `findit()` improves statistical mappings, missing-value handling, abbreviations
  and query matching. Variable names and hints customize examples; compact
  defaults retain expandable alternatives, qualifications and sources.

# tidystata 0.3.0

* Renamed statart to tidystata, focusing on exploration and preparation;
  removed legacy import/export, regression and plotting wrappers.
* Added `findit()` for Stata commands, R functions and plain-language questions,
  with bilingual guides and compact, coloured examples.
* Expanded tabulations, weighted summaries, correlations, missing-value reports
  and grouped calculations.
* Added key checks, duplicate handling, Stata-style merges, panel operators,
  transformations and persistent previews.
* Checked statistical conventions against Stata; preserved table containers
  and consistent missing-value and label handling.
* Faster row calculations and aggregation, with fewer dependencies. Requires
  R 4.1.0 and dplyr 1.1.4 or later; flextable is optional.

# tidystata 0.2.0

* Initial CRAN submission.
