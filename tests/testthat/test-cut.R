# Comprehensive Test Suite for cut_* Functions
# Cut numeric vectors into intervals: xtile, cut_length, cut_breaks

# CHALLENGE: Comprehensive testing for xtile, cut_length, cut_breaks
# FUNCTIONS: xtile, cut_length, cut_breaks
# KEY BEHAVIORS: interval creation, numeric binning
# EDGE CASES: boundary values, duplicate breaks

# Record and assert every expected warning, including min/max warning pairs.
cut_test_warnings <- function(code) {
  messages <- character()
  withCallingHandlers(force(code), warning = function(condition) {
    messages <<- c(messages, conditionMessage(condition))
    invokeRestart("muffleWarning")
  })
  messages
}
cut_empty_range_warnings <- c(
  "no non-missing arguments to min; returning Inf",
  "no non-missing arguments to max; returning -Inf"
)

# ============================================================================
# CHALLENGING TESTS - xtile
# ============================================================================

test_that("xtile: basic quartile creation", {
  x <- 1:100
  result <- xtile(x, n = 4)
  expect_s3_class(result, "ordered")
  expect_equal(length(result), 100)
  expect_equal(nlevels(result), 4)
})

test_that("xtile: creates equal-sized groups", {
  x <- 1:100
  result <- xtile(x, n = 4)
  freq_table <- table(result)
  expect_equal(as.numeric(freq_table), c(25, 25, 25, 25))
})

test_that("xtile: deciles (n=10)", {
  x <- 1:100
  result <- xtile(x, n = 10)
  expect_equal(nlevels(result), 10)
  freq_table <- table(result)
  expect_true(all(freq_table == 10))
})

test_that("xtile: handles NA values", {
  x <- c(1:50, NA, NA, 51:98)
  result <- xtile(x, n = 4)
  expect_equal(sum(is.na(result)), 2)
  expect_equal(length(result), 100)
})

test_that("xtile: with custom labels", {
  x <- 1:100
  result <- xtile(x, n = 4, labels = c("Q1", "Q2", "Q3", "Q4"))
  expect_equal(levels(result), c("Q1", "Q2", "Q3", "Q4"))
})

test_that("xtile: ties handling - collapsed cutpoints", {
  # Many ties that would collapse quantiles
  x <- c(rep(1, 50), rep(2, 50))
  expect_warning(result <- xtile(x, n = 4), "collapsed")
  # With heavy ties, may create fewer unique groups
  expect_true(nlevels(result) >= 2)
  freq_table <- table(result)
  # Check all values are assigned
  expect_equal(sum(freq_table), 100)
})

test_that("xtile: heavy ties preserve equal values", {
  x <- c(rep(1, 33), rep(2, 33), rep(3, 34))
  expect_warning(result <- xtile(x, n = 3), "collapsed")
  expect_identical(as.integer(result), c(rep(1L, 66), rep(2L, 34)))
})

test_that("xtile: single value returns error", {
  x <- rep(5, 100)
  expect_error(xtile(x, n = 4))
})

test_that("xtile: two unique values with n=2", {
  x <- c(rep(1, 50), rep(2, 50))
  result <- xtile(x, n = 2)
  expect_equal(nlevels(result), 2)
})

test_that("xtile: extreme values", {
  x <- c(.Machine$double.xmin * 10, 1:98, .Machine$double.xmax / 1e10)
  result <- xtile(x, n = 4)
  expect_equal(nlevels(result), 4)
  expect_equal(length(result), 100)
})

test_that("xtile: preserves order of original data", {
  withr::local_preserve_seed()
  x <- sample(1:100)
  result <- xtile(x, n = 4)
  expect_equal(length(result), 100)
  # Check that higher values tend to be in higher quantiles
  x_sorted <- sort(x)
  result_sorted <- xtile(x_sorted, n = 4)
  expect_equal(as.numeric(result_sorted)[1], 1)
  expect_equal(as.numeric(result_sorted)[100], 4)
})

# ============================================================================
# CHALLENGING TESTS - cut_length
# ============================================================================

test_that("cut_length: creates equal-length intervals", {
  x <- 1:100
  result <- cut_length(x, n = 4)
  expect_s3_class(result, "ordered")
  expect_equal(nlevels(result), 4)
})

test_that("cut_length: interval ranges are equal", {
  # Probe both sides of the actual width-2 boundaries and each boundary itself.
  x <- c(0, 1.9, 2, 2.1, 3.9, 4, 4.1, 5.9, 6, 6.1, 8)
  result <- cut_length(x, n = 4, labels = FALSE)
  expect_identical(result, c(1L, 1L, 1L, 2L, 2L, 2L, 3L, 3L, 3L, 4L, 4L))
  expect_identical(
    levels(cut_length(x, n = 4)),
    c("[0,2]", "(2,4]", "(4,6]", "(6,8]")
  )
})

test_that("cut_length: handles NA values", {
  x <- c(1:50, NA, NA, 51:98)
  result <- cut_length(x, n = 4)
  expect_equal(sum(is.na(result)), 2)
})

test_that("cut_length: with custom labels", {
  x <- 1:100
  result <- cut_length(
    x,
    n = 4,
    labels = c("Low", "Med-Low", "Med-High", "High")
  )
  expect_equal(levels(result), c("Low", "Med-Low", "Med-High", "High"))
})

test_that("cut_length: negative values", {
  x <- -50:50
  result <- cut_length(x, n = 5)
  expect_equal(nlevels(result), 5)
  expect_equal(length(result), 101)
})

test_that("cut_length: zero-range data errors", {
  x <- rep(5, 100)
  expect_error(cut_length(x, n = 4))
})

test_that("cut_length: very wide range", {
  x <- c(-1e10, 0, 1e10)
  result <- cut_length(x, n = 3)
  expect_equal(nlevels(result), 3)
})

# ============================================================================
# CHALLENGING TESTS - cut_breaks
# ============================================================================

test_that("cut_breaks: basic functionality with explicit breaks", {
  x <- 1:100
  result <- cut_breaks(x, breaks = c(25, 50, 75))
  expect_s3_class(result, "ordered")
  expect_equal(nlevels(result), 4)
})

test_that("cut_breaks: includes lowest value by default", {
  x <- 1:100
  result <- cut_breaks(x, breaks = 50)
  freq_table <- table(result)
  expect_equal(sum(freq_table), 100)
})

test_that("cut_breaks: right=TRUE (default) - intervals closed on right", {
  x <- c(1, 25, 50, 75, 100)
  result <- cut_breaks(x, breaks = c(25, 50, 75), right = TRUE)
  # With right=TRUE: (min,25], (25,50], (50,75], (75,max]
  expect_equal(as.character(result[1]), levels(result)[1]) # 1 in first interval
  expect_equal(as.character(result[2]), levels(result)[1]) # 25 in first interval
})

test_that("cut_breaks: right=FALSE - intervals closed on left", {
  x <- c(1, 25, 50, 75, 100)
  result <- cut_breaks(x, breaks = c(25, 50, 75), right = FALSE)
  # With right=FALSE: [min,25), [25,50), [50,75), [75,max)
  expect_equal(as.character(result[2]), levels(result)[2]) # 25 in second interval
})

test_that("cut_breaks: with custom labels", {
  x <- 1:100
  result <- cut_breaks(x, breaks = c(33, 66), labels = c("Low", "Med", "High"))
  expect_equal(levels(result), c("Low", "Med", "High"))
})

test_that("cut_breaks: handles NA values", {
  x <- c(1:50, NA, NA, 51:98)
  result <- cut_breaks(x, breaks = 50)
  expect_equal(sum(is.na(result)), 2)
})

test_that("cut_breaks: NULL breaks uses median", {
  x <- 1:100
  result <- cut_breaks(x, breaks = NULL)
  expect_equal(nlevels(result), 2)
  freq_table <- table(result)
  expect_equal(as.numeric(freq_table), c(50, 50))
})

test_that("cut_breaks: duplicate breaks are removed", {
  x <- 1:100
  result <- cut_breaks(x, breaks = c(25, 25, 50, 50, 75))
  expect_equal(nlevels(result), 4)
})

test_that("cut_breaks: breaks outside range are handled", {
  x <- 25:75
  result <- cut_breaks(x, breaks = c(10, 50, 90))
  # Breaks outside range are included, creating more levels
  expect_true(nlevels(result) >= 2)
  expect_equal(length(result), 51) # All values assigned
})

test_that("cut_breaks: single unique value errors", {
  x <- rep(5, 100)
  expect_error(cut_breaks(x, breaks = 3))
})

# ============================================================================
# CHALLENGING TESTS - Comparison and Edge Cases
# ============================================================================

test_that("all cut functions: return ordered factors", {
  x <- 1:100
  q_result <- xtile(x, n = 4)
  l_result <- cut_length(x, n = 4)
  b_result <- cut_breaks(x, breaks = c(25, 50, 75))

  expect_s3_class(q_result, "ordered")
  expect_s3_class(l_result, "ordered")
  expect_s3_class(b_result, "ordered")
})

test_that("all cut functions: handle single element", {
  x <- 5
  expect_error(xtile(x, n = 4))
  expect_error(cut_length(x, n = 4))
  expect_error(cut_breaks(x, breaks = 3))
})

test_that("all cut functions: handle two elements", {
  x <- c(1, 2)
  result_q <- xtile(x, n = 2)
  result_l <- cut_length(x, n = 2)
  result_b <- cut_breaks(x, breaks = 1.5)

  expect_equal(nlevels(result_q), 2)
  expect_equal(nlevels(result_l), 2)
  expect_equal(nlevels(result_b), 2)
})

test_that("all cut functions: handle Inf values", {
  x <- c(1, 50, 100, Inf)
  expect_warning(result_q <- xtile(x, n = 4), "collapsed")
  result_b <- cut_breaks(x, breaks = 50)

  # Inf should be placed in the highest interval
  expect_false(is.na(result_q[4]))
  expect_false(is.na(result_b[4]))

  # cut_length doesn't support Inf values
  expect_error(cut_length(x, n = 4))
})

test_that("all cut functions: handle -Inf values", {
  x <- c(-Inf, 1, 50, 100)
  # -Inf is a distinct value, so it keeps its own (lowest) group.
  expect_no_warning(result_q <- xtile(x, n = 4))
  expect_identical(as.integer(result_q), 1:4)
  result_b <- cut_breaks(x, breaks = 50)

  # -Inf should be placed in the lowest interval
  expect_false(is.na(result_q[1]))
  expect_false(is.na(result_b[1]))

  # cut_length doesn't support Inf values
  expect_error(cut_length(x, n = 4))
})

# ============================================================================
# CHALLENGING TESTS - Real-world Scenarios
# ============================================================================

test_that("xtile: income distribution analysis", {
  withr::local_preserve_seed()
  set.seed(42)
  income <- rlnorm(1000, meanlog = 10, sdlog = 1)
  result <- xtile(
    income,
    n = 5,
    labels = c("Bottom 20%", "20-40%", "40-60%", "60-80%", "Top 20%")
  )
  freq_table <- table(result)
  expect_equal(as.numeric(freq_table), rep(200, 5))
})

test_that("cut_length: age group creation", {
  withr::local_preserve_seed()
  ages <- sample(0:100, 500, replace = TRUE)
  result <- cut_length(
    ages,
    n = 5,
    labels = c("0-20", "21-40", "41-60", "61-80", "81-100")
  )
  expect_equal(nlevels(result), 5)
  expect_equal(length(result), 500)
})

test_that("cut_breaks: exam grade boundaries", {
  withr::local_preserve_seed()
  scores <- sample(0:100, 200, replace = TRUE)
  result <- cut_breaks(
    scores,
    breaks = c(40, 60, 70, 80),
    labels = c("Fail", "D", "C", "B", "A")
  )
  expect_equal(nlevels(result), 5)
  # Verify ordering
  expect_equal(levels(result), c("Fail", "D", "C", "B", "A"))
})

test_that("cut functions: time series data", {
  dates <- seq(as.Date("2020-01-01"), as.Date("2023-12-31"), by = "day")
  numeric_dates <- as.numeric(dates)

  result_q <- xtile(numeric_dates, n = 4)
  result_l <- cut_length(numeric_dates, n = 4)

  expect_equal(length(result_q), length(dates))
  expect_equal(length(result_l), length(dates))
})

# ============================================================================
# CHALLENGING TESTS - Error Handling
# ============================================================================

test_that("all cut functions: n <= 0 errors or handles gracefully", {
  x <- 1:100
  # Functions may error or handle invalid n values
  expect_error(xtile(x, n = 0), "positive integer")
  expect_error(xtile(x, n = -1), "positive integer")
  expect_error(cut_length(x, n = 0), "positive integer")
  expect_error(cut_length(x, n = -1), "positive integer")
})

test_that("all cut functions: empty vector errors or handles gracefully", {
  x <- numeric(0)
  # Quantiles require at least one observed value.
  expect_error(xtile(x, n = 4), "non-missing")
  expect_identical(
    cut_test_warnings(expect_error(cut_length(x, n = 4), "finite")),
    cut_empty_range_warnings
  )
  expect_identical(
    cut_test_warnings(result <- cut_breaks(x, breaks = 50)),
    cut_empty_range_warnings
  )
  expect_s3_class(result, "ordered")
  expect_length(result, 0)
})

test_that("all cut functions: all NA errors", {
  x <- rep(NA, 100)
  expect_error(xtile(x, n = 4))
  expect_identical(
    cut_test_warnings(expect_error(cut_length(x, n = 4), "finite")),
    cut_empty_range_warnings
  )
  expect_identical(
    cut_test_warnings(expect_error(cut_breaks(x, breaks = 50), "numeric")),
    cut_empty_range_warnings
  )
})

test_that("cut_breaks: non-numeric breaks errors or converts", {
  x <- 1:100
  expect_warning(
    result <- cut_breaks(x, breaks = "invalid"),
    "NAs introduced by coercion"
  )
  expect_identical(as.integer(result), rep(1L, 100))
})

# ============================================================================
# CHALLENGING TESTS - Large inputs
# ============================================================================

test_that("cut functions: retain size and interval counts for large inputs", {
  withr::local_preserve_seed()
  x <- rnorm(100000)

  result_q <- xtile(x, n = 10)
  result_l <- cut_length(x, n = 10)

  expect_equal(length(result_q), 100000)
  expect_equal(length(result_l), 100000)
  expect_identical(nlevels(result_q), 10L)
  expect_identical(nlevels(result_l), 10L)
})
