# Start here

This reference helps Stata users find an R implementation of a familiar operation.
It accompanies **tidystata**, but covers base R and other packages wherever they
offer a useful approach. It is a lookup companion, not a textbook.

The catalogue contains **{{command_families}} command families** and
**{{example_count}} paired examples**. Its {{lookup_keys}} lookup keys also include
Stata functions, operators and prefixes. The R index describes {{r_functions}}
function/package pairs. Abbreviations and alternative implementations do not
inflate command-family counts.

## Find your task

- Use **Command reference** in the header; its sidebar lists every subject chapter.
- Open the [Stata index](stata-index.qmd) for a command you already know.
- Open the [R index](r-index.qmd) to browse functions by package.
- Search for a command, R function or task. Expand further examples when you need
  options or a different R approach.

Every chapter has a **中文** switch. It opens the same chapter and, when you follow
an example link, the same example in Chinese.

## Look it up in R

```r
library(tidystata)
findit(tab)
findit(tab, sex, region)
findit("merge 1:1 id, keep(match)")
findit(dplyr::left_join)
findit("how do I remove duplicate rows")
findit(tab) |> print(n = Inf)
```

`findit()` and this book share one catalogue. Clear console queries show a
preferred answer; expansion exposes the remaining examples. The lookup does not
load or install the packages named in its results.

## Adapt an example

`data` is your dataset; `x`, `y`, `g`, `id` and `time` are illustrative column names.
`data1` and `data2` are two datasets, and `fit` is an existing fitted model.
Some snippets need setup described in their task or qualification. A snippet is
not necessarily a standalone analysis.

Code with `package::function()` identifies its package explicitly. The label
beneath each example names its primary package; helpers may use other packages
listed in the function index. Attach packages for unqualified calls as needed.

## About the notes {#example-labels}

A note tagged **Differs from Stata** means the R code does the same job, but a
default, the missing-value handling, an estimator or the output layout differs; the
note says how. Other notes are practical tips. Most R examples are run
against checks when the catalogue is built; these test the R code itself, not
numerical parity with Stata.
Missing values, weights, reference levels and standard errors deserve particular
attention when comparing results.

## Keep learning

See the [tidystata documentation](https://socimh.github.io/tidystata/) for package
help, and [Minghong Shen's website](https://www.socimh.com/) and
[books](https://www.socimh.com/books.html) for longer learning material. Report missing or incorrect comparisons through
[the package issue tracker](https://github.com/socimh/tidystata/issues).
