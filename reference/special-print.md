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
#>  ⋮           ⋮                ⋮              ⋮      ⋮   ⋮           ⋮
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

print_headtail(lifeexp, n = Inf, width = Inf)
#> # A tibble: 68 × 6
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
#> 13 1 [Europe & C. Asia] Finland                      0.3    77 25810        94
#> 14 1 [Europe & C. Asia] France                       0.4    79 25740        97
#> 15 1 [Europe & C. Asia] Georgia                     -2.5    70   870        59
#> 16 1 [Europe & C. Asia] Germany                      0      77 28070       100
#> 17 1 [Europe & C. Asia] Greece                       0.6    78 13540        99
#> 18 1 [Europe & C. Asia] Hungary                     -0.2    71  4420        83
#> 19 1 [Europe & C. Asia] Ireland                      1      76 21430        75
#> 20 1 [Europe & C. Asia] Italy                        0      79 22270        95
#> 21 1 [Europe & C. Asia] Kazakhstan                  -2.5    63  1340        63
#> 22 1 [Europe & C. Asia] Kyrgyz Republic              1.5    67   360        46
#> 23 1 [Europe & C. Asia] Latvia                      -0.9    69  2790        93
#> 24 1 [Europe & C. Asia] Lithuania                   -0.7    71  2870        70
#> 25 1 [Europe & C. Asia] North Macedonia              0.5    72  2010        80
#> 26 1 [Europe & C. Asia] Moldova                      0      67   580        40
#> 27 1 [Europe & C. Asia] Netherlands                  0.6    78 27840       100
#> 28 1 [Europe & C. Asia] Norway                       0.6    78 36120       100
#> 29 1 [Europe & C. Asia] Poland                       0      73  4390        NA
#> 30 1 [Europe & C. Asia] Portugal                     0.5    76 12190        94
#> 31 1 [Europe & C. Asia] Romania                     -0.2    70  1580        82
#> 32 1 [Europe & C. Asia] Russian Federation          -0.2    67  2130        75
#> 33 1 [Europe & C. Asia] Slovak Republic              0.1    73  4230        92
#> 34 1 [Europe & C. Asia] Slovenia                    -0.2    75 10970        92
#> 35 1 [Europe & C. Asia] Spain                        0.4    79 15410        99
#> 36 1 [Europe & C. Asia] Sweden                       0.1    79 31100        99
#> 37 1 [Europe & C. Asia] Switzerland                  0.3    79 46650        97
#> 38 1 [Europe & C. Asia] Tajikistan                   0.6    62   170        36
#> 39 1 [Europe & C. Asia] Turkiye                      1.4    71  4150        NA
#> 40 1 [Europe & C. Asia] Turkmenistan                 1.7    64   560        69
#> 41 1 [Europe & C. Asia] Ukraine                     -0.8    68   840        66
#> 42 1 [Europe & C. Asia] United Kingdom               0.3    77 27040       100
#> 43 1 [Europe & C. Asia] Uzbekistan                   1.6    65   610        54
#> 44 1 [Europe & C. Asia] Serbia                      -0.4    72  3250        74
#> 45 2 [North America]    Canada                       0.8    79 20900        99
#> 46 2 [North America]    Cuba                         0.3    75  2240        NA
#> 47 2 [North America]    Dominican Republic           1.7    70  2420        42
#> 48 2 [North America]    El Salvador                  0.6    67  1730        NA
#> 49 2 [North America]    Guatemala                    2.6    66  1600        50
#> 50 2 [North America]    Haiti                        1.9    57   410        NA
#> 51 2 [North America]    Honduras                     2.6    62   960        42
#> 52 2 [North America]    Jamaica                      0.9    71  2940        NA
#> 53 2 [North America]    Mexico                       1.6    72  5340        40
#> 54 2 [North America]    Nicaragua                    1.5    64   890        NA
#> 55 2 [North America]    Panama                       2      73  3510        NA
#> 56 2 [North America]    Puerto Rico (US)             0.6    75  8690        75
#> 57 2 [North America]    Trinidad and Tobago          0.3    68  4450        NA
#> 58 2 [North America]    United States                1.2    77 32040        NA
#> 59 3 [South America]    Argentina                    1.2    73  7960        NA
#> 60 3 [South America]    Bolivia                      1.8    61   960        NA
#> 61 3 [South America]    Brazil                       1.5    69  4980        76
#> 62 3 [South America]    Chile                        1.3    76  5470        91
#> 63 3 [South America]    Colombia                     1.8    71  2600        68
#> 64 3 [South America]    Ecuador                      1.8    72  2150        62
#> 65 3 [South America]    Paraguay                     2.2    70  1800        50
#> 66 3 [South America]    Peru                         1.8    69  2150        45
#> 67 3 [South America]    Uruguay                      0.5    74  7360        NA
#> 68 3 [South America]    Venezuela, RB                2      72  3380        NA
```
