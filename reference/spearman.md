# Calculate Spearman rank correlations

Calculate Spearman rank correlations, like Stata's
`spearman, stats(rho obs p)`. By default, as in Stata, rows missing any
selected variable are excluded from every correlation (casewise
deletion). Use `.pairwise = TRUE` for Stata's `pw` option.

## Usage

``` r
spearman(
  .data,
  ...,
  .by = NULL,
  .pairwise = FALSE,
  .wide = FALSE,
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

- .pairwise:

  If `TRUE`, each pair uses every row where both variables are observed,
  like Stata's `spearman, pw`. The default `FALSE` uses one common
  complete sample.

- .wide:

  If `TRUE`, return the correlation matrix as Stata prints it: one row
  per variable and the lower triangle filled, without `n` or `p`.

- .adjust:

  `"none"` (default), `"bonferroni"` or `"sidak"`, like Stata's
  `bonferroni` and `sidak` options. Adjust p-values separately within
  each group; not available with `.wide = TRUE`.

## Value

An ungrouped tibble with:

- By default, one row per distinct variable pair and group, with any
  grouping keys, `var1`, `var2`, `r` (Spearman's rho), `n`
  (observations), and `p` (two-sided p-value).

- With `.wide = TRUE`, one row per variable and group, with grouping
  keys, `variable`, and one correlation column per variable. The
  diagonal is 1 and the upper triangle is `NA`; `n` and `p` are omitted.

Undefined correlations and p-values are `NA`. With fewer than three
observations, `p` is `NA` even when the correlation is defined.

## Details

Ties receive average ranks, and ranks are computed within each sample
used for a correlation. The p-value tests independence as Stata 18 and
later do: a beta distribution is fitted to the first four exact
permutation moments of the statistic, with a normal approximation,
`sqrt(n - 1) * r`, when `n = 3` or no valid fit exists. Earlier Stata
versions and
[`stats::cor.test()`](https://rdrr.io/r/stats/cor.test.html) use other
approximations, so their p-values can differ. Columns are selected,
computed and grouped as in
[`pwcorr()`](https://socimh.github.io/tidystata/reference/pwcorr.md).
Like Stata's `spearman`, weights are not supported. A constant variable
gives `NA`, where Stata reports a correlation of 1.

`spearman()` is the same as
`pwcorr(.method = "spearman", .listwise = TRUE)`; with
`.pairwise = TRUE` it is the same as `pwcorr(.method = "spearman")`.

## References

[Stata spearman manual](https://www.stata.com/manuals/rspearman.pdf).

## See also

[`pwcorr()`](https://socimh.github.io/tidystata/reference/pwcorr.md),
[`corr()`](https://socimh.github.io/tidystata/reference/corr.md),
[`stats::cor()`](https://rdrr.io/r/stats/cor.html)

Other tabulation functions:
[`corr()`](https://socimh.github.io/tidystata/reference/corr.md),
[`pwcorr()`](https://socimh.github.io/tidystata/reference/pwcorr.md),
[`tab()`](https://socimh.github.io/tidystata/reference/tab.md)

## Examples

``` r
spearman(lifeexp, lexp, gnppc, safewater)
#> # A tibble: 3 × 5
#>   var1  var2          r     n        p
#>   <chr> <chr>     <dbl> <int>    <dbl>
#> 1 lexp  gnppc     0.864    53 5.61e-14
#> 2 lexp  safewater 0.799    53 2.48e-11
#> 3 gnppc safewater 0.800    53 2.20e-11

spearman(lifeexp, lexp, gnppc, safewater, .pairwise = TRUE)
#> # A tibble: 3 × 5
#>   var1  var2          r     n        p
#>   <chr> <chr>     <dbl> <int>    <dbl>
#> 1 lexp  gnppc     0.861    67 3.37e-17
#> 2 lexp  safewater 0.800    54 1.44e-11
#> 3 gnppc safewater 0.800    53 2.20e-11

spearman(lifeexp, lexp, gnppc, .by = region)
#> # A tibble: 3 × 6
#>   region               var1  var2      r     n        p
#>   <dbl+lbl>            <chr> <chr> <dbl> <int>    <dbl>
#> 1 1 [Europe & C. Asia] lexp  gnppc 0.880    43 4.06e-12
#> 2 2 [North America]    lexp  gnppc 0.878    14 1.63e- 4
#> 3 3 [South America]    lexp  gnppc 0.740    10 1.72e- 2

spearman(lifeexp, lexp, gnppc, safewater, .adjust = "bonferroni")
#> # A tibble: 3 × 5
#>   var1  var2          r     n        p
#>   <chr> <chr>     <dbl> <int>    <dbl>
#> 1 lexp  gnppc     0.864    53 1.68e-13
#> 2 lexp  safewater 0.799    53 7.44e-11
#> 3 gnppc safewater 0.800    53 6.59e-11

spearman(lifeexp, lexp, gnppc, safewater, .wide = TRUE)
#> # A tibble: 3 × 4
#>   variable   lexp  gnppc safewater
#>   <chr>     <dbl>  <dbl>     <dbl>
#> 1 lexp      1     NA            NA
#> 2 gnppc     0.864  1            NA
#> 3 safewater 0.799  0.800         1
```
