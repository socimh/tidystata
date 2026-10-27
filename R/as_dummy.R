#' Create indicator (dummy) variables
#'
#' @description
#' `as_dummy()` (`tab_gen()`) expands categorical variables into indicator
#' columns, like Stata's `tabulate x, generate(x_)`. It adds one 0/1 column per
#' observed category of each selected variable, placed right after its source
#' variable.
#'
#' @inheritParams tidystata_args
#' @param ... <[`tidy-select`][dplyr_tidy_select]> The categorical variables to
#'   expand.
#' @param .names How to name the new columns: `"value"` (default) appends the
#'   category, as in `sex_male`; `"index"` numbers the categories, as in
#'   `sex_1`, like Stata's `generate()` option.
#' @param .remove If `TRUE`, drop the source variables. Defaults to `FALSE`.
#'
#' @returns `.data` with integer indicator columns, keeping its data.frame,
#'   tibble, data.table, grouped or sf container and the original rows. Each
#'   indicator is `1` for its category, `0` otherwise, and `NA` for missing
#'   source values. New columns have a `"label"` attribute such as
#'   `"sex==male"`; for labelled vectors, this uses the value label.
#'
#' @details
#' Categories are the observed, non-missing values: factor levels in level order
#' (unused levels are skipped), and other values in ascending order. For
#' labelled vectors, `.names = "value"` uses the codes, such as `region_1`.
#' Missing values include tagged and SPSS user-missing values. New names must
#' not collide with retained columns; source names may be reused when
#' `.remove = TRUE`. Grouping keys cannot be removed. A positive-row data.table
#' result must retain at least one column: if selected variables have no
#' observed categories, retain a source variable or an identifier column.
#' For model formulas, R's factors already expand to dummies; use `as_dummy()`
#' when the indicator columns themselves are needed.
#'
#' @examples
#' as_dummy(lifeexp, region)
#'
#' as_dummy(lifeexp, region, .names = "index", .remove = TRUE)
#' @name as_dummy
#' @family variable generation functions
NULL

#' @rdname as_dummy
#' @export
as_dummy <- function(
  .data,
  ...,
  .names = c("value", "index"),
  .remove = FALSE
) {
  check_data_frame(.data)
  .names <- rlang::arg_match(.names)
  check_bool(.remove)
  data <- dplyr::ungroup(table_working_data(.data))
  selected <- names(tidyselect::eval_select(
    rlang::expr(c(...)),
    data,
    allow_rename = FALSE
  ))
  if (!length(selected)) {
    cli::cli_abort("Select at least one variable to expand.")
  }
  if (.remove && any(selected %in% dplyr::group_vars(.data))) {
    key <- intersect(selected, dplyr::group_vars(.data))[[1L]]
    cli::cli_abort(
      "Grouping key {.var {key}} cannot be removed; ungroup first or use {.code .remove = FALSE}."
    )
  }

  error_call <- rlang::current_env()
  dummies <- lapply(selected, function(var) {
    dummy_columns(data[[var]], var, .names, call = error_call)
  })
  names(dummies) <- selected
  new_names <- unlist(lapply(dummies, names), use.names = FALSE)
  clash <- intersect(new_names, setdiff(names(data), if (.remove) selected))
  if (length(clash)) {
    cli::cli_abort(
      "Column {.var {clash[[1L]]}} already exists; rename it first."
    )
  }
  if (anyDuplicated(new_names)) {
    column <- new_names[duplicated(new_names)][[1L]]
    cli::cli_abort(c(
      "Several values would create the same column {.var {column}}.",
      i = "Use {.code .names = \"index\"} or recode the values first."
    ))
  }

  order <- unlist(
    lapply(names(data), function(name) {
      if (!name %in% selected) {
        return(name)
      }
      c(if (!.remove) name, names(dummies[[name]]))
    }),
    use.names = FALSE
  )
  columns <- unlist(unname(dummies), recursive = FALSE)
  if (inherits(.data, "data.table")) {
    if (nrow(.data) > 0L && !length(order)) {
      cli::cli_abort(c(
        "A data.table result with rows must retain at least one column.",
        i = "Use {.code .remove = FALSE} to retain the source variables, or keep an identifier column."
      ))
    }
    out <- data.table::copy(.data)
    if (.remove) {
      data.table::set(out, j = selected, value = NULL)
    }
    for (name in names(columns)) {
      data.table::set(out, j = name, value = columns[[name]])
    }
    geometry <- setdiff(names(out), order)
    data.table::setcolorder(out, c(order, geometry))
    return(out)
  }
  out <- .data
  for (name in names(columns)) {
    out[[name]] <- columns[[name]]
  }
  # Columns outside the working data (such as sf geometry) stay at the end.
  out[c(order, setdiff(names(out), c(order, if (.remove) selected)))]
}

# Indicator columns for one variable, named and labelled as in Stata.
dummy_columns <- function(x, var, names, call = rlang::caller_env()) {
  if (is.list(x) || !is.null(dim(x))) {
    cli::cli_abort(
      "{.var {var}} is a list or matrix column and cannot be expanded.",
      call = call
    )
  }
  missing <- detect_missing(x)
  values <- vctrs::vec_unique(vctrs::vec_slice(x, !missing))
  if (is.factor(x)) {
    values <- factor(
      intersect(levels(x), as.character(values)),
      levels(x),
      ordered = is.ordered(x)
    )
  } else {
    values <- vctrs::vec_sort(values)
  }
  keys <- as.character(
    if (inherits(x, "haven_labelled")) {
      vctrs::vec_data(values)
    } else {
      values
    }
  )
  display <- if (inherits(x, "haven_labelled")) {
    as.character(haven::as_factor(values, levels = "default"))
  } else {
    keys
  }
  suffix <- if (names == "value") keys else seq_along(keys)
  out <- lapply(seq_along(keys), function(i) {
    hit <- as.integer(vctrs::vec_equal(x, vctrs::vec_slice(values, i)))
    hit[missing] <- NA_integer_
    attr(hit, "label") <- paste0(var, "==", display[[i]])
    hit
  })
  names(out) <- paste0(var, "_", suffix, recycle0 = TRUE)
  out
}

#' @rdname as_dummy
#' @export
tab_gen <- as_dummy
