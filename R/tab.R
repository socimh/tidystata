#' Frequency tables and cross-tabulations
#'
#' @description
#' Create Stata-style frequency tables using joint counts, separate one-way
#' tables, or pairwise cross-tabulations:
#'
#' * `tab()`: Count combinations of selected variables in one long-format
#'   table with frequencies and percentages.
#' * `fre()`: Count the same combinations as `tab()`, adding totals and
#'   displaying value labels.
#' * `tab1()`: Tabulate each variable separately, returning a one-way
#'   frequency table for each variable.
#' * `fre1()`: Tabulate each variable separately as in `tab1()`, adding totals
#'   and displaying value labels.
#' * `tab2()`: Cross-tabulate every pair of selected variables, returning
#'   wide contingency tables with categories in rows and columns.
#' * `fre2()`: Cross-tabulate every pair as in `tab2()`, adding marginal totals
#'   and displaying row-category labels. Column headers retain category codes.
#'
#' @param .data An in-memory data frame, tibble, or data.table. `tab()`,
#'   `tab1()`, `fre()`, and `fre1()` also accept an atomic vector (without
#'   selectors or `.by`). Collect lazy tables first. Spatial geometry columns
#'   are excluded.
#' @param ... <[`tidy-select`][dplyr_tidy_select]> or
#'   <[`data-masking`][args_data_masking]> Variables to tabulate, or named
#'   expressions such as `high = score >= 70`. Defaults to all columns except
#'   active grouping keys. Without explicit `.by`, `tab2()` and `fre2()` treat
#'   inherited grouping columns as ordinary variables. Select at least two
#'   variables for cross-tabulation.
#' @param .by <[`tidy-select`][dplyr_tidy_select]> Optional grouping columns.
#'   For one-way and joint tables, existing [dplyr::group_by()] groups are
#'   inherited unless `.by` is supplied. `tab2()` and `fre2()` require
#'   explicit `.by` to create separate cross-tables for each group. Grouping
#'   keys are not tabulated.
#' @param .desc If `TRUE`, sort categories by decreasing frequency within each
#'   group; missing categories remain last. Defaults to `FALSE`.
#' @param .group_order Order group blocks by `"keys"` (default) or decreasing
#'   `"frequency"` (weighted totals when weights are supplied). Groups with
#'   any missing key follow complete-key groups; within each set, frequency
#'   ties follow key order. Does not change category order within groups.
#' @param .total If `TRUE`, add totals, as in the corresponding `fre()` family
#'   function. Defaults to `FALSE` for `tab()`, `tab1()`, and `tab2()`; the
#'   `fre()` family always includes totals.
#' @param .wt Optional numeric weights, given as a column or one value per
#'   row. Missing weights exclude rows; negative weights are invalid.
#' @param .wt_type `"frequency"` (default) or `"analytic"`. Frequency weights
#'   are summed as counts; analytic weights are normalized within groups.
#'   See Details for the formulas.
#' @param .type Output form, where supported. `tab()` has no `.type` argument.
#'
#'   * `"list"` is the default for `tab1()` and `fre1()`: one table per selected
#'     variable, retaining the input's table class where supported.
#'   * `"auto"` is the default for `fre()`, `tab2()`, and `fre2()`: retain the
#'     input's table class where supported.
#'   * `"tibble"` returns tibbles regardless of the input's table class. For
#'     `tab1()` and `fre1()`, it also combines the variable tables into one.
#'   * `"flextable"` returns formatted tables and requires the optional
#'     flextable package. It is available for `fre()`, `fre1()`, `tab2()`, and
#'     `fre2()`; `tab2()` also requires `.total = TRUE`.
#'
#'   For `tab2()` and `fre2()`, multiple pairs or explicit `.by` groups still
#'   produce lists; `.type` controls each table inside the list.
#' @param .flip If `TRUE`, exchange the row and column variables in a
#'   cross-tabulation. Defaults to `FALSE`.
#' @param .chi2 If `TRUE`, report Pearson's chi-square test and Cramer's V for
#'   cross-tabulations. Analytic weights are not supported for this test.
#'
#' @returns A table or list of tables, depending on the function:
#'
#' * `tab()` and `fre()` return one row per observed combination of selected
#'   categories and grouping keys, followed by `n`, `percent`, `cum`, `valid`,
#'   and `valid_cum`. The `fre()` variant adds total rows.
#' * `tab1()` and `fre1()` return named lists of one-variable frequency tables.
#'   Each contains a `value` column and the same five statistics. Use
#'   `.type = "tibble"` to combine them, adding a `variable` column.
#' * `tab2()` and `fre2()` return wide cross-tabulations: rows represent
#'   categories of one variable, columns represent categories of the other,
#'   and cells contain counts. `fre2()` adds marginal totals. Multiple pairs
#'   or explicit `.by` groups produce lists of tables.
#'
#' For two selected variables, `tab()` and `tab2()` represent the same joint
#' frequencies in different layouts: `tab()` provides a long table with
#' percentages, whereas `tab2()` shows cell counts in a two-way table. With
#' three or more variables, `tab()` counts their joint combinations, while
#' `tab2()` produces a separate table for each variable pair.
#'
#' Results are ungrouped and retain the input table class where supported.
#' For non-flextable output, chi-square results are stored in the `"chi2"`
#' attribute, with `statistic`, `df`, `p_value`, `cramers_v`, and `n`.
#' Flextables display these results in a footer instead.
#'
#' @details
#' **Counts and percentages**
#'
#' The following five columns are produced by `tab()`, `tab1()`, `fre()`, and
#' `fre1()`. For each group, let `n_i` be the count for category (or category
#' combination) `i`, `N` the count across all categories, and `N_valid` the
#' count excluding observations missing any measured variable. All percentages
#' are on a **0–100 scale**.
#'
#' * `n`: Number of observations in the category, or sum of weights if weighted.
#' * `percent`: Percentage of all observations, `100 * n_i / N`, **including**
#'   missing measured values in the denominator.
#' * `cum`: Cumulative `percent`, summed in the displayed category order.
#' * `valid`: Percentage of complete observations, `100 * n_i / N_valid`.
#'   This is `NA` for categories with missing measured values.
#' * `valid_cum`: Cumulative `valid`, in displayed order, omitting missing
#'   measured categories.
#'
#' Thus `percent` corresponds to Stata's `tabulate, missing`, while `valid`
#' uses the denominator from `tabulate` without `missing`. A missing grouping
#' key does not by itself make a measured value invalid.
#'
#' **Missing values and category order**
#'
#' Missing measured values are kept as categories and shown last. Missingness
#' includes `NA`, `NaN`, tagged missing values, and SPSS user-missing codes or
#' ranges; empty strings are observed values. Factors follow their level order;
#' other categories are sorted by value unless `.desc` requests frequency
#' order. List-column elements are counted as complete values, not flattened.
#'
#' **Weighted counts and percentages**
#'
#' Let `w_j` be the weight for observation `j` in a group.
#'
#' * **Frequency weights** (`.wt_type = "frequency"`): Category counts are
#'   `n_i = sum(w_j)` over observations in that category. Weights need not be
#'   integers.
#' * **Analytic weights** (`.wt_type = "analytic"`): Weights are rescaled
#'   within each group to sum to its number of rows. Category counts sum the
#'   rescaled weights, so the overall count stays on the sample-size scale.
#' * **Percentages:** Both weight types give the same percentages because the
#'   normalization factor cancels in each group. Cumulative and valid
#'   percentages use the corresponding weighted counts and denominators.
#'
#' Rows with missing weights are excluded; negative weights are not allowed.
#' If `...` is omitted, the weight column is not itself tabulated.
#'
#' **Totals and value labels**
#'
#' `fre()` and `fre1()` append a `"Total"` row within each group and may add
#' `"Valid Total"` and `"Missing Total"` subtotals. `fre2()` adds a marginal
#' total row and column. `fre()` and `fre1()` display value labels; `fre2()`
#' displays row-category labels but keeps column headers based on category
#' codes. `tab()` and `tab1()` retain underlying category codes and types. Totals
#' may convert a category column to character or introduce a `total` label column.
#' Distinct category codes remain separate even if their labels coincide.
#'
#' **Cross-tabulations and association tests**
#'
#' `tab2()` and `fre2()` report cell counts rather than the five percentages
#' listed above. With `.chi2 = TRUE`, Pearson's chi-square test uses the
#' displayed categories, including missing ones. Filter missing categories
#' beforehand if they should not contribute to the test. Empty rows and
#' columns are excluded from the calculation.
#'
#' Let `O_ij` be an observed cell count, `E_ij` its expected count under
#' independence, `r` the number of nonempty rows, `c` the number of nonempty
#' columns, and `N` the total count:
#'
#' * **Expected counts:** `E_ij = row_total_i * column_total_j / N`.
#' * **Pearson's chi-square:** `X^2 = sum((O_ij - E_ij)^2 / E_ij)`.
#' * **Degrees of freedom:** `df = (r - 1) * (c - 1)`.
#' * **p-value:** Upper-tail probability of a chi-square distribution with
#'   `df` degrees of freedom.
#' * **Cramer's V:** `sqrt(X^2 / (N * min(r - 1, c - 1)))`. For 2-by-2 tables,
#'   it is the signed phi coefficient, as in Stata, with the sign of
#'   `O_11 * O_22 - O_12 * O_21`.
#'
#' Frequency weights act as cell counts for the test. Analytic weights are
#' not supported; for complex survey designs, use `survey::svychisq()`.
#' Cross-tabulation category values become column names, so conflicts with
#' reserved names such as `"total"` may require recoding.
#'
#' **Computed variables and groups**
#'
#' Named expressions in `...` are evaluated on ungrouped data, before counts
#' are calculated within groups. Use grouped [dplyr::mutate()] first for
#' group-specific computations. Input column names that conflict with output
#' columns are renamed in the result; the input data are unchanged.
#'
#' @name tab
#' @family tabulation functions
#'
#' @examples
#' # Compare the three approaches using the same variables
#' # Joint frequencies: one long table
#' tab(lifeexp, region, high = lexp >= 70)
#'
#' # Separate one-way tables: one for region and one for high
#' tab1(lifeexp, region, high = lexp >= 70)
#'
#' # Two-way cross-tabulation: region by high
#' tab2(lifeexp, region, high = lexp >= 70)
#'
#' # Add totals and display value labels
#' fre(lifeexp, region)
#'
#' fre2(lifeexp, region, high = lexp >= 70)
#'
#' # Frequencies within groups
#' tab(lifeexp, high = lexp >= 70, .by = region)
#'
#' # Many distinct values of a continuous variable: preview the table compactly
#' tab(lifeexp, lexp) |> print_headtail(n = 6)
#'
#' tab(lifeexp, lexp) |> print_interval(n = 6)
#'
#' # Pearson's chi-square and Cramer's V
#' result <- tab2(lifeexp, region, high = lexp >= 70, .chi2 = TRUE)
#' attr(result, "chi2")
#'
#' # Frequency weights
#' survey <- tibble::tibble(response = c("yes", "no", "yes"), w = c(2, 1, 3))
#' tab(survey, response, .wt = w)
NULL

#' @export
#' @rdname tab
tab <- function(
  .data,
  ...,
  .by = NULL,
  .desc = FALSE,
  .group_order = c("keys", "frequency"),
  .total = FALSE,
  .wt = NULL,
  .wt_type = c("frequency", "analytic")
) {
  check_bool(.desc)
  check_bool(.total)
  if (.total) {
    return(fre(
      .data,
      ...,
      .by = {{ .by }},
      .desc = .desc,
      .group_order = .group_order,
      .wt = {{ .wt }},
      .wt_type = .wt_type
    ))
  }
  .group_order <- rlang::arg_match(.group_order)
  if (!is.data.frame(.data)) {
    .data <- tab_vector_data(.data, ..., .by = {{ .by }})
  }
  template <- .data
  .data <- aggregation_working_data(
    .data,
    override_groups = !rlang::quo_is_null(rlang::enquo(.by))
  )
  # Identify group variables
  by <- rlang::enquo(.by)
  group_vars <- extract_group_var(
    if (rlang::quo_is_null(by)) .data else dplyr::ungroup(.data),
    by
  )
  .data <- dplyr::ungroup(.data)
  .wt_type <- rlang::arg_match(.wt_type)
  weighted <- weights_prepare(.data, rlang::enquo(.wt))
  .data <- weights_drop_column(
    weighted$data,
    weighted$column,
    !missing(...),
    group_vars
  )
  groups <- if (.group_order == "frequency" || .wt_type == "analytic") {
    aggregation_groups(.data, group_vars)
  } else {
    NULL
  }
  weights <- weights_scale(
    weighted$weights,
    .data,
    group_vars,
    .wt_type,
    groups
  )

  # Prepare data
  .data_nogroup <- tab_prepare_data(.data, ..., group_vars = group_vars)
  .data <- .data |>
    dplyr::select(dplyr::any_of(group_vars)) |>
    dplyr::bind_cols(.data_nogroup)

  # Confirm names
  old_names <- names(.data)
  .data <- tab_rename_reserved(.data, "tab()")
  group_vars <- names(.data)[match(group_vars, old_names)]
  if (length(group_vars) && !is.null(groups)) {
    names(groups$key) <- group_vars
  }

  # Tabulate
  out <- tab_data(
    .data,
    group_vars,
    .desc,
    weights = weights,
    group_order = .group_order,
    input_groups = groups
  ) |>
    dplyr::select(-"...any_miss")

  # Output
  table_restore(out, template)
}

#' @export
#' @rdname tab
tab1 <- function(
  .data,
  ...,
  .by = NULL,
  .desc = FALSE,
  .type = c("list", "tibble"),
  .group_order = c("keys", "frequency"),
  .total = FALSE,
  .wt = NULL,
  .wt_type = c("frequency", "analytic")
) {
  check_bool(.desc)
  check_bool(.total)
  if (.total) {
    return(fre1(
      .data,
      ...,
      .by = {{ .by }},
      .desc = .desc,
      .type = rlang::arg_match(.type),
      .group_order = .group_order,
      .wt = {{ .wt }},
      .wt_type = .wt_type
    ))
  }
  .group_order <- rlang::arg_match(.group_order)
  if (!is.data.frame(.data)) {
    .data <- tab_vector_data(.data, ..., .by = {{ .by }})
  }
  template <- .data
  .data <- aggregation_working_data(
    .data,
    override_groups = !rlang::quo_is_null(rlang::enquo(.by))
  )
  # Identify group variables
  by <- rlang::enquo(.by)
  group_vars <- extract_group_var(
    if (rlang::quo_is_null(by)) .data else dplyr::ungroup(.data),
    by
  )
  .data <- dplyr::ungroup(.data)
  .wt_type <- rlang::arg_match(.wt_type)
  weighted <- weights_prepare(.data, rlang::enquo(.wt))
  .data <- weights_drop_column(
    weighted$data,
    weighted$column,
    !missing(...),
    group_vars
  )
  groups <- if (.group_order == "frequency" || .wt_type == "analytic") {
    aggregation_groups(.data, group_vars)
  } else {
    NULL
  }
  weights <- weights_scale(
    weighted$weights,
    .data,
    group_vars,
    .wt_type,
    groups
  )

  .type <- rlang::arg_match(.type)
  keys <- dplyr::select(dplyr::ungroup(.data), tidyselect::all_of(group_vars))
  values <- tab_prepare_data(.data, ..., group_vars = group_vars)
  .data <- dplyr::bind_cols(keys, values)
  old_names <- names(.data)
  # Measured names become list names or `variable` values, never columns.
  .data <- tab_rename_reserved(.data, "tab1()", group_vars)
  group_vars <- names(.data)[match(group_vars, old_names)]
  if (length(group_vars) && !is.null(groups)) {
    names(groups$key) <- group_vars
  }

  error_call <- rlang::current_env()
  out <- lapply(.data[setdiff(names(.data), group_vars)], function(value) {
    dplyr::bind_cols(.data[group_vars], tibble::tibble(value = value)) |>
      tab_data(
        group_vars,
        .desc,
        weights = weights,
        group_order = .group_order,
        input_groups = groups,
        call = error_call
      ) |>
      dplyr::select(-"...any_miss")
  })

  if (length(out) == 0L && .type[1] == "tibble") {
    return(table_restore(
      dplyr::bind_cols(
        .data[0L, group_vars, drop = FALSE],
        append_tab_list(out)
      ),
      template,
      "tibble"
    ))
  }

  # Bind rows if the type is a tibble
  if (.type[1] == "tibble") {
    out <- append_tab_list(out)
  }

  # Output
  table_restore(out, template, if (.type == "list") "auto" else .type)
}

#' @export
#' @rdname tab
tab2 <- function(
  .data,
  ...,
  .by = NULL,
  .flip = FALSE,
  .total = FALSE,
  .type = c("auto", "tibble", "flextable"),
  .wt = NULL,
  .wt_type = c("frequency", "analytic"),
  .chi2 = FALSE
) {
  local_wrapper_error_call()
  reject_cross_controls(..., function_name = "tab2()")
  check_bool(.flip)
  check_bool(.total)
  check_bool(.chi2)
  .type <- rlang::arg_match(.type)
  if (.type == "flextable" && !.total) {
    cli::cli_abort(
      "Flextable cross-tabulation requires {.code .total = TRUE}."
    )
  }
  template <- .data
  by <- rlang::enquo(.by)
  grouped <- !rlang::quo_is_null(by)
  .data <- aggregation_working_data(.data, override_groups = grouped)
  group_vars <- if (grouped) {
    extract_group_var(dplyr::ungroup(.data), by)
  } else {
    character()
  }
  .wt_type <- rlang::arg_match(.wt_type)
  weighted <- weights_prepare(.data, rlang::enquo(.wt))
  .data <- weights_drop_column(
    weighted$data,
    weighted$column,
    !missing(...),
    group_vars
  )
  if (.chi2 && !is.null(weighted$weights) && .wt_type == "analytic") {
    cli::cli_abort(c(
      "{.arg .chi2} is not available with analytic weights, whose counts are not observation counts.",
      i = "For sampling weights, use {.fn survey::svychisq}."
    ))
  }
  # Prepare data
  keys <- dplyr::ungroup(.data)[group_vars]
  .data <- if (grouped) {
    remove_group_vars(.data, ..., group_vars = group_vars)
  } else {
    select_or_transmute(tab_ungroup(.data), ...)
  }
  if (ncol(.data) == 0L) {
    if (.type == "flextable") {
      cli::cli_abort(
        "Flextable cross-tabulation requires two selected variables."
      )
    }
    return(table_restore(tibble::tibble(), template, .type))
  }

  # Confirm names
  tab2_check_vars(.data)
  .data <- tab_rename_reserved(.data, "tab2()")
  if (!grouped) {
    weights <- weights_scale(weighted$weights, .data, character(), .wt_type)
    return(tab2_tables(.data, weights, template, .flip, .total, .type, .chi2))
  }
  # Like Stata's `by g: tab x y`, one result per group, named "g = value".
  groups <- group_locations(keys, group_vars)
  labels <- tab2_group_labels(groups$keys)
  out <- lapply(seq_along(groups$locs), function(i) {
    loc <- groups$locs[[i]]
    if (.chi2) {
      cli::cli_inform("-> {labels[[i]]}")
    }
    rows <- vctrs::vec_slice(.data, loc)
    weights <- if (is.null(weighted$weights)) {
      NULL
    } else {
      weights_scale(weighted$weights[loc], rows, character(), .wt_type)
    }
    tab2_tables(rows, weights, template, .flip, .total, .type, .chi2)
  })
  rlang::set_names(out, labels)
}

# Three or more variables: every pairwise table, like Stata's tab2.
tab2_tables <- function(.data, weights, template, .flip, .total, .type, .chi2) {
  rlang::local_error_call(rlang::caller_env())
  if (ncol(.data) <= 2L) {
    return(tab2_pair(.data, weights, template, .flip, .total, .type, .chi2))
  }
  pairs <- utils::combn(names(.data), 2L, simplify = FALSE)
  out <- lapply(pairs, function(pair) {
    if (.chi2) {
      cli::cli_inform("-> tabulation of {pair[[1L]]} by {pair[[2L]]}")
    }
    pair_data <- dplyr::select(.data, dplyr::all_of(pair))
    tab2_pair(pair_data, weights, template, .flip, .total, .type, .chi2)
  })
  names(out) <- vapply(pairs, paste, character(1), collapse = " x ")
  out
}

# "g = a" for one key, "g = a, h = b" for several; missing keys print as NA.
tab2_group_labels <- function(keys) {
  parts <- lapply(names(keys), function(name) {
    paste(name, "=", tostring(as_character(keys[[name]])))
  })
  do.call(paste, c(parts, sep = ", "))
}

#' @export
#' @rdname tab
fre2 <- function(
  .data,
  ...,
  .by = NULL,
  .flip = FALSE,
  .type = c("auto", "tibble", "flextable"),
  .wt = NULL,
  .wt_type = c("frequency", "analytic"),
  .chi2 = FALSE
) {
  tab2(
    .data,
    ...,
    .by = {{ .by }},
    .flip = .flip,
    .total = TRUE,
    .type = rlang::arg_match(.type),
    .wt = {{ .wt }},
    .wt_type = rlang::arg_match(.wt_type),
    .chi2 = .chi2
  )
}

# One two-way table from exactly two selected columns.
tab2_pair <- function(.data, weights, template, .flip, .total, .type, .chi2) {
  rlang::local_error_call(rlang::caller_env())
  # Flip variables
  if (.flip) {
    .data <- .data |>
      dplyr::relocate(2, 1)
  }

  # Cross-tabulate
  out <- tab2_data(.data, weights)
  test <- if (.chi2) xtab_chi2(out) else NULL
  if (.total) {
    out <- tab2_add_total(out, .data)
    if (.type == "flextable") {
      out <- result_to_flextable(out, character(0), fre2 = TRUE)
      if (!is.null(test)) {
        out <- flextable::add_footer_lines(out, attr(test, "text"))
      }
      return(out)
    }
  }

  # Output
  out <- table_restore(out, template, .type)
  if (!is.null(test)) {
    attr(test, "text") <- NULL
    attr(out, "chi2") <- test
  }
  out
}

#' @export
#' @rdname tab
fre <- function(
  .data,
  ...,
  .by = NULL,
  .desc = FALSE,
  .type = c("auto", "tibble", "flextable"),
  .group_order = c("keys", "frequency"),
  .wt = NULL,
  .wt_type = c("frequency", "analytic")
) {
  check_bool(.desc)
  .group_order <- rlang::arg_match(.group_order)
  if (!is.data.frame(.data)) {
    .data <- tab_vector_data(.data, ..., .by = {{ .by }})
  }
  template <- .data
  .data <- aggregation_working_data(
    .data,
    override_groups = !rlang::quo_is_null(rlang::enquo(.by))
  )
  .type <- rlang::arg_match(.type)
  # Identify group variables
  by <- rlang::enquo(.by)
  group_vars <- extract_group_var(
    if (rlang::quo_is_null(by)) .data else dplyr::ungroup(.data),
    by
  )
  .data <- dplyr::ungroup(.data)
  .wt_type <- rlang::arg_match(.wt_type)
  weighted <- weights_prepare(.data, rlang::enquo(.wt))
  .data <- weights_drop_column(
    weighted$data,
    weighted$column,
    !missing(...),
    group_vars
  )
  groups <- if (.group_order == "frequency" || .wt_type == "analytic") {
    aggregation_groups(.data, group_vars)
  } else {
    NULL
  }
  weights <- weights_scale(
    weighted$weights,
    .data,
    group_vars,
    .wt_type,
    groups
  )

  # Prepare data
  .data_nogroup <- tab_prepare_data(.data, ..., group_vars = group_vars)
  .data <- .data |>
    dplyr::select(dplyr::any_of(group_vars)) |>
    dplyr::bind_cols(.data_nogroup)

  # Confirm names
  old_names <- names(.data)
  .data <- tab_rename_reserved(.data, "fre()")
  group_vars <- names(.data)[match(group_vars, old_names)]
  if (length(group_vars) && !is.null(groups)) {
    names(groups$key) <- group_vars
  }

  error_call <- rlang::current_env()
  # Tabulate
  out <- .data |>
    tab_data(
      group_vars,
      .desc,
      weights = weights,
      total = TRUE,
      group_order = .group_order,
      input_groups = groups,
      call = error_call
    ) |>
    dplyr::select(-"...any_miss")

  if (.type[1] == "flextable") {
    out <- out |>
      result_to_flextable(group_vars, call = error_call)
  }

  # Output
  if (.type == "flextable") out else table_restore(out, template, .type)
}

#' @export
#' @rdname tab
fre1 <- function(
  .data,
  ...,
  .by = NULL,
  .desc = FALSE,
  .type = c("list", "tibble", "flextable"),
  .group_order = c("keys", "frequency"),
  .wt = NULL,
  .wt_type = c("frequency", "analytic")
) {
  check_bool(.desc)
  .group_order <- rlang::arg_match(.group_order)
  if (!is.data.frame(.data)) {
    .data <- tab_vector_data(.data, ..., .by = {{ .by }})
  }
  template <- .data
  .data <- aggregation_working_data(
    .data,
    override_groups = !rlang::quo_is_null(rlang::enquo(.by))
  )
  # Identify group variables
  by <- rlang::enquo(.by)
  group_vars <- extract_group_var(
    if (rlang::quo_is_null(by)) .data else dplyr::ungroup(.data),
    by
  )
  .data <- dplyr::ungroup(.data)
  .wt_type <- rlang::arg_match(.wt_type)
  weighted <- weights_prepare(.data, rlang::enquo(.wt))
  .data <- weights_drop_column(
    weighted$data,
    weighted$column,
    !missing(...),
    group_vars
  )
  groups <- if (.group_order == "frequency" || .wt_type == "analytic") {
    aggregation_groups(.data, group_vars)
  } else {
    NULL
  }
  weights <- weights_scale(
    weighted$weights,
    .data,
    group_vars,
    .wt_type,
    groups
  )

  .type <- rlang::arg_match(.type)
  keys <- dplyr::select(dplyr::ungroup(.data), tidyselect::all_of(group_vars))
  values <- tab_prepare_data(.data, ..., group_vars = group_vars)
  .data <- dplyr::bind_cols(keys, values)
  old_names <- names(.data)
  .data <- tab_rename_reserved(.data, "fre1()", group_vars)
  group_vars <- names(.data)[match(group_vars, old_names)]
  if (length(group_vars) && !is.null(groups)) {
    names(groups$key) <- group_vars
  }

  error_call <- rlang::current_env()
  out <- lapply(.data[setdiff(names(.data), group_vars)], function(value) {
    dplyr::bind_cols(.data[group_vars], tibble::tibble(value = value)) |>
      tab_data(
        group_vars,
        .desc,
        weights = weights,
        total = TRUE,
        group_order = .group_order,
        input_groups = groups,
        call = error_call
      ) |>
      dplyr::select(-"...any_miss")
  })

  if (length(out) == 0L && .type[1] == "tibble") {
    return(table_restore(
      dplyr::bind_cols(
        .data[0L, group_vars, drop = FALSE],
        append_tab_list(out)
      ),
      template,
      "tibble"
    ))
  }

  if (.type[1] == "flextable") {
    out <- out |>
      append_tab_list(blank_row = TRUE) |>
      dplyr::slice(-dplyr::n()) |>
      result_to_flextable(group_vars, fre1 = TRUE, call = error_call)
  } else if (.type[1] == "tibble") {
    out <- append_tab_list(
      out,
      blank_row = FALSE
    )
  }

  # Output
  if (.type == "flextable") {
    out
  } else {
    table_restore(out, template, if (.type == "list") "auto" else .type)
  }
}


# One-way and grouping controls would otherwise be read as data expressions.
reject_cross_controls <- function(
  ...,
  function_name,
  call = rlang::caller_env()
) {
  supplied <- intersect(c(".desc", ".group_order"), ...names())
  if (length(supplied)) {
    cli::cli_abort(
      c(
        "{.arg {supplied[[1L]]}} is not supported by {.code {function_name}}; cross-tabulations keep categories in value order.",
        i = "Use {.fn tab} or {.fn fre} to order categories by frequency."
      ),
      call = call
    )
  }
}

# Atomic vectors become a one-column tibble named `value`.
tab_vector_data <- function(.data, ..., .by = NULL) {
  # Dots hold user selections, so report errors through the caller's frame.
  rlang::local_error_call(rlang::caller_env())
  if (!is.atomic(.data) || is.null(.data) || !is.null(dim(.data))) {
    stop_input_type(.data, "a data frame or an atomic vector")
  }
  if (!missing(...)) {
    cli::cli_abort("For vector input, omit selectors in {.arg ...}.")
  }
  if (!rlang::quo_is_null(rlang::enquo(.by))) {
    cli::cli_abort("For vector input, omit {.arg .by}.")
  }
  # tibble() reads `.data` as its data pronoun, so bind the vector first.
  value <- .data
  tibble::tibble(value = value)
}
