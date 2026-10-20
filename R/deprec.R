#' Renamed functions
#'
#' @description
#' These functions were renamed in statart 0.2.0.9000. The old names still
#' work and give identical results with a lifecycle deprecation warning.
#' They will be removed in a future release.
#'
#' | Old name | New name |
#' | --- | --- |
#' | `s_match()` | [varlist()] |
#'
#' Other earlier names, such as `cut_quantile()`, `s_try()`,
#' `names_as_column()`, `tab2()` and `fre2()`, are current names or aliases
#' and give no notice.
#'
#' @param ... Arguments passed to the new function.
#' @returns The result of the new function.
#' @name statart-deprecated
#' @keywords internal
NULL

#' @rdname statart-deprecated
#' @export
s_match <- function(...) {
  lifecycle::deprecate_soft("0.2.0.9000", "s_match()", "varlist()")
  varlist(...)
}
