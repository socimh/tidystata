# Inspect and prepare data

A course coordinator sends you a survey spreadsheet. Before comparing
the centres, you need to understand its columns, clean its measurements
and check that the records fit together. This guide introduces that
workflow; each function’s reference page covers its additional options.

## Find your way around

Here are the twelve participants from [Getting
started](https://socimh.github.io/tidystata/articles/getting-started.md).
The two scores are assessment items, and `-99` means income was
undisclosed.

``` r

library(dplyr)
library(tibble)
library(tidystata)

survey <- tribble(
  ~id, ~centre,     ~satisfied, ~income_text, ~score1, ~score2,
    1, "Riverside", "Yes",     "1,200",           2,       4,
    2, "Riverside", "Yes",     "1,500",           4,      NA,
    3, "Riverside", "No",      "",               NA,      NA,
    4, "Riverside", NA,        "-99",             6,       8,
    5, "Riverside", "Yes",     "2,200",           8,      10,
    6, "Riverside", "Yes",     "1,800",           4,       6,
    7, "Hilltop",   "No",      "1,400",           3,       5,
    8, "Hilltop",   "Yes",     "2,100",           5,       7,
    9, "Hilltop",   "No",      "2,600",           7,       9,
   10, "Hilltop",   "Yes",     NA,                9,      NA,
   11, "Hilltop",   "Yes",     "2,300",          NA,       8,
   12, "Hilltop",   NA,        "1,700",           6,       8
) |>
  mutate(score1 = haven::labelled(score1, label = "First assessment item"))

survey |> variables()
#> # A tibble: 6 × 2
#>   name        label                
#>   <chr>       <chr>                
#> 1 id          NA                   
#> 2 centre      NA                   
#> 3 satisfied   NA                   
#> 4 income_text NA                   
#> 5 score1      First assessment item
#> 6 score2      NA
```

[`variables()`](https://socimh.github.io/tidystata/reference/variables.md)
pairs column names with their labels. Search the descriptions when a
large file has names that are hard to remember:

``` r

survey |> variables_search("assessment")
#> # A tibble: 1 × 2
#>   name   label                
#>   <chr>  <chr>                
#> 1 score1 First assessment item
```

Use [`ds()`](https://socimh.github.io/tidystata/reference/names.md) for
a vector of matching names, or
[`codebook()`](https://socimh.github.io/tidystata/reference/codebook.md)
for types and counts. The same tidy selection works when inspecting or
calculating:

``` r

survey |>
  select_or_transmute(id, starts_with("score"), income = destring(income_text))
#> # A tibble: 12 × 4
#>       id score1    score2 income
#>    <dbl> <dbl+lbl>  <dbl>  <dbl>
#>  1     1  2             4   1200
#>  2     2  4            NA   1500
#>  3     3 NA            NA     NA
#>  4     4  6             8    -99
#>  5     5  8            10   2200
#>  6     6  4             6   1800
#>  7     7  3             5   1400
#>  8     8  5             7   2100
#>  9     9  7             9   2600
#> 10    10  9            NA     NA
#> 11    11 NA             8   2300
#> 12    12  6             8   1700
```

[`select_or_transmute()`](https://socimh.github.io/tidystata/reference/select_or_transmute.md)
combines selecting existing columns and computing new ones.
`varlist("score*")` offers Stata-style wildcard selection; ordinary
[`starts_with()`](https://tidyselect.r-lib.org/reference/starts_with.html)
works throughout this guide. For an interactive spreadsheet view, use
[`browse()`](https://socimh.github.io/tidystata/reference/browse.md) in
your own session.

## Clean values before calculating

Read the income strings and replace the sentinel. Use
[`across()`](https://dplyr.tidyverse.org/reference/across.html) to apply
a conversion to several columns when needed.

``` r

clean <- survey |>
  mutate(income = destring(income_text) |> mvdecode(-99))

clean |> misstable(income, starts_with("score"))
#> # A tibble: 3 × 4
#>   variable miss_n miss_pct valid_n
#>   <chr>     <int>    <dbl>   <int>
#> 1 income        3     25         9
#> 2 score1        2     16.7      10
#> 3 score2        3     25         9
```

The income column now has three missing values: a blank answer, the
sentinel and an original `NA`. Use
[`na_if_value()`](https://socimh.github.io/tidystata/reference/na_conversion.md)
for the corresponding single-value replacement.
[`mvencode()`](https://socimh.github.io/tidystata/reference/na_conversion.md)
and
[`value_if_na()`](https://socimh.github.io/tidystata/reference/na_conversion.md)
go in the other direction when an export needs a sentinel; keep ordinary
`NA` values for calculations.

Category codes need a different decision.
[`encode()`](https://socimh.github.io/tidystata/reference/type_conversion.md)
gives text categories labelled integer codes.
[`decode()`](https://socimh.github.io/tidystata/reference/type_conversion.md)
reads those labels back;
[`tostring()`](https://socimh.github.io/tidystata/reference/type_conversion.md)
and its alias
[`as_character()`](https://socimh.github.io/tidystata/reference/type_conversion.md)
instead return the stored codes as text.

``` r

clean |>
  mutate(
    centre_code = encode(centre),
    centre_label = decode(centre_code),
    code_text = tostring(centre_code)
  ) |>
  distinct(centre, centre_code, centre_label, code_text)
#> # A tibble: 2 × 4
#>   centre    centre_code   centre_label code_text
#>   <chr>     <int+lbl>     <chr>        <chr>    
#> 1 Riverside 2 [Riverside] Riverside    2        
#> 2 Hilltop   1 [Hilltop]   Hilltop      1
```

Encode before grouping so all centres share one coding dictionary. Keep
exact identifiers as text from import, rather than converting rounded
numbers back to strings.

## Create measurements inside `mutate()`

How many assessment items did each participant answer, and what was
their average? Row helpers work directly with the columns selected by
[`pick()`](https://dplyr.tidyverse.org/reference/pick.html).

``` r

prepared <- clean |>
  mutate(
    score = row_mean(pick(score1, score2)),
    answered = row_non_miss(pick(score1, score2)),
    score_z = std(score)
  )

prepared |> select(id, starts_with("score"), answered)
#> # A tibble: 12 × 6
#>       id score1    score2 score score_z answered
#>    <dbl> <dbl+lbl>  <dbl> <dbl>   <dbl>    <int>
#>  1     1  2             4     3  -1.59         2
#>  2     2  4            NA     4  -1.12         1
#>  3     3 NA            NA    NA  NA            0
#>  4     4  6             8     7   0.302        2
#>  5     5  8            10     9   1.25         2
#>  6     6  4             6     5  -0.646        2
#>  7     7  3             5     4  -1.12         2
#>  8     8  5             7     6  -0.172        2
#>  9     9  7             9     8   0.775        2
#> 10    10  9            NA     9   1.25         1
#> 11    11 NA             8     8   0.775        1
#> 12    12  6             8     7   0.302        2
```

The all-missing participant keeps an `NA` average.
[`std()`](https://socimh.github.io/tidystata/reference/std.md) expresses
the observed averages in sample standard deviations. Related row helpers
calculate sums, minima, maxima and missing counts without a
[`rowwise()`](https://dplyr.tidyverse.org/reference/rowwise.html) step.

For a simple reporting band, recode ranges and then display their
labels:

``` r

prepared |>
  mutate(band = stata_recode(score, Lower = min:5 ~ 1, Higher = 5:max ~ 2)) |>
  fre(band)
#> # A tibble: 5 × 6
#>   band            n percent   cum valid valid_cum
#>   <chr>       <int>   <dbl> <dbl> <dbl>     <dbl>
#> 1 Lower           4   33.3   33.3  36.4      36.4
#> 2 Higher          7   58.3   91.7  63.6     100  
#> 3 Valid Total    11   91.7   NA   100        NA  
#> 4 NA              1    8.33 100    NA        NA  
#> 5 Total          12  100     NA    NA        NA
```

Rules are applied in order, so a score of exactly 5 belongs to Lower.
[`xtile()`](https://socimh.github.io/tidystata/reference/cut.md) makes
quantile groups while keeping ties together;
[`cut_breaks()`](https://socimh.github.io/tidystata/reference/cut.md)
uses chosen boundaries and
[`cut_length()`](https://socimh.github.io/tidystata/reference/cut.md)
equal-width intervals. For indicator columns, use
[`as_dummy()`](https://socimh.github.io/tidystata/reference/as_dummy.md)
(also called
[`tab_gen()`](https://socimh.github.io/tidystata/reference/as_dummy.md));
its `.names` option selects value-, index- or label-based names.

## Check records before combining them

A participant ID should identify one survey row.
[`isid()`](https://socimh.github.io/tidystata/reference/keys.md)
confirms the key and passes the data along;
[`assert()`](https://socimh.github.io/tidystata/reference/assert.md)
checks a condition inside the pipeline.

``` r

prepared |>
  isid(id) |>
  assert(is.na(score) | (score >= 0 & score <= 10)) |>
  select(id, score) |>
  print_headtail(n = 4)
#> Variable `id` uniquely identifies the rows.
#> # A tibble: 12 × 2
#>       id score
#>    <dbl> <dbl>
#>  1     1     3
#>  2     2     4
#>  ⋮     ⋮     ⋮
#> 11    11     8
#> 12    12     7
#> # ... 8 rows omitted in the middle; use print(x, n = Inf) to show all rows.
```

If an import contains repeated records, start with
[`duplicates_report()`](https://socimh.github.io/tidystata/reference/keys.md)
and inspect them with
[`duplicates_list()`](https://socimh.github.io/tidystata/reference/keys.md).
[`duplicates_tag()`](https://socimh.github.io/tidystata/reference/keys.md)
marks them, and
[`duplicates_drop()`](https://socimh.github.io/tidystata/reference/keys.md)
keeps the first after you decide which rows are redundant.

Now attach the number of course sessions offered by each centre. Declare
the many-participants-to-one-centre relationship and require a match for
every row.

``` r

centres <- tribble(
  ~centre,     ~sessions,
  "Riverside",         8,
  "Hilltop",          10
)

prepared |>
  stata_merge(centres, "m:1", by = "centre", assert = "match") |>
  select(id, centre, sessions, .merge) |>
  print_headtail(n = 4)
#> Result                            Rows
#> --------------------------------------
#> Not matched                          0
#>     from master                      0  (.merge == "master only")
#>     from using                       0  (.merge == "using only")
#> 
#> Matched                             12  (.merge == "matched")
#> --------------------------------------
#> # A tibble: 12 × 4
#>       id centre    sessions .merge 
#>    <dbl> <chr>        <dbl> <fct>  
#>  1     1 Riverside        8 matched
#>  2     2 Riverside        8 matched
#>  ⋮     ⋮     ⋮            ⋮    ⋮   
#> 11    11 Hilltop         10 matched
#> 12    12 Hilltop         10 matched
#> # ... 8 rows omitted in the middle; use print(x, n = Inf) to show all rows.
```

The `.merge` column records match status. Use dplyr joins for ordinary
joins;
[`stata_merge()`](https://socimh.github.io/tidystata/reference/stata_merge.md)
is useful when you also want Stata-style match reporting and checks.

## Follow participants over time

A later survey creates a panel. Participant 1 misses wave 2: the change
from the previous wave should therefore be missing at wave 3.

``` r

followup <- tribble(
  ~id, ~wave, ~score,
    1,     1,      3,
    1,     3,      7,
    2,     1,      4,
    2,     2,      6
)

followup |>
  isid(id, wave) |>
  mutate(
    previous = stata_lag(score, time = wave),
    change = stata_diff(score, time = wave),
    .by = id
  )
#> Variables `id`, `wave` together uniquely identify the rows.
#> # A tibble: 4 × 5
#>      id  wave score previous change
#>   <dbl> <dbl> <dbl>    <dbl>  <dbl>
#> 1     1     1     3       NA     NA
#> 2     1     3     7       NA     NA
#> 3     2     1     4       NA     NA
#> 4     2     2     6        4      2
```

These helpers find the previous *period*, whereas
[`dplyr::lag()`](https://dplyr.tidyverse.org/reference/lead-lag.html)
finds the previous row.
[`stata_lead()`](https://socimh.github.io/tidystata/reference/panel.md)
looks ahead by period. Always identify the panel in `.by` or
[`group_by()`](https://dplyr.tidyverse.org/reference/group_by.html).

## Keep exploring

Use [category
tables](https://socimh.github.io/tidystata/articles/tabulation.md) to
compare responses and [measurement
summaries](https://socimh.github.io/tidystata/articles/summary-statistics.md)
to compare scores and incomes.
[`preview()`](https://socimh.github.io/tidystata/reference/preview.md)
controls a table’s continuing display, while
[`print_headtail()`](https://socimh.github.io/tidystata/reference/special-print.md)
and
[`print_interval()`](https://socimh.github.io/tidystata/reference/special-print.md)
print it briefly once; all retain the complete data. See the
[conventions
guide](https://socimh.github.io/tidystata/articles/containers-and-missing-values.md)
for details.

For occasional workflow tasks, the reference covers reproducible draws
with
[`set_seed()`](https://socimh.github.io/tidystata/reference/set_seed.md),
timing with
[`timer()`](https://socimh.github.io/tidystata/reference/timer.md), and
continuing after an optional expression fails with
[`capture()`](https://socimh.github.io/tidystata/reference/capture.md).
To find a familiar Stata operation, try `findit("tab satisfied")`;
editor and clipboard helpers are also available.
