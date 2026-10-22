# Historical problems: repaired examples

**Version:** 0.3.0 | **Generated:** 2026-10-21 20:42:09 | **Status:** PASS

## Example 1: Blank cross-tab categories remain distinct

```
# A tibble: 2 x 4
  `x \\ y` `<empty>` `<empty>1`     z
  <chr>        <int>      <int> <int>
1 a                1          1     0
2 b                0          0     1
```

## Example 2: Different ordered factors combine

```
# A tibble: 4 x 7
  variable value     n percent   cum valid valid_cum
  <chr>    <chr> <int>   <dbl> <dbl> <dbl>     <dbl>
1 a        a         1      50    50    50        50
2 a        b         1      50   100    50       100
3 b        x         1      50    50    50        50
4 b        y         1      50   100    50       100
```

## Example 3: Row missingness and explicit constants

```
# A tibble: 3 x 5
      a     b observed_sum complete_sum capped
  <dbl> <dbl>        <dbl>        <dbl>  <dbl>
1     1    NA            1           NA      1
2    NA     2            2           NA     NA
3    12     4           16           16      5
```

## Example 4: Summary controls and arbitrary percentiles

```
# A tibble: 2 x 8
  g     type      n unique   min  mean    sd   max
  <fct> <chr> <int>  <int> <dbl> <dbl> <dbl> <dbl>
1 low   dbl       2      2     1     2  1.41     3
2 high  dbl       1      1    10    10 NA       10
# A tibble: 1 x 4
  type   mean  p2.5 p97.5
  <chr> <dbl> <dbl> <dbl>
1 dbl    4.67   1.1  9.65
# A tibble: 4 x 7
  g         x     n percent   cum valid valid_cum
  <fct> <dbl> <int>   <dbl> <dbl> <dbl>     <dbl>
1 low       1     1      50    50    50        50
2 low       3     1      50   100    50       100
3 high     10     1     100   100   100       100
4 <NA>     NA     1     100   100    NA        NA
```

## Example 5: Balanced bins explicitly permit split ties

```
   value bin
1      0   1
2      0   1
3      0   2
4      0   2
5      0   3
6      0   3
7      0   4
8      0   4
9      0   5
10     1   5
rank_bins
1 2 3 4 5
2 2 2 2 2
```

## Example 6: Vectors and reusable name inventories

```
# A tibble: 2 x 6
  value     n percent   cum valid valid_cum
  <dbl> <int>   <dbl> <dbl> <dbl>     <dbl>
1     1     2    66.7  66.7  66.7      66.7
2     2     1    33.3 100    33.3     100
[1] "a"
```

## Example 7: Failed expressions retain the true error

```
Failed execution. Time spent: 0.000s
[1] "original fitting error"
```

## Example 8: Labelled replacements have explicit representations

```
<labelled<double>[3]>
[1] 1 2 1

Labels:
 value label
     1   Yes
     2    No
[1] Yes No  Yes
Levels: Yes No
```

## Example 9: Spatial aggregation ignores geometries

```
  x n  percent       cum    valid valid_cum
1 1 2 66.66667  66.66667 66.66667  66.66667
2 2 1 33.33333 100.00000 33.33333 100.00000
  type n unique min     mean        sd max
1  dbl 3      2   1 1.333333 0.5773503   2
```

## Example 10: Logical axes have consistent category order

```
# A tibble: 3 x 4
  `a \\ b` `FALSE` `TRUE`  `NA`
  <lgl>      <int>  <int> <int>
1 FALSE          0      1     0
2 TRUE           1      0     0
3 NA             0      0     1
```

## Example 11: Missing replacement arguments explain the call

```
[1] "Missing `value`. Use `value_if_na(x, value)` or `x |>\nvalue_if_na(value)`."
```

## Example 12: Constants cap values like pmin()

```
# A tibble: 3 x 3
     id   pct capped
  <int> <dbl>  <dbl>
1     1   0.2    0.2
2     2   0.7    0.5
3     3  NA     NA
```

## Example 13: Summaries sort groups and compute named constants

```
# A tibble: 4 x 8
  edu    type      n unique   min  mean    sd   max
  <fct>  <chr> <int>  <int> <dbl> <dbl> <dbl> <dbl>
1 low    dbl       1      1     7     7    NA     7
2 middle dbl       1      1     8     8    NA     8
3 high   dbl       1      1     5     5    NA     5
4 <NA>   dbl       1      1     6     6    NA     6
# A tibble: 2 x 8
   girl type      n unique   min  mean    sd   max
  <dbl> <chr> <int>  <int> <dbl> <dbl> <dbl> <dbl>
1     0 dbl       2      1     1     1     0     1
2     1 dbl       2      1     1     1     0     1
```

## Example 14: Quantile cuts keep a dummy in two groups

```

[0,0] (0,1]
    7     3
```
