#' Tabulate columns
#'
#' @description
#' `r lifecycle::badge("experimental")`
#' Enhanced `count()`.
#'
#' * `tab()` - Tabulates variable(s) simultaneously, similar to `count()`.
#' * `tab1()` - Tabulates variable(s) one by one.
#' * `tab2()` - Cross-tabulates two variables.
#' * `fre()` - Adds "Total" row(s) to the output of `tab()`.
#' * `fre1()` - Adds "Total" row(s) to the output of `tab1()`.
#' * `fre2()` - Adds a "Total" row and a "total" column to the output of `tab2()`.
#'
#' The tabulation and frequency functions return data by default. The `fre()`
#' family adds totals; rich output is available with `.type = "flextable"`
#' when the optional flextable package is installed.
#'
#' For `tab()`, `tab1()`, `fre()` and `fre1()`, `n` counts observations.
#' `percent` and `cum` are percentages from zero to 100 using all observations
#' within each group; `cum` follows the displayed category order. `valid` and
#' `valid_cum` use only observations with no missing measured values. Missing
#' group keys are retained and do not make an otherwise observed value invalid.
#' Missing measured categories have `NA` valid percentages and appear last.
#'
#' `fre()` and `fre1()` append a `"Total"` row within each group and may add
#' `"Valid Total"` and `"Missing Total"` subtotals. In tables with up to five
#' measured variables, the final measured column is converted to character to
#' hold these labels; wider tables use a separate `total` label column.
#' Displayed value labels can coincide for distinct underlying values, or with
#' an observed `"Total"` category. Counts remain separate; use `tab()` or
#' `tab1()` when original category values and types are needed.
#'
#' `tab()` counts list-column values by their complete identities without
#' flattening their contents. Selecting no measured variables returns no rows:
#' `tab()` and `fre()` retain their count and percentage columns and any grouping
#' keys; `tab1()` and `fre1()` return an empty list by default or an empty table
#' with `.type = "tibble"`. `tab2()` and `fre2()` return an empty table when no
#' variables are selected; otherwise exactly two variables are required.
#' With no selected variables, `fre2(..., .type = "flextable")` errors because
#' rich cross-tabulation requires two selected variables.
#'
#' Cross-tabulation keeps category names unchanged. Categories may match the
#' original variable names. Column categories follow their values: factor
#' levels in order, other types ascending, with missing values last.
#' A category matching the combined row-header name,
#' or literal `"NA"` alongside a missing column category, causes a name-collision
#' error. In `fre2()`, the column category `"total"` is reserved for marginal
#' totals; recode it first or use `tab2()`.
#' The final row in `fre2()` is the marginal total, labelled `"total"`; an
#' observed row category with the same label remains a separate row.
#' Blank column categories use `"<empty>"`, with the smallest unused numeric
#' suffix when that header is already taken. Logical cross-tabulation axes
#' follow `FALSE`, `TRUE`, then missing values.
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
#' `value`; omit selectors and `.by` in this form. `tab2()` and `fre2()` need
#' a data frame.
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
#' variables. `tab2()` and `fre2()` do not accept `.by`, `.desc` or
#' `.group_order`; supplying them is an error.
#' @param .desc If `TRUE`, sort categories by descending count within each
#' group (missing categories stay last). To order the `.by` group blocks by
#' size, use `.group_order = "frequency"`.
#' @param .type Output type. `tab1()` and `fre1()` default to a list of
#' tables; `fre()` and `fre2()` default to `"auto"`, preserving the input
#' container. Explicit `"tibble"` always returns a plain tibble. Explicit
#' `"flextable"` output requires the optional flextable package.
#' @param .flip If TRUE, will transpose the output tibble.
#' @param .group_order Group block order for one-way and joint tables. `"keys"`
#' retains key order; `"frequency"` orders by descending observation count,
#' including missing measured values. Missing grouping keys appear last and ties
#' follow key order. `.desc` controls categories within each group independently.
#'
#' @return
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
#' tab(starwars, s_match("s*e"))
#'
#' tab(starwars)
#'
#' tab(c(1, 1, 2, NA))
#'
#' fre(c(1, 1, 2, NA))
#'
#' tab(starwars, sex, .by = species, .group_order = "frequency")
#'
#' tab1(starwars, 1:3)
#'
#' tab1(starwars, ends_with("color"))
#'
#' tab1(starwars, ends_with("color"), .type = "tibble")
#'
#' fre1(starwars, ends_with("color"))
#'
#' fre1(starwars, ends_with("color"), .type = "list")
#'
#' tab2(starwars, sex, gender)
#'
#' tab2(starwars, height, gender)
#'
#' fre2(starwars, height, gender)
NULL

#' @export
#' @rdname tab
tab <- function(
  .data,
  ...,
  .by = NULL,
  .desc = FALSE,
  .group_order = c("keys", "frequency")
) {
  .group_order <- match.arg(.group_order)
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

  # Prepare data
  .data_nogroup <- prepare_tab_data(.data, ..., group_vars = group_vars)
  .data <- .data %>%
    dplyr::select(dplyr::any_of(group_vars)) %>%
    dplyr::bind_cols(.data_nogroup)

  # Confirm names
  old_names <- names(.data)
  .data <- modify_invalid_names(.data, "tab()")
  group_vars <- names(.data)[match(group_vars, old_names)]

  # Tabulate
  out <- tab_data(
    .data,
    group_vars,
    .desc
  ) %>%
    dplyr::select(-...any_miss)
  out <- order_tab_groups(out, .data, group_vars, .group_order)

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
  .group_order = c("keys", "frequency")
) {
  .group_order <- match.arg(.group_order)
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

  .type <- match.arg(.type)
  keys <- dplyr::select(dplyr::ungroup(.data), tidyselect::all_of(group_vars))
  values <- prepare_tab_data(.data, ..., group_vars = group_vars)
  .data <- dplyr::bind_cols(keys, values)
  old_names <- names(.data)
  # Measured names become list names or `variable` values, never columns.
  .data <- modify_invalid_names(.data, "tab1()", group_vars)
  group_vars <- names(.data)[match(group_vars, old_names)]

  out <- purrr::map(.data[setdiff(names(.data), group_vars)], function(value) {
    dplyr::bind_cols(.data[group_vars], tibble::tibble(value = value)) %>%
      tab_data(group_vars, .desc) %>%
      dplyr::select(-...any_miss) %>%
      order_tab_groups(.data, group_vars, .group_order)
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
  .flip = FALSE
) {
  reject_cross_controls(..., function_name = "tab2()")
  template <- .data
  .data <- aggregation_working_data(.data)
  # Prepare data
  .data <- .data %>%
    s_select(...)
  .data <- s_ungroup(.data)
  if (ncol(.data) == 0L) {
    return(table_restore(tibble::tibble(), template))
  }

  # Confirm names
  check_two_vars(.data)
  .data <- modify_invalid_names(.data, "tab2()")

  # Flip variables
  if (.flip) {
    .data <- .data %>%
      dplyr::relocate(2, 1)
  }

  # Cross-tabulate
  out <- tab2_data(.data)

  # Output
  table_restore(out, template)
}

#' @export
#' @rdname tab
fre <- function(
  .data,
  ...,
  .by = NULL,
  .desc = FALSE,
  .type = c("auto", "tibble", "flextable"),
  .group_order = c("keys", "frequency")
) {
  .group_order <- match.arg(.group_order)
  if (!is.data.frame(.data)) {
    .data <- tab_vector_data(.data, ..., .by = {{ .by }})
  }
  template <- .data
  .data <- aggregation_working_data(
    .data,
    override_groups = !rlang::quo_is_null(rlang::enquo(.by))
  )
  .type <- match.arg(.type)
  # Identify group variables
  by <- rlang::enquo(.by)
  group_vars <- extract_group_var(
    if (rlang::quo_is_null(by)) .data else dplyr::ungroup(.data),
    by
  )
  .data <- dplyr::ungroup(.data)

  # Prepare data
  .data_nogroup <- prepare_tab_data(.data, ..., group_vars = group_vars)
  .data <- .data %>%
    dplyr::select(dplyr::any_of(group_vars)) %>%
    dplyr::bind_cols(.data_nogroup)

  # Confirm names
  old_names <- names(.data)
  .data <- modify_invalid_names(.data, "fre()")
  group_vars <- names(.data)[match(group_vars, old_names)]

  # Tabulate
  out <- .data %>%
    tab_data(group_vars, .desc) %>%
    add_total(group_vars) %>%
    dplyr::select(-...any_miss)
  out <- order_tab_groups(out, .data, group_vars, .group_order)

  if (.type[1] == "flextable") {
    out <- out %>%
      result_to_flextable(group_vars)
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
  .group_order = c("keys", "frequency")
) {
  .group_order <- match.arg(.group_order)
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

  .type <- match.arg(.type)
  keys <- dplyr::select(dplyr::ungroup(.data), tidyselect::all_of(group_vars))
  values <- prepare_tab_data(.data, ..., group_vars = group_vars)
  .data <- dplyr::bind_cols(keys, values)
  old_names <- names(.data)
  .data <- modify_invalid_names(.data, "fre1()", group_vars)
  group_vars <- names(.data)[match(group_vars, old_names)]

  out <- purrr::map(.data[setdiff(names(.data), group_vars)], function(value) {
    dplyr::bind_cols(.data[group_vars], tibble::tibble(value = value)) %>%
      tab_data(group_vars, .desc) %>%
      add_total(group_vars) %>%
      dplyr::select(-...any_miss) %>%
      order_tab_groups(.data, group_vars, .group_order)
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
    out <- out %>%
      append_tab_list(blank_row = TRUE) %>%
      dplyr::slice(-dplyr::n()) %>%
      result_to_flextable(group_vars, fre1 = TRUE)
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


#' @export
#' @rdname tab
fre2 <- function(
  .data,
  ...,
  .flip = FALSE,
  .type = c("auto", "tibble", "flextable")
) {
  reject_cross_controls(..., function_name = "fre2()")
  template <- .data
  .data <- aggregation_working_data(.data)
  .type <- match.arg(.type)
  # Prepare data
  .data <- .data %>%
    s_select(...)
  .data <- s_ungroup(.data)
  if (ncol(.data) == 0L) {
    if (.type == "flextable") {
      stop(
        "Flextable cross-tabulation requires two selected variables.",
        call. = FALSE
      )
    }
    return(table_restore(tibble::tibble(), template, .type))
  }

  # Confirm names
  check_two_vars(.data)
  .data <- modify_invalid_names(.data, "fre2()")

  # Flip variables
  if (.flip) {
    .data <- .data %>%
      dplyr::relocate(2, 1)
  }

  # Cross-tabulate
  out <- .data %>%
    tab2_data() %>%
    add_total2(.data)

  if (.type[1] == "flextable") {
    out <- out %>%
      result_to_flextable(character(0), fre2 = TRUE)
  }

  # Output
  if (.type == "flextable") out else table_restore(out, template, .type)
}

# One-way and grouping controls would otherwise be read as data expressions.
reject_cross_controls <- function(..., function_name) {
  supplied <- intersect(c(".by", ".desc", ".group_order"), ...names())
  if (length(supplied)) {
    stop(
      "`",
      supplied[[1L]],
      "` is not supported by `",
      function_name,
      "`; cross-tabulations have no groups or category sorting. ",
      "Use `tab()` or `fre()` with `.by`, or filter the data first.",
      call. = FALSE
    )
  }
}

# Atomic vectors become a one-column tibble named `value`.
tab_vector_data <- function(.data, ..., .by = NULL) {
  if (!is.atomic(.data) || is.null(.data) || !is.null(dim(.data))) {
    stop("`.data` must be a data frame or an atomic vector.", call. = FALSE)
  }
  if (!missing(...)) {
    stop("For vector input, omit selectors in `...`.", call. = FALSE)
  }
  if (!rlang::quo_is_null(rlang::enquo(.by))) {
    stop("For vector input, omit `.by`.", call. = FALSE)
  }
  # tibble() reads `.data` as its data pronoun, so bind the vector first.
  value <- .data
  tibble::tibble(value = value)
}
