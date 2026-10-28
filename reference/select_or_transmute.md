# Select and compute columns

An enhanced
[`dplyr::select()`](https://dplyr.tidyverse.org/reference/select.html)
that also accepts data-masking expressions. As with
[`dplyr::transmute()`](https://dplyr.tidyverse.org/reference/transmute.html),
only the selected and computed columns are returned.

## Usage

``` r
select_or_transmute(.data, ...)
```

## Arguments

- .data:

  A data frame, tibble, or data.table.

- ...:

  \<[`tidy-select`](https://dplyr.tidyverse.org/reference/dplyr_tidy_select.html)\>
  selections or
  \<[`data-masking`](https://rlang.r-lib.org/reference/args_data_masking.html)\>
  expressions. Omit to return the input unchanged.

## Value

A table containing the selected and computed columns in argument order.
Data-frame classes and grouping follow
[`dplyr::select()`](https://dplyr.tidyverse.org/reference/select.html);
a tibble input returns a tibble. Grouping columns are retained. Unnamed
computed columns use their expression as the name.

## Details

**Selecting and computing**

Selections and computations can be mixed; columns follow argument order.
Column names, strings, positions, tidyselect helpers and
[`varlist()`](https://socimh.github.io/tidystata/reference/varlist.md)
select existing columns. Selection syntax includes
[`c()`](https://rdrr.io/r/base/c.html), `:`, `!`, `&`, `|` and unary
`-`. Calls without column names, such as `all_of(vars)` or `seq_len(2)`,
also act as selections.

Other expressions using columns, such as `lexp >= 70` or
`gnp_thousands = gnppc / 1000`, are computed with
[`dplyr::mutate()`](https://dplyr.tidyverse.org/reference/mutate.html)
and then selected. Arithmetic is therefore not interpreted as column
positions. Named constants (`one = 1`, `label = "x"`, `y = c(1, 2)`)
create columns; they do not select or rename existing columns by
position.

**Names and fallback evaluation**

Unnamed names, strings and positions must identify existing columns. An
error lists unmatched names; a misspelling never falls back to a
same-named object in the calling environment. A symbol holding a
character vector is still passed to tidyselect, which deprecates this
use; write `all_of(vars)`.

If selection fails for another reason, such as duplicate output names,
the arguments are retried sequentially with
[`dplyr::transmute()`](https://dplyr.tidyverse.org/reference/transmute.html).
If both attempts fail, the error reports both. Computations run once
when selection succeeds; a fallback can evaluate them again. Grouping
columns follow dplyr's selection rules.

## See also

Other selection and preview functions:
[`varlist()`](https://socimh.github.io/tidystata/reference/varlist.md)

## Examples

``` r
lifeexp |>
  select_or_transmute()
#> # A tibble: 68 × 6
#>    region               country                popgrowth  lexp gnppc safewater
#>    <dbl+lbl>            <chr>                      <dbl> <dbl> <dbl>     <dbl>
#>  1 1 [Europe & C. Asia] Albania                     -0.6    74   870        49
#>  2 1 [Europe & C. Asia] Armenia                     -1.2    70   570        83
#>  3 1 [Europe & C. Asia] Austria                      0.1    78 27810        97
#>  4 1 [Europe & C. Asia] Azerbaijan                   0.9    64   510        49
#>  5 1 [Europe & C. Asia] Belarus                     -0.5    68  1540        82
#>  6 1 [Europe & C. Asia] Belgium                      0.2    77 26530       100
#>  7 1 [Europe & C. Asia] Bosnia and Herzegovina       1.8    74  1230        87
#>  8 1 [Europe & C. Asia] Bulgaria                    -0.7    71  1440        90
#>  9 1 [Europe & C. Asia] Croatia                     -0.1    72    NA        85
#> 10 1 [Europe & C. Asia] Czechia                     -0.1    75  6140        95
#> # ℹ 58 more rows

lifeexp |>
  select_or_transmute(country, lexp)
#> # A tibble: 68 × 2
#>    country                 lexp
#>    <chr>                  <dbl>
#>  1 Albania                   74
#>  2 Armenia                   70
#>  3 Austria                   78
#>  4 Azerbaijan                64
#>  5 Belarus                   68
#>  6 Belgium                   77
#>  7 Bosnia and Herzegovina    74
#>  8 Bulgaria                  71
#>  9 Croatia                   72
#> 10 Czechia                   75
#> # ℹ 58 more rows

# Ordinary select() rejects this computed expression.
try(dplyr::select(lifeexp, lexp >= 70))
#> Error in dplyr::select(lifeexp, lexp >= 70) : 
#>   ℹ In argument: `lexp >= 70`.
#> Caused by error:
#> ! object 'lexp' not found

lifeexp |>
  select_or_transmute(lexp >= 70)
#> # A tibble: 68 × 1
#>    `lexp >= 70`
#>    <lgl>       
#>  1 TRUE        
#>  2 TRUE        
#>  3 TRUE        
#>  4 FALSE       
#>  5 FALSE       
#>  6 TRUE        
#>  7 TRUE        
#>  8 TRUE        
#>  9 TRUE        
#> 10 TRUE        
#> # ℹ 58 more rows
```
