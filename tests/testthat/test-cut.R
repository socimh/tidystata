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
  expect_warning(result <- xtile(x, n = 4), "occupied")
  # With heavy ties, may create fewer unique groups
  expect_true(nlevels(result) >= 2)
  freq_table <- table(result)
  # Check all values are assigned
  expect_equal(sum(freq_table), 100)
})

test_that("xtile: heavy ties preserve equal values", {
  x <- c(rep(1, 33), rep(2, 33), rep(3, 34))
  expect_warning(result <- xtile(x, n = 3), "occupied")
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
  # Left-closed like cut_breaks(), with the maximum in the last interval.
  result <- cut_length(x, n = 4, labels = FALSE)
  expect_identical(result, c(1L, 1L, 2L, 2L, 2L, 3L, 3L, 3L, 4L, 4L, 4L))
  expect_identical(
    levels(cut_length(x, n = 4)),
    c("[0,2)", "[2,4)", "[4,6)", "[6,8]")
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

test_that("cut_breaks: right=TRUE - intervals closed on right", {
  x <- c(1, 25, 50, 75, 100)
  result <- cut_breaks(x, breaks = c(25, 50, 75), right = TRUE)
  # With right=TRUE: (min,25], (25,50], (50,75], (75,max]
  expect_equal(as.character(result[1]), levels(result)[1]) # 1 in first interval
  expect_equal(as.character(result[2]), levels(result)[1]) # 25 in first interval
})

test_that("cut_breaks: right=FALSE (default) - intervals closed on left", {
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
  expect_warning(result_q <- xtile(x, n = 4), "occupied")
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
  expect_error(xtile(x, n = 0), "whole number larger than or equal to 1")
  expect_error(xtile(x, n = -1), "whole number larger than or equal to 1")
  expect_error(cut_length(x, n = 0), "whole number larger than or equal to 1")
  expect_error(cut_length(x, n = -1), "whole number larger than or equal to 1")
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

test_that("cut_breaks: non-numeric breaks error", {
  expect_error(cut_breaks(1:100, breaks = "invalid"), "must be a numeric")
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

test_that("xtile cutpoints reproduce Stata's rule, quantile(type = 2)", {
  withr::local_seed(20261020)
  for (x in list(
    rnorm(97),
    sample(-3:3, 40, TRUE),
    c(1, Inf, 2, -Inf, 0, -0)
  )) {
    for (n in c(2, 3, 7)) {
      probs <- seq_len(n - 1L) / n
      expect_identical(
        stata_quantile(x, probs),
        # Older R (such as 4.1) returns integers for integer x; ours are doubles.
        as.double(stats::quantile(x, probs, type = 2, names = FALSE))
      )
    }
  }
})

test_that("milestone quantile ties stay together after row permutation", {
  x <- c(rep(1, 8), rep(2, 4), rep(3, 4))
  expect_warning(out <- xtile(x, n = 4), "[Cc]ollaps|[Tt]ie|[Ff]ewer")
  expect_true(all(vapply(
    split(as.integer(out), x),
    function(z) length(unique(z)) == 1L,
    logical(1)
  )))
  p <- rev(seq_along(x))
  expect_warning(other <- xtile(x[p], n = 4), "Tied values leave")
  expect_identical(as.integer(other)[order(p)], as.integer(out))
})

.milestone_quantile_cases <- list(
  quartiles = list(x = 1:100, n = 4),
  deciles = list(x = 1:100, n = 10),
  halves = list(x = 1:20, n = 2),
  one_interval = list(x = 1:8, n = 1),
  negative = list(x = -20:-1, n = 4),
  fractional = list(x = c(0.1, 0.3, 0.8, 2.1, 4.2, 9.9), n = 3),
  uneven_sample = list(x = c(2, 4, 7, 11, 13, 18, 29), n = 4),
  shuffled = list(x = c(8, 1, 6, 3, 4, 7, 2, 5), n = 4),
  missing_edges = list(x = c(NA, 1:12, NA), n = 3),
  missing_middle = list(x = c(1:5, NA, 6:10), n = 4),
  nan_missing = list(x = c(1:5, NaN, 6:10), n = 2),
  two_values = list(x = rep(c(1, 2), each = 20), n = 2),
  two_values_collapsed = list(x = rep(c(1, 2), each = 20), n = 4),
  lower_plateau = list(x = c(rep(1, 12), 2:5), n = 4),
  upper_plateau = list(x = c(1:4, rep(5, 12)), n = 4),
  middle_plateau = list(x = rep(c(1, 2, 3), c(4, 8, 4)), n = 4),
  plateau_with_missing = list(x = c(NA, rep(c(1, 2), each = 20), NA), n = 4),
  labels = list(x = 1:20, n = 4, labels = c("Q1", "Q2", "Q3", "Q4")),
  collapsed_labels = list(
    x = rep(c(1, 2), each = 20),
    n = 4,
    labels = c("Low", "High")
  ),
  integer_codes = list(x = 1:20, n = 4, labels = FALSE),
  collapsed_integer_codes = list(
    x = rep(c(1, 2), each = 20),
    n = 4,
    labels = FALSE
  ),
  more_bins_than_rows = list(x = c(1, 3, 9), n = 6),
  asymmetric_duplicates = list(x = c(rep(-4, 4), rep(0, 8), 2, 4, 8, 16), n = 4)
)

for (.scenario in names(.milestone_quantile_cases)) {
  test_that(
    paste("milestone xtile stable value boundaries", .scenario),
    {
      case <- .milestone_quantile_cases[[.scenario]]
      before <- case$x
      # Stata xtile reference: x joins the first group whose cutpoint >= x,
      # and the codes of empty groups are skipped. Factor levels are the
      # occupied groups.
      # stata_quantile() is checked against Stata in
      # test-stata-parity-summ.R; quantile(type = 2) differs where n * p is
      # whole only in Stata's arithmetic, such as 100 * 0.3.
      observed <- case$x[!is.na(case$x)]
      cutpoints <- stata_quantile(observed, seq_len(case$n - 1L) / case$n)
      raw <- findInterval(case$x, cutpoints, left.open = TRUE) + 1L
      raw[is.na(case$x)] <- NA_integer_
      groups <- length(unique(raw[!is.na(raw)]))
      expected_codes <- if (identical(case$labels, FALSE)) {
        raw
      } else {
        match(raw, sort(unique(raw[!is.na(raw)])))
      }
      collapsed <- groups < case$n
      if (collapsed) {
        expect_warning(
          out <- do.call(xtile, case),
          "[Cc]ollaps|[Tt]ie|[Ff]ewer"
        )
      } else {
        expect_no_warning(out <- do.call(xtile, case))
      }
      expect_identical(as.integer(out), expected_codes)
      if (!collapsed && is.null(case$labels)) {
        # Without ties or empty intervals, results equal base::cut().
        breaks <- stata_quantile(
          observed,
          seq(0, 1, length.out = case$n + 1L)
        )
        expect_equal(
          out,
          base::cut(
            case$x,
            breaks,
            include.lowest = TRUE,
            ordered_result = TRUE
          )
        )
      }
      expect_identical(is.na(out), is.na(case$x))
      expect_identical(case$x, before)
      codes <- as.integer(out)
      for (value in unique(case$x[!is.na(case$x)])) {
        expect_length(unique(codes[!is.na(case$x) & case$x == value]), 1L)
      }
      p <- rev(seq_along(case$x))
      shuffled <- case
      shuffled$x <- case$x[p]
      expect_warning(
        other <- do.call(xtile, shuffled),
        if (collapsed) "Tied values leave" else NA
      )
      expect_identical(as.integer(other)[order(p)], codes)
      if (identical(case$labels, FALSE)) {
        expect_type(out, "integer")
      } else {
        expect_s3_class(out, "ordered")
        expect_equal(nlevels(out), groups)
      }
    }
  )
}

.milestone_invalid_quantiles <- list(
  constant = list(x = rep(4, 10)),
  empty = list(x = numeric()),
  all_missing = list(x = rep(NA_real_, 4)),
  all_nan = list(x = rep(NaN, 4)),
  complex_values = list(x = c(1 + 1i, 2 + 1i)),
  matrix_values = list(x = matrix(1:4, nrow = 2)),
  character = list(x = c("1", "2")),
  factor = list(x = factor(c(1, 2))),
  zero_bins = list(x = 1:10, n = 0),
  negative_bins = list(x = 1:10, n = -1),
  fractional_bins = list(x = 1:10, n = 2.5),
  missing_bins = list(x = 1:10, n = NA_real_),
  infinite_bins = list(x = 1:10, n = Inf),
  character_bins = list(x = 1:10, n = "4"),
  vector_bins = list(x = 1:10, n = c(2, 4)),
  absent_bins = list(x = 1:10, n = numeric()),
  short_labels = list(x = 1:20, n = 4, labels = c("L", "H")),
  long_labels = list(x = 1:20, n = 2, labels = letters[1:4]),
  collapsed_original_labels = list(
    x = rep(c(1, 2), each = 20),
    n = 4,
    labels = letters[1:4]
  ),
  null_values = list(x = NULL)
)

for (.scenario in names(.milestone_invalid_quantiles)) {
  test_that(paste("milestone xtile validates", .scenario), {
    case <- .milestone_invalid_quantiles[[.scenario]]
    expect_error(do.call(xtile, case))
  })
}

test_that("xtile() accepts logical dummies and labels = TRUE", {
  dummy <- c(TRUE, FALSE, TRUE, FALSE, FALSE)
  expect_identical(
    xtile(dummy, 2, labels = FALSE),
    xtile(as.integer(dummy), 2, labels = FALSE)
  )
  expect_identical(xtile(1:4, 2, labels = TRUE), xtile(1:4, 2))
  expect_error(xtile("a"), "numeric or logical")
})

test_that("grouped xtile() returns group-relative integer codes", {
  data <- dplyr::group_by(
    tibble::tibble(k = rep(1:2, each = 4), a = c(1:4, 11:14)),
    k
  )
  out <- dplyr::mutate(data, q = xtile(a, 2))
  expect_identical(out$q, rep(c(1L, 1L, 2L, 2L), 2))
  ungrouped <- dplyr::mutate(dplyr::ungroup(data), q = xtile(a, 2))
  expect_s3_class(ungrouped$q, "ordered")
})

test_that("rank cuts balance ties deterministically and restore missing positions", {
  x <- c(4, 1, 1, NA, 4, 1, 2, 9)
  out <- xtile(x, n = 3, method = "rank", labels = FALSE)
  expect_identical(out, c(2L, 1L, 1L, NA_integer_, 3L, 1L, 2L, 3L))
  expect_equal(as.integer(table(out)), c(3L, 2L, 2L))
  expect_identical(xtile(x, n = 3, method = "rank", labels = FALSE), out)
  constant <- xtile(rep(5, 5), n = 2, method = "rank")
  expect_true(is.ordered(constant))
  expect_equal(levels(constant), c("1", "2"))
  expect_equal(as.integer(constant), c(1L, 1L, 1L, 2L, 2L))
  expect_warning(
    scarce <- xtile(c(4, NA, 2), n = 4, method = "rank"),
    "observations"
  )
  expect_equal(levels(scarce), c("1", "2"))
  expect_equal(as.integer(scarce), c(2L, NA_integer_, 1L))
  expect_equal(
    levels(xtile(
      1:4,
      n = 2,
      method = "rank",
      labels = c("low", "high")
    )),
    c("low", "high")
  )
  expect_error(
    xtile(1:4, n = 2, method = "rank", labels = "x"),
    "length 2"
  )
  expect_error(xtile(NA_real_, method = "rank"), "non-missing")
  expect_identical(
    xtile(
      c(Inf, -Inf, NA, NaN, 0),
      n = 2,
      method = "rank",
      labels = FALSE
    ),
    c(2L, 1L, NA_integer_, NA_integer_, 1L)
  )
  expect_identical(
    xtile(8, n = 1, method = "rank", labels = FALSE),
    1L
  )
  expect_error(xtile(1:5, method = "wrong"), "must be one of")
  expect_error(
    xtile(1:5, n = 1 + 1i, method = "rank"),
    "whole number larger than or equal to 1"
  )
})

test_that("default quantile cuts never merge distinct values", {
  dummy <- rep(0:1, c(7, 3))
  expect_no_warning(two <- xtile(dummy, 2))
  expect_identical(as.integer(two), as.integer(dummy) + 1L)
  expect_identical(levels(two), c("[0,0]", "(0,1]"))
  # Codes skip the empty groups, as Stata's xtile does: the 30th
  # percentile of three 0s and eight 1s is already 1.
  expect_warning(
    codes <- xtile(rep(0:1, c(3, 8)), 10, labels = FALSE),
    "2 of 10"
  )
  expect_identical(codes, rep(c(1L, 3L), c(3, 8)))
  expect_warning(
    three <- xtile(rep(1:3, c(500, 300, 200)), 10, labels = FALSE),
    "3 of 10"
  )
  expect_identical(sort(unique(three)), c(1L, 6L, 9L))
  expect_identical(as.integer(table(three)), c(500L, 300L, 200L))
  expect_warning(
    labelled <- xtile(dummy, 10, labels = c("no", "yes")),
    "2 of 10"
  )
  expect_identical(as.character(labelled), ifelse(dummy == 1, "yes", "no"))
  expect_no_warning(even <- xtile(1:8, 4, labels = FALSE))
  expect_identical(even, rep(1:4, each = 2))
  expect_identical(
    levels(xtile(1:8, 4)),
    c("[1,2.5]", "(2.5,4.5]", "(4.5,6.5]", "(6.5,8]")
  )
  expect_identical(
    xtile(c(NA, 1:4), 2, labels = FALSE),
    c(NA, 1L, 1L, 2L, 2L)
  )
})

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
      "`n` must be a whole number larger than or equal to 1"
    )
  }
})

test_that("cut_length preserves valid intervals, labels and missing values", {
  x <- c(-4, -2, 0, 2, 4, NA_real_)
  expected <- ordered(
    c("low", "low", "high", "high", "high", NA),
    levels = c("low", "high")
  )
  expect_identical(cut_length(x, n = 2, labels = c("low", "high")), expected)
  expect_identical(
    cut_length(x, n = 2L, labels = FALSE),
    c(1L, 1L, 2L, 2L, 2L, NA_integer_)
  )
  expect_identical(
    cut_length(x, n = 1, labels = FALSE),
    c(1L, 1L, 1L, 1L, 1L, NA_integer_)
  )
})

test_that("binning contracts: quantile codes use Stata's boundaries", {
  x <- c(10, 0, 4, 1, 7, NA, 2, 9)
  breaks <- stats::quantile(x, c(0, 0.25, 0.5, 0.75, 1), na.rm = TRUE, type = 2)
  expected <- cut(x, breaks, include.lowest = TRUE, ordered_result = TRUE)
  expect_identical(xtile(x), expected)
  expect_identical(xtile(x, labels = FALSE), as.integer(expected))
})

test_that("binning contracts: collapsed quantile boundaries preserve all ties", {
  x <- c(rep(1, 4), rep(2, 4), NA)
  # Stata cutpoints are 1, 1.5 and 2, so the 2s take code 3.
  expect_warning(
    out <- xtile(x, n = 4, labels = FALSE),
    "leave 2 of 4 quantile groups"
  )
  expect_identical(out, c(rep(1L, 4), rep(3L, 4), NA_integer_))
  expect_warning(
    labelled <- xtile(x, n = 4, labels = c("Low", "High")),
    "leave 2 of 4 quantile groups"
  )
  expect_identical(levels(labelled), c("Low", "High"))
})

test_that("binning contracts: quantile permutation preserves value assignments", {
  x <- c(0, 1, 1, 2, 3, 5, 8, 13, NA)
  order <- c(9, 4, 7, 1, 3, 6, 2, 8, 5)
  expect_identical(
    xtile(x[order], labels = FALSE),
    xtile(x, labels = FALSE)[order]
  )
})

test_that("binning contracts: equal-width edges use left-closed intervals", {
  x <- c(0, 1, 2, 3, 4, 5, 6, 7, 8, NA)
  expect_identical(
    cut_length(x, n = 4, labels = FALSE),
    c(1L, 1L, 2L, 2L, 3L, 3L, 4L, 4L, 4L, NA_integer_)
  )
  expect_identical(
    levels(cut_length(x, n = 4)),
    c("[0,2)", "[2,4)", "[4,6)", "[6,8]")
  )
})

test_that("binning contracts: explicit boundaries respect either closure", {
  x <- c(0, 2, 4, 6, 8, NA)
  expect_identical(
    cut_breaks(x, breaks = c(2, 4, 6), labels = FALSE, right = TRUE),
    c(1L, 1L, 2L, 3L, 4L, NA_integer_)
  )
  # The default follows egen cut(): left-closed intervals.
  expect_identical(
    cut_breaks(x, breaks = c(2, 4, 6), labels = FALSE),
    c(1L, 2L, 3L, 4L, 4L, NA_integer_)
  )
})

test_that("binning contracts: supplied breaks sort and deduplicate with endpoints", {
  x <- c(0, 2, 4, 8, NA)
  expect_identical(
    cut_breaks(x, breaks = c(6, 2, 2, 8), labels = FALSE),
    c(1L, 2L, 2L, 3L, NA_integer_)
  )
})

test_that("binning contracts: defaults and custom labels preserve ordering", {
  x <- c(0, 2, 4, 6, NA)
  expected <- ordered(
    c("Low", "Low", "High", "High", NA),
    levels = c("Low", "High")
  )
  expect_identical(cut_breaks(x, labels = c("Low", "High")), expected)
  expect_identical(cut_length(x, n = 2, labels = c("Low", "High")), expected)
})

test_that("binning contracts: binning does not mutate source values or labels", {
  x <- structure(c(0, 2, 4, 6, NA), label = "Income")
  before <- serialize(x, NULL)
  xtile(x, n = 2)
  cut_length(x, n = 2)
  cut_breaks(x, breaks = 3)
  expect_identical(serialize(x, NULL), before)
})

test_that("binning reports invalid input", {
  expect_snapshot(error = TRUE, {
    xtile(letters)
    xtile(1:10, n = 0)
    xtile(1:10, n = 2.5)
    xtile(c(NA, NA))
    xtile(rep(1, 4))
    xtile(1:4, wt = 1:4, method = "rank")
    xtile(1:4, wt = c(1, -1, 1, 1))
    cut_length(1:10, n = "2")
  })
  expect_snapshot(xtile(1:2, n = 4, method = "rank"))
})
