#' Convert vectors for data preparation
#'
#' @description
#' Prepare vectors using Stata-style conversion commands:
#'
#' * `destring()` (`as_numeric()`): Convert text to numbers; labelled numeric
#'   vectors use their stored values.
#' * `decode()` (`as_character()`): Convert values to text, using value labels
#'   for labelled vectors and level text for factors.
#' * `tostring()`: Convert stored values to text, using numeric codes for
#'   labelled numeric vectors and factors rather than their labels.
#'
#' @name type_conversion
#' @param x A vector or matrix; a vector for `tostring()`.
#' @param ignore `NULL` (default) or a single string of characters to remove
#'   from text before reading numbers, like Stata's `ignore()`. Each character
#'   is removed wherever it appears: `ignore = "kg "` removes `k`, `g` and
#'   spaces.
#'
#' @returns `destring()` and `as_numeric()` return a double vector; `decode()`,
#'   `as_character()`, and `tostring()` return a character vector. Results have
#'   the same length as `x`; matrices are flattened in column order. Unsupported
#'   numeric-conversion inputs, such as lists, raw vectors, and complex vectors,
#'   return missing values of the same length. Empty inputs return typed empty
#'   vectors. Names, dimensions, labels, and units are dropped, except that
#'   `tostring()` returns character input unchanged, including its attributes.
#'   Invalid numeric text adds a `problems` attribute readable with
#'   [readr::problems()].
#'
#' @details
#' **Reading numbers**
#'
#' `destring()` reads text the way Stata's `destring` does. A value must be a
#' number, optionally with a sign, exponent, currency symbol (dollar, euro,
#' pound, yen), thousands separators (`1,234`), a trailing percent sign (`50%`
#' gives 50) and surrounding spaces. Anything else, such as `"12abc"`, `"10 kg"`
#' or a date, becomes `NA` with a warning, like Stata's `force` option; the
#' positions and original values are kept in [readr::problems()]. Use `ignore`
#' to remove other characters first, like Stata's `ignore()`: `destring(x,
#' ignore = "kg")` reads `"10 kg"` as 10. Empty strings, `"NA"` and Stata's
#' `"."` are missing without a warning; the text `"NaN"` becomes `NaN`. Date
#' strings become `NA`; parse them with [as.Date()] or `lubridate::ymd()`
#' instead.
#'
#' A factor whose levels are all numbers, such as `factor(c("1990", "2000"))`,
#' gives those numbers (1990, 2000). Other factors give their level codes.
#' Labelled numeric variables return their values; labelled text is read from
#' its values like plain text.
#'
#' **Labels, missing values, and units**
#'
#' `decode()` uses value labels when a labelled vector has a nonempty `labels`
#' attribute. Without value labels, it uses ordinary character conversion,
#' including for tagged missing values.
#'
#' `destring()` and `decode()` keep SPSS user-missing codes as values or labels.
#' Numeric conversion preserves tagged missing values. Dates become days since
#' 1970-01-01; date-times become seconds since the Unix epoch. Durations and
#' measured vectors retain their numeric values in their existing units.
#' Conversion of large `integer64` values to double can lose precision and emits
#' the underlying conversion warning.
#'
#' **Text formatting**
#'
#' `tostring()` ignores value labels: labelled numeric vectors and factors give
#' their codes. For non-character input, values flagged by `is.na()`, including
#' `NaN`, tagged missing values, and SPSS user-missing codes, become `NA`.
#' Character input is returned unchanged. Numbers are written in full, so 100000
#' gives `"100000"`, not `"1e+05"`, with at most 15 significant digits and a
#' decimal point whatever `options(OutDec)` says. Dates use [as.character()],
#' giving `"2024-01-31"` rather than day numbers.
#'
#' The sjlabelled package also exports `as_numeric()` and `as_character()`. They
#' differ: sjlabelled's `as_numeric()` turns non-numeric text into factor codes,
#' and its `as_character()` gives `NA` for unlabelled values. Whichever package
#' is attached last masks the other; write `tidystata::as_numeric()` to be
#' explicit, or use `destring()` and `decode()`, which do not clash.
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
destring <- function(x, ignore = NULL) {
  check_string(ignore, allow_null = TRUE)
  if (length(x) == 0L) {
    return(numeric())
  }

  type <- var_type(x, abbr = TRUE)
  if (type %in% c("fct", "ord")) {
    # Levels that are all numbers give their values, as Stata reads the text.
    # All levels decide, so every subset of a factor converts the same way.
    levels <- destring_text(levels(x), ignore)
    if (length(levels$values) && !anyNA(levels$values)) {
      return(levels$values[as.integer(x)])
    }
    as.numeric(x)
  } else if (type %in% c("units", "drtn", "time", "dttm")) {
    as.numeric(x)
  } else if (inherits(x, "haven_labelled") && !is.character(x)) {
    as.numeric(unclass(x))
  } else if (is.character(x)) {
    # Labelled text is read from its values, like plain text.
    x <- vctrs::vec_data(x)
    out <- destring_text(x, ignore)
    if (length(out$invalid)) {
      destring_warn(x[out$invalid])
      attr(out$values, "problems") <- tibble::tibble(
        row = out$invalid,
        col = NA_integer_,
        expected = "a number",
        actual = x[out$invalid]
      )
    }
    out$values
  } else if (!is_summable_chr(type)) {
    rep(NA_real_, length(x))
  } else {
    as.numeric(x)
  }
}

# A number with one optional sign (before or after one currency symbol),
# thousands separators, an exponent and a trailing percent sign, with spaces
# around it.
destring_currency <- "$\u20ac\u00a3\u00a5"
destring_pattern <- paste0(
  "^\\s*(?:[",
  destring_currency,
  "]\\s*[-+]|[-+]?(?:[",
  destring_currency,
  "]\\s*)?)(?=\\.?\\d)",
  "(?:\\d{1,3}(?:,\\d{3})+|\\d*)(?:\\.\\d*)?(?:[eE][-+]?\\d+)?(?:\\s*%)?\\s*$"
)

# Numbers read from text, with the positions of values that are not numbers.
# "NA", "." and blanks are missing without complaint; "NaN" stays NaN.
destring_text <- function(x, ignore = NULL) {
  x <- enc2utf8(as.character(x))
  if (!is.null(ignore)) {
    for (char in unique(strsplit(enc2utf8(ignore), "")[[1]])) {
      x <- gsub(char, "", x, fixed = TRUE)
    }
  }
  values <- rep(NA_real_, length(x))
  number <- grepl(destring_pattern, x, perl = TRUE)
  values[number] <- as.numeric(gsub(
    paste0("[", destring_currency, ",%\\s]"),
    "",
    x[number],
    perl = TRUE
  ))
  is_nan <- !number & grepl("^\\s*NaN\\s*$", x, perl = TRUE)
  values[is_nan] <- NaN
  missing <- is.na(x) | grepl("^\\s*(?:NA|\\.)?\\s*$", x, perl = TRUE)
  list(values = values, invalid = which(!(number | is_nan | missing)))
}

destring_warn <- function(text, call = rlang::caller_env()) {
  shown <- utils::head(unique(text), 3L)
  lead <- if (length(unique(text)) > 3L) ", such as" else ":"
  dates <- grepl(
    "^\\s*(?:\\d{4}[-/.]\\d{1,2}[-/.]\\d{1,2}|\\d{1,2}[-/.]\\d{1,2}[-/.]\\d{2,4})\\s*$",
    text,
    perl = TRUE
  )
  cli::cli_warn(
    c(
      "{length(text)} value{?s} {?is/are} not {?a number/numbers} and became {.code NA}{lead} {.val {shown}}.",
      i = "Use {.arg ignore} to remove other characters first, as in {.code destring(x, ignore = \"kg\")}.",
      i = if (any(dates)) {
        "Dates need {.fn as.Date} or {.fn lubridate::ymd}, not {.fn destring}."
      }
    ),
    call = call
  )
}

#' @export
#' @rdname type_conversion
decode <- function(x) {
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
  # Text uses a decimal point whatever the display option, as in Stata.
  rlang::local_options(OutDec = ".")
  missing_value <- is.na(x)
  if (is.factor(x)) {
    x <- as.integer(x)
  } else if (inherits(x, "haven_labelled")) {
    x <- vctrs::vec_data(x)
  }
  out <- as.character(x)
  if (is.numeric(x) && !is.object(x)) {
    # Rewrite exponents with the same 15 significant digits as as.character().
    exponent <- which(is.finite(x) & grepl("e", out, fixed = TRUE))
    out[exponent] <- tostring_fixed(x[exponent])
  }
  out[missing_value] <- NA_character_
  out
}

# Fixed notation from the 15 significant digits of "%.14e", padding with
# zeros. format(scientific = FALSE) prints platform-dependent digits beyond
# double precision for large magnitudes.
tostring_fixed <- function(x) {
  if (!length(x)) {
    return(character())
  }
  scientific <- sprintf("%.14e", abs(x))
  mantissa <- sub("e.*$", "", scientific)
  digits <- sub("0+$", "", sub(".", "", mantissa, fixed = TRUE))
  # Position of the decimal point after the leading digit.
  point <- as.integer(sub("^.*e", "", scientific)) + 1L
  size <- nchar(digits)
  body <- ifelse(
    point >= size,
    paste0(digits, strrep("0", pmax(point - size, 0L))),
    ifelse(
      point > 0L,
      paste0(substr(digits, 1L, point), ".", substr(digits, point + 1L, size)),
      paste0("0.", strrep("0", pmax(-point, 0L)), digits)
    )
  )
  paste0(ifelse(x < 0, "-", ""), body)
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
