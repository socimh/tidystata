# Calculate pairwise correlations

Calculate pairwise correlations, like Stata's `pwcorr, sig obs`. Each
pair of variables uses every row where both are observed (pairwise
deletion), and the table reports the correlation, the number of
observations and the p-value.

## Usage

``` r
pwcorr(
  .data,
  ...,
  .by = NULL,
  .method = c("pearson", "spearman"),
  .wide = FALSE,
  .wt = NULL,
  .wt_type = c("frequency", "analytic"),
  .listwise = FALSE,
  .adjust = c("none", "bonferroni", "sidak")
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

- .method:

  `"pearson"` (default) or `"spearman"`, like Stata's `pwcorr` and
  `spearman, pw`.
  [`spearman()`](https://socimh.github.io/tidystata/reference/spearman.md)
  gives Spearman correlations with Stata's default casewise deletion.

- .wide:

  If `TRUE`, return the correlation matrix as Stata prints it: one row
  per variable and the lower triangle filled, without `n` or `p`.

- .wt:

  Optional weights: a numeric column of `.data` (or a vector with one
  value per row), like Stata's `pwcorr [fweight/aweight]`. Pearson
  correlations only. Rows with a missing weight are excluded with a
  message.

- .wt_type:

  `"frequency"` (default) or `"analytic"`. The correlation is the same
  under both; with frequency weights, `n` and the p-value use the summed
  weight, and with analytic weights the number of observed rows. See
  Details for zero-weight handling.

- .listwise:

  If `TRUE`, use only rows where every selected variable is observed,
  like Stata's `pwcorr, listwise`. Every pair then has the same `n`.
  Unlike
  [`corr()`](https://socimh.github.io/tidystata/reference/corr.md), `p`
  is kept.

- .adjust:

  `"none"` (default), `"bonferroni"` or `"sidak"`, like Stata's
  `bonferroni` and `sidak` options. Adjust p-values separately within
  each group; not available with `.wide = TRUE`.

## Value

An ungrouped tibble with:

- By default, one row per distinct variable pair and group, with any
  grouping keys, `var1`, `var2`, `r` (correlation), `n` (observations or
  summed frequency weight), and `p` (two-sided p-value).

- With `.wide = TRUE`, one row per variable and group, with grouping
  keys, `variable`, and one correlation column per variable. The
  diagonal is 1 and the upper triangle is `NA`; `n` and `p` are omitted.

Undefined correlations and p-values are `NA` (see Details).

## Details

Computed columns are evaluated on ungrouped working data before
correlations are calculated within groups. Create columns with grouped
[`dplyr::mutate()`](https://dplyr.tidyverse.org/reference/mutate.html)
first when a calculation needs to run separately within each group.

Labelled numeric columns are correlated on their codes, excluding tagged
and SPSS user-missing values. Use
[`corr()`](https://socimh.github.io/tidystata/reference/corr.md) for
listwise Pearson correlations, like Stata's `corr` (`correlate`).

Weights must be finite and nonnegative. Fractional frequency weights are
accepted, extending Stata's integer frequency-weight convention.
Zero-weight rows do not contribute to the correlation. With pairwise
deletion, analytic `n` includes complete zero-weight rows; with
`.listwise = TRUE`, these rows are excluded from the common sample and
from `n`. This also affects p-values.

The p-value is the two-sided test of zero correlation that Stata
reports. For Pearson correlations it is based on
`t = r * sqrt((n - 2) / (1 - r^2))` with `n - 2` degrees of freedom and
matches [`cor.test()`](https://rdrr.io/r/stats/cor.test.html). For
Spearman correlations it is the beta approximation of Stata 18 and
later; see
[`spearman()`](https://socimh.github.io/tidystata/reference/spearman.md).
Correlations with a constant variable, and p-values with fewer than
three observations, are `NA`.

With `k` distinct variable pairs within a group, Bonferroni and Sidak
adjustments are `min(1, k * p)` and `min(1, 1 - (1 - p)^k)`,
respectively. Each group's `k` includes pairs whose p-value is `NA`;
adjustment does not combine tests across groups.

Stata's display options `star()` and
[`print()`](https://rdrr.io/r/base/print.html) are not implemented,
because the result is a data frame: filter it instead, for example with
`dplyr::filter(p < 0.05)`. Use `.listwise = TRUE` for Stata's
`casewise`.

## See also

Other tabulation functions:
[`corr()`](https://socimh.github.io/tidystata/reference/corr.md),
[`spearman()`](https://socimh.github.io/tidystata/reference/spearman.md),
[`tab()`](https://socimh.github.io/tidystata/reference/tab.md)

## Examples

``` r
pwcorr(lifeexp, lexp, gnppc, safewater)
#> # A tibble: 3 × 5
#>   var1  var2          r     n        p
#>   <chr> <chr>     <dbl> <int>    <dbl>
#> 1 lexp  gnppc     0.733    67 1.79e-12
#> 2 lexp  safewater 0.760    54 2.74e-11
#> 3 gnppc safewater 0.657    53 8.95e- 8

pwcorr(lifeexp, lexp, gnppc, safewater, .wide = TRUE)
#> # A tibble: 3 × 4
#>   variable   lexp  gnppc safewater
#>   <chr>     <dbl>  <dbl>     <dbl>
#> 1 lexp      1     NA            NA
#> 2 gnppc     0.733  1            NA
#> 3 safewater 0.760  0.657         1

pwcorr(lifeexp, lexp, gnppc, .by = region)
#> # A tibble: 3 × 6
#>   region               var1  var2      r     n        p
#>   <dbl+lbl>            <chr> <chr> <dbl> <int>    <dbl>
#> 1 1 [Europe & C. Asia] lexp  gnppc 0.792    43 2.57e-10
#> 2 2 [North America]    lexp  gnppc 0.658    14 1.05e- 2
#> 3 3 [South America]    lexp  gnppc 0.640    10 4.60e- 2

pwcorr(lifeexp, lexp, gnppc, .method = "spearman")
#> # A tibble: 1 × 5
#>   var1  var2      r     n        p
#>   <chr> <chr> <dbl> <int>    <dbl>
#> 1 lexp  gnppc 0.861    67 3.37e-17

# One common sample, with Bonferroni-adjusted p-values
pwcorr(
  lifeexp, lexp, gnppc, safewater,
  .listwise = TRUE, .adjust = "bonferroni"
)
#> # A tibble: 3 × 5
#>   var1  var2          r     n        p
#>   <chr> <chr>     <dbl> <int>    <dbl>
#> 1 lexp  gnppc     0.777    53 2.27e-11
#> 2 lexp  safewater 0.761    53 1.13e-10
#> 3 gnppc safewater 0.657    53 2.69e- 7

# Correlate an existing column with a computed column
pwcorr(lifeexp, lexp, gnppc_thousands = gnppc / 1000)
#> # A tibble: 1 × 5
#>   var1  var2                r     n        p
#>   <chr> <chr>           <dbl> <int>    <dbl>
#> 1 lexp  gnppc_thousands 0.733    67 1.79e-12
```
