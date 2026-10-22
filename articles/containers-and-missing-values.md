# Containers, grouping and missing values

tidystata separates tabular results from display choices. This tutorial
shows how to preserve data containers and interpret missing values
before passing results to another calculation.

## Container types and lists

``` r

library(tidystata)
library(dplyr)
#> 
#> Attaching package: 'dplyr'
#> The following objects are masked from 'package:stats':
#> 
#>     filter, lag
#> The following objects are masked from 'package:base':
#> 
#>     intersect, setdiff, setequal, union

df <- data.frame(
  group = c("A", "A", "B", NA),
  answer = c("yes", NA, "no", "yes"),
  score = c(2, NA, 6, 8)
)
tbl <- tibble::as_tibble(df)

class(tab(df, answer))
#> [1] "data.frame"
class(tab(tbl, answer))
#> [1] "tbl_df"     "tbl"        "data.frame"
class(summ(df, score))
#> [1] "data.frame"
class(summ(tbl, score))
#> [1] "tbl_df"     "tbl"        "data.frame"
```

New tables from the `tab`, `summ`, `codebook` and `variables` families
preserve a base data frame, tibble or data.table input. A list result
remains a list, and each table inside follows the same rule. An explicit
output option takes precedence.
[`pwcorr()`](https://socimh.github.io/tidystata/reference/pwcorr.md),
[`misstable()`](https://socimh.github.io/tidystata/reference/misstable.md)
and
[`duplicates_report()`](https://socimh.github.io/tidystata/reference/keys.md)
are exceptions: they always return tibbles.

``` r

base_tables <- tab1(df, answer, group)
class(base_tables)
#> [1] "list"
class(base_tables$answer)
#> [1] "data.frame"
class(fre(df, answer, .type = "tibble"))
#> [1] "tbl_df"     "tbl"        "data.frame"
```

Other data-frame subclasses are not reconstructed on newly shaped
tables. Vectors, such as the result of
[`ds()`](https://socimh.github.io/tidystata/reference/names.md) or
[`row_mean()`](https://socimh.github.io/tidystata/reference/row_egen.md),
keep their intentional vector output. New data.table summaries do not
retain input keys or indexes.

The optional data.table integration is exercised only when it is
installed:

``` r

if (requireNamespace("data.table", quietly = TRUE)) {
  dt <- data.table::as.data.table(df)
  class(tab(dt, answer))
  class(summ(dt, score))
}
#> [1] "data.table" "data.frame"
```

Rich output is also optional. It is a display object rather than a data
table:

``` r

if (requireNamespace("flextable", quietly = TRUE)) {
  rich <- fre(tbl, answer, .type = "flextable")
  class(rich)
}
#> [1] "flextable"
```

## Grouping and denominators

``` r

grouped <- group_by(tbl, group)
tab(grouped, answer)
#> # A tibble: 4 × 7
#>   group answer     n percent   cum valid valid_cum
#>   <chr> <chr>  <int>   <dbl> <dbl> <dbl>     <dbl>
#> 1 A     yes        1      50    50   100       100
#> 2 A     NA         1      50   100    NA        NA
#> 3 B     no         1     100   100   100       100
#> 4 NA    yes        1     100   100   100       100
summary <- summ(grouped, score, .stat = c("n", "mean", "missing"))
summary
#> # A tibble: 3 × 5
#>   group type      n  mean missing
#>   <chr> <chr> <int> <dbl>   <int>
#> 1 A     dbl       1     2       1
#> 2 B     dbl       1     6       0
#> 3 NA    dbl       1     8       0
group_vars(summary)
#> character(0)
```

Summary and inventory results are ungrouped. Grouping keys remain
ordinary columns where reported. For
[`tab()`](https://socimh.github.io/tidystata/reference/tab.md),
[`tab1()`](https://socimh.github.io/tidystata/reference/tab.md),
[`tab2()`](https://socimh.github.io/tidystata/reference/tab.md),
[`fre()`](https://socimh.github.io/tidystata/reference/tab.md),
[`fre1()`](https://socimh.github.io/tidystata/reference/tab.md),
[`fre2()`](https://socimh.github.io/tidystata/reference/tab.md),
[`summ()`](https://socimh.github.io/tidystata/reference/summ.md) and
[`tabstat()`](https://socimh.github.io/tidystata/reference/summ.md),
`.by = NULL` inherits existing groups; an explicit `.by` replaces them.

``` r

summ(grouped, score, .by = answer, .stat = c("n", "mean"))
#> # A tibble: 3 × 4
#>   answer type      n  mean
#>   <chr>  <chr> <int> <dbl>
#> 1 no     dbl       1     6
#> 2 yes    dbl       2     5
#> 3 NA     dbl       0    NA
```

Cross-tabulation with
[`tab2()`](https://socimh.github.io/tidystata/reference/tab.md) or
[`fre2()`](https://socimh.github.io/tidystata/reference/tab.md) returns
one table per group, in a list named after each group, as Stata’s
`by group: tab2 x y` does:

``` r

crossed <- tab2(df, answer, score, .by = group)
names(crossed)
#> [1] "group = A"  "group = B"  "group = NA"
```

One-way tabulations use all observations within a group for `percent`
and `cum`, on a zero-to-100 scale. `valid` and `valid_cum` exclude
missing measured values. Missing grouping keys are ordinary groups. In
summaries, `valid_pct` is instead a fraction from zero to one.
`summ(.missing = FALSE)` removes missing grouping keys; numeric
calculations always omit missing measured values.

``` r

tab(tbl, answer)
#> # A tibble: 3 × 6
#>   answer     n percent   cum valid valid_cum
#>   <chr>  <int>   <dbl> <dbl> <dbl>     <dbl>
#> 1 no         1      25    25  33.3      33.3
#> 2 yes        2      50    75  66.7     100  
#> 3 NA         1      25   100  NA        NA
summ(tbl, score, .stat = c("n", "miss_n", "valid_pct", "mean"))
#> # A tibble: 1 × 5
#>   type      n miss_n valid_pct  mean
#>   <chr> <int>  <int>     <dbl> <dbl>
#> 1 dbl       3      1      0.75  5.33
summ(tbl, score, .by = group, .missing = FALSE, .stat = c("n", "mean"))
#> # A tibble: 2 × 4
#>   group type      n  mean
#>   <chr> <chr> <int> <dbl>
#> 1 A     dbl       1     2
#> 2 B     dbl       1     6
```

## Empty and all-missing measurements

``` r

empty <- tbl[0, ]
summ(empty, score, .stat = c("n", "sum", "mean"))
#> # A tibble: 1 × 4
#>   type      n   sum  mean
#>   <chr> <int> <dbl> <dbl>
#> 1 dbl       0    NA    NA
tab1(tbl, starts_with("absent"))
#> named list()

missing <- tibble(a = c(NA_real_, NA_real_), b = c(NA_real_, 4))
summ(missing, a, .stat = c("n", "sum", "mean"))
#> Warning: a is entirely missing; retained with n = 0.
#> # A tibble: 1 × 4
#>   type      n   sum  mean
#>   <chr> <int> <dbl> <dbl>
#> 1 dbl       0    NA    NA
row_sum(missing)
#> [1] 0 4
row_mean(missing)
#> [1] NA  4
```

An ungrouped numeric column with no observations remains in a summary
with `n = 0` and `NA` statistics, including `sum`. An all-missing row
instead has a row sum of zero and a row mean of `NA`. Empty selections
give empty results for tabulation; row helpers require at least one
column. Matrix columns are not supported by the tabulation and
column-summary interfaces.

## Labels and special missing values

Variable labels describe columns; value labels describe particular
values. SPSS user-missing codes and Stata tagged missing values follow
the original vector’s missingness rules.

``` r

labelled <- tibble(
  response = haven::labelled_spss(
    c(1, 2, 99, NA),
    labels = c(Yes = 1, No = 2, Refused = 99),
    na_values = 99,
    label = "Interview response"
  )
)
variables(labelled)
#> # A tibble: 1 × 2
#>   name     label             
#>   <chr>    <chr>             
#> 1 response Interview response
codebook(labelled)
#> # A tibble: 1 × 5
#>   variable label              type             n unique
#>   <chr>    <chr>              <chr>        <int>  <int>
#> 1 response Interview response double+label     2      2
tab(labelled, response)
#> # A tibble: 4 × 6
#>   response              n percent   cum valid valid_cum
#>   <dbl+lbl>         <int>   <dbl> <dbl> <dbl>     <dbl>
#> 1  1 [Yes]              1      25    25    50        50
#> 2  2 [No]               1      25    50    50       100
#> 3 99 (NA) [Refused]     1      25    75    NA        NA
#> 4 NA                    1      25   100    NA        NA
decode(labelled$response)
#> [1] "Yes"     "No"      "Refused" NA
```

Summary statistics for labelled numeric measurements use their
underlying values and exclude SPSS user-missing codes. Factors use level
codes and warn; choose measurements deliberately instead of averaging
category codes.
[`decode()`](https://socimh.github.io/tidystata/reference/type_conversion.md)
displays value labels when present, but does not itself recode every
labelled refusal into an ordinary `NA`.

## Numeric and calendar summary tables

``` r

mixed <- tibble(score = c(2, 4), day = as.Date("2024-01-01") + c(0, 2))
separate <- summ(mixed, .stat = c("n", "min", "mean", "sd", "max"))
#> A list is returned as statistics are heterogeneous.
names(separate)
#> [1] "numeric" "date"
separate$numeric
#> # A tibble: 1 × 7
#>   name  type      n   min  mean    sd   max
#>   <chr> <chr> <int> <dbl> <dbl> <dbl> <dbl>
#> 1 score dbl       2     2     3  1.41     4
separate$date
#> # A tibble: 1 × 7
#>   name  type      n min        mean       sd            max       
#>   <chr> <chr> <int> <chr>      <chr>      <drtn>        <chr>     
#> 1 day   date      2 2024-01-01 2024-01-02 1.414214 days 2024-01-03
class(separate$date$sd)
#> [1] "difftime"
combined <- summ(mixed, .type = "table", .stat = c("n", "min", "mean", "sd", "max"))
combined
#> # A tibble: 2 × 7
#>   name  type            n min        mean          sd max       
#>   <chr> <chr>       <int> <chr>      <chr>      <dbl> <chr>     
#> 1 score dbl             2 2          3           1.41 4         
#> 2 day   date [days]     2 2024-01-01 2024-01-02  1.41 2024-01-03
class(combined$sd)
#> [1] "numeric"
```

Default list mode keeps numeric statistics numeric in their own table.
Calendar locations such as `min`, `mean` and `max` are formatted dates
or date-times, while a spread such as `sd` stays a `difftime`. Table
mode combines families. A location column shared by numeric and calendar
rows becomes character, and the spread column becomes a plain number of
days for dates or seconds for date-times, with the unit shown in the
`type` column. Use raw inputs and base R statistics when full calendar
precision is needed. SD uses the sample denominator, quantiles use type
7, and these conventions are not promises of exact Stata equivalence.

## A preview retains every row

``` r

long <- tibble(id = 1:12, value = (1:12)^2)
preview <- preview_table(long, n = 4)
preview
#> # A tibble: 12 × 2
#>       id value
#>    <int> <dbl>
#>  1     1     1
#>  2     2     4
#> 11    11   121
#> 12    12   144
#> # ... 8 rows omitted in the middle; use print(x, n = Inf) to show all rows.
nrow(preview)
#> [1] 12
sum(preview$value)
#> [1] 650

subset <- slice_headtail(long, n = 4)
subset
#> # A tibble: 4 × 2
#>      id value
#>   <int> <dbl>
#> 1     1     1
#> 2     2     4
#> 3    11   121
#> 4    12   144
nrow(subset)
#> [1] 4
sum(subset$value)
#> [1] 270
```

The preview still contains 12 rows; the slice contains four. `n` is the
total display or selection budget, split between the beginning and end.
Interval mode samples approximately evenly spaced positions; sort first
when position should represent a meaningful order.

``` r

preview_table(long, style = "interval", n = 4)
#> # A tibble: 12 × 2
#>       id value
#>    <int> <dbl>
#>  1     1     1
#>  5     5    25
#>  8     8    64
#> 12    12   144
#> # ... 8 rows omitted between displayed positions; use print(x, n = Inf) to show
#> # all rows.
ordinary <- unpreview_table(preview)
identical(ordinary, long)
#> [1] TRUE
```

[`print_headtail()`](https://socimh.github.io/tidystata/reference/special-print.md)
and
[`print_interval()`](https://socimh.github.io/tidystata/reference/special-print.md)
print once and invisibly return the complete input.
[`unpreview_table()`](https://socimh.github.io/tidystata/reference/special-print.md)
removes the persistent display setting. Supported dplyr/tidyr operations
carry preview settings forward while following their own container and
grouping rules. Wrapping and unwrapping a data.table copies it; later
native data.table mutations retain ordinary reference semantics.
