# Tabulate and compare categories

The course coordinator wants to know whether participants were
satisfied, and whether the two centres tell the same story. Start with a
frequency table, then choose the layout that answers each follow-up
question. Results remain ordinary tables that work with dplyr.

## Start with one question

These are the same twelve participants used in [Getting
started](https://socimh.github.io/tidystata/articles/getting-started.md),
keeping only the columns needed here.

``` r

library(dplyr)
library(tibble)
library(tidystata)

survey <- tribble(
  ~id, ~centre,     ~satisfied,
    1, "Riverside", "Yes",
    2, "Riverside", "Yes",
    3, "Riverside", "No",
    4, "Riverside", NA,
    5, "Riverside", "Yes",
    6, "Riverside", "Yes",
    7, "Hilltop",   "No",
    8, "Hilltop",   "Yes",
    9, "Hilltop",   "No",
   10, "Hilltop",   "Yes",
   11, "Hilltop",   "Yes",
   12, "Hilltop",   NA
)

survey |> tab(satisfied)
#> # A tibble: 3 × 6
#>   satisfied     n percent   cum valid valid_cum
#>   <chr>     <int>   <dbl> <dbl> <dbl>     <dbl>
#> 1 No            3    25    25      30        30
#> 2 Yes           7    58.3  83.3    70       100
#> 3 NA            2    16.7 100      NA        NA
```

Seven participants said yes, three said no, and two did not answer. Read
the columns in terms of the question you want to answer:

| Column | Question |
|----|----|
| `n` | How many participants gave this answer? |
| `percent` | What percentage of **all twelve** participants is that? |
| `valid` | What percentage of the **ten who answered** is that? |
| `cum`, `valid_cum` | What percentage have we reached in the displayed order? |

All four percentage columns use a 0-100 scale. Thus the yes share is
58.3% of everyone and 70% of respondents. Missing categories have no
valid percentage. Cumulative percentages are most useful for categories
with a meaningful order.

## Choose joint, separate or cross-tabulated counts

The three `tab` functions answer different questions using the same
columns.

### Which combinations occur?

[`tab()`](https://socimh.github.io/tidystata/reference/tab.md) counts
combinations in one long table. With two columns, each row is a
centre-answer combination:

``` r

survey |> tab(centre, satisfied)
#> # A tibble: 6 × 7
#>   centre    satisfied     n percent   cum valid valid_cum
#>   <chr>     <chr>     <int>   <dbl> <dbl> <dbl>     <dbl>
#> 1 Hilltop   No            2   16.7   16.7    20        20
#> 2 Hilltop   Yes           3   25     41.7    30        50
#> 3 Riverside No            1    8.33  50      10        60
#> 4 Riverside Yes           4   33.3   83.3    40       100
#> 5 Hilltop   NA            1    8.33  91.7    NA        NA
#> 6 Riverside NA            1    8.33 100      NA        NA
```

Here `percent` and `cum` use all twelve participants; `valid` and
`valid_cum` use the ten with both centre and satisfaction observed.
Adding a third variable would count three-way combinations.

### What is each variable’s distribution?

[`tab1()`](https://socimh.github.io/tidystata/reference/tab.md) makes
separate one-way tables. Use `.type = "tibble"` to stack them into one
table with a `variable` column:

``` r

survey |> tab1(centre, satisfied, .type = "tibble")
#> # A tibble: 5 × 7
#>   variable  value         n percent   cum valid valid_cum
#>   <chr>     <chr>     <int>   <dbl> <dbl> <dbl>     <dbl>
#> 1 centre    Hilltop       6    50    50      50        50
#> 2 centre    Riverside     6    50   100      50       100
#> 3 satisfied No            3    25    25      30        30
#> 4 satisfied Yes           7    58.3  83.3    70       100
#> 5 satisfied NA            2    16.7 100      NA        NA
```

Each variable has its own denominator. The default instead returns a
named list, convenient when the tables will be used separately.

### How do the centres compare side by side?

[`tab2()`](https://socimh.github.io/tidystata/reference/tab.md) puts the
second variable’s categories in columns. Cells contain counts, rather
than the percentages from
[`tab()`](https://socimh.github.io/tidystata/reference/tab.md):

``` r

survey |> tab2(centre, satisfied)
#> # A tibble: 2 × 4
#>   `centre \\ satisfied`    No   Yes  `NA`
#>   <chr>                 <int> <int> <int>
#> 1 Hilltop                   2     3     1
#> 2 Riverside                 1     4     1
```

With more than two selected variables,
[`tab2()`](https://socimh.github.io/tidystata/reference/tab.md) returns
a list of tables for every pair, rather than one higher-dimensional
table. Use `.flip = TRUE` to exchange rows and columns.

## Compare percentages within each centre

To compare satisfaction rates, put the centre in `.by` instead of
counting it as another measured variable:

``` r

survey |> tab(satisfied, .by = centre)
#> # A tibble: 6 × 7
#>   centre    satisfied     n percent   cum valid valid_cum
#>   <chr>     <chr>     <int>   <dbl> <dbl> <dbl>     <dbl>
#> 1 Hilltop   No            2    33.3  33.3    40        40
#> 2 Hilltop   Yes           3    50    83.3    60       100
#> 3 Hilltop   NA            1    16.7 100      NA        NA
#> 4 Riverside No            1    16.7  16.7    20        20
#> 5 Riverside Yes           4    66.7  83.3    80       100
#> 6 Riverside NA            1    16.7 100      NA        NA
```

Both centres have six participants and five observed answers.
Riverside’s yes share is 80% of respondents; Hilltop’s is 60%. The
missing answers still appear, so the difference between all-participant
and valid shares stays visible.

One-way and joint tables also inherit
[`group_by()`](https://dplyr.tidyverse.org/reference/group_by.html)
groups:

``` r

survey |>
  group_by(centre) |>
  tab(satisfied) |>
  filter(satisfied == "Yes") |>
  select(centre, n, percent, valid)
#> # A tibble: 2 × 4
#>   centre        n percent valid
#>   <chr>     <int>   <dbl> <dbl>
#> 1 Hilltop       3    50      60
#> 2 Riverside     4    66.7    80
```

The result is ungrouped. An explicit `.by` replaces inherited groups.
[`tab2()`](https://socimh.github.io/tidystata/reference/tab.md) and
[`fre2()`](https://socimh.github.io/tidystata/reference/tab.md) require
an explicit `.by` to make separate cross-tables by group;
[`group_by()`](https://dplyr.tidyverse.org/reference/group_by.html)
alone does not split their results.

## Add totals and readable labels

[`fre()`](https://socimh.github.io/tidystata/reference/tab.md) adds
total rows. Here we encode the answer to illustrate imported numeric
categories with value labels:

``` r

labelled <- survey |> mutate(answer_code = encode(satisfied))

labelled |> fre(answer_code)
#> # A tibble: 5 × 6
#>   answer_code     n percent   cum valid valid_cum
#>   <chr>       <int>   <dbl> <dbl> <dbl>     <dbl>
#> 1 No              3    25    25      30        30
#> 2 Yes             7    58.3  83.3    70       100
#> 3 Valid Total    10    83.3  NA     100        NA
#> 4 NA              2    16.7 100      NA        NA
#> 5 Total          12   100    NA      NA        NA
```

[`tab()`](https://socimh.github.io/tidystata/reference/tab.md) retains
stored category codes and types;
[`fre()`](https://socimh.github.io/tidystata/reference/tab.md) displays
value labels. Distinct codes remain distinct even when they share a
label. [`fre1()`](https://socimh.github.io/tidystata/reference/tab.md)
adds totals to separate one-way tables;
[`fre2()`](https://socimh.github.io/tidystata/reference/tab.md) adds row
and column totals to a cross-tabulation:

``` r

survey |> fre2(centre, satisfied)
#> # A tibble: 3 × 5
#>   `centre \\ satisfied`    No   Yes  `NA` total
#>   <chr>                 <int> <int> <int> <int>
#> 1 Hilltop                   2     3     1     6
#> 2 Riverside                 1     4     1     6
#> 3 total                     3     7     2    12
```

[`fre2()`](https://socimh.github.io/tidystata/reference/tab.md) displays
labels for row categories; column headers retain category codes. You can
also request totals with `.total = TRUE` in the `tab` family. Totals are
useful for presentation, but use tables without total rows for further
arithmetic so observations are not counted twice.

## Order and reuse the results

Which answer is most common? `.desc = TRUE` sorts by decreasing count,
keeping missing values last:

``` r

survey |> tab(satisfied, .desc = TRUE)
#> # A tibble: 3 × 6
#>   satisfied     n percent   cum valid valid_cum
#>   <chr>     <int>   <dbl> <dbl> <dbl>     <dbl>
#> 1 Yes           7    58.3  58.3    70        70
#> 2 No            3    25    83.3    30       100
#> 3 NA            2    16.7 100      NA        NA
```

Factors follow their level order by default; other categories sort by
value. `.group_order = "frequency"` separately orders group blocks by
their totals. Use dplyr to keep the categories relevant to a report:

``` r

survey |>
  tab(satisfied, .by = centre) |>
  filter(!is.na(satisfied)) |>
  arrange(centre, desc(n)) |>
  select(centre, satisfied, n, valid)
#> # A tibble: 4 × 4
#>   centre    satisfied     n valid
#>   <chr>     <chr>     <int> <dbl>
#> 1 Hilltop   Yes           3    60
#> 2 Hilltop   No            2    40
#> 3 Riverside Yes           4    80
#> 4 Riverside No            1    20
```

Filtering here keeps the percentages already calculated. To change a
denominator, filter the source observations **before** calling
[`tab()`](https://socimh.github.io/tidystata/reference/tab.md). Empty
strings count as observed answers, so clean blank text first if it means
nonresponse.

## Count a file that already contains frequencies

Suppose a second coordinator sends an aggregate file: one row represents
several people. Use the frequency column as `.wt`:

``` r

register <- tribble(
  ~satisfied, ~people,
  "Yes",           7,
  "No",            3,
  NA,              2
)

register |> tab(satisfied, .wt = people)
#> # A tibble: 3 × 6
#>   satisfied     n percent   cum valid valid_cum
#>   <chr>     <dbl>   <dbl> <dbl> <dbl>     <dbl>
#> 1 No            3    25    25      30        30
#> 2 Yes           7    58.3  83.3    70       100
#> 3 NA            2    16.7 100      NA        NA
```

This reproduces the individual-level table. Frequency weights sum to the
reported counts. Analytic weights (`.wt_type = "analytic"`) instead
rescale weights within each group to its number of rows; their
percentages agree, but their counts have a different interpretation.
Missing weights exclude rows, and negative weights are invalid. These
options do not account for a complex survey design.

## Association tests and longer tables

For an association test, `.chi2 = TRUE` adds Pearson’s chi-square and
Cramer’s V. Remove missing answers first when nonresponse should not
enter the test:

``` r

association <- survey |>
  filter(!is.na(satisfied)) |>
  tab2(centre, satisfied, .chi2 = TRUE)
#> Pearson chi2(1) = 0.4762   Pr = 0.490
#> Cramer's V = 0.2182
```

The test is reported as a message. Its numerical results are also
available on the returned table:

``` r

attr(association, "chi2")
#> # A tibble: 1 × 5
#>   statistic    df p_value cramers_v     n
#>       <dbl> <int>   <dbl>     <dbl> <int>
#> 1     0.476     1   0.490     0.218    10
```

This tiny teaching sample has small expected cell counts, so use the
example to learn the interface, rather than draw an inference about the
programme. Analytic weights are not supported for this test.

Score variables can produce long tables because every distinct value is
counted. Add the first assessment item from our survey and shorten its
display with a one-time printer, which still returns every row:

``` r

survey |>
  mutate(score = c(2, 4, NA, 6, 8, 4, 3, 5, 7, 9, NA, 6)) |>
  tab(score) |>
  print_interval(n = 6)
#> # A tibble: 9 × 6
#>   score     n percent    cum valid valid_cum
#>   <dbl> <int>   <dbl>  <dbl> <dbl>     <dbl>
#> 1     2     1    8.33   8.33    10        10
#> 3     4     2   16.7   33.3     20        40
#> 4     5     1    8.33  41.7     10        50
#> 6     7     1    8.33  66.7     10        80
#> 7     8     1    8.33  75       10        90
#> 9    NA     2   16.7  100       NA        NA
#> # ... 3 rows omitted between displayed positions; use print(x, n = Inf) to show
#> # all rows.
```

For formatted reports, the `fre` family supports `.type = "flextable"`
when that optional package is installed. See the [output
conventions](https://socimh.github.io/tidystata/articles/containers-and-missing-values.md)
for lists and table classes, or continue to [measurement
summaries](https://socimh.github.io/tidystata/articles/summary-statistics.md).
