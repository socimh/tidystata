# Assert that conditions hold

Verify that every row satisfies all specified conditions, like Stata's
`assert`. Stop with an error if any condition fails; otherwise, return
the original data invisibly.

## Usage

``` r
assert(.data, ..., .by = NULL)
```

## Arguments

- .data:

  A data frame, tibble, or data.table.

- ...:

  Logical conditions using columns of `.data`. Every condition must be
  `TRUE` for every row.

- .by:

  \<[`tidy-select`](https://dplyr.tidyverse.org/reference/dplyr_tidy_select.html)\>
  Optional grouping variables. Summaries such as `mean(x)` are evaluated
  within each group.

## Value

`.data`, unchanged and invisibly, if all conditions pass.

## Details

Both `FALSE` and `NA` count as failures. Errors report the number of
failing rows for each condition, including missing results, and the
first five failing row numbers. A failed group-level condition counts
every row in that group.

Unlike Stata, `x > 0` fails when `x` is missing. Use `is.na(x) | x > 0`
to allow missing values.

## See also

Other data checking functions:
[`is_first()`](https://socimh.github.io/tidystata/reference/is_first.md),
[`keys`](https://socimh.github.io/tidystata/reference/keys.md),
[`stata_merge()`](https://socimh.github.io/tidystata/reference/stata_merge.md)

## Examples

``` r
scores <- data.frame(
  class = c("A", "A", "B", "B"),
  score = c(80, 90, 55, NA_real_)
)

# Pass: every nonmissing score is at least 50
assert(scores, is.na(score) | score >= 50)

# Fail: row 3 is below 60, and row 4 is missing
try(assert(scores, score >= 60))
#> Error in assert(scores, score >= 60) : Assertion failed:
#> * `score >= 60`: 2 contradictions (1 missing) in 4 rows; rows 3, 4
```
