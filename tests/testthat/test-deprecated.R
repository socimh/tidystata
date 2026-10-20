reset_deprecation_notices <- function() {
  shown <- deprecation_shown
  rm(list = ls(shown), envir = shown)
}

test_that("s_match() gives identical results with a single notice", {
  reset_deprecation_notices()
  withr::defer(reset_deprecation_notices())
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
})

test_that("earlier names are quiet aliases or current names", {
  reset_deprecation_notices()
  withr::defer(reset_deprecation_notices())
  data <- tibble::tibble(x1 = 1, x2 = 2, y = 3)
  cross <- tibble::tibble(a = c("p", "q"), b = c("u", "u"))
  expect_silent(cut_quantile(1:8, 2))
  expect_silent(s_try(stop("x")))
  expect_silent(names_as_column(data))
  expect_silent(tab2(cross, a, b))
  expect_silent(fre2(cross, a, b))
  expect_identical(
    fre2(cross, a, b, .flip = TRUE),
    tab2(cross, a, b, .flip = TRUE, .total = TRUE)
  )
})

test_that("varlist() is recognised as a selection inside computed selections", {
  data <- tibble::tibble(x1 = 1:2, x2 = 3:4, y = 5:6)
  expect_identical(
    names(s_select(data, varlist("x*"), z = y * 2)),
    c("x1", "x2", "z")
  )
})
