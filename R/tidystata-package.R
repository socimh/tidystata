#' @description
#' Stata-inspired tools for frequency tables, summary statistics,
#' variable inspection, column selection, row calculations, and binning.
#' Use [tab()], [summ()], and [codebook()] to start exploring a dataset.
#'
#' Coming from Stata? [findit()] gives the R equivalent of a Stata command,
#' such as `findit(reg)` or `findit("merge 1:1 id")`.
#'
#' @section Tutorials and migration:
#' Read `vignette("getting-started", package = "tidystata")` for a short workflow
#' and `vignette("containers-and-missing-values", package = "tidystata")` for
#' output containers, grouping and missing-value conventions.
#' The full migration guide is the website's
#' [Migration guide](https://socimh.github.io/tidystata/articles/migration.html)
#' article.
#'
#' @keywords internal
"_PACKAGE"

## usethis namespace: start
#' @importFrom rlang := .data
#' @importFrom stats IQR mad median quantile sd
#' @useDynLib tidystata, .registration = TRUE
## usethis namespace: end
NULL
