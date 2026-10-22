# Show the variable list of a dataset

- `variables()` works like the "Variables" tab in Stata.

- `variables_search()` searches for variables by name or variable label,
  rather than by the values stored in the columns.

## Usage

``` r
variables(.data, ...)

variables_search(.data, string, ...)
```

## Arguments

- .data:

  The input data frame, tibble, or data.table.

- ...:

  \<[`tidy-select`](https://dplyr.tidyverse.org/reference/dplyr_tidy_select.html)\>
  Existing columns to select or rename before listing or searching. Omit
  to include all columns. Computed columns are not created by this
  argument.

- string:

  A single non-missing character string to search for in names or
  labels. Search is case-insensitive and matches substrings by default.
  An empty string matches all selected variables. Wildcards `*`, `?`,
  and `~` represent zero or more, exactly one, and one or more
  characters, respectively. Use `^` and `$` anchors to require a
  complete name or label match.

## Value

A table with a character `name` column. A character `label` column is
added only when at least one selected variable has a usable label;
unlabelled variables then have `NA` labels. Search returns only matching
rows, in selection order, with the same columns as the selected variable
list. Tables preserve the input's data.frame, tibble, or data.table
container and supported preview settings. Results are ungrouped;
arbitrary subclasses are not reconstructed on the inventory rows.

## Details

Variable labels are read from each column's `label` attribute, including
ordinary vectors without a labelled class. A usable label is a single,
non-missing value that converts to nonempty text. Value-label mappings
and cell values are not searched. Selecting or renaming columns retains
their variable labels; the input data are not modified.

Selection follows
[`dplyr::select()`](https://dplyr.tidyverse.org/reference/select.html).
On grouped data frames, grouping columns are retained and may produce a
message when not explicitly selected. Ungroup first to search only
independently selected columns.

Search patterns are translated before matching. One bracketed letter
range such as `[a-h]`, or ascending nonnegative integer range such as
`[1-12]`, is supported. Multiple bracketed ranges are unsupported.
Numeric ranges are expanded into alternatives, so use unanchored
patterns such as `item[1-12]` for substring matching. This pattern
language is not a general-purpose regular-expression interface; invalid
patterns produce an error.

## See also

[`ds()`](https://socimh.github.io/tidystata/reference/names.md),
[`codebook()`](https://socimh.github.io/tidystata/reference/codebook.md),
[`browse()`](https://socimh.github.io/tidystata/reference/browse.md)

Other inspection functions:
[`browse()`](https://socimh.github.io/tidystata/reference/browse.md),
[`codebook()`](https://socimh.github.io/tidystata/reference/codebook.md),
[`misstable()`](https://socimh.github.io/tidystata/reference/misstable.md),
[`names`](https://socimh.github.io/tidystata/reference/names.md),
[`var_type()`](https://socimh.github.io/tidystata/reference/var_type.md)

## Examples

``` r
variables(lifeexp)
#> # A tibble: 6 × 2
#>   name      label                   
#>   <chr>     <chr>                   
#> 1 region    Region                  
#> 2 country   Country                 
#> 3 popgrowth Avg. annual % growth    
#> 4 lexp      Life expectancy at birth
#> 5 gnppc     GNP per capita          
#> 6 safewater Safe water              
variables_search(lifeexp, "n")
#> # A tibble: 5 × 2
#>   name      label                   
#>   <chr>     <chr>                   
#> 1 region    Region                  
#> 2 country   Country                 
#> 3 popgrowth Avg. annual % growth    
#> 4 lexp      Life expectancy at birth
#> 5 gnppc     GNP per capita          
variables_search(lifeexp, "^country$")
#> # A tibble: 1 × 2
#>   name    label  
#>   <chr>   <chr>  
#> 1 country Country

# Inspect metadata before choosing columns for subsequent analysis.
survey <- tibble::tibble(age = c(30, 45), income = c(2000, 3000))
attr(survey$income, "label") <- "Monthly earnings"
variables(survey, earnings = income, age)
#> # A tibble: 2 × 2
#>   name     label           
#>   <chr>    <chr>           
#> 1 earnings Monthly earnings
#> 2 age      NA              
variables_search(survey, "earn")
#> # A tibble: 1 × 2
#>   name   label           
#>   <chr>  <chr>           
#> 1 income Monthly earnings
```
