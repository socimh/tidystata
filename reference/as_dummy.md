# Create indicator (dummy) variables

Expand categorical variables into indicator columns, like Stata's
`tabulate x, generate(x_)`:

- `as_dummy()` (`tab_gen()`): Add one 0/1 column per observed category
  of each selected variable, immediately after its source variable.

## Usage

``` r
as_dummy(.data, ..., .names = c("value", "label", "index"), .remove = FALSE)

tab_gen(.data, ..., .names = c("value", "label", "index"), .remove = FALSE)
```

## Arguments

- .data:

  A data frame, tibble, or data.table.

- ...:

  \<[`tidy-select`](https://dplyr.tidyverse.org/reference/dplyr_tidy_select.html)\>
  The categorical variables to expand. Select at least one existing
  column; renaming, computed columns, list columns, and matrix columns
  are not supported.

- .names:

  How to name the new columns: `"value"` (default) appends the original
  value (the code for labelled vectors); `"label"` appends its value
  label, falling back to the original value when no label is available;
  `"index"` numbers the observed categories from 1, like Stata's
  `generate()` option. Factor values use their level text in both
  `"value"` and `"label"` modes.

- .remove:

  If `TRUE`, drop the source variables. Defaults to `FALSE`.

## Value

`.data` with integer indicator columns, keeping its data.frame, tibble,
data.table, grouped or sf container and the original rows. Each
indicator is `1` for its category, `0` otherwise, and `NA` for missing
source values. New columns have a `"label"` attribute such as
`"sex==male"`; for labelled vectors, this uses the value label.

## Details

Categories are determined across the whole input, regardless of
grouping. Existing groups are retained in the result, and the input is
not modified.

Categories are the observed, non-missing values: factor levels in level
order (unused levels are skipped), and other values in ascending order.
For labelled vectors, `.names = "value"` uses the codes, such as
`region_1`; `.names = "label"` uses value labels, such as
`region_Europe & C. Asia`. Label text is used as is, so names may
require backticks when referenced. Naming does not change the categories
or the indicators' label attributes. Missing values include tagged and
SPSS user-missing values. A selected column with no observed categories
adds no indicators. New names must not collide with retained columns;
source names may be reused when `.remove = TRUE`. Grouping keys cannot
be removed. A positive-row data.table result must retain at least one
column: if selected variables have no observed categories, retain a
source variable or an identifier column. For model formulas, R's factors
already expand to dummies; use `as_dummy()` when the indicator columns
themselves are needed.

## See also

Other variable generation functions:
[`cut_quantile()`](https://socimh.github.io/tidystata/reference/cut.md),
[`panel`](https://socimh.github.io/tidystata/reference/panel.md),
[`row_egen`](https://socimh.github.io/tidystata/reference/row_egen.md),
[`stata_recode()`](https://socimh.github.io/tidystata/reference/stata_recode.md),
[`std()`](https://socimh.github.io/tidystata/reference/std.md)

## Examples

``` r
as_dummy(lifeexp, region)
#> # A tibble: 68 × 9
#>    region     region_1 region_2 region_3 country popgrowth  lexp gnppc safewater
#>    <dbl+lbl>     <int>    <int>    <int> <chr>       <dbl> <dbl> <dbl>     <dbl>
#>  1 1 [Europe…        1        0        0 Albania      -0.6    74   870        49
#>  2 1 [Europe…        1        0        0 Armenia      -1.2    70   570        83
#>  3 1 [Europe…        1        0        0 Austria       0.1    78 27810        97
#>  4 1 [Europe…        1        0        0 Azerba…       0.9    64   510        49
#>  5 1 [Europe…        1        0        0 Belarus      -0.5    68  1540        82
#>  6 1 [Europe…        1        0        0 Belgium       0.2    77 26530       100
#>  7 1 [Europe…        1        0        0 Bosnia…       1.8    74  1230        87
#>  8 1 [Europe…        1        0        0 Bulgar…      -0.7    71  1440        90
#>  9 1 [Europe…        1        0        0 Croatia      -0.1    72    NA        85
#> 10 1 [Europe…        1        0        0 Czechia      -0.1    75  6140        95
#> # ℹ 58 more rows

as_dummy(lifeexp, region, .remove = TRUE)
#> # A tibble: 68 × 8
#>    region_1 region_2 region_3 country            popgrowth  lexp gnppc safewater
#>       <int>    <int>    <int> <chr>                  <dbl> <dbl> <dbl>     <dbl>
#>  1        1        0        0 Albania                 -0.6    74   870        49
#>  2        1        0        0 Armenia                 -1.2    70   570        83
#>  3        1        0        0 Austria                  0.1    78 27810        97
#>  4        1        0        0 Azerbaijan               0.9    64   510        49
#>  5        1        0        0 Belarus                 -0.5    68  1540        82
#>  6        1        0        0 Belgium                  0.2    77 26530       100
#>  7        1        0        0 Bosnia and Herzeg…       1.8    74  1230        87
#>  8        1        0        0 Bulgaria                -0.7    71  1440        90
#>  9        1        0        0 Croatia                 -0.1    72    NA        85
#> 10        1        0        0 Czechia                 -0.1    75  6140        95
#> # ℹ 58 more rows

as_dummy(lifeexp, region, .names = "label")
#> # A tibble: 68 × 9
#>    region   region_Europe & C. A…¹ `region_North America` `region_South America`
#>    <dbl+lb>                  <int>                  <int>                  <int>
#>  1 1 [Euro…                      1                      0                      0
#>  2 1 [Euro…                      1                      0                      0
#>  3 1 [Euro…                      1                      0                      0
#>  4 1 [Euro…                      1                      0                      0
#>  5 1 [Euro…                      1                      0                      0
#>  6 1 [Euro…                      1                      0                      0
#>  7 1 [Euro…                      1                      0                      0
#>  8 1 [Euro…                      1                      0                      0
#>  9 1 [Euro…                      1                      0                      0
#> 10 1 [Euro…                      1                      0                      0
#> # ℹ 58 more rows
#> # ℹ abbreviated name: ¹​`region_Europe & C. Asia`
#> # ℹ 5 more variables: country <chr>, popgrowth <dbl>, lexp <dbl>, gnppc <dbl>,
#> #   safewater <dbl>
```
