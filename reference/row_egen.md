# Calculate summaries across columns within each row

Summarize selected columns within each row using arithmetic, extrema,
distinct-value counts, or missing-value counts. Use a data frame
directly or select columns inside
[`dplyr::mutate()`](https://dplyr.tidyverse.org/reference/mutate.html).

- `row_mean()`: Calculate the arithmetic mean within each row.

- `row_sum()`: Add the values within each row.

- `row_max()`: Find the largest value within each row.

- `row_min()`: Find the smallest value within each row.

- `row_median()`: Find the median within each row.

- `row_var()`: Calculate the sample variance within each row.

- `row_sd()`: Calculate the sample standard deviation within each row.

- `row_unique()`: Count distinct values within each row, counting
  missing values as one category.

- `row_nvals()`: Count distinct non-missing values within each row by
  default; use `.missing = TRUE` to count missing values as one
  category.

- `row_miss()`: Count missing values within each row.

- `row_non_miss()`: Count non-missing values within each row.

## Usage

``` r
row_mean(..., na.rm = TRUE)

row_sum(..., na.rm = TRUE)

row_max(..., .values = NULL, na.rm = TRUE)

row_min(..., .values = NULL, na.rm = TRUE)

row_median(..., na.rm = TRUE)

row_var(..., na.rm = TRUE)

row_sd(..., na.rm = TRUE)

row_unique(...)

row_nvals(..., .missing = FALSE)

row_miss(...)

row_non_miss(...)
```

## Arguments

- ...:

  A data frame or tibble, or
  \<[`tidy-select`](https://dplyr.tidyverse.org/reference/dplyr_tidy_select.html)\>
  expressions inside
  [`dplyr::mutate()`](https://dplyr.tidyverse.org/reference/mutate.html).
  Each selected column must be one-dimensional.

- na.rm:

  For arithmetic and extrema helpers, if `TRUE` (the default), omit
  missing values; if `FALSE`, any missing input makes that row's result
  missing. Count helpers (`row_unique()`, `row_nvals()`, `row_miss()`,
  `row_non_miss()`) reject `na.rm`.

- .values:

  For `row_min()` and `row_max()`, additional values to compare with
  selected columns: a vector, or a list of vectors. Each must have
  length one or the number of input rows (the current group size inside
  grouped
  [`mutate()`](https://dplyr.tidyverse.org/reference/mutate.html)).
  Values must have compatible supported types.

- .missing:

  For `row_nvals()`, if `FALSE` (the default), missing values are not
  counted, as in egenmore's `rownvals()`; if `TRUE`, they count as one
  value, as in `row_unique()`.

## Value

A vector with one value per input row. Extrema retain the compatible
common type; arithmetic returns doubles or a supported class as
described under Arithmetic; unique and missing-value counts return
integers. Zero-row inputs return typed empty vectors. All-missing rows
return a typed `NA` for arithmetic and extrema, except
`row_sum(na.rm = TRUE)` returns zero; an all-missing row's mean is `NA`,
not `NaN`.

## Details

All helpers preserve the input. Missingness is determined from the
original columns, including tagged and SPSS user-missing values.
Arithmetic and extrema omit missing values by default. Variance and
standard deviation use the sample denominator and require at least two
observed values. `NULL` and zero selected columns are rejected. Means
and sums of observed numeric values agree with
[`base::rowMeans()`](https://rdrr.io/r/base/colSums.html) and
[`base::rowSums()`](https://rdrr.io/r/base/colSums.html). Undefined
arithmetic on observed infinities can produce `NaN`, as in base R.

## Extrema

`row_min()` and `row_max()` retain the compatible common type of the
selected columns. Logical inputs return logical values, integer inputs
return integers, and mixed logical/integer/double inputs use their
common numeric type. Supported ordered types also include character
vectors, ordered factors, `Date`, `POSIXct`, durations, measured
vectors, `integer64`, and labelled vectors. Character values use C
lexical ordering without numeric parsing; ordered factors use their
level order and cannot be mixed with other types. Labelled values are
compared by their underlying values. Compatible units are normalized
before comparison. Unordered factors, lists, complex values, and
incompatible combinations are rejected rather than assigned an arbitrary
ordering. Like [`pmin()`](https://rdrr.io/r/base/Extremes.html) and
[`pmax()`](https://rdrr.io/r/base/Extremes.html), bare numeric constants
in `row_min()` and `row_max()` are values, not column positions:
`row_min(x, 0.5)` caps `x` at 0.5. Inside
[`mutate()`](https://dplyr.tidyverse.org/reference/mutate.html), a
symbol that is not a column but names a numeric vector in the calling
environment is also used as values. Select columns by position with
[`c()`](https://rdrr.io/r/base/c.html) or a tidyselect helper, for
example `row_min(c(1, 2))`. Length-one constants (including those in
`.values`) never fill a row whose other inputs are all missing; such
rows stay `NA`, as with
[`pmin()`](https://rdrr.io/r/base/Extremes.html). Direct column
references remain columns in one-row groups; computed length-one values
are constants.

## Arithmetic

Plain logical, integer, double, and numeric labelled columns return
double vectors. Labels are dropped after applying the original
missingness mask. `integer64` arithmetic requires explicit conversion so
potential precision loss is a deliberate choice.

Columns from the same calendar family (`Date` or `POSIXct`) support mean
and median while retaining their common class and metadata. Calendar
sums, variance, and standard deviation require explicit numeric
conversion first. Durations support mean, median, sum, and standard
deviation and return `difftime` vectors in a common unit. For duration
variance, convert to one numeric unit first because variance has squared
units.

Compatible measured vectors on linear zero-origin scales are normalized
to a common unit. Mean, median, sum, and standard deviation retain that
unit; variance returns squared units. Offset scales such as Celsius and
Fahrenheit support mean and median only. Convert explicitly to a
zero-origin unit before requesting sums or dispersion. Nonlinear scales
require explicit conversion to a linear unit before any arithmetic.
Other classes and incompatible type combinations are rejected. Measured
arithmetic requires units \>= 1.0.0.

## Counts

`row_unique()` combines compatible column types and counts distinct
values without dropping their identities through numeric conversion.
This includes compatible factors, labelled vectors, calendar/measured
vectors, `integer64`, list columns, and complex vectors. Missing values
count as one category. List elements are compared as whole values rather
than flattened. For extrema and distinct counts, common-type conversion
must preserve each original value's missingness. Conflicting SPSS
missing-value definitions that would turn an observed value into a
missing value produce an error; harmonize those definitions explicitly
before combining the columns.

`row_miss()` and `row_non_miss()` use each original column's
[`is.na()`](https://rdrr.io/r/base/NA.html) result. Scalar missing list
elements are missing; `NULL` and empty list elements are observed.

## See also

Other variable generation functions:
[`as_dummy()`](https://socimh.github.io/tidystata/reference/as_dummy.md),
[`cut`](https://socimh.github.io/tidystata/reference/cut.md),
[`panel`](https://socimh.github.io/tidystata/reference/panel.md),
[`stata_recode()`](https://socimh.github.io/tidystata/reference/stata_recode.md),
[`std()`](https://socimh.github.io/tidystata/reference/std.md)

## Examples

``` r
tb <- tibble::tibble(x = c(1, 2, NA), y = c(3, NA, NA))
row_mean(tb)
#> [1]  2  2 NA

row_sum(tb)
#> [1] 4 2 0

row_non_miss(tb)
#> [1] 2 1 0

tb |>
  dplyr::mutate(mean = row_mean(x, y), sum = row_sum(x, y))
#> # A tibble: 3 × 4
#>       x     y  mean   sum
#>   <dbl> <dbl> <dbl> <dbl>
#> 1     1     3     2     4
#> 2     2    NA     2     2
#> 3    NA    NA    NA     0

tb |>
  dplyr::mutate(capped = row_min(x, .values = 0.5))
#> # A tibble: 3 × 3
#>       x     y capped
#>   <dbl> <dbl>  <dbl>
#> 1     1     3    0.5
#> 2     2    NA    0.5
#> 3    NA    NA   NA  

row_sum(tb, na.rm = FALSE)
#> [1]  4 NA NA

flags <- tibble::tibble(a = c(TRUE, FALSE, NA), b = c(FALSE, NA, NA))
row_max(flags) # TRUE, FALSE, NA, with logical type
#> [1]  TRUE FALSE    NA

dates <- tibble::tibble(
  start = as.Date(c("2024-01-01", NA)),
  end = as.Date(c("2024-01-03", "2024-01-05"))
)
row_min(dates)
#> [1] "2024-01-01" "2024-01-05"

row_mean(dates)
#> [1] "2024-01-02" "2024-01-05"
```
