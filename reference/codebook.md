# View the codebook of a dataset or selected columns

Inspect the types, observed counts, distinct observed values, and
variable labels of a dataset or selected columns.

## Usage

``` r
codebook(.data, ...)
```

## Arguments

- .data:

  The input data (data frame, tibble, or data.table).

- ...:

  \<[`tidy-select`](https://dplyr.tidyverse.org/reference/dplyr_tidy_select.html)\>
  or
  \<[`data-masking`](https://rlang.r-lib.org/reference/args_data_masking.html)\>
  Variables to include in the codebook. Omit to include all columns.
  Selection is attempted first; expressions that are not valid
  selections are evaluated as computed columns by
  [`select_or_transmute()`](https://socimh.github.io/tidystata/reference/select_or_transmute.md).

## Value

An ungrouped table with one row per selected variable, in selection
order. Columns are `variable`, optional `label`, `type`, `n`, and
`unique`. `n` counts observed values and `unique` counts distinct
observed values. Empty and all-missing columns have zero counts. A
zero-column selection returns zero rows with `variable`, `type`, `n`,
and `unique` columns. The input's data.frame, tibble, or data.table
container and supported preview settings are preserved. Other subclasses
are not reconstructed.

## Details

Counts describe the complete input, irrespective of existing grouping.
Data are ungrouped before selection, so omitted grouping keys are not
reinserted. With no selection, grouping-key columns are included like
other columns. The input data are not modified.

Missingness is determined on the original column before counting.
Ordinary missing values, `NaN`, tagged missing values and SPSS
user-missing codes or ranges are excluded. List columns are counted by
element identity without flattening: scalar missing elements are
excluded, while `NULL` and empty elements remain observed values. Matrix
and nested data-frame columns count complete rows as observations; a row
with any missing cell is excluded.

Units are appended to `type` when available. Variable labels are read
from each column's `label` attribute, not its value-label mapping. The
`label` column appears only when at least one selected variable has a
usable label; unlabelled variables then have `NA` labels.

## See also

[`ds()`](https://socimh.github.io/tidystata/reference/names.md),
[`variables()`](https://socimh.github.io/tidystata/reference/variables.md),
[`browse()`](https://socimh.github.io/tidystata/reference/browse.md)

Other inspection functions:
[`browse()`](https://socimh.github.io/tidystata/reference/browse.md),
[`misstable()`](https://socimh.github.io/tidystata/reference/misstable.md),
[`names`](https://socimh.github.io/tidystata/reference/names.md),
[`var_type()`](https://socimh.github.io/tidystata/reference/var_type.md),
[`variables()`](https://socimh.github.io/tidystata/reference/variables.md)

## Examples

``` r
codebook(lifeexp)
#> # A tibble: 6 × 5
#>   variable  label                    type             n unique
#>   <chr>     <chr>                    <chr>        <int>  <int>
#> 1 region    Region                   double+label    68      3
#> 2 country   Country                  character       68     68
#> 3 popgrowth Avg. annual % growth     double          68     32
#> 4 lexp      Life expectancy at birth double          68     20
#> 5 gnppc     GNP per capita           double          67     64
#> 6 safewater Safe water               double          54     32

codebook(lifeexp, 1:4)
#> # A tibble: 4 × 5
#>   variable  label                    type             n unique
#>   <chr>     <chr>                    <chr>        <int>  <int>
#> 1 region    Region                   double+label    68      3
#> 2 country   Country                  character       68     68
#> 3 popgrowth Avg. annual % growth     double          68     32
#> 4 lexp      Life expectancy at birth double          68     20

codebook(lifeexp, where(is.numeric))
#> # A tibble: 5 × 5
#>   variable  label                    type             n unique
#>   <chr>     <chr>                    <chr>        <int>  <int>
#> 1 region    Region                   double+label    68      3
#> 2 popgrowth Avg. annual % growth     double          68     32
#> 3 lexp      Life expectancy at birth double          68     20
#> 4 gnppc     GNP per capita           double          67     64
#> 5 safewater Safe water               double          54     32

starwars <- dplyr::starwars

codebook(starwars, films:starships)
#> # A tibble: 3 × 4
#>   variable  type      n unique
#>   <chr>     <chr> <int>  <int>
#> 1 films     list     87     24
#> 2 vehicles  list     87     11
#> 3 starships list     87     16

codebook(starwars, ends_with("color"))
#> # A tibble: 3 × 4
#>   variable   type          n unique
#>   <chr>      <chr>     <int>  <int>
#> 1 hair_color character    82     11
#> 2 skin_color character    87     31
#> 3 eye_color  character    87     15

# Save a compact inventory before preparing an analysis sample.
survey <- tibble::tibble(age = c(30, NA, 45), income = c(2000, 3000, 4000))
attr(survey$income, "label") <- "Monthly earnings"
inventory <- codebook(survey, age, income)
inventory
#> # A tibble: 2 × 5
#>   variable label            type       n unique
#>   <chr>    <chr>            <chr>  <int>  <int>
#> 1 age      NA               double     2      2
#> 2 income   Monthly earnings double     3      3
codebook(survey, income_thousands = income / 1000)
#> # A tibble: 1 × 5
#>   variable         label            type       n unique
#>   <chr>            <chr>            <chr>  <int>  <int>
#> 1 income_thousands Monthly earnings double     3      3
```
