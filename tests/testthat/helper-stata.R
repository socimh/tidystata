# Reference values produced by Stata from data-raw/stata-parity/*.do, stored
# as CSV in fixtures/stata (CI has no Stata). Empty cells are Stata's missing.
stata_fixture <- function(name) {
  utils::read.csv(
    test_path("fixtures", "stata", paste0(name, ".csv")),
    na.strings = "",
    encoding = "UTF-8",
    stringsAsFactors = FALSE
  )
}

# Numeric agreement to 1e-12, with missing matching missing (NA or NaN).
expect_stata_equal <- function(object, expected, label = NULL) {
  expect_identical(is.na(object), is.na(expected), label = label)
  ok <- !is.na(expected)
  expect_equal(object[ok], expected[ok], tolerance = 1e-12, label = label)
}
