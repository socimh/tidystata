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
such as Stata's `.a`. In a list column, `NA` elements are missing and
`NULL` elements are values, as in
[`summ()`](https://socimh.github.io/tidystata/reference/summ.md) and
[`fre()`](https://socimh.github.io/tidystata/reference/tab.md). Matrix
and data-frame columns follow vctrs row missingness: a row is missing
only when every component is missing. Empty strings are observed values,
unlike Stata's missing string; convert them first with
[`na_if_value()`](https://socimh.github.io/tidystata/reference/na_conversion.md).
When no checked variable has missing values and `.all = FALSE`, a
message says so and the result has no variable rows or columns. Grouping
names must not collide with result columns; rename those keys before
calling `misstable()`.

## See also

Other inspection functions:
[`browse()`](https://socimh.github.io/tidystata/reference/browse.md),
[`codebook()`](https://socimh.github.io/tidystata/reference/codebook.md),
[`names`](https://socimh.github.io/tidystata/reference/names.md),
[`var_type()`](https://socimh.github.io/tidystata/reference/var_type.md),
[`variables()`](https://socimh.github.io/tidystata/reference/variables.md)

## Examples

``` r
misstable(lifeexp)
#> # A tibble: 2 × 4
#>   variable  miss_n miss_pct valid_n
#>   <chr>      <int>    <dbl>   <int>
#> 1 gnppc          1     1.47      67
#> 2 safewater     14    20.6       54
misstable(lifeexp, .all = TRUE)
#> # A tibble: 6 × 4
#>   variable  miss_n miss_pct valid_n
#>   <chr>      <int>    <dbl>   <int>
#> 1 region         0     0         68
#> 2 country        0     0         68
#> 3 popgrowth      0     0         68
#> 4 lexp           0     0         68
#> 5 gnppc          1     1.47      67
#> 6 safewater     14    20.6       54
misstable(lifeexp, .patterns = TRUE)
#> # A tibble: 3 × 4
#>   gnppc safewater     n percent
#>   <int>     <int> <int>   <dbl>
#> 1     1         1    53   77.9 
#> 2     1         0    14   20.6 
#> 3     0         1     1    1.47
misstable(lifeexp, gnppc, safewater, .by = region)
#> # A tibble: 6 × 5
#>   region               variable  miss_n miss_pct valid_n
#>   <dbl+lbl>            <chr>      <int>    <dbl>   <int>
#> 1 1 [Europe & C. Asia] gnppc          1     2.27      43
#> 2 1 [Europe & C. Asia] safewater      2     4.55      42
#> 3 2 [North America]    gnppc          0     0         14
#> 4 2 [North America]    safewater      8    57.1        6
#> 5 3 [South America]    gnppc          0     0         10
#> 6 3 [South America]    safewater      4    40          6
misstable(dplyr::starwars, height, mass, birth_year, .patterns = TRUE)
#> # A tibble: 5 × 5
#>   height  mass birth_year     n percent
#>    <int> <int>      <int> <int>   <dbl>
#> 1      1     1          1    36   41.4 
#> 2      1     1          0    23   26.4 
#> 3      1     0          0    15   17.2 
#> 4      1     0          1     7    8.05
#> 5      0     0          0     6    6.90
```
