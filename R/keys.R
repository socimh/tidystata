#' Check keys and duplicate rows
#'
#' @description
#' Stata-style checks of identifying variables and duplicated rows.
#'
#' * `isid()` checks that the selected columns uniquely identify the rows,
#'   like Stata's `isid`. It returns the data invisibly when they do and
#'   errors otherwise, so it can sit inside a pipeline. Wrap it in
#'   [capture()] for a `TRUE`/`FALSE` answer.
#' * `duplicates_report()` counts how many rows share the same values, like
#'   `duplicates report`.
#' * `duplicates_tag()` adds the number of other rows with the same values,
#'   like `duplicates tag, generate()`.
#' * `duplicates_list()` returns the duplicated rows, like `duplicates list`.
#' * `duplicates_drop()` keeps the first row of each duplicated set, like
#'   `duplicates drop`.
#'
#' @param .data A data frame, tibble, or data.table.
#' @param ... <[`tidy-select`][dplyr_tidy_select]> The identifying columns.
#' Omit to use all columns, as Stata does.
#' @param .missok A single `TRUE` or `FALSE`. If `FALSE` (default), `isid()`
#' errors when an identifying column contains missing values, as Stata's
#' `isid` does without the `missok` option.
#' @param .name Name of the new column created by `duplicates_tag()`.
#' @param .force A single `TRUE` or `FALSE`. When only some columns are
#' selected, rows that share those columns can still differ elsewhere, and
#' `duplicates_drop()` errors unless `.force = TRUE`, like Stata's
#' `duplicates drop varlist, force`.
#'
#' @return
#' * `isid()`: `.data`, invisibly.
#' * `duplicates_report()`: a tibble with one row per number of copies:
#'   `copies`, `observations` (rows with that many copies) and `surplus`
#'   (rows beyond the first of each set).
#' * `duplicates_tag()`: `.data` with an integer column of the number of
#'   other rows sharing the same values (0 for unique rows).
#' * `duplicates_list()`: the duplicated rows, ordered by their identifying
#'   values, with `.dup_group` (set number) and `.row` (original position).
#' * `duplicates_drop()`: `.data` without the surplus rows, with a message
#'   giving the number of rows removed.
#'
#' The input's data.frame, tibble, data.table or grouped container is kept
#' where rows or columns of `.data` are returned.
#'
#' @details
#' Missing values count as equal to each other, as in Stata, so two rows
#' that are both missing on every selected column are duplicates.
#'
#' @name keys
#' @examples
#' panel <- tibble::tibble(
#'   id = c(1, 1, 2, 2, 3),
#'   wave = c(1, 2, 1, 1, 1),
#'   score = c(5, 6, 7, 7, 8)
#' )
#' # id repeats, so this errors; capture() turns it into TRUE/FALSE
#' try(isid(panel, id))
#' capture(isid(panel, id))
#' isid(panel[-4, ], id, wave)
#'
#' duplicates_report(panel, id, wave)
#' duplicates_tag(panel, id, wave)
#' duplicates_list(panel, id, wave)
#' duplicates_drop(panel)
NULL

#' @rdname keys
#' @export
isid <- function(.data, ..., .missok = FALSE) {
  check_flag(.missok, ".missok")
  keys <- key_columns(.data, ...)
  labels <- key_label(names(keys))
  if (!.missok) {
    missing <- vapply(keys, function(x) any(is.na(x)), logical(1))
    if (any(missing)) {
      stop(
        "`",
        paste(names(keys)[missing], collapse = "`, `"),
        "` should never be missing to identify rows.\n",
        "\u2139 Use `.missok = TRUE` to allow missing key values.",
        call. = FALSE
      )
    }
  }
  copies <- key_copies(keys)
  if (any(copies > 1L)) {
    repeated <- sum(copies > 1L)
    sets <- length(unique(vctrs::vec_group_id(keys)[copies > 1L]))
    stop(
      labels,
      if (ncol(keys) == 1L) " does" else " do",
      " not uniquely identify the rows: ",
      sets,
      if (sets == 1L) " value appears" else " values appear",
      " more than once (",
      repeated,
      " rows).\n",
      "\u2139 See them with `duplicates_list()`.",
      call. = FALSE
    )
  }
  invisible(.data)
}

#' @rdname keys
#' @export
duplicates_report <- function(.data, ...) {
  copies <- key_copies(key_columns(.data, ...))
  levels <- sort(unique(copies))
  observations <- vapply(levels, function(k) sum(copies == k), integer(1))
  tibble::tibble(
    copies = as.integer(levels),
    observations = observations,
    surplus = as.integer(observations - observations / levels)
  )
}

#' @rdname keys
#' @export
duplicates_tag <- function(.data, ..., .name = "dup") {
  if (!rlang::is_string(.name) || !nzchar(.name)) {
    stop("`.name` must be a single nonempty string.", call. = FALSE)
  }
  if (.name %in% names(.data)) {
    stop(
      "Column `",
      .name,
      "` already exists; choose another `.name`.",
      call. = FALSE
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
  copies <- key_copies(keys)
  rows <- which(copies > 1L)
  rows <- rows[vctrs::vec_order(vctrs::vec_slice(keys, rows))]
  out <- tibble::as_tibble(
    dplyr::ungroup(table_working_data(.data)),
    .name_repair = "minimal"
  )
  out <- vctrs::vec_slice(out, rows)
  group <- vctrs::vec_group_id(vctrs::vec_slice(keys, rows))
  out$.dup_group <- as.integer(group)
  out$.row <- rows
  table_restore(out, .data)
}

#' @rdname keys
#' @export
duplicates_drop <- function(.data, ..., .force = FALSE) {
  check_flag(.force, ".force")
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
      stop(
        "Rows sharing ",
        key_label(names(keys)),
        " differ in other columns, so dropping them loses data.\n",
        "\u2139 Use `.force = TRUE` to keep the first row of each set anyway.",
        call. = FALSE
      )
    }
  }
  message(
    "(",
    sum(surplus),
    if (sum(surplus) == 1L) " row" else " rows",
    " removed)"
  )
  key_row_slice(.data, which(!surplus))
}

key_columns <- function(.data, ...) {
  if (!is.data.frame(.data)) {
    stop("`.data` must be a data frame.", call. = FALSE)
  }
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
    stop("Select at least one identifying column.", call. = FALSE)
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

check_flag <- function(value, name) {
  if (!is.logical(value) || length(value) != 1L || is.na(value)) {
    stop("`", name, "` must be a single TRUE or FALSE.", call. = FALSE)
  }
}
