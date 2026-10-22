# Browse columns like Stata's `browse` command

Open all or selected columns in an interactive data viewer. Outside an
interactive session, no viewer is opened.

## Usage

``` r
browse(.data, ...)
```

## Arguments

- .data:

  A data frame or tibble.

- ...:

  \<[`tidy-select`](https://dplyr.tidyverse.org/reference/dplyr_tidy_select.html)\>
  or
  \<[`data-masking`](https://rlang.r-lib.org/reference/args_data_masking.html)\>
  Variables to browse. Omit to browse all columns. Selection and
  computed expressions follow
  [`s_select()`](https://socimh.github.io/tidystata/reference/s_select.md).

## Value

The viewed data, invisibly, with its data-frame class preserved. With no
selection this is the input data; otherwise it is the result of
[`s_select()`](https://socimh.github.io/tidystata/reference/s_select.md).
The input is not modified.

## Details

Viewing uses
[`tibble::view()`](https://tibble.tidyverse.org/reference/view.html).
Existing grouping and grouping-key retention follow
[`s_select()`](https://socimh.github.io/tidystata/reference/s_select.md).
Assign the invisible return value to keep the viewed columns for
subsequent analysis. Precompute expressions with side effects before
passing them to the selection interface.

## See also

[`ds()`](https://socimh.github.io/tidystata/reference/names.md),
[`variables()`](https://socimh.github.io/tidystata/reference/variables.md),
[`codebook()`](https://socimh.github.io/tidystata/reference/codebook.md)

Other inspection functions:
[`codebook()`](https://socimh.github.io/tidystata/reference/codebook.md),
[`misstable()`](https://socimh.github.io/tidystata/reference/misstable.md),
[`names`](https://socimh.github.io/tidystata/reference/names.md),
[`var_type()`](https://socimh.github.io/tidystata/reference/var_type.md),
[`variables()`](https://socimh.github.io/tidystata/reference/variables.md)

## Examples

``` r
if (interactive()) {
  browse(dplyr::starwars)
  browse(dplyr::starwars, name:mass)
  browse(dplyr::starwars, varlist("*color"))

  # Retain the viewed columns for the next pipeline stage.
  selected <- browse(dplyr::starwars, name, height, mass)
  summ(selected, height, mass)
}
```
