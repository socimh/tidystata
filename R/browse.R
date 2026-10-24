#' Browse columns like Stata's `browse` command
#'
#' @description
#' Open all or selected columns in an interactive data viewer. Outside an
#' interactive session, no viewer is opened.
#'
#' @param .data A data frame or tibble.
#' @param ... <[`tidy-select`][dplyr_tidy_select]> or
#' <[`data-masking`][args_data_masking]> Variables to browse.
#' Omit to browse all columns. Selection and computed expressions follow
#' [select_or_mutate()].
#'
#' @returns The viewed data, invisibly, with its data-frame class preserved.
#' With no selection this is the input data; otherwise it is the result of
#' [select_or_mutate()]. The input is not modified.
#'
#' @details
#' Viewing uses [tibble::view()]. Existing grouping and grouping-key retention
#' follow [select_or_mutate()]. Assign the invisible return value to keep the viewed
#' columns for subsequent analysis. Precompute expressions with side effects
#' before passing them to the selection interface.
#' @family inspection functions
#' @export
#'
#' @seealso [ds()], [variables()], [codebook()]
#'
#' @examples
#' if (interactive()) {
#'   browse(lifeexp)
#'   browse(lifeexp, country:lexp)
#'   browse(lifeexp, varlist("*p*"))
#'
#'   # Retain the viewed columns for the next pipeline stage.
#'   selected <- browse(lifeexp, country, lexp, gnppc)
#'   summ(selected, lexp, gnppc)
#' }
browse <- function(.data, ...) {
  if (missing(...)) {
    tibble::view(.data)
  } else {
    .data |>
      select_or_mutate(...) |>
      tibble::view()
  }
}
