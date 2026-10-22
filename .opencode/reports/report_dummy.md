# Function: dummy()

**Version:** 0.3.0 | **Generated:** 2026-10-21 20:14:19 | **Status:** PASS

## Example 1: standardise and scale within groups

```
# A tibble: 68 x 6
   region               country                 lexp       z popgrowth  share
   <dbl+lbl>            <chr>                  <dbl>   <dbl>     <dbl>  <dbl>
 1 1 [Europe & C. Asia] Albania                   72 -0.257      1.20   5.19
 2 1 [Europe & C. Asia] Armenia                   74  0.224      1.10   4.76
 3 1 [Europe & C. Asia] Austria                   79  1.43       0.400  1.73
 4 1 [Europe & C. Asia] Azerbaijan                71 -0.498      1.40   6.06
 5 1 [Europe & C. Asia] Belarus                   68 -1.22       0.300  1.30
 6 1 [Europe & C. Asia] Belgium                   78  1.19       0.200  0.866
 7 1 [Europe & C. Asia] Bosnia and Herzegovina    73 -0.0164    -0.5   -2.16
 8 1 [Europe & C. Asia] Bulgaria                  71 -0.498     -0.400 -1.73
 9 1 [Europe & C. Asia] Croatia                   73 -0.0164    -0.100 -0.433
10 1 [Europe & C. Asia] Czech Republic            75  0.465      0      0
# i 58 more rows
```

## Example 2: indicator columns after their source

```
# A tibble: 87 x 6
   name               sex    sex_female sex_hermaphroditic sex_male sex_none
   <chr>              <chr>       <int>              <int>    <int>    <int>
 1 Luke Skywalker     male            0                  0        1        0
 2 C-3PO              none            0                  0        0        1
 3 R2-D2              none            0                  0        0        1
 4 Darth Vader        male            0                  0        1        0
 5 Leia Organa        female          1                  0        0        0
 6 Owen Lars          male            0                  0        1        0
 7 Beru Whitesun Lars female          1                  0        0        0
 8 R5-D4              none            0                  0        0        1
 9 Biggs Darklighter  male            0                  0        1        0
10 Obi-Wan Kenobi     male            0                  0        1        0
# i 77 more rows
[1] "sex==male"
```

## Example 3: Stata-style numbered columns

```
# A tibble: 68 x 8
   region_1 region_2 region_3 country            popgrowth  lexp gnppc safewater
      <int>    <int>    <int> <chr>                  <dbl> <dbl> <dbl>     <dbl>
 1        1        0        0 Albania                1.20     72   810        76
 2        1        0        0 Armenia                1.10     74   460        NA
 3        1        0        0 Austria                0.400    79 26830        NA
 4        1        0        0 Azerbaijan             1.40     71   480        NA
 5        1        0        0 Belarus                0.300    68  2180        NA
 6        1        0        0 Belgium                0.200    78 25380        NA
 7        1        0        0 Bosnia and Herzeg~    -0.5      73    NA        NA
 8        1        0        0 Bulgaria              -0.400    71  1220        NA
 9        1        0        0 Croatia               -0.100    73  4620        63
10        1        0        0 Czech Republic         0        75  5150        NA
# i 58 more rows
```
