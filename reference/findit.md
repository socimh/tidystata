# Find the R equivalent of a Stata command

`findit()` looks up a Stata command and returns the R code that does the
same job, whether a tidystata function or one from another package. It
covers everyday data work (browsing, tabulating, generating, merging,
reshaping) and points to the packages tidystata leaves to others, such
as fixest for `reghdfe`, modelsummary for `esttab`, binsreg for
`binscatter` and srvyr for `svy`.

It also works the other way round: give it an R function, such as
`findit(left_join)`, and it describes the function and lists the Stata
commands it replaces. Beginners need not know which is which; a word
that is both, such as `log` or `round`, shows both meanings.

Type a single word bare, as in `findit(reg)`, or quote anything longer,
as in `findit("merge 1:1 id, keep(match)")`. Call `findit()` with no
argument for the whole list.

## Usage

``` r
findit(command = NULL)
```

## Arguments

- command:

  A Stata command or an R function name, either one bare word
  (`findit(tab)`, `findit(left_join)`) or a quoted string
  (`findit("bysort g: egen m = mean(x)")`). R functions may also be
  written as [`lm()`](https://rdrr.io/r/stats/lm.html) or
  [`dplyr::left_join`](https://dplyr.tidyverse.org/reference/mutate-joins.html).
  Use `!!` to look up a string stored in a variable: `findit(!!cmd)`.
  `NULL` (default) returns every entry.

## Value

A tibble with one row per Stata idiom and the columns `match` (`"stata"`
when the word is a Stata command, `"r"` when it is an R function used in
the entry, `"keyword"` for a text match, `"all"` for the whole list),
`stata` (the Stata code), `r` (equivalent R code), `package` (where the
R function lives) and `task` (what it does). It prints each entry as the
Stata code and task on one line, followed by the R code, so the code is
never cut off; the first `n` entries are shown
(`print(findit(), n = Inf)` for all). A matched R function is printed
with a one-line description. If nothing matches, a message suggests
similar names and an empty tibble is returned invisibly.

## Details

Matching follows fixed rules, without any guessing:

- The first word is looked up both as a Stata command and as an R
  function. Stata's minimum abbreviations work: `reg`, `regr` and
  `regress` all find `regress`; `su` and `sum` find `summarize`; `ta`
  and `tab` find `tabulate`. R functions must be named in full (`lm`
  finds [`lm()`](https://rdrr.io/r/stats/lm.html) but not
  [`glm()`](https://rdrr.io/r/stats/glm.html)); upper and lower case are
  ignored only when no exact name matches.

- Entries found as a Stata command come first. Entries found only
  through the R function follow, under a description of that function.
  About 600 R functions are described, including many that no entry uses
  yet, such as
  [`n_distinct()`](https://dplyr.tidyverse.org/reference/n_distinct.html)
  or `fct_relevel()`; for those, `findit()` prints the description and
  the related Stata command.

- A leading `by ...:` or `bysort ...:` prefix is set aside, so
  `findit("bys g: sum x")` looks up `summarize` and lists the grouped
  entries first.

- The remaining words put the best-matching entries first. For example,
  `findit("merge keep(match)")` lists
  [`inner_join()`](https://dplyr.tidyverse.org/reference/mutate-joins.html)
  before the other merge entries, and `findit("mutate egen")` lists the
  `egen` entries among the many that use
  [`mutate()`](https://dplyr.tidyverse.org/reference/mutate.html). All
  matching entries are still returned.

- If neither matches, the text is searched for in the Stata code, the R
  code and the task, so `findit(winsor)` and `findit(dummy)` also work.

R reads a call before `findit()` runs, so anything that is not a single
R name must be quoted: several words (`"merge 1:1 id"`), reserved words
(`"if"`), and names starting with an underscore (`"_n"`).

The list is curated rather than exhaustive. Longer explanations, in
English and Chinese, are in the "Coming from Stata" articles on the
package website.

tidystata and statar can be attached together; only
[`tab()`](https://socimh.github.io/tidystata/reference/tab.md) and
[`xtile()`](https://socimh.github.io/tidystata/reference/cut.md) share
names. Attach tidystata last, or write
[`tidystata::tab()`](https://socimh.github.io/tidystata/reference/tab.md).

## Examples

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
findit(su)
#> # Stata to R: 5 entries
#> 
#> summarize                  # Summary statistics for all variables [tidystata]
#>   summ(data)
#> summarize x                # Summary statistics for one variable [tidystata]
#>   summ(data, x)
#> summarize x, detail        # Detailed statistics, including percentiles [tidystata]
#>   summ(data, x, .detail = TRUE)
#> bysort group: summarize x  # Summary statistics by group [tidystata]
#>   summ(data, x, .by = group)
#> summarize x [aweight = w]  # Weighted summary statistics [tidystata]
#>   summ(data, x, .wt = w, .wt_type = "analytic")
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
findit("bys g: egen m = mean(x)")
#> # Stata to R: 29 entries
#> 
#> bysort group: egen x_avg = mean(x)  # Group statistic as a new variable [dplyr]
#>   mutate(data, x_avg = mean(x, na.rm = TRUE), .by = group)
#> egen x_avg = mean(x)                # Sample statistic as a new variable [dplyr]
#>   mutate(data, x_avg = mean(x, na.rm = TRUE))
#> bysort group: egen mx = max(x)      # Group maximum [dplyr]
#>   mutate(data, mx = max(x, na.rm = TRUE), .by = group)
#> bysort group: egen mn = min(x)      # Group minimum [dplyr]
#>   mutate(data, mn = min(x, na.rm = TRUE), .by = group)
#> bysort group: egen med = median(x)  # Group median [dplyr]
#>   mutate(data, med = median(x, na.rm = TRUE), .by = group)
#> egen x_sum = rowtotal(x1-x5)        # Row total [tidystata]
#>   mutate(data, x_sum = row_sum(x1:x5))
#> egen x_avg = rowmean(x1-x5)         # Row mean [tidystata]
#>   mutate(data, x_avg = row_mean(x1:x5))
#> egen x_min = rowmin(x1-x5)          # Row minimum [tidystata]
#>   mutate(data, x_min = row_min(x1:x5))
#> egen x_max = rowmax(x1-x5)          # Row maximum [tidystata]
#>   mutate(data, x_max = row_max(x1:x5))
#> egen x_med = rowmedian(x1-x5)       # Row median [tidystata]
#>   mutate(data, x_med = row_median(x1:x5))
#> egen x_mi = rowmiss(x1-x5)          # Number of missing values in each row [tidystata]
#>   mutate(data, x_mi = row_miss(x1:x5))
#> egen x_n = rownonmiss(x1-x5)        # Number of observed values in each row [tidystata]
#>   mutate(data, x_n = row_non_miss(x1:x5))
#> bysort group: egen tot = total(x)   # Group total [dplyr]
#>   mutate(data, tot = sum(x, na.rm = TRUE), .by = group)
#> bysort group: egen n = count(x)     # Number of observed values in each group [dplyr]
#>   mutate(data, n = sum(!is.na(x)), .by = group)
#> bysort group: egen s = sd(x)        # Group standard deviation [dplyr]
#>   mutate(data, s = sd(x, na.rm = TRUE), .by = group)
#> egen s = seq(), from(1) to(3)       # Repeating sequence [dplyr]
#>   mutate(data, s = rep_len(1:3, n()))
#> egen bins = cut(x), group(10)       # Ten groups of about equal size [tidystata]
#>   mutate(data, bins = xtile(x, 10))
#> egen bins = cut(x), at(0(10)100)    # Groups by given cutpoints [base]
#>   mutate(data, bins = cut(x, breaks = seq(0, 100, 10), right = FALSE))
#> egen x_sd = rowsd(x1-x5)            # Row standard deviation [tidystata]
#>   mutate(data, x_sd = row_sd(x1:x5))
#> egen x_nv = rownvals(x1-x5)         # Number of distinct values in each row [tidystata]
#>   mutate(data, x_nv = row_nvals(x1:x5))
#> 
#> # ... and 9 more. Use `print(n = Inf)` to see all, or `View()`.
findit(winsor)
#> # Stata to R: 1 entry
#> 
#> winsor2 x, cuts(1 99)  # Winsorise at the 1st and 99th percentiles [datawizard]
#>   mutate(data, x_w = datawizard::winsorize(x, threshold = 0.01))

# R functions work too, and words with both meanings show both
findit(left_join)
#> # Stata to R: 1 entry
#> 
#> ## R function: left_join() [dplyr]: Merge keeping all rows of the first table
#> merge 1:1 id using data2, keep(master match)  # Keep all rows of the master data [dplyr]
#>   left_join(data1, data2, by = "id")
findit(log)
#> # Stata to R: 2 entries
#> # "log" is a Stata command and an R function.
#> 
#> ## Stata command
#> log using results.log  # Record console output in a file [base]
#>   sink("results.log")
#> 
#> ## R function: log() [base]: Logarithm (natural by default)
#> generate y = ln(x)     # Natural logarithm [base]
#>   mutate(data, y = log(x))

# The whole list
findit()
#> # Stata to R: 415 entries
#> 
#> findit command                    # Find the R equivalent of a Stata command [tidystata]
#>   findit(command)
#> help command                      # Open the help page of a function [utils]
#>   help(function_name)
#> search keyword                    # Search all installed help pages [utils]
#>   help.search("keyword")
#> clear                             # Remove a dataset from memory [base]
#>   rm(data)
#> pwd                               # Show the working directory [base]
#>   getwd()
#> cd "path/to/folder"               # Change the working directory [base]
#>   setwd("path/to/folder")
#> dir                               # List the files in the working directory [base]
#>   dir()
#> global path "path/to/folder"      # Store a value for later use [base]
#>   path <- "path/to/folder"
#> display 2 + 2                     # Calculate and show a result [base]
#>   2 + 2
#> ssc install package               # Install a package [utils]
#>   install.packages("package")
#> net install package, from(url)    # Install a package from GitHub [remotes]
#>   remotes::install_github("user/package")
#> do analysis.do                    # Run a script file [base]
#>   source("analysis.R")
#> log using results.log             # Record console output in a file [base]
#>   sink("results.log")
#> sysuse auto                       # Load an example dataset [datasets]
#>   data("mtcars")
#> use data.dta                      # Open a Stata dataset [haven]
#>   data <- haven::read_dta("data.dta")
#> save data.dta, replace            # Save as a Stata dataset [haven]
#>   haven::write_dta(data, "data.dta")
#> import delimited data.csv         # Import a CSV file [readr]
#>   data <- readr::read_csv("data.csv")
#> import excel data.xlsx, firstrow  # Import an Excel sheet [readxl]
#>   data <- readxl::read_excel("data.xlsx")
#> import spss data.sav              # Import an SPSS file [haven]
#>   data <- haven::read_sav("data.sav")
#> export delimited data.csv         # Export a CSV file [readr]
#>   readr::write_csv(data, "data.csv")
#> 
#> # ... and 395 more. Use `print(n = Inf)` to see all, or `View()`.
```
