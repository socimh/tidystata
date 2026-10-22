# Function: dummy()

**Version:** 0.3.0 | **Generated:** 2026-10-21 20:42:08 | **Status:** PASS

## Example 1: standardise and scale within groups

```
# A tibble: 68 x 6
   region               country                 lexp      z popgrowth  share
   <dbl+lbl>            <chr>                  <dbl>  <dbl>     <dbl>  <dbl>
 1 1 [Europe & C. Asia] Albania                   74  0.303      -0.6 -19.4
 2 1 [Europe & C. Asia] Armenia                   70 -0.505      -1.2 -38.7
 3 1 [Europe & C. Asia] Austria                   78  1.11        0.1   3.23
 4 1 [Europe & C. Asia] Azerbaijan                64 -1.72        0.9  29.0
 5 1 [Europe & C. Asia] Belarus                   68 -0.909      -0.5 -16.1
 6 1 [Europe & C. Asia] Belgium                   77  0.909       0.2   6.45
 7 1 [Europe & C. Asia] Bosnia and Herzegovina    74  0.303       1.8  58.1
 8 1 [Europe & C. Asia] Bulgaria                  71 -0.303      -0.7 -22.6
 9 1 [Europe & C. Asia] Croatia                   72 -0.101      -0.1  -3.23
10 1 [Europe & C. Asia] Czechia                   75  0.505      -0.1  -3.23
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
 1        1        0        0 Albania                 -0.6    74   870        49
 2        1        0        0 Armenia                 -1.2    70   570        83
 3        1        0        0 Austria                  0.1    78 27810        97
 4        1        0        0 Azerbaijan               0.9    64   510        49
 5        1        0        0 Belarus                 -0.5    68  1540        82
 6        1        0        0 Belgium                  0.2    77 26530       100
 7        1        0        0 Bosnia and Herzeg~       1.8    74  1230        87
 8        1        0        0 Bulgaria                -0.7    71  1440        90
 9        1        0        0 Croatia                 -0.1    72    NA        85
10        1        0        0 Czechia                 -0.1    75  6140        95
# i 58 more rows
```
