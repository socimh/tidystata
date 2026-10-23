# duplicates_tag() and duplicates_report() against Stata's `duplicates tag`
# (data-raw/stata-parity/duplicates.do).
reference <- stata_fixture("duplicates-tag")
keys <- reference[c("a", "b")]

test_that("duplicates_tag() matches duplicates tag, with missing values equal", {
  expect_identical(duplicates_tag(keys)$dup, as.integer(reference$dup))
  expect_identical(duplicates_tag(keys, a)$dup, as.integer(reference$dup_a))
})

test_that("duplicates_report() matches duplicates report", {
  # Stata: copies 1, 2, 3 with 3, 2 and 3 observations and 0, 1, 2 surplus.
  report <- duplicates_report(keys)
  expect_equal(report$copies, c(1, 2, 3))
  expect_equal(report$observations, c(3, 2, 3))
  expect_equal(report$surplus, c(0, 1, 2))
})
