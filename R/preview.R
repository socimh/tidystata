#' Persistent previews of complete tables
#'
#' @description
#' `preview_table()` keeps the complete data and remembers how to print it.
#' The default shows the first five and last five rows. Interval previews show
#' evenly spaced rows. `unpreview_table()` removes the preference.
#'
#' `print_headtail()` and `print_interval()` print once and invisibly return
#' the unchanged input. `print_all()` prints every row and every column, like
#' Stata's `list`, and also returns the input invisibly. `s_print()` does all
#' three through one `style` argument. `slice_headtail()` and
#' `slice_interval()` actually select rows, so use them only when a smaller
#' data set is wanted.
#'
#' @param .data An in-memory data frame, data.table, ordinary tibble, grouped
#' tibble, rowwise tibble, or `sf` data frame (geometry is kept when slicing and
#' printed as a column). Convert other subclasses explicitly before wrapping;
#' collect lazy tables first. Apply the wrapper separately to lists of tables.
#' @param style Either `"headtail"` or `"interval"`. `s_print()` also accepts
#' `"all"`, which prints every row and column like `print_all()`.
#' @param n Total number of rows to display or select: a positive whole number
#' or `Inf` for all rows. An odd head/tail budget gives the head the extra row.
#' With `n = 1`, both styles select the first row. Short tables never repeat rows.
#' @param width Console width, passed to tibble formatting. `NULL` uses the
#' current console width; `Inf` shows all columns.
#' @param ... Additional arguments passed to tibble formatting.
#' @param max_extra_cols,max_footer_lines Tibble formatting controls.
#'
#' @details
#' Preview settings survive table subsetting/replacement, dplyr mutation,
#' filtering, sorting, column selection, renaming, relocation, distinct rows,
#' slicing, grouping, rowwise operations, summaries and reframing, as well as
#' tidyr's `pivot_longer()` and `pivot_wider()`. Grouping follows the underlying
#' operation. Joins inherit the left input's settings; `bind_rows()` inherits
#' the first input's settings. Arbitrary third-party transformations and direct
#' `vctrs::vec_rbind()` are not covered by this guarantee.
#'
#' Positions shown in the margin refer to the current table, not the original
#' data before filtering or sorting. Previewing does not change column values,
#' classes, labels, or the data used in subsequent calculations. Grouped tables
#' use a global row budget, not a separate budget per group.
#'
#' `print(x, n = Inf)` displays the entire table. Per-call formatting overrides
#' do not change stored settings. Explicit `tibble::as_tibble()` or
#' `as.data.frame()` conversions remove the preview, as does extracting a column.
#' This feature controls console printing, not HTML widgets or GUI viewers.
#' Only the temporary display is converted to a tibble. Wrapping and unwrapping
#' a data.table creates an independent copy; native operations such as `:=`
#' on a wrapped data.table retain ordinary reference semantics. External
#' dplyr/tidyr verbs determine their own result container and grouping, while
#' preview settings follow the result.
#'
#' @returns `preview_table()` returns the complete input container with an additional
#' `tidystata_preview` class. `unpreview_table()` returns the table without that
#' class or its settings, preserving grouping. The print helpers invisibly
#' return their original input. The slice helpers return the selected rows in
#' the input container, retaining valid grouping and existing preview settings.
#' Explicit base data.frame row names are preserved. Slice helpers regenerate
#' automatic row names following dplyr's row-slicing behavior. Other subclasses
#' are unsupported.
#' @examples
#' x <- preview_table(tibble::tibble(id = 1:30, value = (1:30)^2))
#' x
#' dplyr::filter(x, id > 10)
#' preview_table(x, style = "interval", n = 5)
#' print(x, n = Inf)
#' unpreview_table(x)
#' print_headtail(mtcars, n = 6)
#' print_interval(mtcars, n = 6)
#' print_all(head(mtcars, 12))
#' s_print(mtcars, "interval", n = 6)
#' slice_headtail(mtcars, n = 6)
#' slice_interval(mtcars, n = 6)
#' @name special-print
#' @family selection and preview functions
NULL

#' @rdname special-print
#' @export
preview_table <- function(.data, style = c("headtail", "interval"), n = 10) {
  preview_check_data(.data)
  style <- rlang::arg_match(style)
  preview_check_n(n)
  out <- unpreview_table(.data)
  if (inherits(out, "data.table")) {
    data.table::setattr(out, "tidystata_preview", list(style = style, n = n))
    data.table::setattr(out, "class", c("tidystata_preview", class(out)))
  } else {
    attr(out, "tidystata_preview") <- list(style = style, n = n)
    class(out) <- c("tidystata_preview", class(out))
  }
  out
}

#' @rdname special-print
#' @export
unpreview_table <- function(.data) {
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
  plain <- unpreview_table(x)
  view <- tibble::as_tibble(plain, .name_repair = "minimal")[
    rows,
    ,
    drop = FALSE
  ]
  attr(view, "preview_header") <- pillar::tbl_sum(plain)
  attr(view, "preview_rows") <- rows
  attr(view, "preview_omitted") <- nrow(x) - length(rows)
  attr(view, "preview_style") <- settings$style
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
      data = pillar::pillar_component(shaft)
    ),
    width = id_width
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
    preview_table(.data, "headtail", n),
    width = width,
    ...,
    max_extra_cols = max_extra_cols,
    max_footer_lines = max_footer_lines
  )
  invisible(.data)
}

#' @rdname special-print
#' @export
s_print <- function(
  .data,
  style = c("headtail", "interval", "all"),
  n = 10,
  width = NULL,
  ...
) {
  style <- rlang::arg_match(style)
  switch(
    style,
    headtail = print_headtail(.data, n = n, width = width, ...),
    interval = print_interval(.data, n = n, width = width, ...),
    all = print_all(.data, ...)
  )
}

#' @rdname special-print
#' @export
print_all <- function(.data, ...) {
  print(preview_table(.data, "headtail", Inf), width = Inf, ...)
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
    preview_table(.data, "interval", n),
    width = width,
    ...,
    max_extra_cols = max_extra_cols,
    max_footer_lines = max_footer_lines
  )
  invisible(.data)
}

#' @rdname special-print
#' @export
slice_headtail <- function(.data, n = 10) {
  preview_slice(.data, n, "headtail")
}

#' @rdname special-print
#' @export
slice_interval <- function(.data, n = 10) {
  preview_slice(.data, n, "interval")
}

preview_slice <- function(.data, n, style, call = rlang::caller_env()) {
  preview_check_data(.data, call)
  rows <- preview_rows(nrow(.data), n, style, call)
  if (inherits(.data, "data.table")) {
    out <- unpreview_table(.data)[rows]
    if (inherits(.data, "tidystata_preview")) {
      out <- preview_restore(out, .data)
    }
    return(out)
  }
  dplyr::dplyr_row_slice(.data, rows)
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
  tibble::as_tibble(unpreview_table(x), ...)
}

#' @export
as.data.frame.tidystata_preview <- function(x, ...) {
  as.data.frame(unpreview_table(x), ...)
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
  out <- tidyr::pivot_longer(unpreview_table(data), cols = {{ cols }}, ...)
  preview_restore(out, data)
}

#' @exportS3Method tidyr::pivot_wider
pivot_wider.tidystata_preview <- function(data, ...) {
  preview_restore(NextMethod(), data)
}
