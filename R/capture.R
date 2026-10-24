#' Capture an error and report success
#'
#' `capture()` works like Stata's `capture`: it evaluates an expression,
#' suppresses any error, and returns `TRUE` if the expression succeeded and
#' `FALSE` if it failed.
#'
#' @param x An expression to evaluate once.
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
#' capture(isid(lifeexp, country))
#' @family utility functions
NULL

#' @rdname capture
#' @export
capture <- function(x) {
  try_result <- try(x, silent = TRUE)
  !inherits(try_result, "try-error")
}
