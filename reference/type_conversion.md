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

**Reading numbers with `destring()`**

Text must contain a complete number. Signs, exponents,
dollar/euro/pound/yen symbols, thousands separators (`"1,234"`),
trailing percent signs (`"50%"` gives 50) and surrounding spaces,
including non-breaking spaces, are accepted. Use `ignore` to remove
other characters first: `ignore = "kg"` lets `"10 kg"` become 10.

Invalid text becomes `NA` with a warning, like Stata's `force` option.
[`readr::problems()`](https://readr.tidyverse.org/reference/problems.html)
gives its positions and original values. Empty strings, `"NA"` and `"."`
become missing without a warning; `"NaN"` becomes `NaN`. Date strings
are invalid; parse them with
[`as.Date()`](https://rdrr.io/r/base/as.Date.html) or
`lubridate::ymd()`.

Factors give their numeric level values only when every level, including
unused levels, parses as a number. Otherwise they give their integer
codes. Labelled vectors use their stored values, parsing text as above.
SPSS user-missing codes remain values, and tagged missing values retain
their tags. Lists, raw vectors and complex vectors give `NA` for each
element.

Dates become days since 1970-01-01; date-times become seconds since the
Unix epoch. Durations and measured values keep their numbers in the
existing units. Large `integer64` values can lose precision when
converted to double, with a warning from the underlying conversion.

**Creating labels with `encode()`**

Character categories receive codes 1, 2, 3, ... in UTF-8 radix order,
which is reproducible but may differ from Stata's locale-based ordering.
Numeric-looking text is still a category: `"10"`, `"20"`, `"3"` receive
codes 1, 2, 3. `NA` and `""` become missing; spaces are retained.

Factors keep their integer codes and use all levels as labels, including
unused, empty-string and explicit `NA` levels. For example,
`factor(c(10, 20))` keeps codes 1 and 2. Ordered factors lose their
ordering metadata.

Encode character columns before grouping so every group uses the same
codes. Separate calls can assign different codes; factors with shared
levels keep consistent codes in grouped
[`dplyr::mutate()`](https://dplyr.tidyverse.org/reference/mutate.html).
You cannot supply an existing label dictionary. Re-encoding decoded text
creates a new dictionary, so `encode(decode(x))` may change the original
codes.

**Reading labels with `decode()`**

`decode()` uses value labels when available and factor levels for
factors. Values without a label remain as text, whereas Stata turns them
into empty strings. SPSS user-missing codes remain values or labels.

Inputs without value labels use ordinary
[`as.character()`](https://rdrr.io/r/base/character.html) conversion,
including for tagged missing values. Thus 100000 may become `"1e+05"`;
use `tostring()` to write numbers in full. Unlike Stata's `decode`, this
function also accepts factors, labelled character vectors and unlabelled
inputs.

**Writing text with `tostring()`**

`tostring()` ignores value labels and converts factor codes to text.
Numbers are written in full (`100000` becomes `"100000"`), with the
significant digits of
[`as.character()`](https://rdrr.io/r/base/character.html) and a decimal
point regardless of `options(OutDec)`. Distinct large numbers can
produce the same text; keep identifiers as character or `integer64`
vectors when exact digits matter.

For non-character input, values flagged by
[`is.na()`](https://rdrr.io/r/base/NA.html) become `NA`, including
`NaN`, tagged missing values and SPSS user-missing codes. Stata instead
writes missing values as `"."` or `".a"` through `".z"`. Character input
is unchanged. AsIs wrappers are ignored for other inputs; durations and
measured values use their existing units. Dates use
[`as.character()`](https://rdrr.io/r/base/character.html), for example
`"2024-01-31"`.

The aliases `as_numeric()` and `as_character()` also exist in
sjlabelled, with different behavior: its numeric conversion codes
non-numeric text as factors, and its character conversion makes
unlabelled values `NA`. Use `tidystata::as_numeric()` or the names
`destring()` and `tostring()` to avoid depending on which package was
attached last.

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

# integer codes as text
tostring(category)
#> [1] "2" "1" "2" NA  NA 

# category text
decode(category)
#> [1] "beta"  "alpha" "beta"  NA      NA     
```
