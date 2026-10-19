
<!-- README.md is generated from README.Rmd. Please edit that file -->

# statart

<!-- badges: start -->

[![Lifecycle:
experimental](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://lifecycle.r-lib.org/articles/stages.html#experimental)
[![CRAN
status](https://www.r-pkg.org/badges/version/statart)](https://CRAN.R-project.org/package=statart)
[![R-CMD-check](https://github.com/socimh/statart/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/socimh/statart/actions/workflows/R-CMD-check.yaml)

<!-- badges: end -->

[statart](https://socimh.github.io/statart/) is a set of functions that
combines Stata-inspired features with tidyverse-style operations.

The package focuses on exploring and preparing data:

- `tab()`, `tab1()`, and `tab2()` for frequency tables.
- `fre()`, `fre1()`, and `fre2()` for frequency tables with totals.
- `summ()` and `tabstat()` for summary statistics.
- `codebook()` and `variables()` for variable inspection.
- `s_select()`, row calculations, conversion helpers, and binning for
  data preparation.

The `0.2.0.9000` development series retires the import/export,
regression-table, and detailed-codebook wrappers in preparation for
`0.3.0`. See the [migration
guide](https://socimh.github.io/statart/articles/migration.html) for
direct package alternatives and breaking changes. This experimental
package is undergoing stabilization; see
[DEVELOPMENT.md](https://github.com/socimh/statart/blob/master/DEVELOPMENT.md)
for the verified status and remaining work.

## Installation

You can install the development version of statart like so:

``` r
devtools::install_github("socimh/statart")
```

R 4.1.0 or later and a suitable build toolchain are required to install
from source. Rich table formatting is optional and requires `flextable`.

If you already have this source repository on your computer, open
`statart.Rproj` and restart R before installing the local changes:

``` r
devtools::install(".", upgrade = "never", build_vignettes = FALSE)
```

Restart R again, then check the version and installed location:

``` r
library(statart)
packageVersion("statart")
find.package("statart")
```

Opening the source folder alone does not change what `library(statart)`
loads. Repeat the installation after editing source code. During package
development, `devtools::load_all(".")` loads the working source into the
current session; installation followed by a fresh R session tests the
installed package.

## Learn the workflow

Read [Getting
started](https://socimh.github.io/statart/articles/getting-started.html)
for a small exploration and preparation workflow, and [Containers and
missing
values](https://socimh.github.io/statart/articles/containers-and-missing-values.html)
for return types, grouping, labels and previews. In an installation that
includes vignettes, use
`vignette("getting-started", package = "statart")`.

Plain manual scripts are included in the installed package. Open a
script in your editor and run its lines individually, or run this
complete example:

``` r
source(system.file("examples", "02_frequency_tables.R", package = "statart"),
       echo = TRUE)
```

Use `system.file("examples", "README.md", package = "statart")` for the
script index and `system.file("MIGRATION.md", package = "statart")` for
the full installed migration guide. The source repository also contains
both guides.

## Table return types

Table-producing helpers preserve the input container by default: a
tibble returns a tibble, a base data frame returns a base data frame,
and a data.table returns a data.table. List outputs remain lists, with
each table following the same rule. Explicit output options override
this default. Summaries and variable inventories are ungrouped; grouping
columns are retained where the function normally reports them. Arbitrary
data-frame subclass metadata is not guaranteed on newly constructed
tables. Vector and scalar helpers retain their usual outputs.

`preview_table()` preserves the underlying container while changing its
console display. `unpreview_table()` removes that display setting.
External dplyr and tidyr verbs retain their own container and grouping
behavior, with preview settings preserved for supported operations.

## Example

### Load the package

Load `statart` and the data-manipulation package used in these examples.

``` r
library(statart)
library(dplyr)
```

### codebook()

View the codebook of `lifeexp`.

``` r
codebook(lifeexp)
#> # A tibble: 6 x 5
#>   variable  label                    type             n unique
#>   <chr>     <chr>                    <chr>        <int>  <int>
#> 1 region    Region                   double+label    68      3
#> 2 country   Country                  character       68     68
#> 3 popgrowth Avg. annual % growth     double          68     30
#> 4 lexp      Life expectancy at birth double          68     18
#> 5 gnppc     GNP per capita           double          63     62
#> 6 safewater Safe water               double          40     29
```

### summ()

Summarise selected numeric variables in `mtcars`.

``` r
summ(mtcars, mpg, wt)
#>   name type  n unique    min     mean        sd    max
#> 1  mpg  dbl 32     25 10.400 20.09062 6.0269481 33.900
#> 2   wt  dbl 32     29  1.513  3.21725 0.9784574  5.424
```

Choose numeric variables deliberately: means and standard deviations of
factor codes may have no substantive interpretation. Numeric and logical
columns with no observed values are retained: `n` and `unique` are zero
and summary statistics are `NA`, including `sum`.

Select statistics with `.stat`. Aliases `missing`, `p25`, `p50`, and
`p75` retain their requested names and order; `sum` is available for
numeric summaries. Unsupported statistics produce an error. See the
[migration
guide](https://socimh.github.io/statart/articles/migration.html) for the
date/datetime restrictions and cross-tabulation naming rules.

``` r
summ(mtcars, mpg, .stat = c("missing", "p50", "sum"))
#>   name type missing  p50   sum
#> 1  mpg  dbl       0 19.2 642.9
```

With `.mode = "table"`, numeric and calendar summaries share character
columns for formatted statistics; counts remain numeric. Default list
mode preserves numeric statistic types in the numeric summary.

### tab()

Tabulate a single variable:

``` r
tab(statart::starwars, sex)
#> # A tibble: 5 x 6
#>   sex                n percent   cum valid valid_cum
#>   <chr>          <int>   <dbl> <dbl> <dbl>     <dbl>
#> 1 female            16   18.4   18.4 19.3       19.3
#> 2 hermaphroditic     1    1.15  19.5  1.20      20.5
#> 3 male              60   69.0   88.5 72.3       92.8
#> 4 none               6    6.90  95.4  7.23     100  
#> 5 <NA>               4    4.60 100   NA         NA
```

`tab1()` tabulates variables one by one as a list, and `s_match()` can
select variables in a Stata style.

``` r
tab1(statart::starwars, s_match("*color"))
#> $hair_color
#> # A tibble: 13 x 6
#>    value             n percent    cum valid valid_cum
#>    <chr>         <int>   <dbl>  <dbl> <dbl>     <dbl>
#>  1 auburn            1    1.15   1.15  1.22      1.22
#>  2 auburn, grey      1    1.15   2.30  1.22      2.44
#>  3 auburn, white     1    1.15   3.45  1.22      3.66
#>  4 black            13   14.9   18.4  15.9      19.5 
#>  5 blond             3    3.45  21.8   3.66     23.2 
#>  6 blonde            1    1.15  23.0   1.22     24.4 
#>  7 brown            18   20.7   43.7  22.0      46.3 
#>  8 brown, grey       1    1.15  44.8   1.22     47.6 
#>  9 grey              1    1.15  46.0   1.22     48.8 
#> 10 none             37   42.5   88.5  45.1      93.9 
#> 11 unknown           1    1.15  89.7   1.22     95.1 
#> 12 white             4    4.60  94.3   4.88    100   
#> 13 <NA>              5    5.75 100    NA        NA   
#> 
#> $skin_color
#> # A tibble: 31 x 6
#>    value                   n percent   cum valid valid_cum
#>    <chr>               <int>   <dbl> <dbl> <dbl>     <dbl>
#>  1 blue                    2    2.30  2.30  2.30      2.30
#>  2 blue, grey              2    2.30  4.60  2.30      4.60
#>  3 brown                   4    4.60  9.20  4.60      9.20
#>  4 brown mottle            1    1.15 10.3   1.15     10.3 
#>  5 brown, white            1    1.15 11.5   1.15     11.5 
#>  6 dark                    6    6.90 18.4   6.90     18.4 
#>  7 fair                   17   19.5  37.9  19.5      37.9 
#>  8 fair, green, yellow     1    1.15 39.1   1.15     39.1 
#>  9 gold                    1    1.15 40.2   1.15     40.2 
#> 10 green                   6    6.90 47.1   6.90     47.1 
#> # i 21 more rows
#> 
#> $eye_color
#> # A tibble: 15 x 6
#>    value             n percent   cum valid valid_cum
#>    <chr>         <int>   <dbl> <dbl> <dbl>     <dbl>
#>  1 black            10   11.5   11.5 11.5       11.5
#>  2 blue             19   21.8   33.3 21.8       33.3
#>  3 blue-gray         1    1.15  34.5  1.15      34.5
#>  4 brown            21   24.1   58.6 24.1       58.6
#>  5 dark              1    1.15  59.8  1.15      59.8
#>  6 gold              1    1.15  60.9  1.15      60.9
#>  7 green, yellow     1    1.15  62.1  1.15      62.1
#>  8 hazel             3    3.45  65.5  3.45      65.5
#>  9 orange            8    9.20  74.7  9.20      74.7
#> 10 pink              1    1.15  75.9  1.15      75.9
#> 11 red               5    5.75  81.6  5.75      81.6
#> 12 red, blue         1    1.15  82.8  1.15      82.8
#> 13 unknown           3    3.45  86.2  3.45      86.2
#> 14 white             1    1.15  87.4  1.15      87.4
#> 15 yellow           11   12.6  100   12.6      100
```

One-way tabulation also counts list-column values. Selecting no
variables returns an empty result; `tab1()` and `fre1()` return empty
lists by default. Matrix columns are unsupported.

`tab2()` cross-tabulates two variables.

``` r
tab2(statart::starwars, sex, gender)
#> # A tibble: 5 x 4
#>   `sex \\ gender` feminine masculine  `NA`
#>   <chr>              <int>     <int> <int>
#> 1 female                16         0     0
#> 2 hermaphroditic         0         1     0
#> 3 male                   0        60     0
#> 4 none                   1         5     0
#> 5 <NA>                   0         0     4
```

### fre()

`fre()` family functions simply add total rows (and total columns in
`fre2()`) to their `tab()` counterparts.

`fre()` and `fre2()` default to `.type = "auto"`, preserving the input
container. `fre1()` returns a list whose tables preserve that container.
Request `.type = "tibble"` explicitly when a tibble is required.

``` r
fre(statart::starwars, sex)
#> # A tibble: 7 x 6
#>   sex                n percent   cum  valid valid_cum
#>   <chr>          <int>   <dbl> <dbl>  <dbl>     <dbl>
#> 1 female            16   18.4   18.4  19.3       19.3
#> 2 hermaphroditic     1    1.15  19.5   1.20      20.5
#> 3 male              60   69.0   88.5  72.3       92.8
#> 4 none               6    6.90  95.4   7.23     100  
#> 5 Valid Total       83   95.4   NA   100         NA  
#> 6 <NA>               4    4.60 100    NA         NA  
#> 7 Total             87  100     NA    NA         NA
```

For optional rich formatting, install `flextable` and request it
explicitly:

``` r
fre(statart::starwars, sex, .type = "flextable")
```

### Row calculations and binning

Row helpers return vectors that can be used in `mutate()`:

``` r
tibble(a = c(1, NA, 3), b = c(3, NA, 5)) |>
  mutate(row_average = row_mean(a, b))
#> # A tibble: 3 x 3
#>       a     b row_average
#>   <dbl> <dbl>       <dbl>
#> 1     1     3           2
#> 2    NA    NA          NA
#> 3     3     5           4
```

`cut_quantile()` keeps equal values in the same group. Ties can reduce
the number of intervals, with a warning, rather than splitting equal
values by row order.

## Code of Conduct

Please note that the statart project is released with a [Contributor
Code of
Conduct](https://www.contributor-covenant.org/version/2/0/CODE_OF_CONDUCT.html).
By contributing to this project, you agree to abide by its terms.
