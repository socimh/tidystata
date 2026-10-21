#' Convert vectors for data preparation
#'
#' Vector helpers named after Stata's conversion commands:
#'
#' * `destring()` (alias `as_numeric()`) converts text to numbers, like
#'   Stata's `destring`. Use `mutate(x = destring(x))`.
#' * `decode()` (alias `as_character()`) converts a labelled vector to its
#'   value labels, like Stata's `decode`.
#' * `tostring()` converts values to text and ignores value labels, like
#'   Stata's `tostring`: a labelled vector or factor gives its codes, and
#'   character input is returned unchanged. Missing values stay `NA`. Dates use
#'   [as.character()], so they become `"2024-01-31"` rather than day numbers.
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
#' @param x A vector or matrix; a vector for `tostring()`.
#' @param .x `r lifecycle::badge("deprecated")` Use `x` instead.
#' @returns `as_character()` and `tostring()` return a character vector. `as_numeric()` returns
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
#'     region_chr = decode(region),
#'     region_code = tostring(region),
#'     region_num = destring(region),
#'     region_fct = haven::as_factor(region),
#'     .keep = "used"
#'   )
#' @family conversion functions

#' @export
#' @rdname type_conversion
destring <- function(x, .x = lifecycle::deprecated()) {
  if (lifecycle::is_present(.x)) {
    lifecycle::deprecate_soft("0.3.0", "destring(.x)", "destring(x)")
    x <- .x
  }
  if (length(x) == 0L) {
    return(numeric())
  }

  type <- var_type(x, abbr = TRUE)
  if (type %in% c("units", "drtn", "time", "dttm", "fct", "ord")) {
    as.numeric(x)
  } else if (inherits(x, "haven_labelled")) {
    as.numeric(unclass(x))
  } else if (is.character(x)) {
    # Only strings containing "NaN" can trim to it; trimming all is slow.
    is_nan <- grepl("NaN", x, fixed = TRUE)
    is_nan[is_nan] <- trimws(x[is_nan]) == "NaN"
    x[is_nan] <- NA_character_
    x <- readr::parse_number(x)
    x[is_nan] <- NaN
    x
  } else if (!is_summable_chr(type)) {
    rep(NA_real_, length(x))
  } else {
    as.numeric(x)
  }
}

#' @export
#' @rdname type_conversion
decode <- function(x, .x = lifecycle::deprecated()) {
  if (lifecycle::is_present(.x)) {
    lifecycle::deprecate_soft("0.3.0", "decode(.x)", "decode(x)")
    x <- .x
  }
  if (inherits(x, "haven_labelled") && length(attr(x, "labels")) > 0L) {
    as.character(haven::as_factor(x))
  } else {
    as.character(x)
  }
}

#' @export
#' @rdname type_conversion
tostring <- function(x) {
  if (is.character(x)) {
    return(x)
  }
  missing_value <- is.na(x)
  if (is.factor(x)) {
    x <- as.integer(x)
  } else if (inherits(x, "haven_labelled")) {
    x <- vctrs::vec_data(x)
  }
  out <- as.character(x)
  out[missing_value] <- NA_character_
  out
}

#' @export
#' @rdname type_conversion
as_character <- decode

# Missing-value mask that also counts SPSS user-defined missing codes and
# ranges, as haven's is.na() method does; vctrs sees only the stored values.
detect_missing <- function(x) {
  if (inherits(x, "haven_labelled_spss")) {
    return(unname(is.na(x)))
  }
  vctrs::vec_detect_missing(x)
}

# Doubles behind a numeric labelled vector, with SPSS user-missing codes and
# ranges set to NA before the metadata is dropped. Stored NA, NaN and tagged NA
# values keep their payloads.
labelled_numeric <- function(x) {
  out <- as.numeric(vctrs::vec_data(x))
  out[detect_missing(x) & !is.na(out)] <- NA_real_
  out
}

#' @export
#' @rdname type_conversion
as_numeric <- destring
