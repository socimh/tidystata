#' Assert that conditions hold
#'
#' Verify that every row satisfies all specified conditions, like Stata's
#' `assert`. Stop with an error if any condition fails; otherwise, return
#' the original data invisibly.
#'
#' @inheritParams tidystata_args
#' @param ... Logical conditions using columns of `.data`. Every condition
#'   must be `TRUE` for every row.
#' @param .by <[`tidy-select`][dplyr_tidy_select]> Optional grouping variables.
#'   Summaries such as `mean(x)` are evaluated within each group.
#'
#' @returns `.data`, unchanged and invisibly, if all conditions pass.
#'
#' @details
#' Both `FALSE` and `NA` count as failures. Errors report the number of
#' failing rows for each condition, including missing results, and the first
#' five failing row numbers. A failed group-level condition counts every
#' row in that group.
#'
#' Unlike Stata, `x > 0` fails when `x` is missing. Use
#' `is.na(x) | x > 0` to allow missing values.
#'
#' @examples
#' scores <- data.frame(
#'   class = c("A", "A", "B", "B"),
#'   score = c(80, 90, 55, NA_real_)
#' )
#'
#' # Pass: every nonmissing score is at least 50
#' assert(scores, is.na(score) | score >= 50)
#'
#' # Fail: row 3 is below 60, and row 4 is missing
#' try(assert(scores, score >= 60))
#'
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
