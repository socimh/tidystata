# Find R equivalents of Stata commands

`findit()` looks up Stata commands and their R equivalents, including
functions from tidystata and other packages. It also supports reverse
lookup from R functions, keyword searches, and plain-language questions.
Omit the query to browse all entries.

## Usage

``` r
findit(command = NULL, ...)
```

## Arguments

- command:

  A Stata command, R function, or search phrase. Supply a bare name
  (`findit(reg)`, `findit(left_join)`) or a quoted string for full
  syntax (`findit("merge 1:1 id, keep(match)")`). R function names may
  include `()` or a namespace prefix. Use `!!cmd` to look up a string
  stored in `cmd`. Defaults to `NULL` (all entries).

- ...:

  Optional variable names or command hints, captured without evaluation.
  Names customize examples in Stata operand order, while hints
  prioritize examples (`findit(tab, gen)`). Hints accept exact or
  unambiguous prefixes of at least three letters. Quote names that
  conflict with hints (`findit(tab, "gen")`). Use `!!` for stored
  strings. Only unnamed names and strings are accepted.

## Value

A tibble of class `tidystata_findit` with one row per matching Stata
idiom and five columns: `match` (match type), `stata` (Stata code), `r`
(equivalent R code), `package` (primary R package), and `task`
(description). All matches are returned, even when fewer are printed. If
nothing matches, an empty tibble is returned invisibly with an
explanatory message.

## Details

**Matching**

- Stata abbreviations are recognized (`reg`, `regr`, `regress`), while R
  functions require their full names. Exact-case matches take priority.
  Shared names, such as `log`, show both Stata and R interpretations.

- Stata command matches appear before R function matches. Keyword
  searches are used when neither matches. Additional syntax and hints
  refine the ranking without discarding matches. `by` and `bysort`
  prefixes prioritize grouped operations.

- Plain-language questions use deterministic keyword and synonym
  matching in English or Chinese, without a language model.

**Output**

- Results print as readable Stata/R code pairs. A single clear match is
  shown alone; otherwise, up to five representative examples appear. Use
  `print(n = Inf)` to display all matches.

- The `match` column identifies the lookup type: `"stata"`, `"r"`,
  `"keyword"`, `"nearest"`, or `"all"`.

- Supplied variable names customize compatible examples. Unresolved
  placeholders and unsupported combinations are explained in notes.

**Notes**

- Quote multiword Stata syntax, reserved words (`"if"`), and names that
  are not valid R symbols (`"_n"`).

- Lookup works offline. External packages such as fixest, modelsummary,
  and srvyr are needed only when running their examples.

- Chinese descriptions follow R's language settings. Use
  `Sys.setenv(LANGUAGE = "en")` to switch to English.

- The reference is curated, not a parser or executor for arbitrary Stata
  programs. See the "Coming from Stata" articles for further guidance.

## Examples

``` r
findit(reg)
#> # Linear regression [stats]
#> Stata: regress y x1 x2
#> R:     fit <- lm(y ~ x1 + x2, data = data)
#> # Note: summary(fit) shows the coefficient table; broom::tidy(fit) returns it as a data frame.
#> 
#> # 17 more examples. To see them all: findit(reg) |> print(n = Inf)

findit(tab, gen)
#> # Dummy variables for every category [tidystata]
#> Stata: tabulate x, generate(x_)
#> R:     as_dummy(data, x)
#> # Note: as_dummy(data, x, .names = "index") numbers the columns x_1, x_2, ... as Stata does. Also: fastDummies::dummy_cols(data, "x"). as_dummy() defaults to value-based column names; .names = "index" gives numbered Stata-style suffixes. Check the missing-category indicator policy too.
#> 
#> # 20 more examples. To see them all: findit(tab, gen) |> print(n = Inf)

findit(tab, sex, region)
#> # Two-way cross-tabulation [tidystata]
#> Stata: tabulate sex region
#> R:     tab2(data, sex, region)
#> # Note: fre2(data, x1, x2) adds row and column totals. tidystata retains missing categories by default; Stata tabulate excludes them unless missing is specified. Use .missing = FALSE to match Stata.
#> 
#> # 20 more examples. To see them all: findit(tab, sex, region) |> print(n = Inf)

findit("merge 1:1 id, keep(match)")
#> # Keep matched rows only [dplyr]
#> Stata: merge 1:1 id using data2, keep(match)
#> R:     inner_join(data1, data2, by = "id")
#> # Note: dplyr retains overlapping non-key columns with suffixes instead of Stata master values, creates no _merge, and does not enforce a declared 1:1 key constraint.
#> 
#> # merge() [base]: Merge two data frames (base R)
#>   Related Stata: merge
#> 
#> # 17 more examples. To see them all: findit("merge 1:1 id, keep(match)") |> print(n = Inf)

findit("how do I remove duplicate rows")
#> # Closest entries for "how do I remove duplicate rows"
#> 
#> # Drop rows that duplicate an earlier row [tidystata]
#> Stata: duplicates drop
#> R:     duplicates_drop(data)
#> 
#> # 9 more examples. To see them all: findit("how do I remove duplicate rows") |> print(n = Inf)

findit(left_join)
#> # Keep all rows of the master data [dplyr]
#> Stata: merge 1:1 id using data2, keep(master match)
#> R:     left_join(data1, data2, by = "id")
#> # Note: dplyr retains overlapping non-key columns with suffixes instead of Stata master values, creates no _merge, and does not enforce a declared 1:1 key constraint.
#> 
#> # 3 more examples. To see them all: findit(left_join) |> print(n = Inf)

# Filter the complete reference
entries <- findit()
entries |>
  dplyr::filter(package == "tidystata")
#> # Find the R equivalent of a Stata command [tidystata]
#> Stata: findit command
#> R:     findit(command)
#> # Note: Bare words and comma-separated names work: findit(tab, sex, region). Add hints such as findit(tab, gen), or quote full Stata syntax. One clear example is shown by default; print(n = Inf) reveals every match. findit() with no argument returns the whole list.
#> 
#> # 80 more examples. To see them all: findit() |> print(n = Inf)
```
