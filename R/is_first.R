#' Flag the first row of each group
#'
#' @description
#' `is_first()` is `TRUE` for the first row of each distinct combination of
#' its arguments and `FALSE` for the others, like Stata's
#' `egen t = tag(id year)`. Use it in [dplyr::mutate()] or [dplyr::filter()],
#' for example to count or summarise each group once.
#'
#' Unlike [duplicates_tag()], which counts the other rows sharing the same
#' values, `is_first()` marks one row per group. `s_tag()` is an alias of
#' `is_first()`.
#'
#' @param ... Vectors of equal length that define the groups. Omit them in
#' grouped [dplyr::mutate()] (or with `.by`) to flag the first row of each
#' group.
#' @param .missing A single `TRUE` or `FALSE`. If `FALSE` (default), rows with
#' a missing value in any argument are `FALSE`, as Stata's `tag()` does
#' without its `missing` option. If `TRUE`, missing values form groups of
#' their own.
#'
#' @returns A logical vector. "First" follows the current row order, so sort
#' first when a particular row should be flagged.
#'
#' @examples
#' panel <- tibble::tibble(
#'   id = c(1, 1, 2, 2, 2, NA),
#'   year = c(2001, 2002, 2001, 2002, 2003, 2001)
#' )
#' dplyr::mutate(panel, first = is_first(id))
#'
#' # Count panels, like Stata's egen tag() followed by count if tag
#' sum(is_first(panel$id))
#'
#' # First row within each group
#' dplyr::mutate(panel, first = is_first(), .by = id)
#' @name is_first
#' @family data checking functions
NULL

#' @rdname is_first
#' @export
is_first <- function(..., .missing = FALSE) {
  check_bool(.missing)
  keys <- list(...)
  if (!length(keys)) {
    error_call <- rlang::current_env()
    size <- tryCatch(dplyr::n(), error = function(e) {
      cli::cli_abort(
        "Supply the variables that define the groups, or call {.fn is_first} inside a grouped {.fn dplyr::mutate}.",
        call = error_call
      )
    })
    return(seq_len(size) == 1L)
  }
  sizes <- lengths(keys)
  if (any(sizes != sizes[[1L]])) {
    cli::cli_abort("All arguments to {.fn is_first} must have the same length.")
  }
  names(keys) <- paste0("key", seq_along(keys))
  keys <- vctrs::new_data_frame(keys, n = sizes[[1L]])
  # A row is first when its group id points to itself.
  first <- vctrs::vec_duplicate_id(keys) == seq_len(nrow(keys))
  if (!.missing) {
    incomplete <- Reduce(
      `|`,
      lapply(keys, vctrs::vec_detect_missing),
      logical(nrow(keys))
    )
    first[incomplete] <- FALSE
  }
  first
}

#' @rdname is_first
#' @export
s_tag <- is_first
