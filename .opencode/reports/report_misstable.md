# Function: misstable()

**Version:** 0.3.0 | **Generated:** 2026-10-21 20:14:20 | **Status:** PASS

## Example 1: missing values by variable

```
# A tibble: 8 x 4
  variable   miss_n miss_pct valid_n
  <chr>       <int>    <dbl>   <int>
1 height          6     6.90      81
2 mass           28    32.2       59
3 hair_color      5     5.75      82
4 birth_year     44    50.6       43
5 sex             4     4.60      83
6 gender          4     4.60      83
7 homeworld      10    11.5       77
8 species         4     4.60      83
```

## Example 2: every variable, by group

```
# A tibble: 10 x 5
   sex            variable miss_n miss_pct valid_n
   <chr>          <chr>     <int>    <dbl>   <int>
 1 female         height        2     12.5      14
 2 female         mass          7     43.8       9
 3 hermaphroditic height        0      0         1
 4 hermaphroditic mass          0      0         1
 5 male           height        3      5        57
 6 male           mass         18     30        42
 7 none           height        1     16.7       5
 8 none           mass          2     33.3       4
 9 <NA>           height        0      0         4
10 <NA>           mass          1     25         3
```

## Example 3: missing patterns (1 = observed, 0 = missing)

```
# A tibble: 5 x 5
  height  mass birth_year     n percent
   <int> <int>      <int> <int>   <dbl>
1      1     1          1    36   41.4
2      1     1          0    23   26.4
3      1     0          0    15   17.2
4      1     0          1     7    8.05
5      0     0          0     6    6.90
```
