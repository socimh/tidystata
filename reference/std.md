# Standardise a variable or scale it to a percentage

Vector helpers for
[`dplyr::mutate()`](https://dplyr.tidyverse.org/reference/mutate.html),
following Stata's `egen`:

- `std()`: Standardise to mean 0 and standard deviation 1, like
  `egen z = std(x)`. Unlike
  [`scale()`](https://rdrr.io/r/base/scale.html), it returns a plain
  vector.

- `pc()`: Express each value as a percentage of the total, like
  `egen p = pc(x)`, or as a proportion with `prop = TRUE`.

## Usage

``` r
std(x, mean = 0, sd = 1)

pc(x, prop = FALSE)
```

## Arguments

- x:

  A numeric or logical vector. Labelled numeric vectors are used through
  their codes.

- mean, sd:

  For `std()`, finite numeric scalars giving the target mean (default 0)
  and signed scale multiplier (default 1), like Stata's
  `egen std(x), mean() std()` options. The result has standard deviation
  `abs(sd)`; a negative `sd` reverses the ordering and zero makes all
  observed values equal to `mean` when the input spread is defined.

- prop:

  If `TRUE`, `pc()` returns proportions (summing to 1) instead of
  percentages (summing to 100). Defaults to `FALSE`.

## Value

A double vector with the length and order of `x`. Input classes, names,
and labels are dropped; tagged and SPSS user-missing values are treated
as missing. Missing inputs remain missing. `std()` returns all `NA` when
the standard deviation is zero or undefined (fewer than two observed
values), and `pc()` when the total is zero or infinite, as Stata gives
missing values there.

## Details

By default, `std(x)` computes
`(x - mean(x, na.rm = TRUE)) / sd(x, na.rm = TRUE)` using the sample
standard deviation. `pc(x)` computes `100 * x / sum(x, na.rm = TRUE)`,
not percentile ranks. Use
[`dplyr::percent_rank()`](https://dplyr.tidyverse.org/reference/percent_rank.html)
for ranks on a 0-1 scale, or multiply them by 100 for a 0-100 scale. In
grouped
[`dplyr::mutate()`](https://dplyr.tidyverse.org/reference/mutate.html)
(or with `.by`), the mean, standard deviation and total come from each
group, like Stata's `by g: egen`.

## See also

Other variable generation functions:
[`as_dummy()`](https://socimh.github.io/tidystata/reference/as_dummy.md),
[`cut_quantile()`](https://socimh.github.io/tidystata/reference/cut.md),
[`panel`](https://socimh.github.io/tidystata/reference/panel.md),
[`row_egen`](https://socimh.github.io/tidystata/reference/row_egen.md),
[`stata_recode()`](https://socimh.github.io/tidystata/reference/stata_recode.md)

## Examples

``` r
std(c(1, 2, 3, NA))
#> [1] -1  0  1 NA

pc(c(2, 3, 5))
#> [1] 20 30 50

pc(c(2, 3, 5), prop = TRUE)
#> [1] 0.2 0.3 0.5

lifeexp |>
  dplyr::mutate(
    z = std(lexp),
    share = pc(popgrowth),
    .by = region
  )
#> # A tibble: 68 × 8
#>    region               country    popgrowth  lexp gnppc safewater      z  share
#>    <dbl+lbl>            <chr>          <dbl> <dbl> <dbl>     <dbl>  <dbl>  <dbl>
#>  1 1 [Europe & C. Asia] Albania         -0.6    74   870        49  0.303 -19.4 
#>  2 1 [Europe & C. Asia] Armenia         -1.2    70   570        83 -0.505 -38.7 
#>  3 1 [Europe & C. Asia] Austria          0.1    78 27810        97  1.11    3.23
#>  4 1 [Europe & C. Asia] Azerbaijan       0.9    64   510        49 -1.72   29.0 
#>  5 1 [Europe & C. Asia] Belarus         -0.5    68  1540        82 -0.909 -16.1 
#>  6 1 [Europe & C. Asia] Belgium          0.2    77 26530       100  0.909   6.45
#>  7 1 [Europe & C. Asia] Bosnia an…       1.8    74  1230        87  0.303  58.1 
#>  8 1 [Europe & C. Asia] Bulgaria        -0.7    71  1440        90 -0.303 -22.6 
#>  9 1 [Europe & C. Asia] Croatia         -0.1    72    NA        85 -0.101  -3.23
#> 10 1 [Europe & C. Asia] Czechia         -0.1    75  6140        95  0.505  -3.23
#> # ℹ 58 more rows
```
