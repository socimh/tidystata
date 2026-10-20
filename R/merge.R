#' Merge two tables with a Stata-style match report
#'
#' @description
#' `s_merge()` joins `using` onto `.data` like Stata's `merge`. It checks the
#' stated key relationship first, keeps master, using and matched rows by
#' default, reports how many rows fell into each group, and records the result
#' in a `.merge` column (Stata's `_merge`).
#'
#' @param .data The master table: a data frame, tibble, or data.table.
#' @param using The table to merge in.
#' @param relationship The key relationship, as in Stata: `"1:1"` (keys unique
#' in both tables), `"m:1"` (unique in `using`) or `"1:m"` (unique in `.data`).
#' It is required and checked before joining. Many-to-many merges are not
#' supported, as in Stata; use [dplyr::inner_join()] with
#' `relationship = "many-to-many"` if you really need all pairings.
#' @param by A character vector of key columns. Use a named vector, such as
#' `c(id = "person_id")`, when the names differ (`.data` name = `using` name).
#' @param .keep Which rows to keep: any of `"master"` (only in `.data`),
#' `"using"` (only in `using`) and `"match"` (in both). Default keeps all, as
#' Stata does.
#' @param .assert `NULL` (default) or any of `"master"`, `"using"` and
#' `"match"`. If given, every row must be in one of these groups, otherwise
#' `s_merge()` errors, like Stata's `assert()` option.
#' @param .generate Name of the result column, `".merge"` by default. Use
#' `NULL` to omit it (Stata's `nogenerate`).
#' @param .report A single `TRUE` or `FALSE`. If `TRUE` (default), print the
#' match report as a message.
#'
#' @returns The merged table, in the container of `.data`. Rows from `.data`
#' come first in their original order, followed by rows found only in
#' `using`. The `.merge` column is a factor with levels `"master only"`,
#' `"using only"` and `"matched"`.
#'
#' @details
#' Missing key values match each other, as in Stata. When a non-key column
#' exists in both tables, the values from `.data` are kept and the `using`
#' column is dropped with a message, as Stata does without `update`; rename
#' the column first to keep both. Grouping is not retained.
#'
#' @family data checking functions
#' @export
#' @examples
#' people <- tibble::tibble(id = 1:3, age = c(30, 41, 25))
#' income <- tibble::tibble(id = c(2, 3, 4), income = c(10, 20, 30))
#' s_merge(people, income, "1:1", by = "id")
#'
#' # Keep matched rows only, and insist that every person is matched
#' try(s_merge(people, income, "1:1", by = "id", .assert = "match"))
#' s_merge(people, income, "1:1", by = "id", .keep = "match", .report = FALSE)
#'
#' # Many people per household
#' members <- tibble::tibble(hh = c(1, 1, 2), person = 1:3)
#' households <- tibble::tibble(hh = 1:2, region = c("north", "south"))
#' s_merge(members, households, "m:1", by = "hh")
s_merge <- function(
  .data,
  using,
  relationship,
  by,
  .keep = c("master", "using", "match"),
  .assert = NULL,
  .generate = ".merge",
  .report = TRUE
) {
  if (!is.data.frame(.data) || !is.data.frame(using)) {
    cli::cli_abort("{.arg .data} and {.arg using} must be data frames.")
  }
  if (missing(relationship)) {
    cli::cli_abort(
      "Specify the key {.arg relationship}: {.val 1:1}, {.val m:1} or {.val 1:m}."
    )
  }
  relationship <- match.arg(relationship, c("1:1", "m:1", "1:m"))
  if (missing(by) || !is.character(by) || !length(by) || anyNA(by)) {
    cli::cli_abort("{.arg by} must be a character vector of key columns.")
  }
  groups <- c("master", "using", "match")
  .keep <- merge_groups(.keep, ".keep")
  if (!is.null(.assert)) {
    .assert <- merge_groups(.assert, ".assert")
  }
  check_bool(.report)

  master <- dplyr::ungroup(table_working_data(.data))
  other <- dplyr::ungroup(table_working_data(using))
  master_keys <- if (is.null(names(by))) {
    by
  } else {
    ifelse(nzchar(names(by)), names(by), by)
  }
  using_keys <- unname(by)
  merge_check_keys(master, master_keys, "{.arg .data}")
  merge_check_keys(other, using_keys, "{.arg using}")
  if (relationship %in% c("1:1", "1:m")) {
    merge_check_unique(
      master,
      master_keys,
      "the master data ({.arg .data})"
    )
  }
  if (relationship %in% c("1:1", "m:1")) {
    merge_check_unique(other, using_keys, "the using data")
  }

  # Stata keeps the master's values for shared non-key columns.
  shared <- intersect(
    setdiff(names(master), master_keys),
    setdiff(names(other), using_keys)
  )
  if (length(shared)) {
    cli::cli_inform(c(
      "Kept the values from {.arg .data} for column{?s} also in {.arg using}: {.var {shared}}.",
      i = "Rename them in {.arg using} first to keep both."
    ))
    other <- other[setdiff(names(other), shared)]
  }
  if (!is.null(.generate)) {
    check_string(.generate, allow_empty = FALSE, allow_null = TRUE)
    if (.generate %in% c(names(master), names(other))) {
      cli::cli_abort(
        "Column {.var {(.generate)}} already exists; choose another {.arg .generate} name."
      )
    }
  }

  in_master <- merge_marker(c(names(master), names(other)), "master")
  in_using <- merge_marker(c(names(master), names(other), in_master), "using")
  master[[in_master]] <- TRUE
  other[[in_using]] <- TRUE
  joined <- dplyr::full_join(
    master,
    other,
    by = by,
    relationship = switch(
      relationship,
      "1:1" = "one-to-one",
      "m:1" = "many-to-one",
      "1:m" = "one-to-many"
    )
  )
  # Status codes index `groups`: 1 master only, 2 using only, 3 matched.
  status <- (!is.na(joined[[in_master]])) + 2L * (!is.na(joined[[in_using]]))
  counts <- stats::setNames(tabulate(status, nbins = 3L), groups)
  joined[[in_master]] <- NULL
  joined[[in_using]] <- NULL

  if (.report) {
    # The report is a fixed-width table, so keep its spacing as written.
    rlang::inform(merge_report(counts, .generate))
  }
  if (!is.null(.assert) && !all(counts[setdiff(groups, .assert)] == 0L)) {
    found <- setdiff(groups[unique(status)], .assert)
    found <- paste0(
      counts[found],
      " ",
      merge_group_label(found),
      " row(s)",
      collapse = " and "
    )
    allowed <- paste(merge_group_label(.assert), collapse = ", ")
    cli::cli_abort(
      "Merge assertion failed: found {found}; {.arg .assert} allows only {allowed}."
    )
  }
  if (!is.null(.generate)) {
    joined[[.generate]] <- factor(
      status,
      levels = seq_along(groups),
      labels = merge_group_label(groups)
    )
  }
  keep <- groups[status] %in% .keep
  if (!all(keep)) {
    joined <- joined[keep, , drop = FALSE]
  }
  table_restore(joined, .data)
}

merge_groups <- function(value, argument, call = rlang::caller_env()) {
  groups <- c("master", "using", "match")
  if (!is.character(value) || !length(value) || !all(value %in% groups)) {
    cli::cli_abort(
      "{.arg {argument}} must contain {.val master}, {.val using} and/or {.val match}.",
      call = call
    )
  }
  unique(value)
}

merge_group_label <- function(group) {
  unname(c(master = "master only", using = "using only", match = "matched")[
    group
  ])
}

merge_check_keys <- function(data, keys, label, call = rlang::caller_env()) {
  missing <- setdiff(keys, names(data))
  if (length(missing)) {
    cli::cli_abort(
      paste0("Key column(s) not found in ", label, ": {.var {missing}}."),
      call = call
    )
  }
}

merge_check_unique <- function(data, keys, label, call = rlang::caller_env()) {
  copies <- key_copies(tibble::as_tibble(data[keys]))
  if (any(copies > 1L)) {
    verb <- if (length(keys) == 1L) "does" else "do"
    keys <- key_label(keys)
    shared <- sum(copies > 1L)
    cli::cli_abort(
      c(
        paste0(
          "{keys} {verb} not uniquely identify rows in ",
          label,
          " ({shared} rows share a key)."
        ),
        i = "Check the relationship, or see the rows with {.fn duplicates_list}."
      ),
      call = call
    )
  }
}

merge_marker <- function(taken, stem) {
  name <- paste0(".statart_in_", stem)
  while (name %in% taken) {
    name <- paste0(".", name)
  }
  name
}

# A Stata-like summary of the merge result from the row count of each group.
merge_report <- function(counts, generate) {
  count <- function(group) counts[[group]]
  marker <- function(group) {
    if (is.null(generate)) {
      ""
    } else {
      paste0("  (", generate, " == \"", merge_group_label(group), "\")")
    }
  }
  rows <- c(
    sprintf("%-28s%10s", "Result", "Rows"),
    strrep("-", 38),
    sprintf("%-28s%10d", "Not matched", count("master") + count("using")),
    paste0(
      sprintf("%-28s%10d", "    from master", count("master")),
      marker("master")
    ),
    paste0(
      sprintf("%-28s%10d", "    from using", count("using")),
      marker("using")
    ),
    "",
    paste0(sprintf("%-28s%10d", "Matched", count("match")), marker("match")),
    strrep("-", 38)
  )
  paste(rows, collapse = "\n")
}
