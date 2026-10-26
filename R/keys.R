#' Check keys and duplicate rows
#'
#' @description
#' Stata-style checks of identifying variables and duplicated rows.
#'
#' * `isid()`: Check that the selected columns uniquely identify the rows, like
#'   Stata's `isid`. It confirms a valid key with a message and returns the
#'   data invisibly, so it can sit inside a pipeline. Invalid keys raise an error.
#' * `duplicates_report()`: Count how many rows share the same values, like
#'   `duplicates report`.
#' * `duplicates_tag()`: Add the number of other rows with the same values, like
#'   `duplicates tag, generate()`.
#' * `duplicates_list()`: Return the duplicated rows, like `duplicates list`.
#' * `duplicates_drop()`: Keep the first row of each duplicated set, like
#'   `duplicates drop`.
#'
#' @inheritParams tidystata_args
#' @param ... <[`tidy-select`][dplyr_tidy_select]> The identifying columns. Omit
#'   to use all columns. Stata's `isid` requires an explicit variable list.
#' @param .missing If `FALSE` (default), `isid()` errors when an identifying
#'   column contains missing values or empty strings, as Stata's `isid` does
#'   without `missok`. If `TRUE`, permit these values but still require unique
#'   key combinations. Rows are not dropped.
#' @param .name Name of the new column created by `duplicates_tag()`.
#' @param .force If `TRUE`, allow `duplicates_drop()` to remove rows that match
#'   on the selected columns but differ elsewhere, like Stata's `duplicates drop
#'   varlist, force`. Defaults to `FALSE`; exact duplicate rows can be dropped
#'   without this option.
#'
#' @returns
#' * `isid()`: `.data`, unchanged and invisibly, after a confirmation message.
#' * `duplicates_report()`: a tibble with one row per number of copies:
#'   `copies`, `observations` (rows with that many copies) and `surplus` (rows
#'   beyond the first of each set).
#' * `duplicates_tag()`: `.data` with an integer column of the number of other
#'   rows sharing the same values (0 for unique rows).
#' * `duplicates_list()`: the duplicated rows, ordered by their identifying
#'   values, with `.dup_group` (set number) and `.row` (original position).
#' * `duplicates_drop()`: `.data` without surplus rows, keeping the first row of
#'   each set in input order.
#'
#' The input's data.frame, tibble, data.table or grouped container is kept where
#' rows or columns of `.data` are returned.
#'
#' @details
#' Unlike Stata's silent success, `isid()` names the columns that form a valid
#' key. This confirms uniqueness without storing an ID declaration or adding
#' metadata. Use [suppressMessages()] for silent execution. An empty input
#' reports that there are no rows to check. Checks preserve row order; use
#' [dplyr::arrange()] separately to sort, or [haven::read_dta()] to read a file.
#' Factor values equal to `""` are empty strings; whitespace is not trimmed.
#'
#' Missing values count as equal to each other, as in Stata, so two rows that
#' are both missing on every selected column are duplicates. Checks and
#' duplicate counts use the whole input, regardless of grouping.
#' `duplicates_list()` rejects existing `.dup_group` or `.row` columns; rename
#' them first. `duplicates_drop()` reports the number of rows removed as a
#' message. The input data are not modified.
#'
#' @name keys
#' @examples
#' panel <- tibble::tibble(
#'   id = c(1, 1, 2, 2, 3),
#'   wave = c(1, 2, 1, 1, 1),
#'   score = c(5, 6, 7, 7, 8)
#' )
#' # id repeats, so this check fails and shows the error
#' try(isid(panel, id))
#'
#' # Remove the duplicate row so id + wave uniquely identify observations
#' unique_panel <- dplyr::distinct(panel)
#' # Confirms that id + wave form a key; returns unique_panel invisibly
#' isid(unique_panel, id, wave)
#'
#' duplicates_report(panel, id, wave)
#'
#' duplicates_tag(panel, id, wave)
#'
#' duplicates_list(panel, id, wave)
#'
#' duplicates_drop(panel)
#' @family data checking functions
NULL

#' @rdname keys
#' @export
isid <- function(.data, ..., .missing = FALSE) {
  check_bool(.missing)
  keys <- key_columns(.data, ...)
  labels <- key_label(names(keys))
  if (!.missing) {
    missing <- vapply(
      keys,
      function(x) {
        missing <- any(is.na(x))
        if (is.character(x) || is.factor(x)) {
          missing <- missing || any(as.character(x) == "", na.rm = TRUE)
        }
        missing
      },
      logical(1)
    )
    if (any(missing)) {
      cli::cli_abort(c(
        "{.var {names(keys)[missing]}} should never be missing to identify rows.",
        i = "Use {.code .missing = TRUE} to allow missing key values."
      ))
    }
  }
  copies <- key_copies(keys)
  if (any(copies > 1L)) {
    repeated <- sum(copies > 1L)
    sets <- length(unique(vctrs::vec_group_id(keys)[copies > 1L]))
    verb <- if (ncol(keys) == 1L) "does" else "do"
    cli::cli_abort(c(
      "{labels} {verb} not uniquely identify the rows: {sets} value{?s} appear{?s/} more than once ({repeated} rows).",
      i = "See them with {.fn duplicates_list}."
    ))
  }
  if (!nrow(.data)) {
    cli::cli_inform("No rows to check.")
  } else if (ncol(keys) == 1L) {
    cli::cli_inform("{labels} uniquely identifies the rows.")
  } else {
    cli::cli_inform("{labels} together uniquely identify the rows.")
  }
  invisible(.data)
}

#' @rdname keys
#' @export
duplicates_report <- function(.data, ...) {
  copies <- key_copies(key_columns(.data, ...))
  levels <- sort(unique(copies))
  observations <- tabulate(copies)[levels]
  tibble::tibble(
    copies = as.integer(levels),
    observations = observations,
    surplus = as.integer(observations - observations / levels)
  )
}

#' @rdname keys
#' @export
duplicates_tag <- function(.data, ..., .name = "dup") {
  check_string(.name, allow_empty = FALSE)
  if (.name %in% names(.data)) {
    cli::cli_abort(
      "Column {.var {(.name)}} already exists; choose another {.arg .name}."
    )
  }
  tags <- key_copies(key_columns(.data, ...)) - 1L
  if (inherits(.data, "data.table")) {
    out <- data.table::copy(.data)
    data.table::set(out, j = .name, value = tags)
    return(out)
  }
  .data[[.name]] <- tags
  .data
}

#' @rdname keys
#' @export
duplicates_list <- function(.data, ...) {
  keys <- key_columns(.data, ...)
  clash <- intersect(c(".dup_group", ".row"), names(.data))
  if (length(clash)) {
    cli::cli_abort(c(
      "Column {.var {clash[[1L]]}} already exists.",
      i = "Rename it before calling {.fn duplicates_list}."
    ))
  }
  copies <- key_copies(keys)
  rows <- which(copies > 1L)
  rows <- rows[vctrs::vec_order(vctrs::vec_slice(keys, rows))]
  out <- key_row_slice(.data, rows)
  group <- vctrs::vec_group_id(vctrs::vec_slice(keys, rows))
  out$.dup_group <- as.integer(group)
  out$.row <- rows
  out
}

#' @rdname keys
#' @export
duplicates_drop <- function(.data, ..., .force = FALSE) {
  check_bool(.force)
  keys <- key_columns(.data, ...)
  all_columns <- ncol(keys) == ncol(.data)
  surplus <- duplicated(vctrs::vec_group_id(keys))
  if (!all_columns && !.force && any(surplus)) {
    # Dropping loses data when a removed row is not an exact copy of a kept one.
    full <- tibble::as_tibble(
      dplyr::ungroup(table_working_data(.data)),
      .name_repair = "minimal"
    )
    kept <- vctrs::vec_slice(full, which(!surplus))
    if (vctrs::vec_unique_count(kept) < vctrs::vec_unique_count(full)) {
      cli::cli_abort(c(
        "Rows sharing {sub('^V', 'v', key_label(names(keys)))} differ in other columns, so dropping them loses data.",
        i = "Use {.code .force = TRUE} to keep the first row of each set anyway."
      ))
    }
  }
  cli::cli_inform("({sum(surplus)} row{?s} removed)")
  key_row_slice(.data, which(!surplus))
}

key_columns <- function(.data, ..., call = rlang::caller_env()) {
  check_data_frame(.data, call = call)
  data <- dplyr::ungroup(table_working_data(.data))
  if (missing(...)) {
    return(tibble::as_tibble(data, .name_repair = "minimal"))
  }
  selected <- tidyselect::eval_select(
    rlang::expr(c(...)),
    data,
    allow_rename = FALSE
  )
  if (!length(selected)) {
    cli::cli_abort("Select at least one identifying column.", call = call)
  }
  tibble::as_tibble(data[selected], .name_repair = "minimal")
}

# Number of rows (including itself) sharing each row's key values.
key_copies <- function(keys) {
  id <- vctrs::vec_group_id(keys)
  as.integer(tabulate(id, nbins = attr(id, "n"))[id])
}

key_label <- function(names) {
  label <- paste0("`", names, "`", collapse = ", ")
  if (length(names) == 1L) {
    paste("Variable", label)
  } else {
    paste("Variables", label)
  }
}

key_row_slice <- function(.data, rows) {
  if (inherits(.data, "data.table")) {
    return(.data[rows])
  }
  dplyr::dplyr_row_slice(.data, rows)
}
