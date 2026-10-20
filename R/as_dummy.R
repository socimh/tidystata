#' Create indicator (dummy) variables
#'
#' @description
#' Adds one 0/1 column per observed category of each selected variable, like
#' Stata's `tabulate x, generate(x_)`. The new columns are placed right after
#' their source variable. `tab_gen()` is an alias of `as_dummy()`.
#'
#' @inheritParams statart_args
#' @param ... <[`tidy-select`][dplyr_tidy_select]> The categorical variables
#' to expand.
#' @param .names How to name the new columns: `"value"` (default) appends the
#' category, as in `sex_male`; `"index"` numbers the categories, as in
#' `sex_1`, like Stata's `generate()` option.
#' @param .remove A single `TRUE` or `FALSE`. If `TRUE`, drop the source
#' variables.
#'
#' @returns `.data` with integer indicator columns, keeping its data.frame,
#' tibble, data.table, grouped or sf container. Each indicator is `1` when the
#' row has that category, `0` otherwise, and `NA` when the source value is
#' missing, as in Stata. Each new column has a `"label"` attribute such as
#' `"sex==male"`, as Stata's variable labels do; for labelled vectors the
#' label uses the value label.
#'
#' @details
#' Categories are the observed, non-missing values: factor levels in level
#' order (unused levels are skipped), and other values in ascending order. For
#' labelled vectors, `.names = "value"` uses the codes, such as `region_1`.
#' New names must not already exist in `.data`, and grouping keys cannot be
#' removed. For model formulas, R's factors already expand to dummies; use
#' `as_dummy()` when the indicator columns themselves are needed.
#'
#' @examples
#' as_dummy(starwars, sex)
#' as_dummy(starwars, sex, .names = "index", .remove = TRUE)
#' as_dummy(lifeexp, region)
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
  .names <- match.arg(.names)
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
  if (length(clash) || anyDuplicated(new_names)) {
    column <- c(clash, new_names[duplicated(new_names)])[[1L]]
    cli::cli_abort("Column {.var {column}} already exists; rename it first.")
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
    out <- data.table::copy(.data)
    for (name in names(columns)) {
      data.table::set(out, j = name, value = columns[[name]])
    }
    if (.remove) {
      data.table::set(out, j = selected, value = NULL)
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
  missing <- vctrs::vec_detect_missing(x)
  values <- vctrs::vec_unique(vctrs::vec_slice(x, !missing))
  if (is.factor(x)) {
    values <- factor(intersect(levels(x), as.character(values)), levels(x))
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
  names(out) <- paste0(var, "_", suffix)
  out
}

#' @rdname as_dummy
#' @export
tab_gen <- as_dummy
