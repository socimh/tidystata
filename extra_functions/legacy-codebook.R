#' View the codebook of a dataset or selected columns
#'
#' @description
#' `r lifecycle::badge("experimental")`
#' `codebook()` is a function to view the
#' codebook of a dataset or selected variables.
#'
#' `codebook_detail()` would show more detailed information.
#' It is a wrapper of `datawizard::data_codebook()` with a better output format.
#'
#' @param .data The input data (data frame or tibble).
#' @param ...  <[`tidy-select`][dplyr_tidy_select]> or
#' <[`data-masking`][args_data_masking]> Variables to include in the codebook.
#' *This argument can be omitted*.
#' @param .type The output type. Default for `codebook_detail()` is `"flextable"`.
#' @param n The number of rows to display. Default is `Inf`.
#' @inheritParams datawizard::data_codebook
#'
#' @return  A tibble or a flextable.
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
#' # codebook_detail() is less stable than codebook().
#' # Some column types may not be recognized.
#' lifeexp %>%
#'  dplyr::select(-region) %>%
#'  codebook_detail()

#' @rdname codebook
#' @export
codebook <- function(.data, ...) {
  # if ... is empty, select all variables
  if (!missing(...)) {
    .data <- s_select(.data, ...)
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

  contents <- suppressWarnings(Hmisc::contents(.data))$contents %>%
    tibble::as_tibble() %>%
    dplyr::select(dplyr::any_of(c("Labels")))

  if (ncol(contents) == 1) {
    out <- out %>%
      dplyr::bind_cols(
        contents %>%
          dplyr::rename(label = Labels)
      ) %>%
      dplyr::relocate(label, .after = variable)
  }

  return(out)
}

#' @rdname codebook
#' @export
codebook_detail <- function(.data, ..., .type = c("flextable", "tibble"), n = Inf, max_values = 10, range_at = 6, verbose = TRUE) {
  # if ... is empty, select all variables
  if (!missing(...)) {
    .data <- s_select(.data, ...)
  }

  out <- .data %>%
    datawizard::data_codebook(
      max_values = max_values,
      range_at = range_at,
      verbose = verbose
    ) %>%
    tibble::as_tibble() %>%
    dplyr::rename_with(
      stringr::str_to_lower
    ) %>%
    dplyr::rename_with(
      ~ stringr::str_replace_all(., " ", "_")
    ) %>%
    dplyr::rename(row_id = .row_id)

  if (.type[1] == "flextable") {
    flextable::as_flextable(out, max_row = n) %>%
      return()
  } else {
    print(out, n = n)
  }
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
