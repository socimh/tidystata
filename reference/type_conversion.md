# Convert vectors for data preparation

Vector helpers named after Stata's conversion commands:

## Usage

``` r
destring(x, .x = lifecycle::deprecated())

decode(x, .x = lifecycle::deprecated())

tostring(x)

as_character(x, .x = lifecycle::deprecated())

as_numeric(x, .x = lifecycle::deprecated())
```

## Arguments

- x:

  A vector or matrix; a vector for `tostring()`.

- .x:

  **\[deprecated\]** Use `x` instead.

## Value

`as_character()` and `tostring()` return a character vector.
`as_numeric()` returns a double vector; unsupported types such as lists,
raw vectors, and complex vectors return missing values of the same
length. Empty inputs return typed empty vectors. Names, dimensions,
labels, and units are dropped. Parsing failures retain
[`readr::problems()`](https://readr.tidyverse.org/reference/problems.html)
diagnostics on the result. Conversion of large `integer64` values to
double may lose precision and emits the underlying conversion warning.

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

Character input to `as_numeric()` is parsed with
[`readr::parse_number()`](https://readr.tidyverse.org/reference/parse_number.html),
preserving its length. Invalid numbers generate parsing warnings.
Factors return their level codes; labelled numeric variables return
their values. `as_character()` uses value labels when a labelled vector
has a nonempty `labels` attribute. Without value labels, it uses
ordinary character conversion, including for tagged missing values.

SPSS user-missing codes remain values in both conversions. Numeric
conversion preserves tagged missing values. Dates become days since
1970-01-01; date-times become seconds since the Unix epoch. Durations
and measured vectors retain their numeric values in their existing
units.

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
