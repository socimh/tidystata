#' Replace values with missing values or fill missing values
#'
#' @description
#' * `na_if_value()` replaces values equal to `.value` with `NA`, using
#'   [dplyr::na_if()].
#' * `value_if_na()` replaces missing values with `.value`, using
#'   [tidyr::replace_na()].
#'
#' Both wrappers preserve the underlying function's casting, recycling,
#' and error behavior when both required arguments are supplied. Use
#' `na_if_value(x, value)` or `x |> na_if_value(value)` to replace values,
#' and `value_if_na(x, replacement)` or `x |> value_if_na(replacement)`
#' to fill missing values. A call with only one argument is incomplete.
#' For SPSS labelled vectors ([haven::labelled_spss()]), user-defined missing
#' codes and ranges also count as missing, matching their `is.na()` method;
#' labels and missing-value metadata are retained.
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
  if (missing(.x) || missing(.value)) {
    argument <- if (missing(.x)) ".x" else ".value"
    stop(
      "Missing `",
      argument,
      "`. Use na_if_value(x, value) or ",
      "x |> na_if_value(value).",
      call. = FALSE
    )
  }
  dplyr::na_if(.x, .value)
}

#' @rdname na_conversion
#' @export
value_if_na <- function(.x, .value) {
  if (missing(.x) || missing(.value)) {
    argument <- if (missing(.x)) ".x" else ".value"
    stop(
      "Missing `",
      argument,
      "`. Use value_if_na(x, replacement) or ",
      "x |> value_if_na(replacement).",
      call. = FALSE
    )
  }
  if (inherits(.x, "haven_labelled_spss")) {
    # User-missing codes are missing under is.na(), but not for vctrs/tidyr.
    replacement <- vctrs::vec_cast(.value, vctrs::vec_ptype(.x))
    if (length(replacement) != 1L) {
      stop("`.value` must be a single replacement value.", call. = FALSE)
    }
    .x[is.na(.x)] <- replacement
    return(.x)
  }
  tidyr::replace_na(.x, .value)
}
