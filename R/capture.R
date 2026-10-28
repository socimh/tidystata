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
#' Like Stata's `capture`, this lets a script continue after an error. Unlike
#' Stata's command, it returns the successful value, keeps printed output and
#' reports a caught error as a message by default. The failure notice is not a
#' formal R warning and does not become an error under `options(warn = 2)`.
#' Warnings and messages from `x` propagate unless `quiet = TRUE`; suppressing
#' them does not stop evaluation. With `options(warn = 2)`, an unsuppressed
#' warning from `x` becomes an error and is caught. User interrupts are not
#' caught.
#'
#' A successful `FALSE`, `NA`, `NULL` or object inheriting from `try-error` is
#' returned unchanged. A successful `NULL` and a caught error have the same
#' value. Use [tryCatch()] when you need to distinguish them programmatically or
#' retain the error object.
#' The return value is not a success/failure flag and cannot reliably serve as
#' the condition in `if (capture(...))`.
#'
#' When updating an existing object, put the assignment inside `capture()`:
#' `capture(data <- update(data))`. Writing `data <- capture(update(data))`
#' overwrites `data` with `NULL` if the update fails.
#'
#' An assignment inside `capture()` updates its target only after the right-hand
#' side succeeds. A successful `NULL` is still assigned. A block of separate
#' assignments retains the last completed update and skips steps after the first
#' error, as Stata's capture blocks do. A single assignment around a pipeline
#' retains its original target on error; intermediate pipeline results are not
#' saved.
#'
#' `capture()` is not all-or-nothing: earlier effects are not rolled back. In
#' particular, changes by reference (such as data.table updates or modified
#' environments), files written and printed output before an error remain.
#' Invalid `quiet` values raise an error before `x` is evaluated.
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
