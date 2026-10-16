#' Enhanced select() with data-masking
#'
#' @param .data A data frame or tibble.
#' @param ... <[`tidy-select`][dplyr_tidy_select]> selections or
#' <[`data-masking`][args_data_masking]> expressions. Omit to return the input
#' unchanged.
#'
#' @return The result of [dplyr::select()] when selection succeeds, otherwise
#' the result of [dplyr::transmute()]. Data-frame classes and grouping follow
#' the successful operation; a tibble input returns a tibble.
#'
#' @details
#' Selection is attempted first. Its successful result is returned directly,
#' without trying data masking or repeating the operation. If selection fails,
#' expressions are evaluated with [dplyr::transmute()]. Warnings from the
#' successful operation are emitted; warnings from a failed attempt are not.
#' If both operations fail, the error includes both underlying messages.
#'
#' A failed selection can evaluate user code before the data-masking fallback.
#' For random draws or other expressions with side effects, compute the columns
#' with [dplyr::mutate()] first, then select their names. Grouping columns are
#' retained according to dplyr's selection and transformation rules.
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
  if (missing(...)) {
    return(.data)
  }

  errors <- list(select = NULL, transmute = NULL)
  for (mode in c("select", "transmute")) {
    warnings <- list()
    result <- tryCatch(withCallingHandlers({
      if (mode == "select") {
        dplyr::select(.data, ...)
      } else {
        dplyr::transmute(.data, ...)
      }
    }, warning = function(w) {
      warnings[[length(warnings) + 1L]] <<- w
      invokeRestart("muffleWarning")
    }), error = function(e) {
      errors[[mode]] <<- conditionMessage(e)
      NULL
    })
    if (is.null(errors[[mode]])) {
      for (w in warnings) {
        warning(w)
      }
      return(result)
    }
  }

  stop(
    "Neither <tidy-select> nor <data-masking> recognised the input.\n",
    "  select() error: ", errors$select, "\n",
    "  mutate() error: ", errors$transmute,
    call. = FALSE
  )
}
