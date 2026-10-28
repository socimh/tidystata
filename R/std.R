#' Standardise a variable or scale it to a percentage
#'
#' @description
#' Vector helpers for [dplyr::mutate()], following Stata's `egen`:
#'
#' * `std()`: Standardise to mean 0 and standard deviation 1, like `egen z =
#'   std(x)`. Unlike [scale()], it returns a plain vector.
#' * `pc()`: Express each value as a percentage of the total, like
#'   `egen p = pc(x)`, or as a proportion with `prop = TRUE`.
#'
#' @details
#' By default, `std(x)` computes `(x - mean(x, na.rm = TRUE)) /
#' sd(x, na.rm = TRUE)` using the sample standard deviation.
#' `pc(x)` computes `100 * x / sum(x, na.rm = TRUE)`, not percentile ranks.
#' Use [dplyr::percent_rank()] for ranks on a 0-1 scale, or multiply them by
#' 100 for a 0-100 scale.
#' In grouped [dplyr::mutate()] (or with `.by`), the mean,
#' standard deviation and total come from each group, like Stata's `by g: egen`.
#'
#' @param x A numeric or logical vector. Labelled numeric vectors are used
#'   through their codes.
#' @param mean,sd For `std()`, finite numeric scalars giving the target mean
#'   (default 0) and signed scale multiplier (default 1), like Stata's
#'   `egen std(x), mean() std()` options. The result has standard deviation
#'   `abs(sd)`; a negative `sd` reverses the ordering and zero makes all
#'   observed values equal to `mean` when the input spread is defined.
#' @param prop If `TRUE`, `pc()` returns proportions (summing to 1) instead of
#'   percentages (summing to 100). Defaults to `FALSE`.
#'
#' @returns A double vector with the length and order of `x`. Input classes,
#'   names, and labels are dropped; tagged and SPSS user-missing values are
#'   treated as missing. Missing inputs remain missing.
#'   `std()` returns all `NA` when the standard deviation is zero or undefined
#'   (fewer than two observed values), and `pc()` when the total is zero or
#'   infinite, as Stata gives missing values there.
#'
#' @examples
#' std(c(1, 2, 3, NA))
#'
#' pc(c(2, 3, 5))
#'
#' pc(c(2, 3, 5), prop = TRUE)
#'
#' lifeexp |>
#'   dplyr::mutate(
#'     z = std(lexp),
#'     share = pc(popgrowth),
#'     .by = region
#'   )
#' @family variable generation functions
#' @export
std <- function(x, mean = 0, sd = 1) {
  x <- egen_numeric(x)
  check_number_decimal(mean, allow_infinite = FALSE)
  check_number_decimal(sd, allow_infinite = FALSE)
  center <- base::mean(x, na.rm = TRUE)
  spread <- stats::sd(x, na.rm = TRUE)
  if (is.na(spread) || spread == 0) {
    return(rep(NA_real_, length(x)))
  }
  (x - center) / spread * sd + mean
}

#' @rdname std
#' @export
pc <- function(x, prop = FALSE) {
  x <- egen_numeric(x)
  check_bool(prop)
  total <- sum(x, na.rm = TRUE)
  if (!is.finite(total) || total == 0) {
    return(rep(NA_real_, length(x)))
  }
  out <- x / total
  if (prop) out else out * 100
}
