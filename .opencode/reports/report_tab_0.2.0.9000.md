# Function: tab()

**Version:** 0.2.0.9000 | **Generated:** 2026-10-16 21:08:34 | **Status:** PASS

## Example 1: Basic frequency table

```r
tab(mtcars, cyl)
```

**Output:**

```
# A tibble: 3 x 6
    cyl     n percent   cum valid valid_cum
  <dbl> <int>   <dbl> <dbl> <dbl>     <dbl>
1     4    11    34.4  34.4  34.4      34.4
2     6     7    21.9  56.2  21.9      56.2
3     8    14    43.8 100    43.8     100
```

## Example 2: With percentages

```r
tab(mtcars, cyl)
```

**Output:**

```
# A tibble: 3 x 6
    cyl     n percent   cum valid valid_cum
  <dbl> <int>   <dbl> <dbl> <dbl>     <dbl>
1     4    11    34.4  34.4  34.4      34.4
2     6     7    21.9  56.2  21.9      56.2
3     8    14    43.8 100    43.8     100
```

## Example 3: Sorted by frequency (descending)

```r
tab(mtcars, cyl, .desc = TRUE)
```

**Output:**

```
# A tibble: 3 x 6
    cyl     n percent   cum valid valid_cum
  <dbl> <int>   <dbl> <dbl> <dbl>     <dbl>
1     8    14    43.8  43.8  43.8      43.8
2     4    11    34.4  78.1  34.4      78.1
3     6     7    21.9 100    21.9     100
```

## Example 4: With grouping

```r
df <- data.frame(x = c('a', 'b', NA, 'a', 'b', NA), g = c('x', 'x', 'x', 'y', 'y', 'y'))
tab(df, x, .by = g)
```

**Output:**

```
# A tibble: 6 x 7
  g     x         n percent   cum valid valid_cum
  <chr> <chr> <int>   <dbl> <dbl> <dbl>     <dbl>
1 x     a         1    33.3  33.3    50        50
2 x     b         1    33.3  66.7    50       100
3 x     <NA>      1    33.3 100      NA        NA
4 y     a         1    33.3  33.3    50        50
5 y     b         1    33.3  66.7    50       100
6 y     <NA>      1    33.3 100      NA        NA
```

## Example 5: With starwars data

```r
tab(starwars, sex)
```

**Output:**

```
# A tibble: 5 x 6
  sex                n percent   cum valid valid_cum
  <chr>          <int>   <dbl> <dbl> <dbl>     <dbl>
1 female            16   18.4   18.4 19.3       19.3
2 hermaphroditic     1    1.15  19.5  1.20      20.5
3 male              60   69.0   88.5 72.3       92.8
4 none               6    6.90  95.4  7.23     100
5 <NA>               4    4.60 100   NA         NA
```

## Example 6: Multiple variables

```r
tab(starwars, sex, gender)
```

**Output:**

```
# A tibble: 6 x 7
  sex            gender        n percent   cum valid valid_cum
  <chr>          <chr>     <int>   <dbl> <dbl> <dbl>     <dbl>
1 female         feminine     16   18.4   18.4 19.3       19.3
2 hermaphroditic masculine     1    1.15  19.5  1.20      20.5
3 male           masculine    60   69.0   88.5 72.3       92.8
4 none           feminine      1    1.15  89.7  1.20      94.0
5 none           masculine     5    5.75  95.4  6.02     100
6 <NA>           <NA>          4    4.60 100   NA         NA
```

## Example 7: With boolean expression

```r
tab(starwars, tall = height > 180)
```

**Output:**

```
# A tibble: 3 x 6
  tall      n percent   cum valid valid_cum
  <lgl> <int>   <dbl> <dbl> <dbl>     <dbl>
1 FALSE    42   48.3   48.3  51.9      51.9
2 TRUE     39   44.8   93.1  48.1     100
3 NA        6    6.90 100    NA        NA
```

## Example 8: Cross-tabulation (tab2)

```r
tab2(starwars, sex, gender)
```

**Output:**

```
# A tibble: 5 x 4
  `sex \\ gender` feminine masculine  `NA`
  <chr>              <int>     <int> <int>
1 female                16         0     0
2 hermaphroditic         0         1     0
3 male                   0        60     0
4 none                   1         5     0
5 <NA>                   0         0     4
```

