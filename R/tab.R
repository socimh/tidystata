#' Tabulate columns
#'
#' Count joint categories with `tab()`, variables individually with `tab1()`, or
#' every pair of variables with `tab2()`, following Stata's tabulation commands.
#' The `fre()`, `fre1()`, and `fre2()` variants add totals and value labels.
#'
#' @details
#' **Selection and missing values**
#'
#' Computed columns are evaluated on ungrouped working data before counts are
#' calculated within groups. Create columns with grouped [dplyr::mutate()] first
#' when a calculation needs to run separately within each group. Missingness
#' includes `NaN`, tagged missing values, and SPSS user-missing codes and
#' ranges. Empty strings are observed values. List-column values are counted by
#' their complete identities, without flattening.
#'
#' **Counts, percentages, and totals**
#'
#' For `tab()`, `tab1()`, `fre()` and `fre1()`, `n` counts observations.
#' `percent` and `cum` are percentages from zero to 100 using all observations
#' within each group; `cum` follows the displayed category order. `valid` and
#' `valid_cum` use only observations with no missing measured values. Missing
#' group keys are retained and do not make an otherwise observed value invalid.
#' Missing measured categories have `NA` valid percentages and appear last. So
#' `percent` matches the user-written `fre` and `tabulate, missing`, and `valid`
#' matches plain `tabulate`, which leaves missing values out.
#'
#' `fre()` and `fre1()` append a `"Total"` row within each group and may add
#' `"Valid Total"` and `"Missing Total"` subtotals. In tables with up to five
#' measured variables, the final measured column is converted to character to
#' hold these labels; wider tables use a separate `total` label column.
#' Displayed value labels can coincide for distinct underlying values, or with
#' an observed `"Total"` category. Counts remain separate; use `tab()` or
#' `tab1()` when original category values and types are needed.
#'
#' **Cross-tabulation**
#'
#' Cross-tabulation keeps category names unchanged. Categories may match the
#' original variable names. Column categories follow their values: factor levels
#' in order, other types ascending, with missing values last. A category
#' matching the combined row-header name, or literal `"NA"` alongside a missing
#' column category, causes a name collision. With `tab2(.total = TRUE)`, the
#' column category `"total"` is reserved for marginal totals; recode it first or
#' omit the totals. The final row of `tab2(.total = TRUE)` is the marginal
#' total, labelled `"total"`; an observed row category with that label remains a
#' separate row. Blank column categories use `"<empty>"`, with the smallest
#' unused numeric suffix when that header is already taken. Logical
#' cross-tabulation axes follow `FALSE`, `TRUE`, then missing values.
#'
#' With `.chi2 = TRUE`, `tab2()` tests the categories shown in the table,
#' including missing ones (filter them out first to exclude them, as Stata's
#' `tabulate, chi2` does without `missing`), and drops rows or columns with no
#' observations. It prints Pearson's chi-square, its degrees of freedom, the
#' p-value and Cramer's V as a message; flextable output adds them as a footer.
#' As in Stata, V keeps its sign in 2 x 2 tables. Frequency weights are treated
#' as counts; analytic weights are an error, because a design-based test such as
#' `survey::svychisq()` is needed for sampling weights.
#'
#' **Combined output and names**
#'
#' Combined `tab1()` output uses character values when factor types cannot be
#' combined; each variable's category order is retained. List output preserves
#' the original category classes.
#'
#' Input columns that clash with output names are renamed with a leading dot,
#' with a message. If the new name is already taken, rename the input first. The
#' input data are not modified.
#'
#' @param .data An in-memory data frame, tibble, or data.table. Collect lazy
#'   tables before tabulating. `tab()`, `tab1()`, `fre()` and `fre1()` also
#'   accept an atomic vector, tabulated as a tibble column named `value`; omit
#'   selectors and `.by` in this form. `tab2()` needs a data frame. All spatial
#'   `sfc` geometry columns are excluded before attribute tabulation; geometry
#'   columns cannot be selected as measured variables or grouping keys.
#' @param ... <[`tidy-select`][dplyr_tidy_select]> or
#'   <[`data-masking`][args_data_masking]> Columns to select or compute with
#'   [select_or_transmute()]. Existing columns, selection helpers, and named
#'   expressions can be mixed. Omit to tabulate all columns except grouping
#'   keys; cross-tabulations require at least two measured columns.
#' @param .by Optional grouping columns, selected with tidyselect. For `tab()`,
#'   `tab1()`, `fre()` and `fre1()`, `NULL` inherits existing `group_by()`
#'   groups; an explicit selection replaces them. Grouping columns are not
#'   measured variables. For `tab2()` and `fre2()`, `.by` returns a list with
#'   one cross-table per group, named like `"g = a"`, as Stata's `by g: tab x
#'   y`; grouped data are not split without `.by`. `tab2()` does not accept
#'   `.desc` or `.group_order`. Select existing columns only; create new
#'   grouping columns with [dplyr::mutate()] first.
#' @param .desc If `TRUE`, sort categories by descending count within each group
#'   (missing categories stay last). To order the `.by` group blocks by size,
#'   use `.group_order = "frequency"`.
#' @param .type Output type. `tab1()` and `fre1()` default to a list of tables;
#'   `fre()`, `tab2()` and `fre2()` default to `"auto"`, preserving the input
#'   container. Explicit `"tibble"` always returns a plain tibble. Explicit
#'   `"flextable"` output requires the optional flextable package.
#' @param .flip If `TRUE`, swap the rows and columns of the cross-table.
#'   Defaults to `FALSE`.
#' @param .wt Optional weights: a numeric column of `.data` (or a vector with
#'   one value per row), like Stata's `[fweight]`/`[aweight]`. Rows with a
#'   missing weight are excluded with a message; negative weights are an error.
#'   When `...` is omitted, the weight column is not tabulated itself.
#' @param .wt_type `"frequency"` (default) or `"analytic"`. Frequency weights
#'   count each row `w` times, so `n` is the sum of the weights, as in
#'   `dplyr::count(wt =)`; non-integer weights are allowed. Analytic weights
#'   (Stata's `[aweight]`) are rescaled within each `.by` group to sum to the
#'   number of rows, so `n` stays on the sample scale. Percentages are the same
#'   under both types.
#' @param .total If `TRUE`, add "Total" rows: `tab(.total = TRUE)` is `fre()`
#'   and `tab1(.total = TRUE)` is `fre1()`. `tab2(.total = TRUE)` is `fre2()`
#'   and adds a total row and a total column. Defaults to `FALSE` for `tab()`,
#'   `tab1()`, and `tab2()`; the `fre()` family always adds totals. Flextable
#'   output from `tab2()` requires totals.
#' @param .chi2 If `TRUE`, `tab2()` reports Pearson's chi-square test of
#'   independence and Cramer's V, like Stata's `tab x y, chi2 V`. Defaults to
#'   `FALSE`. See Details.
#' @param .group_order Group block order for one-way and joint tables. `"keys"`
#'   retains key order; `"frequency"` orders by descending observation count
#'   (summed frequency weights when `.wt` is used), including missing measured
#'   values. Missing grouping keys appear last and ties follow key order.
#'   `.desc` controls categories within groups independently.
#'
#' @returns A table, list of tables, or explicitly requested flextable:
#' * `tab()` and `fre()` return one row per observed combination of measured
#'   categories and grouping keys, with the selected columns, `n` (count),
#'   `percent`, `cum`, `valid`, and `valid_cum` (percentages from zero to 100).
#'   Totals add rows and can change category types or add a `total` column (see
#'   Details).
#' * `tab1()` and `fre1()` return a list named by measured variable. Each table
#'   contains grouping keys, a `value` column, and the same count/percentage
#'   columns. `.type = "tibble"` combines tables with a `variable` column.
#' * `tab2()` and `fre2()` return counts with one row per row category and one
#'   column per column category, preceded by the row-category column. Totals add
#'   a row and column. Three or more variables give a list of pairwise tables
#'   named like `"x x y"`; explicit `.by` gives a list per group, containing
#'   pairwise lists when needed.
#'
#' Selecting no measured variables returns zero rows with count/percentage
#' columns and grouping keys for `tab()`/`fre()`, an empty list (or empty
#' combined tibble) for `tab1()`/`fre1()`, and an empty table for
#' `tab2()`/`fre2()`. Cross-tabulation rejects one selected variable; flextable
#' cross-tabulation requires at least two.
#'
#' With `.chi2 = TRUE`, each data cross-table has a one-row tibble in its `chi2`
#' attribute: `statistic`, `df`, `p_value`, `cramers_v`, and `n`. Undefined test
#' statistics are `NA`. Flextables show the test in their footer instead.
#'
#' Default tables preserve the input's data.frame, tibble, or data.table
#' container, including tables in lists. Results are ungrouped; supported
#' preview settings persist unless an explicit output type is requested. Other
#' subclasses are not reconstructed.
#'
#' @name tab
#'
#' @examples
#' # fre() shows value labels; tab() keeps the labelled codes
#' fre(lifeexp, region)
#'
#' tab(lifeexp, region)
#'
#' # Tabulate a column by position, a condition, or a named expression.
#' tab(lifeexp, 1)
#'
#' tab(lifeexp, region, .desc = TRUE)
#'
#' tab(lifeexp, lexp >= 70)
#'
#' tab(lifeexp, lexp_70 = lexp >= 70)
#'
#' # Mix an existing column and a computed category
#' tab(lifeexp, region, lexp_70 = lexp >= 70)
#'
#' tab2(lifeexp, region, lexp_70 = lexp >= 70)
#'
#' tab(lifeexp, varlist("*p*"))
#'
#' tab(lifeexp)
#'
#' tab(c(1, 1, 2, NA))
#'
#' fre(c(1, 1, 2, NA))
#'
#' # Weighted frequencies, like Stata's tab x [fw=w] or [aw=w].
#' survey <- tibble::tibble(edu = c("low", "high", "high"), w = c(2, 1, 1.5))
#' tab(survey, edu, .wt = w)
#'
#' tab(survey, edu, .wt = w, .wt_type = "analytic")
#'
#' # Illustrative indicators for cross-tabulation; keep lifeexp unchanged.
#' countries <- dplyr::mutate(
#'   lifeexp,
#'   lexp_70 = lexp >= 70,
#'   water_80 = safewater >= 80
#' )
#' tab(countries, region, lexp_70)
#'
#' tab(countries, lexp_70, .by = region, .group_order = "frequency")
#'
#' tab1(lifeexp, 1:3)
#'
#' tab1(countries, matches("^(region|lexp_70)$"))
#'
#' tab(lifeexp, region, .total = TRUE)
#'
#' tab2(countries, region, lexp_70)
#'
#' fre2(countries, lexp, lexp_70)
#'
#' # Every pairwise table, like Stata's tab2 region lexp_70 water_80.
#' tab2(countries, region, lexp_70, water_80)
#'
#' # One cross-table per group, like Stata's by region: tab lexp_70 water_80.
#' tab2(countries, lexp_70, water_80, .by = region) |> head(2)
#'
#' # Chi-square test of independence, like Stata's tab x y, chi2 V.
#' chi2 <- tab2(countries, region, lexp_70, .chi2 = TRUE)
#' attr(chi2, "chi2")
#'
#' # Several character columns share a suffix in this dataset.
#' starwars <- dplyr::starwars
#' tab(starwars, ends_with("color"))
#'
#' tab1(starwars, ends_with("color"))
#'
#' tab1(starwars, ends_with("color"), .type = "tibble")
#'
#' fre1(starwars, ends_with("color"))
#' @family tabulation functions
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
