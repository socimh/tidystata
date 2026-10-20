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

test_that("aliases are exported and identical to their primary functions", {
  same <- list(
    xtab = "tab2",
    cut_quantile = "xtile",
    s_try = "capture",
    names_as_column = "ds_as_column",
    pct = "pc",
    s_tag = "is_first",
    tab_gen = "as_dummy",
    var_type = "s_type",
    var_unit = "s_unit"
  )
  exports <- getNamespaceExports("statart")
  for (alias in names(same)) {
    expect_true(alias %in% exports, info = alias)
    expect_identical(
      getExportedValue("statart", alias),
      getExportedValue("statart", same[[alias]]),
      info = alias
    )
  }
  expect_false(any(c("search", "describe", "lookfor") %in% exports))
})

test_that("wrapper aliases give the same results as their primary functions", {
  x <- c(1, -98, -99, NA)
  expect_identical(na_if_value(x, -99), mvdecode(x, -99))
  expect_identical(value_if_na(x, 0), mvencode(x, 0))
  labelled <- haven::labelled(c(1, 2, NA), c(Low = 1, High = 2))
  expect_identical(destring(c("1,000", "2.5")), as_numeric(c("1,000", "2.5")))
  expect_identical(decode(labelled), as_character(labelled))
  data <- tibble::tibble(a = 1, b = 2)
  expect_identical(ds(data, .type = "table"), ds_as_column(data))
  expect_identical(ds(data, b, .type = "table"), names_as_column(data, b))
  expect_identical(ds(data, .type = "vector"), ds(data))
  rows <- list(c(1, 1, NA), c(2, 1, NA), c(NA, 1, 3))
  expect_identical(
    row_nvals(rows[[1]], rows[[2]], rows[[3]], .missing = TRUE),
    row_unique(rows[[1]], rows[[2]], rows[[3]])
  )
})
