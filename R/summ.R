#' Summary statistics
#'
#' @description
#' Summarise selected variables, with one row per variable and group:
#'
#' * `summ()`: Report counts, distinct-value counts, minimum, mean, standard
#'   deviation, and maximum by default.
#' * `tabstat()`: Report means by default, using the same calculations and
#'   options as `summ()`.
#'
#' Both support `.detail = TRUE` for a fuller summary or `.stat` to select
#' statistics.
#'
#' @param .data A data frame, tibble, data.table, or vector. For `sf` data,
#'   only attributes are summarised; geometry columns are excluded.
#' @param ... <[`tidy-select`][dplyr_tidy_select]> or
#'   <[`data-masking`][args_data_masking]> Variables to summarise, or named
#'   expressions such as `income_k = income / 1000`. Defaults to all
#'   nongrouping columns except the weight column. Matrix and nested data-frame
#'   columns are not supported.
#' @param .by <[`tidy-select`][dplyr_tidy_select]> Optional grouping columns.
#'   Existing [dplyr::group_by()] groups are used unless `.by` is supplied.
#'   Grouping columns are excluded from the variables being summarised.
#' @param .keep_all If `TRUE`, retain character and list columns for counts and
#'   distinct values; other statistics for these columns are `NA`.
#'   By default, unsupported columns are omitted with a message.
#' @param .detail If `TRUE`, report all supported statistics unless `.stat`
#'   is supplied explicitly. Defaults to `FALSE`.
#' @param .stat Character vector of statistics to report. See Details for the
#'   complete list and calculation methods. An explicit selection determines
#'   the statistics and their order. Use `p0` to `p100` for percentiles,
#'   including decimals such as `p2.5`.
#' @param .missing If `TRUE` (default), retain observations with missing
#'   grouping keys as a separate group. If `FALSE`, exclude them. Missing
#'   measured values are always omitted from numeric calculations.
#' @param .name If `TRUE`, always include the `name` column. By default, it is
#'   omitted when exactly one variable is summarised.
#' @param .type Output form. `"list"` (default) returns separate tables when
#'   multiple variable families are present, or a single table for one family.
#'   `"table"` combines all families into one table, retaining the input's table
#'   class where supported. `"tibble"` combines them into one tibble regardless
#'   of the input's table class or preview settings.
#' @param .duration_format Retained for compatibility; no longer changes the
#'   output format of calendar spread statistics.
#' @param .sort If `TRUE` (default), sort groups by their keys. If `FALSE`,
#'   preserve the order in which groups appear in the data.
#' @param .drop_empty If `TRUE`, omit variable-group rows with `n = 0`,
#'   including rows with no observed measured values or zero total weight.
#'   Defaults to `FALSE`.
#' @param .wt Optional finite, nonnegative numeric weights, supplied as a
#'   column, one value per input row, or a scalar recycled to all rows. Rows
#'   with missing weights are excluded with a message.
#' @param .wt_type `"frequency"` (default) treats weights as frequencies;
#'   `"analytic"` rescales weights to the number of observed values within
#'   each variable and group. See Details for the calculation differences.
#'
#' @returns An ungrouped table, or a list of tables, with one row per variable
#'   and group. Each table contains grouping keys (if any), `name` (when
#'   applicable), `type`, and the selected statistics.
#'
#' By default, `summ()` returns `n`, `unique`, `min`, `mean`, `sd`, and `max`;
#' `tabstat()` returns `mean`. With `.type = "list"`, results are split into
#' `numeric`, `date`, `datetime`, and `time` tables only when multiple type
#' families occur. With `.type = "table"` or `"tibble"`, all types are combined
#' in one table. Results retain the input's usual table class where supported,
#' except that `.type = "tibble"` always returns a tibble.
#'
#' @details
#' Statistics are calculated separately for each selected variable and group.
#' The formulas below use non-missing measured values `x1, ..., xn`, with
#' `n` denoting their count and `xbar` their arithmetic mean. Unless weights
#' are supplied, calculations are unweighted.
#'
#' **Counts and completeness**
#'
#' * `type`: Variable type (metadata, not a calculated statistic).
#' * `n`: Number of non-missing values.
#' * `unique`: Number of distinct non-missing values.
#' * `miss_n`: Number of missing values (alias: `missing`).
#' * `valid_pct`: Proportion of rows with a non-missing value, between 0 and 1;
#'   `n / (n + miss_n)` without weights. It is **not** multiplied by 100.
#'
#' **Location and totals**
#'
#' * `min`, `max`: Smallest and largest observed values.
#' * `sum`: Arithmetic total, `sum(x)`. Available for numeric variables only.
#' * `mean`: Arithmetic mean, `sum(x) / n`.
#' * `q1` (`p25`), `median` (`p50`), `q3` (`p75`): 25th, 50th, and
#'   75th percentiles, respectively.
#' * `p0` to `p100`: Any requested percentile, including decimal percentages
#'   such as `p2.5`. Percentiles follow **Stata's rule**, not R's default
#'   [stats::quantile()] type 7. For sorted observations and percentile `p`,
#'   set `h = n * p / 100`. If `h` is not an integer, use the observation at
#'   position `ceiling(h)`; if `h` is an integer between 1 and `n - 1`, average
#'   the observations at positions `h` and `h + 1`. The endpoints are the
#'   minimum (`p0`) and maximum (`p100`). For example, the 25th percentile of
#'   `1:4` is 1.5, rather than 1.75 from type 7.
#'
#' **Variation and precision**
#'
#' * `sd`: Sample standard deviation,
#'   `sqrt(sum((x - xbar)^2) / (n - 1))`.
#' * `se`: Standard error of the mean, `sd / sqrt(n)`.
#' * `mad`: Median absolute deviation from the median, multiplied by 1.4826,
#'   as in [stats::mad()]. This is not a statistic reported by Stata's
#'   `summarize` command.
#' * `iqr`: Interquartile range, `q3 - q1`, using the percentiles above.
#'
#' **Distribution shape**
#'
#' Define `mk = sum((x - xbar)^k) / n`, the `k`th population central moment.
#'
#' * `skew`: Skewness, `m3 / m2^(3/2)`.
#' * `kurtosis`: Pearson kurtosis, `m4 / m2^2`. A normal distribution has
#'   kurtosis 3, not 0 (this is not excess kurtosis).
#'
#' Undefined statistics are `NA` (for example, `sd` when `n < 2` and the
#' shape statistics for constant variables). Columns with no observed values
#' have `n = 0`, `unique = 0`, and `NA` for numeric statistics, including `sum`.
#'
#' **When weights are supplied**
#'
#' Let `w` be the weights and `W = sum(w)` over non-missing measured values.
#'
#' * **Frequency weights** (`.wt_type = "frequency"`) use weights as given.
#'   The reported `n` is `W`; non-integer weights are permitted.
#' * **Analytic weights** (`.wt_type = "analytic"`) are rescaled within each
#'   variable and group so that `W` equals the number of observed values.
#'   Thus `n` remains on the sample-count scale.
#' * **Mean and spread:** `mean = sum(w * x) / W`,
#'   `sd = sqrt(sum(w * (x - mean)^2) / (W - 1))`, and
#'   `se = sd / sqrt(W)`. The two weight types give the same mean but can
#'   give different `sd` and `se` values. Both are `NA` when `W <= 1`.
#' * **Shape:** Skewness and kurtosis use weighted population central moments,
#'   `mk = sum(w * (x - mean)^k) / W`. They remain defined for `W > 0` when
#'   the population spread is nonzero, including fractional `W <= 1`.
#' * **Quantiles and MAD:** Percentiles use Stata's weighted percentile rule,
#'   replacing positions with cumulative weights; weighted `mad` uses the
#'   corresponding weighted medians. `min` and `max` exclude zero-weight rows.
#' * **Totals and counts:** `sum` is `sum(w * x)` using the *original*,
#'   unrescaled weights, even for analytic weights. `unique`, `miss_n`, and
#'   `valid_pct` continue to use unweighted row counts.
#'
#' The reported `se` is descriptive and does not account for a complex survey
#' design. For survey inference, use functions such as `survey::svymean()`.
#'
#' **Data types and grouping**
#'
#' Missingness follows `is.na()`, including SPSS user-missing codes. Logical
#' variables are treated as 0/1; factors use their underlying numeric codes;
#' labelled numeric variables use their stored values. Messages note such
#' conversions. Variable names are marked with `*` for labelled variables,
#' `**` for factors, and `***` for retained nonnumeric variables. Numeric
#' calculations use double precision, which may affect large `integer64` values.
#'
#' Dates and datetimes support location and spread statistics, but not `sum`,
#' `skew`, or `kurtosis`. Calendar locations are displayed as dates or times;
#' their spreads (`sd`, `se`, `mad`, `iqr`) are `difftime` values in list mode.
#' With `.type = "table"` or `"tibble"`, calendar locations are text and spreads
#' are numeric durations (days for Dates, seconds for datetimes and times of
#' day).
#'
#' Expressions in `...` are evaluated on ungrouped working data before
#' statistics are calculated by group. For group-specific expressions, first
#' create columns with grouped [dplyr::mutate()].
#'
#' @name summ
#' @family summary functions
#' @export
#'
#' @examples
#' summ(lifeexp)
#'
#' summ(lifeexp, .by = region)
#'
#' tabstat(lifeexp, .by = region)
#'
#' # Compare frequency and analytic weights
#' survey <- tibble::tibble(income = c(10, 20, 40), w = c(3, 1, 1))
#' summ(survey, income, .wt = w, .stat = c("n", "mean", "sd", "p50"))
#'
#' summ(survey, income, .wt = w, .wt_type = "analytic", .stat = c("n", "sd"))
#'
#' lifeexp |>
#'   summ(
#'     dplyr::where(is.numeric),
#'     .by = region,
#'     .stat = c("n", "mean", "sd", "p50")
#'   )
#'
#' # Exclude rows with missing group keys
#' summ(lifeexp, .by = region, .missing = FALSE)
#'
#' # Summarise existing and computed columns together
#' summ(lifeexp, lexp, gnppc_thousands = gnppc / 1000, .by = region)
#'
#' tabstat(lifeexp, lexp, gnppc_thousands = gnppc / 1000)
#'
#' # Separate numeric and calendar summaries
#' mixed <- tibble::tibble(x = c(1, 3), day = as.Date("2024-01-01") + 0:1)
#' summ(mixed, .type = "list")
#'
#' # Combine numeric and calendar summaries in one tibble
#' summ(mixed, .type = "tibble")
#'
#' # Preserve a variable name when starting from a vector
#' scores <- c(4, 6, NA, 8)
#' tibble::tibble(score = scores) |> summ(.name = TRUE)
summ <- function(
  .data,
  ...,
  .by = NULL,
  .keep_all = FALSE,
  .detail = FALSE,
  .stat = character(0),
  .missing = TRUE,
  .name = FALSE,
  .type = c("list", "table", "tibble"),
  .duration_format = c("long", "compact"),
  .sort = TRUE,
  .drop_empty = FALSE,
  .wt = NULL,
  .wt_type = c("frequency", "analytic")
) {
  local_wrapper_error_call()
  check_data_frame_or_vector(.data)
  # Validate controls before data-dependent branching.
  summ_check_flags(list(
    .keep_all = .keep_all,
    .detail = .detail,
    .missing = .missing,
    .name = .name,
    .sort = .sort,
    .drop_empty = .drop_empty
  ))
  summ_stat_names(.stat)
  .type <- rlang::arg_match(.type)
  .duration_format <- rlang::arg_match(.duration_format)
  .wt_type <- rlang::arg_match(.wt_type)

  input_expr <- substitute(.data)
  template <- .data
  .data <- aggregation_working_data(
    .data,
    override_groups = !rlang::quo_is_null(rlang::enquo(.by))
  )
  # Normalize vectors before grouping and selection.
  if (!is.data.frame(.data)) {
    var_name <- summ_vector_name(input_expr)
    .data <- tibble::as_tibble_col(.data, column_name = var_name)
    template <- if (.type == "table") as.data.frame(.data) else .data
  }

  # Identify group variables
  by <- rlang::enquo(.by)
  group_vars <- extract_group_var(
    if (rlang::quo_is_null(by)) .data else dplyr::ungroup(.data),
    by
  )
  .data <- dplyr::ungroup(.data)
  input_names <- names(.data)

  # Weights are evaluated on every row, so a weight vector matches the input.
  weighted <- weights_prepare(.data, rlang::enquo(.wt))
  .data <- weights_drop_column(
    weighted$data,
    weighted$column,
    !missing(...),
    group_vars
  )
  weights <- weighted$weights

  # Missing-key filtering does not change how measured missing values are handled.
  if (!.missing && length(group_vars) > 0) {
    complete <- !Reduce(
      `|`,
      lapply(.data[group_vars], is.na),
      logical(nrow(.data))
    )
    .data <- dplyr::dplyr_row_slice(.data, which(complete))
    if (!is.null(weights)) {
      weights <- weights[complete]
    }
  }

  # Prepare data
  .data_summ <- remove_group_vars(
    .data,
    ...,
    group_vars = group_vars
  )

  if (any(vapply(.data_summ, function(x) !is.null(dim(x)), logical(1)))) {
    cli::cli_abort(
      "Matrix/data-frame columns are not supported; use atomic or list columns."
    )
  }

  # Classify selected vectors once, preserving original missingness methods.
  metadata <- summ_check_metadata(
    summ_metadata(.data_summ, .keep_all),
    .keep_all
  )
  .data <- summ_keep_measured(.data, .data_summ[names(metadata)], group_vars)

  renamed <- summ_rename_reserved_groups(.data, group_vars, input_names, .stat)
  .data <- renamed$data
  group_vars <- renamed$group_vars
  measured_count <- ncol(.data) - length(group_vars)
  # Keep observed counts internally when filtering a selected-statistic result.
  working_stats <- if (.drop_empty && length(.stat)) {
    unique(c(.stat, "n"))
  } else {
    .stat
  }
  out <- summ_list(
    .data,
    group_vars,
    .detail,
    working_stats,
    if (.type == "tibble") "table" else .type,
    weights = weights,
    weight_type = .wt_type,
    metadata = metadata
  )
  measured_names <- setdiff(names(.data), group_vars)
  finalize <- function(data) {
    summ_finalize(data, group_vars, measured_names, .stat, .drop_empty, .sort)
  }
  out <- if (is.data.frame(out)) finalize(out) else lapply(out, finalize)

  # A single measured variable can omit its otherwise redundant name column.
  if (!.name && is.data.frame(out) && "name" %in% names(out)) {
    if (measured_count == 1L) {
      out <- dplyr::select(out, -"name")
    }
  }

  table_restore(out, template, if (.type == "tibble") "tibble" else "auto")
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
  .missing = TRUE,
  .name = FALSE,
  .type = c("list", "table", "tibble"),
  .duration_format = c("long", "compact"),
  .sort = TRUE,
  .drop_empty = FALSE,
  .wt = NULL,
  .wt_type = c("frequency", "analytic")
) {
  check_data_frame_or_vector(.data)
  .type <- rlang::arg_match(.type)
  # Detailed output replaces the default mean-only request.
  if (isTRUE(.detail) && missing(.stat)) {
    .stat <- character(0)
  }
  if (!is.data.frame(.data)) {
    var_name <- summ_vector_name(substitute(.data))
    .data <- tibble::as_tibble_col(.data, column_name = var_name)
    if (.type == "table") {
      .data <- as.data.frame(.data)
    }
  }
  return(
    summ(
      .data,
      ...,
      .by = {{ .by }},
      .keep_all = .keep_all,
      .detail = .detail,
      .stat = .stat,
      .missing = .missing,
      .name = .name,
      .type = .type,
      .duration_format = .duration_format,
      .sort = .sort,
      .drop_empty = .drop_empty,
      .wt = {{ .wt }},
      .wt_type = .wt_type
    )
  )
}

# A multiline expression or a magrittr placeholder has no useful name.
summ_vector_name <- function(expr) {
  name <- deparse(expr)
  if (length(name) > 1L || identical(name, ".")) "value" else name
}

# Summary statistic names, and the metadata and pivot columns of summ() output.
# Grouping columns must not share these names.
summ_reserved_names <- c(
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

summ_check_flags <- function(flags, call = rlang::caller_env()) {
  for (argument in names(flags)) {
    check_bool(flags[[argument]], arg = argument, call = call)
  }
}

# Prefix grouping columns that share a reserved name with dots, avoiding the
# input's column names, and tell the user.
summ_rename_reserved_groups <- function(data, group_vars, input_names, stat) {
  reserved <- unique(c(summ_reserved_names, stat))
  for (position in which(group_vars %in% reserved)) {
    old_name <- group_vars[[position]]
    new_name <- paste0(".", old_name)
    while (new_name %in% c(input_names, names(data))) {
      new_name <- paste0(".", new_name)
    }
    names(data)[names(data) == old_name] <- new_name
    group_vars[[position]] <- new_name
    reserved_name_inform(
      old_name,
      new_name,
      "summ()",
      what = "Grouping column"
    )
  }
  list(data = data, group_vars = group_vars)
}

# Drop empty rows when asked, then order rows by group and by the position of
# each variable in the input.
summ_finalize <- function(
  data,
  group_vars,
  measured_names,
  stat,
  drop_empty,
  sort
) {
  if (drop_empty) {
    data <- data[data$n > 0L, , drop = FALSE]
    if (length(stat) && !"n" %in% stat) {
      data$n <- NULL
    }
  }
  if (!sort) {
    return(data)
  }
  # Strip only the marker added for this type; actual leading stars remain.
  prefix_length <- ifelse(
    !is_summable_chr(data$type),
    3L,
    ifelse(
      data$type %in% c("fct", "ord"),
      2L,
      ifelse(grepl("lbl$", data$type), 1L, 0L)
    )
  )
  variable_positions <- match(
    substring(data$name, prefix_length + 1L),
    measured_names
  )
  dplyr::arrange(data, !!!rlang::syms(group_vars), !!variable_positions)
}
