container_inputs <- function() {
  x <- data.frame(g = c("a", "a", "b"), x = c(1, 3, 5))
  out <- list(data.frame = x, tibble = tibble::as_tibble(x))
  if (requireNamespace("data.table", quietly = TRUE)) {
    out$data.table <- data.table::as.data.table(x)
  }
  out
}

container_class <- function(name) {
  switch(
    name,
    data.frame = "data.frame",
    tibble = c("tbl_df", "tbl", "data.frame"),
    data.table = c("data.table", "data.frame")
  )
}

test_that("vector summaries retain the caller expression after normalization", {
  observations <- c(1, 3, 5)
  expect_identical(summ(observations, .name = TRUE)$name, "observations")
  expect_identical(
    summ(observations, .mode = "table", .name = TRUE)$name,
    "observations"
  )
})

test_that("data.table preview assignment returns the native alias", {
  skip_if_not_installed("data.table")
  wrapped <- preview_table(data.table::data.table(x = 1:3))
  alias <- wrapped[, x := x + 1L]
  alias[, x := 99L]
  expect_identical(wrapped$x, rep(99L, 3))
})

test_that("empty cross-tabs cannot silently override explicit rich output", {
  expect_error(
    xtab(
      data.frame(x = 1),
      tidyselect::starts_with("absent"),
      .type = "flextable",
      .total = TRUE
    ),
    "requires two selected variables"
  )
})

test_that("table APIs preserve supported containers and usable values", {
  calls <- list(
    tab = function(x) tab(x, g),
    tab2 = function(x) xtab(x, g, x),
    fre = function(x) fre(x, g),
    fre2 = function(x) xtab(x, g, x, .total = TRUE),
    summ = function(x) summ(x, x),
    tabstat = function(x) tabstat(x, x),
    codebook = function(x) codebook(x),
    variables = function(x) variables(x),
    variables_search = function(x) variables_search(x, "g"),
    ds_as_column = function(x) ds_as_column(x),
    ds_as_column = function(x) ds_as_column(x)
  )
  for (kind in names(container_inputs())) {
    input <- container_inputs()[[kind]]
    for (name in names(calls)) {
      result <- calls[[name]](input)
      expect_identical(class(result), container_class(kind), info = name)
      expect_gt(nrow(result), 0L)
    }
    counts <- tab(input, g) |> dplyr::filter(g == "a")
    expect_equal(counts$n, 2)
    expect_equal(summ(input, x)$mean, 3)
  }
})

test_that("list members preserve containers and explicit output wins", {
  for (kind in names(container_inputs())) {
    input <- container_inputs()[[kind]]
    input$day <- as.Date("2024-01-01") + 0:2
    outputs <- list(tab1(input, g), fre1(input, g), summ(input, x, day))
    for (output in outputs) {
      expect_type(output, "list")
      expect_false(is.data.frame(output))
      for (element in output) {
        expect_identical(class(element), container_class(kind))
      }
    }
    expect_s3_class(tab1(input, g, .type = "tibble"), "tbl_df")
    expect_s3_class(fre1(input, g, .type = "tibble"), "tbl_df")
    expect_s3_class(fre(input, g, .type = "tibble"), "tbl_df")
    expect_s3_class(
      xtab(input, g, x, .type = "tibble", .total = TRUE),
      "tbl_df"
    )
    expect_identical(
      class(summ(input, x, .mode = "table")),
      container_class(kind)
    )
  }
})

test_that("empty branches preserve containers", {
  for (kind in names(container_inputs())) {
    input <- container_inputs()[[kind]]
    outputs <- list(
      tab(input, tidyselect::starts_with("absent")),
      fre(input, tidyselect::starts_with("absent")),
      xtab(input, tidyselect::starts_with("absent")),
      xtab(input, tidyselect::starts_with("absent"), .total = TRUE),
      codebook(input, tidyselect::starts_with("absent")),
      ds_as_column(input, tidyselect::starts_with("absent")),
      variables_search(input, "absent")
    )
    for (output in outputs) {
      expect_identical(class(output), container_class(kind))
      expect_equal(nrow(output), 0L)
    }
  }
})

test_that("previews and slices preserve data frames and row names", {
  input <- data.frame(x = 1:6, row.names = letters[1:6])
  wrapped <- preview_table(input, n = 2)
  expect_identical(class(wrapped), c("statart_preview", "data.frame"))
  expect_identical(unpreview_table(wrapped), input)
  expect_identical(slice_headtail(input, n = 2), input[c(1, 6), , drop = FALSE])
  expect_identical(
    slice_interval(input, n = 3),
    input[c(1, 4, 6), , drop = FALSE]
  )
  expect_output(print(wrapped), "rows omitted")
  expect_identical(
    unpreview_table(dplyr::filter(wrapped, x > 3)),
    input[4:6, , drop = FALSE]
  )
})

test_that("data.table previews preserve native expressions and isolate inputs", {
  skip_if_not_installed("data.table")
  input <- data.table::data.table(g = c("a", "a", "b"), x = c(1, 3, 5))
  data.table::setkeyv(input, "g")
  before <- data.table::copy(input)
  wrapped <- preview_table(input)
  expect_identical(
    class(wrapped),
    c("statart_preview", "data.table", "data.frame")
  )
  threshold <- 1
  expect_equal(wrapped[x > threshold, sum(x)], 8)
  expect_equal(wrapped[, list(total = sum(x)), by = g]$total, c(4, 5))
  expect_equal(wrapped[, .SD, .SDcols = "x"]$x, c(1, 3, 5))
  wrapped[, x := x * 2]
  expect_equal(wrapped$x, c(2, 6, 10))
  expect_identical(input, before)
  plain <- unpreview_table(wrapped)
  expect_false(inherits(plain, "statart_preview"))
  expect_true(inherits(wrapped, "statart_preview"))
  expect_identical(data.table::key(plain), "g")
  expect_identical(
    class(slice_headtail(input, n = 2)),
    c("data.table", "data.frame")
  )
  expect_null(data.table::key(summ(input, x)))
})
