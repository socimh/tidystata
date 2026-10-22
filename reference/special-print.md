# Persistent previews of complete tables

`preview_table()` keeps the complete data and remembers how to print it.
The default shows the first five and last five rows. Interval previews
show evenly spaced rows. `unpreview_table()` removes the preference.

`print_headtail()` and `print_interval()` print once and invisibly
return the unchanged input. `print_all()` prints every row and every
column, like Stata's `list`, and also returns the input invisibly.
`s_print()` does all three through one `style` argument.
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

s_print(
  .data,
  style = c("headtail", "interval", "all"),
  n = 10,
  width = NULL,
  ...
)

print_all(.data, ...)

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

  Either `"headtail"` or `"interval"`. `s_print()` also accepts `"all"`,
  which prints every row and column like `print_all()`.

- n:

  Total number of rows to display or select: a positive whole number or
  `Inf` for all rows. An odd head/tail budget gives the head the extra
  row. With `n = 1`, both styles select the first row. Short tables
  never repeat rows.

- width:

  Console width, passed to tibble formatting. `NULL` uses the current
  console width; `Inf` shows all columns.

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
[`s_select()`](https://socimh.github.io/tidystata/reference/s_select.md),
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
print_headtail(mtcars, n = 6)
#> # Description: df [32 × 11]
#>      mpg   cyl  disp    hp  drat    wt  qsec    vs    am  gear  carb
#>    <dbl> <dbl> <dbl> <dbl> <dbl> <dbl> <dbl> <dbl> <dbl> <dbl> <dbl>
#>  1  21       6   160   110  3.9   2.62  16.5     0     1     4     4
#>  2  21       6   160   110  3.9   2.88  17.0     0     1     4     4
#>  3  22.8     4   108    93  3.85  2.32  18.6     1     1     4     1
#> 30  19.7     6   145   175  3.62  2.77  15.5     0     1     5     6
#> 31  15       8   301   335  3.54  3.57  14.6     0     1     5     8
#> 32  21.4     4   121   109  4.11  2.78  18.6     1     1     4     2
#> # ... 26 rows omitted in the middle; use print(x, n = Inf) to show all rows.
print_interval(mtcars, n = 6)
#> # Description: df [32 × 11]
#>      mpg   cyl  disp    hp  drat    wt  qsec    vs    am  gear  carb
#>    <dbl> <dbl> <dbl> <dbl> <dbl> <dbl> <dbl> <dbl> <dbl> <dbl> <dbl>
#>  1  21       6 160     110  3.9   2.62  16.5     0     1     4     4
#>  7  14.3     8 360     245  3.21  3.57  15.8     0     0     3     4
#> 13  17.3     8 276.    180  3.07  3.73  17.6     0     0     3     3
#> 20  33.9     4  71.1    65  4.22  1.84  19.9     1     1     4     1
#> 26  27.3     4  79      66  4.08  1.94  18.9     1     1     4     1
#> 32  21.4     4 121     109  4.11  2.78  18.6     1     1     4     2
#> # ... 26 rows omitted between displayed positions; use print(x, n = Inf) to
#> # show all rows.
print_all(head(mtcars, 12))
#> # Description: df [12 × 11]
#>      mpg   cyl  disp    hp  drat    wt  qsec    vs    am  gear  carb
#>    <dbl> <dbl> <dbl> <dbl> <dbl> <dbl> <dbl> <dbl> <dbl> <dbl> <dbl>
#>  1  21       6  160    110  3.9   2.62  16.5     0     1     4     4
#>  2  21       6  160    110  3.9   2.88  17.0     0     1     4     4
#>  3  22.8     4  108     93  3.85  2.32  18.6     1     1     4     1
#>  4  21.4     6  258    110  3.08  3.22  19.4     1     0     3     1
#>  5  18.7     8  360    175  3.15  3.44  17.0     0     0     3     2
#>  6  18.1     6  225    105  2.76  3.46  20.2     1     0     3     1
#>  7  14.3     8  360    245  3.21  3.57  15.8     0     0     3     4
#>  8  24.4     4  147.    62  3.69  3.19  20       1     0     4     2
#>  9  22.8     4  141.    95  3.92  3.15  22.9     1     0     4     2
#> 10  19.2     6  168.   123  3.92  3.44  18.3     1     0     4     4
#> 11  17.8     6  168.   123  3.92  3.44  18.9     1     0     4     4
#> 12  16.4     8  276.   180  3.07  4.07  17.4     0     0     3     3
s_print(mtcars, "interval", n = 6)
#> # Description: df [32 × 11]
#>      mpg   cyl  disp    hp  drat    wt  qsec    vs    am  gear  carb
#>    <dbl> <dbl> <dbl> <dbl> <dbl> <dbl> <dbl> <dbl> <dbl> <dbl> <dbl>
#>  1  21       6 160     110  3.9   2.62  16.5     0     1     4     4
#>  7  14.3     8 360     245  3.21  3.57  15.8     0     0     3     4
#> 13  17.3     8 276.    180  3.07  3.73  17.6     0     0     3     3
#> 20  33.9     4  71.1    65  4.22  1.84  19.9     1     1     4     1
#> 26  27.3     4  79      66  4.08  1.94  18.9     1     1     4     1
#> 32  21.4     4 121     109  4.11  2.78  18.6     1     1     4     2
#> # ... 26 rows omitted between displayed positions; use print(x, n = Inf) to
#> # show all rows.
slice_headtail(mtcars, n = 6)
#>                mpg cyl disp  hp drat    wt  qsec vs am gear carb
#> Mazda RX4     21.0   6  160 110 3.90 2.620 16.46  0  1    4    4
#> Mazda RX4 Wag 21.0   6  160 110 3.90 2.875 17.02  0  1    4    4
#> Datsun 710    22.8   4  108  93 3.85 2.320 18.61  1  1    4    1
#> Ferrari Dino  19.7   6  145 175 3.62 2.770 15.50  0  1    5    6
#> Maserati Bora 15.0   8  301 335 3.54 3.570 14.60  0  1    5    8
#> Volvo 142E    21.4   4  121 109 4.11 2.780 18.60  1  1    4    2
slice_interval(mtcars, n = 6)
#>                 mpg cyl  disp  hp drat    wt  qsec vs am gear carb
#> Mazda RX4      21.0   6 160.0 110 3.90 2.620 16.46  0  1    4    4
#> Duster 360     14.3   8 360.0 245 3.21 3.570 15.84  0  0    3    4
#> Merc 450SL     17.3   8 275.8 180 3.07 3.730 17.60  0  0    3    3
#> Toyota Corolla 33.9   4  71.1  65 4.22 1.835 19.90  1  1    4    1
#> Fiat X1-9      27.3   4  79.0  66 4.08 1.935 18.90  1  1    4    1
#> Volvo 142E     21.4   4 121.0 109 4.11 2.780 18.60  1  1    4    2
```
