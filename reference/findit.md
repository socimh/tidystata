# Find R equivalents of Stata commands

Look up Stata commands and their R equivalents in tidystata and other
packages.

- `findit()`: Search by Stata command, R function, keyword or
  plain-language question. Omit the query to browse all entries.

- `findit_selection()`: Look up highlighted Stata text in the source
  editor.

- `findit_clip()`: Look up Stata text copied to the clipboard.

## Usage

``` r
findit(command = NULL, ...)

findit_selection()

findit_clip()
```

## Arguments

- command:

  A Stata command, R function, or search phrase. Supply a bare name
  (`findit(reg)`, `findit(left_join)`) or a quoted string for full
  syntax (`findit("merge 1:1 id, keep(match)")`). R function names may
  include `()` or a namespace prefix. Use `!!cmd` to look up a string
  stored in `cmd`. Stata text can also be enclosed in backticks, as in
  `` findit(`tab sex region`, row) ``. Recognized variable names and
  options customize matching examples. Defaults to `NULL` (all entries).

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
(description). The returned object contains every selected match,
including any hidden by printing. If nothing matches, a zero-row result
with the same columns and class is returned invisibly with an
explanatory message. `findit_selection()` and `findit_clip()` print the
result once and return it invisibly.

## Details

**Choosing a match**

Bare Stata commands return their whole command family. A specific query
returns one preferred answer when the match is clear, or up to ten
relevant candidates when ambiguous. An omitted query returns the full
reference.

Stata abbreviations (`reg`, `regr`, `regress`) are accepted; R functions
need their full names. Exact-case matches take priority. Shared names
such as `log` include both interpretations, with Stata matches first.
When neither matches, lookup searches keywords. Plain-language questions
use curated English and Chinese keywords and synonyms.

Syntax and hints refine the ranking; `by` and `bysort` favor grouped
operations. Within the same operation, tidystata examples come first,
followed by tidyverse, then other packages or base R. Supplied variable
names customize compatible examples. Unfamiliar syntax keeps generic
examples; notes explain unresolved placeholders or unsupported
combinations.

**Reading the result**

Results print as Stata/R code pairs: one clear match or up to five
representative examples. Use `print(n = Inf)` to show every returned
match. Footers distinguish hidden candidates from broader command-family
examples and indicate when the ten-candidate limit applies. Specific
queries exclude unrelated family entries.

Printing omits package labels and unnecessary prefixes for R's default
packages, but keeps ambiguous names such as
[`stats::filter()`](https://rdrr.io/r/stats/filter.html) qualified.
Returned code and package metadata are unchanged. The `match` column
records `"stata"`, `"r"`, `"keyword"`, `"nearest"` or `"all"`.

**Editor and clipboard**

Select or copy one nonempty Stata command. `findit_selection()` also
runs through the **Find Stata equivalent** addin; it needs rstudioapi
and a source-selection API, as in RStudio or a compatible Positron
session. `findit_clip()` needs clipr and access to a text clipboard.
Both preserve the original text and print the lookup result without
executing any code.

**Text input and language**

Quote multiword syntax, reserved words (`"if"`) and non-R names
(`"_n"`). Backticks accept the same Stata text as strings, preserving
internal quotes. If the Stata text itself contains backticks, use an R
string or raw string.

Lookup works offline; external packages are needed only to run their
examples. Descriptions follow R's language settings;
`Sys.setenv(LANGUAGE = "en")` switches Chinese descriptions to English.
This curated reference does not parse or execute arbitrary Stata
programs. See the "Coming from Stata" articles for guidance.

## Examples

``` r
findit(reg)
#> # Linear regression
#> Stata: regress y x1 x2
#> R:     fit <- lm(y ~ x1 + x2, data = data)
#> # Note: summary(fit) shows the coefficient table; broom::tidy(fit) returns it as a data frame.
#> 
#> # Fit linear regression through the origin
#> Stata: regress y x z, noconstant
#> R:     lm(y ~ x + z - 1, data=data)
#> # Note: OLS coefficient correspondence requires the same complete-case sample, contrasts and weights. R returns an lm object; Stata coefficient tables and stored estimates have a different structure.
#> 
#> # Include two continuous main effects and their interaction
#> Stata: regress y c.x##c.z
#> R:     lm(y ~ x * z, data=data)
#> # Note: OLS coefficient correspondence requires the same complete-case sample, contrasts and weights. R returns an lm object; Stata coefficient tables and stored estimates have a different structure.
#> 
#> # Fit a quadratic regression
#> Stata: regress y c.x##c.x
#> R:     lm(y ~ x + I(x^2), data=data)
#> # Note: OLS coefficient correspondence requires the same complete-case sample, contrasts and weights. R returns an lm object; Stata coefficient tables and stored estimates have a different structure.
#> 
#> # Adjust regression for a categorical predictor
#> Stata: regress y i.g c.x
#> R:     lm(y ~ factor(g) + x, data=data)
#> # Note: OLS coefficient correspondence requires the same complete-case sample, contrasts and weights. R returns an lm object; Stata coefficient tables and stored estimates have a different structure.
#> 
#> # 13 more relevant examples. To see them all: findit(reg) |> print(n = Inf)

findit(tab, gen)
#> # Dummy variables for every category [tidystata]
#> Stata: tabulate x, generate(x_)
#> R:     as_dummy(data, x)
#> # Note: as_dummy(data, x, .names = "index") numbers the columns x_1, x_2, ... as Stata does. Also: fastDummies::dummy_cols(data, "x"). as_dummy() defaults to value-based column names; .names = "index" gives numbered Stata-style suffixes. Check the missing-category indicator policy too.
#> 
#> # 1 more relevant example. To see them all: findit(tab, gen) |> print(n = Inf)
#> # 26 broader tabulate examples. Browse the family: findit(tabulate)

findit(tab, sex, region)
#> # Two-way cross-tabulation [tidystata]
#> Stata: tabulate sex region
#> R:     tab2(data, sex, region)
#> # Note: fre2(data, x1, x2) adds row and column totals. tidystata retains missing categories by default; Stata tabulate excludes them unless missing is specified. Use .missing = FALSE to match Stata. tab2() and fre2() need explicit .by for grouped tables; inherited grouping columns otherwise remain ordinary variables. fre2() displays row value labels, while column headers retain category codes.
#> 
#> # 9 more relevant examples. To see them all: findit(tab, sex, region) |> print(n = Inf)
#> # Only the 10 best candidates are retained; refine the query for a closer match.
#> # 8 broader tabulate examples. Browse the family: findit(tabulate)

findit(`tab sex region`, row)
#> # Compute percentages within each table row [dplyr]
#> Stata: tabulate sex region, row
#> R:     dplyr::mutate(dplyr::count(data, sex, region), percent = 100 * n / sum(n), .by = sex)
#> # Note: Returns one row per observed combination; empty cells are omitted.
#> 
#> # 26 broader tabulate examples. Browse the family: findit(tabulate)

findit("tab sex region, row")
#> # Compute percentages within each table row [dplyr]
#> Stata: tabulate sex region, row
#> R:     dplyr::mutate(dplyr::count(data, sex, region), percent = 100 * n / sum(n), .by = sex)
#> # Note: Returns one row per observed combination; empty cells are omitted.
#> 
#> # 26 broader tabulate examples. Browse the family: findit(tabulate)

findit("merge 1:1 id, keep(match)")
#> # Keep matched rows only [dplyr]
#> Stata: merge 1:1 id using data2, keep(match)
#> R:     inner_join(data1, data2, by = "id")
#> # Note: dplyr retains overlapping non-key columns with suffixes instead of Stata master values, creates no _merge, and does not enforce a declared 1:1 key constraint.
#> 
#> # merge(): Merge two data frames (base R)
#>   Related Stata: merge
#> 
#> # 12 broader merge examples. Browse the family: findit(merge)
#> 
#> # This syntax could not be customized; examples retain generic placeholders.

findit("how do I remove duplicate rows")
#> # Closest entries for "how do I remove duplicate rows"
#> 
#> # Drop rows that duplicate an earlier row [tidystata]
#> Stata: duplicates drop
#> R:     duplicates_drop(data)
#> 
#> # 9 more relevant examples. To see them all: findit("how do I remove duplicate rows") |> print(n = Inf)
#> # Only the 10 best candidates are retained; refine the query for a closer match.

findit(left_join)
#> # Keep all rows of the master data [dplyr]
#> Stata: merge 1:1 id using data2, keep(master match)
#> R:     left_join(data1, data2, by = "id")
#> # Note: dplyr retains overlapping non-key columns with suffixes instead of Stata master values, creates no _merge, and does not enforce a declared 1:1 key constraint.
#> 
#> # 3 more relevant examples. To see them all: findit(left_join) |> print(n = Inf)

# Filter the complete reference
entries <- findit()
entries |>
  dplyr::filter(package == "tidystata")
#> # Find the R equivalent of a Stata command [tidystata]
#> Stata: findit command
#> R:     findit(command)
#> # Note: Bare words and comma-separated names work: findit(tab, sex, region). Add hints such as findit(tab, gen), or quote full Stata syntax. A bare command browses its whole family and shows up to five operations; a clear specific query returns one answer, and ambiguous queries retain up to ten relevant candidates. print(n = Inf) expands the returned results; use the bare command for broader family operations. Within a matching operation, recommendations prefer tidystata, then tidyverse, then other packages or base R. findit() with no argument returns the whole catalogue.
#> 
#> # 143 more relevant examples. To see them all: findit() |> print(n = Inf)

if (FALSE) { # \dontrun{
# Highlight tab sex region, row in the source editor, then run:
findit_selection()

# Copy tab sex region, row to the clipboard, then run:
findit_clip()
} # }
```
