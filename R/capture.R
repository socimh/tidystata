#' Evaluate an expression without stopping on an error
#'
#' `capture()` evaluates an expression once and returns its result. If the
#' expression errors, it reports why evaluation did not complete and returns
#' `NULL` invisibly. Use `quiet = TRUE` to suppress the failure message.
#'
#' When updating an existing object, put the assignment inside `capture()`:
#' `capture(data <- update(data))`. Writing `data <- capture(update(data))`
#' overwrites `data` with `NULL` if the update fails.
#'
#' @param x An expression to evaluate once.
#' @param quiet If `TRUE`, suppress warnings and messages from `x` and the
#'   failure message from `capture()`. Printed output and the returned value
#'   are unchanged. Defaults to `FALSE`.
#' @returns The expression's result, preserving its visibility, class and
#'   attributes. On error, `NULL` invisibly.
#' @details
#' Like Stata's `capture`, this lets a script continue after an error. Unlike
#' Stata's command, it returns the successful value, keeps printed output and
#' reports a caught error as a message by default. The failure notice is not a
#' formal R warning and does not become an error under `options(warn = 2)`.
#' Warnings and messages from `x` propagate unless `quiet = TRUE`; suppressing
#' them does not stop evaluation. With `options(warn = 2)`, an unsuppressed
#' warning from `x` becomes an error and is caught. User interrupts are not caught.
#'
#' A successful `FALSE`, `NA`, `NULL` or object inheriting from `try-error` is
#' returned unchanged. A successful `NULL` and a caught error have the same
#' value. Use [tryCatch()] when you need to distinguish them programmatically or
#' retain the error object.
#' This function no longer returns a success/failure flag, so do not use it as
#' the condition in `if (capture(...))`.
#'
#' An assignment inside `capture()` updates its target only after the right-hand
#' side succeeds. A successful `NULL` is still assigned. A block of separate
#' assignments retains the last completed update and skips steps after the first
#' error, as Stata's capture blocks do. A single assignment around a pipeline
#' retains its original target on error; intermediate pipeline results are not
#' saved.
#'
#' Earlier effects are not rolled back. In particular, changes by reference
#' (such as data.table updates) and printed output before an error remain.
#' Invalid `quiet` values raise an error before `x` is evaluated.
#'
#' @name capture
#' @examples
#' capture(mean(1:10))
#'
#' # Keep a successful result while suppressing warnings and messages
#' capture({
#'   message("Calculating")
#'   mean(1:10)
#' }, quiet = TRUE)
#'
#' # A new object receives NULL on error, with a failure message
#' result <- capture(stop("Cannot calculate"))
#'
#' # An existing object is kept if its replacement fails
#' data <- tibble::tibble(x = 1:3)
#' capture(data <- dplyr::mutate(data, y = x * 2))
#' capture(data <- stop("Update failed"))
#' data
#'
#' # Separate assignments keep the last completed update
#' capture({
#'   data <- dplyr::mutate(data, z = x + 1)
#'   data <- stop("Second update failed")
#'   data <- dplyr::mutate(data, later = TRUE)
#' })
#' data
#'
#' # A single assignment keeps the original target if any pipeline step fails
#' capture(data <- data |>
#'   dplyr::mutate(temporary = x * 10) |>
#'   dplyr::mutate(failed = stop("Pipeline failed")))
#' data
#' @family utility functions
NULL

#' @rdname capture
#' @export
capture <- function(x, quiet = FALSE) {
  check_bool(quiet)
  tryCatch(
    if (quiet) suppressWarnings(suppressMessages(x)) else x,
    error = function(e) {
      if (!quiet) {
        cli::cli_inform(c(
          "Captured expression did not complete.",
          i = "Reason: {conditionMessage(e)}",
          i = "Earlier changes, if any, were not undone."
        ))
      }
      invisible(NULL)
    }
  )
}
