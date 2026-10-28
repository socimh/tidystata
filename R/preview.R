#' Set persistent table previews
#'
#' @description
#' Keep a compact console display while retaining every row and column.
#'
#' * `preview()`: Choose a head/tail or interval display.
#' * `preview_headtail()`: Show the first and last rows.
#' * `preview_interval()`: Show evenly spaced rows.
#' * `unpreview()`: Restore ordinary printing.
#'
#' @param .data An in-memory data frame, data.table, ordinary/grouped/rowwise
#'   tibble, or `sf` data frame. Collect lazy tables and convert other subclasses
#'   explicitly first. Apply previews separately to lists of tables.
#' @param style Either `"headtail"` (default) or `"interval"`.
#' @param n Total number of data rows to display, defaulting to 10. Supply a
#'   positive whole number or `Inf` for all rows; omission markers do not count.
#'
#' @returns A data frame, tibble, data.table, or `sf` data frame with the same
#'   rows, columns, values, and grouping as `.data`. The preview functions add a
#'   `tidystata_preview` class and print preferences; `unpreview()` removes them.
#'
#' @details
#' **Display**
#'
#' Head/tail previews split `n` between the beginning and end, giving an odd
#' row to the beginning. One row of vertical dots marks an omitted middle,
#' using periods without Unicode output. Interval previews show approximately
#' evenly spaced positions without separator rows. An omission footer counts
#' undisplayed rows.
#' With `n = 1`, both styles show the first row; short tables do not repeat rows.
#'
#' Row numbers refer to the current table after filtering or sorting. Grouped
#' tables use one display budget across all groups. `print(x, n = Inf,
#' width = Inf)` shows every row and column without changing stored preferences.
#' Previews control console printing, not HTML widgets or GUI viewers.
#'
#' **Working with previews**
#'
#' Settings follow supported base subsetting/replacement, dplyr row and column
#' operations, grouping (including rowwise operations), summaries and reframing,
#' and tidyr pivots. These operations determine the result's container and
#' grouping. Joins inherit the left input's settings; `bind_rows()` inherits the
#' first input's settings. Arbitrary third-party transformations and direct
#' `vctrs::vec_rbind()` are not covered by this guarantee.
#'
#' Converting with `tibble::as_tibble()` or `as.data.frame()`, or extracting a
#' column, removes the preview. Wrapping and unwrapping a data.table makes an
#' independent copy; subsequent native operations such as `:=` retain ordinary
#' reference semantics. Column classes and labels are preserved.
#'
#' @seealso [print_headtail()] for one-time printing.
#'
#' @examples
#' tb <- tibble::tibble(id = 1:30, value = (1:30)^2)
#' tb
#'
#' ht <- preview_headtail(tb)
#' ht
#'
#' dplyr::filter(ht, id > 10)
#'
#' preview_interval(ht, n = 5)
#'
#' unpreview(ht)
#'
#' @name preview
#' @family persistent preview functions
NULL

#' @rdname preview
#' @export
preview <- function(.data, style = c("headtail", "interval"), n = 10) {
  preview_check_data(.data)
  style <- rlang::arg_match(style)
  preview_check_n(n)
  out <- unpreview(.data)
  if (inherits(out, "data.table")) {
    data.table::setattr(out, "tidystata_preview", list(style = style, n = n))
    data.table::setattr(out, "class", c("tidystata_preview", class(out)))
  } else {
    attr(out, "tidystata_preview") <- list(style = style, n = n)
    class(out) <- c("tidystata_preview", class(out))
  }
  out
}

#' @rdname preview
#' @export
preview_headtail <- function(.data, n = 10) {
  preview(.data, style = "headtail", n = n)
}

#' @rdname preview
#' @export
preview_interval <- function(.data, n = 10) {
  preview(.data, style = "interval", n = n)
}

#' @rdname preview
#' @export
unpreview <- function(.data) {
  preview_check_data(.data)
  if (inherits(.data, "data.table")) {
    .data <- data.table::copy(.data)
    data.table::setattr(.data, "tidystata_preview", NULL)
    data.table::setattr(
      .data,
      "class",
      setdiff(class(.data), "tidystata_preview")
    )
  } else {
    attr(.data, "tidystata_preview") <- NULL
    class(.data) <- setdiff(class(.data), "tidystata_preview")
  }
  .data
}

preview_check_data <- function(x, call = rlang::caller_env()) {
  supported <- c(
    "tidystata_preview",
    "grouped_df",
    "rowwise_df",
    "sf",
    "tbl_df",
    "tbl",
    "data.table",
    "data.frame"
  )
  if (!is.data.frame(x) || !all(class(x) %in% supported)) {
    cli::cli_abort(
      c(
        "{.arg .data} must be an in-memory data frame, data.table, sf data frame, or ordinary/grouped/rowwise tibble.",
        i = "Collect lazy tables and convert other subclasses explicitly with {.fn tibble::as_tibble}; apply the wrapper to each table in a list."
      ),
      call = call
    )
  }
  if (inherits(x, "data.table")) {
    table_check_data_table(call)
  }
}

preview_check_n <- function(n, call = rlang::caller_env()) {
  if (
    !is.numeric(n) ||
      length(n) != 1L ||
      is.na(n) ||
      n <= 0 ||
      (is.finite(n) && n != floor(n))
  ) {
    cli::cli_abort(
      "{.arg n} must be a single positive whole number or {.code Inf}.",
      call = call
    )
  }
}

preview_rows <- function(size, n, style, call = rlang::caller_env()) {
  preview_check_n(n, call)
  if (size <= n) {
    return(seq_len(size))
  }
  if (n == 1) {
    return(1L)
  }
  if (style == "interval") {
    return(as.integer(round(seq(1, size, length.out = n))))
  }
  c(seq_len(ceiling(n / 2)), seq.int(size - floor(n / 2) + 1L, size))
}

preview_restore <- function(out, template) {
  if (is.data.frame(out)) {
    classes <- c("tidystata_preview", setdiff(class(out), "tidystata_preview"))
    settings <- attr(template, "tidystata_preview", exact = TRUE)
    if (inherits(out, "data.table")) {
      table_check_data_table()
      # Native := returns the original reference, which must remain an alias.
      if (
        identical(class(out), classes) &&
          identical(attr(out, "tidystata_preview", exact = TRUE), settings)
      ) {
        return(out)
      }
      out <- data.table::copy(out)
      data.table::setattr(out, "class", classes)
      data.table::setattr(out, "tidystata_preview", settings)
    } else {
      class(out) <- classes
      attr(out, "tidystata_preview") <- settings
    }
  }
  out
}

#' @export
format.tidystata_preview <- function(
  x,
  width = NULL,
  ...,
  n = NULL,
  max_extra_cols = NULL,
  max_footer_lines = NULL
) {
  settings <- attr(x, "tidystata_preview", exact = TRUE)
  if (is.null(n)) {
    n <- settings$n
  }
  rows <- preview_rows(nrow(x), n, settings$style)
  plain <- unpreview(x)
  view <- tibble::as_tibble(plain, .name_repair = "minimal")[
    rows,
    ,
    drop = FALSE
  ]
  attr(view, "preview_header") <- pillar::tbl_sum(plain)
  attr(view, "preview_rows") <- rows
  attr(view, "preview_omitted") <- nrow(x) - length(rows)
  attr(view, "preview_style") <- settings$style
  attr(view, "preview_gap_after") <- if (settings$style == "headtail") {
    which(diff(rows) > 1L)
  } else {
    integer()
  }
  class(view) <- c("tidystata_preview_view", class(view))
  format(
    view,
    width = width,
    ...,
    n = nrow(view),
    max_extra_cols = max_extra_cols,
    max_footer_lines = max_footer_lines
  )
}

#' @export
print.tidystata_preview <- function(
  x,
  width = NULL,
  ...,
  n = NULL,
  max_extra_cols = NULL,
  max_footer_lines = NULL
) {
  cat(
    format(
      x,
      width = width,
      ...,
      n = n,
      max_extra_cols = max_extra_cols,
      max_footer_lines = max_footer_lines
    ),
    sep = "\n"
  )
  invisible(x)
}

#' @exportS3Method pillar::tbl_sum
tbl_sum.tidystata_preview_view <- function(x, ...) {
  attr(x, "preview_header", exact = TRUE)
}

#' @exportS3Method pillar::ctl_new_rowid_pillar
ctl_new_rowid_pillar.tidystata_preview_view <- function(
  controller,
  x,
  width,
  ...
) {
  out <- NextMethod()
  if (is.null(out)) {
    return(NULL)
  }
  ids <- as.character(attr(controller, "preview_rows", exact = TRUE))
  id_width <- max(1L, nchar(ids))
  shaft <- pillar::new_pillar_shaft_simple(
    ids,
    width = id_width,
    align = "right"
  )
  pillar::new_pillar(
    list(
      title = out$title,
      type = out$type,
      data = preview_gap_component(
        pillar::pillar_component(shaft),
        attr(controller, "preview_gap_after", exact = TRUE)
      )
    ),
    width = id_width
  )
}

#' @exportS3Method pillar::ctl_new_pillar
ctl_new_pillar.tidystata_preview_view <- function(
  controller,
  x,
  width,
  ...,
  title = NULL
) {
  out <- NextMethod()
  if (!is.null(out)) {
    out$data <- preview_gap_component(
      out$data,
      attr(controller, "preview_gap_after", exact = TRUE)
    )
  }
  out
}

preview_gap_component <- function(component, after) {
  if (length(after) == 0L) {
    return(component)
  }
  content <- structure(
    list(shaft = component[[1L]], after = after),
    class = "tidystata_preview_gap"
  )
  pillar::new_pillar_component(
    list(content),
    width = attr(component, "width", exact = TRUE),
    min_width = attr(component, "min_width", exact = TRUE)
  )
}

#' @export
format.tidystata_preview_gap <- function(x, width, ...) {
  original <- format(x$shaft, width = width, ...)
  alignment <- attr(original, "align", exact = TRUE)
  if (is.null(alignment)) {
    alignment <- "left"
  }
  lines <- cli::ansi_align(as.character(original), width, align = alignment)
  marker <- if (cli::is_utf8_output()) "\u22ee" else "."
  marker <- cli::ansi_align(
    pillar::style_subtle(marker),
    width,
    align = "center"
  )
  pillar::new_ornament(
    append(lines, marker, after = x$after),
    width = width,
    align = alignment
  )
}

#' @exportS3Method pillar::tbl_format_footer
tbl_format_footer.tidystata_preview_view <- function(x, setup, ...) {
  footer <- NextMethod()
  if (setup$max_footer_lines == 0) {
    return(character())
  }
  omitted <- attr(x, "preview_omitted", exact = TRUE)
  if (omitted == 0L) {
    return(footer)
  }
  where <- if (length(attr(x, "preview_rows", exact = TRUE)) == 1L) {
    "after the displayed row"
  } else if (attr(x, "preview_style", exact = TRUE) == "headtail") {
    "in the middle"
  } else {
    "between displayed positions"
  }
  text <- paste0(
    "... ",
    format(omitted, big.mark = ",", scientific = FALSE, trim = TRUE),
    " rows omitted ",
    where,
    "; use print(x, n = Inf) to show all rows."
  )
  width <- if (is.finite(setup$width)) {
    max(10L, setup$width - 2L)
  } else {
    nchar(text) + 1L
  }
  omission <- pillar::style_subtle(paste0("# ", strwrap(text, width = width)))
  utils::head(c(omission, footer), setup$max_footer_lines)
}

#' Print selected rows once
#'
#' @description
#' Display selected rows in the console without storing print preferences.
#'
#' * `print_headtail()`: Print the first and last rows.
#' * `print_interval()`: Print evenly spaced rows.
#'
#' @inheritParams preview
#' @param width Console width passed to tibble formatting. `NULL` (default)
#'   uses the current console width; `Inf` shows every column.
#' @param ... Additional arguments passed to tibble formatting.
#' @param max_extra_cols,max_footer_lines Maximum number of additional columns
#'   to describe and footer lines to print, respectively. `NULL` uses tibble's
#'   defaults.
#'
#' @returns `.data`, unchanged and invisibly, including all rows, columns,
#'   classes, grouping, and any existing preview preferences.
#'
#' @details
#' Row budgets and omission markers follow [preview()]: head/tail output marks
#' an omitted middle with one row of dots; interval output has no separator
#' rows. Use `n = Inf` and `width = Inf` to print every row and column.
#'
#' @seealso [preview()] for persistent print preferences.
#'
#' @examples
#' print_headtail(lifeexp, n = 6)
#'
#' print_interval(lifeexp, n = 6)
#'
#' print_headtail(lifeexp, n = Inf, width = Inf)
#' @name special-print
#' @family one-time printing functions
NULL

#' @rdname special-print
#' @export
print_headtail <- function(
  .data,
  n = 10,
  width = NULL,
  ...,
  max_extra_cols = NULL,
  max_footer_lines = NULL
) {
  print(
    preview(.data, "headtail", n),
    width = width,
    ...,
    max_extra_cols = max_extra_cols,
    max_footer_lines = max_footer_lines
  )
  invisible(.data)
}

#' @rdname special-print
#' @export
print_interval <- function(
  .data,
  n = 10,
  width = NULL,
  ...,
  max_extra_cols = NULL,
  max_footer_lines = NULL
) {
  print(
    preview(.data, "interval", n),
    width = width,
    ...,
    max_extra_cols = max_extra_cols,
    max_footer_lines = max_footer_lines
  )
  invisible(.data)
}

#' @export
`[.tidystata_preview` <- function(x, ...) {
  preview_restore(NextMethod(), x)
}

#' @export
`[<-.tidystata_preview` <- function(x, ..., value) {
  preview_restore(NextMethod(), x)
}

#' @export
`[[<-.tidystata_preview` <- function(x, ..., value) {
  preview_restore(NextMethod(), x)
}

#' @export
`$<-.tidystata_preview` <- function(x, name, value) {
  preview_restore(NextMethod(), x)
}

#' @export
`names<-.tidystata_preview` <- function(x, value) {
  preview_restore(NextMethod(), x)
}

#' @exportS3Method tibble::as_tibble
as_tibble.tidystata_preview <- function(x, ...) {
  tibble::as_tibble(unpreview(x), ...)
}

#' @export
as.data.frame.tidystata_preview <- function(x, ...) {
  as.data.frame(unpreview(x), ...)
}

#' @exportS3Method dplyr::dplyr_reconstruct
dplyr_reconstruct.tidystata_preview <- function(data, template) {
  preview_restore(NextMethod(), template)
}

#' @exportS3Method dplyr::dplyr_row_slice
dplyr_row_slice.tidystata_preview <- function(data, i, ...) {
  preview_restore(NextMethod(), data)
}

#' @exportS3Method dplyr::dplyr_col_modify
dplyr_col_modify.tidystata_preview <- function(data, cols) {
  preview_restore(NextMethod(), data)
}

#' @exportS3Method dplyr::group_by
group_by.tidystata_preview <- function(.data, ...) {
  preview_restore(NextMethod(), .data)
}

#' @exportS3Method dplyr::ungroup
ungroup.tidystata_preview <- function(x, ...) {
  preview_restore(NextMethod(), x)
}

#' @exportS3Method dplyr::rowwise
rowwise.tidystata_preview <- function(data, ...) {
  preview_restore(NextMethod(), data)
}

#' @exportS3Method dplyr::summarise
summarise.tidystata_preview <- function(.data, ...) {
  preview_restore(NextMethod(), .data)
}

#' @exportS3Method dplyr::reframe
reframe.tidystata_preview <- function(.data, ...) {
  preview_restore(NextMethod(), .data)
}

#' @exportS3Method tidyr::pivot_longer
pivot_longer.tidystata_preview <- function(data, cols, ...) {
  # Inject the selector in its original environment instead of forwarding the
  # method's promise through NextMethod(), which can lose tidy selection scope.
  out <- tidyr::pivot_longer(unpreview(data), cols = {{ cols }}, ...)
  preview_restore(out, data)
}

#' @exportS3Method tidyr::pivot_wider
pivot_wider.tidystata_preview <- function(data, ...) {
  preview_restore(NextMethod(), data)
}
