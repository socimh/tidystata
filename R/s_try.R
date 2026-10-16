#' Try a function and return a logical
#'
#' This function tries to evaluate a function,
#' and if the function throws an error, it returns FALSE.
#' Otherwise, it returns TRUE.
#'
#' @param .fn An expression to evaluate once.
#' @returns A single logical value.
#' @details
#' Errors are caught without printing their messages; warnings and messages
#' propagate normally. For compatibility with [try()], a successful expression
#' that returns an object inheriting from `try-error` also yields `FALSE`.
#'
#' @export
#' @examples
#' s_try(mean(1:10))
#'
#' # This gives a warning, but it is still working, so s_try() returns TRUE
#' s_try(mean(letters[1:10]))
#'
#' # This throws an error, so s_try() returns FALSE
#' s_try(means(1:10))
s_try <- function(.fn) {
  try_result <- try(.fn, silent = TRUE)
  !inherits(try_result, "try-error")
}
