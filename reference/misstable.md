# Tabulate missing values

Missing-value summaries, like Stata's `misstable`.

- By default, `misstable()` counts the missing values of each variable,
  like `misstable summarize`.

- With `.patterns = TRUE`, it counts the combinations of observed and
  missing variables across rows, like `misstable patterns`.

## Usage

``` r
misstable(.data, ..., .by = NULL, .patterns = FALSE, .all = FALSE)
```

## Arguments

- .data:

  A data frame, tibble, or data.table.

- ...:

  \<[`tidy-select`](https://dplyr.tidyverse.org/reference/dplyr_tidy_select.html)\>
  Variables to check. Omit to check every column except grouping keys.

- .by:

  \<[`tidy-select`](https://dplyr.tidyverse.org/reference/dplyr_tidy_select.html)\>
  Optional grouping variables. Grouped data use their groups unless
  `.by` is supplied.

- .patterns:

  A single `TRUE` or `FALSE`. If `TRUE`, tabulate missing patterns
  instead of counting by variable.

- .all:

  A single `TRUE` or `FALSE`. If `FALSE` (default), only variables with
  at least one missing value are shown, as in Stata; if `TRUE`, all
  checked variables are shown.

## Value

By default, a tibble with any grouping keys, `variable`, `miss_n`
(missing values), `miss_pct` (percentage of rows, from zero to 100) and
`valid_n` (observed values), one row per variable (and group).

With `.patterns = TRUE`, a tibble with any grouping keys, one column per
variable holding `1` (observed) or `0` (missing) as in Stata, `n` (rows
with that pattern) and `percent` (of the rows in the group). Patterns
are sorted by decreasing frequency within each group, so the first row
is usually the complete cases.

## Details

A value is missing when [`is.na()`](https://rdrr.io/r/base/NA.html) is
`TRUE` for it, which includes `NaN` and haven's tagged missing values
such as Stata's `.a`. Empty strings are observed values, unlike Stata's
missing string; convert them first with
[`na_if_value()`](https://socimh.github.io/tidystata/reference/na_conversion.md).
When no checked variable has missing values and `.all = FALSE`, a
message says so and the result has no variable rows or columns.

## See also

Other inspection functions:
[`browse()`](https://socimh.github.io/tidystata/reference/browse.md),
[`codebook()`](https://socimh.github.io/tidystata/reference/codebook.md),
[`names`](https://socimh.github.io/tidystata/reference/names.md),
[`var_type()`](https://socimh.github.io/tidystata/reference/var_type.md),
[`variables()`](https://socimh.github.io/tidystata/reference/variables.md)

## Examples

``` r
misstable(dplyr::starwars)
#> # A tibble: 8 × 4
#>   variable   miss_n miss_pct valid_n
#>   <chr>       <int>    <dbl>   <int>
#> 1 height          6     6.90      81
#> 2 mass           28    32.2       59
#> 3 hair_color      5     5.75      82
#> 4 birth_year     44    50.6       43
#> 5 sex             4     4.60      83
#> 6 gender          4     4.60      83
#> 7 homeworld      10    11.5       77
#> 8 species         4     4.60      83
misstable(dplyr::starwars, .all = TRUE)
#> # A tibble: 14 × 4
#>    variable   miss_n miss_pct valid_n
#>    <chr>       <int>    <dbl>   <int>
#>  1 name            0     0         87
#>  2 height          6     6.90      81
#>  3 mass           28    32.2       59
#>  4 hair_color      5     5.75      82
#>  5 skin_color      0     0         87
#>  6 eye_color       0     0         87
#>  7 birth_year     44    50.6       43
#>  8 sex             4     4.60      83
#>  9 gender          4     4.60      83
#> 10 homeworld      10    11.5       77
#> 11 species         4     4.60      83
#> 12 films           0     0         87
#> 13 vehicles        0     0         87
#> 14 starships       0     0         87
misstable(dplyr::starwars, height, mass, birth_year, .patterns = TRUE)
#> # A tibble: 5 × 5
#>   height  mass birth_year     n percent
#>    <int> <int>      <int> <int>   <dbl>
#> 1      1     1          1    36   41.4 
#> 2      1     1          0    23   26.4 
#> 3      1     0          0    15   17.2 
#> 4      1     0          1     7    8.05
#> 5      0     0          0     6    6.90
misstable(dplyr::starwars, height, mass, .by = sex)
#> # A tibble: 10 × 5
#>    sex            variable miss_n miss_pct valid_n
#>    <chr>          <chr>     <int>    <dbl>   <int>
#>  1 female         height        2     12.5      14
#>  2 female         mass          7     43.8       9
#>  3 hermaphroditic height        0      0         1
#>  4 hermaphroditic mass          0      0         1
#>  5 male           height        3      5        57
#>  6 male           mass         18     30        42
#>  7 none           height        1     16.7       5
#>  8 none           mass          2     33.3       4
#>  9 NA             height        0      0         4
#> 10 NA             mass          1     25         3
```
