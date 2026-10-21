#' Capture an error and report success
#'
#' `capture()` works like Stata's `capture`: it evaluates an expression,
#' suppresses any error, and returns `TRUE` if the expression succeeded and
#' `FALSE` if it failed. `s_try()` is an alias of `capture()`.
#'
#' @param x An expression to evaluate once.
#' @param .fn `r lifecycle::badge("deprecated")` Use `x` instead.
#' @returns A single logical value.
#' @details
#' Errors are caught without printing their messages; warnings and messages
#' propagate normally. For compatibility with [try()], a successful expression
#' that returns an object inheriting from `try-error` also yields `FALSE`.
#'
#' @name capture
#' @examples
#' capture(mean(1:10))
#'
#' # This gives a warning, but it is still working, so capture() returns TRUE
#' capture(mean(letters[1:10]))
#'
#' # This throws an error, so capture() returns FALSE
#' capture(means(1:10))
#'
#' # Check a key without stopping the script
#' capture(isid(starwars, name))
#' @family utility functions
NULL

#' @rdname capture
#' @export
capture <- function(x, .fn = lifecycle::deprecated()) {
  if (!missing(.fn)) {
    lifecycle::deprecate_soft("0.3.0", "capture(.fn)", "capture(x)")
    return(capture(.fn))
  }
  try_result <- try(x, silent = TRUE)
  !inherits(try_result, "try-error")
}

#' @rdname capture
#' @export
s_try <- capture
