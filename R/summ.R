#' Summarise columns
#'
#' `r lifecycle::badge("experimental")`
#' Compute one row of summary statistics per selected variable and group.
#' `tabstat()` delegates to `summ()` with `.stat = "mean"` by default.
#'
#' @param ... Variables to summarise, using tidyselect or data-masking
#' expressions (for example, `dplyr::where(is.numeric)` or `x_sq = x^2`).
#' If omitted, select all columns except grouping keys.
#' @param .data A data frame, data frame extension (e.g. a tibble), or a vector.
#' Matrix and data-frame columns are unsupported; use atomic or list columns.
#' @param .by Optional grouping columns, selected with tidyselect. An explicit
#' selection overrides existing `group_by()` groups; when omitted, existing
#' groups are used. Grouping columns are excluded from the measured variables.
#' @param .keep_all A single `TRUE` or `FALSE`. If `FALSE` (default), unsupported
#' nonnumeric columns are removed with a warning; an error is raised if none
#' of the selected columns can be summarised. If `TRUE`, character/list columns
#' retain counts and unique values, with numeric statistics set to `NA`.
#' Numeric-looking character values are not parsed.
#' @param .detail A single `TRUE` or `FALSE`. If `TRUE`, return all statistics
#' available for each variable type unless `.stat` selects a subset.
#' @param .stat A character vector. If nonempty, return only the listed
#' statistics, plus variable names, types and any grouping columns.
#' Supported names are `type`, `n`, `unique`, `miss_n`, `valid_pct`, `min`, `q1`,
#' `median`, `mean`, `mad`, `sd`, `q3`, `max`, `iqr`, `skew`, `kurtosis`,
#' `se`, and `sum`. Aliases `missing`, `p25`, `p50`, and `p75` select
#' `miss_n`, `q1`, `median`, and `q3`; requested names and order are retained.
#' Identical requested names are deduplicated; aliases and canonical names
#' may coexist. `sum` applies to numeric summaries, not calendar dates or
#' datetimes. Calendar summaries do not support `skew` or `kurtosis` either.
#' @param .na.rm A single `TRUE` or `FALSE`. If `TRUE`, remove rows missing
#' any grouping key before summarising. Default is `FALSE`. Missing measured
#' values are always omitted from numeric statistics, regardless of this flag.
#' @param .name A single `TRUE` or `FALSE`. If `TRUE` (default), retain the
#' `name` column. If `FALSE`, drop it only when one measured variable is
#' summarised, including zero-row grouped output.
#' @param .mode A character string. Either `"list"` (default) or `"table"`.
#' List mode returns a single table when one variable-type family is present,
#' otherwise a list named `numeric`, `date`, and/or `datetime`. The `numeric`
#' family also contains nonnumeric columns retained by `.keep_all`.
#' Table mode combines all families. Shared formatted statistic columns become
#' character when numeric and calendar summaries are combined; counts remain
#' numeric. Calendar locations and spreads are strings in both modes.
#' @param .duration_format A character string, `"long"` (default) or `"compact"`.
#' Controls calendar spread statistics such as SD: `"548 days"` versus `"548d"`.
#' Sub-minute datetime spreads are rounded to whole seconds for display.
#' @details
#' Counts and missing values:
#'
#' `n` counts observed values and `unique` counts distinct observed values.
#' `miss_n` counts missing values; `valid_pct` is the fraction observed, from
#' zero to one, and is `NA` for zero-row inputs. Missingness follows the original
#' vector's `is.na()` method, including SPSS user-missing values and ranges.
#' Retained list columns count complete element identities without flattening.
#' Columns with no observed values remain in the result: `n` and `unique` are
#' zero and location/spread statistics, including `sum`, are `NA`.
#' Zero-row grouped inputs do not create artificial groups.
#'
#' Numeric statistics:
#'
#' Numeric calculations use double precision. Large `integer64` values may
#' lose precision during conversion, with a warning.
#'
#' Logical values are treated as zero/one. Factors and ordered factors use
#' their underlying level codes with a warning. Numeric labelled vectors use
#' underlying values, excluding user-missing codes; label metadata is flagged
#' with a warning. Measured vectors and `difftime` use their original units.
#' In variable names, `*` marks labelled vectors, `**` marks factors and `***`
#' marks retained nonnumeric columns.
#'
#' SD uses the sample denominator (`n - 1`); `se` is SD divided by `sqrt(n)`.
#' Quantiles use R's default type 7, `mad` uses [stats::mad()] with its default
#' scaling, and `iqr` uses [stats::IQR()]. `skew` is the mean cubed deviation
#' divided by the sample SD cubed. `kurtosis` is the mean fourth-power deviation
#' divided by the sample SD to the fourth power, minus three (excess kurtosis).
#' These conventions are not promised to match Stata. For singleton or constant
#' inputs, undefined spread or moment statistics may be `NA` or `NaN`.
#'
#' Calendar output and grouping names:
#'
#' Date locations are displayed as `YYYY-MM-DD`; fractional days are not shown.
#' Datetime locations are displayed in UTC as `YYYY-MM-DD HH:MM`, without
#' seconds. Calendar spread statistics are formatted durations, not raw numbers.
#' Grouping keys that collide with summary metadata or internal pivot names
#' are renamed by prepending dots until unique among the input names, with
#' a message. The input data are not modified.
#' @name summ
#'
#' @return A tibble, or a list of tibbles in list mode when multiple
#' variable-type families are present. Table mode restores a base data.frame
#' or data.table for those input classes. Vector input uses its expression
#' as the variable name (or `value` for a multiline expression).
#' @export
#'
#' @examples
#' summ(lifeexp)
#' summ(lifeexp, .by = region)
#' tabstat(lifeexp, .by = region)
#'
#' lifeexp %>%
#'   summ(
#'     dplyr::where(is.numeric),
#'     .by = region,
#'     .stat = c("n", "mean", "sd", "p50")
#'   )
#'
#' # Remove rows missing a grouping key; measured NAs are always omitted
#' summ(lifeexp, .by = region, .na.rm = TRUE)
#'
#' # Keep numeric and calendar summaries in separate tables
#' mixed <- tibble::tibble(x = c(1, 3), day = as.Date("2024-01-01") + 0:1)
#' summ(mixed, .mode = "list", .duration_format = "compact")
summ <- function(
  .data,
  ...,
  .by = NULL,
  .keep_all = FALSE,
  .detail = FALSE,
  .stat = character(0),
  .na.rm = FALSE,
  .name = TRUE,
  .mode = c("list", "table"),
  .duration_format = c("long", "compact")
) {
  # Validate controls before data-dependent branching.
  controls <- list(
    .keep_all = .keep_all,
    .detail = .detail,
    .na.rm = .na.rm,
    .name = .name
  )
  for (argument in names(controls)) {
    value <- controls[[argument]]
    if (!is.logical(value) || length(value) != 1L || is.na(value)) {
      stop("`", argument, "` must be a single TRUE or FALSE.", call. = FALSE)
    }
  }
  summ_stat_names(.stat)
  .mode <- match.arg(.mode)
  .duration_format <- match.arg(.duration_format)

  # Store original class for later restoration
  original_class <- class(.data)[1]
  # Normalize vectors before grouping and selection.
  if (!is.data.frame(.data)) {
    var_name <- deparse(substitute(.data))
    if (length(var_name) > 1) {
      var_name <- "value"
    }
    .data <- tibble::as_tibble_col(.data, column_name = var_name)
    original_class <- "data.frame"
  }

  # Convert data.table to tibble for processing (if needed)
  is_dt <- FALSE
  if (inherits(.data, "data.table")) {
    if (!requireNamespace("data.table", quietly = TRUE)) {
      stop(
        "data.table package required for data.table input. Install with: install.packages('data.table')"
      )
    }
    is_dt <- TRUE
    .data <- tibble::as_tibble(.data)
  }

  # Identify group variables
  by <- rlang::enquo(.by)
  group_vars <- extract_group_var(
    if (rlang::quo_is_null(by)) .data else dplyr::ungroup(.data),
    by
  )
  .data <- dplyr::ungroup(.data)
  input_names <- names(.data)

  # Missing-key filtering does not change how measured missing values are handled.
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
    .data,
    ...,
    group_vars = group_vars
  )

  if (any(vapply(.data_summ, function(x) !is.null(dim(x)), logical(1)))) {
    stop(
      "Matrix/data-frame columns are not supported; use atomic or list columns.",
      call. = FALSE
    )
  }

  # Confirm variables
  check_numeric(.data_summ, .keep_all)
  check_missing(.data_summ, .keep_all)
  .data_num <- if (.keep_all && ncol(.data_summ) > 0L) {
    dplyr::select(.data_summ, tidyselect::where(is_summable))
  } else {
    check_summarise(.data_summ)
  }
  check_factor(.data_num)
  check_label(.data_num)

  # Add group variables
  if (.keep_all == TRUE) {
    .data <- keep_useful_vars(.data, .data_summ, group_vars)
  } else {
    .data <- keep_useful_vars(.data, .data_num, group_vars)
  }

  # Group keys must remain distinct from summary metadata and pivot fields.
  reserved <- c(
    "name",
    "value",
    "type",
    "n",
    "unique",
    "min",
    "mean",
    "sd",
    "max",
    "miss_n",
    "valid_pct",
    "q1",
    "median",
    "mad",
    "q3",
    "iqr",
    "skew",
    "kurtosis",
    "se",
    "sum",
    "missing",
    "p25",
    "p50",
    "p75"
  )
  for (position in which(group_vars %in% reserved)) {
    old_name <- group_vars[[position]]
    new_name <- paste0(".", old_name)
    while (new_name %in% c(input_names, names(.data))) {
      new_name <- paste0(".", new_name)
    }
    names(.data)[names(.data) == old_name] <- new_name
    group_vars[[position]] <- new_name
    message(
      "Grouping column `",
      old_name,
      "` renamed to `",
      new_name,
      "` to avoid summary-column collisions."
    )
  }
  measured_count <- ncol(.data) - length(group_vars)
  out <- summ_list(.data, group_vars, .detail, .stat, .mode, .duration_format)

  # A single measured variable can omit its otherwise redundant name column.
  if (!.name && is.data.frame(out) && "name" %in% names(out)) {
    if (measured_count == 1L) {
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
  .data,
  ...,
  .by = NULL,
  .keep_all = FALSE,
  .detail = FALSE,
  .stat = "mean",
  .na.rm = FALSE,
  .name = TRUE,
  .mode = c("list", "table"),
  .duration_format = c("long", "compact")
) {
  if (!is.data.frame(.data)) {
    var_name <- deparse(substitute(.data))
    if (length(var_name) > 1L) {
      var_name <- "value"
    }
    .data <- as.data.frame(tibble::as_tibble_col(.data, column_name = var_name))
  }
  return(
    summ(
      .data,
      ...,
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
