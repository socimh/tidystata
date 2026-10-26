# Assert that conditions hold

Check conditions on every row, like Stata's `assert`, and stop with the
number of contradictions when any fails. It returns the data invisibly
when all hold, so it can sit inside a pipeline.

## Usage

``` r
assert(.data, ..., .by = NULL)
```

## Arguments

- .data:

  A data frame, tibble, or data.table.

- ...:

  Conditions evaluated like
  [`dplyr::mutate()`](https://dplyr.tidyverse.org/reference/mutate.html)
  expressions, each giving `TRUE` or `FALSE` per row (or a single
  value). Group functions such as
  [`n()`](https://dplyr.tidyverse.org/reference/context.html) and
  [`mean()`](https://rdrr.io/r/base/mean.html) use the groups of `.data`
  or `.by`.

- .by:

  \<[`tidy-select`](https://dplyr.tidyverse.org/reference/dplyr_tidy_select.html)\>
  Optional grouping variables, like Stata's `by g: assert`.

## Value

`.data`, invisibly, when every condition holds.

## Details

The error lists each failing condition with its number of contradictions
and the first failing rows. A missing result (`NA`) counts as a
contradiction and is reported separately. This differs from Stata, where
a missing value is larger than every number, so `assert x > 0` holds
when `x` is missing; write `is.na(x) | x > 0` for that behaviour.

## See also

Other data checking functions:
[`is_first()`](https://socimh.github.io/tidystata/reference/is_first.md),
[`keys`](https://socimh.github.io/tidystata/reference/keys.md),
[`stata_merge()`](https://socimh.github.io/tidystata/reference/stata_merge.md)

## Examples

``` r
lifeexp |>
  assert(lexp > 0, popgrowth < 10) |>
  summ(lexp)
#> # A tibble: 1 × 7
#>   type      n unique   min  mean    sd   max
#>   <chr> <int>  <int> <dbl> <dbl> <dbl> <dbl>
#> 1 dbl      68     20    57  71.7  5.16    79

# Each country appears once per region
assert(lifeexp, dplyr::n() == dplyr::n_distinct(country), .by = region)

try(assert(lifeexp, safewater > 50))
#> Error in assert(lifeexp, safewater > 50) : Assertion failed:
#> • `safewater > 50`: 25 contradictions (14 missing) in 68 rows; rows 1, 4, 22,
#>   26, 29, ...
```
