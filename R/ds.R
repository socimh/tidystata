#' List column names by tidyselect
#'
#' @param .data A data frame, tibble, or data.table. `ds()` also accepts a
#'   character vector representing a name inventory, such as an earlier `ds()`
#'   result. Inventory entries must be unique, nonempty, and nonmissing; the
#'   vector's own names are ignored. An empty inventory is allowed.
#' @param ... <[`tidy-select`][dplyr_tidy_select]> Existing columns to select or
#'   rename. Omit to include all columns. Computed columns are not created by
#'   this argument.
#' @param .type Output form. `"vector"` (default) returns the selected names as
#'   a character vector, like Stata's `ds`. `"table"` returns a one-column table
#'   in the input's table class, or a tibble for a character inventory.
#'   `"tibble"` always returns a one-column tibble.
#'
#' @returns `ds()` returns a character vector. With `.type = "table"` or
#'   `"tibble"`, it returns one character column, `name`, and one row per
#'   selected name, in selection order. On ungrouped data, an empty selection
#'   returns a zero-length vector or zero-row table. Tables preserve the input's
#'   data.frame, tibble, or data.table container and supported preview settings,
#'   without grouping or arbitrary subclasses; character inventories return a
#'   tibble in table mode. Explicit `.type = "tibble"` overrides the input's
#'   table class and preview settings.
#'
#' @details
#' Selection order and renamed column names follow [dplyr::select()]. On a
#' grouped data frame, selection retains grouping columns and can emit a message
#' when they were not explicitly selected. Ungroup first to select independently
#' of grouping columns. The input data are not modified. For character
#' inventories, select by names, positions, or name helpers and rename as usual.
#' Data-type predicates such as `where(is.numeric)` are not available because an
#' inventory contains no column data.
#'
#' @name names
#' @seealso [variables()], [codebook()], [browse()]
#'
#' @examples
#' ds(lifeexp) # equivalent to names(lifeexp)
#'
#' ds(lifeexp, country:lexp)
#'
#' ds(lifeexp, where(is.character), .type = "table")
#'
#' starwars <- dplyr::starwars
#' ds(starwars, ends_with("color"), .type = "table")
#'
#' ds(starwars, ends_with("color"), .type = "tibble")
#'
#' # Save a programmatic selection for later stages of a pipeline.
#' numeric_names <- ds(lifeexp, where(is.numeric))
#' dplyr::select(lifeexp, dplyr::all_of(numeric_names))
#'
#' ds(numeric_names, dplyr::starts_with("pop"))
#' @family inspection functions

#' @rdname names
#' @export
ds <- function(.data, ..., .type = c("vector", "table", "tibble")) {
  if (!is.data.frame(.data) && !(is.character(.data) && is.null(dim(.data)))) {
    stop_input_type(.data, "a data frame or a character vector")
  }
  .type <- rlang::arg_match(.type)
  if (.type != "vector") {
    out <- tibble::as_tibble_col(ds(table_working_data(.data), ...), "name")
    return(table_restore(
      out,
      .data,
      if (.type == "tibble") "tibble" else "auto"
    ))
  }
  if (is.character(.data) && is.null(dim(.data))) {
    if (anyNA(.data) || any(!nzchar(trimws(.data))) || anyDuplicated(.data)) {
      cli::cli_abort(
        "A name inventory must contain unique, nonempty, nonmissing names."
      )
    }
    inventory <- unname(.data)
    if (missing(...)) {
      return(inventory)
    }
    selected <- tidyselect::eval_select(
      rlang::expr(c(!!!rlang::enquos(...))),
      stats::setNames(seq_along(inventory), inventory),
      allow_predicates = FALSE
    )
    return(names(selected))
  }
  if (missing(...)) {
    return(names(.data))
  }
  names(dplyr::select(.data, ...))
}
