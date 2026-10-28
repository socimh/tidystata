# Check keys and duplicate rows

Stata-style checks of identifying variables and duplicated rows.

- `isid()`: Check that the selected columns uniquely identify the rows,
  like Stata's `isid`. It confirms a valid key with a message and
  returns the data invisibly, so it can sit inside a pipeline. Invalid
  keys raise an error.

- `duplicates_report()`: Count how many rows share the same values, like
  `duplicates report`.

- `duplicates_tag()`: Add the number of other rows with the same values,
  like `duplicates tag, generate()`.

- `duplicates_list()`: Return the duplicated rows, like
  `duplicates list`.

- `duplicates_drop()`: Keep the first row of each duplicated set, like
  `duplicates drop`.

## Usage

``` r
isid(.data, ..., .missing = FALSE)

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
  The identifying columns. Omit to use all columns. Stata's `isid`
  requires an explicit variable list.

- .missing:

  If `FALSE` (default), `isid()` errors when an identifying column
  contains missing values or empty strings, as Stata's `isid` does
  without `missok`. If `TRUE`, permit these values but still require
  unique key combinations. Rows are not dropped.

- .name:

  Name of the new column created by `duplicates_tag()`.

- .force:

  If `TRUE`, allow `duplicates_drop()` to remove rows that match on the
  selected columns but differ elsewhere, like Stata's
  `duplicates drop varlist, force`. Defaults to `FALSE`; exact duplicate
  rows can be dropped without this option.

## Value

- `isid()`: `.data`, unchanged and invisibly, after a confirmation
  message.

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

Unlike Stata's silent success, `isid()` names the columns that form a
valid key. This confirms uniqueness without storing an ID declaration or
adding metadata. Use
[`suppressMessages()`](https://rdrr.io/r/base/message.html) for silent
execution. An empty input reports that there are no rows to check.
Checks preserve row order. Instead of Stata's `sort` and `using`
options, use
[`dplyr::arrange()`](https://dplyr.tidyverse.org/reference/arrange.html)
to sort or
[`haven::read_dta()`](https://haven.tidyverse.org/reference/read_dta.html)
to read a file first. Factor values equal to `""` are empty strings;
whitespace is not trimmed.

Duplicate identity follows stored values: ordinary and tagged `NA`
values count as equal, `NaN` is a separate value, and distinct stored
SPSS user-missing codes remain distinct. This differs from `isid()`'s
default validation, which rejects all of these missing values;
`.missing = TRUE` permits them while still checking uniqueness by
stored-value identity. Checks and duplicate counts use the whole input,
regardless of grouping. `duplicates_list()` rejects existing
`.dup_group` or `.row` columns; rename them first. `duplicates_drop()`
reports the number of rows removed as a message. The input data are not
modified.

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
# id repeats, so this check fails and shows the error
try(isid(panel, id))
#> Error in isid(panel, id) : 
#>   Variable `id` does not uniquely identify the rows: 2 values appear more
#> than once (4 rows).
#> ℹ See them with `duplicates_list()`.

# Remove the duplicate row so id + wave uniquely identify observations
unique_panel <- dplyr::distinct(panel)
# Confirms that id + wave form a key; returns unique_panel invisibly
isid(unique_panel, id, wave)
#> Variables `id`, `wave` together uniquely identify the rows.

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
