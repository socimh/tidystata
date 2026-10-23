#' Tabulate columns
#'
#' @description
#' Enhanced `count()`.
#'
#' * `tab()` - Tabulates variable(s) simultaneously, similar to `count()`.
#' * `tab1()` - Tabulates variable(s) one by one.
#' * `tab2()` - Cross-tabulates two variables, like Stata's `tab x y`. With
#'   three or more variables it returns every pairwise table, like Stata's
#'   `tab2 x y z`.
#'
#' Each takes `.total = TRUE` to add "Total" rows (and, for `tab2()`, a
#' "total" column). `fre()`, `fre1()` and `fre2()` are shortcuts for
#' `tab(.total = TRUE)`, `tab1(.total = TRUE)` and `tab2(.total = TRUE)`,
#' named after Stata's `fre`.
#'
#' The functions return data by default. With totals, rich output is
#' available from `fre()`, `fre1()` and `fre2()` with
#' `.type = "flextable"` when the optional flextable package is installed.
#'
#' @details
#' ## Counts and percentages
#'
#' For `tab()`, `tab1()`, `fre()` and `fre1()`, `n` counts observations.
#' `percent` and `cum` are percentages from zero to 100 using all observations
#' within each group; `cum` follows the displayed category order. `valid` and
#' `valid_cum` use only observations with no missing measured values. Missing
#' group keys are retained and do not make an otherwise observed value invalid.
#' Missing measured categories have `NA` valid percentages and appear last.
#'
#' ## Totals
#'
#' `fre()` and `fre1()` append a `"Total"` row within each group and may add
#' `"Valid Total"` and `"Missing Total"` subtotals. In tables with up to five
#' measured variables, the final measured column is converted to character to
#' hold these labels; wider tables use a separate `total` label column.
#' Displayed value labels can coincide for distinct underlying values, or with
#' an observed `"Total"` category. Counts remain separate; use `tab()` or
#' `tab1()` when original category values and types are needed.
#'
#' ## List columns and empty selections
#'
#' `tab()` counts list-column values by their complete identities without
#' flattening their contents. Selecting no measured variables returns no rows:
#' `tab()` and `fre()` retain their count and percentage columns and any grouping
#' keys; `tab1()` and `fre1()` return an empty list by default or an empty table
#' with `.type = "tibble"`. `tab2()` returns an empty table when no
#' variables are selected and errors when only one is. With three or more, it
#' returns a list of every pairwise table, named like `"x x y"`, each with the
#' same options. With no selected variables, `tab2(..., .type = "flextable")`
#' errors because rich cross-tabulation requires two selected variables.
#'
#' ## Cross-tabulation
#'
#' Cross-tabulation keeps category names unchanged. Categories may match the
#' original variable names. Column categories follow their values: factor
#' levels in order, other types ascending, with missing values last.
#' A category matching the combined row-header name,
#' or literal `"NA"` alongside a missing column category, causes a name-collision
#' error. With `tab2(.total = TRUE)`, the column category `"total"` is reserved
#' for marginal totals; recode it first or omit the totals.
#' The final row of `tab2(.total = TRUE)` is the marginal total, labelled `"total"`; an
#' observed row category with the same label remains a separate row.
#' Blank column categories use `"<empty>"`, with the smallest unused numeric
#' suffix when that header is already taken. Logical cross-tabulation axes
#' follow `FALSE`, `TRUE`, then missing values.
#'
#' ## Chi-square test
#'
#' With `.chi2 = TRUE`, `tab2()` tests the categories shown in the table,
#' including missing ones (filter them out first to exclude them), and drops
#' rows or columns with no observations. It prints Pearson's chi-square, its
#' degrees of freedom, the p-value and Cramer's V as a message, and stores
#' them as a one-row tibble in `attr(result, "chi2")` with columns
#' `statistic`, `df`, `p_value`, `cramers_v` and `n`. Flextable output adds
#' them as a footer. As in Stata, V keeps its sign in 2 x 2 tables. The test
#' matches `chisq.test(correct = FALSE)`. Frequency weights are treated as
#' counts; analytic weights are an error, because a design-based test such as
#' `survey::svychisq()` is needed for sampling weights.
#'
#' ## Combined output
#'
#' Combined `tab1()` output uses character values when factor types cannot be
#' combined; each variable's category order is retained. List output preserves
#' the original category classes.
#'
#' If the output tibble has many rows, consider using
#' `print()` to display the output.
#'
#' @param .data An in-memory data frame, tibble, or data.table.
#' Collect lazy tables before tabulating. `tab()`, `tab1()`, `fre()` and
#' `fre1()` also accept an atomic vector, tabulated as a tibble column named
#' `value`; omit selectors and `.by` in this form. `tab2()` needs a data
#' frame.
#' All spatial `sfc` geometry columns are excluded before attribute tabulation;
#' geometry columns cannot be selected as measured variables or grouping keys.
#' @param ... <[`tidy-select`][dplyr_tidy_select]> or
#' <[`data-masking`][args_data_masking]> Variables to tabulate.
#'
#' Both tidyselect (e.g., `starts_with()`) and
#' data masking (e.g., `x_sq = x^2`) are supported.
#' See examples below.
#' @param .by Optional grouping columns, selected with tidyselect. For `tab()`,
#' `tab1()`, `fre()` and `fre1()`, `NULL` inherits existing `group_by()` groups;
#' an explicit selection replaces them. Grouping columns are not measured
#' variables. For `tab2()` and `fre2()`, `.by` returns a list with one
#' cross-table per group, named like `"g = a"`, as Stata's `by g: tab x y`;
#' grouped data are not split without `.by`. `tab2()` does not accept `.desc`
#' or `.group_order`.
#' @param .desc If `TRUE`, sort categories by descending count within each
#' group (missing categories stay last). To order the `.by` group blocks by
#' size, use `.group_order = "frequency"`.
#' @param .type Output type. `tab1()` and `fre1()` default to a list of
#' tables; `fre()`, `tab2()` and `fre2()` default to `"auto"`, preserving the input
#' container. Explicit `"tibble"` always returns a plain tibble. Explicit
#' `"flextable"` output requires the optional flextable package.
#' @param .flip A single `TRUE` or `FALSE`. If `TRUE`, swap the rows and
#' columns of the cross-table.
#' @param .wt Optional weights: a numeric column of `.data` (or a vector
#' with one value per row), like Stata's `[fweight]`/`[aweight]`. Rows with a
#' missing weight are excluded with a message; negative weights are an error.
#' When `...` is omitted, the weight column is not tabulated itself.
#' @param .wt_type `"frequency"` (default) or `"analytic"`. Frequency weights
#' count each row `w` times, so `n` is the sum of the weights, as in
#' `dplyr::count(wt =)`; non-integer weights are allowed. Analytic weights
#' (Stata's `[aweight]`, suitable for sampling weights) are rescaled within
#' each `.by` group to sum to the number of rows, so `n` stays on the sample
#' scale. Percentages are the same under both types.
#' @param .total A single `TRUE` or `FALSE`. If `TRUE`, add "Total" rows:
#' `tab(.total = TRUE)` is `fre()` and `tab1(.total = TRUE)` is `fre1()`.
#' `tab2(.total = TRUE)` is `fre2()` and adds a total row and a total column.
#' Flextable output from `tab2()` requires totals.
#' @param .chi2 A single `TRUE` or `FALSE`. If `TRUE`, `tab2()` reports
#' Pearson's chi-square test of independence and Cramer's V, like Stata's
#' `tab x y, chi2 V`. See Details.
#' @param .group_order Group block order for one-way and joint tables. `"keys"`
#' retains key order; `"frequency"` orders by descending observation count,
#' including missing measured values. Missing grouping keys appear last and ties
#' follow key order. `.desc` controls categories within each group independently.
#'
#' @returns
#' A table, a list of tables, or an explicitly requested flextable. Default
#' tables preserve the input's data.frame, tibble, or data.table container,
#' including each table in a list. Results are ungrouped, with grouping keys
#' retained as columns where applicable. Supported preview settings persist
#' unless an explicit output type is requested. Other subclasses are not
#' reconstructed on these newly shaped tables. Input data are not modified.
#'
#' @name tab
#'
#' @examples
#' # fre() shows value labels; tab() keeps the labelled codes
#' fre(lifeexp, region)
#'
#' tab(lifeexp, region)
#'
#' # tabulate a condition
#' tab(lifeexp, safewater > 50)
#'
#' starwars <- dplyr::starwars
#'
#' # tabulate the 8th column
#' tab(starwars, 8)
#'
#' # tabulate the "sex" column
#' tab(starwars, sex)
#'
#' tab(starwars, sex, .desc = TRUE)
#'
#' fre(starwars, sex)
#'
#' fre(starwars, sex, .desc = TRUE)
#'
#' tab(starwars, sex, gender)
#'
#' tab(starwars, sex == "male")
#'
#' tab(starwars, male = sex == "male")
#'
#' tab(starwars, ends_with("color"))
#'
#' tab(starwars, varlist("s*e"))
#'
#' tab(starwars)
#'
#' tab(c(1, 1, 2, NA))
#'
#' fre(c(1, 1, 2, NA))
#'
#' # Weighted frequencies, like Stata's tab x [fw=w] or [aw=w]
#' survey <- tibble::tibble(edu = c("low", "high", "high"), w = c(2, 1, 1.5))
#' tab(survey, edu, .wt = w)
#' tab(survey, edu, .wt = w, .wt_type = "analytic")
#'
#' tab(starwars, sex, .by = species, .group_order = "frequency")
#'
#' tab1(starwars, 1:3)
#'
#' tab1(starwars, ends_with("color"))
#'
#' tab1(starwars, matches("^(sex|gender)$"))
#'
#' tab1(starwars, ends_with("color"), .type = "tibble")
#'
#' fre1(starwars, ends_with("color"))
#'
#' fre1(starwars, ends_with("color"), .type = "list")
#'
#' tab(starwars, sex, .total = TRUE)
#'
#' tab2(starwars, sex, gender)
#'
#' tab2(starwars, height, gender)
#'
#' fre2(starwars, height, gender)
#'
#' # Every pairwise table, like Stata's tab2 sex gender eye_color
#' tab2(starwars, sex, gender, eye_color)
#'
#' # One cross-table per group, like Stata's by species: tab sex gender
#' tab2(starwars, sex, gender, .by = species) |> head(2)
#'
#' # Chi-square test of independence, like Stata's tab x y, chi2 V
#' chi2 <- tab2(starwars, sex, gender, .chi2 = TRUE)
#' attr(chi2, "chi2")
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
  .data <- weights_drop_column(weighted$data, weighted$column, !missing(...))
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
  .data <- weights_drop_column(weighted$data, weighted$column, !missing(...))
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
  .data <- weighted$data
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
    tab_ungroup(select_or_mutate(.data, ...))
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
  .data <- weights_drop_column(weighted$data, weighted$column, !missing(...))
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
  .data <- weights_drop_column(weighted$data, weighted$column, !missing(...))
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
