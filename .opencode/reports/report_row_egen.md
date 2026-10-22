# Function: row_egen()

**Version:** 0.3.0 | **Generated:** 2026-10-21 20:42:09 | **Status:** PASS

## Example 1: row_min

```r
df <- tibble(a = c(1, 2, 3), b = c(3, 2, 1), c = c(2, 3, 1))
row_min(df)
```

**Output:**

```
[1] 1 2 1
```

## Example 2: row_max

```r
row_max(df)
```

**Output:**

```
[1] 3 3 3
```

## Example 3: row_mean

```r
row_mean(df)
```

**Output:**

```
[1] 2.000000 2.333333 1.666667
```

## Example 4: row_sum

```r
row_sum(df)
```

**Output:**

```
[1] 6 7 5
```

## Example 5: row_miss (count NA per row)

```r
df_na <- tibble(a = c(1, NA, 3), b = c(NA, 2, 1), c = c(2, 3, NA))
row_miss(df_na)
```

**Output:**

```
[1] 1 1 1
```

## Example 6: row_non_miss (count non-NA per row)

```r
row_non_miss(df_na)
```

**Output:**

```
[1] 2 2 2
```

## Example 7: In mutate context

```r
df |>
  mutate(
    min_val = row_min(a, b, c),
    max_val = row_max(a, b, c)
  )
```

**Output:**

```
# A tibble: 3 x 5
      a     b     c min_val max_val
  <dbl> <dbl> <dbl>   <dbl>   <dbl>
1     1     3     2       1       3
2     2     2     3       2       3
3     3     1     1       1       3
```

## Example 8: With scalar values

```r
df |>
  mutate(above_2 = row_min(a, 2))
```

**Output:**

```
# A tibble: 3 x 4
      a     b     c above_2
  <dbl> <dbl> <dbl>   <dbl>
1     1     3     2       1
2     2     2     3       2
3     3     1     1       2
```

## Example 9: Logical extrema retain TRUE/FALSE

```r
flags <- tibble(a = c(TRUE, FALSE, NA), b = c(FALSE, NA, NA))
row_max(flags)
row_min(flags)
typeof(row_max(flags))
```

**Output:**

```
[1]  TRUE FALSE    NA
[1] FALSE FALSE    NA
[1] "logical"
```

## Example 10: Calendar summaries preserve dates

```r
dates <- tibble(a = as.Date(c('2024-01-01', NA)),
                b = as.Date(c('2024-01-03', '2024-01-05')))
row_max(dates)
row_mean(dates)
```

**Output:**

```
[1] "2024-01-03" "2024-01-05"
[1] "2024-01-02" "2024-01-05"
```

## Example 11: Stable C++ sample dispersion

```r
large <- tibble(a = c(1e12, 1e200), b = c(1e12 + 1, 1e200))
row_var(large)
row_sd(large)
```

**Output:**

```
[1] 0.5 0.0
[1] 0.7071068 0.0000000
```

