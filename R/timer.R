#' Time spent on a function
#'
#' @description
#' `timer()` works like the `timer` command in Stata.
#'
#' @param .x The function
#' @return The function output
#' @export
#'
#' @examples
#' x <- seq_len(1e6)
#' mean(x) %>% timer()
timer <- function(.x) {
  begin_time <- Sys.time()
  out <- .x
  end_time <- Sys.time()
  time <- end_time - begin_time
  duration_to_chr(time) %>%
    paste0("Time spent: ", .) %>%
    message()
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
