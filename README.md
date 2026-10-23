
<!-- README.md is generated from README.Rmd. Please edit that file -->

# tidystata

<!-- badges: start -->

[![Lifecycle: stable](https://img.shields.io/badge/lifecycle-stable-brightgreen.svg)](https://lifecycle.r-lib.org/articles/stages.html#stable) [![CRAN status](https://www.r-pkg.org/badges/version/tidystata)](https://CRAN.R-project.org/package=tidystata) [![R-CMD-check](https://github.com/socimh/tidystata/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/socimh/tidystata/actions/workflows/R-CMD-check.yaml)

<!-- badges: end -->

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
findit(reg)
#> # Stata to R: 6 entries
#> 
#> # Linear regression [stats]
#> Stata: regress y x1 x2
#> R:     fit <- lm(y ~ x1 + x2, data = data)
#> 
#> # Heteroskedasticity-robust standard errors [fixest]
#> Stata: regress y x1 x2, robust
#> R:     fixest::feols(y ~ x1 + x2, data = data, vcov = "hetero")
#> 
#> # Clustered standard errors [fixest]
#> Stata: regress y x1 x2, vce(cluster id)
#> R:     fixest::feols(y ~ x1 + x2, data = data, cluster = ~id)
#> 
#> # Factor variables and interactions [stats]
#> Stata: regress y i.group c.x1##c.x2
#> R:     lm(y ~ factor(group) + x1 * x2, data = data)
#> 
#> # Regression with sampling weights [fixest]
#> Stata: regress y x [pweight = wt]
#> R:     fixest::feols(y ~ x, data = data, weights = ~wt, vcov = "hetero")
#> 
#> # Choose the base category [stats]
#> Stata: regress y ib3.group
#> R:     lm(y ~ relevel(factor(group), ref = "3"), data = data)
findit("merge 1:1 id, keep(match)")
#> # Stata to R: 10 entries
#> # "merge" is a Stata command and an R function.
#> 
#> ## Stata command
#> 
#> # Keep matched rows only [dplyr]
#> Stata: merge 1:1 id using data2, keep(match)
#> R:     inner_join(data1, data2, by = "id")
#> 
#> ## R function: merge() [base]: Merge two data frames (base R)
#>   Related Stata: merge
#> 
#> # ... and 9 more. Use `print(n = Inf)` to see all, or `View()`.
```

Every entry is listed by topic in [Coming from Stata](https://socimh.github.io/tidystata/articles/coming-from-stata.html) ([Chinese](https://socimh.github.io/tidystata/articles/coming-from-stata-zh.html)).

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
#>       region name      type      n unique   min    mean       sd   max
#>   <hvn_lbll> <chr>     <chr> <int>  <int> <dbl>   <dbl>    <dbl> <dbl>
#> 1          1 lexp      dbl      44     17    62    72.5     4.95    79
#> 2          1 gnppc     dbl      43     42   170 11284.  12920.   46650
#> 3          1 safewater dbl      42     25    36    81.6    18.6    100
#> 4          2 lexp      dbl      14     13    57    69.7     6.14    79
#> 5          2 gnppc     dbl      14     14   410  6294.   9080.   32040
#> 6          2 safewater dbl       6      5    40    58      24.0     99
#> 7          3 lexp      dbl      10      8    61    70.7     4.06    76
#> 8          3 gnppc     dbl      10      9   960  3881    2432.    7960
#> 9          3 safewater dbl       6      6    45    65.3    17.0     91
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

## Learn more

tidystata also covers correlations (`pwcorr()`), missing values (`misstable()`), keys and merging (`isid()`, `stata_merge()`), row calculations, binning (`xtile()`) and panel lags. See the guides below for examples and output conventions.

- [Getting started](https://socimh.github.io/tidystata/articles/getting-started.html): a short workflow.
- [Containers and missing values](https://socimh.github.io/tidystata/articles/containers-and-missing-values.html): return types, grouping and labels.
- [NEWS](https://socimh.github.io/tidystata/news/index.html): release notes.
- [Reference](https://socimh.github.io/tidystata/reference/index.html): every function.

## Code of Conduct

Please note that the tidystata project is released with a [Contributor Code of Conduct](https://www.contributor-covenant.org/version/2/0/CODE_OF_CONDUCT.html). By contributing to this project, you agree to abide by its terms.
