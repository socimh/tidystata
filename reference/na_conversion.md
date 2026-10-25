# Replace values with missing values or fill missing values

Vector helpers named after Stata's missing-value commands:

- `mvdecode()` replaces every value in `mv` with `NA`, like
  `mvdecode x, mv(-98 -99)`. Each code is matched with
  [`dplyr::na_if()`](https://dplyr.tidyverse.org/reference/na_if.html).

- `mvencode()` replaces missing values with `mv`, like
  `mvencode x, mv(0)`. The replacement is cast to the type of `x`, as in
  [`tidyr::replace_na()`](https://tidyr.tidyverse.org/reference/replace_na.html).

`na_if_value()` and `value_if_na()` are aliases of `mvdecode()` and
`mvencode()`. Use `mutate(x = mvdecode(x, -99))` for one variable, or
`mutate(across(c(x, y), \(v) mvdecode(v, -99)))` for a varlist.

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

Casting and error behavior follow the underlying functions: codes are
cast to the type of `x`, so a lossy cast such as `1.5` for an integer
vector is an error. A call with only one argument is incomplete. For
SPSS labelled vectors
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

mvencode(c(1, NA, 4), 0)
#> [1] 1 0 4
```
