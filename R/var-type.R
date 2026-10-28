#' Report an object's type or unit
#'
#' @description
#' Inspect an object's type and measurement metadata:
#'
#' * `var_type()`: Describe the object's storage type or class, optionally
#'   using an abbreviation.
#' * `var_unit()`: Report the measurement or duration unit, or `NA_character_`
#'   when the object has no unit.
#'
#' @name var_type
#' @param x An object.
#' @param abbr For `var_type()`, if `TRUE`, return an abbreviated type.
#'   Defaults to `FALSE`: expand known abbreviations and use full class names
#'   for default class abbreviations. Custom display labels are preserved.
#' @returns
#' * `var_type()`: One character string describing the type, including
#'   `"units"` for measured vectors in either abbreviation mode.
#' * `var_unit()`: The unit string for measured or duration vectors, including
#'   empty or all-missing measured vectors, or `NA_character_` when no unit is
#'   available.
#' @details
#' **Reading types and units**
#'
#' `var_type()` returns one display label per object, useful for column audits
#' such as `vapply(data, var_type, character(1))`. It describes storage and class
#' metadata, so empty and all-missing vectors retain their type. Haven-labelled
#' vectors add `+lbl` in abbreviation mode and `+label` otherwise.
#'
#' Plain matrices and arrays report their element type; data frames report their
#' container name. Dimensions are omitted. `var_unit()` reads units or duration
#' metadata, including hms times, and returns `NA_character_` otherwise. It also
#' respects custom unit methods for classes described as `units`, `drtn` or `time`.
#'
#' **Choosing an inspector**
#'
#' Use `var_type()` for readable reports. For exact type information in code:
#'
#' * [typeof()] gives storage type: factors, for example, are `"integer"`.
#'   `var_type()` distinguishes doubles, date-times and labelled doubles even
#'   though all three can have `"double"` storage.
#' * [class()] gives the full class vector; [inherits()] tests membership.
#'   `var_type()` reduces `c("ordered", "factor")` to `"ordered"`.
#' * [mode()] combines integers and doubles as `"numeric"`; `var_type()` keeps
#'   them distinct. [utils::str()] shows structure and example values rather
#'   than returning a single label.
#'
#' A display label does not retain full classes, attributes or structure.
#' A numeric-looking label alone does not imply support for numeric summaries.
#'
#' **Custom classes**
#'
#' Classed objects use [pillar::type_sum()] labels. With `abbr = FALSE`, known
#' abbreviations expand exactly (`int64` becomes `integer64`), and default class
#' abbreviations become full primary class names, such as `"dgCMatrix"`.
#' Registered or inherited display methods and explicit pillar labels take
#' precedence. Custom labels, including `I<int>`, `list<int>` and punctuation,
#' are preserved in both modes.
#'
#' A custom `pillar::type_sum()` method can control the label. An empty or
#' missing description falls back to the first class name; method errors
#' propagate.
#'
#' @family inspection functions
#'
#' @examples
#' var_type(1:10)
#'
#' var_type(1:10, abbr = TRUE)
#'
#' var_type(letters)
#'
#' # Compare storage, dispatch classes and readable type labels
#' objects <- list(
#'   score = 1.5,
#'   grade = ordered(c("low", "high"), levels = c("low", "high")),
#'   recorded = as.POSIXct("2026-01-01", tz = "UTC"),
#'   answer = haven::labelled(c(1, 2), labels = c(Yes = 1, No = 2))
#' )
#'
#' lapply(objects, function(x) {
#'   tibble::tibble(
#'     typeof = typeof(x),
#'     class = paste(class(x), collapse = ", "),
#'     var_type = var_type(x)
#'   )
#' }) |>
#'   dplyr::bind_rows(.id = "variable")
#'
#' # Type and unit describe different properties of the same object
#' elapsed <- as.difftime(c(1, 2, 3), units = "hours")
#' elapsed
#'
#' var_type(elapsed)
#'
#' var_unit(elapsed)

#' @export
#' @rdname var_type
var_type <- function(x, abbr = FALSE) {
  check_bool(abbr)
  # Plain storage types need no formatting or S3 dispatch. Matrix/array input
  # retains the established element-type description.
  type <- if (!is.object(x)) {
    switch(
      typeof(x),
      integer = "int",
      double = "dbl",
      character = "chr",
      logical = "lgl",
      complex = "cpl",
      raw = "raw",
      list = "list",
      NULL = "NULL",
      closure = "fn",
      builtin = "fn",
      special = "fn",
      environment = "env",
      symbol = "sym",
      language = "language",
      expression = "expression",
      pairlist = "pairlist",
      pillar::type_sum(x)
    )
  } else if (inherits(x, "haven_labelled")) {
    paste0(var_type(unclass(x), abbr = TRUE), "+lbl")
  } else {
    label <- pillar::type_sum(x)
    if (
      vctrs::obj_is_vector(x) && isTRUE(vctrs::vec_ptype_abbr(x) == "units")
    ) {
      label <- "units"
    }
    if (
      !is.character(label) ||
        length(label) != 1L ||
        is.na(label) ||
        !nzchar(label)
    ) {
      label <- class(x)[[1L]]
    }
    if (!is.null(dim(x))) sub("\\[[ ,0-9]*\\]$", "", label) else label
  }
  if (abbr) {
    return(type)
  }

  # Expand only recognized complete tokens, never substrings of custom labels.
  labelled <- inherits(x, "haven_labelled")
  token <- if (labelled) sub("\\+lbl$", "", type) else type
  expanded <- switch(
    token,
    int = "integer",
    dbl = "double",
    chr = "character",
    lgl = "logical",
    cpl = "complex",
    fct = "factor",
    ord = "ordered",
    dttm = "datetime",
    drtn = "duration",
    df = "dataframe",
    fn = "function",
    env = "environment",
    sym = "symbol",
    int64 = "integer64",
    var_type_class_label(x, token)
  )
  if (labelled) paste0(expanded, "+label") else expanded
}

var_type_class_label <- function(x, label) {
  if (!is.object(x) || !is.null(attr(x, "pillar", exact = TRUE))) {
    return(label)
  }
  primary <- class(x)[[1L]]
  if (identical(label, primary)) {
    return(label)
  }
  # The original display call already reports any abbreviation warnings.
  fallback <- unname(suppressWarnings(abbreviate(primary, 8L)))
  if (!identical(label, fallback)) {
    return(label)
  }

  # Inspect display-method provenance, including S4 inheritance, without
  # predicting upstream dispatch or overriding a potentially intentional label.
  lookup <- new.env(parent = parent.frame())
  lookup$type_sum <- pillar::type_sum
  lookup$vec_ptype_abbr <- vctrs::vec_ptype_abbr
  for (generic in c("type_sum", "vec_ptype_abbr")) {
    for (class_name in .class2(x)) {
      method <- utils::getS3method(
        generic,
        class_name,
        optional = TRUE,
        envir = lookup
      )
      if (!is.null(method)) {
        return(label)
      }
    }
  }
  primary
}

#' @export
#' @rdname var_type
var_unit <- function(x) {
  if (inherits(x, c("units", "difftime"))) {
    return(as.character(units(x)))
  }
  # Preserve custom unit-bearing classes while avoiding repeated type detection
  # for plain vectors, which cannot have a class-specific units method.
  if (
    is.object(x) && var_type(x, abbr = TRUE) %in% c("units", "drtn", "time")
  ) {
    return(as.character(units(x)))
  }
  NA_character_
}
