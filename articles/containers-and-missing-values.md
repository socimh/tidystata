# Containers, grouping and missing values

Most workflows can begin with [Getting
started](https://socimh.github.io/tidystata/articles/getting-started.md),
followed by [category
tables](https://socimh.github.io/tidystata/articles/tabulation.md) or
[measurement
summaries](https://socimh.github.io/tidystata/articles/summary-statistics.md).
This companion explains what to expect when a result is a list, a group
is missing, or a display shows only some rows.

## Start with a tibble

This small illustration adapts the course survey, including a
deliberately missing centre to show how grouping works.

``` r

library(dplyr)
library(tibble)
library(tidystata)

survey <- tibble(
  centre = c("Riverside", "Riverside", "Hilltop", NA),
  satisfied = c("Yes", NA, "No", "Yes"),
  score = c(2, NA, 6, 8)
)

survey |> tab(satisfied)
#> # A tibble: 3 × 6
#>   satisfied     n percent   cum valid valid_cum
#>   <chr>     <int>   <dbl> <dbl> <dbl>     <dbl>
#> 1 No            1      25    25  33.3      33.3
#> 2 Yes           2      50    75  66.7     100  
#> 3 NA            1      25   100  NA        NA
```

With tibble inputs, the `tab`, `summ`, `codebook` and `variables`
families return tibbles, including tables inside lists. Base data frames
and data.table inputs retain their respective table class where
supported. Other subclasses are not reconstructed on newly shaped
tables; data.table summaries do not retain keys or indexes.

[`corr()`](https://socimh.github.io/tidystata/reference/corr.md),
[`pwcorr()`](https://socimh.github.io/tidystata/reference/corr.md),
[`spearman()`](https://socimh.github.io/tidystata/reference/corr.md),
[`misstable()`](https://socimh.github.io/tidystata/reference/misstable.md)
and
[`duplicates_report()`](https://socimh.github.io/tidystata/reference/keys.md)
always return tibbles. Functions designed to return vectors, such as
[`ds()`](https://socimh.github.io/tidystata/reference/names.md) and
[`row_mean()`](https://socimh.github.io/tidystata/reference/row_egen.md),
still return vectors.

## Choose tables or lists deliberately

Separate one-way tabulations return a named list by default. Extract a
table by its name:

``` r

tables <- survey |> tab1(centre, satisfied)

tables[["satisfied"]]
#> # A tibble: 3 × 6
#>   value     n percent   cum valid valid_cum
#>   <chr> <int>   <dbl> <dbl> <dbl>     <dbl>
#> 1 No        1      25    25  33.3      33.3
#> 2 Yes       2      50    75  66.7     100  
#> 3 NA        1      25   100  NA        NA
```

To work with one tibble instead, combine the variable tables:

``` r

survey |> tab1(centre, satisfied, .type = "tibble")
#> # A tibble: 6 × 7
#>   variable  value         n percent   cum valid valid_cum
#>   <chr>     <chr>     <int>   <dbl> <dbl> <dbl>     <dbl>
#> 1 centre    Hilltop       1      25    25  33.3      33.3
#> 2 centre    Riverside     2      50    75  66.7     100  
#> 3 centre    NA            1      25   100  NA        NA  
#> 4 satisfied No            1      25    25  33.3      33.3
#> 5 satisfied Yes           2      50    75  66.7     100  
#> 6 satisfied NA            1      25   100  NA        NA
```

Output options vary by function:

| Option | Where it is useful |
|----|----|
| `"vector"` | The default vector of names from [`ds()`](https://socimh.github.io/tidystata/reference/names.md). |
| `"list"` | Separate variable tables in [`tab1()`](https://socimh.github.io/tidystata/reference/tab.md)/[`fre1()`](https://socimh.github.io/tidystata/reference/tab.md), or type families in summaries. A single summary family returns one table. |
| `"table"` | One table in the input’s table class for [`ds()`](https://socimh.github.io/tidystata/reference/names.md), [`summ()`](https://socimh.github.io/tidystata/reference/summ.md) and [`tabstat()`](https://socimh.github.io/tidystata/reference/summ.md). |
| `"auto"` | Preserve the input’s table class in [`fre()`](https://socimh.github.io/tidystata/reference/tab.md), [`tab2()`](https://socimh.github.io/tidystata/reference/tab.md) and [`fre2()`](https://socimh.github.io/tidystata/reference/tab.md). |
| `"tibble"` | Explicit tibble output where supported; combines one-way variable tables or summary families. |
| `"flextable"` | Formatted output from supported tabulation functions, requiring the optional flextable package. |

[`tab()`](https://socimh.github.io/tidystata/reference/tab.md) has no
`.type` argument. Multiple-pair or explicitly grouped
[`tab2()`](https://socimh.github.io/tidystata/reference/tab.md)/[`fre2()`](https://socimh.github.io/tidystata/reference/tab.md)
calls still return lists: `.type` controls each table inside.
Correlations use `.wide` for layout; both layouts are tibbles.

## Separate grouping keys from measurements

A missing centre is still a group, and does not make its observed
response invalid:

``` r

survey |> tab(satisfied, .by = centre)
#> # A tibble: 4 × 7
#>   centre    satisfied     n percent   cum valid valid_cum
#>   <chr>     <chr>     <int>   <dbl> <dbl> <dbl>     <dbl>
#> 1 Hilltop   No            1     100   100   100       100
#> 2 Riverside Yes           1      50    50   100       100
#> 3 Riverside NA            1      50   100    NA        NA
#> 4 NA        Yes           1     100   100   100       100
```

The one-way/joint tabulation and summary families inherit
[`group_by()`](https://dplyr.tidyverse.org/reference/group_by.html)
groups unless `.by` replaces them. Their results are ungrouped.
Cross-tabulations require an explicit `.by` to split by group.

In summaries, `.missing = FALSE` drops missing grouping keys. Numeric
calculations always omit missing measured values. Tabulation percentages
use a 0-100 scale, while summary `valid_pct` uses 0-1. The dedicated
[tab](https://socimh.github.io/tidystata/articles/tabulation.md) and
[summ](https://socimh.github.io/tidystata/articles/summary-statistics.md)
articles demonstrate the denominators.

## Handle empty and all-missing measurements

An empty input and an all-missing measurement have no observed values.
They retain `n = 0` and undefined statistics, including `sum = NA`:

``` r

survey |>
  slice_head(n = 0) |>
  summ(score, .stat = c("n", "sum", "mean"))
#> # A tibble: 1 × 4
#>   type      n   sum  mean
#>   <chr> <int> <dbl> <dbl>
#> 1 dbl       0    NA    NA
```

Entirely missing summary columns emit a warning. A row sum follows a
different convention: adding no observed items gives zero. A row mean
stays missing.

``` r

tibble(item1 = c(NA_real_, 4), item2 = c(NA_real_, 6)) |>
  mutate(
    total = row_sum(pick(starts_with("item"))),
    average = row_mean(pick(starts_with("item")))
  )
#> # A tibble: 2 × 4
#>   item1 item2 total average
#>   <dbl> <dbl> <dbl>   <dbl>
#> 1    NA    NA     0      NA
#> 2     4     6    10       5
```

Empty selections produce empty tabulation results; row helpers need at
least one column. Matrix columns are unsupported by tabulation and
column summaries.

## Understand labels and special missing values

Variable labels describe columns; value labels describe particular
codes. An SPSS-style export might distinguish a refusal from an
unanswered question:

``` r

imported <- tibble(
  answer = haven::labelled_spss(
    c(1, 2, 99, NA),
    labels = c(Yes = 1, No = 2, Refused = 99),
    na_values = 99,
    label = "Course satisfaction"
  )
)

imported |> fre(answer)
#> # A tibble: 7 × 6
#>   answer            n percent   cum valid valid_cum
#>   <chr>         <int>   <dbl> <dbl> <dbl>     <dbl>
#> 1 Yes               1      25    25    50        50
#> 2 No                1      25    50    50       100
#> 3 Valid Total       2      50    NA   100        NA
#> 4 Refused           1      25    75    NA        NA
#> 5 NA                1      25   100    NA        NA
#> 6 Missing Total     2      50    NA    NA        NA
#> 7 Total             4     100    NA    NA        NA
```

Tabulations recognise ordinary, tagged and SPSS user-missing values as
missing. Numeric summaries exclude them from calculations.
[`decode()`](https://socimh.github.io/tidystata/reference/type_conversion.md)
reads value labels, but does not itself turn every labelled refusal into
ordinary `NA`. For calculations outside haven-aware functions,
explicitly normalise special missing values with
[`haven::zap_missing()`](https://haven.tidyverse.org/reference/zap_missing.html).

[`misstable()`](https://socimh.github.io/tidystata/reference/misstable.md)
also accepts matrix and nested data-frame columns. Ordinary list columns
count scalar `NA` elements as missing and `NULL` as observed. Structured
columns use vctrs row-missingness rules; list-backed matrices have
different cell conventions, detailed in the [missingness
reference](https://socimh.github.io/tidystata/reference/misstable.html).

## Keep calendar units visible

When numeric and calendar measurements occur together, default summaries
separate the type families. Here the date table’s SD retains duration
units:

``` r

visits <- tibble(
  score = c(4, 8),
  day = readr::parse_date(c("2026-09-01", "2026-09-03"))
)
separate <- visits |> summ(.stat = c("n", "mean", "sd"))
#> A list is returned as statistics are heterogeneous.

separate[["date"]]
#> # A tibble: 1 × 5
#>   name  type      n mean       sd           
#>   <chr> <chr> <int> <chr>      <drtn>       
#> 1 day   date      2 2026-09-02 1.414214 days
```

The numeric table keeps numeric statistics. In combined
`.type = "table"` or `"tibble"` output, shared location columns become
character. Spread columns become plain numbers: days for dates and
seconds for date-times, with units shown in `type`.

## Preview a table without removing rows

A longer course register is easier to inspect at its beginning and end:

``` r

register <- tibble(id = 1:12, points = (1:12)^2)
view <- register |> preview_headtail(n = 4)

view
#> # A tibble: 12 × 2
#>       id points
#>    <int>  <dbl>
#>  1     1      1
#>  2     2      4
#>  ⋮     ⋮      ⋮
#> 11    11    121
#> 12    12    144
#> # ... 8 rows omitted in the middle; use print(x, n = Inf) to show all rows.
```

The display budget is four data rows, with an omission marker between
the beginning and end. All twelve rows remain available for
calculations:

``` r

view |> summarise(participants = n(), total_points = sum(points))
#> # A tibble: 1 × 2
#>   participants total_points
#>          <int>        <dbl>
#> 1           12          650
```

For a view across the whole ordered register, use interval previews:

``` r

register |> preview_interval(n = 4)
#> # A tibble: 12 × 2
#>       id points
#>    <int>  <dbl>
#>  1     1      1
#>  5     5     25
#>  8     8     64
#> 12    12    144
#> # ... 8 rows omitted between displayed positions; use print(x, n = Inf) to show
#> # all rows.
```

Sort first when position should represent a meaningful order.
[`unpreview()`](https://socimh.github.io/tidystata/reference/preview.md)
removes the persistent display setting. Supported dplyr/tidyr operations
carry preview settings forward while following their own grouping and
container rules.

[`print_headtail()`](https://socimh.github.io/tidystata/reference/special-print.md)
and
[`print_interval()`](https://socimh.github.io/tidystata/reference/special-print.md)
print once and invisibly return the complete input. Wrapping and
unwrapping data.table inputs copies them; later native data.table
mutations follow ordinary reference semantics. If removing source
columns with `as_dummy(.remove = TRUE)` would leave a data.table with
rows but no columns, retain an identifier or another source column.
