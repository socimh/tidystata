# Function: fre()

**Version:** 0.2.0.9000 | **Generated:** 2026-10-16 21:08:33 | **Status:** PASS

## Example 1: Basic frequency with Total

```r
fre(mtcars, cyl)
```

**Output:**

```
# A tibble: 4 x 6
  cyl       n percent   cum valid valid_cum
  <chr> <int>   <dbl> <dbl> <dbl>     <dbl>
1 4        11    34.4  34.4  34.4      34.4
2 6         7    21.9  56.2  21.9      56.2
3 8        14    43.8 100    43.8     100
4 Total    32   100    NA    NA        NA
```

## Example 2: With tibble output

```r
fre(mtcars, cyl, .type = 'tibble')
```

**Output:**

```
# A tibble: 4 x 6
  cyl       n percent   cum valid valid_cum
  <chr> <int>   <dbl> <dbl> <dbl>     <dbl>
1 4        11    34.4  34.4  34.4      34.4
2 6         7    21.9  56.2  21.9      56.2
3 8        14    43.8 100    43.8     100
4 Total    32   100    NA    NA        NA
```

## Example 3: With grouping

```r
fre(mtcars, gear, .by = cyl, .type = 'tibble')
```

**Output:**

```
# A tibble: 11 x 7
     cyl gear      n percent    cum valid valid_cum
   <dbl> <chr> <int>   <dbl>  <dbl> <dbl>     <dbl>
 1     4 3         1    9.09   9.09  9.09      9.09
 2     4 4         8   72.7   81.8  72.7      81.8
 3     4 5         2   18.2  100    18.2     100
 4     4 Total    11  100     NA    NA        NA
 5     6 3         2   28.6   28.6  28.6      28.6
 6     6 4         4   57.1   85.7  57.1      85.7
 7     6 5         1   14.3  100    14.3     100
 8     6 Total     7  100     NA    NA        NA
 9     8 3        12   85.7   85.7  85.7      85.7
10     8 5         2   14.3  100    14.3     100
11     8 Total    14  100     NA    NA        NA
```

## Example 4: With starwars data

```r
fre(starwars, sex, .type = 'tibble')
```

**Output:**

```
# A tibble: 7 x 6
  sex                n percent   cum  valid valid_cum
  <chr>          <int>   <dbl> <dbl>  <dbl>     <dbl>
1 female            16   18.4   18.4  19.3       19.3
2 hermaphroditic     1    1.15  19.5   1.20      20.5
3 male              60   69.0   88.5  72.3       92.8
4 none               6    6.90  95.4   7.23     100
5 Valid Total       83   95.4   NA   100         NA
6 <NA>               4    4.60 100    NA         NA
7 Total             87  100     NA    NA         NA
```

## Example 5: With missing values

```r
df <- data.frame(x = c('a', 'b', NA, 'a', 'b', NA))
fre(df, x, .type = 'tibble')
```

**Output:**

```
# A tibble: 5 x 6
  x               n percent   cum valid valid_cum
  <chr>       <int>   <dbl> <dbl> <dbl>     <dbl>
1 a               2    33.3  33.3    50        50
2 b               2    33.3  66.7    50       100
3 Valid Total     4    66.7  NA     100        NA
4 <NA>            2    33.3 100      NA        NA
5 Total           6   100    NA      NA        NA
```

## Example 6: fre1() for multiple variables

```r
fre1(starwars, sex, gender, .type = 'tibble')
```

**Output:**

```
# A tibble: 12 x 7
   variable value              n percent   cum  valid valid_cum
   <chr>    <chr>          <int>   <dbl> <dbl>  <dbl>     <dbl>
 1 sex      female            16   18.4   18.4  19.3       19.3
 2 sex      hermaphroditic     1    1.15  19.5   1.20      20.5
 3 sex      male              60   69.0   88.5  72.3       92.8
 4 sex      none               6    6.90  95.4   7.23     100
 5 sex      Valid Total       83   95.4   NA   100         NA
 6 sex      <NA>               4    4.60 100    NA         NA
 7 sex      Total             87  100     NA    NA         NA
 8 gender   feminine          17   19.5   19.5  20.5       20.5
 9 gender   masculine         66   75.9   95.4  79.5      100
10 gender   Valid Total       83   95.4   NA   100         NA
11 gender   <NA>               4    4.60 100    NA         NA
12 gender   Total             87  100     NA    NA         NA
```

