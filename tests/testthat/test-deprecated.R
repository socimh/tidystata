reset_deprecation_notices <- function() {
  shown <- deprecation_shown
  rm(list = ls(shown), envir = shown)
}

test_that("renamed functions give identical results with a single notice", {
  reset_deprecation_notices()
  withr::defer(reset_deprecation_notices())
  expect_message(
    old <- cut_quantile(1:8, 2),
    "renamed to `xtile()`",
    fixed = TRUE
  )
  expect_identical(old, xtile(1:8, 2))
  expect_silent(cut_quantile(1:8, 2))

  expect_message(
    old <- s_try(stop("x")),
    "renamed to `capture()`",
    fixed = TRUE
  )
  expect_identical(old, capture(stop("x")))

  data <- tibble::tibble(x1 = 1, x2 = 2, y = 3)
  expect_message(
    old <- ds(data, s_match("x*")),
    "renamed to `varlist()`",
    fixed = TRUE
  )
  expect_identical(old, ds(data, varlist("x*")))
  expect_identical(
    s_match("x?", vars = names(data)),
    varlist("x?", vars = names(data))
  )

  expect_message(
    old <- names_as_column(data),
    "renamed to `ds_as_column()`",
    fixed = TRUE
  )
  expect_identical(old, ds_as_column(data))

  cross <- tibble::tibble(a = c("p", "q"), b = c("u", "u"))
  expect_message(old <- tab2(cross, a, b), "renamed to `xtab()`", fixed = TRUE)
  expect_identical(old, xtab(cross, a, b))
  expect_message(
    old <- fre2(cross, a, b, .flip = TRUE),
    "renamed to `xtab(.total = TRUE)`",
    fixed = TRUE
  )
  expect_identical(old, xtab(cross, a, b, .flip = TRUE, .total = TRUE))
})

test_that("varlist() is recognised as a selection inside computed selections", {
  data <- tibble::tibble(x1 = 1:2, x2 = 3:4, y = 5:6)
  expect_identical(
    names(s_select(data, varlist("x*"), z = y * 2)),
    c("x1", "x2", "z")
  )
})
