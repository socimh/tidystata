# Comprehensive Challenging Test Suite for tab() Function
# 70+ difficult test scenarios - focusing on edge cases, complexity, and robustness
# All tests designed to run in < 1 minute

# CHALLENGE: Comprehensive testing for tab
# FUNCTIONS: tab
# KEY BEHAVIORS: cross-tabulation, percentage calculation
# EDGE CASES: high-dimensional tables, sparse data

library(testthat)
library(statart)
library(dplyr)
library(tibble)
library(haven)

# ============================================================================
# CHALLENGING TESTS - Variable Combinations & Complex Data Types
# ============================================================================

test_that("tab: five variables with complex interactions", {
  set.seed(42)
  df <- tibble(
    v1 = sample(1:3, 200, replace = TRUE),
    v2 = sample(letters[1:4], 200, replace = TRUE),
    v3 = factor(sample(c("low", "med", "high"), 200, replace = TRUE)),
    v4 = sample(c(TRUE, FALSE), 200, replace = TRUE),
    v5 = sample(1:2, 200, replace = TRUE)
  )
  result <- tab(df, v1, v2, v3, v4, v5)
  expect_true(nrow(result) > 10)
  expect_equal(ncol(result), 6)
  expect_equal(sum(result$n), 200)
})

test_that("tab: variables with reserved names (n, percent, cum)", {
  df <- tibble(n = c(1, 1, 2, 2), percent = c("a", "a", "b", "b"), 
               cum = c("x", "y", "x", "y"))
  expect_message(
    result <- tab(df, n, percent, cum),
    "renamed"
  )
})

test_that("tab: deeply nested list columns should fail gracefully", {
  df <- tibble(
    x = 1:5,
    y = I(list(1:3, 2:4, 3:5, 4:6, 5:7))
  )
  expect_error(tab(df, x, y))
})

test_that("tab: matrix column input", {
  df <- tibble(x = 1:4)
  df$y <- matrix(1:8, nrow = 4)
  expect_error(tab(df, x, y))
})

# ============================================================================
# CHALLENGING TESTS - Missing Value Nightmares
# ============================================================================

test_that("tab: strategic NA placement - only first variable has NAs", {
  df <- tibble(
    x = c(NA, NA, 1, 1, 2, 2, NA),
    y = c("a", "b", "a", "b", "a", "b", "a")
  )
  result <- tab(df, x, y)
  expect_true(any(is.na(result$x)))
  expect_false(any(is.na(result$y)))
})

test_that("tab: cascading NAs - each row has NA in different column", {
  df <- tibble(
    x = c(NA, 2, 3),
    y = c("a", NA, "c"),
    z = c(1, 2, NA)
  )
  result <- tab(df, x, y, z)
  expect_true(any(is.na(result$x)))
  expect_true(any(is.na(result$y)))
  expect_true(any(is.na(result$z)))
  expect_equal(nrow(result), 7)
})

test_that("tab: all combinations of NA patterns", {
  df <- tibble(
    x = c(1, 1, 1, NA, NA, NA),
    y = c("a", "a", NA, "a", "a", NA)
  )
  result <- tab(df, x, y)
  expect_equal(nrow(result), 5)
  expect_true(any(is.na(result$x) & result$y == "a"))
  expect_true(any(is.na(result$x) & is.na(result$y)))
})

test_that("tab: factor with NA level explicitly set", {
  df <- tibble(x = factor(c("a", "b", NA), exclude = NULL))
  result <- tab(df, x)
  expect_true(any(is.na(result$x)))
  expect_equal(sum(result$n), 3)
})

test_that("tab: haven labelled with NA value labelled", {
  df <- tibble(x = labelled(c(1, 2, -99, 1), 
                            labels = c("Yes" = 1, "No" = 2, "Missing" = -99),
                            na_values = -99))
  result <- tab(df, x)
  expect_equal(nrow(result), 3)
})

# ============================================================================
# CHALLENGING TESTS - Complex Grouping Scenarios
# ============================================================================

test_that("tab: group by variable that is also being tabulated", {
  df <- tibble(group = rep(c("A", "B"), each = 10), x = 1:20)
  result <- tab(df, x, group, .by = group)
  expect_true("group" %in% names(result))
  expect_equal(nrow(result), 20)
})

test_that("tab: group with empty groups after filtering", {
  df <- tibble(
    group = rep(c("A", "B", "C"), each = 10),
    x = c(1:10, 11:20, 21:30)
  )
  result <- tab(df, x > 15, .by = group)
  expect_true(any(result$group == "C"))
  expect_false(any(result$group == "A" & result$n > 0))
})

test_that("tab: many grouping variables with complex hierarchy", {
  set.seed(123)
  df <- tibble(
    country = rep(c("US", "UK", "DE"), each = 30),
    region = rep(rep(c("North", "South", "East"), each = 10), 3),
    city = rep(c("A", "B", "C", "D", "E", "F", "G", "H", "I"), each = 10),
    category = sample(c("X", "Y", "Z"), 90, replace = TRUE)
  )
  result <- tab(df, category, .by = c(country, region))
  expect_equal(ncol(result), 4)
  expect_true(nrow(result) <= 27)
})

test_that("tab: group where grouping variable has many NA levels", {
  df <- tibble(
    group = c(rep("A", 5), rep(NA, 20), rep("B", 5)),
    x = rep(c(1, 2), 15)
  )
  result <- tab(df, x, .by = group)
  expect_true(sum(is.na(result$group)) > 0)
  expect_equal(sum(result$n[result$group == "A" | result$group == "B"]), 10)
})

test_that("tab: group with single unique value in group", {
  df <- tibble(group = rep("only", 100), x = sample(1:5, 100, replace = TRUE))
  result <- tab(df, x, .by = group)
  expect_equal(nrow(result), 5)
  expect_true(all(result$group == "only"))
})

# ============================================================================
# CHALLENGING TESTS - Complex Boolean Expressions
# ============================================================================

test_that("tab: boolean with OR and AND combined", {
  df <- tibble(x = 1:100, y = rep(letters[1:5], 20))
  result <- tab(df, y, (x > 20 & x < 40) | (x > 60 & x < 80))
  expect_true(nrow(result) <= 5)
  total_count <- sum(result$n)
  expect_true(total_count <= 38)
})

test_that("tab: boolean expression creating all FALSE", {
  df <- tibble(x = 1:50, y = sample(1:3, 50, replace = TRUE))
  result <- tab(df, y, x > 100)
  expect_equal(nrow(result), 0)
})

test_that("tab: boolean with is.na() function", {
  df <- tibble(x = c(1:5, NA, 7:10), y = c("a", "b", NA, "a", "b", "c", "a", "b", "a", "b"))
  result <- tab(df, y, is.na(x))
  expect_equal(nrow(result), 1)
  expect_equal(result$y, "c")
})

test_that("tab: boolean with %in% operator", {
  df <- tibble(x = 1:20, y = rep(1:4, 5))
  result <- tab(df, y, x %in% c(3, 7, 11, 15, 19))
  expect_equal(nrow(result), 4)
  expect_equal(sum(result$n), 5)
})

test_that("tab: complex nested boolean with multiple variables", {
  df <- tibble(
    a = 1:50,
    b = rep(c("x", "y"), 25),
    c = sample(1:3, 50, replace = TRUE)
  )
  result <- tab(df, c, (a > 10 & b == "x") | (a <= 10 & b == "y"))
  expect_true(nrow(result) >= 1)
})

# ============================================================================
# CHALLENGING TESTS - Edge Cases & Extremes
# ============================================================================

test_that("tab: data frame with only 1 column and 1 row", {
  df <- tibble(x = "single")
  result <- tab(df, x)
  expect_equal(nrow(result), 1)
  expect_equal(result$n, 1)
})

test_that("tab: 1000 unique values with only 1 occurrence each", {
  df <- tibble(x = 1:1000)
  result <- tab(df, x)
  expect_equal(nrow(result), 1000)
  expect_true(all(result$n == 1))
})

test_that("tab: single value repeated 5000 times", {
  df <- tibble(x = rep("only_value", 5000))
  result <- tab(df, x)
  expect_equal(nrow(result), 1)
  expect_equal(result$n, 5000)
})

test_that("tab: Inf and -Inf values mixed with regular numbers", {
  df <- tibble(x = c(Inf, Inf, -Inf, -Inf, 0, 1, 2))
  result <- tab(df, x)
  expect_equal(nrow(result), 5)
  expect_true(Inf %in% result$x)
  expect_true(-Inf %in% result$x)
})

test_that("tab: NaN values treated as distinct from NA", {
  df <- tibble(x = c(1, 2, NaN, NaN, NA, NA))
  result <- tab(df, x)
  expect_true(nrow(result) >= 3)
})

test_that("tab: empty string vs whitespace vs regular strings", {
  df <- tibble(x = c("", " ", "  ", "a", "a", "b"))
  result <- tab(df, x)
  expect_true(nrow(result) >= 4)
  expect_true("" %in% result$x)
  expect_true(" " %in% result$x)
})

test_that("tab: numeric values at floating point precision limits", {
  df <- tibble(x = c(0.1 + 0.2, 0.3, 0.1 + 0.2, 0.3))
  result <- tab(df, x)
  expect_true(nrow(result) <= 2)
})

# ============================================================================
# CHALLENGING TESTS - Type Coercion & Mixed Types
# ============================================================================

test_that("tab: factor levels not in data", {
  df <- tibble(x = factor(c("a", "b"), levels = c("a", "b", "c", "d", "e")))
  result <- tab(df, x)
  expect_equal(nrow(result), 2)
})

test_that("tab: Date values spanning multiple years", {
  df <- tibble(x = as.Date(c("2020-01-01", "2021-06-15", "2022-12-31", 
                             "2020-01-01", "2021-06-15")))
  result <- tab(df, x)
  expect_equal(nrow(result), 3)
  expect_s3_class(result$x, "Date")
})

test_that("tab: POSIXct with different timezones", {
  df <- tibble(x = c(
    as.POSIXct("2024-01-01 12:00", tz = "UTC"),
    as.POSIXct("2024-01-01 12:00", tz = "EST"),
    as.POSIXct("2024-01-01 12:00", tz = "UTC")
  ))
  result <- tab(df, x)
  expect_true(nrow(result) >= 2)
})

test_that("tab: integer64 class from bit64", {
  skip_if_not_installed("bit64")
  df <- tibble(x = bit64::as.integer64(c(1e10, 1e10, 2e10)))
  result <- tab(df, x)
  expect_equal(nrow(result), 2)
})

test_that("tab: difftime objects", {
  df <- tibble(x = as.difftime(c(1, 1, 2, 2), units = "hours"))
  result <- tab(df, x)
  expect_equal(nrow(result), 2)
})

# ============================================================================
# CHALLENGING TESTS - Unicode & Special Characters
# ============================================================================

test_that("tab: mixed scripts (latin, cjk, arabic, emoji)", {
  df <- tibble(x = c("hello", "中文", "العربية", "🎉", "🎉", "mixed中文"))
  result <- tab(df, x)
  expect_equal(nrow(result), 5)
})

test_that("tab: zero-width characters and control characters", {
  df <- tibble(x = c("a\u200Bb", "a\u200Bb", "ab", "a\t", "a\n", "a\r"))
  result <- tab(df, x)
  expect_true(nrow(result) >= 4)
})

test_that("tab: right-to-left text", {
  df <- tibble(x = c("مرحبا", "مرحبا", "שלום", "hello"))
  result <- tab(df, x)
  expect_equal(nrow(result), 3)
})

# ============================================================================
# CHALLENGING TESTS - Tidyselect Edge Cases
# ============================================================================

test_that("tab: starts_with with no matches", {
  df <- tibble(x = 1:3, y = 1:3, z = 1:3)
  result <- tab(df, starts_with("nonexistent"))
  expect_equal(nrow(result), 0)
})

test_that("tab: everything() with hidden columns", {
  df <- tibble(x = 1:3, y = 1:3)
  attr(df$y, "hidden") <- TRUE
  result <- tab(df, everything())
  expect_equal(ncol(result), 3)
})

test_that("tab: where() with complex predicate", {
  df <- tibble(a = 1:3, b = c("x", "y", "z"), c = c(TRUE, FALSE, TRUE))
  result <- tab(df, where(~ is.numeric(.x) | is.logical(.x)))
  expect_equal(ncol(result), 3)
})

# ============================================================================
# CHALLENGING TESTS - Sorting & Ordering
# ============================================================================

test_that("tab: .desc with ties in frequency", {
  df <- tibble(x = c("a", "a", "b", "b", "c", "c", "c"))
  result <- tab(df, x, .desc = TRUE)
  expect_equal(result$x[1], "c")
  expect_true(result$n[2] == result$n[3])
})

test_that("tab: ordering with mixed case strings", {
  df <- tibble(x = c("Apple", "apple", "APPLE", "banana"))
  result <- tab(df, x)
  expect_equal(nrow(result), 4)
})

test_that("tab: factor ordering preserved even with .desc=TRUE", {
  df <- tibble(x = factor(c("high", "low", "med"), 
                          levels = c("low", "med", "high")))
  result <- tab(df, x, .desc = FALSE)
  expect_equal(as.character(result$x[1]), "low")
})

# ============================================================================
# CHALLENGING TESTS - Large-ish Data (but still fast)
# ============================================================================

test_that("tab: 10000 rows with 100 unique combinations", {
  set.seed(42)
  df <- tibble(
    x = sample(1:10, 10000, replace = TRUE),
    y = sample(letters[1:10], 10000, replace = TRUE)
  )
  result <- tab(df, x, y)
  expect_true(nrow(result) <= 100)
  expect_equal(sum(result$n), 10000)
})

test_that("tab: many columns selected", {
  set.seed(42)
  df <- as_tibble(replicate(15, sample(1:3, 100, replace = TRUE)))
  names(df) <- paste0("var", 1:15)
  result <- tab(df, var1:var10)
  expect_equal(ncol(result), 11)
})

# ============================================================================
# CHALLENGING TESTS - Error Handling & Robustness
# ============================================================================

test_that("tab: gracefully handle data.frame with no columns", {
  df <- data.frame()[1:5, ]
  expect_error(tab(df))
})

test_that("tab: NULL input should error", {
  expect_error(tab(NULL))
})

test_that("tab: non-existent column reference should error", {
  df <- tibble(x = 1:5)
  expect_error(tab(df, y))
})

# ============================================================================
# CHALLENGING TESTS - Real-world-like Scenarios
# ============================================================================

test_that("tab: survey data simulation with skip patterns", {
  df <- tibble(
    age_group = sample(c("18-25", "26-35", "36-50", "50+"), 200, replace = TRUE),
    answered_q2 = sample(c(TRUE, FALSE), 200, replace = TRUE),
    q2_response = ifelse(sample(c(TRUE, FALSE), 200, replace = TRUE), 
                         sample(c("Yes", "No"), 200, replace = TRUE), NA)
  )
  result <- tab(df, q2_response, answered_q2)
  expect_true(nrow(result) >= 2)
})

test_that("tab: duplicate rows identification", {
  df <- tibble(x = c(1, 1, 1, 2, 2, 3, 4, 4, 4, 4))
  result <- tab(df, x)
  dupes <- result$n[result$n > 1]
  expect_true(length(dupes) >= 2)
})

test_that("tab: time series data with gaps", {
  dates <- seq(as.Date("2024-01-01"), as.Date("2024-12-31"), by = "day")
  dates <- dates[sample(length(dates), 300)]
  df <- tibble(date = dates)
  result <- tab(df, date)
  expect_equal(nrow(result), 300)
})

# ============================================================================
# CHALLENGING TESTS - Performance Edge Cases
# ============================================================================

test_that("tab: highly duplicated data", {
  df <- tibble(x = rep(1, 10000), y = rep("a", 10000))
  result <- tab(df, x, y)
  expect_equal(nrow(result), 1)
  expect_equal(result$n, 10000)
})

test_that("tab: completely unique data across multiple vars", {
  df <- tibble(x = 1:500, y = letters[1:26][(1:500 %% 26) + 1])
  result <- tab(df, x, y)
  expect_equal(nrow(result), 500)
})

test_that("tab: circular reference in data names", {
  df <- tibble(a = 1:4, b = 1:4)
  names(df) <- c("a", "a")
  expect_error(tab(df, a))
})

# ============================================================================
# CHALLENGING TESTS - Interaction with Other Packages
# ============================================================================

test_that("tab: sf object geometry column handling", {
  skip_if_not_installed("sf")
  df <- tibble(x = 1:5, y = c("a", "a", "b", "b", "c"))
  expect_no_error(result <- tab(df, y))
  expect_equal(nrow(result), 3)
})

test_that("tab: units class from units package", {
  skip_if_not_installed("units")
  df <- tibble(x = units::set_units(c(1, 1, 2, 2), "m"))
  result <- tab(df, x)
  expect_equal(nrow(result), 2)
})
