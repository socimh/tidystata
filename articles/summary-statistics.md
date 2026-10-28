# Summarise measurements

After counting satisfaction, the coordinator asks about assessment
scores and income.
[`summ()`](https://socimh.github.io/tidystata/reference/summ.md) gives a
first look at measurements;
[`tabstat()`](https://socimh.github.io/tidystata/reference/summ.md)
makes a compact table of means. Both fit into dplyr pipelines and return
results you can reuse.

## Start with meaningful measurements

Here are the same twelve participants from [Getting
started](https://socimh.github.io/tidystata/articles/getting-started.md),
with income already cleaned and the two assessment items retained.
Income is monthly; scores run from 0 to 10.

``` r

library(dplyr)
library(tibble)
library(tidystata)

survey <- tribble(
  ~id, ~centre,     ~income, ~score1, ~score2,
    1, "Riverside",    1200,       2,       4,
    2, "Riverside",    1500,       4,      NA,
    3, "Riverside",      NA,      NA,      NA,
    4, "Riverside",      NA,       6,       8,
    5, "Riverside",    2200,       8,      10,
    6, "Riverside",    1800,       4,       6,
    7, "Hilltop",      1400,       3,       5,
    8, "Hilltop",      2100,       5,       7,
    9, "Hilltop",      2600,       7,       9,
   10, "Hilltop",        NA,       9,      NA,
   11, "Hilltop",      2300,      NA,       8,
   12, "Hilltop",      1700,       6,       8
)

survey |> summ(income, starts_with("score"))
#> # A tibble: 3 × 8
#>   name   type      n unique   min    mean     sd   max
#>   <chr>  <chr> <int>  <int> <dbl>   <dbl>  <dbl> <dbl>
#> 1 income dbl       9      9  1200 1867.   464.    2600
#> 2 score1 dbl      10      8     2    5.4    2.22     9
#> 3 score2 dbl       9      7     4    7.22   1.92    10
```

The default columns show observed counts, distinct values, minimum,
mean, sample standard deviation and maximum. The selected measurements
have different observed counts because missingness differs across items.
We leave out `id`: being stored as a number does not make a column a
measurement.

## Ask for just the statistics you need

If the question is simply how average scores compare, start with
[`tabstat()`](https://socimh.github.io/tidystata/reference/summ.md):

``` r

survey |> tabstat(starts_with("score"), .by = centre)
#> # A tibble: 4 × 4
#>   centre    name   type   mean
#>   <chr>     <chr>  <chr> <dbl>
#> 1 Hilltop   score1 dbl     6  
#> 2 Hilltop   score2 dbl     7.4
#> 3 Riverside score1 dbl     4.8
#> 4 Riverside score2 dbl     7
```

It uses the same calculations as
[`summ()`](https://socimh.github.io/tidystata/reference/summ.md), but
reports only the mean by default. For a reporting table, choose
statistics and their order explicitly:

``` r

survey |>
  summ(income, .by = centre, .stat = c("n", "mean", "median", "sd"))
#> # A tibble: 2 × 6
#>   centre    type      n  mean median    sd
#>   <chr>     <chr> <int> <dbl>  <dbl> <dbl>
#> 1 Hilltop   dbl       5  2020   2100  476.
#> 2 Riverside dbl       4  1675   1650  427.
```

Missing measured values are omitted from each calculation. `sd` uses the
sample denominator, and undefined statistics are `NA`, for example an SD
based on one observation. Use `.detail = TRUE` to explore the full
supported set; `.stat` takes precedence when you supply it.

For completeness, ask for counts and the observed proportion together:

``` r

survey |>
  summ(starts_with("score"), .stat = c("n", "miss_n", "valid_pct", "mean"))
#> # A tibble: 2 × 6
#>   name   type      n miss_n valid_pct  mean
#>   <chr>  <chr> <int>  <int>     <dbl> <dbl>
#> 1 score1 dbl      10      2     0.833  5.4 
#> 2 score2 dbl       9      3     0.75   7.22
```

`miss_n` (also called `missing`) counts missing measurements.
`valid_pct` is a **0-1 proportion**, unlike the 0-100 percentages from
[`tab()`](https://socimh.github.io/tidystata/reference/tab.md).

## Calculate first, then summarise

Named expressions can create a column for this summary without changing
the source tibble:

``` r

survey |> summ(income_thousands = income / 1000, .by = centre)
#> # A tibble: 2 × 8
#>   centre    type      n unique   min  mean    sd   max
#>   <chr>     <chr> <int>  <int> <dbl> <dbl> <dbl> <dbl>
#> 1 Hilltop   dbl       5      5   1.4  2.02 0.476   2.6
#> 2 Riverside dbl       4      4   1.2  1.68 0.427   2.2
```

For a measurement that you will reuse, create it in
[`mutate()`](https://dplyr.tidyverse.org/reference/mutate.html). The row
average uses whichever assessment items are observed; it stays missing
when neither is.

``` r

scored <- survey |>
  mutate(score = row_mean(pick(score1, score2)))

scored |>
  summ(score, .by = centre, .stat = c("n", "mean", "sd")) |>
  arrange(desc(mean))
#> # A tibble: 2 × 5
#>   centre    type      n  mean    sd
#>   <chr>     <chr> <int> <dbl> <dbl>
#> 1 Hilltop   dbl       6   7    1.79
#> 2 Riverside dbl       5   5.6  2.41
```

The centre comparison now uses one score per participant. An explicit
`.name = TRUE` retains a `name` column even when summarising a single
variable.

## Make grouping choices explicit

[`summ()`](https://socimh.github.io/tidystata/reference/summ.md) and
[`tabstat()`](https://socimh.github.io/tidystata/reference/summ.md)
inherit
[`group_by()`](https://dplyr.tidyverse.org/reference/group_by.html)
groups, or accept `.by` for one operation. Their results are ungrouped.
An explicit `.by` replaces inherited groups. Computed expressions inside
[`summ()`](https://socimh.github.io/tidystata/reference/summ.md) are
evaluated before grouping; use grouped
[`mutate()`](https://dplyr.tidyverse.org/reference/mutate.html) first
for calculations that depend on each group’s values.

Suppose participant 12’s centre was not recorded. Keep that
participant’s measurement visible as a separate group:

``` r

unknown_centre <- scored |>
  mutate(centre = if_else(id == 12, NA_character_, centre))

unknown_centre |> summ(score, .by = centre, .stat = c("n", "mean"))
#> # A tibble: 3 × 4
#>   centre    type      n  mean
#>   <chr>     <chr> <int> <dbl>
#> 1 Hilltop   dbl       5   7  
#> 2 Riverside dbl       5   5.6
#> 3 NA        dbl       1   7
```

Use `.missing = FALSE` to exclude missing **grouping keys**:

``` r

unknown_centre |>
  summ(score, .by = centre, .missing = FALSE, .stat = c("n", "mean"))
#> # A tibble: 2 × 4
#>   centre    type      n  mean
#>   <chr>     <chr> <int> <dbl>
#> 1 Hilltop   dbl       5   7  
#> 2 Riverside dbl       5   5.6
```

That option does not change how missing measurements are handled.

## Read percentiles using Stata’s rule

Percentiles are useful when a mean hides a wide income distribution.
Request `median`, `q1`, `q3`, or percentiles such as `p10` and `p90`:

``` r

survey |> summ(income, .stat = c("n", "p10", "q1", "median", "q3", "p90"))
#> # A tibble: 1 × 7
#>   type      n   p10    q1 median    q3   p90
#>   <chr> <int> <dbl> <dbl>  <dbl> <dbl> <dbl>
#> 1 dbl       9  1200  1500   1800  2200  2600
```

These follow Stata’s percentile rule, which can differ from R’s default
[`quantile()`](https://rdrr.io/r/stats/quantile.html). A small example
makes the difference visible:

``` r

tibble(score = 1:4) |> summ(score, .stat = c("p25", "p50", "p75"))
#> # A tibble: 1 × 4
#>   type    p25   p50   p75
#>   <chr> <dbl> <dbl> <dbl>
#> 1 int     1.5   2.5   3.5
```

The quartiles are 1.5 and 3.5. For percentile-rank columns, use
[`dplyr::percent_rank()`](https://dplyr.tidyverse.org/reference/percent_rank.html);
for quantile groups, use
[`xtile()`](https://socimh.github.io/tidystata/reference/cut.md).
[`pc()`](https://socimh.github.io/tidystata/reference/std.md) instead
calculates each value’s percentage of a total.

## Distinguish frequency and analytic weights

Suppose an aggregate register has three score values and their
frequencies. Frequency weights reproduce the expanded participants:

``` r

register <- tribble(
  ~score, ~people,
       2,       3,
       6,       1,
      10,       1
)

register |>
  summ(score, .wt = people, .stat = c("n", "mean", "sd", "p50"))
#> # A tibble: 1 × 5
#>   type      n  mean    sd   p50
#>   <chr> <dbl> <dbl> <dbl> <dbl>
#> 1 dbl       5   4.4  3.58     2
```

The reported `n` is five. Analytic weights rescale to the observed row
count within each variable and group, changing the reported count and
sample SD:

``` r

register |>
  summ(
    score, .wt = people, .wt_type = "analytic",
    .stat = c("n", "mean", "sd")
  )
#> # A tibble: 1 × 4
#>   type      n  mean    sd
#>   <chr> <dbl> <dbl> <dbl>
#> 1 dbl       3   4.4  3.92
```

The mean agrees, but `n` is now three. Weights must be finite and
nonnegative; missing weights exclude rows with a message. These are
descriptive weighting rules, not design-based standard errors for a
complex survey.

## Choose a convenient return form

Numeric and calendar variables have different units, so the default
separates their summaries into a list when both families occur. Request
`.type = "tibble"` when you need one combined table:

``` r

visits <- tibble(
  score = c(4, 8),
  day = readr::parse_date(c("2026-09-01", "2026-09-03"))
)

visits |> summ(.type = "tibble", .stat = c("n", "min", "mean", "max"))
#> # A tibble: 2 × 6
#>   name  type      n min        mean       max       
#>   <chr> <chr> <int> <chr>      <chr>      <chr>     
#> 1 score dbl       2 4          6          8         
#> 2 day   date      2 2026-09-01 2026-09-02 2026-09-03
```

Shared location columns become character so they can hold numbers and
dates. The default separate tables preserve each family’s statistic
types. See the [conventions
guide](https://socimh.github.io/tidystata/articles/containers-and-missing-values.md)
for calendar spread units and container preservation.

Unsupported non-numeric columns are omitted with a message.
`.keep_all = TRUE` keeps them for counts and distinct values. Labelled
numeric variables use their codes; factors use level codes and produce a
message. Select meaningful measurements instead of averaging category
codes. Entirely missing columns still warn and remain with `n = 0` and
`NA` statistics, including `sum`; `.drop_empty = TRUE` omits those rows.

## Look at relationships next

Do income and the two assessment items move together?
[`corr()`](https://socimh.github.io/tidystata/reference/corr.md) uses
one common complete sample across all selected columns:

``` r

survey |> corr(income, score1, score2)
#> # A tibble: 3 × 4
#>   var1   var2       r     n
#>   <chr>  <chr>  <dbl> <int>
#> 1 income score1 0.847     7
#> 2 income score2 0.847     7
#> 3 score1 score2 1         7
```

[`pwcorr()`](https://socimh.github.io/tidystata/reference/corr.md)
instead uses the available observations for each pair, reporting counts
and p-values:

``` r

survey |> pwcorr(income, score1, score2)
#> # A tibble: 3 × 5
#>   var1   var2       r     n        p
#>   <chr>  <chr>  <dbl> <int>    <dbl>
#> 1 income score1 0.850     8 7.47e- 3
#> 2 income score2 0.845     8 8.25e- 3
#> 3 score1 score2 1         8 2.74e-47
```

Compare the `n` columns: changing the missing-data rule changes which
participants contribute. `pwcorr(.listwise = TRUE)` uses a common
sample.
[`spearman()`](https://socimh.github.io/tidystata/reference/corr.md)
computes rank correlations on a common sample by default, with
`.pairwise = TRUE` for pairwise samples. The tiny survey illustrates the
interfaces, not evidence about programme effects. See the [correlation
reference](https://socimh.github.io/tidystata/reference/corr.html) for
additional options.

Return to [data
preparation](https://socimh.github.io/tidystata/articles/inspect-and-prepare.md)
to build measurements, or use [category
tables](https://socimh.github.io/tidystata/articles/tabulation.md) for
responses that are categories.
