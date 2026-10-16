#' View the codebook of a dataset or selected columns
#'
#' @description
#' `r lifecycle::badge("experimental")`
#' Inspect the types, observed counts, distinct observed values, and variable
#' labels of a dataset or selected columns.
#'
#' @param .data The input data (data frame or tibble).
#' @param ...  <[`tidy-select`][dplyr_tidy_select]> or
#' <[`data-masking`][args_data_masking]> Variables to include in the codebook.
#' Omit to include all columns. Selection is attempted first; expressions that
#' are not valid selections are evaluated as computed columns by [s_select()].
#'
#' @return An ungrouped tibble with one row per selected variable, in selection
#' order. Columns are `variable`, optional `label`, `type`, `n`, and `unique`.
#' `n` counts observed values and `unique` counts distinct observed values.
#' Empty and all-missing columns have zero counts. A zero-column selection
#' returns zero rows with `variable`, `type`, `n`, and `unique` columns.
#'
#' @details
#' Counts describe the complete input, irrespective of existing grouping. Data
#' are ungrouped before selection, so omitted grouping keys are not reinserted.
#' With no selection, grouping-key columns are included like other columns.
#' The input data are not modified.
#'
#' Missingness is determined on the original column before counting. Ordinary
#' missing values, `NaN`, tagged missing values and SPSS user-missing codes or
#' ranges are excluded. List columns are counted by element identity without
#' flattening: scalar missing elements are excluded, while `NULL` and empty
#' elements remain observed values. Matrix and nested data-frame columns count
#' complete rows as observations; a row with any missing cell is excluded.
#'
#' Units are appended to `type` when available. Variable labels are read from
#' each column's `label` attribute, not its value-label mapping. The `label`
#' column appears only when at least one selected variable has a usable label;
#' unlabelled variables then have `NA` labels.
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
#' # Save a compact inventory before preparing an analysis sample.
#' survey <- tibble::tibble(age = c(30, NA, 45), income = c(2000, 3000, 4000))
#' attr(survey$income, "label") <- "Monthly earnings"
#' inventory <- codebook(survey, age, income)
#' inventory
#' codebook(survey, income_thousands = income / 1000)
#'

#' @rdname codebook
#' @export
codebook <- function(.data, ...) {
  .data <- dplyr::ungroup(.data)
  if (!missing(...)) {
    .data <- s_select(.data, ...)
  }
  vctrs::vec_as_names(names(.data), repair = "check_unique")
  if (ncol(.data) == 0L) {
    return(tibble::tibble(
      variable = character(),
      type = character(),
      n = integer(),
      unique = integer()
    ))
  }

  out <- purrr::imap(.data, function(value, name) {
    dplyr::bind_cols(tibble::tibble(variable = name), codebook_var(value))
  }) %>%
    purrr::list_rbind() %>%
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

  out
}

codebook_var <- function(var) {
  observed <- if (is.null(dim(var))) {
    !is.na(var)
  } else {
    rowSums(is.na(var)) == 0L
  }
  values <- vctrs::vec_slice(var, observed)
  tibble::tibble(
    type = s_type(var),
    unit = s_unit(var),
    n = sum(observed),
    unique = dplyr::n_distinct(values)
  )
}
