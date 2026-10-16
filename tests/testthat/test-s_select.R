# Comprehensive Test Suite for s_select() Function
# Enhanced select with data-masking support

# CHALLENGE: Comprehensive testing for s_select
# FUNCTIONS: s_select
# KEY BEHAVIORS: enhanced select, data-masking
# EDGE CASES: complex expressions, tidyselect integration

library(testthat)
library(statart)
library(dplyr)
library(tibble)

# ============================================================================
# CHALLENGING TESTS - Basic Select Operations
# ============================================================================

test_that("s_select: basic column selection", {
  df <- tibble(x = 1:5, y = 6:10, z = 11:15)
  result <- s_select(df, x, y)
  expect_equal(ncol(result), 2)
  expect_equal(names(result), c("x", "y"))
})

test_that("s_select: select all columns with empty call", {
  df <- tibble(x = 1:5, y = 6:10, z = 11:15)
  result <- s_select(df)
  expect_equal(ncol(result), 3)
  expect_equal(names(result), c("x", "y", "z"))
})

test_that("s_select: single column selection", {
  df <- tibble(x = 1:5, y = 6:10)
  result <- s_select(df, x)
  expect_equal(ncol(result), 1)
  expect_equal(names(result), "x")
})

test_that("s_select: column reordering", {
  df <- tibble(a = 1:5, b = 6:10, c = 11:15)
  result <- s_select(df, c, a, b)
  expect_equal(names(result), c("c", "a", "b"))
})

# ============================================================================
# CHALLENGING TESTS - Data-Masking (Expression Selection)
# ============================================================================

test_that("s_select: select with boolean expression", {
  df <- tibble(x = c(1, 2, 3, 4, 5), y = c(10, 20, 30, 40, 50))
  result <- s_select(df, x > 3)
  expect_equal(ncol(result), 1)
  expect_equal(names(result), "x > 3")
  expect_equal(result[[1]], c(FALSE, FALSE, FALSE, TRUE, TRUE))
})

test_that("s_select: select with arithmetic expression", {
  df <- tibble(x = 1:5, y = 6:10)
  result <- s_select(df, x + y)
  expect_equal(ncol(result), 1)
  expect_equal(result[[1]], c(7, 9, 11, 13, 15))
})

test_that("s_select: multiple computed columns", {
  df <- tibble(x = 1:5, y = 6:10)
  result <- s_select(df, sum_xy = x + y, diff_xy = y - x)
  expect_equal(ncol(result), 2)
  expect_equal(result$sum_xy, c(7, 9, 11, 13, 15))
  expect_equal(result$diff_xy, c(5, 5, 5, 5, 5))
})

test_that("s_select: complex expressions", {
  df <- tibble(a = 1:10, b = 11:20, c = 21:30)
  result <- s_select(
    df,
    weighted = a * 0.5 + b * 0.3 + c * 0.2,
    ratio = (b - a) / c
  )
  expect_equal(ncol(result), 2)
  expect_type(result$weighted, "double")
  expect_type(result$ratio, "double")
})

test_that("s_select: expression using functions", {
  df <- tibble(x = c(1, 4, 9, 16, 25))
  result <- s_select(df, sqrt_x = sqrt(x))
  expect_equal(result$sqrt_x, c(1, 2, 3, 4, 5))
})

# ============================================================================
# CHALLENGING TESTS - Tidyselect Helpers
# ============================================================================

test_that("s_select: starts_with selection", {
  df <- tibble(temp_1 = 1:5, temp_2 = 6:10, pressure = 11:15)
  result <- s_select(df, starts_with("temp"))
  expect_equal(ncol(result), 2)
  expect_true(all(grepl("^temp_", names(result))))
})

test_that("s_select: ends_with selection", {
  df <- tibble(var_a_test = 1:5, var_b_test = 6:10, var_c_prod = 11:15)
  result <- s_select(df, ends_with("_test"))
  expect_equal(ncol(result), 2)
  expect_true(all(grepl("_test$", names(result))))
})

test_that("s_select: contains selection", {
  df <- tibble(temp_morning = 1:5, temp_evening = 6:10, pressure_temp = 11:15)
  result <- s_select(df, contains("temp"))
  expect_equal(ncol(result), 3)
})

test_that("s_select: where() with is.numeric", {
  df <- tibble(
    num1 = 1:5,
    num2 = 6:10,
    char = letters[1:5],
    logi = c(TRUE, FALSE, TRUE, FALSE, TRUE)
  )
  result <- s_select(df, where(is.numeric))
  expect_equal(ncol(result), 2)
  expect_equal(names(result), c("num1", "num2"))
})

test_that("s_select: where() with complex predicate", {
  df <- tibble(
    a = 1:5,
    b = c("x", "y", "z", "x", "y"),
    c = c(TRUE, FALSE, TRUE, FALSE, TRUE),
    d = 6:10
  )
  result <- s_select(df, where(~ is.numeric(.x) | is.logical(.x)))
  expect_equal(ncol(result), 3)
  expect_equal(names(result), c("a", "c", "d"))
})

test_that("s_select: numeric column indices", {
  df <- tibble(a = 1:5, b = 6:10, c = 11:15, d = 16:20, e = 21:25)
  result <- s_select(df, 1, 3, 5)
  expect_equal(ncol(result), 3)
  expect_equal(names(result), c("a", "c", "e"))
})

test_that("s_select: column range with :", {
  df <- tibble(a = 1:5, b = 6:10, c = 11:15, d = 16:20)
  result <- s_select(df, b:d)
  expect_equal(ncol(result), 3)
  expect_equal(names(result), c("b", "c", "d"))
})

test_that("s_select: everything()", {
  df <- tibble(x = 1:5, y = 6:10, z = 11:15)
  result <- s_select(df, everything())
  expect_equal(ncol(result), 3)
})

# ============================================================================
# CHALLENGING TESTS - Mixed Selection Types
# ============================================================================

test_that("s_select: mix of named columns and expressions", {
  df <- tibble(x = 1:5, y = 6:10, z = 11:15)
  result <- s_select(df, x, doubled_y = y * 2)
  expect_equal(ncol(result), 2)
  expect_equal(names(result), c("x", "doubled_y"))
  expect_equal(result$doubled_y, c(12, 14, 16, 18, 20))
})

test_that("s_select: mix of selection and computed columns", {
  df <- tibble(
    temp_1 = 1:5,
    temp_2 = 6:10,
    pressure_1 = 11:15,
    pressure_2 = 16:20
  )
  # First select temp columns, then add computed column in separate step
  result <- df %>%
    s_select(starts_with("temp")) %>%
    mutate(total_pressure = df$pressure_1 + df$pressure_2)
  expect_equal(ncol(result), 3)
})

# ============================================================================
# CHALLENGING TESTS - Error Handling
# ============================================================================

test_that("s_select: non-existent column gives informative error", {
  df <- tibble(x = 1:5, y = 6:10)
  expect_error(s_select(df, z), "Neither.*select.*mutate")
})

test_that("s_select: invalid expression gives informative error", {
  df <- tibble(x = 1:5, y = 6:10)
  expect_error(s_select(df, nonexistent_func(x)), "Neither.*select.*mutate")
})

test_that("s_select: NULL data frame errors", {
  expect_error(s_select(NULL, x))
})

test_that("s_select: empty selection after filtering gives empty result", {
  df <- tibble(x = 1:5, y = 6:10, z = 11:15)
  result <- s_select(df, starts_with("nonexistent"))
  expect_equal(ncol(result), 0)
  expect_equal(nrow(result), 5)
})

# ============================================================================
# CHALLENGING TESTS - Edge Cases
# ============================================================================

test_that("s_select: single row data frame", {
  df <- tibble(x = 1, y = 2, z = 3)
  result <- s_select(df, x, z)
  expect_equal(nrow(result), 1)
  expect_equal(ncol(result), 2)
})

test_that("s_select: zero row data frame", {
  df <- tibble(x = numeric(0), y = numeric(0))
  result <- s_select(df, x)
  expect_equal(nrow(result), 0)
  expect_equal(ncol(result), 1)
})

test_that("s_select: many columns", {
  df <- as_tibble(replicate(100, 1:10), .name_repair = "minimal")
  names(df) <- paste0("var", 1:100)
  result <- s_select(df, var1, var50, var100)
  expect_equal(ncol(result), 3)
})

test_that("s_select: special characters in column names", {
  df <- tibble(
    `var with spaces` = 1:5,
    `var.with.dots` = 6:10,
    `var_with_underscores` = 11:15
  )
  result <- s_select(df, `var with spaces`)
  expect_equal(ncol(result), 1)
})

test_that("s_select: selecting same column multiple times", {
  df <- tibble(x = 1:5, y = 6:10)
  result <- s_select(df, x, x, y)
  # dplyr allows duplicate selections
  expect_true(ncol(result) >= 2)
})

# ============================================================================
# CHALLENGING TESTS - Data Type Handling
# ============================================================================

test_that("s_select: preserves data types", {
  df <- tibble(
    int_col = 1:5,
    dbl_col = c(1.5, 2.5, 3.5, 4.5, 5.5),
    chr_col = letters[1:5],
    fct_col = factor(letters[1:5]),
    logi_col = c(TRUE, FALSE, TRUE, FALSE, TRUE),
    date_col = seq(as.Date("2024-01-01"), by = "day", length.out = 5)
  )
  result <- s_select(df, everything())
  expect_type(result$int_col, "integer")
  expect_type(result$dbl_col, "double")
  expect_type(result$chr_col, "character")
  expect_s3_class(result$fct_col, "factor")
  expect_type(result$logi_col, "logical")
  expect_s3_class(result$date_col, "Date")
})

test_that("s_select: handles list columns", {
  df <- tibble(
    x = 1:3,
    y = I(list(1:2, 3:4, 5:6))
  )
  result <- s_select(df, y)
  expect_equal(ncol(result), 1)
  expect_type(result$y, "list")
})

test_that("s_select: handles matrix columns", {
  df <- tibble(x = 1:3)
  df$y <- matrix(1:6, nrow = 3)
  result <- s_select(df, y)
  expect_equal(ncol(result), 1)
  expect_true(is.matrix(result$y))
})

# ============================================================================
# CHALLENGING TESTS - Real-world Scenarios
# ============================================================================

test_that("s_select: survey data variable selection", {
  survey <- tibble(
    respondent_id = 1:100,
    q1_satisfaction = sample(1:5, 100, replace = TRUE),
    q2_recommend = sample(c("Yes", "No", "Maybe"), 100, replace = TRUE),
    q3_age_group = sample(
      c("18-25", "26-35", "36-50", "50+"),
      100,
      replace = TRUE
    ),
    completion_time = runif(100, 1, 10)
  )

  # Select only question columns
  questions <- s_select(survey, starts_with("q"))
  expect_equal(ncol(questions), 3)

  # Calculate satisfaction score
  satisfaction_with_id <- s_select(
    survey,
    respondent_id,
    is_satisfied = q1_satisfaction >= 4
  )
  expect_equal(ncol(satisfaction_with_id), 2)
  expect_type(satisfaction_with_id$is_satisfied, "logical")
})

test_that("s_select: financial data analysis", {
  financial <- tibble(
    date = seq(as.Date("2024-01-01"), by = "day", length.out = 30),
    open_price = cumsum(rnorm(30, 0.1, 1)) + 100,
    close_price = cumsum(rnorm(30, 0.1, 1)) + 101,
    volume = sample(1000000:10000000, 30)
  )

  result <- s_select(
    financial,
    date,
    price_range = close_price - open_price,
    volume_millions = volume / 1e6
  )

  expect_equal(ncol(result), 3)
  expect_equal(result$price_range, financial$close_price - financial$open_price)
})

test_that("s_select: feature engineering for modeling", {
  data <- tibble(
    x1 = rnorm(100),
    x2 = rnorm(100),
    x3 = rnorm(100),
    target = rnorm(100)
  )

  features <- s_select(
    data,
    x1,
    x2,
    x3,
    x1_sq = x1^2,
    x2_sq = x2^2,
    interaction = x1 * x2,
    target
  )

  expect_equal(ncol(features), 7)
  expect_equal(features$x1_sq, data$x1^2)
  expect_equal(features$interaction, data$x1 * data$x2)
})

# ============================================================================
# CHALLENGING TESTS - data.table Compatibility
# ============================================================================

test_that("s_select: works with data.table input", {
  skip_if_not_installed("data.table")
  dt <- data.table::data.table(x = 1:5, y = 6:10, z = 11:15)
  result <- s_select(dt, x, z)
  expect_s3_class(result, "data.table")
  expect_equal(ncol(result), 2)
})

# ============================================================================
# CHALLENGING TESTS - Performance
# ============================================================================

test_that("s_select: handles wide data frames efficiently", {
  df <- as_tibble(replicate(1000, rnorm(100)), .name_repair = "minimal")
  names(df) <- paste0("var", 1:1000)

  start_time <- Sys.time()
  result <- s_select(df, where(~ mean(.x) > 0))
  end_time <- Sys.time()

  expect_s3_class(result, "tbl_df")
  expect_true(as.numeric(end_time - start_time) < 5) # Should complete in 5 seconds
})
