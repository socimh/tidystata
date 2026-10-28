# Frequency tables and cross-tabulations

Create Stata-style frequency tables using joint counts, separate one-way
tables, or pairwise cross-tabulations:

- `tab()`: Count combinations of selected variables in one long-format
  table with frequencies and percentages.

- `fre()`: Count the same combinations as `tab()`, adding totals and
  displaying value labels.

- `tab1()`: Tabulate each variable separately, returning a one-way
  frequency table for each variable.

- `fre1()`: Tabulate each variable separately as in `tab1()`, adding
  totals and displaying value labels.

- `tab2()`: Cross-tabulate every pair of selected variables, returning
  wide contingency tables with categories in rows and columns.

- `fre2()`: Cross-tabulate every pair as in `tab2()`, adding marginal
  totals and displaying row-category labels. Column headers retain
  category codes.

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

  An in-memory data frame, tibble, or data.table. `tab()`, `tab1()`,
  `fre()`, and `fre1()` also accept an atomic vector (without selectors
  or `.by`). Collect lazy tables first. Spatial geometry columns are
  excluded.

- ...:

  \<[`tidy-select`](https://dplyr.tidyverse.org/reference/dplyr_tidy_select.html)\>
  or
  \<[`data-masking`](https://rlang.r-lib.org/reference/args_data_masking.html)\>
  Variables to tabulate, or named expressions such as
  `high = score >= 70`. Defaults to all columns except active grouping
  keys. Without explicit `.by`, `tab2()` and `fre2()` treat inherited
  grouping columns as ordinary variables. Select at least two variables
  for cross-tabulation.

- .by:

  \<[`tidy-select`](https://dplyr.tidyverse.org/reference/dplyr_tidy_select.html)\>
  Optional grouping columns. For one-way and joint tables, existing
  [`dplyr::group_by()`](https://dplyr.tidyverse.org/reference/group_by.html)
  groups are inherited unless `.by` is supplied. `tab2()` and `fre2()`
  require explicit `.by` to create separate cross-tables for each group.
  Grouping keys are not tabulated.

- .desc:

  If `TRUE`, sort categories by decreasing frequency within each group;
  missing categories remain last. Defaults to `FALSE`.

- .group_order:

  Order group blocks by `"keys"` (default) or decreasing `"frequency"`
  (weighted totals when weights are supplied). Groups with any missing
  key follow complete-key groups; within each set, frequency ties follow
  key order. Does not change category order within groups.

- .total:

  If `TRUE`, add totals, as in the corresponding `fre()` family
  function. Defaults to `FALSE` for `tab()`, `tab1()`, and `tab2()`; the
  `fre()` family always includes totals.

- .wt:

  Optional numeric weights, given as a column or one value per row.
  Missing weights exclude rows; negative weights are invalid.

- .wt_type:

  `"frequency"` (default) or `"analytic"`. Frequency weights are summed
  as counts; analytic weights are normalized within groups. See Details
  for the formulas.

- .type:

  Output form, where supported. `tab()` has no `.type` argument.

  - `"list"` is the default for `tab1()` and `fre1()`: one table per
    selected variable, retaining the input's table class where
    supported.

  - `"auto"` is the default for `fre()`, `tab2()`, and `fre2()`: retain
    the input's table class where supported.

  - `"tibble"` returns tibbles regardless of the input's table class.
    For `tab1()` and `fre1()`, it also combines the variable tables into
    one.

  - `"flextable"` returns formatted tables and requires the optional
    flextable package. It is available for `fre()`, `fre1()`, `tab2()`,
    and `fre2()`; `tab2()` also requires `.total = TRUE`.

  For `tab2()` and `fre2()`, multiple pairs or explicit `.by` groups
  still produce lists; `.type` controls each table inside the list.

- .flip:

  If `TRUE`, exchange the row and column variables in a
  cross-tabulation. Defaults to `FALSE`.

- .chi2:

  If `TRUE`, report Pearson's chi-square test and Cramer's V for
  cross-tabulations. Analytic weights are not supported for this test.

## Value

A table or list of tables, depending on the function:

- `tab()` and `fre()` return one row per observed combination of
  selected categories and grouping keys, followed by `n`, `percent`,
  `cum`, `valid`, and `valid_cum`. The `fre()` variant adds total rows.

- `tab1()` and `fre1()` return named lists of one-variable frequency
  tables. Each contains a `value` column and the same five statistics.
  Use `.type = "tibble"` to combine them, adding a `variable` column.

- `tab2()` and `fre2()` return wide cross-tabulations: rows represent
  categories of one variable, columns represent categories of the other,
  and cells contain counts. `fre2()` adds marginal totals. Multiple
  pairs or explicit `.by` groups produce lists of tables.

For two selected variables, `tab()` and `tab2()` represent the same
joint frequencies in different layouts: `tab()` provides a long table
with percentages, whereas `tab2()` shows cell counts in a two-way table.
With three or more variables, `tab()` counts their joint combinations,
while `tab2()` produces a separate table for each variable pair.

Results are ungrouped and retain the input table class where supported.
For non-flextable output, chi-square results are stored in the `"chi2"`
attribute, with `statistic`, `df`, `p_value`, `cramers_v`, and `n`.
Flextables display these results in a footer instead.

## Details

**Counts and percentages**

`tab()`, `tab1()`, `fre()` and `fre1()` report the five statistics
below. Within each group, `n_i` counts category (or combination) `i`,
`N` counts all observations, and `N_valid` counts those complete on
every measured variable. All percentages are on a **0–100 scale**.

- `n`: Number of observations in the category, or sum of weights if
  weighted.

- `percent`: Percentage of all observations, `100 * n_i / N`,
  **including** missing measured values in the denominator.

- `cum`: Cumulative `percent`, summed in the displayed category order.

- `valid`: Percentage of complete observations, `100 * n_i / N_valid`.
  This is `NA` for categories with missing measured values.

- `valid_cum`: Cumulative `valid`, in displayed order, omitting missing
  measured categories.

`percent` uses Stata's `tabulate, missing` denominator; `valid` uses the
denominator from `tabulate` without `missing`. Missing grouping keys do
not make otherwise complete measured values invalid.

**Missing values and category order**

Missing measured values are kept as categories and shown last.
Missingness includes `NA`, `NaN`, tagged missing values, and SPSS
user-missing codes or ranges; empty strings are observed values. Factors
follow their level order; other categories are sorted by value unless
`.desc` requests frequency order. List-column elements are counted as
complete values, not flattened.

**Weighted counts and percentages**

With weight `w_j` for observation `j`:

- **Frequency weights** (`.wt_type = "frequency"`): Category counts are
  `n_i = sum(w_j)` over observations in that category. Weights need not
  be integers.

- **Analytic weights** (`.wt_type = "analytic"`): Weights are rescaled
  within each group to sum to its number of rows. Category counts sum
  the rescaled weights, so the overall count stays on the sample-size
  scale.

- **Percentages:** Both weight types give the same percentages because
  the normalization factor cancels in each group. Cumulative and valid
  percentages use the corresponding weighted counts and denominators.

Rows with missing weights are excluded; negative weights are not
allowed. If `...` is omitted, the weight column is not itself tabulated.

**Totals and value labels**

`fre()` and `fre1()` append a `"Total"` row within each group and may
add `"Valid Total"` and `"Missing Total"` subtotals. `fre2()` adds a
marginal total row and column. `fre()` and `fre1()` display value
labels; `fre2()` displays row-category labels but keeps column headers
based on category codes. `tab()` and `tab1()` retain underlying category
codes and types. Totals may convert a category column to character or
introduce a `total` label column. Distinct category codes remain
separate even if their labels coincide.

**Cross-tabulations and association tests**

`tab2()` and `fre2()` report cell counts rather than the five
percentages listed above. With `.chi2 = TRUE`, Pearson's chi-square test
uses the displayed categories, including missing ones. Filter missing
categories beforehand if they should not contribute to the test. Empty
rows and columns are excluded from the calculation.

Let `O_ij` be an observed cell count, `E_ij` its expected count under
independence, `r` the number of nonempty rows, `c` the number of
nonempty columns, and `N` the total count:

- **Expected counts:** `E_ij = row_total_i * column_total_j / N`.

- **Pearson's chi-square:** `X^2 = sum((O_ij - E_ij)^2 / E_ij)`.

- **Degrees of freedom:** `df = (r - 1) * (c - 1)`.

- **p-value:** Upper-tail probability of a chi-square distribution with
  `df` degrees of freedom.

- **Cramer's V:** `sqrt(X^2 / (N * min(r - 1, c - 1)))`. For 2-by-2
  tables, it is the signed phi coefficient, as in Stata, with the sign
  of `O_11 * O_22 - O_12 * O_21`.

Frequency weights act as cell counts for the test. Analytic weights are
not supported; for complex survey designs, use `survey::svychisq()`.
Cross-tabulation category values become column names, so conflicts with
reserved names such as `"total"` may require recoding.

**Computed variables and groups**

Named expressions in `...` are evaluated before grouping. Use grouped
[`dplyr::mutate()`](https://dplyr.tidyverse.org/reference/mutate.html)
first for group-specific computations. Names that conflict with output
columns are renamed in the result; the input is unchanged.

## Examples

``` r
# Compare the three approaches using the same variables
# Joint frequencies: one long table
tab(lifeexp, region, high = lexp >= 70)
#> # A tibble: 6 × 7
#>   region               high      n percent   cum valid valid_cum
#>   <dbl+lbl>            <lgl> <int>   <dbl> <dbl> <dbl>     <dbl>
#> 1 1 [Europe & C. Asia] FALSE    12   17.6   17.6 17.6       17.6
#> 2 1 [Europe & C. Asia] TRUE     32   47.1   64.7 47.1       64.7
#> 3 2 [North America]    FALSE     6    8.82  73.5  8.82      73.5
#> 4 2 [North America]    TRUE      8   11.8   85.3 11.8       85.3
#> 5 3 [South America]    FALSE     3    4.41  89.7  4.41      89.7
#> 6 3 [South America]    TRUE      7   10.3  100   10.3      100  

# Separate one-way tables: one for region and one for high
tab1(lifeexp, region, high = lexp >= 70)
#> $region
#> # A tibble: 3 × 6
#>   value                    n percent   cum valid valid_cum
#>   <dbl+lbl>            <int>   <dbl> <dbl> <dbl>     <dbl>
#> 1 1 [Europe & C. Asia]    44    64.7  64.7  64.7      64.7
#> 2 2 [North America]       14    20.6  85.3  20.6      85.3
#> 3 3 [South America]       10    14.7 100    14.7     100  
#> 
#> $high
#> # A tibble: 2 × 6
#>   value     n percent   cum valid valid_cum
#>   <lgl> <int>   <dbl> <dbl> <dbl>     <dbl>
#> 1 FALSE    21    30.9  30.9  30.9      30.9
#> 2 TRUE     47    69.1 100    69.1     100  
#> 

# Two-way cross-tabulation: region by high
tab2(lifeexp, region, high = lexp >= 70)
#> # A tibble: 3 × 3
#>   `region \\ high`     `FALSE` `TRUE`
#>   <dbl+lbl>              <int>  <int>
#> 1 1 [Europe & C. Asia]      12     32
#> 2 2 [North America]          6      8
#> 3 3 [South America]          3      7

# Add totals and display value labels
fre(lifeexp, region)
#> # A tibble: 4 × 6
#>   region               n percent   cum valid valid_cum
#>   <chr>            <int>   <dbl> <dbl> <dbl>     <dbl>
#> 1 Europe & C. Asia    44    64.7  64.7  64.7      64.7
#> 2 North America       14    20.6  85.3  20.6      85.3
#> 3 South America       10    14.7 100    14.7     100  
#> 4 Total               68   100    NA    NA        NA  

fre2(lifeexp, region, high = lexp >= 70)
#> # A tibble: 4 × 4
#>   `region \\ high` `FALSE` `TRUE` total
#>   <chr>              <int>  <int> <int>
#> 1 Europe & C. Asia      12     32    44
#> 2 North America          6      8    14
#> 3 South America          3      7    10
#> 4 total                 21     47    68

# Frequencies within groups
tab(lifeexp, high = lexp >= 70, .by = region)
#> # A tibble: 6 × 7
#>   region               high      n percent   cum valid valid_cum
#>   <dbl+lbl>            <lgl> <int>   <dbl> <dbl> <dbl>     <dbl>
#> 1 1 [Europe & C. Asia] FALSE    12    27.3  27.3  27.3      27.3
#> 2 1 [Europe & C. Asia] TRUE     32    72.7 100    72.7     100  
#> 3 2 [North America]    FALSE     6    42.9  42.9  42.9      42.9
#> 4 2 [North America]    TRUE      8    57.1 100    57.1     100  
#> 5 3 [South America]    FALSE     3    30    30    30        30  
#> 6 3 [South America]    TRUE      7    70   100    70       100  

# Continuous variables: count each distinct value, then shorten the display
tab(lifeexp, lexp) |> print_headtail(n = 6)
#> # A tibble: 20 × 6
#>     lexp     n percent    cum valid valid_cum
#>    <dbl> <int>   <dbl>  <dbl> <dbl>     <dbl>
#>  1    57     1    1.47   1.47  1.47      1.47
#>  2    61     1    1.47   2.94  1.47      2.94
#>  3    62     2    2.94   5.88  2.94      5.88
#>  ⋮     ⋮     ⋮     ⋮      ⋮     ⋮         ⋮  
#> 18    77     5    7.35  85.3   7.35     85.3 
#> 19    78     4    5.88  91.2   5.88     91.2 
#> 20    79     6    8.82 100     8.82    100   
#> # ... 14 rows omitted in the middle; use print(x, n = Inf) to show all rows.

tab(lifeexp, lexp) |> print_interval(n = 6)
#> # A tibble: 20 × 6
#>     lexp     n percent    cum valid valid_cum
#>    <dbl> <int>   <dbl>  <dbl> <dbl>     <dbl>
#>  1    57     1    1.47   1.47  1.47      1.47
#>  5    64     3    4.41  11.8   4.41     11.8 
#>  9    68     3    4.41  25     4.41     25   
#> 12    71     6    8.82  47.1   8.82     47.1 
#> 16    75     4    5.88  72.1   5.88     72.1 
#> 20    79     6    8.82 100     8.82    100   
#> # ... 14 rows omitted between displayed positions; use print(x, n = Inf) to
#> # show all rows.

# Pearson's chi-square and Cramer's V
result <- tab2(lifeexp, region, high = lexp >= 70, .chi2 = TRUE)
#> Pearson chi2(2) = 1.2127   Pr = 0.545
#> Cramer's V = 0.1335
attr(result, "chi2")
#> # A tibble: 1 × 5
#>   statistic    df p_value cramers_v     n
#>       <dbl> <int>   <dbl>     <dbl> <int>
#> 1      1.21     2   0.545     0.134    68

# Frequency weights
survey <- tibble::tibble(response = c("yes", "no", "yes"), w = c(2, 1, 3))
tab(survey, response, .wt = w)
#> # A tibble: 2 × 6
#>   response     n percent   cum valid valid_cum
#>   <chr>    <dbl>   <dbl> <dbl> <dbl>     <dbl>
#> 1 no           1    16.7  16.7  16.7      16.7
#> 2 yes          5    83.3 100    83.3     100  
```
