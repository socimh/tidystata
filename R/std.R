#' Standardise a variable or scale it to a percentage
#'
#' @description
#' Vector helpers for [dplyr::mutate()], following Stata's `egen`:
#'
#' * `std()` standardises to mean 0 and standard deviation 1, like
#'   `egen z = std(x)`. Unlike [scale()], it returns a plain vector.
#' * `pct()` gives each value as a percentage of the total, like
#'   `egen p = pc(x)`, or as a proportion with `prop = TRUE`.
#'
#' In grouped [dplyr::mutate()] (or with `.by`), the mean, standard deviation
#' and total come from each group, like Stata's `by g: egen`.
#'
#' @param x A numeric or logical vector. Labelled numeric vectors are used
#' through their codes.
#' @param mean,sd The mean and standard deviation of the result, like Stata's
#' `egen std(x), mean() std()` options.
#' @param prop A single `TRUE` or `FALSE`. If `TRUE`, `pct()` returns
#' proportions (summing to 1) instead of percentages (summing to 100).
#'
#' @return A double vector the same length as `x`. Missing values stay
#' missing. `std()` returns all `NA` when the standard deviation is zero or
#' undefined (fewer than two observed values), and `pct()` when the total is
#' zero, as Stata gives missing values there.
#'
#' @examples
#' std(c(1, 2, 3, NA))
#' pct(c(2, 3, 5))
#' pct(c(2, 3, 5), prop = TRUE)
#'
#' lifeexp %>%
#'   dplyr::mutate(
#'     z = std(lexp),
#'     share = pct(popgrowth),
#'     .by = region
#'   )
#' @export
std <- function(x, mean = 0, sd = 1) {
  x <- egen_numeric(x)
  check_number(mean, "mean")
  check_number(sd, "sd")
  center <- base::mean(x, na.rm = TRUE)
  spread <- stats::sd(x, na.rm = TRUE)
  if (is.na(spread) || spread == 0) {
    return(rep(NA_real_, length(x)))
  }
  (x - center) / spread * sd + mean
}

#' @rdname std
#' @export
pct <- function(x, prop = FALSE) {
  x <- egen_numeric(x)
  check_flag(prop, "prop")
  total <- sum(x, na.rm = TRUE)
  if (total == 0) {
    return(rep(NA_real_, length(x)))
  }
  out <- x / total
  if (prop) out else out * 100
}

egen_numeric <- function(x) {
  if (inherits(x, "haven_labelled") && is.numeric(vctrs::vec_data(x))) {
    return(as.numeric(vctrs::vec_data(x)))
  }
  if ((is.numeric(x) || is.logical(x)) && !is.object(x)) {
    return(as.numeric(x))
  }
  stop(
    "`x` must be numeric or logical, not ",
    class(x)[[1L]],
    ".",
    call. = FALSE
  )
}

check_number <- function(value, name) {
  if (!is.numeric(value) || length(value) != 1L || !is.finite(value)) {
    stop("`", name, "` must be a single finite number.", call. = FALSE)
  }
}
