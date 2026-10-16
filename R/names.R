#' List column names by tidyselect
#'
#' @param .data A data frame or tibble.
#' @param ... <[`tidy-select`][dplyr_tidy_select]> Existing columns to
#' select or rename. Omit to include all columns. Computed columns are not
#' created by this argument.
#'
#' @return `ds()` returns a character vector. `ds_as_column()` and
#' `names_as_column()` are equivalent and return a tibble with one character
#' column, `name`. On ungrouped data, an empty selection returns a zero-length
#' vector or a zero-row tibble, respectively.
#'
#' @details
#' Selection order and renamed column names follow [dplyr::select()]. On a
#' grouped data frame, selection retains grouping columns and can emit a
#' message when they were not explicitly selected. Ungroup first to select
#' independently of grouping columns. The input data are not modified.
#'
#' @name names
#' @seealso [variables()], [codebook()], [browse()]
#'
#' @examples
#' ds(starwars) # equivalent to names(starwars)
#' ds(starwars, homeworld:starships)
#' ds_as_column(starwars, ends_with("color"))
#' names_as_column(starwars, where(is.character))
#'
#' # Save a programmatic selection for later stages of a pipeline.
#' numeric_names <- ds(lifeexp, where(is.numeric))
#' dplyr::select(lifeexp, dplyr::all_of(numeric_names))

#' @rdname names
#' @export
ds <- function(.data, ...) {
  if (missing(...)) {
    return(names(.data))
  }
  names(dplyr::select(.data, ...))
}

#' @rdname names
#' @export
ds_as_column <- function(.data, ...) {
  names_as_column(.data, ...)
}

#' @rdname names
#' @export
names_as_column <- function(.data, ...) {
  tibble::as_tibble_col(ds(.data, ...), "name")
}
