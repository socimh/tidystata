#' Skewness and kurtosis
#'
#' @param x A numeric vector
#' @param n The number of observations
#'
#' @returns A numeric value
#' @noRd
skew <- function(x, n) {
  mean_val <- mean(x, na.rm = TRUE)
  sd_val <- sd(x, na.rm = TRUE)
  skew_val <- sum((x - mean_val)^3, na.rm = TRUE) / (n * sd_val^3)
  skew_val
}

#' @rdname skew
#' @noRd
kurtosis <- function(x, n) {
  mean_val <- mean(x, na.rm = TRUE)
  sd_val <- sd(x, na.rm = TRUE)
  kurtosis_val <- sum((x - mean_val)^4, na.rm = TRUE) / (n * sd_val^4) - 3
  kurtosis_val
}
