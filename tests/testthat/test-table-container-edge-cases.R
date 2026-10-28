edge_containers <- function(x) {
  out <- list(frame = x, tibble = tibble::as_tibble(x))
  if (requireNamespace("data.table", quietly = TRUE)) {
    out$table <- data.table::as.data.table(x)
  }
  out
}

test_that("grouped summaries and inventories drop obsolete grouping", {
  input <- tibble::tibble(g = c("a", "a", "b"), x = c(1, 3, 5))
  for (grouped in list(dplyr::group_by(input, g), dplyr::rowwise(input, g))) {
    before <- grouped
    summary <- summ(grouped, x)
    expect_identical(class(summary), c("tbl_df", "tbl", "data.frame"))
    if (inherits(grouped, "rowwise_df")) {
      expect_false("g" %in% names(summary))
      expect_equal(summary$mean, 3)
    } else {
      expect_equal(summary$g, c("a", "b"))
      expect_equal(summary$mean, c(2, 5))
    }
    inventory <- suppressMessages(variables(grouped, x))
    expect_identical(class(inventory), c("tbl_df", "tbl", "data.frame"))
    expect_equal(inventory$name, c("g", "x"))
    book <- codebook(grouped, x)
    expect_identical(class(book), c("tbl_df", "tbl", "data.frame"))
    expect_equal(book$variable, "x")
    expect_equal(book$n, 3)
    expect_identical(grouped, before)
  }
})

test_that("empty and missing labelled inputs retain containers and counts", {
  skip_if_not_installed("haven")
  fixture <- data.frame(
    x = haven::labelled(c(NA_real_, NA_real_), c(yes = 1), label = "Answer")
  )
  for (input in edge_containers(fixture)) {
    before <- if (inherits(input, "data.table")) {
      data.table::copy(input)
    } else {
      input
    }
    counts <- tab(input, x)
    expect_identical(class(counts), class(input))
    expect_equal(counts$n, 2)
    expect_true(all(is.na(counts$valid)))
    book <- codebook(input, x)
    expect_identical(class(book), class(input))
    expect_equal(book$n, 0)
    expect_equal(variables(input)$label, "Answer")
    empty <- input[0, , drop = FALSE]
    expect_message(empty_summary <- summ(empty, x), "labelled variable")
    for (result in list(tab(empty, x), empty_summary, codebook(empty))) {
      expect_identical(class(result), class(input))
    }
    expect_equal(sum(tab(empty, x)$n), 0)
    expect_equal(codebook(empty)$n, 0)
    expect_identical(input, before)
  }
})

test_that("own table results and list children preserve preview settings", {
  fixture <- data.frame(g = c("a", "a", "b"), x = c(1, 3, 5))
  fixture$day <- as.Date("2024-01-01") + 0:2
  for (input in edge_containers(fixture)) {
    wrapped <- preview(input, style = "interval", n = 2)
    settings <- attr(wrapped, "tidystata_preview")
    results <- c(
      list(
        tab(wrapped, g),
        fre(wrapped, g),
        summ(wrapped, x),
        codebook(wrapped),
        variables(wrapped)
      ),
      tab1(wrapped, g),
      fre1(wrapped, g),
      summ(wrapped, x, day)
    )
    for (result in results) {
      expect_identical(class(result), c("tidystata_preview", class(input)))
      expect_identical(attr(result, "tidystata_preview"), settings)
    }
    expect_equal(summ(wrapped, x)$mean, 3)
    for (result in list(
      tab1(wrapped, tidyselect::starts_with("absent"), .type = "tibble"),
      fre1(wrapped, tidyselect::starts_with("absent"), .type = "tibble"),
      tab1(input, tidyselect::starts_with("absent"), .type = "tibble"),
      fre1(input, tidyselect::starts_with("absent"), .type = "tibble"),
      fre(wrapped, g, .type = "tibble"),
      tab2(wrapped, g, x, .type = "tibble", .total = TRUE),
      tab1(wrapped, g, .type = "tibble"),
      fre1(wrapped, g, .type = "tibble")
    )) {
      expect_identical(class(result), c("tbl_df", "tbl", "data.frame"))
      expect_null(attr(result, "tidystata_preview"))
    }
    expect_identical(unpreview(wrapped), input)
  }
})

test_that("data.table preview NSE and reference operations remain native", {
  skip_if_not_installed("data.table")
  input <- data.table::data.table(g = c("a", "a", "b"), x = c(1, 3, 5))
  before <- data.table::copy(input)
  wrapped <- preview(input)
  columns <- "x"
  expect_equal(wrapped[, ..columns]$x, c(1, 3, 5))
  local_sum <- function(tbl, cutoff) tbl[x > cutoff, sum(x)]
  expect_equal(local_sum(wrapped, 2), 8)
  expect_equal(
    wrapped[, lapply(.SD, sum), by = g, .SDcols = columns]$x,
    c(4, 5)
  )
  no_columns <- wrapped[, character(), with = FALSE]
  expect_equal(ncol(no_columns), 0L)
  expect_s3_class(no_columns, "data.table")
  alias <- wrapped
  wrapped[, x := x + 10]
  expect_equal(alias$x, c(11, 13, 15))
  expect_identical(input, before)
  plain <- unpreview(wrapped)
  plain[, x := 0]
  expect_equal(wrapped$x, c(11, 13, 15))
  expect_null(attr(plain, "tidystata_preview"))
  expect_s3_class(wrapped, "tidystata_preview")
})

test_that("downstream joins and pivots retain upstream container semantics", {
  skip_if_not_installed("tidyr")
  fixture <- data.frame(g = c("a", "a", "b"), x = c(1, 3, 5))
  lookup <- data.frame(g = c("a", "b"), label = c("First", "Second"))
  for (input in edge_containers(fixture)) {
    counts <- tab(input, g)
    pipeline <- counts |>
      dplyr::select(g, n) |>
      dplyr::mutate(twice = n * 2) |>
      dplyr::left_join(lookup, by = "g")
    expect_equal(pipeline$twice, c(4, 2))
    expect_equal(pipeline$label, c("First", "Second"))
    wrapped <- preview(counts, n = 1)
    joined <- dplyr::left_join(wrapped, lookup, by = "g")
    expect_identical(
      class(unpreview(joined)),
      class(dplyr::left_join(counts, lookup, by = "g"))
    )
    pivoted <- tidyr::pivot_longer(wrapped, c(n, percent))
    ordinary <- tidyr::pivot_longer(counts, c(n, percent))
    expect_identical(unpreview(pivoted), ordinary)
    expect_identical(
      attr(pivoted, "tidystata_preview"),
      attr(wrapped, "tidystata_preview")
    )
  }
})
