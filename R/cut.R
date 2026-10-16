#' Cut a numeric vector into intervals.
#'
#' @param x A numeric vector.
#' @param n A positive integer. The number of intervals.
#' @inheritParams base::cut
#'
#' @details `cut_quantile()` uses type-7 quantiles and collapses duplicate
#' cutpoints with a warning. Equal values stay in the same group, so ties may
#' produce fewer intervals than `n`. Custom labels must match the effective
#' number of intervals. Empty, all-missing, and constant vectors are rejected.
#'
#' @return An ordered factor, or integer interval codes when `labels = FALSE`.
#'
#' @name cut
#' @examples
#' cut_quantile(1:20)
#'
#' cut_length(1:20)
#'
#' cut_breaks(1:20, breaks = c(5, 15))

#' @rdname cut
#' @export
cut_quantile <- function(x, n = 4, labels = NULL) {
  if (!is.numeric(x) || is.complex(x) || !is.null(dim(x))) {
    stop("`x` must be a numeric vector.", call. = FALSE)
  }
  if (!is.numeric(n) || length(n) != 1L || is.na(n) ||
      !is.finite(n) || n < 1 || n != floor(n)) {
    stop("`n` must be a single positive integer.", call. = FALSE)
  }
  observed <- x[!is.na(x)]
  if (length(observed) == 0L) {
    stop("`x` must contain non-missing observations.", call. = FALSE)
  }
  if (length(unique(observed)) == 1L) {
    stop("Cannot cut a vector with only one unique value.", call. = FALSE)
  }
  breaks <- unique(stats::quantile(
    observed, probs = seq(0, 1, length.out = n + 1),
    na.rm = TRUE, type = 7, names = FALSE
  ))
  if (anyNA(breaks)) {
    stop("Cannot form quantile cutpoints from these observations.", call. = FALSE)
  }
  intervals <- length(breaks) - 1L
  if (!is.null(labels) && !identical(labels, FALSE) &&
      length(labels) != intervals) {
    stop(
      "`labels` must have length ", intervals,
      ", the effective number of intervals.", call. = FALSE
    )
  }
  if (intervals < n) {
    warning(
      "Tied values collapsed quantile cutpoints to ", intervals,
      " intervals (requested ", n, ").", call. = FALSE
    )
  }
  cut(x, breaks = breaks, labels = labels, include.lowest = TRUE,
      right = TRUE, ordered_result = TRUE)
}

#' @rdname cut
#' @export
cut_length <- function(x, n = 4, labels = NULL) {
  breaks <- seq(min(x, na.rm = TRUE), max(x, na.rm = TRUE), length.out = n + 1)
  cut_breaks(x, breaks = breaks, labels = labels) %>%
    return()
}

#' @rdname cut
#' @export
cut_breaks <- function(x, breaks = NULL, labels = NULL, right = TRUE) {
  if (is.null(breaks)) {
    breaks <- median(x, na.rm = TRUE)
  }
  min <- min(x, na.rm = TRUE)
  max <- max(x, na.rm = TRUE)
  if (min == max) {
    stop("Cannot cut a vector with only one unique value.")
  }

  breaks <- c(min, breaks, max) %>%
    unique()

  cut(x,
    breaks = breaks,
    include.lowest = TRUE,
    right = right,
    labels = labels,
    ordered_result = TRUE
  ) %>%
    return()
}
