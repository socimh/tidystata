#' Replace values with missing values or fill missing values
#'
#' @description
#' * `na_if_value()` replaces values equal to `.value` with `NA`, using
#'   [dplyr::na_if()].
#' * `value_if_na()` replaces missing values with `.value`, using
#'   [tidyr::replace_na()].
#'
#' Both wrappers preserve the underlying function's casting, recycling,
#' and error behavior.
#'
#'
#' @name na_conversion
#'
#' @param .x A vector.
#' @param .value For `na_if_value()`, values to replace with `NA`; these are cast
#'   to the type of `.x` and recycled to its size. For `value_if_na()`, a single
#'   replacement value for missing elements, cast to the type of `.x`.
#' @return A vector with the same type and size as `.x`, with matching values
#'   replaced or missing values filled.
#'
#' @examples
#' x <- c(1, 2, NA, 4)
#' na_if_value(x, 2)
#'
#' value_if_na(x, 3)

#' @rdname na_conversion
#' @export
na_if_value <- function(.x, .value) {
  dplyr::na_if(.x, .value)
}

#' @rdname na_conversion
#' @export
value_if_na <- function(.x, .value) {
  tidyr::replace_na(.x, .value)
}
