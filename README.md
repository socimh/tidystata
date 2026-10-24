
<!-- README.md is generated from README.Rmd. Please edit that file -->

# tidystata

<!-- badges: start -->

[![Lifecycle: stable](https://img.shields.io/badge/lifecycle-stable-brightgreen.svg)](https://lifecycle.r-lib.org/articles/stages.html#stable) [![CRAN status](https://www.r-pkg.org/badges/version/tidystata)](https://CRAN.R-project.org/package=tidystata) [![R-CMD-check](https://github.com/socimh/tidystata/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/socimh/tidystata/actions/workflows/R-CMD-check.yaml)

<!-- badges: end -->

[中文版](https://github.com/socimh/tidystata/blob/master/README.zh.md)

[tidystata](https://socimh.github.io/tidystata/) brings Stata-style data exploration and preparation to R. Inspect variables, summarise measurements, tabulate categories and prepare new columns. Select variables with tidyselect helpers and calculate by group with `.by`. The resulting tables work with ordinary R tools for filtering, joining and plotting.

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
findit("egen rowmean")
#> # Row mean [tidystata]
#> Stata: egen x_avg = rowmean(x1-x5)
#> R:     mutate(data, x_avg = row_mean(x1:x5))
```

A bare command such as `findit(reg)` lists every entry for it. Every entry is listed by topic in [Coming from Stata](https://socimh.github.io/tidystata/articles/coming-from-stata.html).

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

``` r
summ(lifeexp, lexp, gnppc, safewater, .by = region)
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

### tab(): frequency tables

``` r
tab(dplyr::starwars, sex)
#> # A tibble: 5 x 6
#>   sex                n percent   cum valid valid_cum
#>   <chr>          <int>   <dbl> <dbl> <dbl>     <dbl>
#> 1 female            16   18.4   18.4 19.3       19.3
#> 2 hermaphroditic     1    1.15  19.5  1.20      20.5
#> 3 male              60   69.0   88.5 72.3       92.8
#> 4 none               6    6.90  95.4  7.23     100  
#> 5 <NA>               4    4.60 100   NA         NA
```

`tab1()` tabulates several variables, selected with tidyselect helpers such as `ends_with()` and `matches()` or a Stata `varlist()`; `tab2()` cross-tabulates two.

### fre(): frequency tables with totals and value labels

``` r
fre(lifeexp, region)
#> # A tibble: 4 x 6
#>   region               n percent   cum valid valid_cum
#>   <chr>            <int>   <dbl> <dbl> <dbl>     <dbl>
#> 1 Europe & C. Asia    44    64.7  64.7  64.7      64.7
#> 2 North America       14    20.6  85.3  20.6      85.3
#> 3 South America       10    14.7 100    14.7     100  
#> 4 Total               68   100    NA    NA        NA
```

### row_mean() and friends: row calculations

Like Stata’s `egen rowmean()`, `rowtotal()` and `rownonmiss()`, row functions take a range of columns and skip missing values.

``` r
scores <- tibble(
  id = 1:4,
  math = c(80, 92, NA, 75),
  read = c(70, 88, 95, NA),
  art = c(90, NA, 85, 60)
)
scores |>
  mutate(
    mean = row_mean(math:art),
    total = row_sum(math:art),
    answered = row_non_miss(math:art)
  )
#> # A tibble: 4 x 7
#>      id  math  read   art  mean total answered
#>   <int> <dbl> <dbl> <dbl> <dbl> <dbl>    <int>
#> 1     1    80    70    90  80     240        3
#> 2     2    92    88    NA  90     180        2
#> 3     3    NA    95    85  90     180        2
#> 4     4    75    NA    60  67.5   135        2
```

### stata_lag(): panel lags, leads and differences

`stata_lag()`, `stata_lead()` and `stata_diff()` work like `L.`, `F.` and `D.` after `xtset id year`: they follow the time variable, so a gap in the years gives a missing value instead of the previous row.

``` r
panel <- tibble(
  id = c(1, 1, 1, 2, 2),
  year = c(2001, 2002, 2004, 2001, 2002),
  x = c(10, 12, 15, 20, 21)
)
panel |>
  mutate(
    lag_x = stata_lag(x, time = year),
    d_x = stata_diff(x, time = year),
    .by = id
  )
#> # A tibble: 5 x 5
#>      id  year     x lag_x   d_x
#>   <dbl> <dbl> <dbl> <dbl> <dbl>
#> 1     1  2001    10    NA    NA
#> 2     1  2002    12    10     2
#> 3     1  2004    15    NA    NA
#> 4     2  2001    20    NA    NA
#> 5     2  2002    21    20     1
```

## Learn more

tidystata also covers correlations (`pwcorr()`), missing values (`misstable()`), keys and merging (`isid()`, `stata_merge()`) and binning (`xtile()`). See the guides below for examples and output conventions.

- [Getting started](https://socimh.github.io/tidystata/articles/getting-started.html): a short workflow.
- [Containers and missing values](https://socimh.github.io/tidystata/articles/containers-and-missing-values.html): return types, grouping and labels.
- [Reference](https://socimh.github.io/tidystata/reference/index.html): every function.

## Code of Conduct

Please note that the tidystata project is released with a [Contributor Code of Conduct](https://www.contributor-covenant.org/version/2/0/CODE_OF_CONDUCT.html). By contributing to this project, you agree to abide by its terms.
