#' Print a long tibble with selected rows
#'
#' @description
#' * `print_headtail()` - Print the head and tail rows of the data.
#' * `print_interval()` - Print the selected rows with (almost) equal intervals.
#' * `slice_headtail()` - Return the head and tail rows of the data.
#' * `slice_interval()` - Return the selected rows with (almost) equal intervals.
#'
#' @param .data A data frame, data frame extension
#' (e.g. a tibble), or a lazy data frame (e.g. from dbplyr or dtplyr).
#' @param n A positive integer. The number of rows to show in
#' the head and in the tail.
#' @param width A positive integer. The width of the printed tibble.
#' @inheritParams tibble::print.tbl
#'
#' @return Print the selected rows of the data.
#' Return the input data frame invisibly.
#'
#' @name special-print
#' @examples
#' print_headtail(starwars)
#'
#' print_interval(starwars)
#'
#' slice_headtail(starwars)
#'
#' slice_interval(starwars)

#' @rdname special-print
#' @export
print_headtail <- function(
    .data,
    n = 10, width = NULL,
    ...,
    max_extra_cols = NULL,
    max_footer_lines = NULL) {
  s_print(
    .data, n, width, ...,
    interval = FALSE,
    max_extra_cols = max_extra_cols,
    max_footer_lines = max_footer_lines
  )
}

#' @rdname special-print
#' @export
print_interval <- function(
    .data,
    n = 10, width = NULL,
    ...,
    max_extra_cols = NULL,
    max_footer_lines = NULL) {
  s_print(
    .data, n, width, ...,
    interval = TRUE,
    max_extra_cols = max_extra_cols,
    max_footer_lines = max_footer_lines
  )
}

#' @rdname special-print
#' @export
slice_headtail <- function(.data, n = 10) {
  check_positive_int(n)
  m <- n %/% 2
  n <- n - m
  .data %>%
    tibble::as_tibble() %>%
    head(m) %>%
    dplyr::bind_rows(
      .data %>%
        tail(n)
    ) %>%
    return()
}

#' @rdname special-print
#' @export
slice_interval <- function(.data, n = 10) {
  check_positive_int(n)
  rows <- seq(1, nrow(.data), length.out = n) %>%
    round()
  .data %>%
    tibble::as_tibble() %>%
    dplyr::slice(rows) %>%
    return()
}

# Helper function:
check_positive_int <- function(x) {
  not_positive_int <- !is.numeric(x) || any(x <= 0) || any(!x %% 1 == 0)
  if (not_positive_int && !is.null(x)) {
    stop(paste(x, "must be a positive integer"))
  }
}

head_tail_tbl <- function(.data, class, m, n) {
  vctrs::new_data_frame(
    dplyr::bind_rows(
      .data %>% head(m),
      .data %>% tail(n)
    ),
    nrow = nrow(.data),
    rows = c(
      seq_len(m),
      seq(nrow(.data) - n + 1, nrow(.data))
    ),
    class = c(class, "tbl_df", "tbl")
  )
}

#' @importFrom pillar tbl_sum
#' @export
tbl_sum.head_tail <- function(x) {
  c("A tibble" = paste0(
    attr(x, "nrow") %>%
      format(big.mark = ",", scientific = FALSE, trim = TRUE),
    " \u00d7 ",
    ncol(x)
  ))
}

# Helpers
s_print <- function(
    .data,
    n = 10, width = NULL,
    ...,
    interval = FALSE,
    max_extra_cols = NULL,
    max_footer_lines = NULL) {
  check_positive_int(n)
  check_positive_int(width)

  tb <- tibble::as_tibble(.data)

  print_max <- max(n + 1, 20)

  if (nrow(tb) <= print_max) {
    print(tb, n = nrow(tb), width = width)
  } else if (!interval) {
    m <- n %/% 2
    n <- n - m
    tb <- head_tail_tbl(tb, "head_tail", m, n)
    tb %>%
      print(n = m + n + 1, width = width)
  } else {
    rows <- seq(1, nrow(.data), length.out = n) %>%
      round()
    tb <- interval_tbl(tb, "interval", rows)
    tb %>%
      print(n = n + 1, width = width, ...)
  }

  return(invisible(.data))
}


#' @importFrom pillar ctl_new_rowid_pillar
#' @export
ctl_new_rowid_pillar.head_tail <- function(controller, x, width, ...) {
  out <- NextMethod()
  rowid <- attr(controller, "rows")
  width <- max(nchar(as.character(rowid)))
  list(
    title = out$title,
    type = out$type,
    data = pillar::new_pillar_shaft(
      list(row_ids = rowid),
      width = width,
      class = "pillar_rif_shaft"
    ) %>%
      pillar::pillar_component()
  ) %>%
    pillar::new_pillar(width = width)
}

#' @importFrom pillar tbl_format_footer
#' @export
tbl_format_footer.head_tail <- function(x, ...) {
  default_footer <- NextMethod()

  exclamation <- "\u2139"
  hidden_rows <- attr(x, "nrow") - length(attr(x, "rows"))
  rows_footer <- paste0(
    "# ", exclamation, " ",
    hidden_rows %>%
      format(big.mark = ",", scientific = FALSE, trim = TRUE),
    " more rows in the middle"
  ) %>%
    pillar::style_subtle()
  tip_footer <- paste0(
    "# ", exclamation, " Use `print_headtail(n = ...)` to see more rows"
  ) %>%
    pillar::style_subtle()

  c(rows_footer, default_footer, tip_footer)
}

# Print with fixed intervals
interval_tbl <- function(.data, class, rows) {
  vctrs::new_data_frame(
    .data %>%
      dplyr::slice(rows),
    nrow = nrow(.data),
    rows = rows,
    class = c(class, "tbl_df", "tbl")
  )
}

#' @importFrom pillar tbl_sum
#' @export
tbl_sum.interval <- function(x) {
  c("A tibble" = paste0(
    attr(x, "nrow") %>%
      format(big.mark = ",", scientific = FALSE, trim = TRUE),
    " \u00d7 ",
    ncol(x)
  ))
}

#' @importFrom pillar ctl_new_rowid_pillar
#' @export
ctl_new_rowid_pillar.interval <- function(controller, x, width, ...) {
  out <- NextMethod()
  rowid <- attr(controller, "rows")
  width <- max(nchar(as.character(rowid)))
  list(
    title = out$title,
    type = out$type,
    data = pillar::new_pillar_shaft(
      list(row_ids = rowid),
      width = width,
      class = "pillar_rif_shaft"
    ) %>%
      pillar::pillar_component()
  ) %>%
    pillar::new_pillar(width = width)
}

#' @importFrom pillar tbl_format_footer
#' @export
tbl_format_footer.interval <- function(x, ...) {
  default_footer <- NextMethod()

  exclamation <- "\u2139"
  hidden_rows <- attr(x, "nrow") - length(attr(x, "rows"))
  rows_footer <- paste0(
    "# ", exclamation, " ",
    hidden_rows %>%
      format(big.mark = ",", scientific = FALSE, trim = TRUE),
    " more rows between the intervals"
  ) %>%
    pillar::style_subtle()
  tip_footer <- paste0(
    "# ", exclamation, " Use `print_interval(n = ...)` to see more rows"
  ) %>%
    pillar::style_subtle()

  c(rows_footer, default_footer, tip_footer)
}
