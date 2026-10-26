# Calculate panel lags, leads and differences

Time-aware versions of
[`dplyr::lag()`](https://dplyr.tidyverse.org/reference/lead-lag.html)
and
[`dplyr::lead()`](https://dplyr.tidyverse.org/reference/lead-lag.html),
following Stata's time-series operators after `xtset`. Values are found
by time rather than row position, so gaps give missing values and row
order does not matter. Use them in
[`dplyr::mutate()`](https://dplyr.tidyverse.org/reference/mutate.html)
with the panel identifier in `.by` or
[`dplyr::group_by()`](https://dplyr.tidyverse.org/reference/group_by.html).

- `stata_lag()`: Retrieve the value from `n` periods earlier.

- `stata_lead()`: Retrieve the value from `n` periods later.

- `stata_diff()`: Calculate the `n`th difference; the default first
  difference subtracts the previous period's value from the current
  value.

## Usage

``` r
stata_lag(x, n = 1L, time, delta = 1, unit = NULL)

stata_lead(x, n = 1L, time, delta = 1, unit = NULL)

stata_diff(x, n = 1L, time, delta = 1, unit = NULL)
```

## Arguments

- x:

  A vector. `stata_diff()` needs a numeric, logical, `Date`, date-time
  or `difftime` vector.

- n:

  A single non-negative whole number: the number of periods
  (`stata_lag()`, `stata_lead()`) or the difference order
  (`stata_diff()`).

- time:

  The time variable, unique within each panel. Supported types:

  - numbers, including labelled numbers and Stata `%tm`, `%tq` or `%ty`
    variables read by haven, which arrive as plain numbers;

  - `Date` and date-times (`POSIXct`/`POSIXlt`), with `unit`;

  - period classes, which need no `unit`: tsibble's `yearweek()`,
    `yearmonth()` and `yearquarter()`, and zoo's `yearmon` and
    `yearqtr`;

  - ordered factors, such as survey waves, where each level is one
    period in level order, so an unused level is a gap.

  Missing times give missing results, except for zero-order differences.
  Text and unordered factors are not accepted, because their sorted
  order need not be the time order (`"W10"` sorts before `"W2"`);
  convert them first, for example with `as.numeric(as.character(year))`
  or `factor(wave, levels, ordered = TRUE)`.

- delta:

  The length of one period in units of `time` (or of `unit`), like the
  `delta()` option of `xtset`. For example, `delta = 5` for data every
  five years.

- unit:

  For `Date` and date-time times, the period: `"day"` (the default for
  dates), `"week"`, `"month"`, `"quarter"` or `"year"`, and for
  date-times also `"second"` (their default), `"minute"` and `"hour"`.
  Times are compared by whole periods, as with Stata's `%tw`, `%tm`,
  `%tq` and `%ty` dates, so any day in March is one month after any day
  in February. Weeks follow Stata's `%tw`: each year has 52 weeks
  starting on 1 January, so the last week has 8 or 9 days (tsibble's
  `yearweek()` keeps its ISO weeks). For date-times, seconds measure
  elapsed time; minute and larger periods use the local clock of their
  time zone. Must be `NULL` for numbers and period classes.

## Value

A vector with the length and row order of `x`, with `NA` where the
required period is absent or time is missing. Lags and leads retain the
type and attributes of `x`. Positive-order differences return doubles,
or `difftime` for dates, date-times and `difftime` input.

With `stata_diff(n = 0)`, numeric/logical inputs return doubles and
calendar/duration inputs retain their class (`POSIXlt` becomes
`POSIXct`). Missing times do not mask values in this case.

## Details

- `stata_lag(x, n, time = t)` is `Ln.x`: the value at time
  `t - n * delta`.

- `stata_lead(x, n, time = t)` is `Fn.x`: the value at time
  `t + n * delta`.

- `stata_diff(x, n, time = t)` is `Dn.x`: the `n`th difference, so
  `stata_diff(x, time = t)` is `x - L.x` and
  `stata_diff(x, 2, time = t)` is `D.(D.x)`.

Compared with
[`dplyr::lag()`](https://dplyr.tidyverse.org/reference/lead-lag.html):
`lag(x, order_by = year)` takes the previous *row* after sorting, so
after a gap (2002, then 2004) it returns the 2002 value as the lag of
2004, and it silently accepts repeated years or a forgotten `.by`.
`stata_lag(x, time = year)` takes the value at `year - 1`, returns `NA`
across the gap, and errors on repeated times, as Stata's `L.x` does. The
two agree on sorted, gap-free panels. For irregular event sequences,
where the previous record is wanted however long ago it was, use
[`dplyr::lag()`](https://dplyr.tidyverse.org/reference/lead-lag.html).

Time values must be unique within each panel (within the whole vector
when there is no grouping), as Stata requires with "repeated time values
within panel"; check them first with
[`isid()`](https://socimh.github.io/tidystata/reference/keys.md), such
as `isid(data, id, year)`. Numeric times are matched exactly, so steps
such as `0.1` should be rescaled to whole numbers first.

## See also

Other variable generation functions:
[`as_dummy()`](https://socimh.github.io/tidystata/reference/as_dummy.md),
[`cut`](https://socimh.github.io/tidystata/reference/cut.md),
[`row_egen`](https://socimh.github.io/tidystata/reference/row_egen.md),
[`std()`](https://socimh.github.io/tidystata/reference/std.md)

## Examples

``` r
panel <- tibble::tibble(
  id = c(1, 1, 1, 2, 2),
  year = c(2001, 2002, 2004, 2001, 2002),
  x = c(10, 12, 15, 20, 21)
)
# 2004 has no 2003, so its lag is missing, unlike dplyr::lag()
dplyr::mutate(
  panel,
  lag_x = stata_lag(x, time = year),
  lead_x = stata_lead(x, time = year),
  d_x = stata_diff(x, time = year),
  .by = id
)
#> # A tibble: 5 x 6
#>      id  year     x lag_x lead_x   d_x
#>   <dbl> <dbl> <dbl> <dbl>  <dbl> <dbl>
#> 1     1  2001    10    NA     12    NA
#> 2     1  2002    12    10     NA     2
#> 3     1  2004    15    NA     NA    NA
#> 4     2  2001    20    NA     21    NA
#> 5     2  2002    21    20     NA     1

# Monthly data stored as dates
sales <- tibble::tibble(
  month = as.Date(c("2024-01-31", "2024-02-29", "2024-04-30")),
  amount = c(5, 7, 4)
)
dplyr::mutate(
  sales,
  previous = stata_lag(amount, time = month, unit = "month")
)
#> # A tibble: 3 x 3
#>   month      amount previous
#>   <date>      <dbl>    <dbl>
#> 1 2024-01-31      5       NA
#> 2 2024-02-29      7        5
#> 3 2024-04-30      4       NA
```
