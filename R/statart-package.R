#' @description
#' Stata-inspired tools for frequency tables, summary statistics,
#' variable inspection, column selection, row calculations, and binning.
#' Use [tab()], [summ()], and [codebook()] to start exploring a dataset.
#'
#' @keywords internal
"_PACKAGE"

## usethis namespace: start
#' @importFrom magrittr %>%
#' @importFrom rlang :=
#' @importFrom utils apropos
#' @importFrom stats IQR mad median quantile sd Gamma as.formula binomial coef df.residual glm lm poisson pt setNames
#' @useDynLib statart, .registration = TRUE
## usethis namespace: end
NULL
