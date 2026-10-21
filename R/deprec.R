#' Renamed functions
#'
#' @description
#' These functions were renamed in statart 0.3.0. The old names still
#' work and give identical results with a lifecycle deprecation warning.
#' They will be removed in a future release.
#'
#' | Old name | New name |
#' | --- | --- |
#' | `s_match()` | [varlist()] |
#' | `s_type()` | [var_type()] |
#' | `s_unit()` | [var_unit()] |
#'
#' Quiet aliases such as `cut_quantile()`, `s_try()`, `names_as_column()`,
#' `xtab()` and `pct()` are documented with their primary functions and give
#' no notice.
#'
#' @param ... Arguments passed to the new function.
#' @returns The result of the new function.
#' @name statart-deprecated
#' @keywords internal
NULL

#' @rdname statart-deprecated
#' @export
s_match <- function(...) {
  lifecycle::deprecate_soft("0.3.0", "s_match()", "varlist()")
  varlist(...)
}

#' @rdname statart-deprecated
#' @export
s_type <- function(...) {
  lifecycle::deprecate_soft("0.3.0", "s_type()", "var_type()")
  var_type(...)
}

#' @rdname statart-deprecated
#' @export
s_unit <- function(...) {
  lifecycle::deprecate_soft("0.3.0", "s_unit()", "var_unit()")
  var_unit(...)
}
