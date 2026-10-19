test_that("s_match expands numeric ranges in every pattern position", {
  vars <- c("x1", "x2", "x3", "y", "z", "prefix_x1", "x2_tail", "X1")
  expect_no_warning(
    first <- s_match("x[1-2] y", vars = vars)
  )
  expect_identical(first, c(1L, 2L, 4L, 8L))
  expect_identical(s_match("y x[1-2]", vars = vars), c(1L, 2L, 4L, 8L))
  expect_identical(s_match("y x[1-2] z", vars = vars), c(1L, 2L, 4L, 5L, 8L))
})

test_that("s_match anchors complete expanded alternatives", {
  vars <- c("x1", "x12", "x120", "y", "prefix_x1", "x12_tail", "y_tail")
  expect_identical(s_match("x[1-12] y", vars = vars), c(1L, 2L, 4L))
  expect_identical(s_match("y x[1-12]", vars = vars), c(1L, 2L, 4L))
  expect_identical(s_match("x[1-12]", vars = vars), c(1L, 2L))
})

test_that("s_match composes ranged patterns with tidyselect exclusions", {
  data <- tibble::tibble(x1 = 1, x2 = 2, y = 3, x2_tail = 4, X1 = 5)
  expect_identical(ds(data, s_match("x[1-2] y")), c("x1", "x2", "y", "X1"))
  expect_identical(ds(data, -s_match("y x[1-2]")), "x2_tail")
  expect_identical(
    ds(data, s_match("y x[1-2]", ignore.case = FALSE)),
    c("x1", "x2", "y")
  )
})

test_that("s_match supports separate ranged tokens without broadening a token", {
  vars <- c("x1", "x2", "y1", "y2", "prefix_x1", "y2_tail")
  expect_identical(s_match("x[1-2] y[1-2]", vars = vars), 1:4)
  expect_identical(
    s_match("y[a-b] x[1-2]", vars = c(vars, "ya", "yb")),
    c(1L, 2L, 7L, 8L)
  )
  expect_error(s_match("x[1-2][3-4] y", vars = vars), "Only one range")
  expect_error(s_match("y x[2-1]", vars = vars), "smaller number")
  expect_identical(s_match(NA_character_, vars = c("NA", "x")), 1L)
})
