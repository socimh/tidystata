# Check keys and duplicate rows

Stata-style checks of identifying variables and duplicated rows.

- `isid()` checks that the selected columns uniquely identify the rows,
  like Stata's `isid`. It returns the data invisibly when they do and
  errors otherwise, so it can sit inside a pipeline. Wrap it in
  [`capture()`](https://socimh.github.io/tidystata/reference/capture.md)
  for a `TRUE`/`FALSE` answer.

- `duplicates_report()` counts how many rows share the same values, like
  `duplicates report`.

- `duplicates_tag()` adds the number of other rows with the same values,
  like `duplicates tag, generate()`.

- `duplicates_list()` returns the duplicated rows, like
  `duplicates list`.

- `duplicates_drop()` keeps the first row of each duplicated set, like
  `duplicates drop`.

## Usage

``` r
isid(.data, ..., .missok = FALSE)

duplicates_report(.data, ...)

duplicates_tag(.data, ..., .name = "dup")

duplicates_list(.data, ...)

duplicates_drop(.data, ..., .force = FALSE)
```

## Arguments

- .data:

  A data frame, tibble, or data.table.

- ...:

  \<[`tidy-select`](https://dplyr.tidyverse.org/reference/dplyr_tidy_select.html)\>
  The identifying columns. Omit to use all columns, as Stata does.

- .missok:

  If `FALSE` (default), `isid()` errors when an identifying column
  contains missing values, as Stata's `isid` does without the `missok`
  option.

- .name:

  Name of the new column created by `duplicates_tag()`.

- .force:

  If `TRUE`, allow `duplicates_drop()` to remove rows that match on the
  selected columns but differ elsewhere, like Stata's
  `duplicates drop varlist, force`. Defaults to `FALSE`; exact duplicate
  rows can be dropped without this option.

## Value

- `isid()`: `.data`, invisibly.

- `duplicates_report()`: a tibble with one row per number of copies:
  `copies`, `observations` (rows with that many copies) and `surplus`
  (rows beyond the first of each set).

- `duplicates_tag()`: `.data` with an integer column of the number of
  other rows sharing the same values (0 for unique rows).

- `duplicates_list()`: the duplicated rows, ordered by their identifying
  values, with `.dup_group` (set number) and `.row` (original position).

- `duplicates_drop()`: `.data` without surplus rows, keeping the first
  row of each set in input order.

The input's data.frame, tibble, data.table or grouped container is kept
where rows or columns of `.data` are returned.

## Details

Missing values count as equal to each other, as in Stata, so two rows
that are both missing on every selected column are duplicates. Checks
and duplicate counts use the whole input, regardless of grouping.
`duplicates_list()` rejects existing `.dup_group` or `.row` columns;
rename them first. `duplicates_drop()` reports the number of rows
removed as a message. The input data are not modified.

## See also

Other data checking functions:
[`assert()`](https://socimh.github.io/tidystata/reference/assert.md),
[`is_first()`](https://socimh.github.io/tidystata/reference/is_first.md),
[`stata_merge()`](https://socimh.github.io/tidystata/reference/stata_merge.md)

## Examples

``` r
panel <- tibble::tibble(
  id = c(1, 1, 2, 2, 3),
  wave = c(1, 2, 1, 1, 1),
  score = c(5, 6, 7, 7, 8)
)
# id repeats, so this errors; capture() turns it into TRUE/FALSE
try(isid(panel, id))
#> Error in isid(panel, id) : 
#>   Variable `id` does not uniquely identify the rows: 2 values appear more
#> than once (4 rows).
#> ℹ See them with `duplicates_list()`.

capture(isid(panel, id))
#> [1] FALSE

isid(panel[-4, ], id, wave)

duplicates_report(panel, id, wave)
#> # A tibble: 2 × 3
#>   copies observations surplus
#>    <int>        <int>   <int>
#> 1      1            3       0
#> 2      2            2       1

duplicates_tag(panel, id, wave)
#> # A tibble: 5 × 4
#>      id  wave score   dup
#>   <dbl> <dbl> <dbl> <int>
#> 1     1     1     5     0
#> 2     1     2     6     0
#> 3     2     1     7     1
#> 4     2     1     7     1
#> 5     3     1     8     0

duplicates_list(panel, id, wave)
#> # A tibble: 2 × 5
#>      id  wave score .dup_group  .row
#>   <dbl> <dbl> <dbl>      <int> <int>
#> 1     2     1     7          1     3
#> 2     2     1     7          1     4

duplicates_drop(panel)
#> (1 row removed)
#> # A tibble: 4 × 3
#>      id  wave score
#>   <dbl> <dbl> <dbl>
#> 1     1     1     5
#> 2     1     2     6
#> 3     2     1     7
#> 4     3     1     8
```
