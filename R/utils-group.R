# Grouping helpers shared by summ(), tab(), pwcorr() and misstable().

extract_group_var <- function(.data, by, call = rlang::caller_env()) {
  any_dot_by <- !rlang::quo_is_null(by)
  any_group_by <- dplyr::is_grouped_df(.data)

  if (!any_dot_by && any_group_by) {
    group_vars <- dplyr::group_vars(.data)
  } else if (any_dot_by) {
    check_by_selection(.data, by, call)
    group_vars <- ds(.data, !!by)
  } else {
    group_vars <- character(0)
  }

  if (!has_group_vars(.data, group_vars)) {
    cli::cli_abort(
      "The data do not include all grouping variable(s).",
      call = call
    )
  }

  group_vars
}

# `.by` selects columns; a computed expression would otherwise fail with a
# misleading "object not found" error from tidyselect.
check_by_selection <- function(.data, by, call = rlang::caller_env()) {
  expr <- rlang::quo_get_expr(by)
  if (select_expr_is_selection(expr, names(.data))) {
    return(invisible())
  }
  label <- rlang::as_label(expr)
  cli::cli_abort(
    c(
      "{.arg .by} must select existing columns, not compute {.code {label}}.",
      i = "Create the grouping column first, e.g. {.code mutate(group = {label})}, then use {.code .by = group}."
    ),
    call = call
  )
}

has_group_vars <- function(.data, group_vars) {
  contain <- .data |>
    dplyr::ungroup() |>
    dplyr::select(
      tidyselect::all_of(group_vars)
    ) |>
    capture()
  contain
}

remove_group_vars <- function(.data, ..., group_vars) {
  # Dots hold user selections, so report errors through the caller's frame.
  rlang::local_error_call(rlang::caller_env())
  if (!missing(...)) {
    check_group_selection(.data, ..., group_vars = group_vars)
    .data <- select_or_mutate(.data, ...)
  }
  out <- .data |>
    dplyr::ungroup() |>
    dplyr::select(
      -tidyselect::any_of(group_vars)
    ) |>
    # Suppress "adding missing grouping variables" message
    suppressMessages()
  out
}

# A grouping key selected under another name would be summarised as data.
check_group_selection <- function(.data, ..., group_vars) {
  if (!length(group_vars)) {
    return(invisible())
  }
  data <- dplyr::ungroup(.data)
  dots <- rlang::enquos(...)
  dots <- dots[select_is_selection(dots, names(data))]
  selected <- tryCatch(
    tidyselect::eval_select(rlang::expr(c(!!!dots)), data),
    error = function(e) NULL
  )
  if (is.null(selected)) {
    return(invisible())
  }
  source <- names(data)[selected]
  renamed <- source %in% group_vars & names(selected) != source
  if (any(renamed)) {
    cli::cli_abort(
      "Grouping column {.var {source[renamed][[1L]]}} cannot also be measured (selected as {.var {names(selected)[renamed][[1L]]}}). Copy it first, e.g. with {.fn mutate}, to summarise its values.",
      call = rlang::caller_env()
    )
  }
  invisible()
}

# Group keys in sorted order with the row locations of each group. Ungrouped
# data form one group with no key columns.
group_locations <- function(data, group_vars) {
  if (!length(group_vars)) {
    return(list(
      keys = tibble::new_tibble(list(), nrow = 1L),
      locs = list(seq_len(nrow(data)))
    ))
  }
  groups <- vctrs::vec_group_loc(
    tibble::as_tibble(data[group_vars], .name_repair = "minimal")
  )
  order <- vctrs::vec_order(groups$key)
  list(
    keys = vctrs::vec_slice(groups$key, order),
    locs = groups$loc[order]
  )
}
