# Calculate complete-case Pearson correlations

Calculate correlations using one common sample, like Stata's `corr`
(`correlate`). Rows missing any selected variable are excluded from
every correlation. Use
[`pwcorr()`](https://socimh.github.io/tidystata/reference/pwcorr.md) to
use a separate sample for each pair instead.

## Usage

``` r
corr(
  .data,
  ...,
  .by = NULL,
  .wide = FALSE,
  .wt = NULL,
  .wt_type = c("frequency", "analytic")
)
```

## Arguments

- .data:

  A data frame, tibble, or data.table.

- ...:

  \<[`tidy-select`](https://dplyr.tidyverse.org/reference/dplyr_tidy_select.html)\>
  or
  \<[`data-masking`](https://rlang.r-lib.org/reference/args_data_masking.html)\>
  Columns to select or compute with
  [`select_or_transmute()`](https://socimh.github.io/tidystata/reference/select_or_transmute.md).
  Existing columns, selection helpers, and named expressions can be
  mixed. Results must be numeric or logical vector columns. Matrix
  columns are unsupported. Omit to use every numeric or logical vector
  column; other columns are then skipped. Selecting another type is an
  error.

- .by:

  \<[`tidy-select`](https://dplyr.tidyverse.org/reference/dplyr_tidy_select.html)\>
  Optional grouping variables. Grouped data use their groups unless
  `.by` is supplied. Select existing columns only; create new grouping
  columns with
  [`dplyr::mutate()`](https://dplyr.tidyverse.org/reference/mutate.html)
  first.

- .wide:

  If `TRUE`, return a lower-triangular correlation table with one row
  per variable, like Stata's display. The default is a long table.

- .wt:

  Optional weights: a numeric column of `.data` (or a vector with one
  value per row), like Stata's `pwcorr [fweight/aweight]`. Pearson
  correlations only. Rows with a missing weight are excluded with a
  message.

- .wt_type:

  `"frequency"` (default) reports the sum of weights as `n`;
  `"analytic"` reports the number of complete observations with positive
  weights. Both give the same weighted correlation. Zero-weight rows are
  excluded. Like
  [`pwcorr()`](https://socimh.github.io/tidystata/reference/pwcorr.md),
  fractional frequency weights are accepted, extending Stata's integer
  frequency-weight convention.

## Value

An ungrouped tibble with one row per distinct variable pair and group:
any grouping keys, `var1`, `var2`, `r` (Pearson correlation), and `n`
(complete observations or summed frequency weight). Every pair within a
group uses the same sample and has the same `n`. P-values are omitted.
With `.wide = TRUE`, columns are grouping keys, `variable`, and one
correlation column per variable; the diagonal is 1 and the upper
triangle is `NA`. Undefined correlations are `NA`.

## Details

Select at least two numeric or logical vector columns. When `...` is
omitted, nonnumeric columns and grouping keys are skipped, as in
[`pwcorr()`](https://socimh.github.io/tidystata/reference/pwcorr.md).
Labelled numeric columns use their codes; tagged and SPSS user-missing
values are excluded before determining the common sample. Missing values
in unselected columns do not affect the sample.

Computed columns are evaluated on ungrouped working data before complete
cases and groups are processed. Create columns with grouped
[`dplyr::mutate()`](https://dplyr.tidyverse.org/reference/mutate.html)
first for calculations that need to run separately within each group.
Groups with fewer than two complete observations retain their pairs with
correlations of `NA`; empty grouped inputs return zero rows. The input
is not modified.

Like Stata's correlation mode, this function computes Pearson
correlations. Stata's `covariance`, `means`, and display-formatting
options are not implemented. Use
[`stats::cov()`](https://rdrr.io/r/stats/cor.html) for covariance and
[`summ()`](https://socimh.github.io/tidystata/reference/summ.md) for
summaries. The tidy long table is an R interface choice; Stata prints a
matrix.

## References

[Stata correlate manual](https://www.stata.com/manuals/rcorrelate.pdf).

## See also

[`pwcorr()`](https://socimh.github.io/tidystata/reference/pwcorr.md),
[`stats::cor()`](https://rdrr.io/r/stats/cor.html)

Other tabulation functions:
[`pwcorr()`](https://socimh.github.io/tidystata/reference/pwcorr.md),
[`tab()`](https://socimh.github.io/tidystata/reference/tab.md)

## Examples

``` r
corr(lifeexp, lexp, gnppc, safewater)
#> # A tibble: 3 x 4
#>   var1  var2          r     n
#>   <chr> <chr>     <dbl> <int>
#> 1 lexp  gnppc     0.777    53
#> 2 lexp  safewater 0.761    53
#> 3 gnppc safewater 0.657    53

corr(lifeexp, lexp, gnppc, safewater, .wide = TRUE)
#> # A tibble: 3 x 4
#>   variable   lexp  gnppc safewater
#>   <chr>     <dbl>  <dbl>     <dbl>
#> 1 lexp      1     NA            NA
#> 2 gnppc     0.777  1            NA
#> 3 safewater 0.761  0.657         1

corr(lifeexp, lexp, gnppc, safewater, .by = region)
#> # A tibble: 9 x 5
#>   region               var1  var2          r     n
#>   <dbl+lbl>            <chr> <chr>     <dbl> <int>
#> 1 1 [Europe & C. Asia] lexp  gnppc     0.796    41
#> 2 1 [Europe & C. Asia] lexp  safewater 0.789    41
#> 3 1 [Europe & C. Asia] gnppc safewater 0.653    41
#> 4 2 [North America]    lexp  gnppc     0.873     6
#> 5 2 [North America]    lexp  safewater 0.788     6
#> 6 2 [North America]    gnppc safewater 0.931     6
#> 7 3 [South America]    lexp  gnppc     0.484     6
#> 8 3 [South America]    lexp  safewater 0.713     6
#> 9 3 [South America]    gnppc safewater 0.897     6

corr(lifeexp, lexp, gnppc_thousands = gnppc / 1000)
#> # A tibble: 1 x 4
#>   var1  var2                r     n
#>   <chr> <chr>           <dbl> <int>
#> 1 lexp  gnppc_thousands 0.733    67

# Compare listwise and pairwise samples
survey <- tibble::tibble(
  x = c(1, 2, 3, 4), y = c(2, 3, NA, 5), z = c(1, NA, 4, 3)
)
corr(survey)
#> # A tibble: 3 x 4
#>   var1  var2      r     n
#>   <chr> <chr> <dbl> <int>
#> 1 x     y         1     2
#> 2 x     z         1     2
#> 3 y     z         1     2

pwcorr(survey)
#> # A tibble: 3 x 5
#>   var1  var2      r     n      p
#>   <chr> <chr> <dbl> <int>  <dbl>
#> 1 x     y     1         3  0    
#> 2 x     z     0.786     3  0.425
#> 3 y     z     1         2 NA    
```
