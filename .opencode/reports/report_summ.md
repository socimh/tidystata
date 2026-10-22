# Function: summ()

**Version:** 0.3.0 | **Generated:** 2026-10-21 20:14:21 | **Status:** PASS

## Example 1: Basic numeric summary

```r
summ(mtcars, mpg)
```

**Output:**

```
  type  n unique  min     mean       sd  max
1  dbl 32     25 10.4 20.09062 6.026948 33.9
```

## Example 2: Multiple variables

```r
summ(mtcars, mpg, hp, wt)
```

**Output:**

```
  name type  n unique    min      mean         sd     max
1  mpg  dbl 32     25 10.400  20.09062  6.0269481  33.900
2   hp  dbl 32     22 52.000 146.68750 68.5628685 335.000
3   wt  dbl 32     29  1.513   3.21725  0.9784574   5.424
```

## Example 3: Grouped summary

```r
summ(mtcars, mpg, .by = cyl)
```

**Output:**

```
  cyl type  n unique  min     mean       sd  max
1   4  dbl 11      9 21.4 26.66364 4.509828 33.9
2   6  dbl  7      6 17.8 19.74286 1.453567 21.4
3   8  dbl 14     12 10.4 15.10000 2.560048 19.2
```

## Example 4: Custom statistics

```r
summ(mtcars, mpg, .stat = c('mean', 'sd'))
```

**Output:**

```
  type     mean       sd
1  dbl 20.09062 6.026948
```

## Example 5: Detailed statistics

```r
summ(mtcars, mpg, .detail = TRUE)
```

**Output:**

```
  type  n unique miss_n valid_pct  min     q1 median     mean     mad       sd
1  dbl 32     25      0         1 10.4 15.425   19.2 20.09062 5.41149 6.026948
    q3  max   iqr     skew  kurtosis       se   sum
1 22.8 33.9 7.375 0.610655 -0.372766 1.065424 642.9
```

## Example 6: Inf/-Inf handling

```r
summ(data.frame(x = c(1, 2, Inf, -Inf, 3)))
```

**Output:**

```
  type n unique  min mean  sd max
1  dbl 5      5 -Inf  NaN NaN Inf
```

## Example 7: With grouping and NA handling

```r
df <- data.frame(x = c(1, 2, 3, 4), g = c('a', 'a', NA, 'b'))
summ(df, .by = g, .missing = FALSE)
```

**Output:**

```
  g type n unique min mean        sd max
1 a  dbl 2      2   1  1.5 0.7071068   2
2 b  dbl 1      1   4  4.0        NA   4
```

## Example 8: All numeric variables

```r
summ(mtcars[, 1:4])
```

**Output:**

```
  name type  n unique  min      mean         sd   max
1  mpg  dbl 32     25 10.4  20.09062   6.026948  33.9
2  cyl  dbl 32      3  4.0   6.18750   1.785922   8.0
3 disp  dbl 32     27 71.1 230.72188 123.938694 472.0
4   hp  dbl 32     22 52.0 146.68750  68.562868 335.0
```

## Example 9: tabstat() wrapper

```r
tabstat(mtcars, .by = cyl)
```

**Output:**

```
   cyl name type        mean
1    4  mpg  dbl  26.6636364
2    4 disp  dbl 105.1363636
3    4   hp  dbl  82.6363636
4    4 drat  dbl   4.0709091
5    4   wt  dbl   2.2857273
6    4 qsec  dbl  19.1372727
7    4   vs  dbl   0.9090909
8    4   am  dbl   0.7272727
9    4 gear  dbl   4.0909091
10   4 carb  dbl   1.5454545
11   6  mpg  dbl  19.7428571
12   6 disp  dbl 183.3142857
13   6   hp  dbl 122.2857143
14   6 drat  dbl   3.5857143
15   6   wt  dbl   3.1171429
16   6 qsec  dbl  17.9771429
17   6   vs  dbl   0.5714286
18   6   am  dbl   0.4285714
19   6 gear  dbl   3.8571429
20   6 carb  dbl   3.4285714
21   8  mpg  dbl  15.1000000
22   8 disp  dbl 353.1000000
23   8   hp  dbl 209.2142857
24   8 drat  dbl   3.2292857
25   8   wt  dbl   3.9992143
26   8 qsec  dbl  16.7721429
27   8   vs  dbl   0.0000000
28   8   am  dbl   0.1428571
29   8 gear  dbl   3.2857143
30   8 carb  dbl   3.5000000
```

## Example 10: Zero-variance column

```r
summ(data.frame(x = rep(5, 10)))
```

**Output:**

```
  type  n unique min mean sd max
1  dbl 10      1   5    5  0   5
```

