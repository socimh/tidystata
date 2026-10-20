# Function: conversion()

**Version:** 0.2.0.9000 | **Generated:** 2026-10-19 21:18:21 | **Status:** PASS

## Example 1: Imported survey data

# A tibble: 4 x 4
  respondent response  income   quality
       <int> <dbl+lbl> <chr>      <int>
1          1  1 [Yes]  "$1,200"       1
2          2  2 [No]   "$900"        99
3          3 99        ""             2
4          4 NA        "$1,450"       1

## Example 2: Prepared research data

# A tibble: 4 x 4
  respondent response income quality
       <int> <chr>     <dbl>   <int>
1          1 Yes        1200       1
2          2 No          900      NA
3          3 99           NA       2
4          4 Unknown    1450       1

## Example 3: Factor labels and numeric codes

# A tibble: 3 x 3
  response text   code
  <fct>    <chr> <dbl>
1 Yes      Yes       2
2 No       No        1
3 <NA>     <NA>     NA

## Example 4: SPSS missing codes remain explicit values

# A tibble: 3 x 2
  text    raw_value
  <chr>       <dbl>
1 Yes             1
2 Refused        99
3 <NA>           NA
