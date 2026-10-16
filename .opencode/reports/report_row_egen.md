# Function: row_egen()

**Generated:** 2026-03-03 23:09:16

---

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
[1] 3 3 1
```

## Example 3: row_mean

```r
row_mean(df)
```

**Output:**

```
[1] 2.666667 2.666667 1.000000
```

## Example 4: row_sum

```r
row_sum(df)
```

**Output:**

```
[1] 8 8 3
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
df %>%
  mutate(
    min_val = row_min(a, b, c),
    max_val = row_max(a, b, c)
  )
```

**Output:**

```
# A tibble: 3 × 5
      a     b     c min_val max_val
  <dbl> <dbl> <dbl>   <dbl>   <dbl>
1     3     3     2       3       3
2     3     2     3       3       3
3     1     1     1       1       1
```

## Example 8: With scalar values

```r
df %>%
  mutate(above_2 = row_min(a, 2))
```

**Output:**

```
# A tibble: 3 × 4
      a     b     c above_2
  <dbl> <dbl> <dbl>   <dbl>
1     3     3     2       3
2     2     2     3       2
3     1     1     1       1
```


