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
    summ(observations, .type = "table", .name = TRUE)$name,
    "observations"
  )
})

test_that("data.table preview assignment returns the native alias", {
  skip_if_not_installed("data.table")
  wrapped <- preview(data.table::data.table(x = 1:3))
  alias <- wrapped[, x := x + 1L]
  alias[, x := 99L]
  expect_identical(wrapped$x, rep(99L, 3))
})

test_that("empty cross-tabs cannot silently override explicit rich output", {
  expect_error(
    tab2(
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
    tab2 = function(x) tab2(x, g, x),
    fre = function(x) fre(x, g),
    fre2 = function(x) tab2(x, g, x, .total = TRUE),
    summ = function(x) summ(x, x),
    tabstat = function(x) tabstat(x, x),
    codebook = function(x) codebook(x),
    variables = function(x) variables(x),
    variables_search = function(x) variables_search(x, "g"),
    ds_table = function(x) ds(x, .type = "table")
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
      tab2(input, g, x, .type = "tibble", .total = TRUE),
      "tbl_df"
    )
    expect_identical(
      class(summ(input, x, .type = "table")),
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
      tab2(input, tidyselect::starts_with("absent")),
      tab2(input, tidyselect::starts_with("absent"), .total = TRUE),
      codebook(input, tidyselect::starts_with("absent")),
      ds(input, tidyselect::starts_with("absent"), .type = "table"),
      variables_search(input, "absent")
    )
    for (output in outputs) {
      expect_identical(class(output), container_class(kind))
      expect_equal(nrow(output), 0L)
    }
  }
})

test_that("previews preserve data frames and row names", {
  input <- data.frame(x = 1:6, row.names = letters[1:6])
  wrapped <- preview(input, n = 2)
  expect_identical(class(wrapped), c("tidystata_preview", "data.frame"))
  expect_identical(unpreview(wrapped), input)
  expect_output(print(wrapped), "rows omitted")
  expect_identical(
    unpreview(dplyr::filter(wrapped, x > 3)),
    input[4:6, , drop = FALSE]
  )
})

test_that("data.table previews preserve native expressions and isolate inputs", {
  skip_if_not_installed("data.table")
  input <- data.table::data.table(g = c("a", "a", "b"), x = c(1, 3, 5))
  data.table::setkeyv(input, "g")
  before <- data.table::copy(input)
  wrapped <- preview(input)
  expect_identical(
    class(wrapped),
    c("tidystata_preview", "data.table", "data.frame")
  )
  threshold <- 1
  expect_equal(wrapped[x > threshold, sum(x)], 8)
  expect_equal(wrapped[, list(total = sum(x)), by = g]$total, c(4, 5))
  expect_equal(wrapped[, .SD, .SDcols = "x"]$x, c(1, 3, 5))
  wrapped[, x := x * 2]
  expect_equal(wrapped$x, c(2, 6, 10))
  expect_identical(input, before)
  plain <- unpreview(wrapped)
  expect_false(inherits(plain, "tidystata_preview"))
  expect_true(inherits(wrapped, "tidystata_preview"))
  expect_identical(data.table::key(plain), "g")
  expect_null(data.table::key(summ(input, x)))
})

test_that("serialized data.table inputs explain the missing optional dependency", {
  x <- structure(data.frame(x = 1:8), class = c("data.table", "data.frame"))
  require_namespace <- base::requireNamespace
  testthat::local_mocked_bindings(
    requireNamespace = function(package, ...) {
      if (identical(package, "data.table")) {
        FALSE
      } else {
        require_namespace(package, ...)
      }
    },
    .package = "base"
  )
  expect_error(preview(x), "Install.*data.table")
  expect_error(unpreview(x), "Install.*data.table")
  expect_error(summ(x, x), "Install.*data.table")
  expect_error(
    table_restore(data.frame(x = 1), x),
    "Install.*data.table"
  )
})

test_that("ds tibble output overrides containers and keeps selected names", {
  for (input in container_inputs()) {
    wrapped <- preview(input, n = 1)
    out <- ds(wrapped, renamed = x, g, .type = "tibble")
    expect_identical(out, tibble::tibble(name = c("renamed", "g")))
    empty <- ds(wrapped, tidyselect::starts_with("absent"), .type = "tibble")
    expect_identical(empty, tibble::tibble(name = character()))
    expect_identical(unpreview(wrapped), input)
  }
  expect_identical(
    ds(c("x", "y"), renamed = y, .type = "tibble"),
    tibble::tibble(name = "renamed")
  )
  expect_identical(
    ds(character(), .type = "tibble"),
    tibble::tibble(name = character())
  )
})

test_that("summary tibble output combines families and overrides previews", {
  expected <- tibble::tibble(
    name = c("x", "day"),
    type = c("dbl", "date [days]"),
    n = c(3L, 3L),
    sd = c(2, 1)
  )
  for (input in container_inputs()) {
    input$day <- as.Date("2024-01-01") + 0:2
    wrapped <- preview(input, n = 1)
    for (fn in list(summ, tabstat)) {
      out <- fn(wrapped, x, day, .type = "tibble", .stat = c("n", "sd"))
      expect_identical(out, expected)
      expect_identical(unpreview(wrapped), input)
    }
  }
})

test_that("summary tibble output retains groups, vector names and empty schemas", {
  input <- tibble::tibble(g = c("a", "a", "b"), x = c(1, NA, 5))
  observations <- c(1, 3, NA)
  for (fn in list(summ, tabstat)) {
    grouped <- fn(
      dplyr::group_by(input, g),
      x,
      .type = "tibble",
      .stat = c("n", "mean")
    )
    expect_identical(class(grouped), c("tbl_df", "tbl", "data.frame"))
    expect_identical(grouped$g, c("a", "b"))
    expect_identical(grouped$n, c(1L, 1L))
    expect_equal(grouped$mean, c(1, 5))
    vector <- fn(
      observations,
      .type = "tibble",
      .stat = c("n", "mean"),
      .name = TRUE
    )
    expect_identical(vector$name, "observations")
    expect_identical(vector$n, 2L)
    expect_equal(vector$mean, 2)
    expect_identical(class(vector), c("tbl_df", "tbl", "data.frame"))
    empty <- fn(
      data.frame(x = numeric()),
      x,
      .type = "tibble",
      .stat = c("n", "mean"),
      .drop_empty = TRUE
    )
    expect_identical(
      empty,
      tibble::tibble(type = character(), n = integer(), mean = double())
    )
    expect_error(fn(input, x, .type = "tib"), "[.]type")
  }
  expect_error(ds(input, .type = "tib"), "[.]type")
})
