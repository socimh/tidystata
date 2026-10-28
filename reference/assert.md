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

  \<[`data-masking`](https://rlang.r-lib.org/reference/args_data_masking.html)\>
  One or more logical conditions using columns of `.data`. Each must
  return one value per row, or one value recycled across the current
  group. Every condition must be `TRUE` for every row.

- .by:

  \<[`tidy-select`](https://dplyr.tidyverse.org/reference/dplyr_tidy_select.html)\>
  Optional grouping variables. Summaries such as `mean(x)` are evaluated
  within each group. Existing groups are used when omitted. To supply
  `.by` for grouped data, first call
  [`dplyr::ungroup()`](https://dplyr.tidyverse.org/reference/group_by.html),
  as required by
  [`dplyr::mutate()`](https://dplyr.tidyverse.org/reference/mutate.html).

## Value

`.data`, unchanged and invisibly, including its classes, grouping, and
attributes, if all conditions pass. Failed conditions raise an error.

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
scores
#>   class score
#> 1     A    80
#> 2     A    90
#> 3     B    55
#> 4     B    NA

# Pass: every nonmissing score is at least 50
assert(scores, is.na(score) | score >= 50)

# Fail: row 3 is below 60, and row 4 is missing
try(assert(scores, score >= 60))
#> Error in assert(scores, score >= 60) : Assertion failed:
#> • `score >= 60`: 2 contradictions (1 missing) in 4 rows; rows 3, 4
```
