#' Report an object's type or unit
#'
#' @name var_type
#' @param x An object.
#' @param abbr A single `TRUE` or `FALSE`. If `TRUE`, the abbreviation of the
#'   type is returned.
#' @param .x,.abbr `r lifecycle::badge("deprecated")` Use `x` and `abbr`
#'   instead.
#' @returns A character. `var_type()` returns `"units"` for measured vectors
#' in either abbreviation mode. `var_unit()` returns the unit string for measured
#' or duration vectors, including empty or all-missing measured vectors, and
#' `NA_character_` for vectors without units.
#' @details
#' Types describe storage and class metadata, not the observed values: empty and
#' all-missing vectors retain their type. Known scalar abbreviations are expanded
#' exactly, including `int64` to `integer64`. Haven-labelled vectors append
#' `+lbl` in abbreviation mode and `+label` otherwise.
#'
#' Plain matrices and arrays retain their element-type description, and data
#' frames retain their container name without dimensions. Other classed objects
#' use their pillar type description, preserving punctuation and structured
#' labels such as `I<int>` and `list<int>` in both modes. An empty or missing
#' custom description falls back to the first class name; errors in custom
#' methods are propagated. Custom labels that merely start with a numeric
#' abbreviation do not make a class suitable for numeric summaries. Haven-label
#' conversion requires an actual haven-labelled class.
#'
#' `var_unit()` reads actual units/difftime metadata (including hms times), and
#' retains custom unit methods for classes describing themselves as `units`,
#' `drtn` or `time`. Other objects return `NA_character_`.
#' @family inspection functions
#' @export
#'
#' @examples
#' var_type(1:10)
#' var_type(letters)

#' @export
#' @rdname var_type
var_type <- function(
  x,
  abbr = FALSE,
  .x = lifecycle::deprecated(),
  .abbr = lifecycle::deprecated()
) {
  if (lifecycle::is_present(.x)) {
    lifecycle::deprecate_soft("0.2.0.9000", "var_type(.x)", "var_type(x)")
    # In old calls such as var_type(.x = v, TRUE), the positional value fills `x`.
    if (!missing(x) && missing(abbr)) {
      abbr <- x
    }
    x <- .x
  }
  if (lifecycle::is_present(.abbr)) {
    lifecycle::deprecate_soft("0.2.0.9000", "var_type(.abbr)", "var_type(abbr)")
    abbr <- .abbr
  }
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
    token
  )
  if (labelled) paste0(expanded, "+label") else expanded
}

#' @export
#' @rdname var_type
var_unit <- function(x, .x = lifecycle::deprecated()) {
  if (lifecycle::is_present(.x)) {
    lifecycle::deprecate_soft("0.2.0.9000", "var_unit(.x)", "var_unit(x)")
    x <- .x
  }
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
