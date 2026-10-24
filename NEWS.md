# tidystata 0.3.1

* `findit()` shows a single clear default, retaining alternatives for ambiguous
  inputs. Comma-separated variable names and hints customize catalogue examples,
  as in `findit(tab, sex, region)` and `findit(tab, gen)`; all matches remain
  available through `print(n = Inf)`.

# tidystata 0.3.0

* Renamed from statart to tidystata, with a focus on data exploration and
  preparation. Legacy import/export, regression and plotting wrappers are removed.
* `findit()` translates Stata commands, R function names and plain questions
  into working examples, with English and Chinese guides. In consoles with
  colour, the Stata and R code retain automatic console colours. Results start
  with compact example blocks, omit redundant function notes and count remaining
  examples explicitly.
* Expanded tabulation and summaries include cross-tables, weights, correlations,
  missing-value reports and grouped calculations.
* Added key checks, duplicate handling, Stata-style merges, panel operators,
  variable transformations and persistent table previews.
* Statistical conventions follow Stata and are checked against its output.
  Tables preserve the input container; missing values and labels are handled
  consistently. See the articles and function reference for details.
* Faster row calculations and grouped aggregation, with fewer required
  dependencies. Requires R 4.1.0 and dplyr 1.1.4 or later; flextable is optional.

# tidystata 0.2.0

* Initial CRAN submission.
