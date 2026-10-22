# Function: tab1()

**Version:** 0.3.0 | **Generated:** 2026-10-21 20:42:09 | **Status:** PASS

## Example 1: Basic one-way table

```r
tab1(dplyr::starwars, sex)
```

**Output:**

```
$sex
# A tibble: 5 x 6
  value              n percent   cum valid valid_cum
  <chr>          <int>   <dbl> <dbl> <dbl>     <dbl>
1 female            16   18.4   18.4 19.3       19.3
2 hermaphroditic     1    1.15  19.5  1.20      20.5
3 male              60   69.0   88.5 72.3       92.8
4 none               6    6.90  95.4  7.23     100
5 <NA>               4    4.60 100   NA         NA

```

## Example 2: Multiple variables

```r
tab1(dplyr::starwars, sex, gender)
```

**Output:**

```
$sex
# A tibble: 5 x 6
  value              n percent   cum valid valid_cum
  <chr>          <int>   <dbl> <dbl> <dbl>     <dbl>
1 female            16   18.4   18.4 19.3       19.3
2 hermaphroditic     1    1.15  19.5  1.20      20.5
3 male              60   69.0   88.5 72.3       92.8
4 none               6    6.90  95.4  7.23     100
5 <NA>               4    4.60 100   NA         NA

$gender
# A tibble: 3 x 6
  value         n percent   cum valid valid_cum
  <chr>     <int>   <dbl> <dbl> <dbl>     <dbl>
1 feminine     17   19.5   19.5  20.5      20.5
2 masculine    66   75.9   95.4  79.5     100
3 <NA>          4    4.60 100    NA        NA

```

## Example 3: With boolean expression

```r
tab1(dplyr::starwars, tall = height > 180)
```

**Output:**

```
$tall
# A tibble: 3 x 6
  value     n percent   cum valid valid_cum
  <lgl> <int>   <dbl> <dbl> <dbl>     <dbl>
1 FALSE    42   48.3   48.3  51.9      51.9
2 TRUE     39   44.8   93.1  48.1     100
3 NA        6    6.90 100    NA        NA

```

## Example 4: With tibble output

```r
tab1(dplyr::starwars, sex, gender, .type = 'tibble')
```

**Output:**

```
# A tibble: 8 x 7
  variable value              n percent   cum valid valid_cum
  <chr>    <chr>          <int>   <dbl> <dbl> <dbl>     <dbl>
1 sex      female            16   18.4   18.4 19.3       19.3
2 sex      hermaphroditic     1    1.15  19.5  1.20      20.5
3 sex      male              60   69.0   88.5 72.3       92.8
4 sex      none               6    6.90  95.4  7.23     100
5 sex      <NA>               4    4.60 100   NA         NA
6 gender   feminine          17   19.5   19.5 20.5       20.5
7 gender   masculine         66   75.9   95.4 79.5      100
8 gender   <NA>               4    4.60 100   NA         NA
```

## Example 5: With tidyselect

```r
tab1(dplyr::starwars, ends_with('color'))
```

**Output:**

```
$hair_color
# A tibble: 12 x 6
   value             n percent    cum valid valid_cum
   <chr>         <int>   <dbl>  <dbl> <dbl>     <dbl>
 1 auburn            1    1.15   1.15  1.22      1.22
 2 auburn, grey      1    1.15   2.30  1.22      2.44
 3 auburn, white     1    1.15   3.45  1.22      3.66
 4 black            13   14.9   18.4  15.9      19.5
 5 blond             3    3.45  21.8   3.66     23.2
 6 blonde            1    1.15  23.0   1.22     24.4
 7 brown            18   20.7   43.7  22.0      46.3
 8 brown, grey       1    1.15  44.8   1.22     47.6
 9 grey              1    1.15  46.0   1.22     48.8
10 none             38   43.7   89.7  46.3      95.1
11 white             4    4.60  94.3   4.88    100
12 <NA>              5    5.75 100    NA        NA

$skin_color
# A tibble: 31 x 6
   value                   n percent   cum valid valid_cum
   <chr>               <int>   <dbl> <dbl> <dbl>     <dbl>
 1 blue                    2    2.30  2.30  2.30      2.30
 2 blue, grey              2    2.30  4.60  2.30      4.60
 3 brown                   4    4.60  9.20  4.60      9.20
 4 brown mottle            1    1.15 10.3   1.15     10.3
 5 brown, white            1    1.15 11.5   1.15     11.5
 6 dark                    6    6.90 18.4   6.90     18.4
 7 fair                   17   19.5  37.9  19.5      37.9
 8 fair, green, yellow     1    1.15 39.1   1.15     39.1
 9 gold                    1    1.15 40.2   1.15     40.2
10 green                   6    6.90 47.1   6.90     47.1
# i 21 more rows

$eye_color
# A tibble: 15 x 6
   value             n percent   cum valid valid_cum
   <chr>         <int>   <dbl> <dbl> <dbl>     <dbl>
 1 black            10   11.5   11.5 11.5       11.5
 2 blue             19   21.8   33.3 21.8       33.3
 3 blue-gray         1    1.15  34.5  1.15      34.5
 4 brown            21   24.1   58.6 24.1       58.6
 5 dark              1    1.15  59.8  1.15      59.8
 6 gold              1    1.15  60.9  1.15      60.9
 7 green, yellow     1    1.15  62.1  1.15      62.1
 8 hazel             3    3.45  65.5  3.45      65.5
 9 orange            8    9.20  74.7  9.20      74.7
10 pink              1    1.15  75.9  1.15      75.9
11 red               5    5.75  81.6  5.75      81.6
12 red, blue         1    1.15  82.8  1.15      82.8
13 unknown           3    3.45  86.2  3.45      86.2
14 white             1    1.15  87.4  1.15      87.4
15 yellow           11   12.6  100   12.6      100

```

## Example 6: Named expression

```r
tab1(dplyr::starwars, human = species == 'Human')
```

**Output:**

```
$human
# A tibble: 3 x 6
  value     n percent   cum valid valid_cum
  <lgl> <int>   <dbl> <dbl> <dbl>     <dbl>
1 FALSE    48   55.2   55.2  57.8      57.8
2 TRUE     35   40.2   95.4  42.2     100
3 NA        4    4.60 100    NA        NA

```

