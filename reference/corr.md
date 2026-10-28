# Calculate Pearson and Spearman correlations

Calculate correlations between selected variables, with optional
grouping:

- `corr()`: Calculate Pearson correlations on one common complete
  sample, like Stata's `corr` (`correlate`), reporting correlations and
  counts.

- `pwcorr()`: Calculate Pearson correlations using a separate sample for
  each pair by default, like Stata's `pwcorr, sig obs`, reporting
  correlations, counts and p-values. Spearman correlations and a common
  sample are optional.

- `spearman()`: Calculate Spearman rank correlations on one common
  complete sample by default, like Stata's `spearman, stats(rho obs p)`,
  reporting correlations, counts and p-values. Pairwise samples are
  optional.

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
  column except grouping keys and the weight column; other columns are
  then skipped. Explicitly selecting another type is an error.

- .by:

  \<[`tidy-select`](https://dplyr.tidyverse.org/reference/dplyr_tidy_select.html)\>
  Optional grouping variables. Grouped data use their groups unless
  `.by` is supplied. Select existing columns only; create new grouping
  columns with
  [`dplyr::mutate()`](https://dplyr.tidyverse.org/reference/mutate.html)
  first.

- .wide:

  If `TRUE`, return a lower-triangular correlation table, like Stata's
  display, without counts or p-values. Defaults to `FALSE` (long).

- .wt:

  Optional numeric weights for `corr()` and Pearson `pwcorr()`, given as
  a column of `.data` or one value per row, like Stata's
  `[fweight/aweight]`. Missing weights exclude rows with a message;
  negative weights are invalid. Spearman correlations do not support
  weights.

- .wt_type:

  For `corr()` and Pearson `pwcorr()`, `"frequency"` (default) reports
  summed weights as `n`; `"analytic"` reports the number of observed
  rows. Both give the same weighted correlation. In `pwcorr()`, the
  choice also affects p-values. See Details for zero-weight handling.

- .method:

  For `pwcorr()`, `"pearson"` (default) or `"spearman"`. `corr()` always
  uses Pearson correlations; `spearman()` always uses ranks.

- .listwise:

  For `pwcorr()`, use one common complete sample if `TRUE`, like Stata's
  `listwise` (`casewise`). Defaults to `FALSE` (pairwise). `corr()`
  always uses a common sample; `spearman()` does so by default.

- .adjust:

  For `pwcorr()` and `spearman()`, `"none"` (default), `"bonferroni"` or
  `"sidak"`, like Stata's corresponding options. Adjust p-values
  separately within each group; not available with `.wide = TRUE`.

- .pairwise:

  For `spearman()`, use a separate sample for each pair if `TRUE`, like
  Stata's `pw`. Defaults to `FALSE` (one common complete sample).

## Value

An ungrouped tibble with:

- By default, one row per distinct variable pair and group, with
  grouping keys, `var1`, `var2`, `r` (Pearson correlation or Spearman's
  rho), and `n` (observations or summed frequency weights). `pwcorr()`
  and `spearman()` also return `p` (two-sided p-value); `corr()` omits
  it.

- With `.wide = TRUE`, one row per variable and group, with grouping
  keys, `variable`, and one correlation column per variable. The
  diagonal is 1 and the upper triangle is `NA`; `n` and `p` are omitted.

Variables and pairs follow selection order within each group. Undefined
correlations and p-values are `NA`. With `n < 3`, `p` is `NA` even when
the correlation is defined; frequency-weighted `n` is the summed weight.
Empty grouped inputs return zero rows. The input is not modified.

## Details

**Selection, samples and groups**

Select at least two numeric or logical vector columns. Labelled numeric
columns use their codes; tagged and SPSS user-missing values are
excluded before determining samples. Missing values in unselected
columns do not affect the sample. Grouping keys must not conflict with
output column names; wide output also reserves `variable` and the
selected variable names for its columns.

Listwise deletion excludes rows missing any selected variable, so every
pair within a group uses the same sample and has the same `n`. Pairwise
deletion uses every row where both variables in that pair are observed.
Groups with fewer than two observations retain their pairs with
undefined correlations (`NA`).

Computed columns are evaluated on ungrouped working data before samples
and groups are processed. Create columns with grouped
[`dplyr::mutate()`](https://dplyr.tidyverse.org/reference/mutate.html)
first for calculations that need to run separately within each group.

With the same selections and weights, Pearson `pwcorr(.listwise = TRUE)`
gives the same correlations and counts as `corr()`, retaining p-values.
`spearman()` is equivalent to
`pwcorr(.method = "spearman", .listwise = TRUE)`; with
`.pairwise = TRUE`, it is equivalent to `pwcorr(.method = "spearman")`.

**Weights**

Weights must be finite and nonnegative. Fractional frequency weights are
accepted, extending Stata's integer frequency-weight convention.
Zero-weight rows do not contribute to the correlation. With pairwise
Pearson samples, analytic `n` includes complete zero-weight rows; with a
common sample, these rows are excluded from both the sample and `n`.
This also affects p-values.

**Inference**

Pearson p-values use `t = r * sqrt((n - 2) / (1 - r^2))` with `n - 2`
degrees of freedom. For unweighted data this matches
[`stats::cor.test()`](https://rdrr.io/r/stats/cor.test.html).

Spearman ties receive average ranks, computed within each sample used
for a correlation. P-values test independence as Stata 18 and later do:
a beta distribution is fitted to the first four exact permutation
moments of the statistic, with a normal approximation,
`sqrt(n - 1) * r`, when `n = 3` or no valid fit exists. Earlier Stata
versions and
[`stats::cor.test()`](https://rdrr.io/r/stats/cor.test.html) use other
approximations, so their p-values can differ. A constant variable gives
`NA`, where Stata's `spearman` reports a correlation of 1.

With `k` distinct variable pairs within a group, Bonferroni and Sidak
adjustments are `min(1, k * p)` and `min(1, 1 - (1 - p)^k)`,
respectively. Each group's `k` includes pairs whose p-value is `NA`;
adjustment does not combine tests across groups.

**Stata options**

Stata's `covariance`, `means`, and display-formatting options are not
implemented. Use [`stats::cov()`](https://rdrr.io/r/stats/cor.html) for
covariance and
[`summ()`](https://socimh.github.io/tidystata/reference/summ.md) for
summaries. The tidy long table is an R interface choice; Stata prints a
matrix. Display options `star()` and
[`print()`](https://rdrr.io/r/base/print.html) are also omitted: filter
the result instead, for example with `dplyr::filter(p < 0.05)`.

## References

[Stata correlate manual](https://www.stata.com/manuals/rcorrelate.pdf),
[Stata spearman manual](https://www.stata.com/manuals/rspearman.pdf).

## See also

[`stats::cor()`](https://rdrr.io/r/stats/cor.html),
[`stats::cor.test()`](https://rdrr.io/r/stats/cor.test.html)

## Examples

``` r
corr(lifeexp, lexp, gnppc, safewater)
#> # A tibble: 3 × 4
#>   var1  var2          r     n
#>   <chr> <chr>     <dbl> <int>
#> 1 lexp  gnppc     0.777    53
#> 2 lexp  safewater 0.761    53
#> 3 gnppc safewater 0.657    53

pwcorr(lifeexp, lexp, gnppc, safewater)
#> # A tibble: 3 × 5
#>   var1  var2          r     n        p
#>   <chr> <chr>     <dbl> <int>    <dbl>
#> 1 lexp  gnppc     0.733    67 1.79e-12
#> 2 lexp  safewater 0.760    54 2.74e-11
#> 3 gnppc safewater 0.657    53 8.95e- 8

spearman(lifeexp, lexp, gnppc, safewater)
#> # A tibble: 3 × 5
#>   var1  var2          r     n        p
#>   <chr> <chr>     <dbl> <int>    <dbl>
#> 1 lexp  gnppc     0.864    53 5.61e-14
#> 2 lexp  safewater 0.799    53 2.48e-11
#> 3 gnppc safewater 0.800    53 2.20e-11

# Return a correlation table, or calculate correlations by group
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

# Correlate an existing column with a computed column
corr(lifeexp, lexp, gnppc_k = gnppc / 1000)
#> # A tibble: 1 × 4
#>   var1  var2        r     n
#>   <chr> <chr>   <dbl> <int>
#> 1 lexp  gnppc_k 0.733    67

# Pairwise Spearman correlations with adjusted p-values
spearman(lifeexp, lexp, gnppc, safewater,
  .pairwise = TRUE, .adjust = "bonferroni"
)
#> # A tibble: 3 × 5
#>   var1  var2          r     n        p
#>   <chr> <chr>     <dbl> <int>    <dbl>
#> 1 lexp  gnppc     0.861    67 1.01e-16
#> 2 lexp  safewater 0.800    54 4.32e-11
#> 3 gnppc safewater 0.800    53 6.59e-11

# Spearman correlations on one common sample using pwcorr()
pwcorr(lifeexp, lexp, gnppc, safewater,
  .method = "spearman", .listwise = TRUE
)
#> # A tibble: 3 × 5
#>   var1  var2          r     n        p
#>   <chr> <chr>     <dbl> <int>    <dbl>
#> 1 lexp  gnppc     0.864    53 5.61e-14
#> 2 lexp  safewater 0.799    53 2.48e-11
#> 3 gnppc safewater 0.800    53 2.20e-11

# Pearson correlations on one common sample, retaining adjusted p-values
pwcorr(lifeexp, lexp, gnppc, safewater,
  .listwise = TRUE, .adjust = "bonferroni"
)
#> # A tibble: 3 × 5
#>   var1  var2          r     n        p
#>   <chr> <chr>     <dbl> <int>    <dbl>
#> 1 lexp  gnppc     0.777    53 2.27e-11
#> 2 lexp  safewater 0.761    53 1.13e-10
#> 3 gnppc safewater 0.657    53 2.69e- 7
```
