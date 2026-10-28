# Flag the first row of each group

`is_first()` is `TRUE` for the first row of each distinct combination of
its arguments and `FALSE` for the others, like Stata's
`egen t = tag(id year)`. Use it in
[`dplyr::mutate()`](https://dplyr.tidyverse.org/reference/mutate.html)
or
[`dplyr::filter()`](https://dplyr.tidyverse.org/reference/filter.html),
for example to count or summarise each group once.

## Usage

``` r
is_first(..., .missing = FALSE)
```

## Arguments

- ...:

  Vectors of equal length that define the groups. Omit them in grouped
  [`dplyr::mutate()`](https://dplyr.tidyverse.org/reference/mutate.html)
  (or with `.by`) to flag the first row of each group.

- .missing:

  If `FALSE` (default), rows with a missing value in any explicitly
  supplied argument are `FALSE`, as Stata's `tag()` does without its
  `missing` option. If `TRUE`, missing values form groups of their own.
  With no arguments, flag the first row of every current data-mask
  group, including groups with missing keys, regardless of `.missing`.

## Value

A logical vector with one value per input row, or per row in the current
data-mask group when no arguments are supplied.

## Details

"First" follows the current row order. Unlike
[`duplicates_tag()`](https://socimh.github.io/tidystata/reference/keys.md),
which counts the other rows sharing the same values, `is_first()` marks
one row per group. Missing values include tagged and SPSS user-missing
values.

## See also

Other data checking functions:
[`assert()`](https://socimh.github.io/tidystata/reference/assert.md),
[`keys`](https://socimh.github.io/tidystata/reference/keys.md),
[`stata_merge()`](https://socimh.github.io/tidystata/reference/stata_merge.md)

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

# Including the missing group
dplyr::mutate(panel, first = is_first(id, .missing = TRUE))
#> # A tibble: 6 × 3
#>      id  year first
#>   <dbl> <dbl> <lgl>
#> 1     1  2001 TRUE 
#> 2     1  2002 FALSE
#> 3     2  2001 TRUE 
#> 4     2  2002 FALSE
#> 5     2  2003 FALSE
#> 6    NA  2001 TRUE 

# The no-argument shortcut also includes the missing id group
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

# Count panels
is_first(panel$id) |> sum()
#> [1] 2
```
