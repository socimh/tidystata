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

  A data frame or tibble.

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

Each argument is classified before evaluation. Column names, strings,
numeric positions, selection syntax
([`c()`](https://rdrr.io/r/base/c.html), `:`, `!`, `&`, `|`, unary `-`)
and tidyselect helpers such as
[`starts_with()`](https://tidyselect.r-lib.org/reference/starts_with.html),
[`where()`](https://tidyselect.r-lib.org/reference/where.html),
[`all_of()`](https://tidyselect.r-lib.org/reference/all_of.html) or
[`varlist()`](https://socimh.github.io/tidystata/reference/varlist.md)
select existing columns, as do calls that use no column names (for
example `all_of(vars)` or `seq_len(2)`). Any other expression that uses
columns, such as `lexp >= 70` or `gnp_thousands = gnppc / 1000`, is
computed with
[`dplyr::mutate()`](https://dplyr.tidyverse.org/reference/mutate.html)
and then selected, so arithmetic is never misread as column positions.
Selections and computed values can be mixed; output follows argument
order.

A named constant such as `one = 1`, `label = "x"` or `y = c(1, 2)`
creates a constant column; it never selects or renames columns by
position. Unnamed names, strings and positions must identify existing
columns. If they do not, an error lists every unmatched name instead of
evaluating them as expressions, so a misspelled column is never replaced
by an object of the same name in the calling environment. (A symbol
naming a character vector in the calling environment is still passed to
tidyselect, which deprecates that form in favour of
[`all_of()`](https://tidyselect.r-lib.org/reference/all_of.html).)

If selection itself fails for another reason (for example, duplicate
output names), the arguments are evaluated sequentially with
[`dplyr::transmute()`](https://dplyr.tidyverse.org/reference/transmute.html);
if that also fails, the error reports both attempts. Computed
expressions are evaluated once when selection succeeds. Grouping columns
are retained according to dplyr's selection rules.

## See also

Other selection and preview functions:
[`special-print`](https://socimh.github.io/tidystata/reference/special-print.md),
[`varlist()`](https://socimh.github.io/tidystata/reference/varlist.md)

## Examples

``` r
lifeexp |>
  select_or_transmute()
#> # A tibble: 68 x 6
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
#> # i 58 more rows

lifeexp |>
  select_or_transmute(country, lexp)
#> # A tibble: 68 x 2
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
#> # i 58 more rows

# Ordinary select() rejects this computed expression.
try(dplyr::select(lifeexp, lexp >= 70))
#> Error in dplyr::select(lifeexp, lexp >= 70) : 
#>   i In argument: `lexp >= 70`.
#> Caused by error:
#> ! object 'lexp' not found

lifeexp |>
  select_or_transmute(lexp >= 70)
#> # A tibble: 68 x 1
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
#> # i 58 more rows
```
