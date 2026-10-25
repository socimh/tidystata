test_that("assert() returns the data invisibly when conditions hold", {
  expect_invisible(out <- assert(lifeexp, lexp > 0, popgrowth < 10))
  expect_identical(out, lifeexp)
  grouped <- dplyr::group_by(lifeexp, region)
  expect_identical(assert(grouped, lexp > 0), grouped)
  # A single value is recycled, like mutate().
  expect_identical(assert(lifeexp, nrow(lifeexp) == 68), lifeexp)
  skip_if_not_installed("data.table")
  table <- data.table::as.data.table(lifeexp)
  expect_identical(assert(table, lexp > 0), table)
})

test_that("assert() counts contradictions like Stata", {
  data <- tibble::tibble(x = c(1, -1, NA, 5, -2, -3, -4, -5))
  error <- expect_error(assert(data, x > 0), "Assertion failed")
  message <- conditionMessage(error)
  expect_match(
    message,
    "`x > 0`: 6 contradictions (1 missing) in 8 rows",
    fixed = TRUE
  )
  expect_match(message, "rows 2, 3, 5, 6, 7, ...", fixed = TRUE)
  expect_error(assert(data[2, ], x > 0), "1 contradiction in 1 row; row 1")
  # Every failing condition is reported together.
  both <- expect_error(assert(data, x > 0, x < 3, is.na(x) | x > -10))
  expect_match(conditionMessage(both), "`x < 3`: 2 contradictions")
  expect_no_match(conditionMessage(both), "x > -10")
  expect_match(
    conditionMessage(both),
    "`x < 3`: 2 contradictions (1 missing)",
    fixed = TRUE
  )
  # Stata's treatment of missing values can be written explicitly.
  expect_error(assert(data, is.na(x) | x > -10), NA)
})

test_that("assert() evaluates group functions within groups", {
  panel <- tibble::tibble(id = c(1, 1, 2), year = c(2001, 2002, 2001))
  expect_error(
    assert(panel, dplyr::n_distinct(year) == dplyr::n(), .by = id),
    NA
  )
  expect_error(
    assert(panel, dplyr::n() == 1, .by = id),
    "2 contradictions in 3 rows; rows 1, 2"
  )
  expect_error(
    assert(dplyr::group_by(panel, id), dplyr::n() == 1),
    "rows 1, 2"
  )
})

test_that("assert() validates its input", {
  expect_error(assert(lifeexp), "at least one condition")
  expect_error(
    assert(lifeexp, lexp),
    "must give `TRUE` or `FALSE`, not a double vector"
  )
  expect_error(assert(1:3, TRUE), "must be a data frame")
})

test_that("assert() reports invalid input and failed conditions", {
  d <- tibble::tibble(x = c(1, -1, NA))
  expect_snapshot(error = TRUE, {
    assert(1:3, TRUE)
    assert(d)
    assert(d, x)
    assert(d, x > 0, !is.na(x))
  })
})

test_that("assert() never shadows input columns with internal result names", {
  data <- tibble::tibble(x = 1:2, ...assert1 = c(FALSE, FALSE))
  expect_error(assert(data, x > 0, ...assert1), "2 contradictions")
  expect_identical(data$...assert1, c(FALSE, FALSE))
  grouped <- dplyr::group_by(data, ...assert1)
  expect_error(assert(grouped, x > 0, ...assert1), "2 contradictions")
  ...assert1 <- FALSE
  expect_error(assert(data["x"], x > 0, ...assert1), "2 contradictions")
})

test_that("assert() requires one logical result per row", {
  data <- tibble::tibble(x = 1:2)
  expect_error(
    assert(data, cbind(x > 0, x < 2)),
    "logical vector"
  )
  expect_identical(assert(data, x > 0), data)
})
