# Function: checks()

**Version:** 0.3.0 | **Generated:** 2026-10-21 20:14:19 | **Status:** PASS

## Example 1: assertions inside a pipeline

```
# A tibble: 1 x 7
  type      n unique   min  mean    sd   max
  <chr> <int>  <int> <dbl> <dbl> <dbl> <dbl>
1 dbl      68     18    54  72.3  4.72    79
Assertion failed:
* `safewater > 50`: 30 contradictions (28 missing) in 68 rows; rows 2, 3, 4, 5,
  6, ...
* `popgrowth < 1`: 30 contradictions in 68 rows; rows 1, 2, 4, 22, 38, ...
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
 1          1 Albania                    1.20     72   810        76
 2          1 Armenia                    1.10     74   460        NA
 3          1 Austria                    0.400    79 26830        NA
 4          1 Azerbaijan                 1.40     71   480        NA
 5          1 Belarus                    0.300    68  2180        NA
 6          1 Belgium                    0.200    78 25380        NA
 7          1 Bosnia and Herzegovina    -0.5      73    NA        NA
 8          1 Bulgaria                  -0.400    71  1220        NA
 9          1 Croatia                   -0.100    73  4620        63
10          1 Czech Republic             0        75  5150        NA
11          1 Denmark                    0.200    76 33040        NA
12          1 Estonia                   -0.100    70  3360        NA
```
