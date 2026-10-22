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
  [`s_select()`](https://socimh.github.io/tidystata/reference/s_select.md).

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
dplyr::starwars
#> # A tibble: 87 × 14
#>    name     height  mass hair_color skin_color eye_color birth_year sex   gender
#>    <chr>     <int> <dbl> <chr>      <chr>      <chr>          <dbl> <chr> <chr> 
#>  1 Luke Sk…    172    77 blond      fair       blue            19   male  mascu…
#>  2 C-3PO       167    75 NA         gold       yellow         112   none  mascu…
#>  3 R2-D2        96    32 NA         white, bl… red             33   none  mascu…
#>  4 Darth V…    202   136 none       white      yellow          41.9 male  mascu…
#>  5 Leia Or…    150    49 brown      light      brown           19   fema… femin…
#>  6 Owen La…    178   120 brown, gr… light      blue            52   male  mascu…
#>  7 Beru Wh…    165    75 brown      light      blue            47   fema… femin…
#>  8 R5-D4        97    32 NA         white, red red             NA   none  mascu…
#>  9 Biggs D…    183    84 black      light      brown           24   male  mascu…
#> 10 Obi-Wan…    182    77 auburn, w… fair       blue-gray       57   male  mascu…
#> # ℹ 77 more rows
#> # ℹ 5 more variables: homeworld <chr>, species <chr>, films <list>,
#> #   vehicles <list>, starships <list>

codebook(dplyr::starwars)
#> # A tibble: 14 × 4
#>    variable   type          n unique
#>    <chr>      <chr>     <int>  <int>
#>  1 name       character    87     87
#>  2 height     integer      81     45
#>  3 mass       double       59     38
#>  4 hair_color character    82     11
#>  5 skin_color character    87     31
#>  6 eye_color  character    87     15
#>  7 birth_year double       43     36
#>  8 sex        character    83      4
#>  9 gender     character    83      2
#> 10 homeworld  character    77     48
#> 11 species    character    83     37
#> 12 films      list         87     24
#> 13 vehicles   list         87     11
#> 14 starships  list         87     16

codebook(dplyr::starwars, 1:4)
#> # A tibble: 4 × 4
#>   variable   type          n unique
#>   <chr>      <chr>     <int>  <int>
#> 1 name       character    87     87
#> 2 height     integer      81     45
#> 3 mass       double       59     38
#> 4 hair_color character    82     11

codebook(dplyr::starwars, ends_with("color"))
#> # A tibble: 3 × 4
#>   variable   type          n unique
#>   <chr>      <chr>     <int>  <int>
#> 1 hair_color character    82     11
#> 2 skin_color character    87     31
#> 3 eye_color  character    87     15

codebook(dplyr::starwars, where(is.numeric))
#> # A tibble: 3 × 4
#>   variable   type        n unique
#>   <chr>      <chr>   <int>  <int>
#> 1 height     integer    81     45
#> 2 mass       double     59     38
#> 3 birth_year double     43     36

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
