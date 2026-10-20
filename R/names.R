#' List column names by tidyselect
#'
#' @param .data A data frame, tibble, or data.table. `ds()` also accepts a
#'   character vector representing a name inventory, such as an earlier
#'   `ds()` result. Inventory entries must be unique, nonempty, and nonmissing;
#'   the vector's own names are ignored. An empty inventory is allowed.
#' @param ... <[`tidy-select`][dplyr_tidy_select]> Existing columns to
#' select or rename. Omit to include all columns. Computed columns are not
#' created by this argument.
#'
#' @return `ds()` returns a character vector. `ds_as_column()` returns a table
#' with one character column, `name` (`names_as_column()` is a deprecated
#' alias). On ungrouped data, an empty selection returns a zero-length
#' vector or a zero-row table, respectively. Tables preserve the input's
#' data.frame, tibble, or data.table container and supported preview settings,
#' but do not recreate grouping or arbitrary subclasses on the new rows.
#'
#' @details
#' Selection order and renamed column names follow [dplyr::select()]. On a
#' grouped data frame, selection retains grouping columns and can emit a
#' message when they were not explicitly selected. Ungroup first to select
#' independently of grouping columns. The input data are not modified.
#' For character inventories, select by names, positions, or name helpers and
#' rename as usual. Data-type predicates such as `where(is.numeric)` are not
#' available because an inventory contains no column data.
#'
#' @name names
#' @seealso [variables()], [codebook()], [browse()]
#'
#' @examples
#' ds(starwars) # equivalent to names(starwars)
#' ds(starwars, homeworld:starships)
#' ds_as_column(starwars, ends_with("color"))
#' ds_as_column(starwars, where(is.character))
#'
#' # Save a programmatic selection for later stages of a pipeline.
#' numeric_names <- ds(lifeexp, where(is.numeric))
#' dplyr::select(lifeexp, dplyr::all_of(numeric_names))
#' ds(numeric_names, dplyr::starts_with("pop"))

#' @rdname names
#' @export
ds <- function(.data, ...) {
  if (is.character(.data) && is.null(dim(.data))) {
    if (anyNA(.data) || any(!nzchar(trimws(.data))) || anyDuplicated(.data)) {
      stop(
        "A name inventory must contain unique, nonempty, nonmissing names.",
        call. = FALSE
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

#' @rdname names
#' @export
ds_as_column <- function(.data, ...) {
  out <- tibble::as_tibble_col(ds(table_working_data(.data), ...), "name")
  table_restore(out, .data)
}
