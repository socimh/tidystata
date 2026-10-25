# tidystata

[中文版](https://github.com/socimh/tidystata/blob/master/README.zh.md)

[tidystata](https://socimh.github.io/tidystata/) brings Stata-style data
exploration and preparation to R. Inspect variables, summarise
measurements, tabulate categories and prepare new columns. Select
variables with tidyselect helpers and calculate by group with `.by`. The
resulting tables work with ordinary R tools for filtering, joining and
plotting.

## Installation

``` r

# install.packages("pak")
pak::pak("socimh/tidystata")
```

## Core functions

``` r

library(tidystata)
library(dplyr)
```

### findit(): find the R equivalent of a Stata command

``` r

findit("reg, robust")
#> # Heteroskedasticity-robust standard errors [fixest]
#> Stata: regress y x1 x2, robust
#> R:     fixest::feols(y ~ x1 + x2, data = data, vcov = "hetero")
#> # Note: Match fixest covariance small-sample corrections and singleton handling with Stata; the same formula does not guarantee identical standard errors or retained observations.
#> 
#> # 17 more examples. To see them all: findit("reg, robust") |> print(n = Inf)
findit("egen rowmean")
#> # Average available values across columns [base]
#> Stata: egen z = rowmean(x y)
#> R:     data$z <- rowMeans(data[c('x','y')],na.rm=TRUE); data$z[is.nan(data$z)] <- NA_real_
#> 
#> # 59 more examples. To see them all: findit("egen rowmean") |> print(n = Inf)
```

A bare command such as `findit(reg)` shows one clear example;
`findit(reg) |> print(n = Inf)` shows every match. Add variable names or
hints with commas, as in `findit(tab, sex, region)` or
`findit(tab, gen)`. Every entry is listed by topic in [Coming from
Stata](https://socimh.github.io/tidystata/articles/coming-from-stata.html).

### codebook(): describe every variable

``` r

codebook(lifeexp)
#> # A tibble: 6 x 5
#>   variable  label                    type             n unique
#>   <chr>     <chr>                    <chr>        <int>  <int>
#> 1 region    Region                   double+label    68      3
#> 2 country   Country                  character       68     68
#> 3 popgrowth Avg. annual % growth     double          68     32
#> 4 lexp      Life expectancy at birth double          68     20
#> 5 gnppc     GNP per capita           double          67     64
#> 6 safewater Safe water               double          54     32
```

### summ(): summary statistics

`lexp:safewater` selects the three consecutive variables from `lexp`
through `safewater`, including both endpoints. Other tidyselect helpers
such as
[`ends_with()`](https://tidyselect.r-lib.org/reference/starts_with.html)
and
[`matches()`](https://tidyselect.r-lib.org/reference/starts_with.html),
or a Stata-style
[`varlist()`](https://socimh.github.io/tidystata/reference/varlist.md),
also work.

``` r

summ(lifeexp, lexp:safewater, .by = region)
#> # A tibble: 9 x 9
#>   region               name      type      n unique   min    mean       sd   max
#>   <dbl+lbl>            <chr>     <chr> <int>  <int> <dbl>   <dbl>    <dbl> <dbl>
#> 1 1 [Europe & C. Asia] lexp      dbl      44     17    62    72.5     4.95    79
#> 2 1 [Europe & C. Asia] gnppc     dbl      43     42   170 11284.  12920.   46650
#> 3 1 [Europe & C. Asia] safewater dbl      42     25    36    81.6    18.6    100
#> 4 2 [North America]    lexp      dbl      14     13    57    69.7     6.14    79
#> 5 2 [North America]    gnppc     dbl      14     14   410  6294.   9080.   32040
#> 6 2 [North America]    safewater dbl       6      5    40    58      24.0     99
#> 7 3 [South America]    lexp      dbl      10      8    61    70.7     4.06    76
#> 8 3 [South America]    gnppc     dbl      10      9   960  3881    2432.    7960
#> 9 3 [South America]    safewater dbl       6      6    45    65.3    17.0     91
```

### tab(), tab1() and tab2(): compare frequency tables

Use region and a second category derived from `lifeexp`: whether life
expectancy is at least 70 years. `region:lexp_70` selects these two
columns.

[`tab()`](https://socimh.github.io/tidystata/reference/tab.md) counts
each observed combination, with percentages.

``` r

lifeexp_tab <- lifeexp |>
  transmute(region, lexp_70 = lexp >= 70)

tab(lifeexp_tab, region:lexp_70)
#> # A tibble: 6 x 7
#>   region               lexp_70     n percent   cum valid valid_cum
#>   <dbl+lbl>            <lgl>   <int>   <dbl> <dbl> <dbl>     <dbl>
#> 1 1 [Europe & C. Asia] FALSE      12   17.6   17.6 17.6       17.6
#> 2 1 [Europe & C. Asia] TRUE       32   47.1   64.7 47.1       64.7
#> 3 2 [North America]    FALSE       6    8.82  73.5  8.82      73.5
#> 4 2 [North America]    TRUE        8   11.8   85.3 11.8       85.3
#> 5 3 [South America]    FALSE       3    4.41  89.7  4.41      89.7
#> 6 3 [South America]    TRUE        7   10.3  100   10.3      100
```

[`tab1()`](https://socimh.github.io/tidystata/reference/tab.md) returns
a named list with a separate frequency table for each variable.

``` r

tab1(lifeexp_tab, region:lexp_70)
#> $region
#> # A tibble: 3 x 6
#>   value                    n percent   cum valid valid_cum
#>   <dbl+lbl>            <int>   <dbl> <dbl> <dbl>     <dbl>
#> 1 1 [Europe & C. Asia]    44    64.7  64.7  64.7      64.7
#> 2 2 [North America]       14    20.6  85.3  20.6      85.3
#> 3 3 [South America]       10    14.7 100    14.7     100  
#> 
#> $lexp_70
#> # A tibble: 2 x 6
#>   value     n percent   cum valid valid_cum
#>   <lgl> <int>   <dbl> <dbl> <dbl>     <dbl>
#> 1 FALSE    21    30.9  30.9  30.9      30.9
#> 2 TRUE     47    69.1 100    69.1     100
```

[`tab2()`](https://socimh.github.io/tidystata/reference/tab.md) displays
the joint counts as a cross-table, with region in rows and life
expectancy category in columns.

``` r

tab2(lifeexp_tab, region:lexp_70)
#> # A tibble: 3 x 3
#>   `region \\ lexp_70`  `FALSE` `TRUE`
#>   <dbl+lbl>              <int>  <int>
#> 1 1 [Europe & C. Asia]      12     32
#> 2 2 [North America]          6      8
#> 3 3 [South America]          3      7
```

## Learn more

tidystata also covers row calculations
([`row_mean()`](https://socimh.github.io/tidystata/reference/row_egen.md)),
panel operators
([`stata_lag()`](https://socimh.github.io/tidystata/reference/panel.md)),
correlations
([`pwcorr()`](https://socimh.github.io/tidystata/reference/pwcorr.md)),
missing values
([`misstable()`](https://socimh.github.io/tidystata/reference/misstable.md)),
keys and merging
([`isid()`](https://socimh.github.io/tidystata/reference/keys.md),
[`stata_merge()`](https://socimh.github.io/tidystata/reference/stata_merge.md))
and binning
([`xtile()`](https://socimh.github.io/tidystata/reference/cut.md)). See
the guides below for examples and output conventions.

- [Getting
  started](https://socimh.github.io/tidystata/articles/getting-started.html):
  a short workflow.
- [Containers and missing
  values](https://socimh.github.io/tidystata/articles/containers-and-missing-values.html):
  return types, grouping and labels.
- [Reference](https://socimh.github.io/tidystata/reference/index.html):
  every function.

## Code of Conduct

Please note that the tidystata project is released with a [Contributor
Code of
Conduct](https://www.contributor-covenant.org/version/2/0/CODE_OF_CONDUCT.html).
By contributing to this project, you agree to abide by its terms.
