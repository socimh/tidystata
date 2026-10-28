#' Tabulate missing values
#'
#' Summarize missing values by variable (`misstable summarize`) or tabulate
#' missingness patterns across rows (`misstable patterns`), following Stata's
#' `misstable` command.
#'
#' @inheritParams tidystata_args
#' @param ... <[`tidy-select`][dplyr_tidy_select]> or
#'   <[`data-masking`][args_data_masking]> Columns to select or compute with
#'   [select_or_transmute()]. Existing columns, selection helpers, and named
#'   expressions can be mixed. Omit to check all columns except grouping keys.
#' @param .patterns If `TRUE`, tabulate missingness patterns instead of
#'   summarizing individual variables.
#' @param .all If `TRUE`, include variables without missing values in either
#'   mode. Defaults to `FALSE`, as in Stata.
#'
#' @returns An ungrouped tibble with any grouping keys and:
#' * By default, one row per checked variable and group, with `variable`,
#'   `miss_n` (missing count), `miss_pct` (missing percentage), and `valid_n`
#'   (observed count). No checked variables gives zero rows.
#' * With `.patterns = TRUE`, one row per observed pattern and group, with a `1`
#'   (observed) or `0` (missing) column per checked variable, plus `n`
#'   (frequency) and `percent`. With no checked variables, each nonempty group
#'   has one row containing only its keys, `n`, and `percent`.
#'
#' Percentages range from zero to 100 within each group. Summary rows for
#' zero-row ungrouped inputs have zero counts and `NA` percentages when `.all =
#' TRUE`; empty inputs have no pattern rows.
#'
#' @details
#' Atomic missingness follows `is.na()`, including `NaN`, haven's tagged missing
#' values, and SPSS user-missing codes and ranges. In ordinary list columns,
#' scalar `NA` elements are missing but `NULL` elements are observed. Matrix
#' and data-frame columns follow [vctrs::vec_detect_missing()] row semantics:
#' a row is missing only when all its components are missing. In a list-backed
#' matrix, a component is missing when it is `NULL`; a scalar `NA` cell is
#' observed, unlike an `NA` element in an ordinary list column.
#'
#' Computed columns are evaluated on ungrouped working data before missingness
#' is summarized within groups. Create columns with grouped [dplyr::mutate()]
#' first when a calculation needs to run separately within each group.
#'
#' Empty strings are treated as observed values, unlike in Stata. Use
#' [na_if_value()] to convert them to missing values.
#'
#' With `.all = FALSE`, variables are checked only if they contain missing
#' values anywhere in the input. A message is displayed when none do. Summary
#' rows follow selection order within each group; patterns follow decreasing
#' frequency, with ties preferring observed values column by column. Grouping
#' keys must not conflict with output column names. Pattern variables must also
#' differ from grouping keys and the names `n` and `percent`.
#'
#' @examples
#' # Summarize missing values
#' misstable(lifeexp)
#'
#' misstable(lifeexp, .all = TRUE)
#'
#' # Tabulate missingness patterns
#' misstable(lifeexp, .patterns = TRUE)
#'
#' # Select variables and group observations
#' misstable(lifeexp, gnppc, safewater, .by = region)
#'
#' # Check an existing column alongside a computed column
#' misstable(lifeexp, gnppc, water_share = safewater / 100, .all = TRUE)
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
  reserved <- if (.patterns) {
    c("n", "percent")
  } else {
    c("variable", "miss_n", "miss_pct", "valid_n")
  }
  clash <- intersect(group_vars, reserved)
  if (length(clash)) {
    cli::cli_abort(
      "Grouping column {.var {clash[[1L]]}} clashes with a result column; rename it first."
    )
  }
  .data <- dplyr::ungroup(.data)
  values <- remove_group_vars(.data, ..., group_vars = group_vars)
  # Ordinary lists follow is.na(); structured columns need one mask per row.
  missing <- lapply(values, function(x) {
    if (is.list(x) && !is.data.frame(x) && is.null(dim(x))) {
      unname(is.na(x))
    } else {
      detect_missing(x)
    }
  })
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
    # Most frequent first; ties put observed values first, column by column.
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
