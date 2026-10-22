# Flag the first row of each group

`is_first()` is `TRUE` for the first row of each distinct combination of
its arguments and `FALSE` for the others, like Stata's
`egen t = tag(id year)`. Use it in
[`dplyr::mutate()`](https://dplyr.tidyverse.org/reference/mutate.html)
or
[`dplyr::filter()`](https://dplyr.tidyverse.org/reference/filter.html),
for example to count or summarise each group once.

Unlike
[`duplicates_tag()`](https://socimh.github.io/tidystata/reference/keys.md),
which counts the other rows sharing the same values, `is_first()` marks
one row per group. `s_tag()` is an alias of `is_first()`.

## Usage

``` r
is_first(..., .missing = FALSE)

s_tag(..., .missing = FALSE)
```

## Arguments

- ...:

  Vectors of equal length that define the groups. Omit them in grouped
  [`dplyr::mutate()`](https://dplyr.tidyverse.org/reference/mutate.html)
  (or with `.by`) to flag the first row of each group.

- .missing:

  A single `TRUE` or `FALSE`. If `FALSE` (default), rows with a missing
  value in any argument are `FALSE`, as Stata's `tag()` does without its
  `missing` option. If `TRUE`, missing values form groups of their own.

## Value

A logical vector. "First" follows the current row order, so sort first
when a particular row should be flagged.

## See also

Other data checking functions:
[`assert()`](https://socimh.github.io/tidystata/reference/assert.md),
[`keys`](https://socimh.github.io/tidystata/reference/keys.md),
[`s_merge()`](https://socimh.github.io/tidystata/reference/s_merge.md)

## Examples

``` r
panel <- tibble::tibble(
  id = c(1, 1, 2, 2, 2, NA),
  year = c(2001, 2002, 2001, 2002, 2003, 2001)
)
dplyr::mutate(panel, first = is_first(id))
#> # A tibble: 6 × 3
#>      id  year first
#>   <dbl> <dbl> <lgl>
#> 1     1  2001 TRUE 
#> 2     1  2002 FALSE
#> 3     2  2001 TRUE 
#> 4     2  2002 FALSE
#> 5     2  2003 FALSE
#> 6    NA  2001 FALSE

# Count panels, like Stata's egen tag() followed by count if tag
sum(is_first(panel$id))
#> [1] 2

# First row within each group
dplyr::mutate(panel, first = is_first(), .by = id)
#> # A tibble: 6 × 3
#>      id  year first
#>   <dbl> <dbl> <lgl>
#> 1     1  2001 TRUE 
#> 2     1  2002 FALSE
#> 3     2  2001 TRUE 
#> 4     2  2002 FALSE
#> 5     2  2003 FALSE
#> 6    NA  2001 TRUE 
```
