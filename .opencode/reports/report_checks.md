# Function: checks()

**Version:** 0.3.0 | **Generated:** 2026-10-21 20:42:07 | **Status:** PASS

## Example 1: assertions inside a pipeline

```
# A tibble: 1 x 7
  type      n unique   min  mean    sd   max
  <chr> <int>  <int> <dbl> <dbl> <dbl> <dbl>
1 dbl      68     20    57  71.7  5.16    79
Assertion failed:
* `safewater > 50`: 25 contradictions (14 missing) in 68 rows; rows 1, 4, 22,
  26, 29, ...
* `popgrowth < 1`: 23 contradictions in 68 rows; rows 7, 19, 22, 39, 40, ...
```

## Example 2: flag one row per group

```
# A tibble: 6 x 3
     id  year first
  <dbl> <dbl> <lgl>
1     1  2001 TRUE
2     1  2002 FALSE
3     2  2001 TRUE
4     2  2002 FALSE
5     2  2003 FALSE
6    NA  2001 FALSE
```

## Example 3: list every row and column

```
# A tibble: 12 x 6
       region country                popgrowth  lexp gnppc safewater
   <hvn_lbll> <chr>                      <dbl> <dbl> <dbl>     <dbl>
 1          1 Albania                     -0.6    74   870        49
 2          1 Armenia                     -1.2    70   570        83
 3          1 Austria                      0.1    78 27810        97
 4          1 Azerbaijan                   0.9    64   510        49
 5          1 Belarus                     -0.5    68  1540        82
 6          1 Belgium                      0.2    77 26530       100
 7          1 Bosnia and Herzegovina       1.8    74  1230        87
 8          1 Bulgaria                    -0.7    71  1440        90
 9          1 Croatia                     -0.1    72    NA        85
10          1 Czechia                     -0.1    75  6140        95
11          1 Denmark                      0.4    76 33440        95
12          1 Estonia                     -1      69  3820        92
```
