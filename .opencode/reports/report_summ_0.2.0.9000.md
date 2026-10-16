# Function: summ()

**Version:** 0.2.0.9000 | **Generated:** 2026-10-16 18:04:57 | **Status:** PASS

## Example 1: Basic numeric summary

```r
summ(mtcars, mpg)
```

**Output:**

```
# A tibble: 1 x 8
  name  type      n unique   min  mean    sd   max
  <chr> <chr> <int>  <int> <dbl> <dbl> <dbl> <dbl>
1 mpg   dbl      32     25  10.4  20.1  6.03  33.9
```

## Example 2: Multiple variables

```r
summ(mtcars, mpg, hp, wt)
```

**Output:**

```
# A tibble: 3 x 8
  name  type      n unique   min   mean     sd    max
  <chr> <chr> <int>  <int> <dbl>  <dbl>  <dbl>  <dbl>
1 mpg   dbl      32     25 10.4   20.1   6.03   33.9
2 hp    dbl      32     22 52    147.   68.6   335
3 wt    dbl      32     29  1.51   3.22  0.978   5.42
```

## Example 3: Grouped summary

```r
summ(mtcars, mpg, .by = cyl)
```

**Output:**

```
# A tibble: 3 x 9
    cyl name  type      n unique   min  mean    sd   max
  <dbl> <chr> <chr> <int>  <int> <dbl> <dbl> <dbl> <dbl>
1     6 mpg   dbl       7      6  17.8  19.7  1.45  21.4
2     4 mpg   dbl      11      9  21.4  26.7  4.51  33.9
3     8 mpg   dbl      14     12  10.4  15.1  2.56  19.2
```

## Example 4: Custom statistics

```r
summ(mtcars, mpg, .stat = c('mean', 'sd'))
```

**Output:**

```
# A tibble: 1 x 4
  name  type   mean    sd
  <chr> <chr> <dbl> <dbl>
1 mpg   dbl    20.1  6.03
```

## Example 5: Detailed statistics

```r
summ(mtcars, mpg, .detail = TRUE)
```

**Output:**

```
# A tibble: 1 x 19
  name  type      n unique miss_n valid_pct   min    q1 median  mean   mad    sd
  <chr> <chr> <int>  <int>  <int>     <dbl> <dbl> <dbl>  <dbl> <dbl> <dbl> <dbl>
1 mpg   dbl      32     25      0         1  10.4  15.4   19.2  20.1  5.41  6.03
# i 7 more variables: q3 <dbl>, max <dbl>, iqr <dbl>, skew <dbl>,
#   kurtosis <dbl>, se <dbl>, sum <dbl>
```

## Example 6: Inf/-Inf handling

```r
summ(data.frame(x = c(1, 2, Inf, -Inf, 3)))
```

**Output:**

```
# A tibble: 1 x 8
  name  type      n unique   min  mean    sd   max
  <chr> <chr> <int>  <int> <dbl> <dbl> <dbl> <dbl>
1 x     dbl       5      5  -Inf   NaN   NaN   Inf
```

## Example 7: With grouping and NA handling

```r
df <- data.frame(x = c(1, 2, 3, 4), g = c('a', 'a', NA, 'b'))
summ(df, .by = g, .na.rm = TRUE)
```

**Output:**

```
# A tibble: 2 x 9
  g     name  type      n unique   min  mean     sd   max
  <chr> <chr> <chr> <int>  <int> <dbl> <dbl>  <dbl> <dbl>
1 a     x     dbl       2      2     1   1.5  0.707     2
2 b     x     dbl       1      1     4   4   NA         4
```

## Example 8: All numeric variables

```r
summ(mtcars[, 1:4])
```

**Output:**

```
# A tibble: 4 x 8
  name  type      n unique   min   mean     sd   max
  <chr> <chr> <int>  <int> <dbl>  <dbl>  <dbl> <dbl>
1 mpg   dbl      32     25  10.4  20.1    6.03  33.9
2 cyl   dbl      32      3   4     6.19   1.79   8
3 disp  dbl      32     27  71.1 231.   124.   472
4 hp    dbl      32     22  52   147.    68.6  335
```

## Example 9: tabstat() wrapper

```r
tabstat(mtcars, .by = cyl)
```

**Output:**

```
# A tibble: 30 x 4
     cyl name  type     mean
   <dbl> <chr> <chr>   <dbl>
 1     6 mpg   dbl    19.7
 2     6 disp  dbl   183.
 3     6 hp    dbl   122.
 4     6 drat  dbl     3.59
 5     6 wt    dbl     3.12
 6     6 qsec  dbl    18.0
 7     6 vs    dbl     0.571
 8     6 am    dbl     0.429
 9     6 gear  dbl     3.86
10     6 carb  dbl     3.43
# i 20 more rows
```

## Example 10: Zero-variance column

```r
summ(data.frame(x = rep(5, 10)))
```

**Output:**

```
# A tibble: 1 x 8
  name  type      n unique   min  mean    sd   max
  <chr> <chr> <int>  <int> <dbl> <dbl> <dbl> <dbl>
1 x     dbl      10      1     5     5     0     5
```

