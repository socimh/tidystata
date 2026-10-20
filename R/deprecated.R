#' Renamed functions
#'
#' @description
#' These functions were renamed in statart 0.2.0.9000. The old names still
#' work and give identical results; each shows a notice once per session.
#' They will be removed in a future release.
#'
#' | Old name | New name |
#' | --- | --- |
#' | `cut_quantile()` | [xtile()] |
#' | `s_match()` | [varlist()] |
#' | `s_try()` | [capture()] |
#' | `names_as_column()` | [ds_as_column()] |
#' | `tab2()` | [xtab()] |
#' | `fre2()` | [`xtab(.total = TRUE)`][xtab()] |
#'
#' @param .data,.flip,.type Passed to [xtab()].
#' @param ... Arguments passed to the new function.
#' @return The result of the new function.
#' @name statart-deprecated
#' @keywords internal
NULL

#' @rdname statart-deprecated
#' @export
cut_quantile <- function(...) {
  deprecate_rename("cut_quantile", "xtile()")
  xtile(...)
}

#' @rdname statart-deprecated
#' @export
s_match <- function(...) {
  deprecate_rename("s_match", "varlist()")
  varlist(...)
}

#' @rdname statart-deprecated
#' @export
s_try <- function(...) {
  deprecate_rename("s_try", "capture()")
  capture(...)
}

#' @rdname statart-deprecated
#' @export
names_as_column <- function(...) {
  deprecate_rename("names_as_column", "ds_as_column()")
  ds_as_column(...)
}

#' @rdname statart-deprecated
#' @export
tab2 <- function(.data, ..., .flip = FALSE) {
  deprecate_rename("tab2", "xtab()")
  xtab(.data, ..., .flip = .flip)
}

#' @rdname statart-deprecated
#' @export
fre2 <- function(
  .data,
  ...,
  .flip = FALSE,
  .type = c("auto", "tibble", "flextable")
) {
  deprecate_rename("fre2", "xtab(.total = TRUE)")
  xtab(.data, ..., .flip = .flip, .total = TRUE, .type = match.arg(.type))
}

deprecation_shown <- new.env(parent = emptyenv())

# One notice per old name and session. Package code uses only the new names.
# `new` is the replacement call as users should write it, e.g. "xtile()".
deprecate_rename <- function(old, new) {
  if (isTRUE(deprecation_shown[[old]])) {
    return(invisible())
  }
  deprecation_shown[[old]] <- TRUE
  message(
    "`",
    old,
    "()` was renamed to `",
    new,
    "` in statart 0.2.0.9000; the old name will be removed in a future ",
    "release.\n\u2139 This notice is shown once per session."
  )
  invisible()
}
