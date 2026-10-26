# Cut a numeric vector into groups

Group numeric values using quantiles, equal widths, or chosen cutpoints:

- `xtile()` (`cut_quantile()`): Create `n` quantile groups, following
  Stata's `xtile`.

- `cut_length()`: Create `n` intervals of equal length. Stata has no
  equal-width command (`egen cut(), group()` is not equal-width).

- `cut_breaks()`: Cut at given cutpoints, like `egen cut(), at()`.

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

cut_breaks(x, breaks = NULL, labels = NULL, right = FALSE)
```

## Arguments

- x:

  A numeric vector. `xtile()` also accepts a logical vector, treated as
  0/1. SPSS user-missing codes and ranges are omitted. Convert
  `integer64` inputs and cutpoints explicitly to ordinary numeric values
  first.

- n:

  A positive integer. The number of intervals.

- labels:

  `NULL` (default) creates labels; `FALSE` returns integer codes. Supply
  a character vector for custom labels. For `xtile()`, grouped data
  masks default to integer codes, and `TRUE` explicitly requests labels.

- method:

  Quantile boundaries (`"quantile"`, the default), or balanced rank
  groups (`"rank"`, which has no Stata counterpart). Rank groups may
  split ties, breaking them by original position. They differ in size by
  at most one; earlier groups get extra rows.

- wt:

  Optional weights for `xtile()`, one per element of `x`, like Stata's
  `xtile ... [aweight = w]`. Cutpoints then follow Stata's weighted
  percentile rule; elements with a missing weight get a missing code.
  Not available with `method = "rank"`.

- breaks:

  Numeric cutpoints for `cut_breaks()`. The observed minimum and maximum
  are added when values lie beyond the breaks. `NULL` uses the observed
  median as an interior cutpoint. A single number supplies one interior
  cutpoint, rather than the number of intervals.

- right:

  If `FALSE` (default), intervals are closed on the left (`a <= x < b`),
  as in Stata's `egen cut()`; the last interval also includes its upper
  end. If `TRUE`, they are closed on the right (`a < x <= b`), as in
  [`base::cut()`](https://rdrr.io/r/base/cut.html).

## Value

An ordered factor, or integer interval codes when `labels = FALSE` or
when `xtile()` runs in a grouped data mask with default labels. The
result has the same length and order as `x`, with missing inputs
remaining missing. All-missing inputs are rejected. Empty inputs are
rejected by `xtile()` and `cut_length()`;
`cut_breaks(numeric(), breaks = 50)` returns an empty ordered factor
with range warnings.

## Details

For `xtile(method = "quantile")`, cutpoints are the percentiles at
`1/n, 2/n, ...`, using Stata's percentile rule (see
[`summ()`](https://socimh.github.io/tidystata/reference/summ.md)), and
each value joins the first group whose cutpoint is at least that value.
Equal values stay in the same group; different values may share a group.
Ties can leave groups empty; as in Stata, their codes are skipped (codes
1, 3 and 4, say) and a warning is given. Factor levels are the occupied
groups. Default labels describe the contiguous intervals covered by each
group, for example `"[0,0]"` and `"(0,1]"`. Custom labels must match the
effective number of groups. `xtile()` rejects empty and all-missing
vectors; it rejects constants in quantile mode but accepts them in rank
mode. `cut_length()` and `cut_breaks()` reject constants and all-missing
vectors.

`cut_breaks()` differs from `egen cut(), at()` at the ends: Stata leaves
values outside the breaks (and at the last break) missing, while
`cut_breaks()` extends the end intervals to the observed range.

With `xtile()`, `labels = NULL` (default) or `TRUE` creates labels.
Inside grouped
[`dplyr::mutate()`](https://dplyr.tidyverse.org/reference/mutate.html),
each group has its own cutpoints and interval labels, which cannot be
combined, so `xtile()` defaults to integer codes within each group (like
Stata's `xtile, by()`). Supply `labels = TRUE` to request labels there
anyway. `cut_length()` and `cut_breaks()` keep their factor output
inside grouped data masks; use a character vector for custom labels or
`FALSE` for integer codes.

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
#>  [1] [1,5.5]     [1,5.5]     [1,5.5]     [1,5.5]     [1,5.5]     (5.5,10.5] 
#>  [7] (5.5,10.5]  (5.5,10.5]  (5.5,10.5]  (5.5,10.5]  (10.5,15.5] (10.5,15.5]
#> [13] (10.5,15.5] (10.5,15.5] (10.5,15.5] (15.5,20]   (15.5,20]   (15.5,20]  
#> [19] (15.5,20]   (15.5,20]  
#> Levels: [1,5.5] < (5.5,10.5] < (10.5,15.5] < (15.5,20]

xtile(c(0, 0, 0, 1, 1), 2)
#> [1] [0,0] [0,0] [0,0] (0,1] (0,1]
#> Levels: [0,0] < (0,1]

cut_length(1:20)
#>  [1] [1,5.75)    [1,5.75)    [1,5.75)    [1,5.75)    [1,5.75)    [5.75,10.5)
#>  [7] [5.75,10.5) [5.75,10.5) [5.75,10.5) [5.75,10.5) [10.5,15.2) [10.5,15.2)
#> [13] [10.5,15.2) [10.5,15.2) [10.5,15.2) [15.2,20]   [15.2,20]   [15.2,20]  
#> [19] [15.2,20]   [15.2,20]  
#> Levels: [1,5.75) < [5.75,10.5) < [10.5,15.2) < [15.2,20]

cut_breaks(1:20, breaks = c(5, 15))
#>  [1] [1,5)   [1,5)   [1,5)   [1,5)   [5,15)  [5,15)  [5,15)  [5,15)  [5,15) 
#> [10] [5,15)  [5,15)  [5,15)  [5,15)  [5,15)  [15,20] [15,20] [15,20] [15,20]
#> [19] [15,20] [15,20]
#> Levels: [1,5) < [5,15) < [15,20]

cut_breaks(1:20, breaks = 10)
#>  [1] [1,10)  [1,10)  [1,10)  [1,10)  [1,10)  [1,10)  [1,10)  [1,10)  [1,10) 
#> [10] [10,20] [10,20] [10,20] [10,20] [10,20] [10,20] [10,20] [10,20] [10,20]
#> [19] [10,20] [10,20]
#> Levels: [1,10) < [10,20]
```
