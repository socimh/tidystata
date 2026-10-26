#' Assert that conditions hold
#'
#' Check conditions on every row, like Stata's `assert`, and stop with the
#' number of contradictions when any fails. It returns the data invisibly when
#' all hold, so it can sit inside a pipeline.
#'
#' @inheritParams tidystata_args
#' @param ... Conditions evaluated like [dplyr::mutate()] expressions, each
#'   giving `TRUE` or `FALSE` per row (or a single value). Group functions such
#'   as `n()` and `mean()` use the groups of `.data` or `.by`.
#' @param .by <[`tidy-select`][dplyr_tidy_select]> Optional grouping variables,
#'   like Stata's `by g: assert`.
#'
#' @returns `.data`, invisibly, when every condition holds.
#'
#' @details
#' The error lists each failing condition with its number of contradictions and
#' the first failing rows. A missing result (`NA`) counts as a contradiction and
#' is reported separately. This differs from Stata, where a missing value is
#' larger than every number, so `assert x > 0` holds when `x` is missing; write
#' `is.na(x) | x > 0` for that behaviour.
#'
#' @examples
#' lifeexp |>
#'   assert(lexp > 0, popgrowth < 10) |>
#'   summ(lexp)
#'
#' # Each country appears once per region
#' assert(lifeexp, dplyr::n() == dplyr::n_distinct(country), .by = region)
#'
#' try(assert(lifeexp, safewater > 50))
#' @family data checking functions
#' @export
assert <- function(.data, ..., .by = NULL) {
  check_data_frame(.data)
  conditions <- rlang::enquos(...)
  if (!length(conditions)) {
    cli::cli_abort("Supply at least one condition to check.")
  }
  labels <- vapply(conditions, rlang::as_label, character(1))
  data <- table_working_data(.data)
  referenced <- unlist(
    lapply(conditions, function(condition) {
      all.names(rlang::quo_get_expr(condition))
    }),
    use.names = FALSE
  )
  result_names <- paste0("...assert", seq_along(conditions))
  while (any(result_names %in% c(names(data), referenced))) {
    result_names <- paste0(".", result_names)
  }
  names(conditions) <- result_names
  results <- dplyr::mutate(
    data,
    !!!conditions,
    .by = {{ .by }},
    .keep = "none"
  )
  failures <- character()
  for (i in seq_along(conditions)) {
    value <- results[[names(conditions)[[i]]]]
    if (!is.logical(value)) {
      cli::cli_abort(
        "Condition {.code {labels[[i]]}} must give {.code TRUE} or {.code FALSE}, not {.obj_type_friendly {value}}."
      )
    }
    if (!is.null(dim(value))) {
      cli::cli_abort(
        "Condition {.code {labels[[i]]}} must give a logical vector with one value per row."
      )
    }
    failed <- which(!value | is.na(value))
    if (length(failed)) {
      missing <- sum(is.na(value))
      failures <- c(
        failures,
        paste0(
          "`",
          labels[[i]],
          "`: ",
          format(length(failed), big.mark = ","),
          if (length(failed) == 1L) " contradiction" else " contradictions",
          if (missing) paste0(" (", missing, " missing)"),
          " in ",
          format(nrow(data), big.mark = ","),
          if (nrow(data) == 1L) " row; " else " rows; ",
          if (length(failed) == 1L) "row " else "rows ",
          paste(utils::head(failed, 5L), collapse = ", "),
          if (length(failed) > 5L) ", ..."
        )
      )
    }
  }
  if (length(failures)) {
    # Interpolate each failure so condition labels are never parsed by cli.
    bullets <- sprintf("{failures[[%d]]}", seq_along(failures))
    cli::cli_abort(c("Assertion failed:", rlang::set_names(bullets, "*")))
  }
  invisible(.data)
}
