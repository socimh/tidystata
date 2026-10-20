# Function: panel()

**Version:** 0.2.0.9000 | **Generated:** 2026-10-19 21:18:21 | **Status:** PASS

## Example 1: lags follow time, not row order

```
# A tibble: 7 x 6
     id  year     x lag_x lead_x   d_x
  <dbl> <dbl> <dbl> <dbl>  <dbl> <dbl>
1     1  2001    10    NA     12    NA
2     1  2002    12    10     NA     2
3     1  2004    15    NA     18    NA
4     1  2005    18    15     NA     3
5     2  2001    31    NA     32    NA
6     2  2002    32    31     33     1
7     2  2003    33    32     NA     1
```

## Example 2: dplyr::lag() shifts rows across the gap

```
# A tibble: 7 x 5
     id  year     x row_lag time_lag
  <dbl> <dbl> <dbl>   <dbl>    <dbl>
1     1  2001    10      NA       NA
2     1  2002    12      10       10
3     1  2004    15      12       NA
4     1  2005    18      15       15
5     2  2001    31      NA       NA
6     2  2002    32      31       31
7     2  2003    33      32       32
```

## Example 3: monthly dates compare whole months

```
# A tibble: 3 x 3
  month      amount previous
  <date>      <dbl>    <dbl>
1 2024-01-31      5       NA
2 2024-02-29      7        5
3 2024-04-30      4       NA
```
