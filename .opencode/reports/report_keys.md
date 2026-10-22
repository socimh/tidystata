# Function: keys()

**Version:** 0.3.0 | **Generated:** 2026-10-21 20:42:08 | **Status:** PASS

## Example 1: isid() asserts a key inside a pipeline

```
[1] "Variables `id`, `wave` do not uniquely identify the rows: 1 value\nappears more than once (2 rows).\ni See them with `duplicates_list()`."
```

## Example 2: duplicates report, tag and list

```
# A tibble: 2 x 3
  copies observations surplus
   <int>        <int>   <int>
1      1            1       0
2      2            4       2
# A tibble: 5 x 4
     id  wave score   dup
  <dbl> <dbl> <dbl> <int>
1     1     1     5     0
2     1     2     6     0
3     2     1     7     1
4     2     1     7     1
5     3     1     8     0
# A tibble: 2 x 5
     id  wave score .dup_group  .row
  <dbl> <dbl> <dbl>      <int> <int>
1     2     1     7          1     3
2     2     1     7          1     4
```

## Example 3: dropping duplicates guards against data loss

```
[1] "Rows sharing variable `id` differ in other columns, so dropping them\nloses data.\ni Use `.force = TRUE` to keep the first row of each set anyway."
(1 row removed)
# A tibble: 4 x 3
     id  wave score
  <dbl> <dbl> <dbl>
1     1     1     5
2     1     2     6
3     2     1     7
4     3     1     8
```

## Example 4: renamed functions

```
[1] [0,0] [0,0] [0,0] (0,1] (0,1]
Levels: [0,0] < (0,1]
[1] "id"   "wave"
```

## Example 5: s_merge() reports matches like Stata

```
Result                            Rows
--------------------------------------
Not matched                          2
    from master                      1  (.merge == "master only")
    from using                       1  (.merge == "using only")

Matched                              2  (.merge == "matched")
--------------------------------------
# A tibble: 4 x 4
     id   age income .merge
  <int> <dbl>  <dbl> <fct>
1     1    30     NA master only
2     2    41     10 matched
3     3    25     20 matched
4     4    NA     30 using only
Result                            Rows
--------------------------------------
Not matched                          2
    from master                      1  (.merge == "master only")
    from using                       1  (.merge == "using only")

Matched                              2  (.merge == "matched")
--------------------------------------
[1] "Merge assertion failed: found 1 master only row(s) and 1 using only\nrow(s); `assert` allows only matched."
```

## Example 6: tab2() cross-tabulates, optionally with totals

```
# A tibble: 5 x 4
  `sex \\ gender` feminine masculine  `NA`
  <chr>              <int>     <int> <int>
1 female                16         0     0
2 hermaphroditic         0         1     0
3 male                   0        60     0
4 none                   1         5     0
5 <NA>                   0         0     4
# A tibble: 6 x 5
  `sex \\ gender` feminine masculine  `NA` total
  <chr>              <int>     <int> <int> <int>
1 female                16         0     0    16
2 hermaphroditic         0         1     0     1
3 male                   0        60     0    60
4 none                   1         5     0     6
5 <NA>                   0         0     4     4
6 total                 17        66     4    87
```

## Example 7: duplicate metadata is safe for grouped data

```
# A tibble: 2 x 5
# Groups:   id [1]
     id  wave score .dup_group  .row
  <dbl> <dbl> <dbl>      <int> <int>
1     2     1     7          1     3
2     2     1     7          1     4
[1] "Column `.row` already exists.\ni Rename it before calling `duplicates_list()`."
```
