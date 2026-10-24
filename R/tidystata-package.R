#' @description
#' Stata-inspired tools for frequency tables, summary statistics,
#' variable inspection, column selection, row calculations, and binning.
#' Use [tab()], [summ()], and [codebook()] to start exploring a dataset.
#'
#' Coming from Stata? [findit()] gives the R equivalent of a Stata command,
#' such as `findit(reg)` or `findit("merge 1:1 id")`.
#'
#' @section Tutorials:
#' Read `vignette("getting-started", package = "tidystata")` for a short workflow
#' and `vignette("containers-and-missing-values", package = "tidystata")` for
#' output containers, grouping and missing-value conventions.
#'
#' @keywords internal
"_PACKAGE"

## usethis namespace: start
#' @importFrom rlang := .data
#' @importFrom stats IQR mad median quantile sd
#' @useDynLib tidystata, .registration = TRUE
## usethis namespace: end
NULL
