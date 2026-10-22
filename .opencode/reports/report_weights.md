# Function: weights()

**Version:** 0.3.0 | **Generated:** 2026-10-21 20:14:22 | **Status:** PASS

## Example 1: frequency weights count each row w times

```
# A tibble: 2 x 6
  edu       n percent   cum valid valid_cum
  <chr> <dbl>   <dbl> <dbl> <dbl>     <dbl>
1 high      4    44.4  44.4  44.4      44.4
2 low       5    55.6 100    55.6     100
```

## Example 2: analytic weights keep the sample scale

```
# A tibble: 4 x 7
  region edu       n percent   cum valid valid_cum
  <chr>  <chr> <dbl>   <dbl> <dbl> <dbl>     <dbl>
1 north  high    1.2      40    40    40        40
2 north  low     1.8      60   100    60       100
3 south  high    1        50    50    50        50
4 south  low     1        50   100    50       100
```

## Example 3: weighted cross-tabulation with totals

```
# A tibble: 3 x 4
  `region \\ edu`  high   low total
  <chr>           <dbl> <dbl> <dbl>
1 north               2     3     5
2 south               2     2     4
3 total               4     5     9
```

## Example 4: weighted summaries

```
# A tibble: 2 x 6
  region type      n  mean    sd   p50
  <chr>  <chr> <dbl> <dbl> <dbl> <dbl>
1 north  dbl       5  18   13.0   10
2 south  dbl       4   6.5  1.73   6.5
# A tibble: 1 x 5
  type      n  mean    sd   p50
  <chr> <dbl> <dbl> <dbl> <dbl>
1 dbl       5  12.9  11.7    10
```

## Example 5: weighted quantile groups

```
[1] [5,10]  (10,40] (10,40] [5,10]  [5,10]
Levels: [5,10] < (10,40]
```

## Example 6: analytic weights keep their scale safely

```
# A tibble: 2 x 6
  edu       n percent   cum valid valid_cum
  <chr> <dbl>   <dbl> <dbl> <dbl>     <dbl>
1 high      2    66.7  66.7  66.7      66.7
2 low       1    33.3 100    33.3     100
```
