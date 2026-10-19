#' @title Skewness and kurtosis
#' @description Calculate skewness and kurtosis
#'
#' @param x A numeric vector
#' @param n The number of observations
#'
#' @return A numeric value
#' @name stat
#' @keywords internal

#' @rdname stat
skew <- function(x, n) {
  mean_val <- mean(x, na.rm = TRUE)
  sd_val <- sd(x, na.rm = TRUE)
  skew_val <- sum((x - mean_val)^3, na.rm = TRUE) / (n * sd_val^3)
  return(skew_val)
}

#' @rdname stat
kurtosis <- function(x, n) {
  mean_val <- mean(x, na.rm = TRUE)
  sd_val <- sd(x, na.rm = TRUE)
  kurtosis_val <- sum((x - mean_val)^4, na.rm = TRUE) / (n * sd_val^4) - 3
  return(kurtosis_val)
}
