# Summarise columns

Compute one row of summary statistics per selected variable and group.
`tabstat()` uses `.stat = "mean"` by default; with `.detail = TRUE` and
no explicit `.stat`, it returns all detail statistics.

## Usage

``` r
summ(
  .data,
  ...,
  .by = NULL,
  .keep_all = FALSE,
  .detail = FALSE,
  .stat = character(0),
  .missing = TRUE,
  .name = FALSE,
  .type = c("list", "table"),
  .duration_format = c("long", "compact"),
  .sort = TRUE,
  .drop_empty = FALSE,
  .wt = NULL,
  .wt_type = c("frequency", "analytic")
)

tabstat(
  .data,
  ...,
  .by = NULL,
  .keep_all = FALSE,
  .detail = FALSE,
  .stat = "mean",
  .missing = TRUE,
  .name = FALSE,
  .type = c("list", "table"),
  .duration_format = c("long", "compact"),
  .sort = TRUE,
  .drop_empty = FALSE,
  .wt = NULL,
  .wt_type = c("frequency", "analytic")
)
```

## Arguments

- .data:

  A data frame, data frame extension (e.g. a tibble), or a vector.
  Matrix and data-frame columns are unsupported; use atomic or list
  columns. For `sf` input, summarise attribute data only: all geometry
  columns are removed before selection. Geometry columns cannot be
  selected or grouped.

- ...:

  \<[`tidy-select`](https://dplyr.tidyverse.org/reference/dplyr_tidy_select.html)\>
  or
  \<[`data-masking`](https://rlang.r-lib.org/reference/args_data_masking.html)\>
  Columns to select or compute with
  [`select_or_transmute()`](https://socimh.github.io/tidystata/reference/select_or_transmute.md).
  Existing columns, selection helpers, and named expressions can be
  mixed. Omit to summarize all columns except grouping keys.

- .by:

  Optional grouping columns, selected with tidyselect. An explicit
  selection overrides existing
  [`group_by()`](https://dplyr.tidyverse.org/reference/group_by.html)
  groups; when omitted, existing groups are used. Grouping columns are
  excluded from the measured variables. Select existing columns only;
  create new grouping columns with
  [`dplyr::mutate()`](https://dplyr.tidyverse.org/reference/mutate.html)
  first.

- .keep_all:

  If `FALSE` (default), unsupported nonnumeric columns are removed with
  a warning; an error is raised if none of the selected columns can be
  summarised. If `TRUE`, character/list columns retain counts and unique
  values, with numeric statistics set to `NA`. Numeric-looking character
  values are not parsed.

- .detail:

  If `TRUE`, return all statistics available for each variable type
  unless `.stat` selects a subset. Defaults to `FALSE`.

- .stat:

  A character vector. If nonempty, return only the listed statistics,
  plus variable names, types and any grouping columns. Supported names
  are `type`, `n`, `unique`, `miss_n`, `valid_pct`, `min`, `q1`,
  `median`, `mean`, `mad`, `sd`, `q3`, `max`, `iqr`, `skew`, `kurtosis`,
  `se`, and `sum`. Aliases `missing`, `p25`, `p50`, and `p75` select
  `miss_n`, `q1`, `median`, and `q3`; requested names and order are
  retained. Identical requested names are deduplicated; aliases and
  canonical names may coexist. `sum` applies to numeric summaries, not
  calendar dates or datetimes. Calendar summaries do not support `skew`
  or `kurtosis` either; when such a statistic is requested alongside
  numeric variables, calendar variables are skipped with a warning.
  Percentiles `p0` through `p100`, including decimals such as `p2.5`,
  follow Stata's rule (see Details).

- .missing:

  If `TRUE` (default), rows with a missing grouping key form their own
  group, like Stata's `tabstat, by() missing`. If `FALSE`, drop them
  before summarising. Missing measured values are always omitted from
  numeric statistics, regardless of this flag.

- .name:

  If `FALSE` (default), drop the `name` column when exactly one measured
  variable is summarised, including zero-row grouped output; with
  several variables it is always kept. If `TRUE`, always retain it.

- .type:

  `"list"` (default) separates variable-type families when needed;
  `"table"` combines them in one table. See Value for the return
  structure and Details for calendar conversions.

- .duration_format:

  Retained for compatibility and no longer affects the output: calendar
  spreads are always `difftime` columns (see Details).

- .sort:

  If `TRUE` (default), sort grouping keys ascending like
  [`tab()`](https://socimh.github.io/tidystata/reference/tab.md) (factor
  levels in their defined order, character keys in C-locale order), with
  ordinary missing keys last. SPSS user-missing codes retain their
  stored-value ordering. Within each group, preserve the selected
  variable order. If `FALSE`, groups follow first appearance.

- .drop_empty:

  If `TRUE`, remove individual summary rows with no observed measured
  values (`n == 0`), even when `n` is not requested. This is independent
  of `.missing`. Default is `FALSE`.

- .wt:

  Optional weights: a numeric column of `.data` (or a vector with one
  value per row), like Stata's `summarize [fweight/aweight]`. Rows with
  a missing weight are excluded with a message; negative weights are an
  error. When `...` is omitted, the weight column is not summarised
  itself.

- .wt_type:

  `"frequency"` (default) or `"analytic"`. With frequency weights, `n`
  is the sum of the weights (non-integer weights are allowed). Analytic
  weights (Stata's `[aweight]`) are rescaled within each group and
  variable to sum to the number of observed values, so `n` is the number
  of observations. Means, percentiles and `sum` are the same under both
  types; `sd` and `se` differ.

## Value

An ungrouped table with one row per measured variable and group, or a
list of such tables:

- With `.type = "list"`, one table for a single variable-type family;
  otherwise, a list named `numeric`, `date`, `datetime`, and/or `time`
  (`hms`). The numeric family includes columns retained by `.keep_all`.

- With `.type = "table"`, one combined table.

Tables include grouping keys, `name` (subject to `.name`), `type`, and
statistics. By default, `summ()` includes `n`, `unique`, `min`, `mean`,
`sd`, and `max`; `tabstat()` includes `mean`. `.detail` adds the
available statistics listed under `.stat`, which can instead choose a
subset and its column names/order. Calendar location columns are
character; spreads are `difftime` in list mode and numeric in table
mode. Entirely missing columns have zero observed/distinct counts and
`NA` location/spread statistics, including `sum`; zero-row grouped
inputs have no result rows.

Tables preserve the input's data.frame, tibble, or data.table container
and supported preview settings; other subclasses are not reconstructed.
Vector input returns a tibble in list mode or a data.frame in table
mode. Its expression supplies the variable name, falling back to `value`
for multiline expressions or a magrittr pipe (`.`); a named tibble
supplies a stable name.

## Details

Computed columns are evaluated on ungrouped working data before
statistics are calculated within groups. Create columns with grouped
[`dplyr::mutate()`](https://dplyr.tidyverse.org/reference/mutate.html)
first when a calculation needs to run separately within each group.

**Counts and missing values**

`n` counts observed values and `unique` counts distinct observed values.
`miss_n` counts missing values; `valid_pct` is the fraction observed,
from zero to one, and is `NA` for zero-row inputs. Missingness follows
the original vector's [`is.na()`](https://rdrr.io/r/base/NA.html)
method, including SPSS user-missing values/ranges. Retained list columns
count complete element identities without flattening. Columns with no
observed values remain in the result: `n` and `unique` are zero and
location/spread statistics, including `sum`, are `NA`. Zero-row grouped
inputs do not create artificial groups.

**Numeric statistics**

Numeric calculations use double precision. Large `integer64` values may
lose precision during conversion, with a warning.

Logical values are treated as zero/one. Factors and ordered factors use
their underlying level codes with a warning. Numeric labelled vectors
use underlying values, excluding user-missing codes; label metadata is
flagged with a warning. Measured vectors and `difftime` use their
original units. In variable names, `*` marks labelled vectors, `**`
marks factors and `***` marks retained nonnumeric columns.

Statistics follow Stata's `summarize, detail`:

- SD uses the sample denominator (`n - 1`); `se` is SD divided by
  `sqrt(n)`.

- Percentiles use Stata's rule, not R's default
  [`stats::quantile()`](https://rdrr.io/r/stats/quantile.html) type 7:
  with `n` sorted values, the `p`th percentile is the value at position
  `floor(n * p) + 1`, or the mean of the values at positions `n * p` and
  `n * p + 1` when `n * p` is whole. So `q1` of `1:4` is 1.5 (type 7
  gives 1.75). `median`, `q1`, `q3` and `iqr` (`q3 - q1`) use the same
  rule.

- `skew` and `kurtosis` use population moments, `m3 / m2^1.5` and
  `m4 / m2^2`, so `kurtosis` is 3 for a normal distribution (not excess
  kurtosis). They are `NA` when the values are constant or fewer than
  two.

- `mad` has no Stata counterpart; it uses
  [`stats::mad()`](https://rdrr.io/r/stats/mad.html) with its default
  scaling.

For singleton or constant inputs, undefined spread statistics are `NA`.

**Weighted statistics**

With `.wt`, the mean is `sum(w * x) / W` and the variance is
`sum(w * (x - mean)^2) / (W - 1)`, where `W` is the summed weight (after
rescaling for analytic weights); `se` is `sd / sqrt(W)`, and `sum` is
`sum(w * x)` with the weights as given, as Stata's `r(sum)`, even for
analytic weights. Percentiles, `median`, `q1`, `q3`, `iqr` and `mad` use
Stata's weighted percentile rule, the unweighted rule with cumulative
weights in place of positions, so weights of 1 give the unweighted
values. `min` and `max` ignore rows with zero weight. `unique`, `miss_n`
and `valid_pct` remain unweighted row counts. These standard errors do
not account for a survey design. Use `survey::svymean()` for inference
with sampling weights, clusters or strata.

**Calendar output and grouping names**

Date locations are displayed as `YYYY-MM-DD`; fractional days are not
shown. Infinite Date locations are displayed as `-Inf` or `Inf`; missing
locations remain `NA`. Datetime locations are displayed as
`YYYY-MM-DD HH:MM`, without seconds, in the variable's own time zone
(the session time zone when none is set). `hms` time-of-day locations
are displayed as `hh:mm:ss`.

Calendar spread statistics (`sd`, `se`, `mad`, `iqr`) are `difftime`
columns, so they can be compared across rows and used in arithmetic.
Each column has one unit: days for Dates; for datetimes and times, the
unit (seconds, minutes, hours or days) that fits the column's median
nonzero spread. Convert with, for example,
`as.numeric(out$sd, units = "hours")`.

With `.type = "table"`, calendar locations are text. A shared location
column such as `mean` becomes character, with numeric values rounded to
seven significant digits; counts remain numeric. Calendar spreads become
numbers in days (Dates) or seconds (datetimes and times), with the unit
appended to `type`, for example `"date [days]"`.

Grouping keys that collide with summary metadata or internal pivot names
are renamed by prepending dots until unique among the input names, with
a message. The input data are not modified.

## Examples

``` r
summ(lifeexp)
#> Warning: country is non-numeric and thus removed.
#> Warning: region is a labelled variable (*).
#> # A tibble: 5 × 8
#>   name      type        n unique   min     mean        sd     max
#>   <chr>     <chr>   <int>  <int> <dbl>    <dbl>     <dbl>   <dbl>
#> 1 *region   dbl+lbl    68      3   1      1.5       0.743     3  
#> 2 popgrowth dbl        68     32  -2.5    0.553     1.06      2.6
#> 3 lexp      dbl        68     20  57     71.7       5.16     79  
#> 4 gnppc     dbl        67     64 170   9137.    11497.    46650  
#> 5 safewater dbl        54     32  36     77.2      20.6     100  

summ(lifeexp, .by = region)
#> Warning: country is non-numeric and thus removed.
#> # A tibble: 12 × 9
#>    region               name     type      n unique   min    mean      sd    max
#>    <dbl+lbl>            <chr>    <chr> <int>  <int> <dbl>   <dbl>   <dbl>  <dbl>
#>  1 1 [Europe & C. Asia] popgrow… dbl      44     25  -2.5 7.05e-2 9.10e-1 1.8 e0
#>  2 1 [Europe & C. Asia] lexp     dbl      44     17  62   7.25e+1 4.95e+0 7.9 e1
#>  3 1 [Europe & C. Asia] gnppc    dbl      43     42 170   1.13e+4 1.29e+4 4.66e4
#>  4 1 [Europe & C. Asia] safewat… dbl      42     25  36   8.16e+1 1.86e+1 1   e2
#>  5 2 [North America]    popgrow… dbl      14     11   0.3 1.33e+0 7.80e-1 2.6 e0
#>  6 2 [North America]    lexp     dbl      14     13  57   6.97e+1 6.14e+0 7.9 e1
#>  7 2 [North America]    gnppc    dbl      14     14 410   6.29e+3 9.08e+3 3.20e4
#>  8 2 [North America]    safewat… dbl       6      5  40   5.8 e+1 2.40e+1 9.9 e1
#>  9 3 [South America]    popgrow… dbl      10      7   0.5 1.59e+0 4.89e-1 2.2 e0
#> 10 3 [South America]    lexp     dbl      10      8  61   7.07e+1 4.06e+0 7.6 e1
#> 11 3 [South America]    gnppc    dbl      10      9 960   3.88e+3 2.43e+3 7.96e3
#> 12 3 [South America]    safewat… dbl       6      6  45   6.53e+1 1.70e+1 9.1 e1

tabstat(lifeexp, .by = region)
#> Warning: country is non-numeric and thus removed.
#> # A tibble: 12 × 4
#>    region               name      type        mean
#>    <dbl+lbl>            <chr>     <chr>      <dbl>
#>  1 1 [Europe & C. Asia] popgrowth dbl       0.0705
#>  2 1 [Europe & C. Asia] lexp      dbl      72.5   
#>  3 1 [Europe & C. Asia] gnppc     dbl   11284.    
#>  4 1 [Europe & C. Asia] safewater dbl      81.6   
#>  5 2 [North America]    popgrowth dbl       1.33  
#>  6 2 [North America]    lexp      dbl      69.7   
#>  7 2 [North America]    gnppc     dbl    6294.    
#>  8 2 [North America]    safewater dbl      58     
#>  9 3 [South America]    popgrowth dbl       1.59  
#> 10 3 [South America]    lexp      dbl      70.7   
#> 11 3 [South America]    gnppc     dbl    3881     
#> 12 3 [South America]    safewater dbl      65.3   

# Weighted summaries, like Stata's summarize [aweight = w]
survey <- tibble::tibble(income = c(10, 20, 40), w = c(3, 1, 1))
summ(survey, income, .wt = w, .stat = c("n", "mean", "sd", "p50"))
#> # A tibble: 1 × 5
#>   type      n  mean    sd   p50
#>   <chr> <dbl> <dbl> <dbl> <dbl>
#> 1 dbl       5    18  13.0    10

summ(survey, income, .wt = w, .wt_type = "analytic", .stat = c("n", "sd"))
#> # A tibble: 1 × 3
#>   type      n    sd
#>   <chr> <dbl> <dbl>
#> 1 dbl       3  14.3

lifeexp |>
  summ(
    dplyr::where(is.numeric),
    .by = region,
    .stat = c("n", "mean", "sd", "p50")
  )
#> # A tibble: 12 × 7
#>    region               name      type      n       mean        sd     p50
#>    <dbl+lbl>            <chr>     <chr> <int>      <dbl>     <dbl>   <dbl>
#>  1 1 [Europe & C. Asia] popgrowth dbl      44     0.0705     0.910    0.1 
#>  2 1 [Europe & C. Asia] lexp      dbl      44    72.5        4.95    72.5 
#>  3 1 [Europe & C. Asia] gnppc     dbl      43 11284.     12920.    4150   
#>  4 1 [Europe & C. Asia] safewater dbl      42    81.6       18.6     88.5 
#>  5 2 [North America]    popgrowth dbl      14     1.33       0.780    1.35
#>  6 2 [North America]    lexp      dbl      14    69.7        6.14    70.5 
#>  7 2 [North America]    gnppc     dbl      14  6294.      9080.    2680   
#>  8 2 [North America]    safewater dbl       6    58         24.0     46   
#>  9 3 [South America]    popgrowth dbl      10     1.59       0.489    1.8 
#> 10 3 [South America]    lexp      dbl      10    70.7        4.06    71.5 
#> 11 3 [South America]    gnppc     dbl      10  3881       2432.    2990   
#> 12 3 [South America]    safewater dbl       6    65.3       17.0     65   

# Remove rows missing a grouping key; measured NAs are always omitted
summ(lifeexp, .by = region, .missing = FALSE)
#> Warning: country is non-numeric and thus removed.
#> # A tibble: 12 × 9
#>    region               name     type      n unique   min    mean      sd    max
#>    <dbl+lbl>            <chr>    <chr> <int>  <int> <dbl>   <dbl>   <dbl>  <dbl>
#>  1 1 [Europe & C. Asia] popgrow… dbl      44     25  -2.5 7.05e-2 9.10e-1 1.8 e0
#>  2 1 [Europe & C. Asia] lexp     dbl      44     17  62   7.25e+1 4.95e+0 7.9 e1
#>  3 1 [Europe & C. Asia] gnppc    dbl      43     42 170   1.13e+4 1.29e+4 4.66e4
#>  4 1 [Europe & C. Asia] safewat… dbl      42     25  36   8.16e+1 1.86e+1 1   e2
#>  5 2 [North America]    popgrow… dbl      14     11   0.3 1.33e+0 7.80e-1 2.6 e0
#>  6 2 [North America]    lexp     dbl      14     13  57   6.97e+1 6.14e+0 7.9 e1
#>  7 2 [North America]    gnppc    dbl      14     14 410   6.29e+3 9.08e+3 3.20e4
#>  8 2 [North America]    safewat… dbl       6      5  40   5.8 e+1 2.40e+1 9.9 e1
#>  9 3 [South America]    popgrow… dbl      10      7   0.5 1.59e+0 4.89e-1 2.2 e0
#> 10 3 [South America]    lexp     dbl      10      8  61   7.07e+1 4.06e+0 7.6 e1
#> 11 3 [South America]    gnppc    dbl      10      9 960   3.88e+3 2.43e+3 7.96e3
#> 12 3 [South America]    safewat… dbl       6      6  45   6.53e+1 1.70e+1 9.1 e1

# Summarize existing and computed columns together
summ(lifeexp, lexp, gnppc_thousands = gnppc / 1000, .by = region)
#> # A tibble: 6 × 9
#>   region               name           type      n unique   min  mean    sd   max
#>   <dbl+lbl>            <chr>          <chr> <int>  <int> <dbl> <dbl> <dbl> <dbl>
#> 1 1 [Europe & C. Asia] lexp           dbl      44     17 62    72.5   4.95 79   
#> 2 1 [Europe & C. Asia] gnppc_thousan… dbl      43     42  0.17 11.3  12.9  46.6 
#> 3 2 [North America]    lexp           dbl      14     13 57    69.7   6.14 79   
#> 4 2 [North America]    gnppc_thousan… dbl      14     14  0.41  6.29  9.08 32.0 
#> 5 3 [South America]    lexp           dbl      10      8 61    70.7   4.06 76   
#> 6 3 [South America]    gnppc_thousan… dbl      10      9  0.96  3.88  2.43  7.96

tabstat(lifeexp, lexp, gnppc_thousands = gnppc / 1000)
#> # A tibble: 2 × 3
#>   name            type   mean
#>   <chr>           <chr> <dbl>
#> 1 lexp            dbl   71.7 
#> 2 gnppc_thousands dbl    9.14

# Keep numeric and calendar summaries in separate tables
mixed <- tibble::tibble(x = c(1, 3), day = as.Date("2024-01-01") + 0:1)
summ(mixed, .type = "list")
#> A list is returned as statistics are heterogeneous.
#> $numeric
#> # A tibble: 1 × 8
#>   name  type      n unique   min  mean    sd   max
#>   <chr> <chr> <int>  <int> <dbl> <dbl> <dbl> <dbl>
#> 1 x     dbl       2      2     1     2  1.41     3
#> 
#> $date
#> # A tibble: 1 × 8
#>   name  type      n unique mean       sd             min        max       
#>   <chr> <chr> <int>  <int> <chr>      <drtn>         <chr>      <chr>     
#> 1 day   date      2      2 2024-01-01 0.7071068 days 2024-01-01 2024-01-02
#> 

# Choose a stable variable name when starting from a vector
scores <- c(4, 6, NA, 8)
tibble::tibble(score = scores) |> summ(.name = TRUE)
#> # A tibble: 1 × 8
#>   name  type      n unique   min  mean    sd   max
#>   <chr> <chr> <int>  <int> <dbl> <dbl> <dbl> <dbl>
#> 1 score dbl       3      3     4     6     2     8
```
