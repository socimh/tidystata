# Coming from Stata

[中文版](https://socimh.github.io/tidystata/articles/coming-from-stata-zh.md)

If you know Stata, you already know what you want to do; the question is
how to say it in R. This page lists Stata commands next to the R code
that does the same job, using tidystata where it has a Stata-style
function and the standard package everywhere else.

## Look it up from the console

[`findit()`](https://socimh.github.io/tidystata/reference/findit.md)
searches the same list from R. Type one Stata word bare, or quote
anything longer. Stata’s abbreviations work.

``` r

findit(reg)
#> # Stata to R: 6 entries
#> 
#> regress y x1 x2                   # Linear regression [stats]
#>   fit <- lm(y ~ x1 + x2, data = data)
#> regress y x1 x2, robust           # Heteroskedasticity-robust standard errors [fixest]
#>   fixest::feols(y ~ x1 + x2, data = data, vcov = "hetero")
#> regress y x1 x2, vce(cluster id)  # Clustered standard errors [fixest]
#>   fixest::feols(y ~ x1 + x2, data = data, cluster = ~id)
#> regress y i.group c.x1##c.x2      # Factor variables and interactions [stats]
#>   lm(y ~ factor(group) + x1 * x2, data = data)
#> regress y x [pweight = wt]        # Regression with sampling weights [fixest]
#>   fixest::feols(y ~ x, data = data, weights = ~wt, vcov = "hetero")
#> regress y ib3.group               # Choose the base category [stats]
#>   lm(y ~ relevel(factor(group), ref = "3"), data = data)
findit("merge 1:1 id, keep(match)")
#> # Stata to R: 10 entries
#> # "merge" is a Stata command and an R function.
#> 
#> ## Stata command
#> merge 1:1 id using data2, keep(match)                            # Keep matched rows only [dplyr]
#>   inner_join(data1, data2, by = "id")
#> merge 1:1 id using data2, keep(match) keepusing(id) nogenerate   # Keep rows of data1 whose id is in data2 [dplyr]
#>   semi_join(data1, data2, by = "id")
#> merge 1:1 id using data2                                         # Merge with a match report [tidystata]
#>   s_merge(data1, data2, "1:1", by = "id")
#> merge 1:1 id using data2, keep(master match)                     # Keep all rows of the master data [dplyr]
#>   left_join(data1, data2, by = "id")
#> merge 1:1 id using data2, keep(using match)                      # Keep all rows of the using data [dplyr]
#>   right_join(data1, data2, by = "id")
#> merge 1:1 id1 id2 using data2, nogenerate                        # Merge on two keys [dplyr]
#>   full_join(data1, data2, by = c("id1", "id2"))
#> merge 1:1 id using data2, keep(master) keepusing(id) nogenerate  # Keep rows of data1 whose id is not in data2 [dplyr]
#>   anti_join(data1, data2, by = "id")
#> merge m:1 id using data2                                         # Many-to-one merge with a match report [tidystata]
#>   s_merge(data1, data2, "m:1", by = "id")
#> merge 1:m id using data2                                         # One-to-many merge with a match report [tidystata]
#>   s_merge(data1, data2, "1:m", by = "id")
#> merge 1:1 _n using data2                                         # Put two datasets side by side by row position [dplyr]
#>   bind_cols(data1, data2)
#> 
#> ## R function: merge() [base]: Merge two data frames (base R)
#>   Related Stata: merge
```

Call
[`findit()`](https://socimh.github.io/tidystata/reference/findit.md)
with no argument for the whole list, or `??stata` to find this help
again.

## Where to find the rest

tidystata covers the everyday loop of inspecting, tabulating,
summarising, preparing and checking data. For everything else, these
packages are the usual choices:

- **Regression and fixed effects** (`regress`, `reghdfe`, `xtreg`,
  `ivregress`): [`lm()`](https://rdrr.io/r/stats/lm.html) and
  [`glm()`](https://rdrr.io/r/stats/glm.html), or `fixest::feols()`.
- **Regression tables** (`esttab`, `outreg2`):
  `modelsummary::modelsummary()`.
- **Marginal effects** (`margins`): marginaleffects.
- **Reshaping** (`reshape`):
  [`tidyr::pivot_longer()`](https://tidyr.tidyverse.org/reference/pivot_longer.html)
  and `pivot_wider()`.
- **Winsorising** (`winsor2`): `datawizard::winsorize()`.
- **Panels and calendar periods** (`tsset`, `xtset`, `L.`, `mofd()`):
  tsibble and lubridate.
- **Survey data** (`svyset`, `svy:`): srvyr and survey.
- **Graphs** (`twoway`, `histogram`): ggplot2; for `binscatter`, binsreg
  or `statar::stat_binmean()`.

tidystata and [statar](https://github.com/matthieugomez/statar) can be
attached together; only
[`tab()`](https://socimh.github.io/tidystata/reference/tab.md) and
[`xtile()`](https://socimh.github.io/tidystata/reference/cut.md) share
names. Attach tidystata last, or write
[`tidystata::tab()`](https://socimh.github.io/tidystata/reference/tab.md).

A few RStudio habits replace Stata’s interface: Ctrl+Enter (Cmd+Return
on a Mac) runs the current line or selection, Tab completes names, and
the Environment and Files panes play the roles of Stata’s Variables
window and `dir`.

In the tables below, `data` is your dataset, `data1` and `data2` are the
master and using data of a merge, and `fit` is a fitted model. Most
entries use dplyr, so attach it with
[`library(dplyr)`](https://dplyr.tidyverse.org) or
[`library(tidyverse)`](https://tidyverse.tidyverse.org).

## Basics

[TABLE]

## Explore data

[TABLE]

## Check data

[TABLE]

## Labels

[TABLE]

## Construct and modify variables

[TABLE]

## Select variables and rows

[TABLE]

## Sort

| Stata | R | Notes |
|:---|:---|:---|
| `order x1-x4` | `relocate(data, x1:x4)` | Move variables to the front |
| `order x1-x4, before(x5)` | `relocate(data, x1:x4, .before = x5)` | Move variables before another |
| `sort x1 x2` | `arrange(data, x1, x2)` | Sort in ascending order |
| `gsort x1 -x2` | `arrange(data, x1, desc(x2))` | Sort ascending and descending |

## Combine data

[TABLE]

## Reshape

[TABLE]

## Construct data

[TABLE]

## Strings and dates

[TABLE]

## Loops and programming

[TABLE]

## Models and tables

[TABLE]

## Panel and time series

[TABLE]

## Survival analysis

[TABLE]

## Survey data

[TABLE]

## Graphs

[TABLE]

## R functions in this guide

R functions a Stata user is likely to meet, including every function
used above, with its package, a related Stata command and what it does.
Type `findit(name)`, such as `findit(left_join)`, to see the Stata
commands it replaces.

| Function | Package | Related Stata | Description |
|:---|:---|:---|:---|
| [`abs()`](https://rdrr.io/r/base/MathFun.html) | base | abs() | Absolute value |
| [`acf()`](https://rdrr.io/r/stats/acf.html) | stats | corrgram | Autocorrelation function |
| [`across()`](https://dplyr.tidyverse.org/reference/across.html) | dplyr |  | Apply the same calculation to several columns |
| [`add_count()`](https://dplyr.tidyverse.org/reference/count.html) | dplyr | bysort g: generate n = \_N | Add a column with group counts |
| [`add_row()`](https://tibble.tidyverse.org/reference/add_row.html) | tibble | set obs | Add rows to a table |
| [`addmargins()`](https://rdrr.io/r/stats/addmargins.html) | stats | tabulate x1 x2 | Add totals to a table |
| `adorn_totals()` | janitor | tabulate x1 x2 | Add totals to a tabyl |
| `aes()` | ggplot2 |  | Map variables to x, y, colour and other plot features |
| [`aggregate()`](https://rdrr.io/r/stats/aggregate.html) | stats | collapse | Group statistics (base R) |
| [`AIC()`](https://rdrr.io/r/stats/AIC.html) | stats |  | Akaike information criterion |
| [`all()`](https://rdrr.io/r/base/all.html) | base | assert | Whether all values are TRUE |
| [`all_of()`](https://tidyselect.r-lib.org/reference/all_of.html) | dplyr | keep \`vars' | Select columns named in a character vector |
| `alpha()` | psych | alpha | Cronbach's alpha |
| `annotate()` | ggplot2 | text() | Add one annotation, such as text |
| [`anova()`](https://rdrr.io/r/stats/anova.html) | stats | anova | ANOVA table, or comparison of nested models |
| `Anova()` | car | anova | Type II and III ANOVA tables |
| [`anti_join()`](https://dplyr.tidyverse.org/reference/filter-joins.html) | dplyr |  | Keep rows of the first table with no match in the second |
| [`any()`](https://rdrr.io/r/base/any.html) | base | count if | Whether any value is TRUE |
| [`any_of()`](https://tidyselect.r-lib.org/reference/all_of.html) | dplyr | capture keep | Select listed columns that exist |
| [`aov()`](https://rdrr.io/r/stats/aov.html) | stats |  | Analysis of variance |
| [`apply()`](https://rdrr.io/r/base/apply.html) | base | egen rowtotal() | Apply a function over rows or columns |
| [`arima()`](https://rdrr.io/r/stats/arima.html) | stats |  | ARIMA time-series model |
| [`arrange()`](https://dplyr.tidyverse.org/reference/arrange.html) | dplyr |  | Sort rows |
| [`as.character()`](https://rdrr.io/r/base/character.html) | base |  | Convert to text |
| [`as.Date()`](https://rdrr.io/r/base/as.Date.html) | base |  | Convert to a date |
| [`as.double()`](https://rdrr.io/r/base/double.html) | base |  | Convert to double-precision numbers |
| [`as.factor()`](https://rdrr.io/r/base/factor.html) | base | encode | Convert to a factor |
| [`as.integer()`](https://rdrr.io/r/base/integer.html) | base |  | Convert to whole numbers |
| [`as.numeric()`](https://rdrr.io/r/base/numeric.html) | base |  | Convert to numbers |
| [`as_character()`](https://socimh.github.io/tidystata/reference/type_conversion.md) | tidystata | decode | Alias of decode() |
| `as_date()` | lubridate | dofc() | Convert to a date |
| [`as_dummy()`](https://socimh.github.io/tidystata/reference/as_dummy.md) | tidystata |  | Dummy variables for every category |
| `as_factor()` | haven | decode | Turn labelled values into a factor |
| [`as_numeric()`](https://socimh.github.io/tidystata/reference/type_conversion.md) | tidystata | destring | Alias of destring() |
| `as_survey_design()` | srvyr |  | Declare a survey design |
| [`as_tibble()`](https://tibble.tidyverse.org/reference/as_tibble.html) | tibble |  | Convert to a tibble |
| `as_tsibble()` | tsibble |  | Declare time-series or panel data |
| [`assert()`](https://socimh.github.io/tidystata/reference/assert.md) | tidystata |  | Stop and count the rows where a condition fails |
| `att_gt()` | did |  | Staggered difference in differences (Callaway-Sant'Anna) |
| [`attr()`](https://rdrr.io/r/base/attr.html) | base |  | Get or set an attribute of an object |
| `augment()` | broom | predict | Add fitted values and residuals to the data |
| `avg_comparisons()` | marginaleffects | margins r.x | Average contrasts |
| `avg_predictions()` | marginaleffects |  | Average predictions, like Stata's margins |
| `avg_slopes()` | marginaleffects |  | Average marginal effects |
| `avPlots()` | car |  | Added-variable plots |
| [`bartlett.test()`](https://rdrr.io/r/stats/bartlett.test.html) | stats | oneway | Bartlett test of equal variances |
| [`between()`](https://dplyr.tidyverse.org/reference/between.html) | dplyr |  | Whether values lie within a range |
| [`BIC()`](https://rdrr.io/r/stats/AIC.html) | stats |  | Bayesian information criterion |
| [`bind_cols()`](https://dplyr.tidyverse.org/reference/bind_cols.html) | dplyr |  | Put tables side by side |
| [`bind_rows()`](https://dplyr.tidyverse.org/reference/bind_rows.html) | dplyr |  | Stack tables on top of each other |
| [`binom.test()`](https://rdrr.io/r/stats/binom.test.html) | stats | bitest | Exact binomial test |
| [`binomial()`](https://rdrr.io/r/stats/family.html) | stats |  | Binomial family for logit and probit models |
| `binsreg()` | binsreg |  | Binned scatter plot and estimation |
| `bptest()` | lmtest |  | Breusch-Pagan test for heteroskedasticity |
| [`browse()`](https://socimh.github.io/tidystata/reference/browse.md) | tidystata |  | View data in a spreadsheet window |
| [`c()`](https://rdrr.io/r/base/c.html) | base |  | Combine values into a vector |
| [`c_across()`](https://dplyr.tidyverse.org/reference/c_across.html) | dplyr | egen rowtotal() | Combine columns inside rowwise() |
| [`capture()`](https://socimh.github.io/tidystata/reference/capture.md) | tidystata |  | Run code and return TRUE or FALSE instead of stopping on an error |
| [`case_match()`](https://dplyr.tidyverse.org/reference/case_match.html) | dplyr | recode | Recode values by matching them |
| [`case_when()`](https://dplyr.tidyverse.org/reference/case-and-replace-when.html) | dplyr |  | Several if-else conditions in one step |
| [`cat()`](https://rdrr.io/r/base/cat.html) | base |  | Print text without quotes |
| [`cbind()`](https://rdrr.io/r/base/cbind.html) | base | merge 1:1 \_n | Put side by side (base R) |
| [`ceiling()`](https://rdrr.io/r/base/Round.html) | base |  | Round up |
| [`chisq.test()`](https://rdrr.io/r/stats/chisq.test.html) | stats | tabulate x1 x2, chi2 | Chi-square test |
| [`class()`](https://rdrr.io/r/base/class.html) | base | describe | Class of an object |
| `clean_names()` | janitor | rename \*, lower | Clean and lower-case variable names |
| `clogit()` | survival |  | Conditional logit |
| [`coalesce()`](https://dplyr.tidyverse.org/reference/coalesce.html) | dplyr |  | First non-missing value across vectors |
| [`codebook()`](https://socimh.github.io/tidystata/reference/codebook.md) | tidystata |  | Describe every variable: type, label, counts and values |
| [`coef()`](https://rdrr.io/r/stats/coef.html) | stats |  | Model coefficients |
| `coefplot()` | fixest | coefplot | Coefficient plot for fixest models |
| `coeftest()` | lmtest |  | Coefficient tests with a chosen variance matrix |
| [`colnames()`](https://rdrr.io/r/base/colnames.html) | base | ds | Column names |
| `comparisons()` | marginaleffects | margins r.x | Differences between predictions (contrasts) |
| `complete()` | tidyr |  | Add rows for missing combinations of values |
| [`complete.cases()`](https://rdrr.io/r/stats/complete.cases.html) | stats | egen rowmiss() | Rows with no missing values |
| [`confint()`](https://rdrr.io/r/stats/confint.html) | stats | regress | Confidence intervals of coefficients |
| [`consecutive_id()`](https://dplyr.tidyverse.org/reference/consecutive_id.html) | dplyr | tsspell | Number runs of identical values |
| [`contains()`](https://tidyselect.r-lib.org/reference/starts_with.html) | dplyr |  | Select columns whose names contain some text |
| `coord_cartesian()` | ggplot2 | xscale(range()) | Zoom in without dropping data |
| `coord_flip()` | ggplot2 |  | Swap the x and y axes |
| `coord_polar()` | ggplot2 |  | Polar coordinates, used for pie charts |
| [`cor()`](https://rdrr.io/r/stats/cor.html) | stats |  | Correlation matrix |
| [`cor.test()`](https://rdrr.io/r/stats/cor.test.html) | stats |  | Correlation with a significance test |
| [`count()`](https://dplyr.tidyverse.org/reference/count.html) | dplyr |  | Count rows in each group |
| [`cov()`](https://rdrr.io/r/stats/cor.html) | stats | correlate, covariance | Covariance |
| `coxph()` | survival |  | Cox proportional hazards model |
| [`cross_join()`](https://dplyr.tidyverse.org/reference/cross_join.html) | dplyr |  | Every combination of rows from two tables |
| `crossing()` | tidyr | cross | All combinations, sorted and unique |
| [`cumall()`](https://dplyr.tidyverse.org/reference/cumall.html) | dplyr | sum() | Running all(): TRUE until the first FALSE |
| [`cume_dist()`](https://dplyr.tidyverse.org/reference/percent_rank.html) | dplyr | cumul | Cumulative distribution |
| [`cumprod()`](https://rdrr.io/r/base/cumsum.html) | base | generate | Running product |
| [`cumsum()`](https://rdrr.io/r/base/cumsum.html) | base |  | Running sum |
| [`cur_group()`](https://dplyr.tidyverse.org/reference/context.html) | dplyr | by | Keys of the current group |
| [`cur_group_id()`](https://dplyr.tidyverse.org/reference/context.html) | dplyr |  | Number of the current group |
| [`cut()`](https://socimh.github.io/tidystata/reference/cut.md) | base |  | Cut numbers into intervals |
| [`cut_quantile()`](https://socimh.github.io/tidystata/reference/cut.md) | tidystata | xtile | Alias of xtile() |
| [`data()`](https://rdrr.io/r/utils/data.html) | utils |  | Load a built-in example dataset |
| `datasummary()` | modelsummary | tabstat | Custom summary-statistics tables |
| `datasummary_skim()` | modelsummary | codebook | Quick overview of all variables |
| `day()` | lubridate |  | Day of the month |
| `days()` | lubridate | d + 7 | A period of days, for date arithmetic |
| [`decode()`](https://socimh.github.io/tidystata/reference/type_conversion.md) | tidystata |  | Convert to text, using value labels for labelled data |
| [`dense_rank()`](https://dplyr.tidyverse.org/reference/row_number.html) | dplyr | egen group() | Ranks without gaps |
| [`density()`](https://rdrr.io/r/stats/density.html) | stats | kdensity | Kernel density estimate |
| [`desc()`](https://dplyr.tidyverse.org/reference/desc.html) | dplyr |  | Sort in descending order inside arrange() |
| `describe()` | psych | summarize | Summary statistics (unlike Stata's describe) |
| [`destring()`](https://socimh.github.io/tidystata/reference/type_conversion.md) | tidystata |  | Convert to numbers, dropping value labels |
| [`diag()`](https://rdrr.io/r/base/diag.html) | base |  | Diagonal of a matrix |
| [`diff()`](https://rdrr.io/r/base/diff.html) | base | D. | Differences between neighbouring values |
| [`dim()`](https://rdrr.io/r/base/dim.html) | base | describe | Numbers of rows and columns |
| [`dir()`](https://rdrr.io/r/base/list.files.html) | base |  | List files in a folder |
| [`dir.create()`](https://rdrr.io/r/base/files2.html) | base | mkdir | Create a folder |
| [`distinct()`](https://dplyr.tidyverse.org/reference/distinct.html) | dplyr |  | Keep unique rows |
| `dmy()` | lubridate | date(s, "DMY") | Parse day-month-year text into a date |
| [`dnorm()`](https://rdrr.io/r/stats/Normal.html) | stats | normalden() | Normal density |
| [`do.call()`](https://rdrr.io/r/base/do.call.html) | base | program | Call a function with a list of arguments |
| `drop_na()` | tidyr | drop if missing(x) | Drop rows with missing values |
| [`droplevels()`](https://rdrr.io/r/base/droplevels.html) | base | label define | Drop unused factor levels |
| [`ds()`](https://socimh.github.io/tidystata/reference/names.md) | tidystata |  | List variable names |
| [`ds_as_column()`](https://socimh.github.io/tidystata/reference/names.md) | tidystata | ds | Variable names as a one-column table |
| [`duplicates_drop()`](https://socimh.github.io/tidystata/reference/keys.md) | tidystata |  | Drop duplicated rows, keeping the first |
| [`duplicates_list()`](https://socimh.github.io/tidystata/reference/keys.md) | tidystata |  | List duplicated rows |
| [`duplicates_report()`](https://socimh.github.io/tidystata/reference/keys.md) | tidystata |  | Count duplicated rows |
| [`duplicates_tag()`](https://socimh.github.io/tidystata/reference/keys.md) | tidystata |  | Mark duplicated rows |
| [`ecdf()`](https://rdrr.io/r/stats/ecdf.html) | stats | cumul | Empirical cumulative distribution |
| [`ends_with()`](https://tidyselect.r-lib.org/reference/starts_with.html) | dplyr |  | Select columns whose names end with some text |
| `etable()` | fixest | esttab | Regression table for fixest models |
| [`everything()`](https://tidyselect.r-lib.org/reference/everything.html) | dplyr | \_all | Select all columns |
| `excel_sheets()` | readxl | import excel, describe | Sheet names of an Excel file |
| [`exp()`](https://rdrr.io/r/base/Log.html) | base | exp() | Exponential |
| `expand()` | tidyr | fillin | All combinations of values, dropping other columns |
| `expand_grid()` | tidyr | cross | Table of every combination of given values |
| `fa()` | psych | factor | Factor analysis with more methods |
| `facet_grid()` | ggplot2 | by() | Panels by two variables |
| `facet_wrap()` | ggplot2 |  | One panel per group |
| [`factanal()`](https://rdrr.io/r/stats/factanal.html) | stats |  | Factor analysis |
| [`factor()`](https://rdrr.io/r/base/factor.html) | base |  | Categorical variable with labelled levels |
| `fct_collapse()` | forcats | recode | Combine levels into groups |
| `fct_count()` | forcats | tabulate | Count each level |
| `fct_drop()` | forcats | label define | Drop unused levels |
| `fct_infreq()` | forcats | tabulate x, sort | Order levels by frequency |
| `fct_lump_n()` | forcats | recode | Lump rare levels into Other |
| `fct_na_value_to_level()` | forcats | tabulate x, missing | Make missing values a level |
| `fct_recode()` | forcats | label define, modify | Rename factor levels |
| `fct_relevel()` | forcats | ib3.x | Move factor levels to the front |
| `fct_reorder()` | forcats | graph bar, sort | Order levels by another variable |
| `fct_rev()` | forcats | label define | Reverse the order of levels |
| `feglm()` | fixest | xtlogit | GLM, such as logit, with fixed effects |
| `fenegbin()` | fixest | xtnbreg | Negative binomial model with fixed effects |
| `feols()` | fixest |  | Linear regression with fixed effects, clustering and IV |
| `fepois()` | fixest |  | Poisson regression with fixed effects |
| [`file.exists()`](https://rdrr.io/r/base/files.html) | base | confirm file | Whether a file exists |
| [`file.path()`](https://rdrr.io/r/base/file.path.html) | base | global path | Build a file path |
| `fill()` | tidyr |  | Fill missing values with the previous or next value |
| `fill_gaps()` | tsibble |  | Add rows for missing time points |
| [`filter()`](https://dplyr.tidyverse.org/reference/filter.html) | dplyr |  | Keep rows that meet a condition |
| [`findit()`](https://socimh.github.io/tidystata/reference/findit.md) | tidystata |  | Find the R equivalent of a Stata command |
| [`first()`](https://dplyr.tidyverse.org/reference/nth.html) | dplyr | x\[1\] | First value |
| [`fisher.test()`](https://rdrr.io/r/stats/fisher.test.html) | stats |  | Fisher's exact test |
| `fitstat()` | fixest | estat firststage | Fit statistics, including the first-stage F |
| [`fitted()`](https://rdrr.io/r/stats/fitted.values.html) | stats |  | Fitted values of a model |
| `fixed()` | stringr |  | Match text literally rather than as a regular expression |
| `flextable()` | flextable |  | Formatted table for Word or PowerPoint |
| [`floor()`](https://rdrr.io/r/base/Round.html) | base |  | Round down |
| `floor_date()` | lubridate | mofd() | Round a date down to a unit, such as the month |
| [`format()`](https://rdrr.io/r/base/format.html) | base |  | Format values for display |
| [`formatC()`](https://rdrr.io/r/base/formatc.html) | base | string(x, "%9.2f") | Format numbers with width and padding |
| [`fre()`](https://socimh.github.io/tidystata/reference/tab.md) | tidystata |  | Frequency table with a total row |
| [`fre2()`](https://socimh.github.io/tidystata/reference/tab.md) | tidystata | tabulate | Two-way cross-tabulation with row and column totals |
| `fread()` | data.table | import delimited | Fast reading of large text files |
| [`ftable()`](https://rdrr.io/r/stats/ftable.html) | stats | table | Flat multi-way table |
| [`full_join()`](https://dplyr.tidyverse.org/reference/mutate-joins.html) | dplyr |  | Merge keeping all rows of both tables |
| `full_seq()` | tidyr | tsfill | Complete sequence of values |
| `fwrite()` | data.table | export delimited | Fast writing of large text files |
| `geom_abline()` | ggplot2 | function | Line with a given slope and intercept |
| `geom_area()` | ggplot2 |  | Area plot |
| `geom_bar()` | ggplot2 |  | Bar chart of counts |
| `geom_boxplot()` | ggplot2 |  | Box plot |
| `geom_col()` | ggplot2 | graph bar (asis) | Bars with given heights |
| `geom_density()` | ggplot2 |  | Density curve |
| `geom_errorbar()` | ggplot2 |  | Error bars or capped ranges |
| `geom_histogram()` | ggplot2 |  | Histogram |
| `geom_hline()` | ggplot2 | yline() | Horizontal reference line |
| `geom_jitter()` | ggplot2 | scatter, jitter() | Jittered points |
| `geom_label()` | ggplot2 | mlabel() | Text labels in boxes |
| `geom_line()` | ggplot2 |  | Lines connecting observations |
| `geom_point()` | ggplot2 |  | Points (scatter plot) |
| `geom_pointrange()` | ggplot2 | rcap | Points with intervals |
| `geom_qq()` | ggplot2 |  | Quantile-quantile points |
| `geom_qq_line()` | ggplot2 |  | Reference line for a quantile-quantile plot |
| `geom_ribbon()` | ggplot2 |  | Shaded band between two values |
| `geom_sf()` | ggplot2 | spmap | Map from spatial data |
| `geom_smooth()` | ggplot2 |  | Fitted line or smooth curve |
| `geom_step()` | ggplot2 | line, connect(stairstep) | Step plot |
| `geom_text()` | ggplot2 |  | Text labels on a plot |
| `geom_tile()` | ggplot2 | heatplot | Heat-map tiles |
| `geom_violin()` | ggplot2 |  | Violin plot |
| `geom_vline()` | ggplot2 |  | Vertical reference line |
| `get_dupes()` | janitor | duplicates list | List duplicated rows |
| [`getAnywhere()`](https://rdrr.io/r/utils/getAnywhere.html) | utils |  | Find where a function is defined |
| [`getwd()`](https://rdrr.io/r/base/getwd.html) | base |  | Show the working directory |
| `ggplot()` | ggplot2 |  | Start a plot |
| `ggsave()` | ggplot2 |  | Save a plot to a file |
| `glance()` | broom |  | One-row summary of model statistics |
| [`glimpse()`](https://pillar.r-lib.org/reference/glimpse.html) | dplyr | describe | Compact view of all columns |
| [`glm()`](https://rdrr.io/r/stats/glm.html) | stats |  | Generalised linear model, such as logit or Poisson |
| `glm.nb()` | MASS |  | Negative binomial regression |
| `glmer()` | lme4 |  | Multilevel generalised linear model |
| [`glob2rx()`](https://rdrr.io/r/utils/glob2rx.html) | utils |  | Turn a wildcard pattern into a regular expression |
| [`grepl()`](https://rdrr.io/r/base/grep.html) | base |  | Whether text matches a pattern |
| [`group_by()`](https://dplyr.tidyverse.org/reference/group_by.html) | dplyr |  | Group rows so later steps work within groups |
| [`group_split()`](https://dplyr.tidyverse.org/reference/group_split.html) | dplyr | by | Split a table into one table per group |
| [`group_vars()`](https://dplyr.tidyverse.org/reference/group_data.html) | dplyr | by | Names of the grouping variables |
| [`gsub()`](https://rdrr.io/r/base/grep.html) | base | subinstr() | Replace every match |
| [`head()`](https://rdrr.io/r/utils/head.html) | utils |  | First rows |
| [`help()`](https://rdrr.io/r/utils/help.html) | utils |  | Open a help page |
| [`help.search()`](https://rdrr.io/r/utils/help.search.html) | utils |  | Search all installed help pages |
| `hour()` | lubridate | hh() | Hour of a date-time |
| `hypotheses()` | marginaleffects |  | Tests of linear and nonlinear hypotheses |
| [`if_all()`](https://dplyr.tidyverse.org/reference/across.html) | dplyr | egen rowmin() | Whether a condition holds in all of several columns |
| [`if_any()`](https://dplyr.tidyverse.org/reference/across.html) | dplyr | egen anymatch() | Whether a condition holds in any of several columns |
| [`if_else()`](https://dplyr.tidyverse.org/reference/if_else.html) | dplyr |  | One value if a condition holds, another if not |
| [`ifelse()`](https://rdrr.io/r/base/ifelse.html) | base | cond() | Vectorised if-else (base R) |
| [`inner_join()`](https://dplyr.tidyverse.org/reference/mutate-joins.html) | dplyr |  | Merge keeping only matched rows |
| [`install.packages()`](https://rdrr.io/r/utils/install.packages.html) | utils |  | Install a package from CRAN |
| `install_github()` | remotes |  | Install a package from GitHub |
| [`interaction()`](https://rdrr.io/r/base/interaction.html) | base | egen group() | Combine factors into one |
| [`intersect()`](https://generics.r-lib.org/reference/setops.html) | dplyr | merge, keep(match) | Rows in both tables |
| `interval()` | lubridate |  | Time span between two dates |
| [`IQR()`](https://rdrr.io/r/stats/IQR.html) | stats | egen iqr() | Interquartile range |
| [`is.character()`](https://rdrr.io/r/base/character.html) | base | confirm string variable | Whether a vector holds text |
| [`is.na()`](https://rdrr.io/r/base/NA.html) | base |  | Whether values are missing |
| [`is.numeric()`](https://rdrr.io/r/base/numeric.html) | base | confirm numeric variable | Whether a vector holds numbers |
| [`is_first()`](https://socimh.github.io/tidystata/reference/is_first.md) | tidystata |  | Mark the first row of each group |
| [`isid()`](https://socimh.github.io/tidystata/reference/keys.md) | tidystata |  | Check that variables uniquely identify the rows |
| [`join_by()`](https://dplyr.tidyverse.org/reference/join_by.html) | dplyr | joinby | Join keys, including inequality and range joins |
| [`kmeans()`](https://rdrr.io/r/stats/kmeans.html) | stats |  | K-means clustering |
| [`kruskal.test()`](https://rdrr.io/r/stats/kruskal.test.html) | stats |  | Kruskal-Wallis test |
| [`ks.test()`](https://rdrr.io/r/stats/ks.test.html) | stats |  | Kolmogorov-Smirnov test |
| `labelled()` | haven |  | Attach value labels to a vector |
| `labs()` | ggplot2 | title() | Title and axis labels |
| [`lag()`](https://dplyr.tidyverse.org/reference/lead-lag.html) | dplyr |  | Value from the previous row |
| [`lapply()`](https://rdrr.io/r/base/lapply.html) | base | foreach | Apply a function to each element, returning a list |
| [`last()`](https://dplyr.tidyverse.org/reference/nth.html) | dplyr | x\[\_N\] | Last value |
| [`last_col()`](https://tidyselect.r-lib.org/reference/everything.html) | dplyr | order | The last column |
| [`lead()`](https://dplyr.tidyverse.org/reference/lead-lag.html) | dplyr |  | Value from the next row |
| [`left_join()`](https://dplyr.tidyverse.org/reference/mutate-joins.html) | dplyr |  | Merge keeping all rows of the first table |
| [`length()`](https://rdrr.io/r/base/length.html) | base | count | Number of elements |
| [`levels()`](https://rdrr.io/r/base/levels.html) | base |  | Categories of a factor |
| [`library()`](https://rdrr.io/r/base/library.html) | base | ssc install | Attach a package |
| `linearHypothesis()` | car | test | Test linear restrictions on coefficients |
| [`list()`](https://rdrr.io/r/base/list.html) | base |  | A list of objects |
| [`list.files()`](https://rdrr.io/r/base/list.files.html) | base | dir | Files in a folder |
| `list_rbind()` | purrr | append | Stack a list of data frames |
| [`lm()`](https://rdrr.io/r/stats/lm.html) | stats |  | Linear regression |
| `lmer()` | lme4 |  | Multilevel linear model |
| [`load()`](https://rdrr.io/r/base/load.html) | base | use | Load objects from an .RData file |
| [`log()`](https://rdrr.io/r/base/Log.html) | base |  | Logarithm (natural by default) |
| [`log10()`](https://rdrr.io/r/base/Log.html) | base | log10() | Base-10 logarithm |
| [`logLik()`](https://rdrr.io/r/stats/logLik.html) | stats | e(ll) | Log-likelihood of a model |
| `look_for()` | labelled | lookfor | Find variables by name or label |
| [`lowess()`](https://rdrr.io/r/stats/lowess.html) | stats | lowess | Lowess smoother |
| `lrtest()` | lmtest |  | Likelihood-ratio test |
| [`ls()`](https://rdrr.io/r/base/ls.html) | base |  | List objects in memory |
| [`mad()`](https://rdrr.io/r/stats/mad.html) | stats | egen mad() | Median absolute deviation |
| [`make.names()`](https://rdrr.io/r/base/make.names.html) | base |  | Turn text into valid names |
| `make_date()` | lubridate |  | Date from year, month and day |
| `make_datetime()` | lubridate | mdyhms() | Date-time from its parts |
| `map()` | purrr | foreach | Apply a function to each element, returning a list |
| `map2()` | purrr | forvalues | Apply a function to pairs of elements |
| `map_chr()` | purrr | foreach | Apply a function to each element, returning text |
| `map_dbl()` | purrr | foreach | Apply a function to each element, returning numbers |
| [`matches()`](https://tidyselect.r-lib.org/reference/starts_with.html) | dplyr |  | Select columns whose names match a regular expression |
| `matchit()` | MatchIt |  | Matching for causal inference |
| [`matrix()`](https://rdrr.io/r/base/matrix.html) | base |  | Create a matrix |
| [`max()`](https://rdrr.io/r/base/Extremes.html) | base |  | Largest value |
| [`mcnemar.test()`](https://rdrr.io/r/stats/mcnemar.test.html) | stats | mcc | McNemar test for paired proportions |
| `mdy()` | lubridate | date(s, "MDY") | Parse month-day-year text into a date |
| [`mean()`](https://rdrr.io/r/base/mean.html) | base |  | Mean |
| [`median()`](https://rdrr.io/r/stats/median.html) | stats |  | Median |
| [`merge()`](https://rdrr.io/r/base/merge.html) | base | merge | Merge two data frames (base R) |
| [`message()`](https://rdrr.io/r/base/message.html) | base | display | Print a message |
| `mice()` | mice |  | Multiple imputation by chained equations |
| [`min()`](https://rdrr.io/r/base/Extremes.html) | base |  | Smallest value |
| [`min_rank()`](https://dplyr.tidyverse.org/reference/row_number.html) | dplyr | egen rank(), track | Ranks with ties given the lowest rank |
| `minute()` | lubridate | mm() | Minute of a date-time |
| [`misstable()`](https://socimh.github.io/tidystata/reference/misstable.md) | tidystata |  | Missing values per variable, or missing-value patterns |
| [`model.matrix()`](https://rdrr.io/r/stats/model.matrix.html) | stats | xi | Design matrix with dummy variables |
| `modelplot()` | modelsummary |  | Coefficient plot |
| `modelsummary()` | modelsummary |  | Regression and summary tables |
| `month()` | lubridate |  | Month of a date |
| `multinom()` | nnet |  | Multinomial logit |
| [`mutate()`](https://dplyr.tidyverse.org/reference/mutate.html) | dplyr |  | Create or change columns |
| [`mvdecode()`](https://socimh.github.io/tidystata/reference/na_conversion.md) | tidystata |  | Turn given codes into missing values |
| [`mvencode()`](https://socimh.github.io/tidystata/reference/na_conversion.md) | tidystata |  | Replace missing values with a code |
| [`n()`](https://dplyr.tidyverse.org/reference/context.html) | dplyr |  | Number of rows in the current group |
| [`n_distinct()`](https://dplyr.tidyverse.org/reference/n_distinct.html) | dplyr | distinct | Number of distinct values |
| [`na.omit()`](https://rdrr.io/r/stats/na.fail.html) | stats |  | Drop rows with missing values |
| [`na_if()`](https://dplyr.tidyverse.org/reference/na_if.html) | dplyr |  | Turn one value into missing |
| [`na_if_value()`](https://socimh.github.io/tidystata/reference/na_conversion.md) | tidystata | mvdecode | Alias of mvdecode() |
| [`names()`](https://socimh.github.io/tidystata/reference/names.md) | base |  | Names of an object, such as column names |
| [`names_as_column()`](https://socimh.github.io/tidystata/reference/names.md) | tidystata | ds | Alias of ds_as_column() |
| [`nchar()`](https://rdrr.io/r/base/nchar.html) | base | strlen() | Number of characters |
| [`ncol()`](https://rdrr.io/r/base/nrow.html) | base | describe | Number of columns |
| [`near()`](https://dplyr.tidyverse.org/reference/near.html) | dplyr | reldif() | Compare numbers with a tolerance |
| `nest()` | tidyr | by | Nest rows into list-columns, one row per group |
| [`nlevels()`](https://rdrr.io/r/base/nlevels.html) | base | levelsof | Number of factor levels |
| [`nls()`](https://rdrr.io/r/stats/nls.html) | stats | nl | Nonlinear least squares |
| [`nobs()`](https://rdrr.io/r/stats/nobs.html) | stats | e(N) | Number of observations used by a model |
| `now()` | lubridate | now() | Current date and time |
| [`nrow()`](https://rdrr.io/r/base/nrow.html) | base |  | Number of rows |
| [`nth()`](https://dplyr.tidyverse.org/reference/nth.html) | dplyr | x\[5\] | Value at a given position |
| [`ntile()`](https://dplyr.tidyverse.org/reference/ntile.html) | dplyr | xtile | Split into n groups of nearly equal size |
| [`num_range()`](https://tidyselect.r-lib.org/reference/starts_with.html) | dplyr | keep x1-x5 | Select x1, x2 and so on by number |
| `oaxaca()` | oaxaca |  | Blinder-Oaxaca decomposition |
| [`optim()`](https://rdrr.io/r/stats/optim.html) | stats | ml | General-purpose optimisation |
| [`options()`](https://rdrr.io/r/base/options.html) | base | set | Set global options |
| [`order()`](https://rdrr.io/r/base/order.html) | base | sort | Positions that would sort a vector |
| [`p.adjust()`](https://rdrr.io/r/stats/p.adjust.html) | stats | test, mtest | Adjust p-values for multiple tests |
| [`pairs()`](https://rdrr.io/r/graphics/pairs.html) | graphics |  | Scatter-plot matrix |
| [`pairwise.t.test()`](https://rdrr.io/r/stats/pairwise.t.test.html) | stats | pwmean | Pairwise t tests with adjusted p-values |
| `parse_number()` | readr | destring, ignore() | Extract a number from text such as \$1,200 |
| [`paste()`](https://rdrr.io/r/base/paste.html) | base |  | Join text with a separator |
| [`paste0()`](https://rdrr.io/r/base/paste.html) | base |  | Join text without a separator |
| [`pc()`](https://socimh.github.io/tidystata/reference/std.md) | tidystata |  | Percentage of the total |
| [`pchisq()`](https://rdrr.io/r/stats/Chisquare.html) | stats | chi2tail() | Chi-square probability |
| [`pct()`](https://socimh.github.io/tidystata/reference/std.md) | tidystata | egen pc() | Alias of pc() |
| `pdata.frame()` | plm | xtset | Declare panel data for plm |
| [`percent_rank()`](https://dplyr.tidyverse.org/reference/percent_rank.html) | dplyr | egen rank() | Rank rescaled to 0-1 |
| `pgmm()` | plm |  | Dynamic panel GMM (Arellano-Bond) |
| `phtest()` | plm | hausman | Hausman test |
| [`pick()`](https://dplyr.tidyverse.org/reference/pick.html) | dplyr | varlist | Select columns inside mutate() or summarise() |
| `pivot_longer()` | tidyr |  | Reshape from wide to long |
| `pivot_wider()` | tidyr |  | Reshape from long to wide |
| `plm()` | plm |  | Panel models: fixed and random effects |
| [`plot()`](https://rdrr.io/r/graphics/plot.default.html) | base |  | Basic plot |
| `plot_predictions()` | marginaleffects |  | Plot predictions, like marginsplot |
| `plot_slopes()` | marginaleffects | marginsplot | Plot marginal effects |
| [`pmax()`](https://rdrr.io/r/base/Extremes.html) | base | max(a, b) | Element-wise maximum of several vectors |
| [`pmin()`](https://rdrr.io/r/base/Extremes.html) | base | min(a, b) | Element-wise minimum of several vectors |
| [`pnorm()`](https://rdrr.io/r/stats/Normal.html) | stats | normal() | Normal cumulative probability |
| `polr()` | MASS |  | Ordered logit or probit |
| [`poly()`](https://rdrr.io/r/stats/poly.html) | stats |  | Polynomial terms for a model |
| `pool()` | mice |  | Combine results across imputations |
| `position_dodge()` | ggplot2 | over() | Place bars or points side by side |
| `possibly()` | purrr | capture | Return a default value instead of an error |
| [`power.t.test()`](https://rdrr.io/r/stats/power.t.test.html) | stats | power twomeans | Power and sample size for a t test |
| [`prcomp()`](https://rdrr.io/r/stats/prcomp.html) | stats |  | Principal components |
| [`predict()`](https://rdrr.io/r/stats/predict.html) | stats |  | Predictions from a model |
| `predictions()` | marginaleffects | margins | Predictions with standard errors |
| [`print()`](https://rdrr.io/r/base/print.html) | base |  | Print an object |
| [`print_all()`](https://socimh.github.io/tidystata/reference/special-print.md) | tidystata |  | Print every row and column |
| `print_labels()` | haven | label list | Show value labels |
| [`prop.table()`](https://rdrr.io/r/base/proportions.html) | base |  | Turn counts into proportions |
| [`prop.test()`](https://rdrr.io/r/stats/prop.test.html) | stats |  | Test of a proportion |
| [`proportions()`](https://rdrr.io/r/base/proportions.html) | base | tabulate, row | Turn a table into proportions |
| [`pt()`](https://rdrr.io/r/stats/TDist.html) | stats | ttail() | t-distribution probability |
| [`pull()`](https://dplyr.tidyverse.org/reference/pull.html) | dplyr |  | Extract one column as a vector |
| [`pwcorr()`](https://socimh.github.io/tidystata/reference/pwcorr.md) | tidystata |  | Pairwise correlations with counts and p-values |
| [`qnorm()`](https://rdrr.io/r/stats/Normal.html) | stats | invnormal() | Normal quantile |
| [`quantile()`](https://rdrr.io/r/stats/quantile.html) | stats |  | Quantiles |
| `quarter()` | lubridate | quarter() | Quarter of a date |
| [`quasibinomial()`](https://rdrr.io/r/stats/family.html) | stats |  | Binomial family that allows survey weights |
| `ranef()` | lme4 | predict, reffects | Predicted random effects |
| [`range()`](https://rdrr.io/r/base/range.html) | base | summarize | Minimum and maximum |
| [`rank()`](https://rdrr.io/r/base/rank.html) | base |  | Ranks, with ties averaged |
| [`rbind()`](https://rdrr.io/r/base/cbind.html) | base | append | Stack rows (base R) |
| [`rbinom()`](https://rdrr.io/r/stats/Binomial.html) | stats | rbinomial() | Binomial random numbers |
| `rdrobust()` | rdrobust |  | Regression discontinuity |
| [`read.csv()`](https://rdrr.io/r/utils/read.table.html) | utils | import delimited | Read a CSV file (base R) |
| `read_csv()` | readr |  | Read a CSV file |
| `read_delim()` | readr | import delimited | Read a file with any delimiter |
| `read_dta()` | haven |  | Read a Stata .dta file |
| `read_excel()` | readxl |  | Read an Excel sheet |
| `read_sas()` | haven |  | Read a SAS file |
| `read_sav()` | haven |  | Read an SPSS .sav file |
| `read_tsv()` | readr | import delimited | Read a tab-separated file |
| [`readRDS()`](https://rdrr.io/r/base/readRDS.html) | base | use | Read an R object file (.rds) |
| `reduce()` | purrr | merge | Combine elements one after another, such as repeated merges |
| [`reframe()`](https://dplyr.tidyverse.org/reference/reframe.html) | dplyr | collapse | Summarise to any number of rows per group |
| `regex()` | stringr |  | Regular expression with options such as ignore_case |
| [`relevel()`](https://rdrr.io/r/stats/relevel.html) | stats |  | Choose the base category of a factor |
| [`relocate()`](https://dplyr.tidyverse.org/reference/relocate.html) | dplyr |  | Move columns to a new position |
| `remove_empty()` | janitor | missings dropvars | Drop empty rows and columns |
| [`rename()`](https://dplyr.tidyverse.org/reference/rename.html) | dplyr |  | Rename columns (new = old) |
| [`rename_with()`](https://dplyr.tidyverse.org/reference/rename.html) | dplyr |  | Rename columns with a function, such as toupper |
| [`rep()`](https://rdrr.io/r/base/rep.html) | base | expand | Repeat values |
| [`rep_len()`](https://rdrr.io/r/base/rep.html) | base |  | Repeat values to a given length |
| `replace_na()` | tidyr | replace x = 0 if missing(x) | Replace missing values |
| `resettest()` | lmtest |  | RESET test for omitted variables |
| [`residuals()`](https://rdrr.io/r/stats/residuals.html) | stats | predict, residuals | Model residuals |
| [`rev()`](https://rdrr.io/r/base/rev.html) | base | gsort | Reverse the order |
| [`right_join()`](https://dplyr.tidyverse.org/reference/mutate-joins.html) | dplyr |  | Merge keeping all rows of the second table |
| `rlm()` | MASS |  | Robust regression |
| [`rm()`](https://rdrr.io/r/base/rm.html) | base |  | Remove objects from memory |
| [`rnorm()`](https://rdrr.io/r/stats/Normal.html) | stats |  | Normal random numbers |
| [`round()`](https://rdrr.io/r/base/Round.html) | base |  | Round to a number of decimals |
| [`row_max()`](https://socimh.github.io/tidystata/reference/row_egen.md) | tidystata |  | Maximum across variables in each row |
| [`row_mean()`](https://socimh.github.io/tidystata/reference/row_egen.md) | tidystata |  | Mean across variables in each row |
| [`row_median()`](https://socimh.github.io/tidystata/reference/row_egen.md) | tidystata |  | Median across variables in each row |
| [`row_min()`](https://socimh.github.io/tidystata/reference/row_egen.md) | tidystata |  | Minimum across variables in each row |
| [`row_miss()`](https://socimh.github.io/tidystata/reference/row_egen.md) | tidystata |  | Number of missing values in each row |
| [`row_non_miss()`](https://socimh.github.io/tidystata/reference/row_egen.md) | tidystata |  | Number of observed values in each row |
| [`row_number()`](https://dplyr.tidyverse.org/reference/row_number.html) | dplyr |  | Row number |
| [`row_nvals()`](https://socimh.github.io/tidystata/reference/row_egen.md) | tidystata |  | Number of distinct values in each row, ignoring missing values |
| [`row_sd()`](https://socimh.github.io/tidystata/reference/row_egen.md) | tidystata |  | Standard deviation across variables in each row |
| [`row_sum()`](https://socimh.github.io/tidystata/reference/row_egen.md) | tidystata |  | Sum across variables in each row |
| [`row_unique()`](https://socimh.github.io/tidystata/reference/row_egen.md) | tidystata | egen rownvals() | Number of distinct values in each row, counting missing as one |
| `rownames_to_column()` | tibble | xpose | Turn row names into a column |
| [`rows_update()`](https://dplyr.tidyverse.org/reference/rows.html) | dplyr | merge, update replace | Update rows from another table |
| [`rowSums()`](https://rdrr.io/r/base/colSums.html) | base |  | Sum across columns in each row |
| [`rowwise()`](https://dplyr.tidyverse.org/reference/rowwise.html) | dplyr | egen rowmean() | Compute row by row |
| `rq()` | quantreg |  | Quantile regression |
| [`runif()`](https://rdrr.io/r/stats/Uniform.html) | stats |  | Uniform random numbers |
| [`s_diff()`](https://socimh.github.io/tidystata/reference/panel.md) | tidystata |  | Difference from the previous period, respecting time gaps |
| [`s_lag()`](https://socimh.github.io/tidystata/reference/panel.md) | tidystata |  | Value from an earlier period, respecting time gaps |
| [`s_lead()`](https://socimh.github.io/tidystata/reference/panel.md) | tidystata |  | Value from a later period, respecting time gaps |
| [`s_merge()`](https://socimh.github.io/tidystata/reference/s_merge.md) | tidystata |  | Merge two tables and report matches, like Stata's merge |
| [`s_print()`](https://socimh.github.io/tidystata/reference/special-print.md) | tidystata | list | Print the first and last rows, evenly spaced rows or all rows |
| [`s_tag()`](https://socimh.github.io/tidystata/reference/is_first.md) | tidystata | egen tag() | Alias of is_first() |
| [`s_try()`](https://socimh.github.io/tidystata/reference/capture.md) | tidystata | capture | Alias of capture() |
| [`sample()`](https://rdrr.io/r/base/sample.html) | base | sample | Random sample of values |
| [`sapply()`](https://rdrr.io/r/base/lapply.html) | base | foreach | Apply a function to each element and simplify |
| [`save()`](https://rdrr.io/r/base/save.html) | base | save | Save objects to an .RData file |
| `save_as_docx()` | flextable |  | Save tables to a Word file |
| [`saveRDS()`](https://rdrr.io/r/base/readRDS.html) | base |  | Save one R object to a file |
| [`scale()`](https://rdrr.io/r/base/scale.html) | base | egen std() | Standardise columns |
| `scale_colour_manual()` | ggplot2 | mcolor() | Choose colours by hand |
| `scale_fill_brewer()` | ggplot2 | set scheme | ColorBrewer fill colours |
| `scale_x_continuous()` | ggplot2 | xlabel() | Axis breaks and labels |
| `scale_x_log10()` | ggplot2 | xscale(log) | Logarithmic x axis |
| [`sd()`](https://rdrr.io/r/stats/sd.html) | stats |  | Standard deviation |
| [`select()`](https://dplyr.tidyverse.org/reference/select.html) | dplyr |  | Keep or drop columns |
| `selection()` | sampleSelection |  | Heckman sample-selection model |
| `sem()` | lavaan |  | Structural equation model |
| [`semi_join()`](https://dplyr.tidyverse.org/reference/filter-joins.html) | dplyr |  | Keep rows of the first table that have a match in the second |
| `separate_longer_delim()` | tidyr | split | Split text into rows |
| `separate_wider_delim()` | tidyr |  | Split one text column into several |
| `separate_wider_position()` | tidyr | substr() | Split text into columns by position |
| [`seq()`](https://rdrr.io/r/base/seq.html) | base |  | Sequence of numbers |
| [`seq_along()`](https://rdrr.io/r/base/seq.html) | base | \_n | Positions of the elements of a vector |
| [`seq_len()`](https://rdrr.io/r/base/seq.html) | base | \_n | Whole numbers from 1 to n |
| [`set.seed()`](https://rdrr.io/r/base/Random.html) | base |  | Make random numbers reproducible |
| [`set_seed()`](https://socimh.github.io/tidystata/reference/set_seed.md) | tidystata |  | Set the random seed, alone or at the end of a pipe |
| `set_variable_labels()` | labelled |  | Set variable labels |
| [`setdiff()`](https://generics.r-lib.org/reference/setops.html) | dplyr | merge, keep(master) | Rows in the first table only |
| [`setwd()`](https://rdrr.io/r/base/getwd.html) | base |  | Change the working directory |
| [`shapiro.test()`](https://rdrr.io/r/stats/shapiro.test.html) | stats |  | Shapiro-Wilk normality test |
| [`signif()`](https://rdrr.io/r/base/Round.html) | base | round() | Round to significant digits |
| [`sink()`](https://rdrr.io/r/base/sink.html) | base |  | Send console output to a file |
| [`slice()`](https://dplyr.tidyverse.org/reference/slice.html) | dplyr |  | Keep rows by position |
| [`slice_head()`](https://dplyr.tidyverse.org/reference/slice.html) | dplyr | bysort g: keep if \_n \<= 3 | First rows of each group |
| [`slice_max()`](https://dplyr.tidyverse.org/reference/slice.html) | dplyr | gsort -x; keep in 1/5 | Rows with the largest values |
| [`slice_min()`](https://dplyr.tidyverse.org/reference/slice.html) | dplyr | sort x; keep in 1/5 | Rows with the smallest values |
| [`slice_sample()`](https://dplyr.tidyverse.org/reference/slice.html) | dplyr |  | Random sample of rows |
| [`slice_tail()`](https://dplyr.tidyverse.org/reference/slice.html) | dplyr | bysort g: keep if \_n \> \_N - 3 | Last rows of each group |
| `slopes()` | marginaleffects | margins, dydx(x) at() | Marginal effects for each observation |
| [`sort()`](https://rdrr.io/r/base/sort.html) | base |  | Sort a vector |
| [`source()`](https://rdrr.io/r/base/source.html) | base |  | Run an R script |
| [`split()`](https://rdrr.io/r/base/split.html) | base | by | Split data into groups |
| [`sprintf()`](https://rdrr.io/r/base/sprintf.html) | base |  | Format numbers and text with a template |
| [`sqrt()`](https://rdrr.io/r/base/MathFun.html) | base |  | Square root |
| [`starts_with()`](https://tidyselect.r-lib.org/reference/starts_with.html) | dplyr |  | Select columns whose names start with some text |
| `stat_ecdf()` | ggplot2 | cumul | Empirical cumulative distribution plot |
| `stat_summary()` | ggplot2 |  | Plot a summary, such as the mean, of y at each x |
| [`std()`](https://socimh.github.io/tidystata/reference/std.md) | tidystata |  | Standardise to mean 0 and standard deviation 1 |
| [`stem()`](https://rdrr.io/r/graphics/stem.html) | graphics |  | Stem-and-leaf display |
| [`step()`](https://rdrr.io/r/stats/step.html) | stats | stepwise | Stepwise model selection |
| [`stop()`](https://rdrr.io/r/base/stop.html) | base | exit 198 | Stop with an error |
| [`stopifnot()`](https://rdrr.io/r/base/stopifnot.html) | base |  | Stop if a condition is not TRUE |
| [`str()`](https://rdrr.io/r/utils/str.html) | utils |  | Compact view of an object's structure |
| `str_c()` | stringr | generate s = a + b | Join strings |
| `str_count()` | stringr |  | Count matches in a string |
| `str_detect()` | stringr |  | Whether a string contains a pattern |
| `str_dup()` | stringr | "-" \* 10 | Repeat a string |
| `str_ends()` | stringr | substr() | Whether a string ends with a pattern |
| `str_extract()` | stringr |  | Extract the matching text |
| `str_extract_all()` | stringr | ustrregexs() | Extract every match |
| `str_flatten()` | stringr | levelsof, separate() | Collapse a vector into one string |
| `str_glue()` | stringr | display "\`x'" | Fill a text template |
| `str_length()` | stringr |  | Number of characters |
| `str_locate()` | stringr | strpos() | Position of a match |
| `str_match()` | stringr | regexs() | Extract the groups of a regular expression |
| `str_pad()` | stringr | string(x, "%05.0f") | Pad a string to a fixed width |
| `str_remove()` | stringr | subinstr() | Remove the first match |
| `str_remove_all()` | stringr | subinstr() | Remove every match |
| `str_replace()` | stringr |  | Replace the first match |
| `str_replace_all()` | stringr |  | Replace every match |
| `str_split()` | stringr | split | Split strings into pieces |
| `str_squish()` | stringr |  | Trim spaces and collapse repeated spaces |
| `str_starts()` | stringr | substr() | Whether a string starts with a pattern |
| `str_sub()` | stringr |  | Part of a string by position |
| `str_subset()` | stringr | keep if regexm() | Keep the strings that match |
| `str_to_lower()` | stringr |  | Lower case |
| `str_to_sentence()` | stringr | strproper() | Sentence case |
| `str_to_title()` | stringr |  | Title case |
| `str_to_upper()` | stringr |  | Upper case |
| `str_trim()` | stringr |  | Remove leading and trailing spaces |
| `str_trunc()` | stringr | abbrev() | Shorten strings to a width |
| `str_wrap()` | stringr | display | Wrap text into lines |
| `strata()` | survival |  | Stratum term in a survival model formula |
| [`strsplit()`](https://rdrr.io/r/base/strsplit.html) | base | split | Split strings |
| [`sub()`](https://rdrr.io/r/base/grep.html) | base | regexr() | Replace the first match |
| [`subset()`](https://rdrr.io/r/base/subset.html) | base | keep if | Rows meeting a condition (base R) |
| [`substr()`](https://rdrr.io/r/base/substr.html) | base | substr() | Part of a string by position |
| [`sum()`](https://rdrr.io/r/base/sum.html) | base |  | Sum |
| [`summ()`](https://socimh.github.io/tidystata/reference/summ.md) | tidystata |  | Summary statistics for variables |
| [`summarise()`](https://dplyr.tidyverse.org/reference/summarise.html) | dplyr |  | Reduce each group to one row of statistics |
| [`summarize()`](https://dplyr.tidyverse.org/reference/summarise.html) | dplyr | collapse | Same as summarise() |
| [`summary()`](https://rdrr.io/r/base/summary.html) | base |  | Summary of an object, such as a model |
| `Surv()` | survival |  | Survival-time outcome for a model |
| `survdiff()` | survival |  | Log-rank test |
| `survey_mean()` | srvyr |  | Survey-weighted mean |
| `survey_prop()` | srvyr |  | Survey-weighted proportion |
| `survey_quantile()` | srvyr | epctile | Survey-weighted quantiles |
| `survey_total()` | srvyr | svy: total | Survey-weighted total |
| `survfit()` | survival |  | Kaplan-Meier survival curves |
| `survreg()` | survival |  | Parametric survival model |
| `svydesign()` | survey | svyset | Declare a survey design (survey package) |
| `svyglm()` | survey |  | Survey-weighted regression |
| `svymean()` | survey | svy: mean | Survey-weighted mean (survey package) |
| `svytable()` | survey | svy: tabulate | Survey-weighted table |
| `synth()` | Synth |  | Synthetic control |
| [`Sys.Date()`](https://rdrr.io/r/base/Sys.time.html) | base |  | Today's date |
| [`Sys.time()`](https://rdrr.io/r/base/Sys.time.html) | base | c(current_time) | Current date and time |
| [`t()`](https://rdrr.io/r/base/t.html) | base |  | Transpose a matrix |
| [`t.test()`](https://rdrr.io/r/stats/t.test.html) | stats |  | t test and confidence interval of a mean |
| [`tab()`](https://socimh.github.io/tidystata/reference/tab.md) | tidystata |  | Frequency table |
| [`tab1()`](https://socimh.github.io/tidystata/reference/tab.md) | tidystata |  | One frequency table per variable |
| [`tab2()`](https://socimh.github.io/tidystata/reference/tab.md) | tidystata |  | Two-way cross-tabulation, or every pairwise table |
| [`tab_gen()`](https://socimh.github.io/tidystata/reference/as_dummy.md) | tidystata | tabulate, generate() | Alias of as_dummy() |
| [`table()`](https://rdrr.io/r/base/table.html) | base |  | Count values |
| [`tabstat()`](https://socimh.github.io/tidystata/reference/summ.md) | tidystata |  | Chosen statistics for variables, optionally by group |
| `tabyl()` | janitor | tabulate | Frequency and cross tables |
| `tagged_na()` | haven | replace x = .a | Stata-style extended missing values such as .a |
| [`tail()`](https://rdrr.io/r/utils/head.html) | utils |  | Last rows |
| [`tally()`](https://dplyr.tidyverse.org/reference/count.html) | dplyr | count | Count rows |
| [`tapply()`](https://rdrr.io/r/base/tapply.html) | base | bysort g: egen | Apply a function within groups |
| `tbl_cross()` | gtsummary | tabulate x1 x2 | Cross table |
| `tbl_regression()` | gtsummary | esttab | Regression table |
| `tbl_summary()` | gtsummary |  | Descriptive Table 1 |
| [`tempfile()`](https://rdrr.io/r/base/tempfile.html) | base |  | Name for a temporary file |
| `theme()` | ggplot2 | graphregion() | Fine-tune the look of a plot |
| `theme_bw()` | ggplot2 |  | Black-and-white plot theme |
| `theme_classic()` | ggplot2 | set scheme | Classic plot theme |
| `theme_minimal()` | ggplot2 | set scheme | Minimal plot theme |
| `theme_set()` | ggplot2 |  | Set the default theme for every plot |
| [`tibble()`](https://tibble.tidyverse.org/reference/tibble.html) | tibble |  | Create a data frame (tibble) |
| `tidy()` | broom |  | Coefficient table as a data frame |
| `time_length()` | lubridate |  | Length of a time span in chosen units, such as years |
| [`timer()`](https://socimh.github.io/tidystata/reference/timer.md) | tidystata |  | Time how long code takes |
| `to_factor()` | labelled | decode | Turn labelled values into a factor |
| `tobit()` | AER |  | Tobit (censored) regression |
| `today()` | lubridate | today() | Today's date |
| [`tolower()`](https://rdrr.io/r/base/chartr.html) | base | strlower() | Lower case |
| [`tostring()`](https://socimh.github.io/tidystata/reference/type_conversion.md) | tidystata |  | Convert to text, keeping codes rather than value labels |
| [`toupper()`](https://rdrr.io/r/base/chartr.html) | base | strupper() | Upper case |
| [`traceback()`](https://rdrr.io/r/base/traceback.html) | base |  | Show where the last error happened |
| [`transmute()`](https://dplyr.tidyverse.org/reference/transmute.html) | dplyr | keep | Create columns and keep only those |
| [`tribble()`](https://tibble.tidyverse.org/reference/tribble.html) | tibble | input | Type a small table row by row |
| [`trimws()`](https://rdrr.io/r/base/trimws.html) | base | strtrim() | Remove leading and trailing spaces |
| [`trunc()`](https://rdrr.io/r/base/Round.html) | base | int() | Drop the decimals |
| [`try()`](https://rdrr.io/r/base/try.html) | base | capture | Run code and continue after an error |
| [`tryCatch()`](https://rdrr.io/r/base/conditions.html) | base | capture | Handle errors and warnings |
| [`ts()`](https://rdrr.io/r/stats/ts.html) | stats | tsset | Time-series object |
| [`TukeyHSD()`](https://rdrr.io/r/stats/TukeyHSD.html) | stats | pwcompare, mcompare(tukey) | Tukey multiple comparisons |
| [`typeof()`](https://rdrr.io/r/base/typeof.html) | base | describe | Storage type |
| `uncount()` | tidyr |  | Repeat each row a given number of times |
| [`ungroup()`](https://dplyr.tidyverse.org/reference/group_by.html) | dplyr |  | Remove grouping |
| [`union()`](https://generics.r-lib.org/reference/setops.html) | dplyr | append | Rows in either table, without duplicates |
| [`unique()`](https://rdrr.io/r/base/unique.html) | base |  | Distinct values |
| `unite()` | tidyr | egen concat() | Join columns into one |
| `unnest()` | tidyr | expand | Expand list-columns back into rows |
| [`update()`](https://rdrr.io/r/stats/update.html) | stats | regress | Refit a model with changes |
| [`update.packages()`](https://rdrr.io/r/utils/update.packages.html) | utils |  | Update installed packages |
| `val_labels()` | labelled | label values | Get or set value labels |
| [`value_if_na()`](https://socimh.github.io/tidystata/reference/na_conversion.md) | tidystata | mvencode | Alias of mvencode() |
| [`var()`](https://rdrr.io/r/stats/cor.html) | stats | summarize, detail | Variance |
| [`var.test()`](https://rdrr.io/r/stats/var.test.html) | stats | sdtest | F test of equal variances |
| `var_label()` | labelled | label variable | Get or set a variable label |
| `VarCorr()` | lme4 | estat sd | Variance components of a multilevel model |
| [`variables()`](https://socimh.github.io/tidystata/reference/variables.md) | tidystata |  | List variables with their types and labels |
| [`variables_search()`](https://socimh.github.io/tidystata/reference/variables.md) | tidystata |  | Find variables by name or label |
| [`varlist()`](https://socimh.github.io/tidystata/reference/varlist.md) | tidystata |  | Select variables with Stata wildcards such as x\* |
| [`vcov()`](https://rdrr.io/r/stats/vcov.html) | stats |  | Variance-covariance matrix of a model |
| `vcovBS()` | sandwich |  | Bootstrap variance matrix |
| `vcovCL()` | sandwich | vce(cluster id) | Clustered variance matrix |
| `vcovHC()` | sandwich | vce(robust) | Heteroskedasticity-robust variance matrix |
| `vcovJK()` | sandwich |  | Jackknife variance matrix |
| [`View()`](https://rdrr.io/r/utils/View.html) | utils | browse | Open the data viewer |
| `vif()` | car |  | Variance inflation factors |
| `waldtest()` | lmtest | test | Wald test of nested models |
| `walk()` | purrr | foreach | Apply a function for its side effects, such as saving files |
| [`warning()`](https://rdrr.io/r/base/warning.html) | base | display as error | Give a warning |
| `wday()` | lubridate |  | Day of the week |
| `week()` | lubridate | week() | Week of the year |
| [`weighted.mean()`](https://rdrr.io/r/stats/weighted.mean.html) | stats | summarize \[aweight = w\] | Weighted mean |
| `weightit()` | WeightIt |  | Balancing weights, such as inverse-probability weights |
| [`where()`](https://tidyselect.r-lib.org/reference/where.html) | dplyr | ds, has(type numeric) | Select columns by type, such as where(is.numeric) |
| [`which()`](https://rdrr.io/r/base/which.html) | base | list if | Positions where a condition is TRUE |
| [`wilcox.test()`](https://rdrr.io/r/stats/wilcox.test.html) | stats |  | Wilcoxon rank-sum or signed-rank test |
| `winsorize()` | datawizard |  | Winsorise extreme values |
| [`with()`](https://rdrr.io/r/base/with.html) | base |  | Evaluate code with the columns of a data frame |
| `word()` | stringr |  | Extract words from a sentence |
| `wrap_plots()` | patchwork |  | Combine several plots |
| [`write.csv()`](https://rdrr.io/r/utils/write.table.html) | utils | export delimited | Write a CSV file (base R) |
| `write_csv()` | readr |  | Write a CSV file |
| `write_dta()` | haven |  | Write a Stata .dta file |
| `write_sav()` | haven | savespss | Write an SPSS file |
| `write_xlsx()` | writexl |  | Write an Excel file |
| `xlim()` | ggplot2 | xscale(range()) | Limits of the x axis |
| [`xtab()`](https://socimh.github.io/tidystata/reference/tab.md) | tidystata | tabulate | Alias of tab2() |
| [`xtabs()`](https://rdrr.io/r/stats/xtabs.html) | stats | tabulate x1 x2 | Cross-tabulation from a formula |
| [`xtile()`](https://socimh.github.io/tidystata/reference/cut.md) | tidystata |  | Quantile groups, following Stata's xtile |
| `yday()` | lubridate | doy() | Day of the year |
| `year()` | lubridate |  | Year of a date |
| `yearmonth()` | tsibble |  | Monthly period |
| `yearquarter()` | tsibble |  | Quarterly period |
| `years()` | lubridate | d + 365 | A period of years, for date arithmetic |
| `ymd()` | lubridate |  | Parse text such as 2024-01-31 into a date |
| `ymd_hms()` | lubridate |  | Parse text into a date-time |
| `zap_labels()` | haven |  | Remove value labels |
| `zap_missing()` | haven | mvdecode | Turn special missing values into NA |
