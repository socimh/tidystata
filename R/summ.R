#' Summarise columns
#'
#' Compute one row of summary statistics per selected variable and group.
#' `tabstat()` uses `.stat = "mean"` by default; with `.detail = TRUE` and no
#' explicit `.stat`, it returns all detail statistics.
#'
#' @param ... <[`tidy-select`][dplyr_tidy_select]> or
#'   <[`data-masking`][args_data_masking]> Columns to select or compute with
#'   [select_or_transmute()]. Existing columns, selection helpers, and named
#'   expressions can be mixed. Omit to summarize all columns except grouping
#'   keys.
#' @param .data A data frame, data frame extension (e.g. a tibble), or a vector.
#'   Matrix and data-frame columns are unsupported; use atomic or list columns.
#'   For `sf` input, summarise attribute data only: all geometry columns are
#'   removed before selection. Geometry columns cannot be selected or grouped.
#' @param .by Optional grouping columns, selected with tidyselect. An explicit
#'   selection overrides existing `group_by()` groups; when omitted, existing
#'   groups are used. Grouping columns are excluded from the measured variables.
#'   Select existing columns only; create new grouping columns with
#'   [dplyr::mutate()] first.
#' @param .keep_all If `FALSE` (default), unsupported nonnumeric columns are
#'   removed with a warning; an error is raised if none of the selected columns
#'   can be summarised. If `TRUE`, character/list columns retain counts and
#'   unique values, with numeric statistics set to `NA`. Numeric-looking
#'   character values are not parsed.
#' @param .detail If `TRUE`, return all statistics available for each variable
#'   type unless `.stat` selects a subset. Defaults to `FALSE`.
#' @param .stat A character vector. If nonempty, return only the listed
#'   statistics, plus variable names, types and any grouping columns. Supported
#'   names are `type`, `n`, `unique`, `miss_n`, `valid_pct`, `min`, `q1`,
#'   `median`, `mean`, `mad`, `sd`, `q3`, `max`, `iqr`, `skew`, `kurtosis`,
#'   `se`, and `sum`. Aliases `missing`, `p25`, `p50`, and `p75` select
#'   `miss_n`, `q1`, `median`, and `q3`; requested names and order are retained.
#'   Identical requested names are deduplicated; aliases and canonical names may
#'   coexist. `sum` applies to numeric summaries, not calendar dates or
#'   datetimes. Calendar summaries do not support `skew` or `kurtosis` either;
#'   when such a statistic is requested alongside numeric variables, calendar
#'   variables are skipped with a warning. Percentiles `p0` through `p100`,
#'   including decimals such as `p2.5`, follow Stata's rule (see Details).
#' @param .missing If `TRUE` (default), rows with a missing grouping key form
#'   their own group, like Stata's `tabstat, by() missing`. If `FALSE`, drop
#'   them before summarising. Missing measured values are always omitted from
#'   numeric statistics, regardless of this flag.
#' @param .name If `FALSE` (default), drop the `name` column when exactly one
#'   measured variable is summarised, including zero-row grouped output; with
#'   several variables it is always kept. If `TRUE`, always retain it.
#' @param .type `"list"` (default) separates variable-type families when needed;
#'   `"table"` combines them in one table. See Value for the return structure
#'   and Details for calendar conversions.
#' @param .duration_format Retained for compatibility and no longer affects the
#'   output: calendar spreads are always `difftime` columns (see Details).
#' @param .sort If `TRUE` (default), sort grouping keys ascending like [tab()]
#'   (factor levels in their defined order, character keys in C-locale order),
#'   with ordinary missing keys last. SPSS user-missing codes retain their
#'   stored-value ordering. Within each group, preserve the selected variable
#'   order. If `FALSE`, groups follow first appearance.
#' @param .drop_empty If `TRUE`, remove individual summary rows with no observed
#'   measured values (`n == 0`), even when `n` is not requested. This is
#'   independent of `.missing`. Default is `FALSE`.
#' @param .wt Optional weights: a numeric column of `.data` (or a vector with
#'   one value per row), like Stata's `summarize [fweight/aweight]`. Rows with a
#'   missing weight are excluded with a message; negative weights are an error.
#'   When `...` is omitted, the weight column is not summarised itself.
#' @param .wt_type `"frequency"` (default) or `"analytic"`. With frequency
#'   weights, `n` is the sum of the weights (non-integer weights are allowed).
#'   Analytic weights (Stata's `[aweight]`) are rescaled within each group and
#'   variable to sum to the number of observed values, so `n` is the number of
#'   observations. Means, percentiles and `sum` are the same under both types;
#'   `sd` and `se` differ.
#' @details
#' Computed columns are evaluated on ungrouped working data before statistics
#' are calculated within groups. Create columns with grouped [dplyr::mutate()]
#' first when a calculation needs to run separately within each group.
#'
#' **Counts and missing values**
#'
#' `n` counts observed values and `unique` counts distinct observed values.
#' `miss_n` counts missing values; `valid_pct` is the fraction observed, from
#' zero to one, and is `NA` for zero-row inputs. Missingness follows the
#' original vector's `is.na()` method, including SPSS user-missing
#' values/ranges. Retained list columns count complete element identities
#' without flattening. Columns with no observed values remain in the result: `n`
#' and `unique` are zero and location/spread statistics, including `sum`, are
#' `NA`. Zero-row grouped inputs do not create artificial groups.
#'
#' **Numeric statistics**
#'
#' Numeric calculations use double precision. Large `integer64` values may lose
#' precision during conversion, with a warning.
#'
#' Logical values are treated as zero/one. Factors and ordered factors use their
#' underlying level codes with a warning. Numeric labelled vectors use
#' underlying values, excluding user-missing codes; label metadata is flagged
#' with a warning. Measured vectors and `difftime` use their original units. In
#' variable names, `*` marks labelled vectors, `**` marks factors and `***`
#' marks retained nonnumeric columns.
#'
#' Statistics follow Stata's `summarize, detail`:
#'
#' * SD uses the sample denominator (`n - 1`); `se` is SD divided by `sqrt(n)`.
#' * Percentiles use Stata's rule, not R's default [stats::quantile()] type 7:
#'   with `n` sorted values, the `p`th percentile is the value at position
#'   `floor(n * p) + 1`, or the mean of the values at positions `n * p` and `n *
#'   p + 1` when `n * p` is whole. So `q1` of `1:4` is 1.5 (type 7 gives 1.75).
#'   `median`, `q1`, `q3` and `iqr` (`q3 - q1`) use the same rule.
#' * `skew` and `kurtosis` use population moments, `m3 / m2^1.5` and `m4 /
#'   m2^2`, so `kurtosis` is 3 for a normal distribution (not excess kurtosis).
#'   They are `NA` when the values are constant or fewer than two.
#' * `mad` has no Stata counterpart; it uses [stats::mad()] with its default
#'   scaling.
#'
#' For singleton or constant inputs, undefined spread statistics are `NA`.
#'
#' **Weighted statistics**
#'
#' With `.wt`, the mean is `sum(w * x) / W` and the variance is `sum(w * (x -
#' mean)^2) / (W - 1)`, where `W` is the summed weight (after rescaling for
#' analytic weights); `se` is `sd / sqrt(W)`, and `sum` is `sum(w * x)` with the
#' weights as given, as Stata's `r(sum)`, even for analytic weights.
#' Percentiles, `median`, `q1`, `q3`, `iqr` and `mad` use Stata's weighted
#' percentile rule, the unweighted rule with cumulative weights in place of
#' positions, so weights of 1 give the unweighted values. `min` and `max` ignore
#' rows with zero weight. `unique`, `miss_n` and `valid_pct` remain unweighted
#' row counts. These standard errors do not account for a survey design. Use
#' `survey::svymean()` for inference with sampling weights, clusters or strata.
#'
#' **Calendar output and grouping names**
#'
#' Date locations are displayed as `YYYY-MM-DD`; fractional days are not shown.
#' Infinite Date locations are displayed as `-Inf` or `Inf`; missing locations
#' remain `NA`. Datetime locations are displayed as `YYYY-MM-DD HH:MM`, without
#' seconds, in the variable's own time zone (the session time zone when none is
#' set). `hms` time-of-day locations are displayed as `hh:mm:ss`.
#'
#' Calendar spread statistics (`sd`, `se`, `mad`, `iqr`) are `difftime` columns,
#' so they can be compared across rows and used in arithmetic. Each column has
#' one unit: days for Dates; for datetimes and times, the unit (seconds,
#' minutes, hours or days) that fits the column's median nonzero spread. Convert
#' with, for example, `as.numeric(out$sd, units = "hours")`.
#'
#' With `.type = "table"`, calendar locations are text. A shared location column
#' such as `mean` becomes character, with numeric values rounded to seven
#' significant digits; counts remain numeric. Calendar spreads become numbers in
#' days (Dates) or seconds (datetimes and times), with the unit appended to
#' `type`, for example `"date [days]"`.
#'
#' Grouping keys that collide with summary metadata or internal pivot names are
#' renamed by prepending dots until unique among the input names, with a
#' message. The input data are not modified.
#' @name summ
#'
#' @returns An ungrouped table with one row per measured variable and group, or
#'   a list of such tables:
#' * With `.type = "list"`, one table for a single variable-type family;
#'   otherwise, a list named `numeric`, `date`, `datetime`, and/or `time`
#'   (`hms`). The numeric family includes columns retained by `.keep_all`.
#' * With `.type = "table"`, one combined table.
#'
#' Tables include grouping keys, `name` (subject to `.name`), `type`, and
#' statistics. By default, `summ()` includes `n`, `unique`, `min`, `mean`, `sd`,
#' and `max`; `tabstat()` includes `mean`. `.detail` adds the available
#' statistics listed under `.stat`, which can instead choose a subset and its
#' column names/order. Calendar location columns are character; spreads are
#' `difftime` in list mode and numeric in table mode. Entirely missing columns
#' have zero observed/distinct counts and `NA` location/spread statistics,
#' including `sum`; zero-row grouped inputs have no result rows.
#'
#' Tables preserve the input's data.frame, tibble, or data.table container and
#' supported preview settings; other subclasses are not reconstructed. Vector
#' input returns a tibble in list mode or a data.frame in table mode. Its
#' expression supplies the variable name, falling back to `value` for multiline
#' expressions or a magrittr pipe (`.`); a named tibble supplies a stable name.
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
#' # Weighted summaries, like Stata's summarize [aweight = w]
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
#' # Remove rows missing a grouping key; measured NAs are always omitted
#' summ(lifeexp, .by = region, .missing = FALSE)
#'
#' # Summarize existing and computed columns together
#' summ(lifeexp, lexp, gnppc_thousands = gnppc / 1000, .by = region)
#'
#' tabstat(lifeexp, lexp, gnppc_thousands = gnppc / 1000)
#'
#' # Keep numeric and calendar summaries in separate tables
#' mixed <- tibble::tibble(x = c(1, 3), day = as.Date("2024-01-01") + 0:1)
#' summ(mixed, .type = "list")
#'
#' # Choose a stable variable name when starting from a vector
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
  .type = c("list", "table"),
  .duration_format = c("long", "compact"),
  .sort = TRUE,
  .drop_empty = FALSE,
  .wt = NULL,
  .wt_type = c("frequency", "analytic")
) {
  local_wrapper_error_call()
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
    .type,
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

  table_restore(out, template)
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
  .type = c("list", "table"),
  .duration_format = c("long", "compact"),
  .sort = TRUE,
  .drop_empty = FALSE,
  .wt = NULL,
  .wt_type = c("frequency", "analytic")
) {
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
