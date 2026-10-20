#' Tabulate missing values
#'
#' @description
#' Missing-value summaries, like Stata's `misstable`.
#'
#' * By default, `misstable()` counts the missing values of each variable,
#'   like `misstable summarize`.
#' * With `.patterns = TRUE`, it counts the combinations of observed and
#'   missing variables across rows, like `misstable patterns`.
#'
#' @inheritParams statart_args
#' @param ... <[`tidy-select`][dplyr_tidy_select]> Variables to check. Omit to
#' check every column except grouping keys.
#' @param .patterns A single `TRUE` or `FALSE`. If `TRUE`, tabulate missing
#' patterns instead of counting by variable.
#' @param .all A single `TRUE` or `FALSE`. If `FALSE` (default), only
#' variables with at least one missing value are shown, as in Stata; if
#' `TRUE`, all checked variables are shown.
#'
#' @returns
#' By default, a tibble with any grouping keys, `variable`, `miss_n` (missing
#' values), `miss_pct` (percentage of rows, from zero to 100) and `valid_n`
#' (observed values), one row per variable (and group).
#'
#' With `.patterns = TRUE`, a tibble with any grouping keys, one column per
#' variable holding `1` (observed) or `0` (missing) as in Stata, `n` (rows with
#' that pattern) and `percent` (of the rows in the group). Patterns are sorted
#' by decreasing frequency within each group, so the first row is usually the
#' complete cases.
#'
#' @details
#' A value is missing when `is.na()` is `TRUE` for it, which includes `NaN`
#' and haven's tagged missing values such as Stata's `.a`. Empty strings are
#' observed values, unlike Stata's missing string; convert them first with
#' [na_if_value()]. When no checked variable has missing values and
#' `.all = FALSE`, a message says so and the result has no variable rows or
#' columns.
#'
#' @examples
#' misstable(starwars)
#' misstable(starwars, .all = TRUE)
#' misstable(starwars, height, mass, birth_year, .patterns = TRUE)
#' misstable(starwars, height, mass, .by = sex)
#' @family inspection functions
#' @export
misstable <- function(
  .data,
  ...,
  .by = NULL,
  .patterns = FALSE,
  .all = FALSE
) {
  check_data_frame(.data)
  check_bool(.patterns)
  check_bool(.all)
  by <- rlang::enquo(.by)
  .data <- aggregation_working_data(
    .data,
    override_groups = !rlang::quo_is_null(by)
  )
  group_vars <- extract_group_var(
    if (rlang::quo_is_null(by)) .data else dplyr::ungroup(.data),
    by
  )
  .data <- dplyr::ungroup(.data)
  values <- remove_group_vars(.data, ..., group_vars = group_vars)
  missing <- lapply(values, vctrs::vec_detect_missing)
  if (!.all) {
    missing <- missing[vapply(missing, any, logical(1))]
    if (!length(missing) && length(values)) {
      cli::cli_inform("No missing values in the selected variables.")
    }
  }
  groups <- group_locations(.data, group_vars)
  if (.patterns) {
    misstable_patterns(missing, groups, group_vars)
  } else {
    misstable_summary(missing, groups)
  }
}

misstable_summary <- function(missing, groups) {
  out <- lapply(seq_along(groups$locs), function(i) {
    loc <- groups$locs[[i]]
    miss_n <- unname(vapply(missing, function(x) sum(x[loc]), integer(1)))
    table <- tibble::tibble(
      variable = names(missing),
      miss_n = miss_n,
      miss_pct = if (length(loc)) miss_n / length(loc) * 100 else NA_real_,
      valid_n = length(loc) - miss_n
    )
    keys <- vctrs::vec_slice(groups$keys, rep(i, nrow(table)))
    dplyr::bind_cols(keys, table)
  })
  empty <- tibble::tibble(
    variable = character(),
    miss_n = integer(),
    miss_pct = numeric(),
    valid_n = integer()
  )
  vctrs::vec_rbind(dplyr::bind_cols(groups$keys[0L, ], empty), !!!out)
}

misstable_patterns <- function(
  missing,
  groups,
  group_vars,
  call = rlang::caller_env()
) {
  clash <- intersect(names(missing), c("n", "percent", group_vars))
  if (length(clash)) {
    cli::cli_abort(
      "Variable {.var {clash[[1L]]}} clashes with a pattern table column; rename it first.",
      call = call
    )
  }
  observed <- tibble::as_tibble(
    lapply(missing, function(x) as.integer(!x)),
    .name_repair = "minimal"
  )
  out <- lapply(seq_along(groups$locs), function(i) {
    loc <- groups$locs[[i]]
    if (!length(loc)) {
      return(NULL)
    }
    rows <- if (length(missing)) {
      vctrs::vec_slice(observed, loc)
    } else {
      tibble::new_tibble(list(), nrow = length(loc))
    }
    patterns <- vctrs::vec_group_loc(rows)
    n <- lengths(patterns$loc)
    table <- patterns$key
    # Most frequent first; ties put patterns with more observed values first.
    order <- do.call(base::order, c(list(-n), lapply(unname(table), `-`)))
    table <- vctrs::vec_slice(table, order)
    table$n <- n[order]
    table$percent <- table$n / length(loc) * 100
    keys <- vctrs::vec_slice(groups$keys, rep(i, nrow(table)))
    dplyr::bind_cols(keys, table)
  })
  empty <- tibble::as_tibble(
    c(
      lapply(missing, function(x) integer()),
      list(n = integer(), percent = numeric())
    ),
    .name_repair = "minimal"
  )
  vctrs::vec_rbind(dplyr::bind_cols(groups$keys[0L, ], empty), !!!out)
}
