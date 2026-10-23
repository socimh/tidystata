#' Time spent on a function
#'
#' @description
#' `timer()` works like the `timer` command in Stata.
#'
#' @param x An expression to evaluate and time.
#' @param on_error A single `TRUE` or `FALSE`. If `TRUE` (the default), also
#'   report elapsed time when the expression fails, then let the original error
#'   propagate. Use `FALSE` to report elapsed time only on success.
#' @returns The evaluated result, invisibly.
#' @details
#' The expression is evaluated once. On success, elapsed time is emitted as a
#' message. Warnings and errors propagate normally. When the expression fails
#' (or is interrupted) and `on_error = TRUE`, a message marked as failed
#' execution reports the elapsed time while the error unwinds; the original
#' condition object, including its call, is not modified.
#'
#' Nested or repeated timers each measure everything evaluated inside them,
#' so a later timer in a pipeline reports cumulative time from its own start.
#' @family utility functions
#' @export
#'
#' @examples
#' x <- seq_len(1e6)
#' mean(x) |> timer()
#' try(timer(stop("failure")))
timer <- function(x, on_error = TRUE) {
  check_bool(on_error)
  begin_time <- Sys.time()
  completed <- FALSE
  # Report failures while unwinding, without wrapping the evaluation frame.
  on.exit(
    if (!completed && on_error) {
      cli::cli_inform(
        "Failed execution. Time spent: {duration_to_chr(Sys.time() - begin_time)}"
      )
    },
    add = TRUE
  )
  out <- x
  completed <- TRUE
  end_time <- Sys.time()
  time <- end_time - begin_time
  cli::cli_inform("Time spent: {duration_to_chr(time)}")
  invisible(out)
}

# Compact output: "1m5s", "2h3m", "0.123s"
duration_to_chr <- function(duration) {
  total_secs <- as.numeric(duration, units = "secs")

  h <- floor(total_secs / 3600)
  m <- floor((total_secs %% 3600) / 60)
  s <- total_secs %% 60

  if (h > 0) {
    # e.g. "1h30m"
    sprintf("%dh%dm", h, m)
  } else if (m > 0) {
    # e.g. "2m5s"
    sprintf("%dm%ds", m, floor(s))
  } else if (s >= 1) {
    # e.g. "5.23s"
    sprintf("%.2fs", s)
  } else {
    # sub-second: "0.012s"
    sprintf("%.3fs", s)
  }
}
