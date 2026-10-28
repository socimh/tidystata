# Convert vectors for data preparation

Prepare vectors using Stata-style conversion commands:

- `destring()` (`as_numeric()`): Convert text to numbers; labelled
  numeric vectors use their stored values.

- `tostring()` (`as_character()`): Convert stored values to text, using
  numeric codes for labelled numeric vectors and factors rather than
  labels.

- `encode()`: Convert text categories to labelled integer codes, or
  retain a factor's integer codes with its levels as value labels.

- `decode()`: Convert values to text, using value labels for labelled
  vectors and level text for factors.

## Usage

``` r
destring(x, ignore = NULL)

decode(x)

encode(x)

tostring(x)

as_character(x)

as_numeric(x, ignore = NULL)
```

## Arguments

- x:

  A vector or matrix. For `encode()`, a character vector or factor
  without dimensions. Data frames are not accepted; convert their
  columns with
  [`dplyr::across()`](https://dplyr.tidyverse.org/reference/across.html).

- ignore:

  `NULL` (default) or a single string of characters to remove from text
  before reading numbers, like Stata's `ignore()`. Each character is
  removed wherever it appears: `ignore = "kg "` removes `k`, `g` and
  spaces.

## Value

Results retain the length and element order of `x`:

- `destring()` (`as_numeric()`): A double vector. Invalid numeric text
  adds a `problems` attribute readable with
  [`readr::problems()`](https://readr.tidyverse.org/reference/problems.html).

- `tostring()` (`as_character()`): A character vector, except that
  character input is returned unchanged, including names, dimensions and
  attributes.

- `encode()`: A `haven_labelled` integer vector with value labels and
  the input's variable label, if present. Names and other attributes are
  dropped.

- `decode()`: A character vector containing value labels or converted
  values.

Except for the preservation rules above, names, dimensions, labels and
units are dropped; matrices are flattened in column order. Empty inputs
return typed empty results. None of these functions modifies the input.

## Details

**Reading numbers**

`destring()` reads text the way Stata's `destring` does. A value must be
a number, optionally with a sign, exponent, currency symbol (dollar,
euro, pound, yen), thousands separators (`1,234`), a trailing percent
sign (`50%` gives 50) and surrounding spaces, including non-breaking
spaces. Anything else, such as `"12abc"`, `"10 kg"` or a date, becomes
`NA` with a warning, like Stata's `force` option; the positions and
original values are kept in
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
Unsupported numeric-conversion inputs, such as lists, raw vectors and
complex vectors, return missing values of the same length.

**Labels, missing values, and units**

`decode()` uses value labels when a labelled vector has a nonempty
`labels` attribute. Without value labels, it uses ordinary character
conversion, including for tagged missing values, so 100000 gives
`"1e+05"`; use `tostring()` to write numbers in full.

`destring()` and `decode()` keep SPSS user-missing codes as values or
labels. Numeric conversion preserves tagged missing values. Dates become
days since 1970-01-01; date-times become seconds since the Unix epoch.
Durations and measured vectors retain their numeric values in their
existing units. Conversion of large `integer64` values to double can
lose precision and emits the underlying conversion warning.

**Encoding categories**

`encode()` assigns codes 1, 2, 3, ... to distinct nonempty character
values in UTF-8 radix order. Numeric-looking text is a category: `"10"`,
`"20"`, `"3"` get codes 1, 2, 3, not the numbers 10, 20, 3. `NA` and
`""` become missing; spaces are retained. Radix ordering is reproducible
but can differ from locale-specific alphabetical ordering in Stata.

For factors and ordered factors, `encode()` preserves the stored integer
indices and uses all levels as value labels, including unused levels and
explicit empty-string and `NA` levels. Numeric level text does not
replace indices: `factor(c(10, 20))` has codes 1 and 2. Ordering
metadata is dropped.

`encode(decode(x))` need not recover the original codes: decoding
discards the dictionary, so re-encoding character text creates new codes
starting at 1. Existing dictionaries cannot be supplied to `encode()`.
Encode character columns before grouping to use one dictionary across
groups; separate calls can assign conflicting codes. Factors with shared
levels retain a common dictionary within grouped
[`dplyr::mutate()`](https://dplyr.tidyverse.org/reference/mutate.html).

`decode()` follows Stata's value-label conversion but also accepts
factors, labelled character vectors and unlabelled inputs as an R
convenience. It falls back to ordinary character conversion when no
value labels exist. For partial dictionaries, unlabelled values remain
as text, whereas Stata returns empty strings for them.

**Text formatting**

`tostring()` and its alias `as_character()` ignore value labels:
labelled numeric vectors and factors give their codes. For non-character
input, values flagged by [`is.na()`](https://rdrr.io/r/base/NA.html),
including `NaN`, tagged missing values, and SPSS user-missing codes,
become `NA`. Character input is returned unchanged. Numbers are written
in full, so 100000 gives `"100000"`, not `"1e+05"`, with the significant
digits of [`as.character()`](https://rdrr.io/r/base/character.html) and
a decimal point whatever `options(OutDec)` says. This precision policy
can map distinct large numbers to the same text; keep identifiers as
character or `integer64` vectors when exact digits matter. AsIs wrappers
are ignored for non-character input. Measured values and durations are
written as numbers in their existing units. Dates use
[`as.character()`](https://rdrr.io/r/base/character.html), giving
`"2024-01-31"` rather than day numbers. Unlike Stata's `tostring`,
missing values remain `NA` rather than becoming the strings `"."` or
`".a"` through `".z"`.

The sjlabelled package also exports `as_numeric()` and `as_character()`.
They differ: sjlabelled's `as_numeric()` turns non-numeric text into
factor codes, and its `as_character()` gives `NA` for unlabelled values.
Whichever package is attached last masks the other; write
`tidystata::as_numeric()` to be explicit, or use `destring()` and
`tostring()`, which do not clash. To read value labels as text, use
`decode()`.

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

category <- encode(c("beta", "alpha", "beta", "", NA))
category
#> <labelled<integer>[5]>
#> [1]  2  1  2 NA NA
#> 
#> Labels:
#>  value label
#>      1 alpha
#>      2  beta
tostring(category) # integer codes as text
#> [1] "2" "1" "2" NA  NA 
decode(category) # category text
#> [1] "beta"  "alpha" "beta"  NA      NA     
encode(factor(c("Yes", "No"), levels = c("Unused", "No", "Yes")))
#> <labelled<integer>[2]>
#> [1] 3 2
#> 
#> Labels:
#>  value  label
#>      1 Unused
#>      2     No
#>      3    Yes
```
