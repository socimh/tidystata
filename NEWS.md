# tidystata (development version)

* `summ()` and `tabstat()` reuse native scratch storage for numerical summaries,
  weighted statistics and grouped distinct counts, reducing temporary allocation.
  Large two-column categorical tabulations use bounded native counting when a
  dense integer, logical or factor key is available. Other tabulations retain
  the general counting path. Public interfaces and statistical rules are unchanged.

* `pwcorr()`, `corr()` and `spearman()` compute every variable pair natively
  instead of allocating a row mask and subsets for each pair. Pearson and
  Spearman results, including p-values, are identical; Spearman tables on
  100,000 rows and 30 variables take seconds instead of a minute, and
  temporary allocation falls from gigabytes to megabytes. Integer, logical and
  labelled columns are read without conversion; SPSS-labelled columns are still
  converted so that their user-missing codes are excluded.
* Row functions such as `row_max()` and `row_sum()`, and `summ()`/`tabstat()`,
  read integer, logical and numeric labelled columns in place rather than
  copying them to doubles. Row functions also accept the same vector more than
  once, as Stata's `egen rowmax(x x)` does.

* `var_type()` retains full primary class names when `abbr = FALSE` and the
  display label is a default class abbreviation, including S4 and S7 classes.
  Custom display labels and compact output are preserved; `codebook()` uses
  the improved descriptive labels.

* `as_dummy()` (`tab_gen()`) expands ordered factors instead of failing with
  an internal type error.
* `cut_length()` reports infinite values and empty input with a clear error;
  `NaN` counts as missing. `cut_breaks()` returns an empty ordered factor for
  empty input without base-R range warnings.
* `mvdecode()`, `mvencode()`, `na_if_value()` and `value_if_na()` report a
  value whose type does not match `x` with an error naming `mv` or `value`.
* `tostring()` writes at most 15 significant digits for very large or small
  numbers, instead of platform-dependent extra digits. `tostring()` and the
  interval labels of `xtile()`, `cut_length()` and `cut_breaks()` use a
  decimal point whatever `options(OutDec)` says.
* `summ()`, `tabstat()`, `tab2()`, `fre2()`, `codebook()`, `browse()`, `ds()`,
  `variables()`, `variables_search()` and `select_or_transmute()` reject
  objects that are not data frames, such as dbplyr lazy tables and arrow
  tables, with the same `.data` error as `tab()`; `ds()`, `variables()` and
  `variables_search()` previously listed the object's internal components.
* New stress tests check every exported function against adversarial column
  types, shapes and containers, plus invariants for row order, grouping,
  weights and round trips.

* New `stata_recode()` (alias `recode()`) recodes numeric values with Stata's
  `recode` rules inside `mutate()`: `1:5 ~ 1` selects the closed range 1 to 5,
  including decimals; `c(1, 3:5)` combines values and ranges; `min`, `max` and
  `NA` select the ends and missing values. The first matching rule wins,
  unmatched values are kept unless `.default` replaces them, and named rules
  label the new codes. The `recode()` alias and the superseded
  `dplyr::recode()` mask each other, depending on attach order;
  `stata_recode()` always works. `findit("recode")` lists the new examples.
  Matching now uses C++ without per-rule row masks or expanded scalar defaults,
  reducing allocation on large vectors while retaining ordered rules, numeric
  types, value labels and SPSS/tagged missing-value handling. Integer input
  stays integer when every code and `.default` is a whole number, so
  `1:5 ~ 1` keeps an integer variable's storage type, as in Stata.

* `summ()` and `tabstat()` retain defined weighted skewness and kurtosis when
  fractional frequency weights total at most one, without grouped square-root
  warnings. Weighted means and shape statistics avoid overflow from large
  finite weights; reported frequency totals and weighted sums keep their scale.
* `as_dummy()` preserves generated indicators that replace removed source
  names in data.table inputs. It reports an error when removing every column
  would discard rows from a data.table, with guidance to retain a column.
* `misstable()` applies structured-column missingness to list-backed matrices
  instead of indexing their cell masks as rows.
* Function help and migration guidance clarify missing-key ordering, duplicate
  identities, grouped assertions, panel units, binning boundaries and weights,
  signed standardisation, and Spearman's small-sample p-values. Bilingual
  `findit()` descriptions distinguish variable labels from value labels.

* `pwcorr()` and `spearman()` preserve very small nonzero p-values under Sidak
  adjustment. Weighted `pwcorr()` and `corr()` retain defined correlations when
  unequal weights make the variance product underflow.

* Rename the persistent preview helpers to `preview()` and `unpreview()`,
  with `preview_headtail()` and `preview_interval()` shortcuts. Remove the
  former preview names and row-slicing helpers without compatibility aliases.
  Head/tail output marks an omitted middle with aligned dots; interval output
  retains its compact layout. Persistent previews and one-time printers have
  separate help topics.
* New `spearman()` computes Spearman rank correlations like Stata's
  `spearman`: one common complete sample by default, `.pairwise = TRUE` for
  `spearman, pw`, and Stata 18's beta-approximation p-values. The Spearman
  p-values of `pwcorr(.method = "spearman")` now use the same method instead of
  the t approximation of earlier Stata versions, so they change slightly.
* `pwcorr()` gains `.listwise` (Stata's `pwcorr, listwise`) and `.adjust`
  (`"bonferroni"` or `"sidak"`, Stata's options of the same names).
* `ds()`, `summ()`, and `tabstat()` accept `.type = "tibble"` to return one
  tibble regardless of the input's table class or preview settings. Summary
  families combine as in table output; existing defaults are unchanged.

* `findit()` refreshes bilingual function descriptions and notes for current
  contracts, with reverse lookup descriptions for every tidystata function.

* Shared help pages compare related functions and aliases in opening bullets.
  Grouping, labels, cutting edge cases and examples reflect current behavior.

* `isid()` confirms successful key checks with a message while returning the
  original data invisibly. Use `suppressMessages()` for silent execution.
  `.missing` replaces `.missok` without an alias; update existing calls.
  Empty strings, including empty-string factor values, are rejected by default;
  `.missing = TRUE` allows them and other missing values but still requires
  unique key combinations.

* `capture()` returns the expression's result on success and invisible `NULL`
  on error, replacing its previous `TRUE`/`FALSE` result. It preserves successful
  visibility and evaluates once. Caught errors emit a failure message by default
  that chains the original error, keeping its call and bullets;
  `quiet = TRUE` suppresses it along with warnings and messages from the expression.
  Printed output is retained. Put assignments inside `capture()` to preserve
  existing objects on failure. Existing Boolean uses must be updated.

* `corr()` calculates Pearson correlations on a common complete-case sample,
  like Stata's `corr` (`correlate`), with tidy selection, computed columns,
  groups, weights, and long or wide tibble output.

# tidystata 0.3.2

* `assert()` protects input columns from internal-name collisions and rejects
  matrix conditions instead of reporting nonexistent row numbers.
* `summ()` excludes zero-weight observations from weighted arithmetic, scales
  large analytic weights safely, and avoids overflow when averaging percentile
  boundaries. Weighted percentiles retain their values for large finite weights.
  Datetimes with an empty timezone attribute are accepted.
  Summary and tabulation help distinguish analytic weights from survey-design
  inference.
* `summ()`, the tabulation family and `pwcorr()` retain a grouping column when
  it is also the weight column in an implicit all-column selection.
* `stata_merge()` retains shared non-key values on using-only rows while
  preserving master values, including missing values, on matched rows.
* `cut_length()` and `cut_breaks()` omit SPSS user-missing values before
  computing intervals. Binning functions reject `integer64` inputs with an
  explicit-conversion message instead of reading their underlying payloads.
* `row_min()` and `row_max()` recognize `.data[[column]]` inputs in one-row
  groups and keep `.env` scalars from filling otherwise all-missing rows.

* `tostring()` writes numbers in full, as Stata does: 100000 gives `"100000"`,
  not `"1e+05"`. `destring()` reads labelled text like plain text, so `ignore`,
  its warning and `readr::problems()` apply, and rejects a doubled sign such as
  `"-$-5"`.
* `misstable()` counts SPSS user-missing codes and ranges. List columns use
  the established summary rule: scalar `NA` elements are missing and `NULL`
  elements are observed values. Grouping names that collide with its result
  columns give a clear error.
* `row_min()`/`row_max()` treat `.values` columns as columns in one-row groups,
  and a missing constant makes rows missing when `na.rm = FALSE`, as in `pmin()`.
* `stata_merge()` keeps the master key when `using` has a non-key column of the
  same name; `cut_breaks()` warns when the default median does not split the
  values and rejects missing breaks and all-missing input.
* Fixes: `tab2()` and `fre2()` no longer tabulate grouping or weight columns
  without `.by`, keep factor order around blank headers and compute Cramer's V
  for large 2 x 2 tables; `summ(.missing = FALSE)` accepts weight vectors;
  `as_dummy()` handles columns without observed values; `is_first()` accepts
  `pick()`; malformed `varlist()` ranges, `NA`
  positions and `var_type(abbr = NA)` give clear errors; `pc()` is missing for
  an infinite total; the timer no longer prints `60.00s`.

# tidystata 0.3.1

- `findit()` corrects audited statistical mappings, missing-value handling and
  estimator defaults, with explicit bilingual qualifications and command-specific
  sources. Name substitution, documented abbreviations, row-number queries,
  by-prefix options and Chinese chart questions work while example anchors stay
  stable. Earlier curated examples show their notes in compact output too.
- Add a searchable English/Chinese Stata-to-R reference book, generated from the
  `findit()` catalogue, with chapter navigation and a matching-page language switch.
  A dedicated pkgdown navigation link opens the book on the author's website.
- Expand the bilingual `findit()` reference with executable, source-linked
  examples and selected alternative R approaches. The generated guide provides
  an alphabetical command index, subject tables and a package-sorted R index.
- Keep concise defaults while showing qualifications and sources on explicit
  expansion. Stable example IDs allow several R answers for the same Stata code.
- Respect package-qualified R queries, avoid unrelated word-fragment matches,
  and explain known gaps and unrepresented option combinations.

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
