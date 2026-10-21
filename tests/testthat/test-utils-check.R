test_that("checkers accept valid values invisibly", {
  expect_invisible(check_bool(TRUE))
  expect_invisible(check_bool(NULL, allow_null = TRUE))
  expect_invisible(check_string(""))
  expect_invisible(check_string("x", allow_empty = FALSE))
  expect_invisible(check_number_whole(3, min = 0, max = 3))
  expect_invisible(check_number_whole(Inf, allow_infinite = TRUE))
  expect_invisible(check_number_decimal(0.5, min = 0))
  expect_invisible(check_data_frame(data.frame()))
})

test_that("checkers name the argument and describe what was supplied", {
  flag <- NA
  expect_error(
    check_bool(flag),
    "`flag` must be `TRUE` or `FALSE`, not `NA`.",
    fixed = TRUE,
    class = "rlang_error"
  )
  expect_error(
    check_string(c("a", "b")),
    "must be a single string, not a character vector.",
    fixed = TRUE
  )
  expect_error(
    check_string("", allow_empty = FALSE),
    "must be a non-empty string",
    fixed = TRUE
  )
  expect_error(
    check_number_whole(1.5),
    "must be a whole number, not the number 1.5.",
    fixed = TRUE
  )
  expect_error(
    check_number_whole(-1, min = 0),
    "must be a whole number larger than or equal to 0, not the number -1.",
    fixed = TRUE
  )
  expect_error(
    check_number_whole(5, min = 1, max = 4),
    "must be a whole number between 1 and 4, not the number 5.",
    fixed = TRUE
  )
  expect_error(
    check_number_decimal(Inf, allow_infinite = FALSE),
    "must be a finite number",
    fixed = TRUE
  )
  expect_error(
    check_data_frame(1:3),
    "must be a data frame, not an integer vector.",
    fixed = TRUE
  )
})

test_that("checkers report the caller's call", {
  f <- function(n) check_number_whole(n)
  error <- tryCatch(f("a"), error = identity)
  expect_identical(error$call, quote(f("a")))
})
