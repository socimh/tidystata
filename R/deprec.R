#' Renamed functions
#'
#' @description
#' These functions were renamed in statart 0.2.0.9000. The old names still
#' work and give identical results; each shows a notice once per session.
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
  deprecate_rename("s_match", "varlist()")
  varlist(...)
}

deprecation_shown <- new.env(parent = emptyenv())

# One notice per old name and session. Package code uses only the new names.
# `new` is the replacement call as users should write it, e.g. "varlist()".
deprecate_rename <- function(old, new) {
  if (isTRUE(deprecation_shown[[old]])) {
    return(invisible())
  }
  deprecation_shown[[old]] <- TRUE
  cli::cli_inform(c(
    "{.fn {old}} was renamed to {.code {new}} in statart 0.2.0.9000; the old name will be removed in a future release.",
    i = "This notice is shown once per session."
  ))
  invisible()
}
