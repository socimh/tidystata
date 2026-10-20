#' Convert vectors for data preparation
#'
#' Character input to `as_numeric()` is parsed with [readr::parse_number()],
#' preserving its length. Invalid numbers generate parsing warnings. Factors
#' return their level codes; labelled numeric variables return their values.
#' `as_character()` uses value labels when a labelled vector has a nonempty
#' `labels` attribute. Without value labels, it uses ordinary character
#' conversion, including for tagged missing values.
#'
#' SPSS user-missing codes remain values in both conversions. Numeric conversion
#' preserves tagged missing values. Dates become days since 1970-01-01;
#' date-times become seconds since the Unix epoch. Durations and measured
#' vectors retain their numeric values in their existing units.
#'
#' @name type_conversion
#' @param .x A vector or matrix.
#' @return `as_character()` returns a character vector. `as_numeric()` returns
#'   a double vector; unsupported types such as lists, raw vectors, and complex
#'   vectors return missing values of the same length. Empty inputs return
#'   typed empty vectors. Names, dimensions, labels, and units are dropped.
#'   Parsing failures retain [readr::problems()] diagnostics on the result.
#'   Conversion of large `integer64` values to double may lose precision and
#'   emits the underlying conversion warning.
#'
#' @examples
#' lifeexp |>
#'   dplyr::mutate(
#'     region_chr = as_character(region),
#'     region_num = as_numeric(region),
#'     region_fct = haven::as_factor(region),
#'     .keep = "used"
#'   )

#' @export
#' @rdname type_conversion
as_character <- function(.x) {
  if (inherits(.x, "haven_labelled") && length(attr(.x, "labels")) > 0L) {
    as.character(haven::as_factor(.x))
  } else {
    as.character(.x)
  }
}

#' @export
#' @rdname type_conversion
as_numeric <- function(.x) {
  if (length(.x) == 0L) {
    return(numeric())
  }

  type <- s_type(.x, .abbr = TRUE)
  if (type %in% c("units", "drtn", "time", "dttm", "fct", "ord")) {
    as.numeric(.x)
  } else if (inherits(.x, "haven_labelled")) {
    as.numeric(unclass(.x))
  } else if (is.character(.x)) {
    is_nan <- !is.na(.x) & trimws(.x) == "NaN"
    .x[is_nan] <- NA_character_
    .x <- readr::parse_number(.x)
    .x[is_nan] <- NaN
    .x
  } else if (!is_summable_chr(type)) {
    rep(NA_real_, length(.x))
  } else {
    as.numeric(.x)
  }
}
