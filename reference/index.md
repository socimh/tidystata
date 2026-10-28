# Package index

## Coming from Stata

- [`findit()`](https://socimh.github.io/tidystata/reference/findit.md)
  [`findit_selection()`](https://socimh.github.io/tidystata/reference/findit.md)
  [`findit_clip()`](https://socimh.github.io/tidystata/reference/findit.md)
  : Find R equivalents of Stata commands

## Inspect variables

- [`codebook()`](https://socimh.github.io/tidystata/reference/codebook.md)
  : Inspect a dataset's codebook

- [`browse()`](https://socimh.github.io/tidystata/reference/browse.md) :

  Browse columns like Stata's `browse` command

- [`misstable()`](https://socimh.github.io/tidystata/reference/misstable.md)
  : Tabulate missing values

- [`var_type()`](https://socimh.github.io/tidystata/reference/var_type.md)
  [`var_unit()`](https://socimh.github.io/tidystata/reference/var_type.md)
  : Report an object's type or unit

- [`ds()`](https://socimh.github.io/tidystata/reference/names.md) :
  Select and list column names

- [`variables()`](https://socimh.github.io/tidystata/reference/variables.md)
  [`variables_search()`](https://socimh.github.io/tidystata/reference/variables.md)
  : Show the variable list of a dataset

## Select columns

- [`select_or_transmute()`](https://socimh.github.io/tidystata/reference/select_or_transmute.md)
  : Select and compute columns
- [`varlist()`](https://socimh.github.io/tidystata/reference/varlist.md)
  : Select columns with a Stata varlist

## Convert types

- [`destring()`](https://socimh.github.io/tidystata/reference/type_conversion.md)
  [`decode()`](https://socimh.github.io/tidystata/reference/type_conversion.md)
  [`encode()`](https://socimh.github.io/tidystata/reference/type_conversion.md)
  [`tostring()`](https://socimh.github.io/tidystata/reference/type_conversion.md)
  [`as_character()`](https://socimh.github.io/tidystata/reference/type_conversion.md)
  [`as_numeric()`](https://socimh.github.io/tidystata/reference/type_conversion.md)
  : Convert vectors for data preparation
- [`mvdecode()`](https://socimh.github.io/tidystata/reference/na_conversion.md)
  [`mvencode()`](https://socimh.github.io/tidystata/reference/na_conversion.md)
  [`na_if_value()`](https://socimh.github.io/tidystata/reference/na_conversion.md)
  [`value_if_na()`](https://socimh.github.io/tidystata/reference/na_conversion.md)
  : Replace values with missing values or fill missing values

## Check and combine data

- [`isid()`](https://socimh.github.io/tidystata/reference/keys.md)
  [`duplicates_report()`](https://socimh.github.io/tidystata/reference/keys.md)
  [`duplicates_tag()`](https://socimh.github.io/tidystata/reference/keys.md)
  [`duplicates_list()`](https://socimh.github.io/tidystata/reference/keys.md)
  [`duplicates_drop()`](https://socimh.github.io/tidystata/reference/keys.md)
  : Check keys and duplicate rows
- [`assert()`](https://socimh.github.io/tidystata/reference/assert.md) :
  Assert that conditions hold
- [`is_first()`](https://socimh.github.io/tidystata/reference/is_first.md)
  : Flag the first row of each group
- [`stata_merge()`](https://socimh.github.io/tidystata/reference/stata_merge.md)
  : Merge two tables with a Stata-style match report

## Create and transform variables

- [`stata_recode()`](https://socimh.github.io/tidystata/reference/stata_recode.md)
  [`recode()`](https://socimh.github.io/tidystata/reference/stata_recode.md)
  : Recode numeric values with Stata-style rules
- [`cut_quantile()`](https://socimh.github.io/tidystata/reference/cut.md)
  [`xtile()`](https://socimh.github.io/tidystata/reference/cut.md)
  [`cut_length()`](https://socimh.github.io/tidystata/reference/cut.md)
  [`cut_breaks()`](https://socimh.github.io/tidystata/reference/cut.md)
  : Cut a numeric vector into groups
- [`as_dummy()`](https://socimh.github.io/tidystata/reference/as_dummy.md)
  [`tab_gen()`](https://socimh.github.io/tidystata/reference/as_dummy.md)
  : Create indicator (dummy) variables
- [`std()`](https://socimh.github.io/tidystata/reference/std.md)
  [`pc()`](https://socimh.github.io/tidystata/reference/std.md) :
  Standardise a variable or scale it to a percentage
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

## Panel operations

- [`stata_lag()`](https://socimh.github.io/tidystata/reference/panel.md)
  [`stata_lead()`](https://socimh.github.io/tidystata/reference/panel.md)
  [`stata_diff()`](https://socimh.github.io/tidystata/reference/panel.md)
  : Calculate panel lags, leads and differences

## Tabulate and summarise

- [`tab()`](https://socimh.github.io/tidystata/reference/tab.md)
  [`tab1()`](https://socimh.github.io/tidystata/reference/tab.md)
  [`tab2()`](https://socimh.github.io/tidystata/reference/tab.md)
  [`fre2()`](https://socimh.github.io/tidystata/reference/tab.md)
  [`fre()`](https://socimh.github.io/tidystata/reference/tab.md)
  [`fre1()`](https://socimh.github.io/tidystata/reference/tab.md) :
  Frequency tables and cross-tabulations
- [`summ()`](https://socimh.github.io/tidystata/reference/summ.md)
  [`tabstat()`](https://socimh.github.io/tidystata/reference/summ.md) :
  Summary statistics

## Correlations

- [`corr()`](https://socimh.github.io/tidystata/reference/corr.md)
  [`pwcorr()`](https://socimh.github.io/tidystata/reference/corr.md)
  [`spearman()`](https://socimh.github.io/tidystata/reference/corr.md) :
  Calculate Pearson and Spearman correlations

## Preview tables

- [`preview()`](https://socimh.github.io/tidystata/reference/preview.md)
  [`preview_headtail()`](https://socimh.github.io/tidystata/reference/preview.md)
  [`preview_interval()`](https://socimh.github.io/tidystata/reference/preview.md)
  [`unpreview()`](https://socimh.github.io/tidystata/reference/preview.md)
  : Set persistent table previews
- [`print_headtail()`](https://socimh.github.io/tidystata/reference/special-print.md)
  [`print_interval()`](https://socimh.github.io/tidystata/reference/special-print.md)
  : Print selected rows once

## Workflow utilities

- [`set_seed()`](https://socimh.github.io/tidystata/reference/set_seed.md)
  : Set the random seed, in a pipeline or alone
- [`capture()`](https://socimh.github.io/tidystata/reference/capture.md)
  : Evaluate an expression without stopping on an error
- [`timer()`](https://socimh.github.io/tidystata/reference/timer.md) :
  Time an expression
- [`` `%>%` ``](https://socimh.github.io/tidystata/reference/pipe.md) :
  Pass a value through a pipeline

## Sample data

- [`lifeexp`](https://socimh.github.io/tidystata/reference/lifeexp.md) :
  Life expectancy data in 1998
