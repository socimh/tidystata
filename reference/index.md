# Package index

## Coming from Stata

- [`findit()`](https://socimh.github.io/tidystata/reference/findit.md) :
  Find the R equivalent of a Stata command

## Inspect variables

- [`browse()`](https://socimh.github.io/tidystata/reference/browse.md) :

  Browse columns like Stata's `browse` command

- [`codebook()`](https://socimh.github.io/tidystata/reference/codebook.md)
  : View the codebook of a dataset or selected columns

- [`misstable()`](https://socimh.github.io/tidystata/reference/misstable.md)
  : Tabulate missing values

- [`ds()`](https://socimh.github.io/tidystata/reference/names.md) : List
  column names by tidyselect

- [`var_type()`](https://socimh.github.io/tidystata/reference/var_type.md)
  [`var_unit()`](https://socimh.github.io/tidystata/reference/var_type.md)
  : Report an object's type or unit

- [`variables()`](https://socimh.github.io/tidystata/reference/variables.md)
  [`variables_search()`](https://socimh.github.io/tidystata/reference/variables.md)
  : Show the variable list of a dataset

## Tabulate

- [`pwcorr()`](https://socimh.github.io/tidystata/reference/pwcorr.md) :
  Pairwise correlations
- [`tab()`](https://socimh.github.io/tidystata/reference/tab.md)
  [`tab1()`](https://socimh.github.io/tidystata/reference/tab.md)
  [`tab2()`](https://socimh.github.io/tidystata/reference/tab.md)
  [`fre2()`](https://socimh.github.io/tidystata/reference/tab.md)
  [`fre()`](https://socimh.github.io/tidystata/reference/tab.md)
  [`fre1()`](https://socimh.github.io/tidystata/reference/tab.md) :
  Tabulate columns

## Summarise

- [`summ()`](https://socimh.github.io/tidystata/reference/summ.md)
  [`tabstat()`](https://socimh.github.io/tidystata/reference/summ.md) :
  Summarise columns

## Check and combine data

- [`assert()`](https://socimh.github.io/tidystata/reference/assert.md) :
  Assert that conditions hold
- [`is_first()`](https://socimh.github.io/tidystata/reference/is_first.md)
  : Flag the first row of each group
- [`isid()`](https://socimh.github.io/tidystata/reference/keys.md)
  [`duplicates_report()`](https://socimh.github.io/tidystata/reference/keys.md)
  [`duplicates_tag()`](https://socimh.github.io/tidystata/reference/keys.md)
  [`duplicates_list()`](https://socimh.github.io/tidystata/reference/keys.md)
  [`duplicates_drop()`](https://socimh.github.io/tidystata/reference/keys.md)
  : Check keys and duplicate rows
- [`stata_merge()`](https://socimh.github.io/tidystata/reference/stata_merge.md)
  : Merge two tables with a Stata-style match report

## Generate variables

- [`as_dummy()`](https://socimh.github.io/tidystata/reference/as_dummy.md)
  [`tab_gen()`](https://socimh.github.io/tidystata/reference/as_dummy.md)
  : Create indicator (dummy) variables
- [`xtile()`](https://socimh.github.io/tidystata/reference/cut.md)
  [`cut_quantile()`](https://socimh.github.io/tidystata/reference/cut.md)
  [`cut_length()`](https://socimh.github.io/tidystata/reference/cut.md)
  [`cut_breaks()`](https://socimh.github.io/tidystata/reference/cut.md)
  : Cut a numeric vector into groups
- [`stata_lag()`](https://socimh.github.io/tidystata/reference/panel.md)
  [`stata_lead()`](https://socimh.github.io/tidystata/reference/panel.md)
  [`stata_diff()`](https://socimh.github.io/tidystata/reference/panel.md)
  : Panel lags, leads and differences
- [`row_mean()`](https://socimh.github.io/tidystata/reference/row_egen.md)
  [`row_sum()`](https://socimh.github.io/tidystata/reference/row_egen.md)
  [`row_max()`](https://socimh.github.io/tidystata/reference/row_egen.md)
  [`row_min()`](https://socimh.github.io/tidystata/reference/row_egen.md)
  [`row_median()`](https://socimh.github.io/tidystata/reference/row_egen.md)
  [`row_var()`](https://socimh.github.io/tidystata/reference/row_egen.md)
  [`row_sd()`](https://socimh.github.io/tidystata/reference/row_egen.md)
  [`row_unique()`](https://socimh.github.io/tidystata/reference/row_egen.md)
  [`row_nvals()`](https://socimh.github.io/tidystata/reference/row_egen.md)
  [`row_miss()`](https://socimh.github.io/tidystata/reference/row_egen.md)
  [`row_non_miss()`](https://socimh.github.io/tidystata/reference/row_egen.md)
  : Calculate summaries across columns within each row
- [`std()`](https://socimh.github.io/tidystata/reference/std.md)
  [`pc()`](https://socimh.github.io/tidystata/reference/std.md)
  [`pct()`](https://socimh.github.io/tidystata/reference/std.md) :
  Standardise a variable or scale it to a percentage

## Convert types

- [`mvdecode()`](https://socimh.github.io/tidystata/reference/na_conversion.md)
  [`mvencode()`](https://socimh.github.io/tidystata/reference/na_conversion.md)
  [`na_if_value()`](https://socimh.github.io/tidystata/reference/na_conversion.md)
  [`value_if_na()`](https://socimh.github.io/tidystata/reference/na_conversion.md)
  : Replace values with missing values or fill missing values
- [`destring()`](https://socimh.github.io/tidystata/reference/type_conversion.md)
  [`decode()`](https://socimh.github.io/tidystata/reference/type_conversion.md)
  [`tostring()`](https://socimh.github.io/tidystata/reference/type_conversion.md)
  [`as_character()`](https://socimh.github.io/tidystata/reference/type_conversion.md)
  [`as_numeric()`](https://socimh.github.io/tidystata/reference/type_conversion.md)
  : Convert vectors for data preparation

## Select and preview

- [`select_or_transmute()`](https://socimh.github.io/tidystata/reference/select_or_transmute.md)
  : Select and compute columns
- [`preview_table()`](https://socimh.github.io/tidystata/reference/special-print.md)
  [`unpreview_table()`](https://socimh.github.io/tidystata/reference/special-print.md)
  [`print_headtail()`](https://socimh.github.io/tidystata/reference/special-print.md)
  [`print_all()`](https://socimh.github.io/tidystata/reference/special-print.md)
  [`print_interval()`](https://socimh.github.io/tidystata/reference/special-print.md)
  [`slice_headtail()`](https://socimh.github.io/tidystata/reference/special-print.md)
  [`slice_interval()`](https://socimh.github.io/tidystata/reference/special-print.md)
  : Persistent previews of complete tables
- [`varlist()`](https://socimh.github.io/tidystata/reference/varlist.md)
  : Select columns with a Stata varlist

## Small tools

- [`capture()`](https://socimh.github.io/tidystata/reference/capture.md)
  : Capture an error and report success
- [`set_seed()`](https://socimh.github.io/tidystata/reference/set_seed.md)
  : Set the random seed, in a pipeline or alone
- [`timer()`](https://socimh.github.io/tidystata/reference/timer.md) :
  Time spent on a function
- [`` `%>%` ``](https://socimh.github.io/tidystata/reference/pipe.md) :
  Pipe operator

## Sample Data

- [`lifeexp`](https://socimh.github.io/tidystata/reference/lifeexp.md) :
  Life expectancy data in 1998
