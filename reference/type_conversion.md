# Convert vectors for data preparation

Vector helpers named after Stata's conversion commands:

## Usage

``` r
destring(x, ignore = NULL)

decode(x)

tostring(x)

as_character(x)

as_numeric(x, ignore = NULL)
```

## Arguments

- x:

  A vector or matrix; a vector for `tostring()`.

- ignore:

  `NULL` (default) or a single string of characters to remove from text
  before reading numbers, like Stata's `ignore()`. Each character is
  removed wherever it appears: `ignore = "kg "` removes `k`, `g` and
  spaces.

## Value

`as_character()` and `tostring()` return a character vector.
`as_numeric()` returns a double vector; unsupported types such as lists,
raw vectors, and complex vectors return missing values of the same
length. Empty inputs return typed empty vectors. Names, dimensions,
labels, and units are dropped. Text that is not a number gives a warning
and keeps its row and value in
[`readr::problems()`](https://readr.tidyverse.org/reference/problems.html)
on the result. Conversion of large `integer64` values to double may lose
precision and emits the underlying conversion warning.

## Details

- `destring()` (alias `as_numeric()`) converts text to numbers, like
  Stata's `destring`. Use `mutate(x = destring(x))`.

- `decode()` (alias `as_character()`) converts a labelled vector to its
  value labels, like Stata's `decode`.

- `tostring()` converts values to text and ignores value labels, like
  Stata's `tostring`: a labelled vector or factor gives its codes, and
  character input is returned unchanged. Missing values stay `NA`. Dates
  use [`as.character()`](https://rdrr.io/r/base/character.html), so they
  become `"2024-01-31"` rather than day numbers.

`destring()` reads text the way Stata's `destring` does. A value must be
a number, optionally with a sign, a currency symbol (dollar, euro,
pound, yen), thousands separators (`1,234`), a trailing percent sign
(`50%` gives 50) and surrounding spaces. Anything else, such as
`"12abc"`, `"10 kg"` or a date, becomes `NA` with a warning, like
Stata's `force` option; the positions are kept in
[`readr::problems()`](https://readr.tidyverse.org/reference/problems.html).
Use `ignore` to remove other characters first, like Stata's `ignore()`:
`destring(x, ignore = "kg")` reads `"10 kg"` as 10. Empty strings,
`"NA"` and Stata's `"."` are missing without a warning. Dates stay `NA`;
convert them with [`as.Date()`](https://rdrr.io/r/base/as.Date.html) or
`lubridate::ymd()` instead.

A factor whose levels are all numbers, such as
`factor(c("1990", "2000"))`, gives those numbers (1990, 2000). Other
factors give their level codes. Labelled numeric variables return their
values. `as_character()` uses value labels when a labelled vector has a
nonempty `labels` attribute. Without value labels, it uses ordinary
character conversion, including for tagged missing values.

SPSS user-missing codes remain values in both conversions. Numeric
conversion preserves tagged missing values. Dates become days since
1970-01-01; date-times become seconds since the Unix epoch. Durations
and measured vectors retain their numeric values in their existing
units.

The sjlabelled package also exports `as_numeric()` and `as_character()`.
They differ: sjlabelled's `as_numeric()` turns non-numeric text into
factor codes, and its `as_character()` gives `NA` for unlabelled values.
Whichever package is attached last masks the other; write
`tidystata::as_numeric()` to be explicit, or use `destring()` and
`decode()`, which do not clash.

## See also

Other conversion functions:
[`na_conversion`](https://socimh.github.io/tidystata/reference/na_conversion.md)

## Examples

``` r
lifeexp |>
  dplyr::mutate(
    region_chr = decode(region),
    region_code = tostring(region),
    region_num = destring(region),
    region_fct = haven::as_factor(region),
    .keep = "used"
  )
#> # A tibble: 68 × 5
#>    region               region_chr       region_code region_num region_fct      
#>    <dbl+lbl>            <chr>            <chr>            <dbl> <fct>           
#>  1 1 [Europe & C. Asia] Europe & C. Asia 1                    1 Europe & C. Asia
#>  2 1 [Europe & C. Asia] Europe & C. Asia 1                    1 Europe & C. Asia
#>  3 1 [Europe & C. Asia] Europe & C. Asia 1                    1 Europe & C. Asia
#>  4 1 [Europe & C. Asia] Europe & C. Asia 1                    1 Europe & C. Asia
#>  5 1 [Europe & C. Asia] Europe & C. Asia 1                    1 Europe & C. Asia
#>  6 1 [Europe & C. Asia] Europe & C. Asia 1                    1 Europe & C. Asia
#>  7 1 [Europe & C. Asia] Europe & C. Asia 1                    1 Europe & C. Asia
#>  8 1 [Europe & C. Asia] Europe & C. Asia 1                    1 Europe & C. Asia
#>  9 1 [Europe & C. Asia] Europe & C. Asia 1                    1 Europe & C. Asia
#> 10 1 [Europe & C. Asia] Europe & C. Asia 1                    1 Europe & C. Asia
#> # ℹ 58 more rows
```
