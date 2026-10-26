# Tabulate missing values

Summarize missing values by variable (`misstable summarize`) or tabulate
missingness patterns across rows (`misstable patterns`), following
Stata's `misstable` command.

## Usage

``` r
misstable(.data, ..., .by = NULL, .patterns = FALSE, .all = FALSE)
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
  mixed. Omit to check all columns except grouping keys.

- .by:

  \<[`tidy-select`](https://dplyr.tidyverse.org/reference/dplyr_tidy_select.html)\>
  Optional grouping variables. Grouped data use their groups unless
  `.by` is supplied. Select existing columns only; create new grouping
  columns with
  [`dplyr::mutate()`](https://dplyr.tidyverse.org/reference/mutate.html)
  first.

- .patterns:

  If `TRUE`, tabulate missingness patterns instead of summarizing
  individual variables.

- .all:

  If `TRUE`, include variables without missing values in either mode.
  Defaults to `FALSE`, as in Stata.

## Value

An ungrouped tibble with any grouping keys and:

- By default, one row per checked variable and group, with `variable`,
  `miss_n` (missing count), `miss_pct` (missing percentage), and
  `valid_n` (observed count). No checked variables gives zero rows.

- With `.patterns = TRUE`, one row per observed pattern and group, with
  a `1` (observed) or `0` (missing) column per checked variable, plus
  `n` (frequency) and `percent`. With no checked variables, each
  nonempty group has one row containing only its keys, `n`, and
  `percent`.

Percentages range from zero to 100 within each group. Summary rows for
zero-row ungrouped inputs have zero counts and `NA` percentages when
`.all = TRUE`; empty inputs have no pattern rows.

## Details

Atomic missingness follows [`is.na()`](https://rdrr.io/r/base/NA.html),
including `NaN`, haven's tagged missing values, and SPSS user-missing
codes and ranges. In list columns, `NA` is missing but `NULL` is
observed. Matrix and data-frame columns are missing only when all
components in a row are missing, following vctrs conventions.

Computed columns are evaluated on ungrouped working data before
missingness is summarized within groups. Create columns with grouped
[`dplyr::mutate()`](https://dplyr.tidyverse.org/reference/mutate.html)
first when a calculation needs to run separately within each group.

Empty strings are treated as observed values, unlike in Stata. Use
[`na_if_value()`](https://socimh.github.io/tidystata/reference/na_conversion.md)
to convert them to missing values.

With `.all = FALSE`, variables are checked only if they contain missing
values anywhere in the input. A message is displayed when none do.
Summary rows follow selection order within each group; patterns follow
decreasing frequency, with ties preferring observed values column by
column. Grouping keys must not conflict with output column names.
Pattern variables must also differ from grouping keys and the names `n`
and `percent`.

## See also

Other inspection functions:
[`browse()`](https://socimh.github.io/tidystata/reference/browse.md),
[`codebook()`](https://socimh.github.io/tidystata/reference/codebook.md),
[`names`](https://socimh.github.io/tidystata/reference/names.md),
[`var_type()`](https://socimh.github.io/tidystata/reference/var_type.md),
[`variables()`](https://socimh.github.io/tidystata/reference/variables.md)

## Examples

``` r
# Summarize missing values
misstable(lifeexp)
#> # A tibble: 2 × 4
#>   variable  miss_n miss_pct valid_n
#>   <chr>      <int>    <dbl>   <int>
#> 1 gnppc          1     1.47      67
#> 2 safewater     14    20.6       54

misstable(lifeexp, .all = TRUE)
#> # A tibble: 6 × 4
#>   variable  miss_n miss_pct valid_n
#>   <chr>      <int>    <dbl>   <int>
#> 1 region         0     0         68
#> 2 country        0     0         68
#> 3 popgrowth      0     0         68
#> 4 lexp           0     0         68
#> 5 gnppc          1     1.47      67
#> 6 safewater     14    20.6       54

# Tabulate missingness patterns
misstable(lifeexp, .patterns = TRUE)
#> # A tibble: 3 × 4
#>   gnppc safewater     n percent
#>   <int>     <int> <int>   <dbl>
#> 1     1         1    53   77.9 
#> 2     1         0    14   20.6 
#> 3     0         1     1    1.47

# Select variables and group observations
misstable(lifeexp, gnppc, safewater, .by = region)
#> # A tibble: 6 × 5
#>   region               variable  miss_n miss_pct valid_n
#>   <dbl+lbl>            <chr>      <int>    <dbl>   <int>
#> 1 1 [Europe & C. Asia] gnppc          1     2.27      43
#> 2 1 [Europe & C. Asia] safewater      2     4.55      42
#> 3 2 [North America]    gnppc          0     0         14
#> 4 2 [North America]    safewater      8    57.1        6
#> 5 3 [South America]    gnppc          0     0         10
#> 6 3 [South America]    safewater      4    40          6

# Check an existing column alongside a computed column
misstable(lifeexp, gnppc, water_share = safewater / 100, .all = TRUE)
#> # A tibble: 2 × 4
#>   variable    miss_n miss_pct valid_n
#>   <chr>        <int>    <dbl>   <int>
#> 1 gnppc            1     1.47      67
#> 2 water_share     14    20.6       54
```
