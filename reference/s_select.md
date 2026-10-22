# Select and compute columns

An enhanced
[`dplyr::select()`](https://dplyr.tidyverse.org/reference/select.html)
that also accepts data-masking expressions.

## Usage

``` r
s_select(.data, ...)
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

The selected (and computed) columns. Data-frame classes and grouping
follow
[`dplyr::select()`](https://dplyr.tidyverse.org/reference/select.html);
a tibble input returns a tibble.

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
columns, such as `height > 50` or `bmi = mass / height^2`, is computed
with
[`dplyr::mutate()`](https://dplyr.tidyverse.org/reference/mutate.html)
and then selected, so arithmetic on columns is never misread as column
positions. Selections and computed values can be mixed; output follows
argument order. Unnamed computed columns are named by their expression.

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
dplyr::starwars |>
  s_select()
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
dplyr::starwars |>
  s_select(name, height)
#> # A tibble: 87 × 2
#>    name               height
#>    <chr>               <int>
#>  1 Luke Skywalker        172
#>  2 C-3PO                 167
#>  3 R2-D2                  96
#>  4 Darth Vader           202
#>  5 Leia Organa           150
#>  6 Owen Lars             178
#>  7 Beru Whitesun Lars    165
#>  8 R5-D4                  97
#>  9 Biggs Darklighter     183
#> 10 Obi-Wan Kenobi        182
#> # ℹ 77 more rows
# Ordinary select() rejects this computed expression.
try(dplyr::select(dplyr::starwars, height > 50))
#> Error in dplyr::select(dplyr::starwars, height > 50) : 
#>   ℹ In argument: `height > 50`.
#> Caused by error:
#> ! object 'height' not found
dplyr::starwars |>
  s_select(height > 50)
#> # A tibble: 87 × 1
#>    `height > 50`
#>    <lgl>        
#>  1 TRUE         
#>  2 TRUE         
#>  3 TRUE         
#>  4 TRUE         
#>  5 TRUE         
#>  6 TRUE         
#>  7 TRUE         
#>  8 TRUE         
#>  9 TRUE         
#> 10 TRUE         
#> # ℹ 77 more rows
```
