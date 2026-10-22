# Function: cut()

**Version:** 0.3.0 | **Generated:** 2026-10-21 00:58:08 | **Status:** PASS

## Example 1: Quartiles

```r
x <- 1:100
xtile(x, n = 4)
table(xtile(x, n = 4))
```

**Output:**

```

   [1,25.8] (25.8,50.5] (50.5,75.2]  (75.2,100]
         25          25          25          25
```

## Example 2: Deciles

```r
x <- rnorm(1000)
table(xtile(x, n = 10))
```

**Output:**

```

  [-3.09,-1.26]  (-1.26,-0.868] (-0.868,-0.579]  (-0.579,-0.29] (-0.29,-0.0617]
            100             100             100             100             100
(-0.0617,0.188]   (0.188,0.496]   (0.496,0.814]    (0.814,1.23]     (1.23,2.75]
            100             100             100             100             100
```

## Example 3: With ties

```r
x <- c(rep(1, 40), rep(2, 60))
table(xtile(x, n = 2))
```

**Output:**

```
Warning: Tied values collapsed quantile cutpoints to 1 groups (requested 2).

[1,2]
  100
```

## Example 4: With NA values

```r
x <- c(1:98, NA, NA)
table(xtile(x, n = 4), useNA = 'ifany')
```

**Output:**

```

   [1,25.2] (25.2,49.5] (49.5,73.8]   (73.8,98]        <NA>
         25          24          24          25           2
```

## Example 5: Custom labels

```r
x <- 1:12
xtile(x, n = 3, labels = c('low', 'mid', 'high'))
```

**Output:**

```
 [1] low  low  low  low  mid  mid  mid  mid  high high high high
Levels: low < mid < high
```

## Example 6: cut_length() for equal-width bins

```r
x <- 1:20
table(cut_length(x, n = 4))
```

**Output:**

```

   [1,5.75] (5.75,10.5] (10.5,15.2]   (15.2,20]
          5           5           5           5
```

## Example 7: cut_breaks() for custom breaks

```r
x <- 1:20
cut_breaks(x, breaks = c(5, 15))
```

**Output:**

```

  [1,5]  (5,15] (15,20]
      5      10       5
```

