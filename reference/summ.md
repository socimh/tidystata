# Summary statistics

Summarise selected variables, with one row per variable and group:

- `summ()`: Report counts, distinct-value counts, minimum, mean,
  standard deviation, and maximum by default.

- `tabstat()`: Report means by default, using the same calculations and
  options as `summ()`.

Both support `.detail = TRUE` for a fuller summary or `.stat` to select
statistics.

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
  .type = c("list", "table", "tibble"),
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
  .type = c("list", "table", "tibble"),
  .duration_format = c("long", "compact"),
  .sort = TRUE,
  .drop_empty = FALSE,
  .wt = NULL,
  .wt_type = c("frequency", "analytic")
)
```

## Arguments

- .data:

  A data frame, tibble, data.table, or vector. For `sf` data, only
  attributes are summarised; geometry columns are excluded.

- ...:

  \<[`tidy-select`](https://dplyr.tidyverse.org/reference/dplyr_tidy_select.html)\>
  or
  \<[`data-masking`](https://rlang.r-lib.org/reference/args_data_masking.html)\>
  Variables to summarise, or named expressions such as
  `income_k = income / 1000`. Defaults to all nongrouping columns except
  the weight column. Matrix and nested data-frame columns are not
  supported.

- .by:

  \<[`tidy-select`](https://dplyr.tidyverse.org/reference/dplyr_tidy_select.html)\>
  Optional grouping columns. Existing
  [`dplyr::group_by()`](https://dplyr.tidyverse.org/reference/group_by.html)
  groups are used unless `.by` is supplied. Grouping columns are
  excluded from the variables being summarised.

- .keep_all:

  If `TRUE`, retain character and list columns for counts and distinct
  values; other statistics for these columns are `NA`. By default,
  unsupported columns are omitted with a message.

- .detail:

  If `TRUE`, report all supported statistics unless `.stat` is supplied
  explicitly. Defaults to `FALSE`.

- .stat:

  Character vector of statistics to report. See Details for the complete
  list and calculation methods. An explicit selection determines the
  statistics and their order. Use `p0` to `p100` for percentiles,
  including decimals such as `p2.5`.

- .missing:

  If `TRUE` (default), retain observations with missing grouping keys as
  a separate group. If `FALSE`, exclude them. Missing measured values
  are always omitted from numeric calculations.

- .name:

  If `TRUE`, always include the `name` column. By default, it is omitted
  when exactly one variable is summarised.

- .type:

  Output form. `"list"` (default) returns separate tables when multiple
  variable families are present, or a single table for one family.
  `"table"` combines all families into one table, retaining the input's
  table class where supported. `"tibble"` combines them into one tibble
  regardless of the input's table class or preview settings.

- .duration_format:

  Retained for compatibility; no longer changes the output format of
  calendar spread statistics.

- .sort:

  If `TRUE` (default), sort groups by their keys. If `FALSE`, preserve
  the order in which groups appear in the data.

- .drop_empty:

  If `TRUE`, omit variable-group rows with `n = 0`, including rows with
  no observed measured values or zero total weight. Defaults to `FALSE`.

- .wt:

  Optional finite, nonnegative numeric weights, supplied as a column,
  one value per input row, or a scalar recycled to all rows. Rows with
  missing weights are excluded with a message.

- .wt_type:

  `"frequency"` (default) treats weights as frequencies; `"analytic"`
  rescales weights to the number of observed values within each variable
  and group. See Details for the calculation differences.

## Value

An ungrouped table, or a list of tables, with one row per variable and
group. Each table contains grouping keys (if any), `name` (when
applicable), `type`, and the selected statistics.

By default, `summ()` returns `n`, `unique`, `min`, `mean`, `sd`, and
`max`; `tabstat()` returns `mean`. With `.type = "list"`, results are
split into `numeric`, `date`, `datetime`, and `time` tables only when
multiple type families occur. With `.type = "table"` or `"tibble"`, all
types are combined in one table. Results retain the input's usual table
class where supported, except that `.type = "tibble"` always returns a
tibble.

## Details

Statistics are calculated separately for each selected variable and
group. The formulas below use non-missing measured values `x1, ..., xn`,
with `n` denoting their count and `xbar` their arithmetic mean. Unless
weights are supplied, calculations are unweighted.

**Counts and completeness**

- `type`: Variable type (metadata, not a calculated statistic).

- `n`: Number of non-missing values.

- `unique`: Number of distinct non-missing values.

- `miss_n`: Number of missing values (alias: `missing`).

- `valid_pct`: Proportion of rows with a non-missing value, between 0
  and 1; `n / (n + miss_n)` without weights. It is **not** multiplied by
  100.

**Location and totals**

- `min`, `max`: Smallest and largest observed values.

- `sum`: Arithmetic total, `sum(x)`. Available for numeric variables
  only.

- `mean`: Arithmetic mean, `sum(x) / n`.

- `q1` (`p25`), `median` (`p50`), `q3` (`p75`): 25th, 50th, and 75th
  percentiles, respectively.

- `p0` to `p100`: Any requested percentile, including decimal
  percentages such as `p2.5`. Percentiles follow **Stata's rule**, not
  R's default
  [`stats::quantile()`](https://rdrr.io/r/stats/quantile.html) type 7.
  For sorted observations and percentile `p`, set `h = n * p / 100`. If
  `h` is not an integer, use the observation at position `ceiling(h)`;
  if `h` is an integer between 1 and `n - 1`, average the observations
  at positions `h` and `h + 1`. The endpoints are the minimum (`p0`) and
  maximum (`p100`). For example, the 25th percentile of `1:4` is 1.5,
  rather than 1.75 from type 7.

**Variation and precision**

- `sd`: Sample standard deviation, `sqrt(sum((x - xbar)^2) / (n - 1))`.

- `se`: Standard error of the mean, `sd / sqrt(n)`.

- `mad`: Median absolute deviation from the median, multiplied by
  1.4826, as in [`stats::mad()`](https://rdrr.io/r/stats/mad.html). This
  is not a statistic reported by Stata's `summarize` command.

- `iqr`: Interquartile range, `q3 - q1`, using the percentiles above.

**Distribution shape**

Define `mk = sum((x - xbar)^k) / n`, the `k`th population central
moment.

- `skew`: Skewness, `m3 / m2^(3/2)`.

- `kurtosis`: Pearson kurtosis, `m4 / m2^2`. A normal distribution has
  kurtosis 3, not 0 (this is not excess kurtosis).

Undefined statistics are `NA` (for example, `sd` when `n < 2` and the
shape statistics for constant variables). Columns with no observed
values have `n = 0`, `unique = 0`, and `NA` for numeric statistics,
including `sum`.

**When weights are supplied**

Let `w` be the weights and `W = sum(w)` over non-missing measured
values.

- **Frequency weights** (`.wt_type = "frequency"`) use weights as given.
  The reported `n` is `W`; non-integer weights are permitted.

- **Analytic weights** (`.wt_type = "analytic"`) are rescaled within
  each variable and group so that `W` equals the number of observed
  values. Thus `n` remains on the sample-count scale.

- **Mean and spread:** `mean = sum(w * x) / W`,
  `sd = sqrt(sum(w * (x - mean)^2) / (W - 1))`, and `se = sd / sqrt(W)`.
  The two weight types give the same mean but can give different `sd`
  and `se` values. Both are `NA` when `W <= 1`.

- **Shape:** Skewness and kurtosis use weighted population central
  moments, `mk = sum(w * (x - mean)^k) / W`. They remain defined for
  `W > 0` when the population spread is nonzero, including fractional
  `W <= 1`.

- **Quantiles and MAD:** Percentiles use Stata's weighted percentile
  rule, replacing positions with cumulative weights; weighted `mad` uses
  the corresponding weighted medians. `min` and `max` exclude
  zero-weight rows.

- **Totals and counts:** `sum` is `sum(w * x)` using the *original*,
  unrescaled weights, even for analytic weights. `unique`, `miss_n`, and
  `valid_pct` continue to use unweighted row counts.

The reported `se` is descriptive and does not account for a complex
survey design. For survey inference, use functions such as
`survey::svymean()`.

**Data types and grouping**

Missingness follows [`is.na()`](https://rdrr.io/r/base/NA.html),
including SPSS user-missing codes. Logical variables are treated as 0/1;
factors use their underlying numeric codes; labelled numeric variables
use their stored values. Messages note such conversions. Variable names
are marked with `*` for labelled variables, `**` for factors, and `***`
for retained nonnumeric variables. Numeric calculations use double
precision, which may affect large `integer64` values.

Dates and datetimes support location and spread statistics, but not
`sum`, `skew`, or `kurtosis`. Calendar locations are displayed as dates
or times; their spreads (`sd`, `se`, `mad`, `iqr`) are `difftime` values
in list mode. With `.type = "table"` or `"tibble"`, calendar locations
are text and spreads are numeric durations (days for Dates, seconds for
datetimes and times of day).

Expressions in `...` are evaluated on ungrouped working data before
statistics are calculated by group. For group-specific expressions,
first create columns with grouped
[`dplyr::mutate()`](https://dplyr.tidyverse.org/reference/mutate.html).

## Examples

``` r
summ(lifeexp)
#> country is non-numeric and thus removed.
#> region is a labelled variable (*).
#> # A tibble: 5 × 8
#>   name      type        n unique   min     mean        sd     max
#>   <chr>     <chr>   <int>  <int> <dbl>    <dbl>     <dbl>   <dbl>
#> 1 *region   dbl+lbl    68      3   1      1.5       0.743     3  
#> 2 popgrowth dbl        68     32  -2.5    0.553     1.06      2.6
#> 3 lexp      dbl        68     20  57     71.7       5.16     79  
#> 4 gnppc     dbl        67     64 170   9137.    11497.    46650  
#> 5 safewater dbl        54     32  36     77.2      20.6     100  

summ(lifeexp, .by = region)
#> country is non-numeric and thus removed.
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
#> country is non-numeric and thus removed.
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

# Compare frequency and analytic weights
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

# Exclude rows with missing group keys
summ(lifeexp, .by = region, .missing = FALSE)
#> country is non-numeric and thus removed.
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

# Summarise existing and computed columns together
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

# Separate numeric and calendar summaries
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

# Combine numeric and calendar summaries in one tibble
summ(mixed, .type = "tibble")
#> # A tibble: 2 × 8
#>   name  type            n unique min        mean          sd max       
#>   <chr> <chr>       <int>  <int> <chr>      <chr>      <dbl> <chr>     
#> 1 x     dbl             2      2 1          2          1.41  3         
#> 2 day   date [days]     2      2 2024-01-01 2024-01-01 0.707 2024-01-02

# Preserve a variable name when starting from a vector
scores <- c(4, 6, NA, 8)
tibble::tibble(score = scores) |> summ(.name = TRUE)
#> # A tibble: 1 × 8
#>   name  type      n unique   min  mean    sd   max
#>   <chr> <chr> <int>  <int> <dbl> <dbl> <dbl> <dbl>
#> 1 score dbl       3      3     4     6     2     8
```
