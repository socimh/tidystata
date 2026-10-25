#' View the codebook of a dataset or selected columns
#'
#' @description
#' Inspect the types, observed counts, distinct observed values, and variable
#' labels of a dataset or selected columns.
#'
#' @param .data The input data (data frame, tibble, or data.table).
#' @param ...  <[`tidy-select`][dplyr_tidy_select]> or
#' <[`data-masking`][args_data_masking]> Variables to include in the codebook.
#' Omit to include all columns. Selection is attempted first; expressions that
#' are not valid selections are evaluated as computed columns by
#' [select_or_transmute()].
#'
#' @returns An ungrouped table with one row per selected variable, in selection
#' order. Columns are `variable`, optional `label`, `type`, `n`, and `unique`.
#' `n` counts observed values and `unique` counts distinct observed values.
#' Empty and all-missing columns have zero counts. A zero-column selection
#' returns zero rows with `variable`, `type`, `n`, and `unique` columns.
#' The input's data.frame, tibble, or data.table container and supported preview
#' settings are preserved. Other subclasses are not reconstructed.
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
#' codebook(lifeexp)
#'
#' codebook(lifeexp, 1:4)
#'
#' codebook(lifeexp, where(is.numeric))
#'
#' starwars <- dplyr::starwars
#'
#' codebook(starwars, films:starships)
#'
#' codebook(starwars, ends_with("color"))
#'
#' # Save a compact inventory before preparing an analysis sample.
#' survey <- tibble::tibble(age = c(30, NA, 45), income = c(2000, 3000, 4000))
#' attr(survey$income, "label") <- "Monthly earnings"
#' inventory <- codebook(survey, age, income)
#' inventory
#' codebook(survey, income_thousands = income / 1000)
#'
#' @family inspection functions

#' @rdname codebook
#' @export
codebook <- function(.data, ...) {
  template <- .data
  .data <- table_working_data(.data)
  .data <- dplyr::ungroup(.data)
  if (!missing(...)) {
    .data <- select_or_transmute(.data, ...)
  }
  vctrs::vec_as_names(names(.data), repair = "check_unique")
  if (ncol(.data) == 0L) {
    return(table_restore(
      tibble::tibble(
        variable = character(),
        type = character(),
        n = integer(),
        unique = integer()
      ),
      template
    ))
  }

  # Collect scalar metadata first, then construct the result once.
  rows <- lapply(.data, codebook_var)
  column <- function(name) unlist(lapply(rows, `[[`, name), use.names = FALSE)
  type <- column("type")
  unit <- column("unit")
  measured <- !is.na(unit)
  type[measured] <- paste0(type[measured], " [", unit[measured], "]")
  variables <- names(.data)
  out <- tibble::tibble(
    variable = variables,
    type = type,
    n = column("n"),
    unique = column("unique")
  )

  labels <- variable_labels(.data)
  if (any(!is.na(labels))) {
    out$label <- unname(labels[out$variable])
    out <- dplyr::relocate(out, "label", .after = "variable")
  }

  table_restore(out, template)
}

codebook_var <- function(var) {
  observed <- if (is.null(dim(var))) {
    !is.na(var)
  } else {
    rowSums(is.na(var)) == 0L
  }
  values <- vctrs::vec_slice(var, observed)
  list(
    type = var_type(var),
    unit = var_unit(var),
    n = sum(observed),
    unique = vctrs::vec_unique_count(values)
  )
}
