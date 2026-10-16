#' Summarise columns
#'
#' `r lifecycle::badge("experimental")`
#' Enhanced `summarise()`.
#'
#' @inheritParams tab
#' @inheritParams dplyr::summarise
#' @param .data A data frame, data frame extension (e.g. a tibble), or a vector.
#' @param .keep_all A logical. If `TRUE`, all variables are kept.
#' @param .detail A logical. If `TRUE`, the detailed summary is returned.
#' @param .stat A character vector.
#' If specified, only the listed statistics are returned.
#' Supported names are `type`, `n`, `unique`, `miss_n`, `valid_pct`, `min`, `q1`,
#' `median`, `mean`, `mad`, `sd`, `q3`, `max`, `iqr`, `skew`, `kurtosis`,
#' `se`, and `sum`. Aliases `missing`, `p25`, `p50`, and `p75` select
#' `miss_n`, `q1`, `median`, and `q3`; requested names and order are retained.
#' `sum` applies to numeric summaries, not calendar dates or datetimes.
#' Date/datetime summaries support counts, percentiles, location and spread,
#' but not skewness or kurtosis.
#' @param .na.rm A logical. If `TRUE`, rows where the `.by` grouping variable
#' is `NA` are dropped before summarising. Default is `FALSE`.
#' @param .name A logical. If `TRUE` (default), the `name` column is always
#' shown. If `FALSE`, the `name` column is dropped when only one variable is
#' summarised.
#' @param .mode A character string. Either "list" (default) or "table". 
#' If "list", returns a list of tables grouped by variable type (numeric, date, datetime).
#' If "table", returns a single table with all variables (dates formatted as strings).
#' When numeric and calendar summaries share a table, common formatted
#' statistic columns are character; count columns remain numeric.
#' @param .duration_format A character string. Either "long" (default) or "compact".
#' Controls how durations (SD for dates) are formatted:
#' "long" shows "548 days", "compact" shows "548d".
#' @details Numeric/logical columns with no observed values are retained,
#' including zero-row inputs: `n` and `unique` are zero and summary statistics
#' are `NA` (including `sum`). Missing counts retain the number of input rows.
#' Zero-row grouped inputs do not create artificial groups.
#' @name summ
#'
#' @return A tibble, data.frame, data.table, or list (depending on .mode and input class)
#' @export
#'
#' @examples
#' summ(lifeexp)
#'
#' summ(lifeexp, .by = region)
#'
#' tabstat(lifeexp, .by = region)
#'
#' lifeexp %>%
#'   summ(
#'     dplyr::where(is.numeric),
#'     .by = region,
#'     .stat = c("mean", "sd")
#'   )
#'
#' # Drop NA in grouping variable
#' summ(lifeexp, .by = region, .na.rm = TRUE)
#'
#' # Return list grouped by type
#' summ(lifeexp, .mode = "list")
#'
#' # Use long duration format
#' summ(lifeexp, .duration_format = "long")
summ <- function(
    .data, ...,
    .by = NULL,
    .keep_all = FALSE,
    .detail = FALSE,
    .stat = character(0),
    .na.rm = FALSE,
    .name = TRUE,
    .mode = c("list", "table"),
    .duration_format = c("long", "compact")) {
  
  # Match arguments
  summ_stat_names(.stat)
  .mode <- match.arg(.mode)
  .duration_format <- match.arg(.duration_format)
  
  # Store original class for later restoration
  original_class <- class(.data)[1]
# Handle vector input
  if (!is.data.frame(.data)) {
    var_name <- deparse(substitute(.data))
    if (length(var_name) > 1) var_name <- "value"
    .data <- tibble::as_tibble_col(.data, column_name = var_name)
    original_class <- "data.frame"
  }
  
  # Convert data.table to tibble for processing (if needed)
  is_dt <- FALSE
  if (inherits(.data, "data.table")) {
    if (!requireNamespace("data.table", quietly = TRUE)) {
      stop("data.table package required for data.table input. Install with: install.packages('data.table')")
    }
    is_dt <- TRUE
    .data <- tibble::as_tibble(.data)
  }

  # Identify group variables
  by <- rlang::enquo(.by)
  group_vars <- extract_group_var(.data, by)

  # 3.4: Drop NA rows in grouping variables if requested
  if (.na.rm && length(group_vars) > 0) {
    .data <- .data %>%
      dplyr::filter(
        dplyr::if_all(
          tidyselect::all_of(group_vars),
          ~ !is.na(.x)
        )
      )
  }

  # Prepare data
  .data_summ <- remove_group_vars(
    .data, ...,
    group_vars = group_vars
  )

  # Confirm variables
  check_numeric(.data_summ, .keep_all)
  check_missing(.data_summ, .keep_all)
  .data_num <- check_summarise(.data_summ)
  check_factor(.data_num)
  check_label(.data_num)

  # Add group variables
  if (.keep_all == TRUE) {
    .data <- keep_useful_vars(.data, .data_summ, group_vars)
  } else {
    .data <- keep_useful_vars(.data, .data_num, group_vars)
  }

  out <- summ_list(.data, group_vars, .detail, .stat, .mode, .duration_format)

  # 3.5: Drop name column when summarising a single variable
  if (!.name && is.data.frame(out) && "name" %in% names(out)) {
    if (dplyr::n_distinct(out$name) == 1L) {
      out <- dplyr::select(out, -name)
    }
  }
  
  # Convert output back to original class (for table mode)
  if (.mode == "table" && is.data.frame(out)) {
    if (original_class == "data.frame") {
      out <- as.data.frame(out)
    } else if (is_dt) {
      out <- data.table::as.data.table(out)
    }
  }

  return(out)
}

#' @rdname summ
#' @export
tabstat <- function(
    .data, ...,
    .by = NULL,
    .keep_all = FALSE,
    .detail = FALSE,
    .stat = "mean",
    .na.rm = FALSE,
    .name = TRUE,
    .mode = c("list", "table"),
    .duration_format = c("long", "compact")) {
  return(
    summ(
      .data, ...,
      .by = {{ .by }},
      .keep_all = .keep_all,
      .detail = .detail,
      .stat = .stat,
      .na.rm = .na.rm,
      .name = .name,
      .mode = .mode,
      .duration_format = .duration_format
    )
  )
}
