#' Standardise a variable or scale it to a percentage
#'
#' @description
#' Vector helpers for [dplyr::mutate()], following Stata's `egen`:
#'
#' * `std()`: Standardise to mean 0 and standard deviation 1, like `egen z =
#'   std(x)`. Unlike [scale()], it returns a plain vector.
#' * `pc()` (`pct()`): Express each value as a percentage of the total, like
#'   `egen p = pc(x)`, or as a proportion with `prop = TRUE`.
#'
#' @details
#' The gt package also exports a `pct()` (for column widths), so prefer `pc()`
#' when gt is attached. In grouped [dplyr::mutate()] (or with `.by`), the mean,
#' standard deviation and total come from each group, like Stata's `by g: egen`.
#'
#' @param x A numeric or logical vector. Labelled numeric vectors are used
#'   through their codes.
#' @param mean,sd The target mean and signed scale multiplier, like Stata's
#'   `egen std(x), mean() std()` options. The result has standard deviation
#'   `abs(sd)`; a negative `sd` reverses the ordering and zero makes all
#'   observed values equal to `mean` when the input spread is defined.
#' @param prop If `TRUE`, `pc()` returns proportions (summing to 1) instead of
#'   percentages (summing to 100). Defaults to `FALSE`.
#'
#' @returns A double vector the same length as `x`. Missing values stay missing.
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

#' @rdname std
#' @export
pct <- pc

egen_numeric <- function(
  x,
  arg = rlang::caller_arg(x),
  call = rlang::caller_env()
) {
  if (inherits(x, "haven_labelled") && is.numeric(vctrs::vec_data(x))) {
    return(labelled_numeric(x))
  }
  if ((is.numeric(x) || is.logical(x)) && !is.object(x)) {
    return(as.numeric(x))
  }
  stop_input_type(x, "a numeric or logical vector", arg = arg, call = call)
}
