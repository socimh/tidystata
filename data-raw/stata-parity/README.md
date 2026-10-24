# Stata reference values

These do-files produce the reference values that the `test-stata-parity-*.R`
tests compare tidystata against. Each writes CSV files to
`tests/testthat/fixtures/stata/`, which are committed because CI has no Stata.

| Do-file          | Stata commands                                        | Tests                            |
| ---------------- | ----------------------------------------------------- | -------------------------------- |
| `summ.do`        | `summarize, detail` and `_pctile`, unweighted, `[fw]`, `[aw]` | `test-stata-parity-summ.R`       |
| `xtile.do`       | `xtile, nquantiles()` and `egen cut(), at()`          | `test-stata-parity-cut.R`        |
| `egen.do`        | `egen row*()`, `std()`, `pc()` and `tag()`            | `test-stata-parity-egen.R`       |
| `pwcorr_tab.do`  | `pwcorr, sig obs` and `tabulate, chi2 V`              | `test-stata-parity-pwcorr-tab.R` |
| `panel.do`       | `L.`, `F.` and `D.` after `xtset`, with `%tw`, `%tm`, `%tq` | `test-stata-parity-panel.R` |
| `duplicates.do`  | `duplicates tag`                                      | `test-stata-parity-duplicates.R` |

`xtile.do` reads `summ-input.csv`, so run `summ.do` first. Run each file from
this folder in batch mode, for example `stata-mp -b do summ.do` (or the
Windows equivalent `StataMP-64.exe /e do summ.do`), and check the log for
`r(` error codes. The current files were produced by StataNow 19.5 MP.

Inputs are exact binary fractions (such as 2.25 and -8.125), so the CSV files
carry them without rounding; results are written with `%21.0g`, and the tests
compare them to a relative tolerance of 1e-12.

When a function's rule changes, or a new function computes something Stata
also computes, add the case to the matching do-file, rerun it and commit the
updated CSV with the test.
