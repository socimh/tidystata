#' Replace values with missing values or fill missing values
#'
#' @description
#' `mvdecode()` replaces specified codes with `NA`, like Stata's `mvdecode x,
#' mv(-98 -99)`. `mvencode()` fills missing values with a replacement, like
#' `mvencode x, mv(0)`.
#'
#' `na_if_value()` and `value_if_na()` are aliases of `mvdecode()` and
#' `mvencode()`.
#'
#' @details
#' Codes are matched with [dplyr::na_if()]; filling follows
#' [tidyr::replace_na()]. Codes and replacements are cast to the type of `x`, so
#' a lossy cast such as `1.5` for an integer vector is an error. Both the input
#' vector and the codes or replacement must be supplied. For SPSS labelled
#' vectors ([haven::labelled_spss()]), user-defined missing codes and ranges
#' also count as missing, matching their `is.na()` method; labels and
#' missing-value metadata are retained.
#'
#' @name na_conversion
#'
#' @param x A vector.
#' @param mv,value For `mvdecode()` and `na_if_value()`, the codes to replace
#'   with `NA`; any value equal to one of them becomes missing. For `mvencode()`
#'   and `value_if_na()`, a single replacement value for missing elements, cast
#'   to the type of `x`.
#' @returns A vector with the same type and size as `x`, with matching values
#'   replaced or missing values filled.
#'
#' @examples
#' x <- c(1, -99, NA, 4, -98)
#' mvdecode(x, -99)
#'
#' mvdecode(x, c(-98, -99))
#'
#' mvencode(c(1, NA, 4), 0)
#' @family conversion functions

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
na_if_value <- function(x, value) {
  if (missing(x) || missing(value)) {
    na_conversion_missing(
      if (missing(x)) "x" else "value",
      "na_if_value",
      "value"
    )
  }
  na_decode(x, value)
}

#' @rdname na_conversion
#' @export
value_if_na <- function(x, value) {
  if (missing(x) || missing(value)) {
    na_conversion_missing(
      if (missing(x)) "x" else "value",
      "value_if_na",
      "value"
    )
  }
  na_encode(x, value, "value")
}

na_conversion_missing <- function(
  argument,
  fn,
  value,
  call = rlang::caller_env()
) {
  cli::cli_abort(
    "Missing {.arg {argument}}. Use {.code {fn}(x, {value})} or {.code x |> {fn}({value})}.",
    call = call
  )
}

# Each code is matched separately, so `mv` is a set of codes, as in Stata.
na_decode <- function(x, mv) {
  for (i in seq_along(mv)) {
    x <- dplyr::na_if(x, mv[i])
  }
  x
}

na_encode <- function(x, mv, argument, call = rlang::caller_env()) {
  if (inherits(x, "haven_labelled_spss")) {
    # User-missing codes are missing under is.na(), but not for vctrs/tidyr.
    replacement <- vctrs::vec_cast(mv, vctrs::vec_ptype(x))
    if (length(replacement) != 1L) {
      cli::cli_abort(
        "{.arg {argument}} must be a single replacement value.",
        call = call
      )
    }
    x[is.na(x)] <- replacement
    return(x)
  }
  replace_missing(x, mv, argument, call = call)
}

# Missing values (including NaN) replaced by one value cast to the type of
# `x`, as tidyr::replace_na() does; a lossy cast is an error.
replace_missing <- function(
  x,
  replace,
  replace_arg = "replace",
  call = rlang::caller_env()
) {
  if (vctrs::vec_size(replace) != 1L) {
    cli::cli_abort(
      "{.arg {replace_arg}} must be a single replacement value.",
      call = call
    )
  }
  missing <- vctrs::vec_detect_missing(x)
  if (!any(missing)) {
    return(x)
  }
  vctrs::vec_assign(
    x,
    missing,
    replace,
    x_arg = "x",
    value_arg = replace_arg,
    call = call
  )
}
