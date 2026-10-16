#' Enhanced select() with data-masking
#'
#' @inheritParams tab
#'
#' @return A tibble
#' @export
#'
#' @examples
#' starwars %>%
#'   s_select()
#' starwars %>%
#'   s_select(name, height)
#' \dontrun{
#' starwars %>%
#'   dplyr::select(height > 50)
#' }
#' starwars %>%
#'   s_select(height > 50)
s_select <- function(.data, ...) {
  select_err  <- NULL
  mutate_err  <- NULL
  empty_dots  <- missing(...)

  select_works <- tryCatch({
    suppressWarnings(dplyr::select(.data, ...))
    TRUE
  }, error = function(e) {
    select_err <<- conditionMessage(e)
    FALSE
  })

  mutate_works <- tryCatch({
    suppressWarnings(dplyr::transmute(.data, ...))
    TRUE
  }, error = function(e) {
    mutate_err <<- conditionMessage(e)
    FALSE
  })

  if (!select_works && !mutate_works && !empty_dots) {
    # Build a more informative message showing both underlying errors
    detail <- paste0(
      "  select() error: ", select_err, "\n",
      "  mutate() error: ", mutate_err
    )
    stop(
      "Neither <tidy-select> nor <data-masking> recognised the input.\n",
      detail,
      call. = FALSE
    )
  }

  if (!empty_dots) {
    if (select_works) {
      .data <- dplyr::select(.data, ...)
    } else {
      .data <- dplyr::transmute(.data, ...)
    }
  }
  return(.data)
}
