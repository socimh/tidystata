#' Evaluate an expression without stopping on an error
#'
#' `capture()` evaluates an expression once and returns its result. If the
#' expression errors, it reports why evaluation did not complete and returns
#' `NULL` invisibly. Use `quiet = TRUE` to suppress the failure message.
#'
#' @param x An expression to evaluate once.
#' @param quiet If `TRUE`, suppress warnings and messages from `x` and the
#'   failure message from `capture()`. Printed output and the returned value
#'   are unchanged. Defaults to `FALSE`.
#' @returns The expression's result, preserving its visibility, class and
#'   attributes. On error, `NULL` invisibly.
#' @details
#' Like Stata's `capture`, this lets a script continue after an error. It also
#' returns successful results and, by default, reports errors as messages.
#'
#' **Updating objects**
#'
#' Put an assignment inside `capture()` to keep the existing object if the
#' right-hand side fails: `capture(data <- update(data))`. Assigning outside,
#' as in `data <- capture(update(data))`, replaces `data` with `NULL` on error.
#' A successful `NULL` result is assigned in either case.
#'
#' In a block, completed assignments remain and the first error skips the
#' remaining steps. A single assignment around a pipeline saves only the final
#' result, so a failed pipeline leaves its target unchanged. Earlier side
#' effects are never undone: changes by reference (such as data.table or
#' environment updates), written files and printed output remain.
#'
#' **Errors, warnings and return values**
#'
#' `quiet = TRUE` suppresses warnings and messages without stopping evaluation;
#' printed output remains. Under `options(warn = 2)`, an unsuppressed warning
#' becomes an error and is caught. The failure notice from `capture()` is a
#' message, so this option does not turn it into an error. User interrupts
#' are never caught. Invalid `quiet` values fail before `x` is evaluated.
#'
#' Successful values, including `FALSE`, `NA`, `NULL` and `try-error` objects,
#' are returned unchanged. The result is therefore unsuitable as a success
#' flag in `if (capture(...))`. Use [tryCatch()] to retain the error object or
#' distinguish an error from a successful `NULL` result.
#'
#' @name capture
#' @examples
#' # Keep a successful result
#' capture(mean(1:10))
#'
#' # Suppress warnings and messages
#' capture(
#'   {
#'     message("Calculating")
#'     mean(1:10)
#'   },
#'   quiet = TRUE
#' )
#'
#' # A new object receives NULL on error, with a failure message
#' result <- capture(stop("Cannot calculate"))
#'
#' result
#'
#' # A failed assignment leaves the original data unchanged
#' data <- tibble::tibble(x = 1:3)
#' capture(data <- dplyr::mutate(data, y = missing_var * 2))
#'
#' data
#'
#' # Successful assignments are preserved before an error
#' capture({
#'   data <- dplyr::mutate(data, y = x * 2)
#'   data <- dplyr::mutate(data, z = missing_var * 2)
#' })
#'
#' data
#'
#' # A pipeline updates the data only if all steps succeed
#' capture(
#'   data <- data |>
#'     dplyr::mutate(z = x + 1) |>
#'     dplyr::mutate(w = missing_var * 2)
#' )
#'
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
        # A top-level stop() in `x` reports tryCatch()'s internal frame.
        call <- conditionCall(e)
        if (is.call(call) && identical(call[[1L]], quote(doTryCatch))) {
          e$call <- NULL
        }
        cli::cli_inform(
          c(
            "Captured expression did not complete.",
            i = "Changes made before the error may persist."
          ),
          parent = e
        )
      }
      invisible(NULL)
    }
  )
}
