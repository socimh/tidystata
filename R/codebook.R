#' Inspect a dataset's codebook
#'
#' Inspect the types, observed counts, distinct observed values, and variable
#' labels of a dataset or selected columns.
#'
#' @param .data A data frame, tibble, or data.table.
#' @param ... <[`tidy-select`][dplyr_tidy_select]> or
#'   <[`data-masking`][args_data_masking]> Columns to select or compute with
#'   [select_or_transmute()]. Existing columns, selection helpers, and named
#'   expressions can be mixed. Omit to include all columns.
#'
#' @returns An ungrouped table with one row per selected variable, in selection
#'   order, and columns `variable`, `type`, `n` (observed values), and `unique`
#'   (distinct observed values). A `label` column is included when labels are
#'   available. Empty or entirely missing columns have zero counts; selecting no
#'   columns returns zero rows with `variable`, `type`, `n`, and `unique`
#'   columns. The input's data.frame, tibble, or data.table container and
#'   supported preview settings are preserved; other subclasses are not
#'   reconstructed.
#'
#' @details
#' **Counting**
#'
#' * Counts ignore existing groups. Data are ungrouped before selection, so
#'   grouping columns can be omitted. The input data remain unchanged.
#' * Missing values, including `NaN`, tagged missing values, and SPSS
#'   user-missing values, are excluded.
#' * List columns count distinct elements without flattening; `NULL` and empty
#'   elements are included. Matrix and nested data-frame columns count complete
#'   rows, excluding rows with missing cells.
#'
#' **Labels and types**
#'
#' * Variable labels come from the `label` attribute, not value labels.
#'   Unlabelled variables receive `NA` when a label column is present.
#' * Units are appended to `type` when available.
#'
#' @name codebook
#' @seealso [ds()], [variables()], [browse()]
#'
#' @examples
#' # All variables
#' codebook(lifeexp)
#'
#' # Selected variables
#' codebook(lifeexp, 1:4)
#'
#' codebook(lifeexp, where(is.numeric))
#'
#' # Inspect an existing column alongside a computed column
#' codebook(lifeexp, country, gnppc_thousands = gnppc / 1000)
#'
#' starwars <- dplyr::starwars
#' codebook(starwars, films:starships)
#'
#' codebook(starwars, ends_with("color"))
#' @family inspection functions
#' @export
codebook <- function(.data, ...) {
  check_data_frame(.data)
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
