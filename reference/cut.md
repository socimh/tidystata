# Cut a numeric vector into groups

- `xtile()` creates `n` quantile groups, following Stata's `xtile`.

- `cut_length()` creates `n` intervals of equal length.

- `cut_breaks()` cuts at given cutpoints.

`cut_quantile()` is an alias of `xtile()`.

## Usage

``` r
xtile(x, n = 4, labels = NULL, method = c("quantile", "rank"), wt = NULL)

cut_quantile(
  x,
  n = 4,
  labels = NULL,
  method = c("quantile", "rank"),
  wt = NULL
)

cut_length(x, n = 4, labels = NULL)

cut_breaks(x, breaks = NULL, labels = NULL, right = TRUE)
```

## Arguments

- x:

  A numeric vector. `xtile()` also accepts a logical vector, treated as
  0/1.

- n:

  A positive integer. The number of intervals.

- labels:

  labels for the levels of the resulting category. By default, labels
  are constructed using `"(a,b]"` interval notation. If
  `labels = FALSE`, simple integer codes are returned instead of a
  factor.

- method:

  Quantile boundaries (`"quantile"`, the default), or balanced rank
  groups (`"rank"`). Rank groups may split ties, breaking them by
  original position. They differ in size by at most one; earlier groups
  get extra rows.

- wt:

  Optional weights for `xtile()`, one per element of `x`, like Stata's
  `xtile ... [aweight = w]`. Cutpoints then follow Stata's weighted
  percentile rule; elements with a missing weight get a missing code.
  Not available with `method = "rank"`.

- breaks:

  Numeric cutpoints for `cut_breaks()`. The observed minimum and maximum
  are included automatically. `NULL` uses the observed median as an
  interior cutpoint. A single number supplies one interior cutpoint,
  rather than the number of intervals.

- right:

  logical, indicating if the intervals should be closed on the right
  (and open on the left) or vice versa.

## Value

An ordered factor, or integer interval codes when `labels = FALSE` or
when `xtile()` runs in a grouped data mask with default labels.

## Details

`xtile()` follows Stata's `xtile` rule with type-7 quantile cutpoints at
`1/n, 2/n, ...`: each value joins the first group whose cutpoint is at
least that value. Equal values stay in the same group and distinct
values are never merged, so a 0/1 dummy always gives two groups. Ties
can leave fewer than `n` groups; occupied groups are then numbered
consecutively and a warning is given. Default labels are the contiguous
intervals covered by each group, for example `"[0,0]"` and `"(0,1]"`.
Custom labels must match the effective number of groups. Empty and
all-missing vectors are rejected. Constant vectors are rejected only by
the default quantile method. Cutpoints are not promised to match Stata's
percentile definition exactly.

`labels = NULL` (the default) or `TRUE` gives interval labels; `FALSE`
gives integer codes. Inside grouped
[`dplyr::mutate()`](https://dplyr.tidyverse.org/reference/mutate.html),
each group has its own cutpoints and interval labels, which cannot be
combined, so the default returns integer codes within each group (like
Stata's `xtile, by()`). Supply `labels = TRUE` to request labels there
anyway.

Rank groups omit missing observations when ranking, then restore missing
output positions. If `n` exceeds the observed count, use one group per
observation and warn. Default rank labels are `"1"` through the
effective group count; custom labels must match that count.

## See also

Other variable generation functions:
[`as_dummy()`](https://socimh.github.io/tidystata/reference/as_dummy.md),
[`panel`](https://socimh.github.io/tidystata/reference/panel.md),
[`row_egen`](https://socimh.github.io/tidystata/reference/row_egen.md),
[`std()`](https://socimh.github.io/tidystata/reference/std.md)

## Examples

``` r
xtile(1:20)
#>  [1] [1,5.75]    [1,5.75]    [1,5.75]    [1,5.75]    [1,5.75]    (5.75,10.5]
#>  [7] (5.75,10.5] (5.75,10.5] (5.75,10.5] (5.75,10.5] (10.5,15.2] (10.5,15.2]
#> [13] (10.5,15.2] (10.5,15.2] (10.5,15.2] (15.2,20]   (15.2,20]   (15.2,20]  
#> [19] (15.2,20]   (15.2,20]  
#> Levels: [1,5.75] < (5.75,10.5] < (10.5,15.2] < (15.2,20]
xtile(c(0, 0, 0, 1, 1), 2)
#> [1] [0,0] [0,0] [0,0] (0,1] (0,1]
#> Levels: [0,0] < (0,1]

cut_length(1:20)
#>  [1] [1,5.75]    [1,5.75]    [1,5.75]    [1,5.75]    [1,5.75]    (5.75,10.5]
#>  [7] (5.75,10.5] (5.75,10.5] (5.75,10.5] (5.75,10.5] (10.5,15.2] (10.5,15.2]
#> [13] (10.5,15.2] (10.5,15.2] (10.5,15.2] (15.2,20]   (15.2,20]   (15.2,20]  
#> [19] (15.2,20]   (15.2,20]  
#> Levels: [1,5.75] < (5.75,10.5] < (10.5,15.2] < (15.2,20]

cut_breaks(1:20, breaks = c(5, 15))
#>  [1] [1,5]   [1,5]   [1,5]   [1,5]   [1,5]   (5,15]  (5,15]  (5,15]  (5,15] 
#> [10] (5,15]  (5,15]  (5,15]  (5,15]  (5,15]  (5,15]  (15,20] (15,20] (15,20]
#> [19] (15,20] (15,20]
#> Levels: [1,5] < (5,15] < (15,20]
cut_breaks(1:20, breaks = 10)
#>  [1] [1,10]  [1,10]  [1,10]  [1,10]  [1,10]  [1,10]  [1,10]  [1,10]  [1,10] 
#> [10] [1,10]  (10,20] (10,20] (10,20] (10,20] (10,20] (10,20] (10,20] (10,20]
#> [19] (10,20] (10,20]
#> Levels: [1,10] < (10,20]
```
