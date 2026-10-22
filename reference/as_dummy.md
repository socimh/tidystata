# Create indicator (dummy) variables

Adds one 0/1 column per observed category of each selected variable,
like Stata's `tabulate x, generate(x_)`. The new columns are placed
right after their source variable. `tab_gen()` is an alias of
`as_dummy()`.

## Usage

``` r
as_dummy(.data, ..., .names = c("value", "index"), .remove = FALSE)

tab_gen(.data, ..., .names = c("value", "index"), .remove = FALSE)
```

## Arguments

- .data:

  A data frame, tibble, or data.table.

- ...:

  \<[`tidy-select`](https://dplyr.tidyverse.org/reference/dplyr_tidy_select.html)\>
  The categorical variables to expand.

- .names:

  How to name the new columns: `"value"` (default) appends the category,
  as in `sex_male`; `"index"` numbers the categories, as in `sex_1`,
  like Stata's `generate()` option.

- .remove:

  A single `TRUE` or `FALSE`. If `TRUE`, drop the source variables.

## Value

`.data` with integer indicator columns, keeping its data.frame, tibble,
data.table, grouped or sf container. Each indicator is `1` when the row
has that category, `0` otherwise, and `NA` when the source value is
missing, as in Stata. Each new column has a `"label"` attribute such as
`"sex==male"`, as Stata's variable labels do; for labelled vectors the
label uses the value label.

## Details

Categories are the observed, non-missing values: factor levels in level
order (unused levels are skipped), and other values in ascending order.
For labelled vectors, `.names = "value"` uses the codes, such as
`region_1`. New names must not already exist in `.data`, and grouping
keys cannot be removed. For model formulas, R's factors already expand
to dummies; use `as_dummy()` when the indicator columns themselves are
needed.

## See also

Other variable generation functions:
[`cut`](https://socimh.github.io/tidystata/reference/cut.md),
[`panel`](https://socimh.github.io/tidystata/reference/panel.md),
[`row_egen`](https://socimh.github.io/tidystata/reference/row_egen.md),
[`std()`](https://socimh.github.io/tidystata/reference/std.md)

## Examples

``` r
as_dummy(dplyr::starwars, sex)
#> # A tibble: 87 × 18
#>    name            height  mass hair_color skin_color eye_color birth_year sex  
#>    <chr>            <int> <dbl> <chr>      <chr>      <chr>          <dbl> <chr>
#>  1 Luke Skywalker     172    77 blond      fair       blue            19   male 
#>  2 C-3PO              167    75 NA         gold       yellow         112   none 
#>  3 R2-D2               96    32 NA         white, bl… red             33   none 
#>  4 Darth Vader        202   136 none       white      yellow          41.9 male 
#>  5 Leia Organa        150    49 brown      light      brown           19   fema…
#>  6 Owen Lars          178   120 brown, gr… light      blue            52   male 
#>  7 Beru Whitesun …    165    75 brown      light      blue            47   fema…
#>  8 R5-D4               97    32 NA         white, red red             NA   none 
#>  9 Biggs Darkligh…    183    84 black      light      brown           24   male 
#> 10 Obi-Wan Kenobi     182    77 auburn, w… fair       blue-gray       57   male 
#> # ℹ 77 more rows
#> # ℹ 10 more variables: sex_female <int>, sex_hermaphroditic <int>,
#> #   sex_male <int>, sex_none <int>, gender <chr>, homeworld <chr>,
#> #   species <chr>, films <list>, vehicles <list>, starships <list>
as_dummy(dplyr::starwars, sex, .names = "index", .remove = TRUE)
#> # A tibble: 87 × 17
#>    name      height  mass hair_color skin_color eye_color birth_year sex_1 sex_2
#>    <chr>      <int> <dbl> <chr>      <chr>      <chr>          <dbl> <int> <int>
#>  1 Luke Sky…    172    77 blond      fair       blue            19       0     0
#>  2 C-3PO        167    75 NA         gold       yellow         112       0     0
#>  3 R2-D2         96    32 NA         white, bl… red             33       0     0
#>  4 Darth Va…    202   136 none       white      yellow          41.9     0     0
#>  5 Leia Org…    150    49 brown      light      brown           19       1     0
#>  6 Owen Lars    178   120 brown, gr… light      blue            52       0     0
#>  7 Beru Whi…    165    75 brown      light      blue            47       1     0
#>  8 R5-D4         97    32 NA         white, red red             NA       0     0
#>  9 Biggs Da…    183    84 black      light      brown           24       0     0
#> 10 Obi-Wan …    182    77 auburn, w… fair       blue-gray       57       0     0
#> # ℹ 77 more rows
#> # ℹ 8 more variables: sex_3 <int>, sex_4 <int>, gender <chr>, homeworld <chr>,
#> #   species <chr>, films <list>, vehicles <list>, starships <list>
as_dummy(lifeexp, region)
#> # A tibble: 68 × 9
#>    region     region_1 region_2 region_3 country popgrowth  lexp gnppc safewater
#>    <dbl+lbl>     <int>    <int>    <int> <chr>       <dbl> <dbl> <dbl>     <dbl>
#>  1 1 [Europe…        1        0        0 Albania      -0.6    74   870        49
#>  2 1 [Europe…        1        0        0 Armenia      -1.2    70   570        83
#>  3 1 [Europe…        1        0        0 Austria       0.1    78 27810        97
#>  4 1 [Europe…        1        0        0 Azerba…       0.9    64   510        49
#>  5 1 [Europe…        1        0        0 Belarus      -0.5    68  1540        82
#>  6 1 [Europe…        1        0        0 Belgium       0.2    77 26530       100
#>  7 1 [Europe…        1        0        0 Bosnia…       1.8    74  1230        87
#>  8 1 [Europe…        1        0        0 Bulgar…      -0.7    71  1440        90
#>  9 1 [Europe…        1        0        0 Croatia      -0.1    72    NA        85
#> 10 1 [Europe…        1        0        0 Czechia      -0.1    75  6140        95
#> # ℹ 58 more rows
```
