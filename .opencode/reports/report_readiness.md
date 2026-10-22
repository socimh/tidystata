# Function: readiness()

**Version:** 0.3.0 | **Generated:** 2026-10-21 20:14:21 | **Status:** PASS

## Example 1: Calendar spreads as comparable difftime columns

```
# A tibble: 1 x 3
  type  sd             se
  <chr> <drtn>         <drtn>
1 date  0.7071068 days 0.5 days
```

## Example 2: Shared numeric/calendar table columns

```
# A tibble: 2 x 4
  name  type      n mean
  <chr> <chr> <int> <chr>
1 x     dbl       2 2
2 day   date      2 2024-01-01
A list is returned as statistics are heterogeneous.
$numeric
# A tibble: 1 x 3
  name  type   mean
  <chr> <chr> <dbl>
1 x     dbl       2

$date
# A tibble: 1 x 3
  name  type  mean
  <chr> <chr> <chr>
1 day   date  2024-01-01

```

## Example 3: Piped vector expression name and explicit-name workaround

```
# A tibble: 1 x 3
  name  type   mean
  <chr> <chr> <dbl>
1 1:3   int       2
# A tibble: 1 x 3
  name  type   mean
  <chr> <chr> <dbl>
1 value int       2
```

## Example 4: Infinite Date extrema

```
# A tibble: 1 x 5
  type      n miss_n min   max
  <chr> <int>  <int> <chr> <chr>
1 date      3      1 -Inf  Inf
```

## Example 5: Vector tabulation

```
# A tibble: 2 x 6
  value     n percent   cum valid valid_cum
  <dbl> <int>   <dbl> <dbl> <dbl>     <dbl>
1     1     2    66.7  66.7  66.7      66.7
2     2     1    33.3 100    33.3     100
# A tibble: 3 x 6
  value     n percent   cum valid valid_cum
  <chr> <int>   <dbl> <dbl> <dbl>     <dbl>
1 1         2    66.7  66.7  66.7      66.7
2 2         1    33.3 100    33.3     100
3 Total     3   100    NA    NA        NA
```

## Example 6: Namespace-qualified datasets

```
tidystata     dplyr
       87        87
[1] "package:dplyr"     "package:tidystata"
```

## Example 7: Missing argument diagnostic

```
[1] "Missing `value`. Use `na_if_value(x, value)` or `x |>\nna_if_value(value)`."
```

## Example 8: Grouped quantile cuts return integer codes

```
$a
[1] [1,2.5] [1,2.5] (2.5,4] (2.5,4]
Levels: [1,2.5] < (2.5,4]

$b
[1] [11,12.5] [11,12.5] (12.5,14] (12.5,14]
Levels: [11,12.5] < (12.5,14]

# A tibble: 8 x 3
# Groups:   g [2]
  g         x   bin
  <chr> <int> <int>
1 a         1     1
2 a         2     1
3 a         3     2
4 a         4     2
5 b        11     1
6 b        12     1
7 b        13     2
8 b        14     2
```

## Example 9: Nested timers measure their complete expressions

```
Time spent: 0.000s
Time spent: 0.004s
No duration threshold is asserted. Each timer measures its own expression.
```
