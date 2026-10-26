#' Capture an error and report success
#'
#' `capture()` works like Stata's `capture`: it evaluates an expression,
#' suppresses any error, and returns `TRUE` if the expression succeeded and
#' `FALSE` if it failed.
#'
#' @param x An expression to evaluate once.
#' @returns A single logical value: `TRUE` on success, `FALSE` on error or when
#'   the expression returns an object inheriting from `try-error`.
#' @details
#' Errors are caught without printing their messages; warnings and messages
#' propagate normally. The `try-error` exception follows [try()] compatibility.
#'
#' @name capture
#' @examples
#' capture(mean(1:10))
#'
#' # Warnings do not count as errors
#' capture(mean(letters[1:10]))
#'
#' # Errors return FALSE
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
