# Select columns with a Stata varlist

`varlist()` selects columns with a Stata-style varlist string such as
`"inc* age? x[1-12]"`, as in Stata's `keep inc* age?`. It is a simpler
version of
[`matches()`](https://tidyselect.r-lib.org/reference/starts_with.html)
in
\<[`tidy-select`](https://dplyr.tidyverse.org/reference/dplyr_tidy_select.html)\>.

Use `varlist()` within a *selecting* function, such as
[`ds()`](https://socimh.github.io/tidystata/reference/names.md),
[`tab()`](https://socimh.github.io/tidystata/reference/tab.md) or
[`dplyr::across()`](https://dplyr.tidyverse.org/reference/across.html).
Alternatively, provide `vars` explicitly to return matching positions in
a standalone call. `varlist()` was called
[`s_match()`](https://socimh.github.io/tidystata/reference/tidystata-deprecated.md)
before tidystata 0.3.0; the old name still works with a deprecation
warning.

## Usage

``` r
varlist(
  string,
  ignore_case = TRUE,
  vars = NULL,
  ignore.case = lifecycle::deprecated()
)
```

## Arguments

- string:

  A single character string containing patterns, separated by spaces,
  like selecting a varlist in Stata's `keep` command.

- ignore_case:

  If `TRUE` (the default), matching ignores case.

- vars:

  A character vector of variable names. If not supplied, the variables
  are taken from the current selection context (as established by
  functions like
  [`select()`](https://dplyr.tidyverse.org/reference/select.html) or
  `pivot_longer()`).

- ignore.case:

  **\[deprecated\]** Use `ignore_case` instead.

## Value

An integer vector of positions in the available column names.

## Details

- `*` matches zero or more characters.

- `~` matches one or more characters.

- `?` matches one character.

- `[a-h]` matches any character in the range from `a` to `h`.

- `[1-12]` matches any number in the range from `1` to `12`.

- `var1-var5` is NOT used to select a range of variables. Use
  `var1:var5` outside `varlist()` instead.

Space-separated patterns are alternatives, each matched against complete
column names. Numeric ranges expand within each pattern before matching.
Each pattern can contain one bracketed range; separate patterns may each
contain their own range.

## See also

Other selection and preview functions:
[`s_select()`](https://socimh.github.io/tidystata/reference/s_select.md),
[`special-print`](https://socimh.github.io/tidystata/reference/special-print.md)

## Examples

``` r
varlist("x[1-2] y", vars = c("x1", "x2", "x3", "y"))
#> [1] 1 2 4

tb <- paste0("x", 1:15) |>
  tibble::as_tibble() |>
  tidyr::pivot_wider(names_from = value)
tb
#> # A tibble: 1 × 15
#>   x1    x2    x3    x4    x5    x6    x7    x8    x9    x10   x11   x12   x13  
#>   <chr> <chr> <chr> <chr> <chr> <chr> <chr> <chr> <chr> <chr> <chr> <chr> <chr>
#> 1 x1    x2    x3    x4    x5    x6    x7    x8    x9    x10   x11   x12   x13  
#> # ℹ 2 more variables: x14 <chr>, x15 <chr>

# List variable names by ds()
ds(tb)
#>  [1] "x1"  "x2"  "x3"  "x4"  "x5"  "x6"  "x7"  "x8"  "x9"  "x10" "x11" "x12"
#> [13] "x13" "x14" "x15"

tb |>
  ds(varlist("x1*"))
#> [1] "x1"  "x10" "x11" "x12" "x13" "x14" "x15"

tb |>
  ds(varlist("x1~"))
#> [1] "x10" "x11" "x12" "x13" "x14" "x15"

tb |>
  ds(varlist("*5"))
#> [1] "x5"  "x15"

tb |>
  ds(varlist("?5"))
#> [1] "x5"

tb |>
  ds(varlist("x[9-15]"))
#> [1] "x9"  "x10" "x11" "x12" "x13" "x14" "x15"

# A literal hyphen pattern selects no columns here; it is not a range.
tb |>
  ds(varlist("x1-x5"))
#> character(0)

tb |>
  ds(x1:x5)
#> [1] "x1" "x2" "x3" "x4" "x5"
```
