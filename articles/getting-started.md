# Getting started with tidystata

Did participants enjoy the community course? How did their assessment
scores compare across centres? tidystata helps answer these first
questions inside a tidyverse workflow: start with a tibble, inspect it,
prepare columns with
[`mutate()`](https://dplyr.tidyverse.org/reference/mutate.html), and
pass results to the next step with `|>`.

Install tidystata using the instructions on the [package
homepage](https://socimh.github.io/tidystata/). We attach dplyr and
tibble individually; the full tidyverse package is not required.

## Meet the survey

Twelve participants attended courses at Riverside and Hilltop. Each
answered a yes/no satisfaction question and two assessment items. Some
answers are missing, and income arrived as text.

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
)

survey |> codebook()
#> # A tibble: 6 × 4
#>   variable    type          n unique
#>   <chr>       <chr>     <int>  <int>
#> 1 id          double       12     12
#> 2 centre      character    12      2
#> 3 satisfied   character    10      2
#> 4 income_text character    11     11
#> 5 score1      double       10      8
#> 6 score2      double        9      7
```

There are six participants per centre. The codebook shows which columns
contain text, how many values are observed, and where the gaps are. An
identifier is numeric too, but we will select assessment items
deliberately when summarising.

## Prepare measurements with `mutate()`

The survey form uses `-99` for an undisclosed income. Read the numeric
text, turn that code into `NA`, and calculate an average across the two
assessment items.

``` r

prepared <- survey |>
  mutate(
    income = destring(income_text) |> mvdecode(-99),
    score = row_mean(pick(score1, score2)),
    answered = row_non_miss(pick(score1, score2))
  )

prepared |> select(id, income, score, answered)
#> # A tibble: 12 × 4
#>       id income score answered
#>    <dbl>  <dbl> <dbl>    <int>
#>  1     1   1200     3        2
#>  2     2   1500     4        1
#>  3     3     NA    NA        0
#>  4     4     NA     7        2
#>  5     5   2200     9        2
#>  6     6   1800     5        2
#>  7     7   1400     4        2
#>  8     8   2100     6        2
#>  9     9   2600     8        2
#> 10    10     NA     9        1
#> 11    11   2300     8        1
#> 12    12   1700     7        2
```

Participant 2 has one assessment answer, so the average uses that
answer. Participant 3 has none: the average is `NA` and `answered` is
zero.
[`destring()`](https://socimh.github.io/tidystata/reference/type_conversion.md)
also reads the thousands separators; blank text becomes missing.

## Count responses

How many participants were satisfied?

``` r

prepared |> tab(satisfied)
#> # A tibble: 3 × 6
#>   satisfied     n percent   cum valid valid_cum
#>   <chr>     <int>   <dbl> <dbl> <dbl>     <dbl>
#> 1 No            3    25    25      30        30
#> 2 Yes           7    58.3  83.3    70       100
#> 3 NA            2    16.7 100      NA        NA
```

Seven said yes. That is 58.3% of all twelve participants, or 70% of the
ten who answered. The `percent` and `valid` columns make both
denominators visible. The two missing answers remain a category.

Results are tibbles here, so ordinary dplyr verbs can answer a follow-up
question:

``` r

prepared |>
  tab(satisfied, .by = centre) |>
  filter(satisfied == "Yes") |>
  select(centre, n, valid)
#> # A tibble: 2 × 3
#>   centre        n valid
#>   <chr>     <int> <dbl>
#> 1 Hilltop       3    60
#> 2 Riverside     4    80
```

## Compare measurements

Now compare the assessment average across centres.

``` r

prepared |>
  summ(score, .by = centre, .stat = c("n", "mean", "sd"))
#> # A tibble: 2 × 5
#>   centre    type      n  mean    sd
#>   <chr>     <chr> <int> <dbl> <dbl>
#> 1 Hilltop   dbl       6   7    1.79
#> 2 Riverside dbl       5   5.6  2.41
```

Each mean uses the observed scores in that centre. The returned table is
ready for another pipeline; no results need to be copied out of console
output. Use
[`tabstat()`](https://socimh.github.io/tidystata/reference/summ.md) when
a compact table of means is enough.

## Choose the next question

- [Inspect and prepare
  data](https://socimh.github.io/tidystata/articles/inspect-and-prepare.md)
  follows the survey from unfamiliar columns to clean measurements,
  checked keys and follow-up records.
- [Tabulate and compare
  categories](https://socimh.github.io/tidystata/articles/tabulation.md)
  explains
  [`tab()`](https://socimh.github.io/tidystata/reference/tab.md),
  [`tab1()`](https://socimh.github.io/tidystata/reference/tab.md),
  [`tab2()`](https://socimh.github.io/tidystata/reference/tab.md) and
  the [`fre()`](https://socimh.github.io/tidystata/reference/tab.md)
  family in more depth.
- [Summarise
  measurements](https://socimh.github.io/tidystata/articles/summary-statistics.md)
  develops
  [`summ()`](https://socimh.github.io/tidystata/reference/summ.md) and
  [`tabstat()`](https://socimh.github.io/tidystata/reference/summ.md),
  then introduces correlations.
- [Containers, grouping and missing
  values](https://socimh.github.io/tidystata/articles/containers-and-missing-values.md)
  explains output conventions and special cases when you need them.

Coming from Stata? The [Stata
guide](https://socimh.github.io/tidystata/articles/coming-from-stata.html)
and `findit("tab satisfied")` help locate a familiar command’s R
equivalent.
