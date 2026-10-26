# Inspect a dataset's codebook

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
  Columns to select or compute with
  [`select_or_transmute()`](https://socimh.github.io/tidystata/reference/select_or_transmute.md).
  Existing columns, selection helpers, and named expressions can be
  mixed. Omit to include all columns.

## Value

An ungrouped table with one row per selected variable, in selection
order, and columns `variable`, `type`, `n` (observed values), and
`unique` (distinct observed values). A `label` column is included when
labels are available. Empty or entirely missing columns have zero
counts; selecting no columns returns zero rows with `variable`, `type`,
`n`, and `unique` columns. The input's data.frame, tibble, or data.table
container and supported preview settings are preserved; other subclasses
are not reconstructed.

## Details

**Counting**

- Counts ignore existing groups. Data are ungrouped before selection, so
  grouping columns can be omitted. The input data remain unchanged.

- Missing values, including `NaN`, tagged missing values, and SPSS
  user-missing values, are excluded.

- List columns count distinct elements without flattening; `NULL` and
  empty elements are included. Matrix and nested data-frame columns
  count complete rows, excluding rows with missing cells.

**Labels and types**

- Variable labels come from the `label` attribute, not value labels.
  Unlabelled variables receive `NA` when a label column is present.

- Units are appended to `type` when available.

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
# All variables
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

# Selected variables
codebook(lifeexp, 1:4)
#> # A tibble: 4 x 5
#>   variable  label                    type             n unique
#>   <chr>     <chr>                    <chr>        <int>  <int>
#> 1 region    Region                   double+label    68      3
#> 2 country   Country                  character       68     68
#> 3 popgrowth Avg. annual % growth     double          68     32
#> 4 lexp      Life expectancy at birth double          68     20

codebook(lifeexp, where(is.numeric))
#> # A tibble: 5 x 5
#>   variable  label                    type             n unique
#>   <chr>     <chr>                    <chr>        <int>  <int>
#> 1 region    Region                   double+label    68      3
#> 2 popgrowth Avg. annual % growth     double          68     32
#> 3 lexp      Life expectancy at birth double          68     20
#> 4 gnppc     GNP per capita           double          67     64
#> 5 safewater Safe water               double          54     32

# Inspect an existing column alongside a computed column
codebook(lifeexp, country, gnppc_thousands = gnppc / 1000)
#> # A tibble: 2 x 5
#>   variable        label          type          n unique
#>   <chr>           <chr>          <chr>     <int>  <int>
#> 1 country         Country        character    68     68
#> 2 gnppc_thousands GNP per capita double       67     64

starwars <- dplyr::starwars
codebook(starwars, films:starships)
#> # A tibble: 3 x 4
#>   variable  type      n unique
#>   <chr>     <chr> <int>  <int>
#> 1 films     list     87     24
#> 2 vehicles  list     87     11
#> 3 starships list     87     16

codebook(starwars, ends_with("color"))
#> # A tibble: 3 x 4
#>   variable   type          n unique
#>   <chr>      <chr>     <int>  <int>
#> 1 hair_color character    82     11
#> 2 skin_color character    87     31
#> 3 eye_color  character    87     15
```
