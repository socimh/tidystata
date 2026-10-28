#' Print selected rows once
#'
#' @description
#' Display selected rows in the console without storing print preferences.
#'
#' * `print_headtail()`: Print the first and last rows.
#' * `print_interval()`: Print evenly spaced rows.
#'
#' @inheritParams preview
#' @param width Console width passed to tibble formatting. `NULL` (default)
#'   uses the current console width; `Inf` shows every column.
#' @param ... Additional arguments passed to tibble formatting.
#' @param max_extra_cols,max_footer_lines Maximum number of additional columns
#'   to describe and footer lines to print, respectively. `NULL` uses tibble's
#'   defaults.
#'
#' @returns `.data`, unchanged and invisibly, including all rows, columns,
#'   classes, grouping, and any existing preview preferences.
#'
#' @details
#' Each call prints a temporary preview and returns the complete original table.
#' Existing groups share one row budget; they are not printed separately.
#'
#' Row budgets and omission markers follow [preview()]: head/tail output marks
#' an omitted middle with one row of dots; interval output has no separator
#' rows. Use `n = Inf` and `width = Inf` to print every row and column.
#'
#' @seealso [preview()] for persistent print preferences.
#'
#' @examples
#' print_headtail(lifeexp, n = 6)
#'
#' print_interval(lifeexp, n = 6)
#'
#' @name special-print
#' @family one-time printing functions
NULL

#' @rdname special-print
#' @export
print_headtail <- function(
  .data,
  n = 10,
  width = NULL,
  ...,
  max_extra_cols = NULL,
  max_footer_lines = NULL
) {
  print(
    preview(.data, "headtail", n),
    width = width,
    ...,
    max_extra_cols = max_extra_cols,
    max_footer_lines = max_footer_lines
  )
  invisible(.data)
}

#' @rdname special-print
#' @export
print_interval <- function(
  .data,
  n = 10,
  width = NULL,
  ...,
  max_extra_cols = NULL,
  max_footer_lines = NULL
) {
  print(
    preview(.data, "interval", n),
    width = width,
    ...,
    max_extra_cols = max_extra_cols,
    max_footer_lines = max_footer_lines
  )
  invisible(.data)
}
