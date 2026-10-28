# Print selected rows once

Display selected rows in the console without storing print preferences.

- `print_headtail()`: Print the first and last rows.

- `print_interval()`: Print evenly spaced rows.

## Usage

``` r
print_headtail(
  .data,
  n = 10,
  width = NULL,
  ...,
  max_extra_cols = NULL,
  max_footer_lines = NULL
)

print_interval(
  .data,
  n = 10,
  width = NULL,
  ...,
  max_extra_cols = NULL,
  max_footer_lines = NULL
)
```

## Arguments

- .data:

  An in-memory data frame, data.table, ordinary/grouped/rowwise tibble,
  or `sf` data frame. Collect lazy tables and convert other subclasses
  explicitly first. Apply previews separately to lists of tables.

- n:

  Total number of data rows to display, defaulting to 10. Supply a
  positive whole number or `Inf` for all rows; omission markers do not
  count.

- width:

  Console width passed to tibble formatting. `NULL` (default) uses the
  current console width; `Inf` shows every column.

- ...:

  Additional arguments passed to tibble formatting.

- max_extra_cols, max_footer_lines:

  Maximum number of additional columns to describe and footer lines to
  print, respectively. `NULL` uses tibble's defaults.

## Value

`.data`, unchanged and invisibly, including all rows, columns, classes,
grouping, and any existing preview preferences.

## Details

Each call prints a temporary preview and returns the complete original
table. Existing groups share one row budget; they are not printed
separately.

Row budgets and omission markers follow
[`preview()`](https://socimh.github.io/tidystata/reference/preview.md):
head/tail output marks an omitted middle with one row of dots; interval
output has no separator rows. Use `n = Inf` and `width = Inf` to print
every row and column.

## See also

[`preview()`](https://socimh.github.io/tidystata/reference/preview.md)
for persistent print preferences.

## Examples

``` r
print_headtail(lifeexp, n = 6)
#> # A tibble: 68 × 6
#>    region               country       popgrowth  lexp gnppc safewater
#>    <dbl+lbl>            <chr>             <dbl> <dbl> <dbl>     <dbl>
#>  1 1 [Europe & C. Asia] Albania            -0.6    74   870        49
#>  2 1 [Europe & C. Asia] Armenia            -1.2    70   570        83
#>  3 1 [Europe & C. Asia] Austria             0.1    78 27810        97
#>  ⋮ ⋮                          ⋮              ⋮      ⋮     ⋮         ⋮
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
```
