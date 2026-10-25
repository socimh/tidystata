# Persistent previews of complete tables

`preview_table()` keeps the complete data and remembers how to print it.
The default shows the first five and last five rows. Interval previews
show evenly spaced rows. `unpreview_table()` removes the preference.

`print_headtail()` and `print_interval()` print once and invisibly
return the unchanged input. `print_all()` prints every row and every
column, like Stata's `list`, and also returns the input invisibly.
`slice_headtail()` and `slice_interval()` actually select rows, so use
them only when a smaller data set is wanted.

## Usage

``` r
preview_table(.data, style = c("headtail", "interval"), n = 10)

unpreview_table(.data)

print_headtail(
  .data,
  n = 10,
  width = NULL,
  ...,
  max_extra_cols = NULL,
  max_footer_lines = NULL
)

print_all(.data, ..., width = Inf)

print_interval(
  .data,
  n = 10,
  width = NULL,
  ...,
  max_extra_cols = NULL,
  max_footer_lines = NULL
)

slice_headtail(.data, n = 10)

slice_interval(.data, n = 10)
```

## Arguments

- .data:

  An in-memory data frame, data.table, ordinary tibble, grouped tibble,
  rowwise tibble, or `sf` data frame (geometry is kept when slicing and
  printed as a column). Convert other subclasses explicitly before
  wrapping; collect lazy tables first. Apply the wrapper separately to
  lists of tables.

- style:

  Either `"headtail"` or `"interval"`.

- n:

  Total number of rows to display or select: a positive whole number or
  `Inf` for all rows. An odd head/tail budget gives the head the extra
  row. With `n = 1`, both styles select the first row. Short tables
  never repeat rows.

- width:

  Console width, passed to tibble formatting. `NULL` uses the current
  console width; `Inf` (the default for `print_all()`) shows all
  columns.

- ...:

  Additional arguments passed to tibble formatting.

- max_extra_cols, max_footer_lines:

  Tibble formatting controls.

## Value

`preview_table()` returns the complete input container with an
additional `tidystata_preview` class. `unpreview_table()` returns the
table without that class or its settings, preserving grouping. The print
helpers invisibly return their original input. The slice helpers return
the selected rows in the input container, retaining valid grouping and
existing preview settings. Explicit base data.frame row names are
preserved. Slice helpers regenerate automatic row names following
dplyr's row-slicing behavior. Other subclasses are unsupported.

## Details

Preview settings survive table subsetting/replacement, dplyr mutation,
filtering, sorting, column selection, renaming, relocation, distinct
rows, slicing, grouping, rowwise operations, summaries and reframing, as
well as tidyr's `pivot_longer()` and `pivot_wider()`. Grouping follows
the underlying operation. Joins inherit the left input's settings;
[`bind_rows()`](https://dplyr.tidyverse.org/reference/bind_rows.html)
inherits the first input's settings. Arbitrary third-party
transformations and direct
[`vctrs::vec_rbind()`](https://vctrs.r-lib.org/reference/vec_bind.html)
are not covered by this guarantee.

Positions shown in the margin refer to the current table, not the
original data before filtering or sorting. Previewing does not change
column values, classes, labels, or the data used in subsequent
calculations. Grouped tables use a global row budget, not a separate
budget per group.

`print(x, n = Inf)` displays the entire table. Per-call formatting
overrides do not change stored settings. Explicit
[`tibble::as_tibble()`](https://tibble.tidyverse.org/reference/as_tibble.html)
or [`as.data.frame()`](https://rdrr.io/r/base/as.data.frame.html)
conversions remove the preview, as does extracting a column. This
feature controls console printing, not HTML widgets or GUI viewers. Only
the temporary display is converted to a tibble. Wrapping and unwrapping
a data.table creates an independent copy; native operations such as `:=`
on a wrapped data.table retain ordinary reference semantics. External
dplyr/tidyr verbs determine their own result container and grouping,
while preview settings follow the result.

## See also

Other selection and preview functions:
[`select_or_transmute()`](https://socimh.github.io/tidystata/reference/select_or_transmute.md),
[`varlist()`](https://socimh.github.io/tidystata/reference/varlist.md)

## Examples

``` r
x <- preview_table(tibble::tibble(id = 1:30, value = (1:30)^2))
x
#> # A tibble: 30 × 2
#>       id value
#>    <int> <dbl>
#>  1     1     1
#>  2     2     4
#>  3     3     9
#>  4     4    16
#>  5     5    25
#> 26    26   676
#> 27    27   729
#> 28    28   784
#> 29    29   841
#> 30    30   900
#> # ... 20 rows omitted in the middle; use print(x, n = Inf) to show all rows.
dplyr::filter(x, id > 10)
#> # A tibble: 20 × 2
#>       id value
#>    <int> <dbl>
#>  1    11   121
#>  2    12   144
#>  3    13   169
#>  4    14   196
#>  5    15   225
#> 16    26   676
#> 17    27   729
#> 18    28   784
#> 19    29   841
#> 20    30   900
#> # ... 10 rows omitted in the middle; use print(x, n = Inf) to show all rows.
preview_table(x, style = "interval", n = 5)
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
print(x, n = Inf)
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
#> 11    11   121
#> 12    12   144
#> 13    13   169
#> 14    14   196
#> 15    15   225
#> 16    16   256
#> 17    17   289
#> 18    18   324
#> 19    19   361
#> 20    20   400
#> 21    21   441
#> 22    22   484
#> 23    23   529
#> 24    24   576
#> 25    25   625
#> 26    26   676
#> 27    27   729
#> 28    28   784
#> 29    29   841
#> 30    30   900
unpreview_table(x)
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
print_headtail(lifeexp, n = 6)
#> # A tibble: 68 × 6
#>    region               country       popgrowth  lexp gnppc safewater
#>    <dbl+lbl>            <chr>             <dbl> <dbl> <dbl>     <dbl>
#>  1 1 [Europe & C. Asia] Albania            -0.6    74   870        49
#>  2 1 [Europe & C. Asia] Armenia            -1.2    70   570        83
#>  3 1 [Europe & C. Asia] Austria             0.1    78 27810        97
#> 66 3 [South America]    Peru                1.8    69  2150        45
#> 67 3 [South America]    Uruguay             0.5    74  7360        NA
#> 68 3 [South America]    Venezuela, RB       2      72  3380        NA
#> # ... 62 rows omitted in the middle; use print(x, n = Inf) to show all rows.
print_interval(lifeexp, n = 6)
#> # A tibble: 68 × 6
#>    region               country       popgrowth  lexp gnppc safewater
#>    <dbl+lbl>            <chr>             <dbl> <dbl> <dbl>     <dbl>
#>  1 1 [Europe & C. Asia] Albania            -0.6    74   870        49
#> 14 1 [Europe & C. Asia] France              0.4    79 25740        97
#> 28 1 [Europe & C. Asia] Norway              0.6    78 36120       100
#> 41 1 [Europe & C. Asia] Ukraine            -0.8    68   840        66
#> 55 2 [North America]    Panama              2      73  3510        NA
#> 68 3 [South America]    Venezuela, RB       2      72  3380        NA
#> # ... 62 rows omitted between displayed positions; use print(x, n = Inf) to
#> # show all rows.
print_all(head(lifeexp, 12))
#> # A tibble: 12 × 6
#>    region               country                popgrowth  lexp gnppc safewater
#>    <dbl+lbl>            <chr>                      <dbl> <dbl> <dbl>     <dbl>
#>  1 1 [Europe & C. Asia] Albania                     -0.6    74   870        49
#>  2 1 [Europe & C. Asia] Armenia                     -1.2    70   570        83
#>  3 1 [Europe & C. Asia] Austria                      0.1    78 27810        97
#>  4 1 [Europe & C. Asia] Azerbaijan                   0.9    64   510        49
#>  5 1 [Europe & C. Asia] Belarus                     -0.5    68  1540        82
#>  6 1 [Europe & C. Asia] Belgium                      0.2    77 26530       100
#>  7 1 [Europe & C. Asia] Bosnia and Herzegovina       1.8    74  1230        87
#>  8 1 [Europe & C. Asia] Bulgaria                    -0.7    71  1440        90
#>  9 1 [Europe & C. Asia] Croatia                     -0.1    72    NA        85
#> 10 1 [Europe & C. Asia] Czechia                     -0.1    75  6140        95
#> 11 1 [Europe & C. Asia] Denmark                      0.4    76 33440        95
#> 12 1 [Europe & C. Asia] Estonia                     -1      69  3820        92
slice_headtail(lifeexp, n = 6)
#> # A tibble: 6 × 6
#>   region               country       popgrowth  lexp gnppc safewater
#>   <dbl+lbl>            <chr>             <dbl> <dbl> <dbl>     <dbl>
#> 1 1 [Europe & C. Asia] Albania            -0.6    74   870        49
#> 2 1 [Europe & C. Asia] Armenia            -1.2    70   570        83
#> 3 1 [Europe & C. Asia] Austria             0.1    78 27810        97
#> 4 3 [South America]    Peru                1.8    69  2150        45
#> 5 3 [South America]    Uruguay             0.5    74  7360        NA
#> 6 3 [South America]    Venezuela, RB       2      72  3380        NA
slice_interval(lifeexp, n = 6)
#> # A tibble: 6 × 6
#>   region               country       popgrowth  lexp gnppc safewater
#>   <dbl+lbl>            <chr>             <dbl> <dbl> <dbl>     <dbl>
#> 1 1 [Europe & C. Asia] Albania            -0.6    74   870        49
#> 2 1 [Europe & C. Asia] France              0.4    79 25740        97
#> 3 1 [Europe & C. Asia] Norway              0.6    78 36120       100
#> 4 1 [Europe & C. Asia] Ukraine            -0.8    68   840        66
#> 5 2 [North America]    Panama              2      73  3510        NA
#> 6 3 [South America]    Venezuela, RB       2      72  3380        NA
```
