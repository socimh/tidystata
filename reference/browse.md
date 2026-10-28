# Browse columns like Stata's `browse` command

Open all or selected columns in an interactive data viewer. Outside an
interactive session, no viewer is opened.

## Usage

``` r
browse(.data, ...)
```

## Arguments

- .data:

  A data frame, tibble, or data.table.

- ...:

  \<[`tidy-select`](https://dplyr.tidyverse.org/reference/dplyr_tidy_select.html)\>
  or
  \<[`data-masking`](https://rlang.r-lib.org/reference/args_data_masking.html)\>
  Columns to select or compute with
  [`select_or_transmute()`](https://socimh.github.io/tidystata/reference/select_or_transmute.md).
  Existing columns, selection helpers, and named expressions can be
  mixed. Omit to browse all columns.

## Value

The viewed data, invisibly, with its data-frame class preserved. With no
selection this is the input data; otherwise it is the result of
[`select_or_transmute()`](https://socimh.github.io/tidystata/reference/select_or_transmute.md).
The input is not modified.

## Details

Viewing uses
[`tibble::view()`](https://tibble.tidyverse.org/reference/view.html).
Existing grouping and grouping-key retention follow
[`select_or_transmute()`](https://socimh.github.io/tidystata/reference/select_or_transmute.md).
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
  browse(lifeexp)

  browse(lifeexp, country:lexp)

  browse(lifeexp, varlist("*p*"))

  browse(lifeexp, country, gnppc_thousands = gnppc / 1000)

  # Retain the viewed columns for the next pipeline stage.
  selected <- browse(lifeexp, country, lexp, gnppc)
  summ(selected, lexp, gnppc)
}
```
