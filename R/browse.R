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
#' [s_select()].
#'
#' @returns The viewed data, invisibly, with its data-frame class preserved.
#' With no selection this is the input data; otherwise it is the result of
#' [s_select()]. The input is not modified.
#'
#' @details
#' Viewing uses [tibble::view()]. Existing grouping and grouping-key retention
#' follow [s_select()]. Assign the invisible return value to keep the viewed
#' columns for subsequent analysis. Precompute expressions with side effects
#' before passing them to the selection interface.
#' @family inspection functions
#' @export
#'
#' @seealso [ds()], [variables()], [codebook()]
#'
#' @examples
#' if (interactive()) {
#'   browse(starwars)
#'   browse(starwars, name:mass)
#'   browse(starwars, varlist("*color"))
#'
#'   # Retain the viewed columns for the next pipeline stage.
#'   selected <- browse(starwars, name, height, mass)
#'   summ(selected, height, mass)
#' }
browse <- function(.data, ...) {
  if (missing(...)) {
    tibble::view(.data)
  } else {
    .data %>%
      s_select(...) %>%
      tibble::view()
  }
}
