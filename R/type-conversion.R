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
#' **Reading numbers with `destring()`**
#'
#' Text must contain a complete number. Signs, exponents, dollar/euro/pound/yen
#' symbols, thousands separators (`"1,234"`), trailing percent signs (`"50%"`
#' gives 50) and surrounding spaces, including non-breaking spaces, are accepted.
#' Use `ignore` to remove other characters first: `ignore = "kg"` lets
#' `"10 kg"` become 10.
#'
#' Invalid text becomes `NA` with a warning, like Stata's `force` option.
#' [readr::problems()] gives its positions and original values. Empty strings,
#' `"NA"` and `"."` become missing without a warning; `"NaN"` becomes `NaN`.
#' Date strings are invalid; parse them with [as.Date()] or `lubridate::ymd()`.
#'
#' Factors give their numeric level values only when every level, including
#' unused levels, parses as a number. Otherwise they give their integer codes.
#' Labelled vectors use their stored values, parsing text as above. SPSS
#' user-missing codes remain values, and tagged missing values retain their tags.
#' Lists, raw vectors and complex vectors give `NA` for each element.
#'
#' Dates become days since 1970-01-01; date-times become seconds since the Unix
#' epoch. Durations and measured values keep their numbers in the existing
#' units. Large `integer64` values can lose precision when converted to double,
#' with a warning from the underlying conversion.
#'
#' **Creating labels with `encode()`**
#'
#' Character categories receive codes 1, 2, 3, ... in UTF-8 radix order, which
#' is reproducible but may differ from Stata's locale-based ordering.
#' Numeric-looking text is still a category: `"10"`, `"20"`, `"3"` receive
#' codes 1, 2, 3. `NA` and `""` become missing; spaces are retained.
#'
#' Factors keep their integer codes and use all levels as labels, including
#' unused, empty-string and explicit `NA` levels. For example,
#' `factor(c(10, 20))` keeps codes 1 and 2. Ordered factors lose their ordering
#' metadata.
#'
#' Encode character columns before grouping so every group uses the same
#' codes. Separate calls can assign different codes; factors with shared
#' levels keep consistent codes in grouped `dplyr::mutate()`. You cannot supply
#' an existing label dictionary. Re-encoding decoded text creates a new
#' dictionary, so `encode(decode(x))` may change the original codes.
#'
#' **Reading labels with `decode()`**
#'
#' `decode()` uses value labels when available and factor levels for factors.
#' Values without a label remain as text, whereas Stata turns them into empty
#' strings. SPSS user-missing codes remain values or labels.
#'
#' Inputs without value labels use ordinary [as.character()] conversion,
#' including for tagged missing values. Thus 100000 may become `"1e+05"`;
#' use `tostring()` to write numbers in full. Unlike Stata's `decode`, this
#' function also accepts factors, labelled character vectors and unlabelled
#' inputs.
#'
#' **Writing text with `tostring()`**
#'
#' `tostring()` ignores value labels and converts factor codes to text.
#' Numbers are written in full (`100000` becomes `"100000"`), with the
#' significant digits of [as.character()] and a decimal point regardless of
#' `options(OutDec)`. Distinct large numbers can produce the same text; keep
#' identifiers as character or `integer64` vectors when exact digits matter.
#'
#' For non-character input, values flagged by `is.na()` become `NA`, including
#' `NaN`, tagged missing values and SPSS user-missing codes. Stata instead
#' writes missing values as `"."` or `".a"` through `".z"`. Character input is
#' unchanged. AsIs wrappers are ignored for other inputs; durations and
#' measured values use their existing units. Dates use [as.character()],
#' for example `"2024-01-31"`.
#'
#' The aliases `as_numeric()` and `as_character()` also exist in sjlabelled,
#' with different behavior: its numeric conversion codes non-numeric text as
#' factors, and its character conversion makes unlabelled values `NA`. Use
#' `tidystata::as_numeric()` or the names `destring()` and `tostring()` to
#' avoid depending on which package was attached last.
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
#'
#' # integer codes as text
#' tostring(category)
#'
#' # category text
#' decode(category)
#'
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
