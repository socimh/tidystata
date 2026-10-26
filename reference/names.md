# List column names by tidyselect

List column names by tidyselect

## Usage

``` r
ds(.data, ..., .type = c("vector", "table"))
```

## Arguments

- .data:

  A data frame, tibble, or data.table. `ds()` also accepts a character
  vector representing a name inventory, such as an earlier `ds()`
  result. Inventory entries must be unique, nonempty, and nonmissing;
  the vector's own names are ignored. An empty inventory is allowed.

- ...:

  \<[`tidy-select`](https://dplyr.tidyverse.org/reference/dplyr_tidy_select.html)\>
  Existing columns to select or rename. Omit to include all columns.
  Computed columns are not created by this argument.

- .type:

  `"vector"` (the default) returns the names as a character vector, like
  Stata's `ds`; `"table"` returns them as a one-column table.

## Value

`ds()` returns a character vector. `ds(.type = "table")` returns a table
with one character column, `name`, and one row per selected name, in
selection order. On ungrouped data, an empty selection returns a
zero-length vector or zero-row table. Tables preserve the input's
data.frame, tibble, or data.table container and supported preview
settings, without grouping or arbitrary subclasses; character
inventories return a tibble in table mode.

## Details

Selection order and renamed column names follow
[`dplyr::select()`](https://dplyr.tidyverse.org/reference/select.html).
On a grouped data frame, selection retains grouping columns and can emit
a message when they were not explicitly selected. Ungroup first to
select independently of grouping columns. The input data are not
modified. For character inventories, select by names, positions, or name
helpers and rename as usual. Data-type predicates such as
`where(is.numeric)` are not available because an inventory contains no
column data.

## See also

[`variables()`](https://socimh.github.io/tidystata/reference/variables.md),
[`codebook()`](https://socimh.github.io/tidystata/reference/codebook.md),
[`browse()`](https://socimh.github.io/tidystata/reference/browse.md)

Other inspection functions:
[`browse()`](https://socimh.github.io/tidystata/reference/browse.md),
[`codebook()`](https://socimh.github.io/tidystata/reference/codebook.md),
[`misstable()`](https://socimh.github.io/tidystata/reference/misstable.md),
[`var_type()`](https://socimh.github.io/tidystata/reference/var_type.md),
[`variables()`](https://socimh.github.io/tidystata/reference/variables.md)

## Examples

``` r
ds(lifeexp) # equivalent to names(lifeexp)
#> [1] "region"    "country"   "popgrowth" "lexp"      "gnppc"     "safewater"

ds(lifeexp, country:lexp)
#> [1] "country"   "popgrowth" "lexp"     

ds(lifeexp, where(is.character), .type = "table")
#> # A tibble: 1 × 1
#>   name   
#>   <chr>  
#> 1 country

starwars <- dplyr::starwars
ds(starwars, ends_with("color"), .type = "table")
#> # A tibble: 3 × 1
#>   name      
#>   <chr>     
#> 1 hair_color
#> 2 skin_color
#> 3 eye_color 

# Save a programmatic selection for later stages of a pipeline.
numeric_names <- ds(lifeexp, where(is.numeric))
dplyr::select(lifeexp, dplyr::all_of(numeric_names))
#> # A tibble: 68 × 5
#>    region               popgrowth  lexp gnppc safewater
#>    <dbl+lbl>                <dbl> <dbl> <dbl>     <dbl>
#>  1 1 [Europe & C. Asia]      -0.6    74   870        49
#>  2 1 [Europe & C. Asia]      -1.2    70   570        83
#>  3 1 [Europe & C. Asia]       0.1    78 27810        97
#>  4 1 [Europe & C. Asia]       0.9    64   510        49
#>  5 1 [Europe & C. Asia]      -0.5    68  1540        82
#>  6 1 [Europe & C. Asia]       0.2    77 26530       100
#>  7 1 [Europe & C. Asia]       1.8    74  1230        87
#>  8 1 [Europe & C. Asia]      -0.7    71  1440        90
#>  9 1 [Europe & C. Asia]      -0.1    72    NA        85
#> 10 1 [Europe & C. Asia]      -0.1    75  6140        95
#> # ℹ 58 more rows

ds(numeric_names, dplyr::starts_with("pop"))
#> [1] "popgrowth"
```
