# Set persistent table previews

Keep a compact console display while retaining every row and column.

- `preview()`: Store a head/tail or interval display preference.

- `preview_headtail()`: Store a preference for the first and last rows.

- `preview_interval()`: Store a preference for evenly spaced rows.

- `unpreview()`: Remove preview preferences and restore ordinary
  printing.

## Usage

``` r
preview(.data, style = c("headtail", "interval"), n = 10)

preview_headtail(.data, n = 10)

preview_interval(.data, n = 10)

unpreview(.data)
```

## Arguments

- .data:

  An in-memory data frame, data.table, ordinary/grouped/rowwise tibble,
  or `sf` data frame. Collect lazy tables and convert other subclasses
  explicitly first. Apply previews separately to lists of tables.

- style:

  For `preview()`, either `"headtail"` (default) or `"interval"`.

- n:

  Total number of data rows to display, defaulting to 10. Supply a
  positive whole number or `Inf` for all rows; omission markers do not
  count.

## Value

A data frame, tibble, data.table, or `sf` data frame with the same rows,
columns, values, row names, and grouping as `.data`. The preview
functions add a `tidystata_preview` class and print preferences;
`unpreview()` removes them.

## Details

**Display**

Head/tail previews split `n` between the beginning and end, giving an
odd row to the beginning. One row of vertical dots marks an omitted
middle, using periods without Unicode output. Numeric markers align with
printed decimal points, or the last significand digit when no decimal is
shown. Row-number markers align with the last digit. Other columns,
including dates, times, factors, logicals and lists, use centered
markers. Numeric columns without displayed numbers also use centered
markers. Interval previews show approximately evenly spaced positions
without separator rows. An omission footer counts undisplayed rows. With
`n = 1`, both styles show the first row; short tables do not repeat
rows.

Row numbers refer to the current table after filtering or sorting.
Grouped tables use one display budget across all groups.
`print(x, n = Inf, width = Inf)` shows every row and column without
changing stored preferences. Previews control console printing, not HTML
widgets or GUI viewers.

**Working with previews**

Settings follow supported base subsetting/replacement, dplyr row and
column operations, grouping (including rowwise operations), summaries
and reframing, and tidyr pivots. These operations determine the result's
container and grouping. Joins inherit the left input's settings;
[`bind_rows()`](https://dplyr.tidyverse.org/reference/bind_rows.html)
inherits the first input's settings. Arbitrary third-party
transformations and direct
[`vctrs::vec_rbind()`](https://vctrs.r-lib.org/reference/vec_bind.html)
are not covered by this guarantee.

Converting with
[`tibble::as_tibble()`](https://tibble.tidyverse.org/reference/as_tibble.html)
or [`as.data.frame()`](https://rdrr.io/r/base/as.data.frame.html), or
extracting a column, removes the preview. Wrapping and unwrapping a
data.table makes an independent copy; subsequent native operations such
as `:=` retain ordinary reference semantics. Column classes and labels
are preserved.

## See also

[`print_headtail()`](https://socimh.github.io/tidystata/reference/special-print.md)
for one-time printing.

## Examples

``` r
tb <- tibble::tibble(id = 1:30, value = (1:30)^2)
tb
#> # A tibble: 30 × 2
#>       id value
#>    <int> <dbl>
#>  1     1     1
#>  2     2     4
#>  3     3     9
#>  4     4    16
#>  5     5    25
#>  6     6    36
#>  7     7    49
#>  8     8    64
#>  9     9    81
#> 10    10   100
#> # ℹ 20 more rows

ht <- preview_headtail(tb)
ht
#> # A tibble: 30 × 2
#>       id value
#>    <int> <dbl>
#>  1     1     1
#>  2     2     4
#>  3     3     9
#>  4     4    16
#>  5     5    25
#>  ⋮     ⋮     ⋮
#> 26    26   676
#> 27    27   729
#> 28    28   784
#> 29    29   841
#> 30    30   900
#> # ... 20 rows omitted in the middle; use print(x, n = Inf) to show all rows.

dplyr::filter(ht, id > 10)
#> # A tibble: 20 × 2
#>       id value
#>    <int> <dbl>
#>  1    11   121
#>  2    12   144
#>  3    13   169
#>  4    14   196
#>  5    15   225
#>  ⋮     ⋮     ⋮
#> 16    26   676
#> 17    27   729
#> 18    28   784
#> 19    29   841
#> 20    30   900
#> # ... 10 rows omitted in the middle; use print(x, n = Inf) to show all rows.

preview_interval(ht, n = 5)
#> # A tibble: 30 × 2
#>       id value
#>    <int> <dbl>
#>  1     1     1
#>  8     8    64
#> 16    16   256
#> 23    23   529
#> 30    30   900
#> # ... 25 rows omitted between displayed positions; use print(x, n = Inf) to
#> # show all rows.

unpreview(ht)
#> # A tibble: 30 × 2
#>       id value
#>    <int> <dbl>
#>  1     1     1
#>  2     2     4
#>  3     3     9
#>  4     4    16
#>  5     5    25
#>  6     6    36
#>  7     7    49
#>  8     8    64
#>  9     9    81
#> 10    10   100
#> # ℹ 20 more rows
```
