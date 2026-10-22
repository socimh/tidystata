# Merge two tables with a Stata-style match report

`s_merge()` joins `using` onto `.data` like Stata's `merge`. It checks
the stated key relationship first, keeps master, using and matched rows
by default, reports how many rows fell into each group, and records the
result in a `.merge` column (Stata's `_merge`).

## Usage

``` r
s_merge(
  .data,
  using,
  relationship,
  by,
  keep = c("master", "using", "match"),
  assert = NULL,
  generate = ".merge",
  report = TRUE,
  .keep = lifecycle::deprecated(),
  .assert = lifecycle::deprecated(),
  .generate = lifecycle::deprecated(),
  .report = lifecycle::deprecated()
)
```

## Arguments

- .data:

  The master table: a data frame, tibble, or data.table.

- using:

  The table to merge in.

- relationship:

  The key relationship, as in Stata: `"1:1"` (keys unique in both
  tables), `"m:1"` (unique in `using`) or `"1:m"` (unique in `.data`).
  It is required and checked before joining. Many-to-many merges are not
  supported, as in Stata; use
  [`dplyr::inner_join()`](https://dplyr.tidyverse.org/reference/mutate-joins.html)
  with `relationship = "many-to-many"` if you really need all pairings.

- by:

  A character vector of key columns. Use a named vector, such as
  `c(id = "person_id")`, when the names differ (`.data` name = `using`
  name).

- keep:

  Which rows to keep: any of `"master"` (only in `.data`), `"using"`
  (only in `using`) and `"match"` (in both). Default keeps all, as Stata
  does.

- assert:

  `NULL` (default) or any of `"master"`, `"using"` and `"match"`. If
  given, every row must be in one of these groups, otherwise `s_merge()`
  errors, like Stata's
  [`assert()`](https://socimh.github.io/tidystata/reference/assert.md)
  option.

- generate:

  Name of the result column, `".merge"` by default. Use `NULL` to omit
  it (Stata's `nogenerate`).

- report:

  A single `TRUE` or `FALSE`. If `TRUE` (default), print the match
  report as a message.

- .keep, .assert, .generate, .report:

  **\[deprecated\]** Use `keep`, `assert`, `generate` and `report`
  instead.

## Value

The merged table, in the container of `.data`. Rows from `.data` come
first in their original order, followed by rows found only in `using`.
The `.merge` column is a factor with levels `"master only"`,
`"using only"` and `"matched"`.

## Details

Missing key values match each other, as in Stata. When a non-key column
exists in both tables, the values from `.data` are kept and the `using`
column is dropped with a message, as Stata does without `update`; rename
the column first to keep both. Grouping is not retained.

## See also

Other data checking functions:
[`assert()`](https://socimh.github.io/tidystata/reference/assert.md),
[`is_first()`](https://socimh.github.io/tidystata/reference/is_first.md),
[`keys`](https://socimh.github.io/tidystata/reference/keys.md)

## Examples

``` r
people <- tibble::tibble(id = 1:3, age = c(30, 41, 25))
income <- tibble::tibble(id = c(2, 3, 4), income = c(10, 20, 30))
s_merge(people, income, "1:1", by = "id")
#> Result                            Rows
#> --------------------------------------
#> Not matched                          2
#>     from master                      1  (.merge == "master only")
#>     from using                       1  (.merge == "using only")
#> 
#> Matched                              2  (.merge == "matched")
#> --------------------------------------
#> # A tibble: 4 × 4
#>      id   age income .merge     
#>   <dbl> <dbl>  <dbl> <fct>      
#> 1     1    30     NA master only
#> 2     2    41     10 matched    
#> 3     3    25     20 matched    
#> 4     4    NA     30 using only 

# Keep matched rows only, and insist that every person is matched
try(s_merge(people, income, "1:1", by = "id", assert = "match"))
#> Result                            Rows
#> --------------------------------------
#> Not matched                          2
#>     from master                      1  (.merge == "master only")
#>     from using                       1  (.merge == "using only")
#> 
#> Matched                              2  (.merge == "matched")
#> --------------------------------------
#> Error in s_merge(people, income, "1:1", by = "id", assert = "match") : 
#>   Merge assertion failed: found 1 master only row(s) and 1 using only
#> row(s); `assert` allows only matched.
s_merge(people, income, "1:1", by = "id", keep = "match", report = FALSE)
#> # A tibble: 2 × 4
#>      id   age income .merge 
#>   <dbl> <dbl>  <dbl> <fct>  
#> 1     2    41     10 matched
#> 2     3    25     20 matched

# Many people per household
members <- tibble::tibble(hh = c(1, 1, 2), person = 1:3)
households <- tibble::tibble(hh = 1:2, region = c("north", "south"))
s_merge(members, households, "m:1", by = "hh")
#> Result                            Rows
#> --------------------------------------
#> Not matched                          0
#>     from master                      0  (.merge == "master only")
#>     from using                       0  (.merge == "using only")
#> 
#> Matched                              3  (.merge == "matched")
#> --------------------------------------
#> # A tibble: 3 × 4
#>      hh person region .merge 
#>   <dbl>  <int> <chr>  <fct>  
#> 1     1      1 north  matched
#> 2     1      2 north  matched
#> 3     2      3 south  matched
```
