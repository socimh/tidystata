# Function: fre()

**Generated:** 2026-03-03 23:09:16

---

## Example 1: Basic frequency with Total

```r
fre(mtcars, cyl)
```

**Output:**

```
a flextable object.
col_keys: `cyl`, `n`, `percent`, `cum`, `valid`, `valid_cum` 
header has 2 row(s) 
body has 4 row(s) 
original dataset sample: 
    cyl  n percent     cum  valid valid_cum
1     4 11  34.375  34.375 34.375    34.375
2     6  7  21.875  56.250 21.875    56.250
3     8 14  43.750 100.000 43.750   100.000
4 Total 32 100.000      NA     NA        NA
```

## Example 2: With tibble output

```r
fre(mtcars, cyl, .type = 'tibble')
```

**Output:**

```
    cyl  n percent     cum  valid valid_cum
1     4 11  34.375  34.375 34.375    34.375
2     6  7  21.875  56.250 21.875    56.250
3     8 14  43.750 100.000 43.750   100.000
4 Total 32 100.000      NA     NA        NA
```

## Example 3: With grouping

```r
fre(mtcars, gear, .by = cyl, .type = 'tibble')
```

**Output:**

```
# A tibble: 9 × 7
    cyl gear      n percent    cum valid valid_cum
  <dbl> <chr> <int>   <dbl>  <dbl> <dbl>     <dbl>
1     4 3         1    9.09   9.09  9.09      9.09
2     4 4         8   72.7   81.8  72.7      81.8 
3     4 5         2   18.2  100    18.2     100   
4     6 3         2   28.6   28.6  28.6      28.6 
5     6 4         4   57.1   85.7  57.1      85.7 
6     6 5         1   14.3  100    14.3     100   
7     8 3        12   85.7   85.7  85.7      85.7 
8     8 5         2   14.3  100    14.3     100   
9    NA Total    32  100     NA    NA        NA   
```

## Example 4: With starwars data

```r
fre(starwars, sex, .type = 'tibble')
```

**Output:**

```
# A tibble: 7 × 6
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
            x n   percent       cum valid valid_cum
1           a 2  33.33333  33.33333    50        50
2           b 2  33.33333  66.66667    50       100
3 Valid Total 4  66.66667        NA   100        NA
4        <NA> 2  33.33333 100.00000    NA        NA
5       Total 6 100.00000        NA    NA        NA
```

## Example 6: fre1() for multiple variables

```r
fre1(starwars, sex, gender, .type = 'tibble')
```

**Output:**

```
# A tibble: 14 × 7
   variable value              n percent   cum  valid valid_cum
   <chr>    <chr>          <int>   <dbl> <dbl>  <dbl>     <dbl>
 1 sex      female            16   18.4   18.4  19.3       19.3
 2 sex      hermaphroditic     1    1.15  19.5   1.20      20.5
 3 sex      male              60   69.0   88.5  72.3       92.8
 4 sex      none               6    6.90  95.4   7.23     100  
 5 sex      Valid Total       83   95.4   NA   100         NA  
 6 sex      <NA>               4    4.60 100    NA         NA  
 7 sex      Total             87  100     NA    NA         NA  
 8 <NA>     <NA>              NA   NA     NA    NA         NA  
 9 gender   feminine          17   19.5   19.5  20.5       20.5
10 gender   masculine         66   75.9   95.4  79.5      100  
11 gender   Valid Total       83   95.4   NA   100         NA  
12 gender   <NA>               4    4.60 100    NA         NA  
13 gender   Total             87  100     NA    NA         NA  
14 <NA>     <NA>              NA   NA     NA    NA         NA  
```


