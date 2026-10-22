# Function: pwcorr()

**Version:** 0.3.0 | **Generated:** 2026-10-21 20:42:09 | **Status:** PASS

## Example 1: pairwise correlations with n and p

```
# A tibble: 3 x 5
  var1  var2          r     n        p
  <chr> <chr>     <dbl> <int>    <dbl>
1 lexp  gnppc     0.733    67 1.79e-12
2 lexp  safewater 0.760    54 2.74e-11
3 gnppc safewater 0.657    53 8.95e- 8
```

## Example 2: the matrix as Stata prints it

```
# A tibble: 3 x 4
  variable   lexp  gnppc safewater
  <chr>     <dbl>  <dbl>     <dbl>
1 lexp      1     NA            NA
2 gnppc     0.733  1            NA
3 safewater 0.760  0.657         1
```

## Example 3: by group and with Spearman correlations

```
# A tibble: 3 x 6
  region               var1  var2      r     n        p
  <dbl+lbl>            <chr> <chr> <dbl> <int>    <dbl>
1 1 [Europe & C. Asia] lexp  gnppc 0.792    43 2.57e-10
2 2 [North America]    lexp  gnppc 0.658    14 1.05e- 2
3 3 [South America]    lexp  gnppc 0.640    10 4.60e- 2
# A tibble: 1 x 5
  var1  var2      r     n        p
  <chr> <chr> <dbl> <int>    <dbl>
1 lexp  gnppc 0.861    67 9.53e-21
```

## Example 4: chi-square test with Cramer's V

```
Pearson chi2(8) = 168.6368   Pr = 0.000
Cramer's V = 0.9845
# A tibble: 5 x 4
  `sex \\ gender` feminine masculine  `NA`
  <chr>              <int>     <int> <int>
1 female                16         0     0
2 hermaphroditic         0         1     0
3 male                   0        60     0
4 none                   1         5     0
5 <NA>                   0         0     4
# A tibble: 1 x 5
  statistic    df  p_value cramers_v     n
      <dbl> <int>    <dbl>     <dbl> <int>
1      169.     8 2.49e-32     0.984    87
```

## Example 5: zero-weight outliers do not affect correlation

```
# A tibble: 1 x 5
  var1  var2      r     n     p
  <chr> <chr> <dbl> <dbl> <dbl>
1 x     y         1     2    NA
```
