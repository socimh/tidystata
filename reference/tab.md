# Tabulate columns

Enhanced [`count()`](https://dplyr.tidyverse.org/reference/count.html).

- `tab()` - Tabulates variable(s) simultaneously, similar to
  [`count()`](https://dplyr.tidyverse.org/reference/count.html).

- `tab1()` - Tabulates variable(s) one by one.

- `tab2()` - Cross-tabulates two variables, like Stata's `tab x y`. With
  three or more variables it returns every pairwise table, like Stata's
  `tab2 x y z`.

Each takes `.total = TRUE` to add "Total" rows (and, for `tab2()`, a
"total" column). `fre()`, `fre1()` and `fre2()` are shortcuts for
`tab(.total = TRUE)`, `tab1(.total = TRUE)` and `tab2(.total = TRUE)`,
named after Stata's `fre`. `xtab()` is an alias of `tab2()`.

The functions return data by default. With totals, rich output is
available from `fre()`, `fre1()` and `fre2()` with `.type = "flextable"`
when the optional flextable package is installed.

## Usage

``` r
tab(
  .data,
  ...,
  .by = NULL,
  .desc = FALSE,
  .group_order = c("keys", "frequency"),
  .total = FALSE,
  .wt = NULL,
  .wt_type = c("frequency", "analytic")
)

tab1(
  .data,
  ...,
  .by = NULL,
  .desc = FALSE,
  .type = c("list", "tibble"),
  .group_order = c("keys", "frequency"),
  .total = FALSE,
  .wt = NULL,
  .wt_type = c("frequency", "analytic")
)

tab2(
  .data,
  ...,
  .by = NULL,
  .flip = FALSE,
  .total = FALSE,
  .type = c("auto", "tibble", "flextable"),
  .wt = NULL,
  .wt_type = c("frequency", "analytic"),
  .chi2 = FALSE
)

xtab(
  .data,
  ...,
  .by = NULL,
  .flip = FALSE,
  .total = FALSE,
  .type = c("auto", "tibble", "flextable"),
  .wt = NULL,
  .wt_type = c("frequency", "analytic"),
  .chi2 = FALSE
)

fre2(
  .data,
  ...,
  .by = NULL,
  .flip = FALSE,
  .type = c("auto", "tibble", "flextable"),
  .wt = NULL,
  .wt_type = c("frequency", "analytic"),
  .chi2 = FALSE
)

fre(
  .data,
  ...,
  .by = NULL,
  .desc = FALSE,
  .type = c("auto", "tibble", "flextable"),
  .group_order = c("keys", "frequency"),
  .wt = NULL,
  .wt_type = c("frequency", "analytic")
)

fre1(
  .data,
  ...,
  .by = NULL,
  .desc = FALSE,
  .type = c("list", "tibble", "flextable"),
  .group_order = c("keys", "frequency"),
  .wt = NULL,
  .wt_type = c("frequency", "analytic")
)
```

## Arguments

- .data:

  An in-memory data frame, tibble, or data.table. Collect lazy tables
  before tabulating. `tab()`, `tab1()`, `fre()` and `fre1()` also accept
  an atomic vector, tabulated as a tibble column named `value`; omit
  selectors and `.by` in this form. `tab2()` needs a data frame. All
  spatial `sfc` geometry columns are excluded before attribute
  tabulation; geometry columns cannot be selected as measured variables
  or grouping keys.

- ...:

  \<[`tidy-select`](https://dplyr.tidyverse.org/reference/dplyr_tidy_select.html)\>
  or
  \<[`data-masking`](https://rlang.r-lib.org/reference/args_data_masking.html)\>
  Variables to tabulate.

  Both tidyselect (e.g.,
  [`starts_with()`](https://tidyselect.r-lib.org/reference/starts_with.html))
  and data masking (e.g., `x_sq = x^2`) are supported. See examples
  below.

- .by:

  Optional grouping columns, selected with tidyselect. For `tab()`,
  `tab1()`, `fre()` and `fre1()`, `NULL` inherits existing
  [`group_by()`](https://dplyr.tidyverse.org/reference/group_by.html)
  groups; an explicit selection replaces them. Grouping columns are not
  measured variables. For `tab2()` and `fre2()`, `.by` returns a list
  with one cross-table per group, named like `"g = a"`, as Stata's
  `by g: tab x y`; grouped data are not split without `.by`. `tab2()`
  does not accept `.desc` or `.group_order`.

- .desc:

  If `TRUE`, sort categories by descending count within each group
  (missing categories stay last). To order the `.by` group blocks by
  size, use `.group_order = "frequency"`.

- .group_order:

  Group block order for one-way and joint tables. `"keys"` retains key
  order; `"frequency"` orders by descending observation count, including
  missing measured values. Missing grouping keys appear last and ties
  follow key order. `.desc` controls categories within each group
  independently.

- .total:

  A single `TRUE` or `FALSE`. If `TRUE`, add "Total" rows:
  `tab(.total = TRUE)` is `fre()` and `tab1(.total = TRUE)` is `fre1()`.
  `tab2(.total = TRUE)` is `fre2()` and adds a total row and a total
  column. Flextable output from `tab2()` requires totals.

- .wt:

  Optional weights: a numeric column of `.data` (or a vector with one
  value per row), like Stata's `[fweight]`/`[aweight]`. Rows with a
  missing weight are excluded with a message; negative weights are an
  error. When `...` is omitted, the weight column is not tabulated
  itself.

- .wt_type:

  `"frequency"` (default) or `"analytic"`. Frequency weights count each
  row `w` times, so `n` is the sum of the weights, as in
  `dplyr::count(wt =)`; non-integer weights are allowed. Analytic
  weights (Stata's `[aweight]`, suitable for sampling weights) are
  rescaled within each `.by` group to sum to the number of rows, so `n`
  stays on the sample scale. Percentages are the same under both types.

- .type:

  Output type. `tab1()` and `fre1()` default to a list of tables;
  `fre()`, `tab2()` and `fre2()` default to `"auto"`, preserving the
  input container. Explicit `"tibble"` always returns a plain tibble.
  Explicit `"flextable"` output requires the optional flextable package.

- .flip:

  A single `TRUE` or `FALSE`. If `TRUE`, swap the rows and columns of
  the cross-table.

- .chi2:

  A single `TRUE` or `FALSE`. If `TRUE`, `tab2()` reports Pearson's
  chi-square test of independence and Cramer's V, like Stata's
  `tab x y, chi2 V`. See Details.

## Value

A table, a list of tables, or an explicitly requested flextable. Default
tables preserve the input's data.frame, tibble, or data.table container,
including each table in a list. Results are ungrouped, with grouping
keys retained as columns where applicable. Supported preview settings
persist unless an explicit output type is requested. Other subclasses
are not reconstructed on these newly shaped tables. Input data are not
modified.

## Details

### Counts and percentages

For `tab()`, `tab1()`, `fre()` and `fre1()`, `n` counts observations.
`percent` and `cum` are percentages from zero to 100 using all
observations within each group; `cum` follows the displayed category
order. `valid` and `valid_cum` use only observations with no missing
measured values. Missing group keys are retained and do not make an
otherwise observed value invalid. Missing measured categories have `NA`
valid percentages and appear last.

### Totals

`fre()` and `fre1()` append a `"Total"` row within each group and may
add `"Valid Total"` and `"Missing Total"` subtotals. In tables with up
to five measured variables, the final measured column is converted to
character to hold these labels; wider tables use a separate `total`
label column. Displayed value labels can coincide for distinct
underlying values, or with an observed `"Total"` category. Counts remain
separate; use `tab()` or `tab1()` when original category values and
types are needed.

### List columns and empty selections

`tab()` counts list-column values by their complete identities without
flattening their contents. Selecting no measured variables returns no
rows: `tab()` and `fre()` retain their count and percentage columns and
any grouping keys; `tab1()` and `fre1()` return an empty list by default
or an empty table with `.type = "tibble"`. `tab2()` returns an empty
table when no variables are selected and errors when only one is. With
three or more, it returns a list of every pairwise table, named like
`"x x y"`, each with the same options. With no selected variables,
`tab2(..., .type = "flextable")` errors because rich cross-tabulation
requires two selected variables.

### Cross-tabulation

Cross-tabulation keeps category names unchanged. Categories may match
the original variable names. Column categories follow their values:
factor levels in order, other types ascending, with missing values last.
A category matching the combined row-header name, or literal `"NA"`
alongside a missing column category, causes a name-collision error. With
`tab2(.total = TRUE)`, the column category `"total"` is reserved for
marginal totals; recode it first or omit the totals. The final row of
`tab2(.total = TRUE)` is the marginal total, labelled `"total"`; an
observed row category with the same label remains a separate row. Blank
column categories use `"<empty>"`, with the smallest unused numeric
suffix when that header is already taken. Logical cross-tabulation axes
follow `FALSE`, `TRUE`, then missing values.

### Chi-square test

With `.chi2 = TRUE`, `tab2()` tests the categories shown in the table,
including missing ones (filter them out first to exclude them), and
drops rows or columns with no observations. It prints Pearson's
chi-square, its degrees of freedom, the p-value and Cramer's V as a
message, and stores them as a one-row tibble in `attr(result, "chi2")`
with columns `statistic`, `df`, `p_value`, `cramers_v` and `n`.
Flextable output adds them as a footer. As in Stata, V keeps its sign in
2 x 2 tables. The test matches `chisq.test(correct = FALSE)`. Frequency
weights are treated as counts; analytic weights are an error, because a
design-based test such as `survey::svychisq()` is needed for sampling
weights.

### Combined output

Combined `tab1()` output uses character values when factor types cannot
be combined; each variable's category order is retained. List output
preserves the original category classes.

If the output tibble has many rows, consider using
[`print()`](https://rdrr.io/r/base/print.html) to display the output.

## See also

Other tabulation functions:
[`pwcorr()`](https://socimh.github.io/tidystata/reference/pwcorr.md)

## Examples

``` r
# tabulate the 8th column
tab(dplyr::starwars, 8)
#> # A tibble: 5 × 6
#>   sex                n percent   cum valid valid_cum
#>   <chr>          <int>   <dbl> <dbl> <dbl>     <dbl>
#> 1 female            16   18.4   18.4 19.3       19.3
#> 2 hermaphroditic     1    1.15  19.5  1.20      20.5
#> 3 male              60   69.0   88.5 72.3       92.8
#> 4 none               6    6.90  95.4  7.23     100  
#> 5 NA                 4    4.60 100   NA         NA  

# tabulate the "sex" column
tab(dplyr::starwars, sex)
#> # A tibble: 5 × 6
#>   sex                n percent   cum valid valid_cum
#>   <chr>          <int>   <dbl> <dbl> <dbl>     <dbl>
#> 1 female            16   18.4   18.4 19.3       19.3
#> 2 hermaphroditic     1    1.15  19.5  1.20      20.5
#> 3 male              60   69.0   88.5 72.3       92.8
#> 4 none               6    6.90  95.4  7.23     100  
#> 5 NA                 4    4.60 100   NA         NA  

tab(dplyr::starwars, sex, .desc = TRUE)
#> # A tibble: 5 × 6
#>   sex                n percent   cum valid valid_cum
#>   <chr>          <int>   <dbl> <dbl> <dbl>     <dbl>
#> 1 male              60   69.0   69.0 72.3       72.3
#> 2 female            16   18.4   87.4 19.3       91.6
#> 3 none               6    6.90  94.3  7.23      98.8
#> 4 hermaphroditic     1    1.15  95.4  1.20     100  
#> 5 NA                 4    4.60 100   NA         NA  

fre(dplyr::starwars, sex)
#> # A tibble: 7 × 6
#>   sex                n percent   cum  valid valid_cum
#>   <chr>          <int>   <dbl> <dbl>  <dbl>     <dbl>
#> 1 female            16   18.4   18.4  19.3       19.3
#> 2 hermaphroditic     1    1.15  19.5   1.20      20.5
#> 3 male              60   69.0   88.5  72.3       92.8
#> 4 none               6    6.90  95.4   7.23     100  
#> 5 Valid Total       83   95.4   NA   100         NA  
#> 6 NA                 4    4.60 100    NA         NA  
#> 7 Total             87  100     NA    NA         NA  

fre(dplyr::starwars, sex, .desc = TRUE)
#> # A tibble: 7 × 6
#>   sex                n percent   cum  valid valid_cum
#>   <chr>          <int>   <dbl> <dbl>  <dbl>     <dbl>
#> 1 male              60   69.0   69.0  72.3       72.3
#> 2 female            16   18.4   87.4  19.3       91.6
#> 3 none               6    6.90  94.3   7.23      98.8
#> 4 hermaphroditic     1    1.15  95.4   1.20     100  
#> 5 Valid Total       83   95.4   NA   100         NA  
#> 6 NA                 4    4.60 100    NA         NA  
#> 7 Total             87  100     NA    NA         NA  

tab(dplyr::starwars, sex, gender)
#> # A tibble: 6 × 7
#>   sex            gender        n percent   cum valid valid_cum
#>   <chr>          <chr>     <int>   <dbl> <dbl> <dbl>     <dbl>
#> 1 female         feminine     16   18.4   18.4 19.3       19.3
#> 2 hermaphroditic masculine     1    1.15  19.5  1.20      20.5
#> 3 male           masculine    60   69.0   88.5 72.3       92.8
#> 4 none           feminine      1    1.15  89.7  1.20      94.0
#> 5 none           masculine     5    5.75  95.4  6.02     100  
#> 6 NA             NA            4    4.60 100   NA         NA  

tab(dplyr::starwars, sex == "male")
#> # A tibble: 3 × 6
#>   `sex == "male"`     n percent   cum valid valid_cum
#>   <lgl>           <int>   <dbl> <dbl> <dbl>     <dbl>
#> 1 FALSE              23   26.4   26.4  27.7      27.7
#> 2 TRUE               60   69.0   95.4  72.3     100  
#> 3 NA                  4    4.60 100    NA        NA  

tab(dplyr::starwars, male = sex == "male")
#> # A tibble: 3 × 6
#>   male      n percent   cum valid valid_cum
#>   <lgl> <int>   <dbl> <dbl> <dbl>     <dbl>
#> 1 FALSE    23   26.4   26.4  27.7      27.7
#> 2 TRUE     60   69.0   95.4  72.3     100  
#> 3 NA        4    4.60 100    NA        NA  

tab(dplyr::starwars, ends_with("color"))
#> # A tibble: 67 × 8
#>    hair_color    skin_color eye_color     n percent   cum valid valid_cum
#>    <chr>         <chr>      <chr>     <int>   <dbl> <dbl> <dbl>     <dbl>
#>  1 auburn        fair       blue          1    1.15  1.15  1.22      1.22
#>  2 auburn, grey  fair       blue          1    1.15  2.30  1.22      2.44
#>  3 auburn, white fair       blue-gray     1    1.15  3.45  1.22      3.66
#>  4 black         blue, grey yellow        1    1.15  4.60  1.22      4.88
#>  5 black         brown      brown         1    1.15  5.75  1.22      6.10
#>  6 black         dark       brown         3    3.45  9.20  3.66      9.76
#>  7 black         dark       dark          1    1.15 10.3   1.22     11.0 
#>  8 black         fair       brown         2    2.30 12.6   2.44     13.4 
#>  9 black         light      brown         1    1.15 13.8   1.22     14.6 
#> 10 black         tan        brown         2    2.30 16.1   2.44     17.1 
#> # ℹ 57 more rows

tab(dplyr::starwars, varlist("s*e"))
#> # A tibble: 0 × 5
#> # ℹ 5 variables: n <int>, percent <dbl>, cum <dbl>, valid <dbl>,
#> #   valid_cum <dbl>

tab(dplyr::starwars)
#> # A tibble: 87 × 19
#>    name     height  mass hair_color skin_color eye_color birth_year sex   gender
#>    <chr>     <int> <dbl> <chr>      <chr>      <chr>          <dbl> <chr> <chr> 
#>  1 Ackbar      180  83   none       brown mot… orange          41   male  mascu…
#>  2 Anakin …    188  84   blond      fair       blue            41.9 male  mascu…
#>  3 Ayla Se…    178  55   none       blue       hazel           48   fema… femin…
#>  4 Barriss…    166  50   black      yellow     blue            40   fema… femin…
#>  5 Beru Wh…    165  75   brown      light      blue            47   fema… femin…
#>  6 Biggs D…    183  84   black      light      brown           24   male  mascu…
#>  7 Boba Fe…    183  78.2 black      fair       brown           31.5 male  mascu…
#>  8 Bossk       190 113   none       green      red             53   male  mascu…
#>  9 Chewbac…    228 112   brown      unknown    blue           200   male  mascu…
#> 10 Darth M…    175  80   none       red        yellow          54   male  mascu…
#> # ℹ 77 more rows
#> # ℹ 10 more variables: homeworld <chr>, species <chr>, films <list>,
#> #   vehicles <list>, starships <list>, n <int>, percent <dbl>, cum <dbl>,
#> #   valid <dbl>, valid_cum <dbl>

tab(c(1, 1, 2, NA))
#> # A tibble: 3 × 6
#>   value     n percent   cum valid valid_cum
#>   <dbl> <int>   <dbl> <dbl> <dbl>     <dbl>
#> 1     1     2      50    50  66.7      66.7
#> 2     2     1      25    75  33.3     100  
#> 3    NA     1      25   100  NA        NA  

fre(c(1, 1, 2, NA))
#> # A tibble: 5 × 6
#>   value           n percent   cum valid valid_cum
#>   <chr>       <int>   <dbl> <dbl> <dbl>     <dbl>
#> 1 1               2      50    50  66.7      66.7
#> 2 2               1      25    75  33.3     100  
#> 3 Valid Total     3      75    NA 100        NA  
#> 4 NA              1      25   100  NA        NA  
#> 5 Total           4     100    NA  NA        NA  

# Weighted frequencies, like Stata's tab x [fw=w] or [aw=w]
survey <- tibble::tibble(edu = c("low", "high", "high"), w = c(2, 1, 1.5))
tab(survey, edu, .wt = w)
#> # A tibble: 2 × 6
#>   edu       n percent   cum valid valid_cum
#>   <chr> <dbl>   <dbl> <dbl> <dbl>     <dbl>
#> 1 high    2.5    55.6  55.6  55.6      55.6
#> 2 low     2      44.4 100    44.4     100  
tab(survey, edu, .wt = w, .wt_type = "analytic")
#> # A tibble: 2 × 6
#>   edu       n percent   cum valid valid_cum
#>   <chr> <dbl>   <dbl> <dbl> <dbl>     <dbl>
#> 1 high   1.67    55.6  55.6  55.6      55.6
#> 2 low    1.33    44.4 100    44.4     100  

tab(dplyr::starwars, sex, .by = species, .group_order = "frequency")
#> # A tibble: 41 × 7
#>    species  sex        n percent   cum valid valid_cum
#>    <chr>    <chr>  <int>   <dbl> <dbl> <dbl>     <dbl>
#>  1 Human    female     9    25.7  25.7  25.7      25.7
#>  2 Human    male      26    74.3 100    74.3     100  
#>  3 Droid    none       6   100   100   100       100  
#>  4 Gungan   male       3   100   100   100       100  
#>  5 Kaminoan female     1    50    50    50        50  
#>  6 Kaminoan male       1    50   100    50       100  
#>  7 Mirialan female     2   100   100   100       100  
#>  8 Twi'lek  female     1    50    50    50        50  
#>  9 Twi'lek  male       1    50   100    50       100  
#> 10 Wookiee  male       2   100   100   100       100  
#> # ℹ 31 more rows

tab1(dplyr::starwars, 1:3)
#> $name
#> # A tibble: 87 × 6
#>    value                   n percent   cum valid valid_cum
#>    <chr>               <int>   <dbl> <dbl> <dbl>     <dbl>
#>  1 Ackbar                  1    1.15  1.15  1.15      1.15
#>  2 Adi Gallia              1    1.15  2.30  1.15      2.30
#>  3 Anakin Skywalker        1    1.15  3.45  1.15      3.45
#>  4 Arvel Crynyd            1    1.15  4.60  1.15      4.60
#>  5 Ayla Secura             1    1.15  5.75  1.15      5.75
#>  6 BB8                     1    1.15  6.90  1.15      6.90
#>  7 Bail Prestor Organa     1    1.15  8.05  1.15      8.05
#>  8 Barriss Offee           1    1.15  9.20  1.15      9.20
#>  9 Ben Quadinaros          1    1.15 10.3   1.15     10.3 
#> 10 Beru Whitesun Lars      1    1.15 11.5   1.15     11.5 
#> # ℹ 77 more rows
#> 
#> $height
#> # A tibble: 46 × 6
#>    value     n percent   cum valid valid_cum
#>    <int> <int>   <dbl> <dbl> <dbl>     <dbl>
#>  1    66     1    1.15  1.15  1.23      1.23
#>  2    79     1    1.15  2.30  1.23      2.47
#>  3    88     1    1.15  3.45  1.23      3.70
#>  4    94     1    1.15  4.60  1.23      4.94
#>  5    96     2    2.30  6.90  2.47      7.41
#>  6    97     1    1.15  8.05  1.23      8.64
#>  7   112     1    1.15  9.20  1.23      9.88
#>  8   122     1    1.15 10.3   1.23     11.1 
#>  9   137     1    1.15 11.5   1.23     12.3 
#> 10   150     2    2.30 13.8   2.47     14.8 
#> # ℹ 36 more rows
#> 
#> $mass
#> # A tibble: 39 × 6
#>    value     n percent   cum valid valid_cum
#>    <dbl> <int>   <dbl> <dbl> <dbl>     <dbl>
#>  1    15     1    1.15  1.15  1.69      1.69
#>  2    17     1    1.15  2.30  1.69      3.39
#>  3    20     1    1.15  3.45  1.69      5.08
#>  4    32     2    2.30  5.75  3.39      8.47
#>  5    40     1    1.15  6.90  1.69     10.2 
#>  6    45     2    2.30  9.20  3.39     13.6 
#>  7    48     2    2.30 11.5   3.39     16.9 
#>  8    49     1    1.15 12.6   1.69     18.6 
#>  9    50     2    2.30 14.9   3.39     22.0 
#> 10    55     2    2.30 17.2   3.39     25.4 
#> # ℹ 29 more rows
#> 

tab1(dplyr::starwars, ends_with("color"))
#> $hair_color
#> # A tibble: 12 × 6
#>    value             n percent    cum valid valid_cum
#>    <chr>         <int>   <dbl>  <dbl> <dbl>     <dbl>
#>  1 auburn            1    1.15   1.15  1.22      1.22
#>  2 auburn, grey      1    1.15   2.30  1.22      2.44
#>  3 auburn, white     1    1.15   3.45  1.22      3.66
#>  4 black            13   14.9   18.4  15.9      19.5 
#>  5 blond             3    3.45  21.8   3.66     23.2 
#>  6 blonde            1    1.15  23.0   1.22     24.4 
#>  7 brown            18   20.7   43.7  22.0      46.3 
#>  8 brown, grey       1    1.15  44.8   1.22     47.6 
#>  9 grey              1    1.15  46.0   1.22     48.8 
#> 10 none             38   43.7   89.7  46.3      95.1 
#> 11 white             4    4.60  94.3   4.88    100   
#> 12 NA                5    5.75 100    NA        NA   
#> 
#> $skin_color
#> # A tibble: 31 × 6
#>    value                   n percent   cum valid valid_cum
#>    <chr>               <int>   <dbl> <dbl> <dbl>     <dbl>
#>  1 blue                    2    2.30  2.30  2.30      2.30
#>  2 blue, grey              2    2.30  4.60  2.30      4.60
#>  3 brown                   4    4.60  9.20  4.60      9.20
#>  4 brown mottle            1    1.15 10.3   1.15     10.3 
#>  5 brown, white            1    1.15 11.5   1.15     11.5 
#>  6 dark                    6    6.90 18.4   6.90     18.4 
#>  7 fair                   17   19.5  37.9  19.5      37.9 
#>  8 fair, green, yellow     1    1.15 39.1   1.15     39.1 
#>  9 gold                    1    1.15 40.2   1.15     40.2 
#> 10 green                   6    6.90 47.1   6.90     47.1 
#> # ℹ 21 more rows
#> 
#> $eye_color
#> # A tibble: 15 × 6
#>    value             n percent   cum valid valid_cum
#>    <chr>         <int>   <dbl> <dbl> <dbl>     <dbl>
#>  1 black            10   11.5   11.5 11.5       11.5
#>  2 blue             19   21.8   33.3 21.8       33.3
#>  3 blue-gray         1    1.15  34.5  1.15      34.5
#>  4 brown            21   24.1   58.6 24.1       58.6
#>  5 dark              1    1.15  59.8  1.15      59.8
#>  6 gold              1    1.15  60.9  1.15      60.9
#>  7 green, yellow     1    1.15  62.1  1.15      62.1
#>  8 hazel             3    3.45  65.5  3.45      65.5
#>  9 orange            8    9.20  74.7  9.20      74.7
#> 10 pink              1    1.15  75.9  1.15      75.9
#> 11 red               5    5.75  81.6  5.75      81.6
#> 12 red, blue         1    1.15  82.8  1.15      82.8
#> 13 unknown           3    3.45  86.2  3.45      86.2
#> 14 white             1    1.15  87.4  1.15      87.4
#> 15 yellow           11   12.6  100   12.6      100  
#> 

tab1(dplyr::starwars, ends_with("color"), .type = "tibble")
#> # A tibble: 58 × 7
#>    variable   value             n percent   cum valid valid_cum
#>    <chr>      <chr>         <int>   <dbl> <dbl> <dbl>     <dbl>
#>  1 hair_color auburn            1    1.15  1.15  1.22      1.22
#>  2 hair_color auburn, grey      1    1.15  2.30  1.22      2.44
#>  3 hair_color auburn, white     1    1.15  3.45  1.22      3.66
#>  4 hair_color black            13   14.9  18.4  15.9      19.5 
#>  5 hair_color blond             3    3.45 21.8   3.66     23.2 
#>  6 hair_color blonde            1    1.15 23.0   1.22     24.4 
#>  7 hair_color brown            18   20.7  43.7  22.0      46.3 
#>  8 hair_color brown, grey       1    1.15 44.8   1.22     47.6 
#>  9 hair_color grey              1    1.15 46.0   1.22     48.8 
#> 10 hair_color none             38   43.7  89.7  46.3      95.1 
#> # ℹ 48 more rows

fre1(dplyr::starwars, ends_with("color"))
#> $hair_color
#> # A tibble: 14 × 6
#>    value             n percent    cum  valid valid_cum
#>    <chr>         <int>   <dbl>  <dbl>  <dbl>     <dbl>
#>  1 auburn            1    1.15   1.15   1.22      1.22
#>  2 auburn, grey      1    1.15   2.30   1.22      2.44
#>  3 auburn, white     1    1.15   3.45   1.22      3.66
#>  4 black            13   14.9   18.4   15.9      19.5 
#>  5 blond             3    3.45  21.8    3.66     23.2 
#>  6 blonde            1    1.15  23.0    1.22     24.4 
#>  7 brown            18   20.7   43.7   22.0      46.3 
#>  8 brown, grey       1    1.15  44.8    1.22     47.6 
#>  9 grey              1    1.15  46.0    1.22     48.8 
#> 10 none             38   43.7   89.7   46.3      95.1 
#> 11 white             4    4.60  94.3    4.88    100   
#> 12 Valid Total      82   94.3   NA    100        NA   
#> 13 NA                5    5.75 100     NA        NA   
#> 14 Total            87  100     NA     NA        NA   
#> 
#> $skin_color
#> # A tibble: 32 × 6
#>    value                   n percent   cum valid valid_cum
#>    <chr>               <int>   <dbl> <dbl> <dbl>     <dbl>
#>  1 blue                    2    2.30  2.30  2.30      2.30
#>  2 blue, grey              2    2.30  4.60  2.30      4.60
#>  3 brown                   4    4.60  9.20  4.60      9.20
#>  4 brown mottle            1    1.15 10.3   1.15     10.3 
#>  5 brown, white            1    1.15 11.5   1.15     11.5 
#>  6 dark                    6    6.90 18.4   6.90     18.4 
#>  7 fair                   17   19.5  37.9  19.5      37.9 
#>  8 fair, green, yellow     1    1.15 39.1   1.15     39.1 
#>  9 gold                    1    1.15 40.2   1.15     40.2 
#> 10 green                   6    6.90 47.1   6.90     47.1 
#> # ℹ 22 more rows
#> 
#> $eye_color
#> # A tibble: 16 × 6
#>    value             n percent   cum valid valid_cum
#>    <chr>         <int>   <dbl> <dbl> <dbl>     <dbl>
#>  1 black            10   11.5   11.5 11.5       11.5
#>  2 blue             19   21.8   33.3 21.8       33.3
#>  3 blue-gray         1    1.15  34.5  1.15      34.5
#>  4 brown            21   24.1   58.6 24.1       58.6
#>  5 dark              1    1.15  59.8  1.15      59.8
#>  6 gold              1    1.15  60.9  1.15      60.9
#>  7 green, yellow     1    1.15  62.1  1.15      62.1
#>  8 hazel             3    3.45  65.5  3.45      65.5
#>  9 orange            8    9.20  74.7  9.20      74.7
#> 10 pink              1    1.15  75.9  1.15      75.9
#> 11 red               5    5.75  81.6  5.75      81.6
#> 12 red, blue         1    1.15  82.8  1.15      82.8
#> 13 unknown           3    3.45  86.2  3.45      86.2
#> 14 white             1    1.15  87.4  1.15      87.4
#> 15 yellow           11   12.6  100   12.6      100  
#> 16 Total            87  100     NA   NA         NA  
#> 

fre1(dplyr::starwars, ends_with("color"), .type = "list")
#> $hair_color
#> # A tibble: 14 × 6
#>    value             n percent    cum  valid valid_cum
#>    <chr>         <int>   <dbl>  <dbl>  <dbl>     <dbl>
#>  1 auburn            1    1.15   1.15   1.22      1.22
#>  2 auburn, grey      1    1.15   2.30   1.22      2.44
#>  3 auburn, white     1    1.15   3.45   1.22      3.66
#>  4 black            13   14.9   18.4   15.9      19.5 
#>  5 blond             3    3.45  21.8    3.66     23.2 
#>  6 blonde            1    1.15  23.0    1.22     24.4 
#>  7 brown            18   20.7   43.7   22.0      46.3 
#>  8 brown, grey       1    1.15  44.8    1.22     47.6 
#>  9 grey              1    1.15  46.0    1.22     48.8 
#> 10 none             38   43.7   89.7   46.3      95.1 
#> 11 white             4    4.60  94.3    4.88    100   
#> 12 Valid Total      82   94.3   NA    100        NA   
#> 13 NA                5    5.75 100     NA        NA   
#> 14 Total            87  100     NA     NA        NA   
#> 
#> $skin_color
#> # A tibble: 32 × 6
#>    value                   n percent   cum valid valid_cum
#>    <chr>               <int>   <dbl> <dbl> <dbl>     <dbl>
#>  1 blue                    2    2.30  2.30  2.30      2.30
#>  2 blue, grey              2    2.30  4.60  2.30      4.60
#>  3 brown                   4    4.60  9.20  4.60      9.20
#>  4 brown mottle            1    1.15 10.3   1.15     10.3 
#>  5 brown, white            1    1.15 11.5   1.15     11.5 
#>  6 dark                    6    6.90 18.4   6.90     18.4 
#>  7 fair                   17   19.5  37.9  19.5      37.9 
#>  8 fair, green, yellow     1    1.15 39.1   1.15     39.1 
#>  9 gold                    1    1.15 40.2   1.15     40.2 
#> 10 green                   6    6.90 47.1   6.90     47.1 
#> # ℹ 22 more rows
#> 
#> $eye_color
#> # A tibble: 16 × 6
#>    value             n percent   cum valid valid_cum
#>    <chr>         <int>   <dbl> <dbl> <dbl>     <dbl>
#>  1 black            10   11.5   11.5 11.5       11.5
#>  2 blue             19   21.8   33.3 21.8       33.3
#>  3 blue-gray         1    1.15  34.5  1.15      34.5
#>  4 brown            21   24.1   58.6 24.1       58.6
#>  5 dark              1    1.15  59.8  1.15      59.8
#>  6 gold              1    1.15  60.9  1.15      60.9
#>  7 green, yellow     1    1.15  62.1  1.15      62.1
#>  8 hazel             3    3.45  65.5  3.45      65.5
#>  9 orange            8    9.20  74.7  9.20      74.7
#> 10 pink              1    1.15  75.9  1.15      75.9
#> 11 red               5    5.75  81.6  5.75      81.6
#> 12 red, blue         1    1.15  82.8  1.15      82.8
#> 13 unknown           3    3.45  86.2  3.45      86.2
#> 14 white             1    1.15  87.4  1.15      87.4
#> 15 yellow           11   12.6  100   12.6      100  
#> 16 Total            87  100     NA   NA         NA  
#> 

tab(dplyr::starwars, sex, .total = TRUE)
#> # A tibble: 7 × 6
#>   sex                n percent   cum  valid valid_cum
#>   <chr>          <int>   <dbl> <dbl>  <dbl>     <dbl>
#> 1 female            16   18.4   18.4  19.3       19.3
#> 2 hermaphroditic     1    1.15  19.5   1.20      20.5
#> 3 male              60   69.0   88.5  72.3       92.8
#> 4 none               6    6.90  95.4   7.23     100  
#> 5 Valid Total       83   95.4   NA   100         NA  
#> 6 NA                 4    4.60 100    NA         NA  
#> 7 Total             87  100     NA    NA         NA  

tab2(dplyr::starwars, sex, gender)
#> # A tibble: 5 × 4
#>   `sex \\ gender` feminine masculine  `NA`
#>   <chr>              <int>     <int> <int>
#> 1 female                16         0     0
#> 2 hermaphroditic         0         1     0
#> 3 male                   0        60     0
#> 4 none                   1         5     0
#> 5 NA                     0         0     4

tab2(dplyr::starwars, height, gender)
#> # A tibble: 46 × 4
#>    `height \\ gender` feminine masculine  `NA`
#>                 <int>    <int>     <int> <int>
#>  1                 66        0         1     0
#>  2                 79        0         1     0
#>  3                 88        0         1     0
#>  4                 94        0         1     0
#>  5                 96        1         1     0
#>  6                 97        0         1     0
#>  7                112        0         1     0
#>  8                122        0         1     0
#>  9                137        0         1     0
#> 10                150        2         0     0
#> # ℹ 36 more rows

fre2(dplyr::starwars, height, gender)
#> # A tibble: 47 × 5
#>    `height \\ gender` feminine masculine  `NA` total
#>    <chr>                 <int>     <int> <int> <int>
#>  1 66                        0         1     0     1
#>  2 79                        0         1     0     1
#>  3 88                        0         1     0     1
#>  4 94                        0         1     0     1
#>  5 96                        1         1     0     2
#>  6 97                        0         1     0     1
#>  7 112                       0         1     0     1
#>  8 122                       0         1     0     1
#>  9 137                       0         1     0     1
#> 10 150                       2         0     0     2
#> # ℹ 37 more rows

# Every pairwise table, like Stata's tab2 sex gender eye_color
tab2(dplyr::starwars, sex, gender, eye_color)
#> $`sex x gender`
#> # A tibble: 5 × 4
#>   `sex \\ gender` feminine masculine  `NA`
#>   <chr>              <int>     <int> <int>
#> 1 female                16         0     0
#> 2 hermaphroditic         0         1     0
#> 3 male                   0        60     0
#> 4 none                   1         5     0
#> 5 NA                     0         0     4
#> 
#> $`sex x eye_color`
#> # A tibble: 5 × 16
#>   `sex \\ eye_color` black  blue `blue-gray` brown  dark  gold `green, yellow`
#>   <chr>              <int> <int>       <int> <int> <int> <int>           <int>
#> 1 female                 2     6           0     4     0     0               0
#> 2 hermaphroditic         0     0           0     0     0     0               0
#> 3 male                   7    12           1    15     1     1               1
#> 4 none                   1     0           0     0     0     0               0
#> 5 NA                     0     1           0     2     0     0               0
#> # ℹ 8 more variables: hazel <int>, orange <int>, pink <int>, red <int>,
#> #   `red, blue` <int>, unknown <int>, white <int>, yellow <int>
#> 
#> $`gender x eye_color`
#> # A tibble: 3 × 16
#>   `gender \\ eye_color` black  blue `blue-gray` brown  dark  gold
#>   <chr>                 <int> <int>       <int> <int> <int> <int>
#> 1 feminine                  2     6           0     4     0     0
#> 2 masculine                 8    12           1    15     1     1
#> 3 NA                        0     1           0     2     0     0
#> # ℹ 9 more variables: `green, yellow` <int>, hazel <int>, orange <int>,
#> #   pink <int>, red <int>, `red, blue` <int>, unknown <int>, white <int>,
#> #   yellow <int>
#> 

# One cross-table per group, like Stata's by species: tab sex gender
tab2(dplyr::starwars, sex, gender, .by = species) |> head(2)
#> $`species = Aleena`
#> # A tibble: 1 × 2
#>   `sex \\ gender` masculine
#>   <chr>               <int>
#> 1 male                    1
#> 
#> $`species = Besalisk`
#> # A tibble: 1 × 2
#>   `sex \\ gender` masculine
#>   <chr>               <int>
#> 1 male                    1
#> 

# Chi-square test of independence, like Stata's tab x y, chi2 V
chi2 <- tab2(dplyr::starwars, sex, gender, .chi2 = TRUE)
#> Pearson chi2(8) = 168.6368   Pr = 0.000
#> Cramer's V = 0.9845
attr(chi2, "chi2")
#> # A tibble: 1 × 5
#>   statistic    df  p_value cramers_v     n
#>       <dbl> <int>    <dbl>     <dbl> <int>
#> 1      169.     8 2.49e-32     0.984    87
```
