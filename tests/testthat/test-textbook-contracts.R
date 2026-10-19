test_that("cut_length rejects interval counts outside its integer contract", {
  invalid <- list(
    0,
    -1,
    1.5,
    NA_real_,
    NaN,
    Inf,
    -Inf,
    numeric(),
    c(2, 3),
    TRUE,
    "2",
    NULL,
    2 + 1i
  )
  for (n in invalid) {
    expect_error(
      cut_length(1:10, n = n),
      "`n` must be a single positive integer"
    )
  }
})

test_that("cut_length preserves valid intervals, labels and missing values", {
  x <- c(-4, -2, 0, 2, 4, NA_real_)
  expected <- ordered(
    c("low", "low", "low", "high", "high", NA),
    levels = c("low", "high")
  )
  expect_identical(cut_length(x, n = 2, labels = c("low", "high")), expected)
  expect_identical(
    cut_length(x, n = 2L, labels = FALSE),
    c(1L, 1L, 1L, 2L, 2L, NA_integer_)
  )
  expect_identical(
    cut_length(x, n = 1, labels = FALSE),
    c(1L, 1L, 1L, 1L, 1L, NA_integer_)
  )
})

test_that("s_match diagnoses noncharacter patterns without changing selections", {
  for (pattern in list(1, TRUE, NULL, list("x*"), factor("x*"))) {
    expect_error(
      s_match(pattern, vars = c("x1", "x2", "y")),
      "`string` must be a character string"
    )
  }
  expect_identical(s_match("x*", vars = c("x1", "x2", "y")), c(1L, 2L))
  expect_identical(s_match(NA_character_, vars = c("NA", "x")), 1L)
})

test_that("slicing retains explicit row names and regenerates automatic ones", {
  automatic <- data.frame(x = 1:8)
  explicit <- data.frame(x = 1:8, row.names = letters[1:8])
  expect_identical(
    rownames(slice_headtail(automatic, n = 4)),
    as.character(1:4)
  )
  expect_identical(
    rownames(slice_headtail(explicit, n = 4)),
    letters[c(1, 2, 7, 8)]
  )
  expect_identical(
    rownames(slice_interval(automatic, n = 3)),
    as.character(1:3)
  )
  expect_identical(
    rownames(slice_interval(explicit, n = 3)),
    letters[c(1, 4, 8)]
  )
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
  expect_error(preview_table(x), "Install.*data.table")
  expect_error(unpreview_table(x), "Install.*data.table")
  expect_error(slice_headtail(x), "Install.*data.table")
  expect_error(summ(x, x), "Install.*data.table")
  expect_error(
    table_restore(data.frame(x = 1), x),
    "Install.*data.table"
  )
})
