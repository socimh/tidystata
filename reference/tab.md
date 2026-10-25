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
named after Stata's `fre`.

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
valid percentages and appear last. So `percent` matches the user-written
`fre` and `tabulate, missing`, and `valid` matches plain `tabulate`,
which leaves missing values out.

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
including missing ones (filter them out first to exclude them, as
Stata's `tabulate, chi2` does without `missing`), and drops rows or
columns with no observations. It prints Pearson's chi-square, its
degrees of freedom, the p-value and Cramer's V as a message, and stores
them as a one-row tibble in `attr(result, "chi2")` with columns
`statistic`, `df`, `p_value`, `cramers_v` and `n`. Flextable output adds
them as a footer. As in Stata, V keeps its sign in 2 x 2 tables. The
statistic, p-value and V are tested against Stata's `tabulate, chi2 V`.
Frequency weights are treated as counts; analytic weights are an error,
because a design-based test such as `survey::svychisq()` is needed for
sampling weights.

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
# fre() shows value labels; tab() keeps the labelled codes
fre(lifeexp, region)
#> # A tibble: 4 × 6
#>   region               n percent   cum valid valid_cum
#>   <chr>            <int>   <dbl> <dbl> <dbl>     <dbl>
#> 1 Europe & C. Asia    44    64.7  64.7  64.7      64.7
#> 2 North America       14    20.6  85.3  20.6      85.3
#> 3 South America       10    14.7 100    14.7     100  
#> 4 Total               68   100    NA    NA        NA  

tab(lifeexp, region)
#> # A tibble: 3 × 6
#>   region                   n percent   cum valid valid_cum
#>   <dbl+lbl>            <int>   <dbl> <dbl> <dbl>     <dbl>
#> 1 1 [Europe & C. Asia]    44    64.7  64.7  64.7      64.7
#> 2 2 [North America]       14    20.6  85.3  20.6      85.3
#> 3 3 [South America]       10    14.7 100    14.7     100  

# tabulate a condition
tab(lifeexp, safewater > 50)
#> # A tibble: 3 × 6
#>   `safewater > 50`     n percent   cum valid valid_cum
#>   <lgl>            <int>   <dbl> <dbl> <dbl>     <dbl>
#> 1 FALSE               11    16.2  16.2  20.4      20.4
#> 2 TRUE                43    63.2  79.4  79.6     100  
#> 3 NA                  14    20.6 100    NA        NA  

# Tabulate a column by position, a condition, or a named expression.
tab(lifeexp, 1)
#> # A tibble: 3 × 6
#>   region                   n percent   cum valid valid_cum
#>   <dbl+lbl>            <int>   <dbl> <dbl> <dbl>     <dbl>
#> 1 1 [Europe & C. Asia]    44    64.7  64.7  64.7      64.7
#> 2 2 [North America]       14    20.6  85.3  20.6      85.3
#> 3 3 [South America]       10    14.7 100    14.7     100  
tab(lifeexp, region, .desc = TRUE)
#> # A tibble: 3 × 6
#>   region                   n percent   cum valid valid_cum
#>   <dbl+lbl>            <int>   <dbl> <dbl> <dbl>     <dbl>
#> 1 1 [Europe & C. Asia]    44    64.7  64.7  64.7      64.7
#> 2 2 [North America]       14    20.6  85.3  20.6      85.3
#> 3 3 [South America]       10    14.7 100    14.7     100  
fre(lifeexp, region, .desc = TRUE)
#> # A tibble: 4 × 6
#>   region               n percent   cum valid valid_cum
#>   <chr>            <int>   <dbl> <dbl> <dbl>     <dbl>
#> 1 Europe & C. Asia    44    64.7  64.7  64.7      64.7
#> 2 North America       14    20.6  85.3  20.6      85.3
#> 3 South America       10    14.7 100    14.7     100  
#> 4 Total               68   100    NA    NA        NA  
tab(lifeexp, lexp >= 70)
#> # A tibble: 2 × 6
#>   `lexp >= 70`     n percent   cum valid valid_cum
#>   <lgl>        <int>   <dbl> <dbl> <dbl>     <dbl>
#> 1 FALSE           21    30.9  30.9  30.9      30.9
#> 2 TRUE            47    69.1 100    69.1     100  
tab(lifeexp, lexp_70 = lexp >= 70)
#> # A tibble: 2 × 6
#>   lexp_70     n percent   cum valid valid_cum
#>   <lgl>   <int>   <dbl> <dbl> <dbl>     <dbl>
#> 1 FALSE      21    30.9  30.9  30.9      30.9
#> 2 TRUE       47    69.1 100    69.1     100  
tab(lifeexp, varlist("*p*"))
#> # A tibble: 68 × 8
#>    popgrowth  lexp gnppc     n percent   cum valid valid_cum
#>        <dbl> <dbl> <dbl> <int>   <dbl> <dbl> <dbl>     <dbl>
#>  1      -2.5    63  1340     1    1.47  1.47  1.49      1.49
#>  2      -2.5    70   870     1    1.47  2.94  1.49      2.99
#>  3      -1.2    70   570     1    1.47  4.41  1.49      4.48
#>  4      -1      69  3820     1    1.47  5.88  1.49      5.97
#>  5      -0.9    69  2790     1    1.47  7.35  1.49      7.46
#>  6      -0.8    68   840     1    1.47  8.82  1.49      8.96
#>  7      -0.7    71  1440     1    1.47 10.3   1.49     10.4 
#>  8      -0.7    71  2870     1    1.47 11.8   1.49     11.9 
#>  9      -0.6    74   870     1    1.47 13.2   1.49     13.4 
#> 10      -0.5    68  1540     1    1.47 14.7   1.49     14.9 
#> # ℹ 58 more rows
tab(lifeexp)
#> # A tibble: 68 × 11
#>    region      country popgrowth  lexp gnppc safewater     n percent   cum valid
#>    <dbl+lbl>   <chr>       <dbl> <dbl> <dbl>     <dbl> <int>   <dbl> <dbl> <dbl>
#>  1 1 [Europe … Albania      -0.6    74   870        49     1    1.47  1.47  1.89
#>  2 1 [Europe … Armenia      -1.2    70   570        83     1    1.47  2.94  1.89
#>  3 1 [Europe … Austria       0.1    78 27810        97     1    1.47  4.41  1.89
#>  4 1 [Europe … Azerba…       0.9    64   510        49     1    1.47  5.88  1.89
#>  5 1 [Europe … Belarus      -0.5    68  1540        82     1    1.47  7.35  1.89
#>  6 1 [Europe … Belgium       0.2    77 26530       100     1    1.47  8.82  1.89
#>  7 1 [Europe … Bosnia…       1.8    74  1230        87     1    1.47 10.3   1.89
#>  8 1 [Europe … Bulgar…      -0.7    71  1440        90     1    1.47 11.8   1.89
#>  9 1 [Europe … Czechia      -0.1    75  6140        95     1    1.47 13.2   1.89
#> 10 1 [Europe … Denmark       0.4    76 33440        95     1    1.47 14.7   1.89
#> # ℹ 58 more rows
#> # ℹ 1 more variable: valid_cum <dbl>

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

# Weighted frequencies, like Stata's tab x [fw=w] or [aw=w].
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

# Illustrative indicators for cross-tabulation; keep lifeexp unchanged.
countries <- dplyr::mutate(
  lifeexp,
  lexp_70 = lexp >= 70,
  water_80 = safewater >= 80
)
tab(countries, region, lexp_70)
#> # A tibble: 6 × 7
#>   region               lexp_70     n percent   cum valid valid_cum
#>   <dbl+lbl>            <lgl>   <int>   <dbl> <dbl> <dbl>     <dbl>
#> 1 1 [Europe & C. Asia] FALSE      12   17.6   17.6 17.6       17.6
#> 2 1 [Europe & C. Asia] TRUE       32   47.1   64.7 47.1       64.7
#> 3 2 [North America]    FALSE       6    8.82  73.5  8.82      73.5
#> 4 2 [North America]    TRUE        8   11.8   85.3 11.8       85.3
#> 5 3 [South America]    FALSE       3    4.41  89.7  4.41      89.7
#> 6 3 [South America]    TRUE        7   10.3  100   10.3      100  
tab(countries, lexp_70, .by = region, .group_order = "frequency")
#> # A tibble: 6 × 7
#>   region               lexp_70     n percent   cum valid valid_cum
#>   <dbl+lbl>            <lgl>   <int>   <dbl> <dbl> <dbl>     <dbl>
#> 1 1 [Europe & C. Asia] FALSE      12    27.3  27.3  27.3      27.3
#> 2 1 [Europe & C. Asia] TRUE       32    72.7 100    72.7     100  
#> 3 2 [North America]    FALSE       6    42.9  42.9  42.9      42.9
#> 4 2 [North America]    TRUE        8    57.1 100    57.1     100  
#> 5 3 [South America]    FALSE       3    30    30    30        30  
#> 6 3 [South America]    TRUE        7    70   100    70       100  
tab1(lifeexp, 1:3)
#> $region
#> # A tibble: 3 × 6
#>   value                    n percent   cum valid valid_cum
#>   <dbl+lbl>            <int>   <dbl> <dbl> <dbl>     <dbl>
#> 1 1 [Europe & C. Asia]    44    64.7  64.7  64.7      64.7
#> 2 2 [North America]       14    20.6  85.3  20.6      85.3
#> 3 3 [South America]       10    14.7 100    14.7     100  
#> 
#> $country
#> # A tibble: 68 × 6
#>    value                      n percent   cum valid valid_cum
#>    <chr>                  <int>   <dbl> <dbl> <dbl>     <dbl>
#>  1 Albania                    1    1.47  1.47  1.47      1.47
#>  2 Argentina                  1    1.47  2.94  1.47      2.94
#>  3 Armenia                    1    1.47  4.41  1.47      4.41
#>  4 Austria                    1    1.47  5.88  1.47      5.88
#>  5 Azerbaijan                 1    1.47  7.35  1.47      7.35
#>  6 Belarus                    1    1.47  8.82  1.47      8.82
#>  7 Belgium                    1    1.47 10.3   1.47     10.3 
#>  8 Bolivia                    1    1.47 11.8   1.47     11.8 
#>  9 Bosnia and Herzegovina     1    1.47 13.2   1.47     13.2 
#> 10 Brazil                     1    1.47 14.7   1.47     14.7 
#> # ℹ 58 more rows
#> 
#> $popgrowth
#> # A tibble: 32 × 6
#>    value     n percent   cum valid valid_cum
#>    <dbl> <int>   <dbl> <dbl> <dbl>     <dbl>
#>  1  -2.5     2    2.94  2.94  2.94      2.94
#>  2  -1.2     1    1.47  4.41  1.47      4.41
#>  3  -1       1    1.47  5.88  1.47      5.88
#>  4  -0.9     1    1.47  7.35  1.47      7.35
#>  5  -0.8     1    1.47  8.82  1.47      8.82
#>  6  -0.7     2    2.94 11.8   2.94     11.8 
#>  7  -0.6     1    1.47 13.2   1.47     13.2 
#>  8  -0.5     1    1.47 14.7   1.47     14.7 
#>  9  -0.4     1    1.47 16.2   1.47     16.2 
#> 10  -0.2     4    5.88 22.1   5.88     22.1 
#> # ℹ 22 more rows
#> 
tab1(countries, matches("^(region|lexp_70)$"))
#> $region
#> # A tibble: 3 × 6
#>   value                    n percent   cum valid valid_cum
#>   <dbl+lbl>            <int>   <dbl> <dbl> <dbl>     <dbl>
#> 1 1 [Europe & C. Asia]    44    64.7  64.7  64.7      64.7
#> 2 2 [North America]       14    20.6  85.3  20.6      85.3
#> 3 3 [South America]       10    14.7 100    14.7     100  
#> 
#> $lexp_70
#> # A tibble: 2 × 6
#>   value     n percent   cum valid valid_cum
#>   <lgl> <int>   <dbl> <dbl> <dbl>     <dbl>
#> 1 FALSE    21    30.9  30.9  30.9      30.9
#> 2 TRUE     47    69.1 100    69.1     100  
#> 
tab(lifeexp, region, .total = TRUE)
#> # A tibble: 4 × 6
#>   region               n percent   cum valid valid_cum
#>   <chr>            <int>   <dbl> <dbl> <dbl>     <dbl>
#> 1 Europe & C. Asia    44    64.7  64.7  64.7      64.7
#> 2 North America       14    20.6  85.3  20.6      85.3
#> 3 South America       10    14.7 100    14.7     100  
#> 4 Total               68   100    NA    NA        NA  
tab2(countries, region, lexp_70)
#> # A tibble: 3 × 3
#>   `region \\ lexp_70`  `FALSE` `TRUE`
#>   <dbl+lbl>              <int>  <int>
#> 1 1 [Europe & C. Asia]      12     32
#> 2 2 [North America]          6      8
#> 3 3 [South America]          3      7
tab2(countries, lexp, lexp_70)
#> # A tibble: 20 × 3
#>    `lexp \\ lexp_70` `FALSE` `TRUE`
#>                <dbl>   <int>  <int>
#>  1                57       1      0
#>  2                61       1      0
#>  3                62       2      0
#>  4                63       1      0
#>  5                64       3      0
#>  6                65       1      0
#>  7                66       1      0
#>  8                67       4      0
#>  9                68       3      0
#> 10                69       4      0
#> 11                70       0      5
#> 12                71       0      6
#> 13                72       0      6
#> 14                73       0      4
#> 15                74       0      3
#> 16                75       0      4
#> 17                76       0      4
#> 18                77       0      5
#> 19                78       0      4
#> 20                79       0      6
fre2(countries, lexp, lexp_70)
#> # A tibble: 21 × 4
#>    `lexp \\ lexp_70` `FALSE` `TRUE` total
#>    <chr>               <int>  <int> <int>
#>  1 57                      1      0     1
#>  2 61                      1      0     1
#>  3 62                      2      0     2
#>  4 63                      1      0     1
#>  5 64                      3      0     3
#>  6 65                      1      0     1
#>  7 66                      1      0     1
#>  8 67                      4      0     4
#>  9 68                      3      0     3
#> 10 69                      4      0     4
#> # ℹ 11 more rows

# Every pairwise table, like Stata's tab2 region lexp_70 water_80.
tab2(countries, region, lexp_70, water_80)
#> $`region x lexp_70`
#> # A tibble: 3 × 3
#>   `region \\ lexp_70`  `FALSE` `TRUE`
#>   <dbl+lbl>              <int>  <int>
#> 1 1 [Europe & C. Asia]      12     32
#> 2 2 [North America]          6      8
#> 3 3 [South America]          3      7
#> 
#> $`region x water_80`
#> # A tibble: 3 × 4
#>   `region \\ water_80` `FALSE` `TRUE`  `NA`
#>   <dbl+lbl>              <int>  <int> <int>
#> 1 1 [Europe & C. Asia]      14     28     2
#> 2 2 [North America]          5      1     8
#> 3 3 [South America]          5      1     4
#> 
#> $`lexp_70 x water_80`
#> # A tibble: 2 × 4
#>   `lexp_70 \\ water_80` `FALSE` `TRUE`  `NA`
#>   <lgl>                   <int>  <int> <int>
#> 1 FALSE                      13      3     5
#> 2 TRUE                       11     27     9
#> 

# One cross-table per group, like Stata's by region: tab lexp_70 water_80.
tab2(countries, lexp_70, water_80, .by = region) |> head(2)
#> $`region = Europe & C. Asia`
#> # A tibble: 2 × 4
#>   `lexp_70 \\ water_80` `FALSE` `TRUE`  `NA`
#>   <lgl>                   <int>  <int> <int>
#> 1 FALSE                       9      3     0
#> 2 TRUE                        5     25     2
#> 
#> $`region = North America`
#> # A tibble: 2 × 4
#>   `lexp_70 \\ water_80` `FALSE` `TRUE`  `NA`
#>   <lgl>                   <int>  <int> <int>
#> 1 FALSE                       2      0     4
#> 2 TRUE                        3      1     4
#> 

# Chi-square test of independence, like Stata's tab x y, chi2 V.
chi2 <- tab2(countries, region, lexp_70, .chi2 = TRUE)
#> Pearson chi2(2) = 1.2127   Pr = 0.545
#> Cramer's V = 0.1335
attr(chi2, "chi2")
#> # A tibble: 1 × 5
#>   statistic    df p_value cramers_v     n
#>       <dbl> <int>   <dbl>     <dbl> <int>
#> 1      1.21     2   0.545     0.134    68

# Several character columns share a suffix in this dataset.
starwars <- dplyr::starwars
tab(starwars, ends_with("color"))
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
tab1(starwars, ends_with("color"))
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
tab1(starwars, ends_with("color"), .type = "tibble")
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
fre1(starwars, ends_with("color"))
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
fre1(starwars, ends_with("color"), .type = "list")
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
```
