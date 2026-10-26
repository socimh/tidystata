# Replace values with missing values or fill missing values

Convert between missing values and explicit replacement codes:

- `mvdecode()` (`na_if_value()`): Replace specified codes with `NA`,
  like Stata's `mvdecode x, mv(-98 -99)`.

- `mvencode()` (`value_if_na()`): Fill missing values with one
  replacement, like Stata's `mvencode x, mv(0)`.

The aliases perform the same operations but name the replacement
argument `value` instead of `mv`.

## Usage

``` r
mvdecode(x, mv)

mvencode(x, mv)

na_if_value(x, value)

value_if_na(x, value)
```

## Arguments

- x:

  A vector.

- mv, value:

  For `mvdecode()` and `na_if_value()`, the codes to replace with `NA`;
  any value equal to one of them becomes missing. For `mvencode()` and
  `value_if_na()`, a single replacement value for missing elements, cast
  to the type of `x`.

## Value

A vector with the same type and size as `x`, with matching values
replaced or missing values filled.

## Details

Codes are matched with
[`dplyr::na_if()`](https://dplyr.tidyverse.org/reference/na_if.html);
filling follows
[`tidyr::replace_na()`](https://tidyr.tidyverse.org/reference/replace_na.html).
Codes and replacements are cast to the type of `x`, so a lossy cast such
as `1.5` for an integer vector is an error when applied. Filling a
non-SPSS vector with no missing values returns it unchanged without
casting the replacement. Both the input vector and the codes or
replacement must be supplied. For SPSS labelled vectors
([`haven::labelled_spss()`](https://haven.tidyverse.org/reference/labelled_spss.html)),
user-defined missing codes and ranges also count as missing, matching
their [`is.na()`](https://rdrr.io/r/base/NA.html) method; labels and
missing-value metadata are retained.

## See also

Other conversion functions:
[`type_conversion`](https://socimh.github.io/tidystata/reference/type_conversion.md)

## Examples

``` r
x <- c(1, -99, NA, 4, -98)
mvdecode(x, -99)
#> [1]   1  NA  NA   4 -98

mvdecode(x, c(-98, -99))
#> [1]  1 NA NA  4 NA

mvencode(x, 0)
#> [1]   1 -99   0   4 -98
```
