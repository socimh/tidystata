#' Convert vectors for data preparation
#'
#' @description
#' Prepare vectors using Stata-style conversion commands:
#'
#' * `destring()` (`as_numeric()`): Convert text to numbers; labelled numeric
#'   vectors use their stored values.
#' * `tostring()` (`as_character()`): Convert stored values to text, using
#'   numeric codes for labelled numeric vectors and factors rather than labels.
#' * `encode()`: Convert text categories to labelled integer codes, or retain
#'   a factor's integer codes with its levels as value labels.
#' * `decode()`: Convert values to text, using value labels for labelled
#'   vectors and level text for factors.
#'
#' @name type_conversion
#' @param x A vector or matrix. For `encode()`, a character vector or factor
#'   without dimensions. Data frames are not accepted; convert their columns
#'   with [dplyr::across()].
#' @param ignore `NULL` (default) or a single string of characters to remove
#'   from text before reading numbers, like Stata's `ignore()`. Each character
#'   is removed wherever it appears: `ignore = "kg "` removes `k`, `g` and
#'   spaces.
#'
#' @returns Results retain the length and element order of `x`:
#'
#' * `destring()` (`as_numeric()`): A double vector. Invalid numeric text adds
#'   a `problems` attribute readable with [readr::problems()].
#' * `tostring()` (`as_character()`): A character vector, except that character
#'   input is returned unchanged, including names, dimensions and attributes.
#' * `encode()`: A `haven_labelled` integer vector with value labels and the
#'   input's variable label, if present. Names and other attributes are dropped.
#' * `decode()`: A character vector containing value labels or converted values.
#'
#' Except for the preservation rules above, names, dimensions, labels and units
#' are dropped; matrices are flattened in column order. Empty inputs return
#' typed empty results. None of these functions modifies the input.
#'
#' @details
#' **Reading numbers**
#'
#' `destring()` reads text the way Stata's `destring` does. A value must be a
#' number, optionally with a sign, exponent, currency symbol (dollar, euro,
#' pound, yen), thousands separators (`1,234`), a trailing percent sign (`50%`
#' gives 50) and surrounding spaces, including non-breaking spaces. Anything
#' else, such as `"12abc"`, `"10 kg"` or a date, becomes `NA` with a warning,
#' like Stata's `force` option; the
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
#' Unsupported numeric-conversion inputs, such as lists, raw vectors and complex
#' vectors, return missing values of the same length.
#'
#' **Labels, missing values, and units**
#'
#' `decode()` uses value labels when a labelled vector has a nonempty `labels`
#' attribute. Without value labels, it uses ordinary character conversion,
#' including for tagged missing values, so 100000 gives `"1e+05"`; use
#' `tostring()` to write numbers in full.
#'
#' `destring()` and `decode()` keep SPSS user-missing codes as values or labels.
#' Numeric conversion preserves tagged missing values. Dates become days since
#' 1970-01-01; date-times become seconds since the Unix epoch. Durations and
#' measured vectors retain their numeric values in their existing units.
#' Conversion of large `integer64` values to double can lose precision and emits
#' the underlying conversion warning.
#'
#' **Encoding categories**
#'
#' `encode()` assigns codes 1, 2, 3, ... to distinct nonempty character values
#' in UTF-8 radix order. Numeric-looking text is a category: `"10"`, `"20"`,
#' `"3"` get codes 1, 2, 3, not the numbers 10, 20, 3. `NA` and `""` become
#' missing; spaces are retained. Radix ordering is reproducible but can differ
#' from locale-specific alphabetical ordering in Stata.
#'
#' For factors and ordered factors, `encode()` preserves the stored integer
#' indices and uses all levels as value labels, including unused levels and
#' explicit empty-string and `NA` levels. Numeric level text does not replace
#' indices: `factor(c(10, 20))` has codes 1 and 2. Ordering metadata is dropped.
#'
#' `encode(decode(x))` need not recover the original codes: decoding discards
#' the dictionary, so re-encoding character text creates new codes starting
#' at 1. Existing dictionaries cannot be supplied to `encode()`. Encode
#' character columns before grouping to use one dictionary across groups;
#' separate calls can assign conflicting codes. Factors with shared levels
#' retain a common dictionary within grouped `dplyr::mutate()`.
#'
#' `decode()` follows Stata's value-label conversion but also accepts factors,
#' labelled character vectors and unlabelled inputs as an R convenience. It
#' falls back to ordinary character conversion when no value labels exist.
#' For partial dictionaries, unlabelled values remain as text, whereas Stata
#' returns empty strings for them.
#'
#' **Text formatting**
#'
#' `tostring()` and its alias `as_character()` ignore value labels: labelled
#' numeric vectors and factors give their codes. For non-character input, values
#' flagged by `is.na()`, including `NaN`, tagged missing values, and SPSS
#' user-missing codes, become `NA`.
#' Character input is returned unchanged. Numbers are written in full, so 100000
#' gives `"100000"`, not `"1e+05"`, with the significant digits of
#' [as.character()] and a decimal point whatever `options(OutDec)` says.
#' This precision policy can map distinct large numbers to the same text;
#' keep identifiers as character or `integer64` vectors when exact digits matter.
#' AsIs wrappers are ignored for non-character input. Measured values and
#' durations are written as numbers in their existing units.
#' Dates use [as.character()], giving `"2024-01-31"` rather than day numbers.
#' Unlike Stata's `tostring`, missing values remain `NA` rather than becoming
#' the strings `"."` or `".a"` through `".z"`.
#'
#' The sjlabelled package also exports `as_numeric()` and `as_character()`. They
#' differ: sjlabelled's `as_numeric()` turns non-numeric text into factor codes,
#' and its `as_character()` gives `NA` for unlabelled values. Whichever package
#' is attached last masks the other; write `tidystata::as_numeric()` to be
#' explicit, or use `destring()` and `tostring()`, which do not clash. To read
#' value labels as text, use `decode()`.
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
#'
#' category <- encode(c("beta", "alpha", "beta", "", NA))
#' category
#' tostring(category) # integer codes as text
#' decode(category) # category text
#' encode(factor(c("Yes", "No"), levels = c("Unused", "No", "Yes")))
#' @family conversion functions

#' @export
#' @rdname type_conversion
destring <- function(x, ignore = NULL) {
  check_string(ignore, allow_null = TRUE)
  check_conversion_vector(x)
  if (length(x) == 0L) {
    return(numeric())
  }

  if (inherits(x, "AsIs")) {
    class(x) <- setdiff(attr(x, "class"), "AsIs")
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
        actual = unname(x[out$invalid])
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
# around it. Spaces include the non-breaking spaces of spreadsheet exports.
destring_currency <- "$\u20ac\u00a3\u00a5"
destring_space <- "[\\s\u00a0\u2007\u202f]"
destring_pattern <- paste0(
  "^",
  destring_space,
  "*(?:[",
  destring_currency,
  "]",
  destring_space,
  "*[-+]|[-+]?(?:[",
  destring_currency,
  "]",
  destring_space,
  "*)?)(?=\\.?\\d)",
  "(?:\\d{1,3}(?:,\\d{3})+|\\d*)(?:\\.\\d*)?(?:[eE][-+]?\\d+)?(?:",
  destring_space,
  "*%)?",
  destring_space,
  "*$"
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
    paste0("[", destring_currency, ",%\\s\u00a0\u2007\u202f]"),
    "",
    x[number],
    perl = TRUE
  ))
  space <- destring_space
  is_nan <- !number &
    grepl(paste0("^", space, "*NaN", space, "*$"), x, perl = TRUE)
  values[is_nan] <- NaN
  missing <- is.na(x) |
    grepl(paste0("^", space, "*(?:NA|\\.)?", space, "*$"), x, perl = TRUE)
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
  check_conversion_vector(x)
  if (inherits(x, "haven_labelled") && length(attr(x, "labels")) > 0L) {
    as.character(haven::as_factor(x))
  } else {
    as.character(x)
  }
}

#' @export
#' @rdname type_conversion
encode <- function(x) {
  if (missing(x)) {
    cli::cli_abort("Missing {.arg x}. Use {.code encode(x)}.")
  }
  if ((!is.character(x) && !is.factor(x)) || !is.null(dim(x))) {
    cli::cli_abort("{.arg x} must be a character vector or factor.")
  }
  label <- attr(x, "label", exact = TRUE)
  if (is.factor(x)) {
    labels <- levels(x)
    codes <- as.integer(x)
  } else {
    x <- enc2utf8(vctrs::vec_data(x))
    labels <- sort(unique(x[!is.na(x) & x != ""]), method = "radix")
    codes <- match(x, labels)
  }
  haven::labelled(
    codes,
    stats::setNames(seq_along(labels), labels),
    label = label
  )
}

#' @export
#' @rdname type_conversion
tostring <- function(x) {
  check_conversion_vector(x)
  if (is.character(x)) {
    return(x)
  }
  # Text uses a decimal point whatever the display option, as in Stata.
  rlang::local_options(OutDec = ".")
  if (inherits(x, "AsIs")) {
    class(x) <- setdiff(attr(x, "class"), "AsIs")
  }
  missing_value <- is.na(x)
  if (is.factor(x)) {
    x <- as.integer(x)
  } else if (inherits(x, "haven_labelled")) {
    x <- vctrs::vec_data(x)
  } else if (inherits(x, c("units", "difftime"))) {
    x <- as.numeric(x)
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

check_conversion_vector <- function(x, call = rlang::caller_env()) {
  if (is.data.frame(x)) {
    cli::cli_abort(
      c(
        "{.arg x} must be a vector, not a data frame.",
        i = "Convert columns with {.code dplyr::mutate(dplyr::across(...))}."
      ),
      call = call
    )
  }
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
as_character <- tostring

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
