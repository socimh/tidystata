# Getting started with tidystata

This tutorial follows a small survey from inspection to tabulation,
grouped summaries and new variables. Results are ordinary R objects that
you can save, filter and join. Install tidystata as shown on the
[package homepage](https://socimh.github.io/tidystata/) before starting.

## Load data and inspect variables

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

survey <- tibble(
  id = 1:6,
  group = c("A", "A", "A", "B", "B", NA),
  response = c("yes", "no", NA, "yes", "yes", "no"),
  score1 = c(2, 4, NA, 6, 8, 10),
  score2 = c(4, NA, NA, 8, 10, 12)
)
attr(survey$score1, "label") <- "First assessment score"

codebook(survey)
#> # A tibble: 5 × 5
#>   variable label                  type          n unique
#>   <chr>    <chr>                  <chr>     <int>  <int>
#> 1 id       NA                     integer       6      6
#> 2 group    NA                     character     5      2
#> 3 response NA                     character     5      2
#> 4 score1   First assessment score double        5      5
#> 5 score2   NA                     double        4      4
variables(survey)
#> # A tibble: 5 × 2
#>   name     label                 
#>   <chr>    <chr>                 
#> 1 id       NA                    
#> 2 group    NA                    
#> 3 response NA                    
#> 4 score1   First assessment score
#> 5 score2   NA
ds(survey, starts_with("score"))
#> [1] "score1" "score2"
```

[`codebook()`](https://socimh.github.io/tidystata/reference/codebook.md)
gives one row per variable.
[`variables()`](https://socimh.github.io/tidystata/reference/variables.md)
reports names and variable labels, while
[`ds()`](https://socimh.github.io/tidystata/reference/names.md) returns
a character vector of names.
[`variables_search()`](https://socimh.github.io/tidystata/reference/variables.md)
searches names and labels, so it can find a variable from its
description:

``` r

variables_search(survey, "assessment")
#> # A tibble: 1 × 2
#>   name   label                 
#>   <chr>  <chr>                 
#> 1 score1 First assessment score
select_or_transmute(survey, id, starts_with("score"))
#> # A tibble: 6 × 3
#>      id score1 score2
#>   <int>  <dbl>  <dbl>
#> 1     1      2      4
#> 2     2      4     NA
#> 3     3     NA     NA
#> 4     4      6      8
#> 5     5      8     10
#> 6     6     10     12
```

## Count categories

``` r

counts <- tab(survey, response)
counts
#> # A tibble: 3 × 6
#>   response     n percent   cum valid valid_cum
#>   <chr>    <int>   <dbl> <dbl> <dbl>     <dbl>
#> 1 no           2    33.3  33.3    40        40
#> 2 yes          3    50    83.3    60       100
#> 3 NA           1    16.7 100      NA        NA
sum(counts$n)
#> [1] 6

fre(survey, response)
#> # A tibble: 5 × 6
#>   response        n percent   cum valid valid_cum
#>   <chr>       <int>   <dbl> <dbl> <dbl>     <dbl>
#> 1 no              2    33.3  33.3    40        40
#> 2 yes             3    50    83.3    60       100
#> 3 Valid Total     5    83.3  NA     100        NA
#> 4 NA              1    16.7 100      NA        NA
#> 5 Total           6   100    NA      NA        NA
tab2(survey, group, response)
#> # A tibble: 3 × 4
#>   `group \\ response`    no   yes  `NA`
#>   <chr>               <int> <int> <int>
#> 1 A                       1     1     1
#> 2 B                       0     2     0
#> 3 NA                      1     0     0
```

The counts sum to six, including the missing response.
[`tab()`](https://socimh.github.io/tidystata/reference/tab.md) returns
observed categories with counts and percentages.
[`fre()`](https://socimh.github.io/tidystata/reference/tab.md) adds
total rows;
[`tab2()`](https://socimh.github.io/tidystata/reference/tab.md) puts the
categories of its second variable into columns. Use
[`tab1()`](https://socimh.github.io/tidystata/reference/tab.md) when you
want separate one-way tables instead of a joint table:

``` r

tables <- tab1(survey, group, response)
tables$response
#> # A tibble: 3 × 6
#>   value     n percent   cum valid valid_cum
#>   <chr> <int>   <dbl> <dbl> <dbl>     <dbl>
#> 1 no        2    33.3  33.3    40        40
#> 2 yes       3    50    83.3    60       100
#> 3 NA        1    16.7 100      NA        NA
```

The returned objects contain data. For example, select categories
occurring more than once with an ordinary pipeline:

``` r

tab(survey, response) |>
  filter(n > 1)
#> # A tibble: 2 × 6
#>   response     n percent   cum valid valid_cum
#>   <chr>    <int>   <dbl> <dbl> <dbl>     <dbl>
#> 1 no           2    33.3  33.3    40        40
#> 2 yes          3    50    83.3    60       100
```

## Summarise measurements

Select numeric measurements deliberately. Codes attached to categories
are not automatically meaningful measurements.

``` r

summ(survey, score1, score2, .stat = c("n", "mean", "sd", "missing"))
#> # A tibble: 2 × 6
#>   name   type      n  mean    sd missing
#>   <chr>  <chr> <int> <dbl> <dbl>   <int>
#> 1 score1 dbl       5   6    3.16       1
#> 2 score2 dbl       4   8.5  3.42       2
tabstat(survey, score1, score2, .by = group)
#> # A tibble: 6 × 4
#>   group name   type   mean
#>   <chr> <chr>  <chr> <dbl>
#> 1 A     score1 dbl       3
#> 2 A     score2 dbl       4
#> 3 B     score1 dbl       7
#> 4 B     score2 dbl       9
#> 5 NA    score1 dbl      10
#> 6 NA    score2 dbl      12
mean(survey$score1, na.rm = TRUE)
#> [1] 6
```

[`summ()`](https://socimh.github.io/tidystata/reference/summ.md) can
return several statistics.
[`tabstat()`](https://socimh.github.io/tidystata/reference/summ.md)
selects means by default. Both omit missing measured values from numeric
calculations. Missing grouping keys remain as a group unless you request
`.missing = FALSE`:

``` r

summ(survey, score1, .by = group, .missing = FALSE, .stat = c("n", "mean"))
#> # A tibble: 2 × 4
#>   group type      n  mean
#>   <chr> <chr> <int> <dbl>
#> 1 A     dbl       2     3
#> 2 B     dbl       2     7
```

Numeric-only summaries return a table. When numeric and calendar
measurements are combined, the default can be a list of tables. The
companion
[`vignette("containers-and-missing-values", package = "tidystata")`](https://socimh.github.io/tidystata/articles/containers-and-missing-values.md)
explains those types and their missing-value conventions.

## Prepare new variables

Row helpers return vectors, making them convenient in
[`mutate()`](https://dplyr.tidyverse.org/reference/mutate.html).
[`pick()`](https://dplyr.tidyverse.org/reference/pick.html) makes the
columns being combined explicit.

``` r

prepared <- survey |>
  mutate(
    average = row_mean(pick(score1, score2)),
    observed = row_non_miss(pick(score1, score2))
  )
prepared
#> # A tibble: 6 × 7
#>      id group response score1 score2 average observed
#>   <int> <chr> <chr>     <dbl>  <dbl>   <dbl>    <int>
#> 1     1 A     yes           2      4       3        2
#> 2     2 A     no            4     NA       4        1
#> 3     3 A     NA           NA     NA      NA        0
#> 4     4 B     yes           6      8       7        2
#> 5     5 B     yes           8     10       9        2
#> 6     6 NA    no           10     12      11        2
```

The third row has no observed score, so its average is `NA` and its
observed count is zero. Row sums use zero for an all-missing row, while
column summaries use `NA` for a sum with no observations.

Character measurements can be parsed explicitly, and sentinel values can
be replaced before calculations:

``` r

destring(c("1,200", "2,500", NA))
#> [1] 1200 2500   NA
mvdecode(c(1, -99, 3), -99)
#> [1]  1 NA  3
xtile(1:8, 4)
#> [1] [1,2.5]   [1,2.5]   (2.5,4.5] (2.5,4.5] (4.5,6.5] (4.5,6.5] (6.5,8]  
#> [8] (6.5,8]  
#> Levels: [1,2.5] < (2.5,4.5] < (4.5,6.5] < (6.5,8]
```

[`destring()`](https://socimh.github.io/tidystata/reference/type_conversion.md)
reads numbers with currency symbols, thousands separators and percent
signs; other text, such as `"10 kg"`, becomes `NA` with a warning unless
you remove it with `ignore = "kg"`.
[`xtile()`](https://socimh.github.io/tidystata/reference/cut.md) uses
Stata’s percentile cutpoints and keeps tied values together; ties can
leave some groups empty.

## Next steps

Read [Containers and missing
values](https://socimh.github.io/tidystata/articles/containers-and-missing-values.md)
for output conventions, or [Coming from
Stata](https://socimh.github.io/tidystata/articles/coming-from-stata.md)
to find the R equivalent of a Stata command.
