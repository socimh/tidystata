# Convert vectors for data preparation

Convert text to numbers with `destring()`, labelled values to labels
with `decode()`, or values to text with `tostring()`, following Stata's
conversion commands. `as_numeric()` and `as_character()` are aliases of
`destring()` and `decode()`.

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

`destring()` and `as_numeric()` return a double vector; `decode()`,
`as_character()`, and `tostring()` return a character vector. Results
have the same length as `x`; matrices are flattened in column order.
Unsupported numeric-conversion inputs, such as lists, raw vectors, and
complex vectors, return missing values of the same length. Empty inputs
return typed empty vectors. Names, dimensions, labels, and units are
dropped, except that `tostring()` returns character input unchanged,
including its attributes. Invalid numeric text adds a `problems`
attribute readable with
[`readr::problems()`](https://readr.tidyverse.org/reference/problems.html).

## Details

**Reading numbers**

`destring()` reads text the way Stata's `destring` does. A value must be
a number, optionally with a sign, exponent, currency symbol (dollar,
euro, pound, yen), thousands separators (`1,234`), a trailing percent
sign (`50%` gives 50) and surrounding spaces. Anything else, such as
`"12abc"`, `"10 kg"` or a date, becomes `NA` with a warning, like
Stata's `force` option; the positions and original values are kept in
[`readr::problems()`](https://readr.tidyverse.org/reference/problems.html).
Use `ignore` to remove other characters first, like Stata's `ignore()`:
`destring(x, ignore = "kg")` reads `"10 kg"` as 10. Empty strings,
`"NA"` and Stata's `"."` are missing without a warning; the text `"NaN"`
becomes `NaN`. Date strings become `NA`; parse them with
[`as.Date()`](https://rdrr.io/r/base/as.Date.html) or `lubridate::ymd()`
instead.

A factor whose levels are all numbers, such as
`factor(c("1990", "2000"))`, gives those numbers (1990, 2000). Other
factors give their level codes. Labelled numeric variables return their
values; labelled text is read from its values like plain text.

**Labels, missing values, and units**

`decode()` uses value labels when a labelled vector has a nonempty
`labels` attribute. Without value labels, it uses ordinary character
conversion, including for tagged missing values.

`destring()` and `decode()` keep SPSS user-missing codes as values or
labels. Numeric conversion preserves tagged missing values. Dates become
days since 1970-01-01; date-times become seconds since the Unix epoch.
Durations and measured vectors retain their numeric values in their
existing units. Conversion of large `integer64` values to double can
lose precision and emits the underlying conversion warning.

**Text formatting**

`tostring()` ignores value labels: labelled numeric vectors and factors
give their codes. For non-character input, values flagged by
[`is.na()`](https://rdrr.io/r/base/NA.html), including `NaN`, tagged
missing values, and SPSS user-missing codes, become `NA`. Character
input is returned unchanged. Numbers are written in full, so 100000
gives `"100000"`, not `"1e+05"`. Dates use
[`as.character()`](https://rdrr.io/r/base/character.html), giving
`"2024-01-31"` rather than day numbers.

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
