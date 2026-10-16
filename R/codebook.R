#' View the codebook of a dataset or selected columns
#'
#' @description
#' `r lifecycle::badge("experimental")`
#' `codebook()` is a function to view the
#' codebook of a dataset or selected variables.
#'
#' @param .data The input data (data frame or tibble).
#' @param ...  <[`tidy-select`][dplyr_tidy_select]> or
#' <[`data-masking`][args_data_masking]> Variables to include in the codebook.
#' *This argument can be omitted*.
#'
#' @return A tibble. The label column is included when at least one selected
#' variable has a label attribute; unlabelled variables then have `NA` labels.
#' @name codebook
#' @seealso [ds()], [variables()], [browse()]
#'
#' @examples
#' starwars
#'
#' codebook(starwars)
#'
#' codebook(starwars, 1:4)
#'
#' codebook(starwars, ends_with("color"))
#'
#' codebook(starwars, where(is.numeric))
#'
#' codebook(lifeexp)
#'

#' @rdname codebook
#' @export
codebook <- function(.data, ...) {
  # if ... is empty, select all variables
  if (!missing(...)) {
    .data <- s_select(.data, ...)
  }
  if (ncol(.data) == 0L) {
    return(tibble::tibble(
      variable = character(), type = character(),
      n = integer(), unique = integer()
    ))
  }

  out <- dplyr::summarise(
    .data,
    dplyr::across(tidyselect::everything(), codebook_var)
  ) %>%
    tidyr::pivot_longer(
      tidyselect::everything(),
      names_to = "variable"
    ) %>%
    tidyr::unnest_wider(value) %>%
    dplyr::mutate(
      type = dplyr::if_else(
        !is.na(unit),
        paste0(type, " [", unit, "]"),
        type
      )
    ) %>%
    dplyr::select(-unit)

  labels <- variable_labels(.data)
  if (any(!is.na(labels))) {
    out$label <- unname(labels[out$variable])
    out <- dplyr::relocate(out, label, .after = variable)
  }

  return(out)
}

# Helper function:
codebook_var <- function(var) {
  stat_tb <- tibble::tibble(
    type = s_type(var),
    unit = s_unit(var),
    n = sum(!is.na(var), na.rm = TRUE),
    unique = dplyr::n_distinct(var, na.rm = TRUE)
  )
  return(stat_tb)
}
