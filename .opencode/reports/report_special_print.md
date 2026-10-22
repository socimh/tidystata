# Function: special_print()

**Version:** 0.3.0 | **Generated:** 2026-10-21 20:42:09 | **Status:** PASS

## Shared input

```r
library(tidystata)
survey <- tibble::tibble(
  respondent_id = seq_len(36),
  region = rep(c("North", "South", "West"), each = 12),
  employed = rep(c("Yes", "No", "Student"), 12),
  age = 22 + seq_len(36),
  income_k = 32 + (seq_len(36) %% 11) * 3.5
)
survey$income_k[c(7, 19)] <- NA_real_
```

## Example 1: Keep every respondent behind a head/tail preview

```r
prepared <- survey |>
  preview_table(n = 5) |>
  dplyr::mutate(income_log = log(income_k))
print(prepared)
```

**Output:**

```text
# A tibble: 36 x 6
   respondent_id region employed   age income_k income_log
           <int> <chr>  <chr>    <dbl>    <dbl>      <dbl>
 1             1 North  Yes         23     35.5       3.57
 2             2 North  No          24     39         3.66
 3             3 North  Student     25     42.5       3.75
35            35 West   No          57     39         3.66
36            36 West   Student     58     42.5       3.75
# ... 31 rows omitted in the middle; use print(x, n = Inf) to show all rows.
```


## Example 2: Review positions along a sorted income distribution

```r
sorted <- prepared |>
  dplyr::arrange(income_k, respondent_id) |>
  preview_table(style = "interval", n = 6)
print(sorted)
```

**Output:**

```text
# A tibble: 36 x 6
   respondent_id region employed   age income_k income_log
           <int> <chr>  <chr>    <dbl>    <dbl>      <dbl>
 1            11 North  No          33     32         3.47
 8             2 North  No          24     39         3.66
15            36 West   Student     58     42.5       3.75
22             6 North  Student     28     53         3.97
29             9 North  Student     31     63.5       4.15
36            19 South  Yes         41     NA        NA
# ... 30 rows omitted between displayed positions; use print(x, n = Inf) to
# show all rows.
```


## Example 3: One-off print helpers retain the complete input

```r
headtail_result <- withVisible(print_headtail(survey, n = 5, width = 90))
interval_result <- withVisible(print_interval(survey, n = 5, width = 90))
```

**Output:**

```text
# A tibble: 36 x 5
   respondent_id region employed   age income_k
           <int> <chr>  <chr>    <dbl>    <dbl>
 1             1 North  Yes         23     35.5
 2             2 North  No          24     39
 3             3 North  Student     25     42.5
35            35 West   No          57     39
36            36 West   Student     58     42.5
# ... 31 rows omitted in the middle; use print(x, n = Inf) to show all rows.
# A tibble: 36 x 5
   respondent_id region employed   age income_k
           <int> <chr>  <chr>    <dbl>    <dbl>
 1             1 North  Yes         23     35.5
10            10 North  Yes         32     67
18            18 South  Student     40     56.5
27            27 West   Student     49     49.5
36            36 West   Student     58     42.5
# ... 31 rows omitted between displayed positions; use print(x, n = Inf) to show all
# rows.
```


## Example 4: Slice helpers deliberately produce smaller research samples

```r
ends <- slice_headtail(survey, n = 5)
spaced <- slice_interval(survey, n = 5)
print(ends)
print(spaced)
```

**Output:**

```text
# A tibble: 5 x 5
  respondent_id region employed   age income_k
          <int> <chr>  <chr>    <dbl>    <dbl>
1             1 North  Yes         23     35.5
2             2 North  No          24     39
3             3 North  Student     25     42.5
4            35 West   No          57     39
5            36 West   Student     58     42.5
# A tibble: 5 x 5
  respondent_id region employed   age income_k
          <int> <chr>  <chr>    <dbl>    <dbl>
1             1 North  Yes         23     35.5
2            10 North  Yes         32     67
3            18 South  Student     40     56.5
4            27 West   Student     49     49.5
5            36 West   Student     58     42.5
```


## Example 5: Compact frequencies retain every category and respondent

```r
frequencies <- survey |>
  tab(region, employed) |>
  preview_table(n = 4) |>
  dplyr::mutate(proportion = n / sum(n))
print(frequencies)
```

**Output:**

```text
# A tibble: 9 x 8
  region employed     n percent   cum valid valid_cum proportion
  <chr>  <chr>    <int>   <dbl> <dbl> <dbl>     <dbl>      <dbl>
1 North  No           4    11.1  11.1  11.1      11.1      0.111
2 North  Student      4    11.1  22.2  11.1      22.2      0.111
8 West   Student      4    11.1  88.9  11.1      88.9      0.111
9 West   Yes          4    11.1 100    11.1     100        0.111
# ... 5 rows omitted in the middle; use print(x, n = Inf) to show all rows.
```


## Example 6: Summary output remains available for subsequent analysis

```r
summary <- survey |>
  summ(age, income_k, .by = region, .stat = c("n", "mean", "sd")) |>
  preview_table(n = 4)
print(summary)
```

**Output:**

```text
# A tibble: 6 x 6
  region name     type      n  mean    sd
  <chr>  <chr>    <chr> <int> <dbl> <dbl>
1 North  age      dbl      12  28.5  3.61
2 North  income_k dbl      11  47.6 12.1
5 West   age      dbl      12  52.5  3.61
6 West   income_k dbl      12  48.9 11.3
# ... 2 rows omitted in the middle; use print(x, n = Inf) to show all rows.
```


## Example 7: Grouped summaries and a long research table retain the style

```r
grouped <- prepared |>
  dplyr::group_by(region)
group_summary <- grouped |>
  dplyr::summarise(
    respondents = dplyr::n(),
    mean_income_k = mean(income_k, na.rm = TRUE),
    .groups = "drop"
  )
long_summary <- group_summary |>
  tidyr::pivot_longer(
    c(respondents, mean_income_k),
    names_to = "measure",
    values_to = "value"
  )
print(long_summary)
```

**Output:**

```text
# A tibble: 6 x 3
  region measure       value
  <chr>  <chr>         <dbl>
1 North  respondents    12
2 North  mean_income_k  47.6
3 South  respondents    12
5 West   respondents    12
6 West   mean_income_k  48.9
# ... 1 rows omitted in the middle; use print(x, n = Inf) to show all rows.
```


## Example 8: Remove the preview before sharing an ordinary table

```r
ordinary <- unpreview_table(prepared)
print(dplyr::slice_head(ordinary, n = 3))
```

**Output:**

```text
# A tibble: 3 x 6
  respondent_id region employed   age income_k income_log
          <int> <chr>  <chr>    <dbl>    <dbl>      <dbl>
1             1 North  Yes         23     35.5       3.57
2             2 North  No          24     39         3.66
3             3 North  Student     25     42.5       3.75
```
