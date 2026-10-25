# Find the R equivalent of a Stata command

`findit()` looks up a Stata command and returns the R code that does the
same job, whether a tidystata function or one from another package. It
covers everyday data work (browsing, tabulating, generating, merging,
reshaping) and points to the packages tidystata leaves to others, such
as fixest for `reghdfe`, modelsummary for `esttab`, binsreg for
`binscatter` and srvyr for `svy`.

It also works the other way round: give it an R function, such as
`findit(left_join)`, and it describes the function and lists the Stata
commands it replaces. Beginners need not know which is which; a word
that is both, such as `log` or `round`, shows both meanings.

Type a single word bare, as in `findit(reg)`, add names and hints with
commas, as in `findit(tab, sex, region)` or `findit(tab, gen)`, or quote
full Stata syntax, as in `findit("merge 1:1 id, keep(match)")`. Call
`findit()` with no argument for the whole list.

## Usage

``` r
findit(command = NULL, ...)
```

## Arguments

- command:

  A Stata command or an R function name, either one bare word
  (`findit(tab)`, `findit(left_join)`) or a quoted string
  (`findit("bysort g: egen m = mean(x)")`). R functions may also be
  written as [`lm()`](https://rdrr.io/r/stats/lm.html) or
  [`dplyr::left_join`](https://dplyr.tidyverse.org/reference/mutate-joins.html).
  Use `!!` to look up a string stored in a variable: `findit(!!cmd)`.
  `NULL` (default) returns every entry.

- ...:

  Unnamed variable names and command hints, captured without evaluation.
  Names customize examples in Stata operand order, including new output
  variables: `findit(xtile, quartile, income)`. A bare hint such as
  `gen` selects the `generate()` option. Hints match exactly or by an
  unambiguous prefix of at least three letters. Quote a name to use it
  literally when it conflicts with a hint, as in `findit(tab, "gen")`.
  Use `!!` for a name stored in a string. Calls, numbers, missing
  arguments and named arguments are not accepted here.

## Value

A tibble with one row per Stata idiom and the columns `match` (`"stata"`
when the word is a Stata command, `"r"` when it is an R function used in
the entry, `"keyword"` for a text match, `"nearest"` for the closest
entries to a plain question, `"all"` for the whole list), `stata` (the
Stata code), `r` (equivalent R code), `package` (where the R function
lives) and `task` (what it does). It prints each entry as a short block:
what it does, then the Stata code and the R code on lines labelled
`Stata:` and `R:`, so the code is never cut off. The `package` column
identifies the primary package; namespace-qualified helper calls may
require additional packages. When one entry answers the query, only that
entry is printed. Routine commands have a canonical default, such as
`tabulate x` for `findit(tab)`. Up to five examples are printed when
different meanings or structural choices remain unresolved, such as the
direction of `reshape`. Hidden examples are always counted, with a line
to run for the rest, such as `findit(tab) |> print(n = Inf)`. The
returned tibble always has every match, so it can be stored, filtered or
opened with [`View()`](https://rdrr.io/r/utils/View.html). Headings use
a single `#`, without an introductory summary. R-function notes already
demonstrated or resolved by comma-separated inputs are omitted. Supplied
names customize compatible examples; examples requiring different
variables retain all their original placeholders. No matches are
removed. A note identifies retained placeholders when those examples are
displayed, or explains when no example fits. If nothing matches, a
message suggests similar names and an empty tibble is returned
invisibly.

## Details

Matching follows fixed rules, without any guessing:

- The first word is looked up both as a Stata command and as an R
  function. Stata's minimum abbreviations work: `reg`, `regr` and
  `regress` all find `regress`; `su` and `sum` find `summarize`; `ta`
  and `tab` find `tabulate`. R functions must be named in full (`lm`
  finds [`lm()`](https://rdrr.io/r/stats/lm.html) but not
  [`glm()`](https://rdrr.io/r/stats/glm.html)); upper and lower case are
  ignored only when no exact name matches.

- Entries found as a Stata command come first. Entries found only
  through the R function follow. A description is added only when the
  function does not appear in a displayed example. Hundreds of R
  functions are described, including many that no entry uses yet, such
  as
  [`n_distinct()`](https://dplyr.tidyverse.org/reference/n_distinct.html)
  or `fct_relevel()`; for those, `findit()` prints the description and
  the related Stata command.

- A leading `by ...:` or `bysort ...:` prefix is set aside, so
  `findit("bys g: sum x")` looks up `summarize` and lists the grouped
  entries first.

- The remaining words put the best-matching entries first. For example,
  `findit("merge keep(match)")` lists
  [`inner_join()`](https://dplyr.tidyverse.org/reference/mutate-joins.html)
  before the other merge entries, and `findit("mutate egen")` lists the
  `egen` entries among the many that use
  [`mutate()`](https://dplyr.tidyverse.org/reference/mutate.html). Among
  equally good entries, the one with the fewest further words comes
  first. All matching entries are still returned.

- Comma-separated names and hints select among these examples and fill
  their recorded variable roles. Variable lists can accept several
  names, while fixed roles must all be supplied. Dataset names, function
  names and unrelated constants are unchanged. Strings that represent
  column names or formulas are customized too. R names are quoted as
  needed; non-Stata names are shown with backticks in the reference
  Stata line. This is a lookup over existing examples, not a parser or
  executor for arbitrary Stata programs.

- If a hint prefix has several interpretations, competing examples are
  shown. If no example satisfies every hint, the closest alternatives
  are shown with an explanation. For plain questions a uniquely
  highest-ranked meaning is shown alone; tied meanings retain up to five
  representative examples.

- If neither matches, the text is searched for in the Stata code, the R
  code and the task, so `findit(winsor)` and `findit(dummy)` also work.

- Otherwise the text is read as a plain question, in English or Chinese,
  and the closest entries are listed under their own heading:
  `findit("how do I remove duplicate rows")`. The closest entries are
  the ones sharing the most informative words with the question, after
  common words are dropped and a short built-in list of synonyms is
  applied ("average" also means "mean"). A question of three or more
  words that happens to start with a command, such as
  `findit("count how many people in each category")`, lists the closest
  entries first. No language model is involved, so the same question
  always gives the same answer.

R reads a call before `findit()` runs, so anything that is not a single
R name must be quoted: several words (`"merge 1:1 id"`), reserved words
(`"if"`), and names starting with an underscore (`"_n"`).

When R runs in Chinese (the `LANGUAGE` environment variable or, if it is
unset, the locale), the task and function descriptions are shown in
Chinese, and Chinese keywords are searched in any language.
`Sys.setenv(LANGUAGE = "en")` switches back to English, as it does for
R's own messages.

The list is curated rather than exhaustive. Longer explanations, in
English and Chinese, are in the "Coming from Stata" articles on the
package website.

Nonempty notes and qualifications print with their examples, including
legacy workflows. Explicit expansion also prints reference links.
Reference packages are needed only when running their examples; lookup
stays offline and does not load or install them. A qualification
identifies supplied option combinations absent from the curated
examples. Known unsupported queries are explained explicitly. The
reference articles distinguish canonical commands, Stata functions and
operators, Stata examples and alternative R approaches. Example metadata
uses stable IDs, so several R implementations may share the same Stata
syntax without losing their variable-role annotations.

tidystata and statar can be attached together; only
[`tab()`](https://socimh.github.io/tidystata/reference/tab.md) and
[`xtile()`](https://socimh.github.io/tidystata/reference/cut.md) share
names. Attach tidystata last, or write
[`tidystata::tab()`](https://socimh.github.io/tidystata/reference/tab.md).

## Examples

``` r
findit(reg)
#> # Linear regression [stats]
#> Stata: regress y x1 x2
#> R:     fit <- lm(y ~ x1 + x2, data = data)
#> # Note: summary(fit) shows the coefficient table; broom::tidy(fit) returns it as a data frame.
#> 
#> # 17 more examples. To see them all: findit(reg) |> print(n = Inf)
findit(su)
#> # Summary statistics for all variables [tidystata]
#> Stata: summarize
#> R:     summ(data)
#> # Note: summary(data) is the base R version, with a less tidy layout. summ() also reports missing counts and has its own default statistic layout; select .stat explicitly when matching Stata output.
#> 
#> # 6 more examples. To see them all: findit(su) |> print(n = Inf)
findit(tab, sex, region)
#> # Two-way cross-tabulation [tidystata]
#> Stata: tabulate sex region
#> R:     tab2(data, sex, region)
#> # Note: fre2(data, x1, x2) adds row and column totals. tidystata retains missing categories by default; Stata tabulate excludes them unless missing is specified. Use .missing = FALSE to match Stata.
#> 
#> # 20 more examples. To see them all: findit(tab, sex, region) |> print(n = Inf)
findit(tab, gen)
#> # Dummy variables for every category [tidystata]
#> Stata: tabulate x, generate(x_)
#> R:     as_dummy(data, x)
#> # Note: as_dummy(data, x, .names = "index") numbers the columns x_1, x_2, ... as Stata does. Also: fastDummies::dummy_cols(data, "x"). as_dummy() defaults to value-based column names; .names = "index" gives numbered Stata-style suffixes. Check the missing-category indicator policy too.
#> 
#> # 20 more examples. To see them all: findit(tab, gen) |> print(n = Inf)
findit(xtile, quartile, income)
#> # Quantile groups [tidystata]
#> Stata: xtile quartile = income, nquantiles(4)
#> R:     mutate(data, quartile = xtile(income, 4))
#> # Note: xtile() follows Stata's rule, so equal values stay in the same group.
#> 
#> # 2 more examples. To see them all: findit(xtile, quartile, income) |> print(n = Inf)
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
findit("bys g: egen m = mean(x)")
#> # Group statistic as a new variable [dplyr]
#> Stata: bysort group: egen x_avg = mean(x)
#> R:     mutate(data, x_avg = mean(x, na.rm = TRUE), .by = group)
#> # Note: For an all-missing group mean(..., na.rm = TRUE) gives NaN; Stata egen mean() gives numeric missing. Normalize NaN if that distinction matters.
#> 
#> # 59 more examples. To see them all: findit("bys g: egen m = mean(x)") |> print(n = Inf)
findit(winsor)
#> # Winsorise at the 1st and 99th percentiles [datawizard]
#> Stata: winsor2 x, cuts(1 99)
#> R:     mutate(data, x_w = datawizard::winsorize(x, threshold = 0.01))
#> # Note: datawizard uses R quantile cutpoints while winsor2 uses Stata percentile rules; small samples and ties can therefore yield different caps.
#> 
#> # Cap both tails at explicitly selected empirical quartiles [base]
#> Stata: gstats winsor x, cuts(25 75) generate(z)
#> R:     bounds <- stats::quantile(data$x,c(.25,.75),na.rm=TRUE,type=2); data$z <- pmax(bounds[1],pmin(bounds[2],data$x))
#> # Note: Unweighted workflow with an explicit R type-2 empirical percentile rule; no cross-software numerical certification is claimed.
#> 
#> # Set values outside empirical quartiles to missing [base]
#> Stata: gstats winsor x, cuts(25 75) trim generate(z)
#> R:     bounds <- stats::quantile(data$x,c(.25,.75),na.rm=TRUE,type=2); data$z <- data$x; data$z[!is.na(data$x) & (data$x<bounds[1] | data$x>bounds[2])] <- NA_real_
#> # Note: Trimming sets tails to missing while retaining rows; percentile rule is explicit R type 2 and no weighted parity is asserted.
#> 
#> # Cap tails separately inside each group [dplyr]
#> Stata: gstats winsor x, by(g) cuts(25 75) replace
#> R:     data <- dplyr::mutate(data,x={b <- stats::quantile(x,c(.25,.75),na.rm=TRUE,type=2); pmax(b[1],pmin(b[2],x))},.by=g)
#> # Note: Groups use independent unweighted R type-2 cutoffs; all-missing groups require an explicit policy.

# Plain questions
findit("how do I remove duplicate rows")
#> # Closest entries for "how do I remove duplicate rows"
#> 
#> # Drop rows that duplicate an earlier row [tidystata]
#> Stata: duplicates drop
#> R:     duplicates_drop(data)
#> 
#> # 9 more examples. To see them all: findit("how do I remove duplicate rows") |> print(n = Inf)

# R functions work too, and words with both meanings show both
findit(left_join)
#> # Keep all rows of the master data [dplyr]
#> Stata: merge 1:1 id using data2, keep(master match)
#> R:     left_join(data1, data2, by = "id")
#> # Note: dplyr retains overlapping non-key columns with suffixes instead of Stata master values, creates no _merge, and does not enforce a declared 1:1 key constraint.
#> 
#> # 3 more examples. To see them all: findit(left_join) |> print(n = Inf)
findit(log)
#> # Record console output in a file [base]
#> Stata: log using results.log
#> R:     sink("results.log")
#> # Note: Most R users write an R Markdown or Quarto report instead of a log.
#> 
#> # Natural logarithm [base]
#> Stata: generate y = ln(x)
#> R:     mutate(data, y = log(x))
#> # Note: log10() matches Stata's log10(). R's log(0) is -Inf rather than missing. R log(0) gives -Inf and a negative input gives NaN with a warning; Stata ln() gives numeric missing for these invalid inputs.
#> 
#> # 9 more examples. To see them all: findit(log) |> print(n = Inf)

# The whole list
findit()
#> # Find the R equivalent of a Stata command [tidystata]
#> Stata: findit command
#> R:     findit(command)
#> # Note: Bare words and comma-separated names work: findit(tab, sex, region). Add hints such as findit(tab, gen), or quote full Stata syntax. One clear example is shown by default; print(n = Inf) reveals every match. findit() with no argument returns the whole list.
#> 
#> # Open the help page of a function [utils]
#> Stata: help command
#> R:     help(function_name)
#> # Note: ?function does the same. In RStudio you can also search the Help pane.
#> 
#> # Search all installed help pages [utils]
#> Stata: search keyword
#> R:     help.search("keyword")
#> # Note: ??keyword is a shortcut. To find the R version of a Stata command, use findit().
#> 
#> # Remove a dataset from memory [base]
#> Stata: clear
#> R:     rm(data)
#> # Note: Rarely needed: R holds many tables at once, each under its own name.
#> 
#> # Show the working directory [base]
#> Stata: pwd
#> R:     getwd()
#> 
#> # 1777 more examples. To see them all: findit() |> print(n = Inf)
```
