#' Browse columns like Stata's `browse` command
#'
#' Open all or selected columns in an interactive data viewer. Outside an
#' interactive session, no viewer is opened.
#'
#' @param .data A data frame, tibble, or data.table.
#' @param ... <[`tidy-select`][dplyr_tidy_select]> or
#'   <[`data-masking`][args_data_masking]> Columns to select or compute with
#'   [select_or_transmute()]. Existing columns, selection helpers, and named
#'   expressions can be mixed. Omit to browse all columns.
#'
#' @returns The viewed data, invisibly, with its data-frame class preserved.
#'   With no selection this is the input data; otherwise it is the result of
#'   [select_or_transmute()]. The input is not modified.
#'
#' @details
#' Viewing uses [tibble::view()]. Existing grouping and grouping-key retention
#' follow [select_or_transmute()]. Assign the invisible return value to keep the
#' viewed columns for subsequent analysis. Precompute expressions with side
#' effects before passing them to the selection interface.
#' @family inspection functions
#' @export
#'
#' @seealso [ds()], [variables()], [codebook()]
#'
#' @examples
#' if (interactive()) {
#'   browse(lifeexp)
#'
#'   browse(lifeexp, country:lexp)
#'
#'   browse(lifeexp, varlist("*p*"))
#'
#'   browse(lifeexp, country, gnppc_thousands = gnppc / 1000)
#'
#'   # Retain the viewed columns for the next pipeline stage.
#'   selected <- browse(lifeexp, country, lexp, gnppc)
#'   summ(selected, lexp, gnppc)
#' }
browse <- function(.data, ...) {
  check_data_frame(.data)
  if (missing(...)) {
    tibble::view(.data)
  } else {
    .data |>
      select_or_transmute(...) |>
      tibble::view()
  }
}
