#' Flag the first row of each group
#'
#' @description
#' `is_first()` is `TRUE` for the first row of each distinct combination of
#' its arguments and `FALSE` for the others, like Stata's
#' `egen t = tag(id year)`. Use it in [dplyr::mutate()] or [dplyr::filter()],
#' for example to count or summarise each group once.
#'
#' Unlike [duplicates_tag()], which counts the other rows sharing the same
#' values, `is_first()` marks one row per group.
#'
#' @param ... Vectors of equal length that define the groups. Omit them in
#' grouped [dplyr::mutate()] (or with `.by`) to flag the first row of each
#' group.
#' @param .missing A single `TRUE` or `FALSE`. If `FALSE` (default), rows with
#' a missing value in any argument are `FALSE`, as Stata's `tag()` does
#' without its `missing` option. If `TRUE`, missing values form groups of
#' their own.
#'
#' @return A logical vector. "First" follows the current row order, so sort
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
#' @export
is_first <- function(..., .missing = FALSE) {
  check_flag(.missing, ".missing")
  keys <- list(...)
  if (!length(keys)) {
    size <- tryCatch(dplyr::n(), error = function(e) {
      stop(
        "Supply the variables that define the groups, or call `is_first()` ",
        "inside a grouped `mutate()`.",
        call. = FALSE
      )
    })
    return(seq_len(size) == 1L)
  }
  sizes <- lengths(keys)
  if (any(sizes != sizes[[1L]])) {
    stop(
      "All arguments to `is_first()` must have the same length.",
      call. = FALSE
    )
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
