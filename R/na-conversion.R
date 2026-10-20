#' Replace values with missing values or fill missing values
#'
#' @description
#' Vector helpers named after Stata's missing-value commands:
#'
#' * `mvdecode()` replaces every value in `mv` with `NA`, like
#'   `mvdecode x, mv(-98 -99)`. Each code is matched with [dplyr::na_if()].
#' * `mvencode()` replaces missing values with `mv`, like `mvencode x, mv(0)`,
#'   using [tidyr::replace_na()].
#'
#' `na_if_value()` and `value_if_na()` are aliases of `mvdecode()` and
#' `mvencode()`. Use `mutate(x = mvdecode(x, -99))` for one variable, or
#' `mutate(across(c(x, y), \(v) mvdecode(v, -99)))` for a varlist.
#'
#' Casting and error behavior follow the underlying functions: codes are cast
#' to the type of `x`, so a lossy cast such as `1.5` for an integer vector is
#' an error. A call with only one argument is incomplete.
#' For SPSS labelled vectors ([haven::labelled_spss()]), user-defined missing
#' codes and ranges also count as missing, matching their `is.na()` method;
#' labels and missing-value metadata are retained.
#'
#' @name na_conversion
#'
#' @param x,.x A vector.
#' @param mv,.value For `mvdecode()` and `na_if_value()`, the codes to replace
#'   with `NA`; any value equal to one of them becomes missing. For
#'   `mvencode()` and `value_if_na()`, a single replacement value for missing
#'   elements, cast to the type of `x`.
#' @return A vector with the same type and size as `x`, with matching values
#'   replaced or missing values filled.
#'
#' @examples
#' x <- c(1, -99, NA, 4, -98)
#' mvdecode(x, -99)
#' mvdecode(x, c(-98, -99))
#'
#' mvencode(c(1, NA, 4), 0)

#' @rdname na_conversion
#' @export
mvdecode <- function(x, mv) {
  if (missing(x) || missing(mv)) {
    na_conversion_missing(if (missing(x)) "x" else "mv", "mvdecode", "mv")
  }
  na_decode(x, mv)
}

#' @rdname na_conversion
#' @export
mvencode <- function(x, mv) {
  if (missing(x) || missing(mv)) {
    na_conversion_missing(if (missing(x)) "x" else "mv", "mvencode", "mv")
  }
  na_encode(x, mv, "mv")
}

#' @rdname na_conversion
#' @export
na_if_value <- function(.x, .value) {
  if (missing(.x) || missing(.value)) {
    na_conversion_missing(
      if (missing(.x)) ".x" else ".value",
      "na_if_value",
      "value"
    )
  }
  na_decode(.x, .value)
}

#' @rdname na_conversion
#' @export
value_if_na <- function(.x, .value) {
  if (missing(.x) || missing(.value)) {
    na_conversion_missing(
      if (missing(.x)) ".x" else ".value",
      "value_if_na",
      "replacement"
    )
  }
  na_encode(.x, .value, ".value")
}

na_conversion_missing <- function(argument, fn, value) {
  stop(
    "Missing `",
    argument,
    "`. Use ",
    fn,
    "(x, ",
    value,
    ") or x |> ",
    fn,
    "(",
    value,
    ").",
    call. = FALSE
  )
}

# Each code is matched separately, so `mv` is a set of codes, as in Stata.
na_decode <- function(x, mv) {
  for (i in seq_along(mv)) {
    x <- dplyr::na_if(x, mv[i])
  }
  x
}

na_encode <- function(x, mv, argument) {
  if (inherits(x, "haven_labelled_spss")) {
    # User-missing codes are missing under is.na(), but not for vctrs/tidyr.
    replacement <- vctrs::vec_cast(mv, vctrs::vec_ptype(x))
    if (length(replacement) != 1L) {
      stop(
        "`",
        argument,
        "` must be a single replacement value.",
        call. = FALSE
      )
    }
    x[is.na(x)] <- replacement
    return(x)
  }
  tidyr::replace_na(x, mv)
}
