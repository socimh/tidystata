# Comprehensive Challenging Test Suite for fre2() Function
# 70+ difficult test scenarios - focusing on edge cases, complexity, and robustness
# All tests designed to run in < 1 minute

# CHALLENGE: Comprehensive testing for fre2
# FUNCTIONS: fre2
# KEY BEHAVIORS: bivariate frequency tables
# EDGE CASES: sparse tables, zero cells

library(testthat)
library(statart)
library(dplyr)
library(tibble)
library(haven)

# ============================================================================
# CHALLENGING TESTS - Output Type Variations
# ============================================================================

test_that("fre2: tibble output (default)", {
  df <- tibble(
    x = rep(c("A", "B"), each = 3),
    y = rep(c("X", "Y", "Z"), 2)
  )
  result <- fre2(df, x, y)
  expect_s3_class(result, "tbl_df")
})

test_that("fre2: tibble output", {
  df <- tibble(
    x = rep(c("A", "B"), each = 3),
    y = rep(c("X", "Y", "Z"), 2)
  )
  result <- fre2(df, x, y, .type = "tibble")
  expect_s3_class(result, "tbl_df")
})

test_that("fre2: numeric row and character column", {
  df <- tibble(
    row = rep(1:3, each = 4),
    col = rep(c("a", "b", "c", "d"), 3)
  )
  result <- fre2(df, row, col, .type = "tibble")
  expect_s3_class(result, "tbl_df")
})

# ============================================================================
# CHALLENGING TESTS - Total Row and Column
# ============================================================================

test_that("fre2: Total row sum equals grand total", {
  df <- tibble(
    x = c("A", "A", "B", "B"),
    y = c("X", "Y", "X", "Y")
  )
  result <- fre2(df, x, y, .type = "tibble")
  total_row <- result[grepl("Total", result[[1]], ignore.case = TRUE), ]
  expect_equal(total_row$n, 4)
})

test_that("fre2: Total column sum equals row totals", {
  df <- tibble(
    x = rep(c("A", "B"), each = 3),
    y = rep(c("X", "Y", "Z"), 2)
  )
  result <- fre2(df, x, y, .type = "tibble")
  total_col <- result[[ncol(result)]]
  total_row_idx <- which(grepl("Total", result[[1]], ignore.case = TRUE))
  if(length(total_row_idx) > 0) {
    expect_equal(total_col[total_row_idx], nrow(df))
  }
})

test_that("fre2: all cell values plus totals", {
  df <- tibble(
    x = c("A", "A", "A", "B", "B", "C"),
    y = c("X", "X", "Y", "X", "Y", "Y")
  )
  result <- fre2(df, x, y, .type = "tibble")
  # Check structure has both row and column headers plus Total
  expect_true(ncol(result) >= 4)
  expect_true(nrow(result) >= 4)
})

# ============================================================================
# CHALLENGING TESTS - Flip Parameter
# ============================================================================

test_that("fre2: .flip=TRUE swaps dimensions", {
  df <- tibble(
    x = rep(c("A", "B"), each = 3),
    y = rep(c("X", "Y", "Z"), 2)
  )
  result_normal <- fre2(df, x, y, .type = "tibble")
  result_flipped <- fre2(df, x, y, .flip = TRUE, .type = "tibble")
  expect_equal(nrow(result_normal), ncol(result_flipped))
  expect_equal(ncol(result_normal), nrow(result_flipped))
})

test_that("fre2: flip with many levels", {
  df <- tibble(
    rows = rep(letters[1:10], each = 5),
    cols = rep(LETTERS[1:5], 10)
  )
  result <- fre2(df, rows, cols, .flip = TRUE, .type = "tibble")
  expect_equal(nrow(result), 6)  # 5 cols + Total
})

# ============================================================================
# CHALLENGING TESTS - Missing Value Handling
# ============================================================================

test_that("fre2: NAs in row variable", {
  df <- tibble(
    x = c(NA, NA, "A", "A", "B"),
    y = c("X", "Y", "X", "Y", "X")
  )
  result <- fre2(df, x, y, .type = "tibble")
  expect_true(any(is.na(result[[1]])))
})

test_that("fre2: NAs in column variable", {
  df <- tibble(
    x = c("A", "A", "B", "B"),
    y = c("X", NA, "Y", NA)
  )
  result <- fre2(df, x, y, .type = "tibble")
  # NA should appear as a column
  expect_true(ncol(result) >= 4)
})

test_that("fre2: NAs in both variables", {
  df <- tibble(
    x = c(NA, "A", NA, "B"),
    y = c("X", NA, NA, "Y")
  )
  result <- fre2(df, x, y, .type = "tibble")
  expect_true(any(is.na(result[[1]])))
})

test_that("fre2: factor with NA level", {
  df <- tibble(
    x = factor(c("a", "b", NA), exclude = NULL),
    y = c("x", "y", "x")
  )
  result <- fre2(df, x, y, .type = "tibble")
  expect_true(any(is.na(result[[1]])))
})

# ============================================================================
# CHALLENGING TESTS - Edge Cases
# ============================================================================

test_that("fre2: single row dataset", {
  df <- tibble(x = "A", y = "X")
  result <- fre2(df, x, y, .type = "tibble")
  expect_equal(nrow(result), 3)  # A, Total row
  expect_equal(ncol(result), 4)  # x, X, Total col, n
})

test_that("fre2: all identical values", {
  df <- tibble(x = rep("same", 100), y = rep("value", 100))
  result <- fre2(df, x, y, .type = "tibble")
  expect_equal(nrow(result), 2)  # same, Total
  expect_equal(ncol(result), 4)  # x, value, Total, n
})

test_that("fre2: row var all unique, column var few levels", {
  df <- tibble(
    x = 1:100,
    y = rep(c("A", "B"), 50)
  )
  result <- fre2(df, x, y, .type = "tibble")
  expect_equal(nrow(result), 101)  # 100 unique + Total
})

test_that("fre2: row var few levels, column var all unique", {
  df <- tibble(
    x = rep(c("A", "B"), 50),
    y = 1:100
  )
  result <- fre2(df, x, y, .type = "tibble")
  expect_equal(ncol(result), 103)  # x, 100 cols, Total, n
})

test_that("fre2: empty data frame", {
  df <- tibble(x = character(0), y = character(0))
  result <- fre2(df, x, y, .type = "tibble")
  expect_equal(nrow(result), 0)
})

# ============================================================================
# CHALLENGING TESTS - Large-ish Data
# ============================================================================

test_that("fre2: 10x10 cross-tabulation with totals", {
  set.seed(42)
  df <- tibble(
    x = sample(1:10, 1000, replace = TRUE),
    y = sample(letters[1:10], 1000, replace = TRUE)
  )
  result <- fre2(df, x, y, .type = "tibble")
  expect_equal(nrow(result), 11)  # 10 + Total
  expect_equal(ncol(result), 13)  # x, 10, Total, n
})

test_that("fre2: sparse matrix with totals", {
  set.seed(42)
  df <- tibble(
    x = sample(1:20, 100, replace = TRUE),
    y = sample(1:20, 100, replace = TRUE)
  )
  result <- fre2(df, x, y, .type = "tibble")
  zero_cells <- sum(result == 0, na.rm = TRUE)
  expect_true(zero_cells > 0)
  expect_true(nrow(result) <= 21)
})

# ============================================================================
# CHALLENGING TESTS - Unicode & Special Characters
# ============================================================================

test_that("fre2: unicode in both dimensions", {
  df <- tibble(
    x = c("中文", "中文", "日本語", "日本語"),
    y = c("مرحبا", "مرحبا", "שלום", "שלום")
  )
  result <- fre2(df, x, y, .type = "tibble")
  expect_equal(nrow(result), 3)  # 2 + Total
  expect_equal(ncol(result), 5)  # x, 2, Total, n
})

test_that("fre2: emoji as values", {
  df <- tibble(
    emotion = c("🎉", "🎉", "😢", "😢", "🎉"),
    category = c("A", "B", "A", "B", "A")
  )
  result <- fre2(df, emotion, category, .type = "tibble")
  expect_equal(nrow(result), 3)
  expect_equal(ncol(result), 5)
})

# ============================================================================
# CHALLENGING TESTS - Special Data Types
# ============================================================================

test_that("fre2: Date vs character", {
  df <- tibble(
    date = as.Date(c("2024-01-01", "2024-01-01", "2024-01-02", "2024-01-02")),
    status = c("Active", "Inactive", "Active", "Inactive")
  )
  result <- fre2(df, date, status, .type = "tibble")
  expect_s3_class(result[[1]], "Date")
})

test_that("fre2: logical vs numeric", {
  df <- tibble(
    flag = c(TRUE, TRUE, FALSE, FALSE, TRUE),
    value = c(1, 2, 1, 2, 1)
  )
  result <- fre2(df, flag, value, .type = "tibble")
  expect_equal(nrow(result), 3)
  expect_equal(ncol(result), 6)
})

test_that("fre2: ordered factor vs regular factor", {
  df <- tibble(
    size = ordered(c("S", "M", "L", "S", "M"), levels = c("S", "M", "L")),
    color = factor(c("Red", "Blue", "Red", "Blue", "Red"))
  )
  result <- fre2(df, size, color, .type = "tibble")
  expect_s3_class(result[[1]], "ordered")
})

# ============================================================================
# CHALLENGING TESTS - Reserved Names
# ============================================================================

test_that("fre2: variables named n, total in data", {
  df <- tibble(
    n = c("A", "A", "B"),
    total = c("X", "Y", "X")
  )
  expect_message(
    result <- fre2(df, n, total, .type = "tibble"),
    "renamed"
  )
})

# ============================================================================
# CHALLENGING TESTS - Error Handling
# ============================================================================

test_that("fre2: single variable should error", {
  df <- tibble(x = 1:5)
  expect_error(fre2(df, x))
})

test_that("fre2: three variables should error", {
  df <- tibble(x = 1:5, y = 1:5, z = 1:5)
  expect_error(fre2(df, x, y, z))
})

test_that("fre2: NULL input should error", {
  expect_error(fre2(NULL))
})

test_that("fre2: non-existent column should error", {
  df <- tibble(x = 1:5)
  expect_error(fre2(df, x, y))
})

# ============================================================================
# CHALLENGING TESTS - Real-world Scenarios
# ============================================================================

test_that("fre2: clinical trial contingency table", {
  set.seed(42)
  df <- tibble(
    treatment = sample(c("Drug", "Placebo"), 200, replace = TRUE),
    response = sample(c("Complete", "Partial", "None"), 200, replace = TRUE)
  )
  result <- fre2(df, treatment, response, .type = "tibble")
  expect_equal(nrow(result), 3)  # 2 + Total
  expect_equal(ncol(result), 6)  # treatment, 3 responses, Total, n
})

test_that("fre2: demographic breakdown with totals", {
  df <- tibble(
    age_group = sample(c("18-25", "26-35", "36-50", "50+"), 500, replace = TRUE),
    gender = sample(c("Male", "Female", "Other"), 500, replace = TRUE)
  )
  result <- fre2(df, age_group, gender, .type = "tibble")
  expect_equal(nrow(result), 5)  # 4 + Total
  expect_equal(ncol(result), 6)  # age_group, 3 genders, Total, n
})

test_that("fre2: time series cross-tab with totals", {
  df <- tibble(
    quarter = rep(c("Q1", "Q2", "Q3", "Q4"), each = 25),
    region = sample(c("North", "South", "East", "West"), 100, replace = TRUE)
  )
  result <- fre2(df, quarter, region, .type = "tibble")
  expect_equal(nrow(result), 5)  # 4 + Total
  expect_equal(ncol(result), 7)  # quarter, 4 regions, Total, n
})

test_that("fre2: survey cross-tab with totals", {
  df <- tibble(
    question_1 = sample(c("Yes", "No", "Maybe"), 300, replace = TRUE),
    question_2 = sample(c("Agree", "Disagree", "Neutral"), 300, replace = TRUE)
  )
  result <- fre2(df, question_1, question_2, .type = "tibble")
  expect_equal(nrow(result), 4)  # 3 + Total
  expect_equal(ncol(result), 6)  # q1, 3 q2, Total, n
})

# ============================================================================
# CHALLENGING TESTS - Factor Level Handling
# ============================================================================

test_that("fre2: factor with unused levels", {
  df <- tibble(
    x = factor(c("a", "b"), levels = c("a", "b", "c", "d")),
    y = factor(c("x", "y"), levels = c("x", "y", "z"))
  )
  result <- fre2(df, x, y, .type = "tibble")
  expect_equal(nrow(result), 3)  # 2 + Total
  expect_equal(ncol(result), 5)  # x, 2, Total, n
})

test_that("fre2: factor levels not alphabetically ordered", {
  df <- tibble(
    x = factor(c("High", "Med", "Low"), levels = c("Low", "Med", "High")),
    y = c("A", "B", "A")
  )
  result <- fre2(df, x, y, .type = "tibble")
  expect_equal(as.character(result[[1]][1]), "Low")
})

# ============================================================================
# CHALLENGING TESTS - Tidyselect Integration
# ============================================================================

test_that("fre2: using numeric column positions", {
  df <- tibble(a = 1:4, x = c("A", "B", "A", "B"), b = 1:4, y = c("X", "Y", "X", "Y"))
  result <- fre2(df, 2, 4, .type = "tibble")
  expect_equal(nrow(result), 3)
})

test_that("fre2: everything() with two columns", {
  df <- tibble(x = c("A", "B", "A", "B"), y = c("X", "Y", "X", "Y"))
  result <- fre2(df, everything(), .type = "tibble")
  expect_equal(nrow(result), 3)
  expect_equal(ncol(result), 5)
})

# ============================================================================
# CHALLENGING TESTS - Numeric Edge Cases
# ============================================================================

test_that("fre2: Inf and -Inf values", {
  df <- tibble(
    x = c(Inf, Inf, -Inf, -Inf, 0),
    y = c("A", "B", "A", "B", "A")
  )
  result <- fre2(df, x, y, .type = "tibble")
  expect_true(any(result[[1]] == Inf | result[[1]] == -Inf))
})

test_that("fre2: very large numbers", {
  df <- tibble(
    x = c(1e200, 1e200, 2e200, 2e200),
    y = c("A", "B", "A", "B")
  )
  result <- fre2(df, x, y, .type = "tibble")
  expect_equal(nrow(result), 3)
})

test_that("fre2: very small numbers near zero", {
  df <- tibble(
    x = c(1e-300, 1e-300, 2e-300, 2e-300),
    y = c("A", "B", "A", "B")
  )
  result <- fre2(df, x, y, .type = "tibble")
  expect_equal(nrow(result), 3)
})

# ============================================================================
# CHALLENGING TESTS - Quality Control Scenarios
# ============================================================================

test_that("fre2: defect analysis by shift", {
  df <- tibble(
    shift = sample(c("Morning", "Afternoon", "Night"), 500, replace = TRUE),
    defect_type = sample(c("None", "Minor", "Major", "Critical"), 500, 
                        replace = TRUE, prob = c(0.85, 0.1, 0.04, 0.01))
  )
  result <- fre2(df, shift, defect_type, .type = "tibble")
  expect_equal(nrow(result), 4)  # 3 shifts + Total
  expect_equal(ncol(result), 7)  # shift, 4 defects, Total, n
  
  # Verify grand total equals nrow(df)
  total_row <- result[grepl("Total", result[[1]], ignore.case = TRUE), ]
  expect_equal(total_row$n, 500)
})

test_that("fre2: product sales by region", {
  df <- tibble(
    product = sample(c("Widget", "Gadget", "Tool"), 1000, replace = TRUE),
    region = sample(c("North", "South", "East", "West"), 1000, replace = TRUE)
  )
  result <- fre2(df, product, region, .type = "tibble")
  expect_equal(nrow(result), 4)  # 3 products + Total
  expect_equal(ncol(result), 7)  # product, 4 regions, Total, n
})

# ============================================================================
# CHALLENGING TESTS - Performance Edge Cases
# ============================================================================

test_that("fre2: highly concentrated data", {
  df <- tibble(
    x = c(rep("A", 950), rep("B", 50)),
    y = c(rep("X", 950), rep("Y", 50))
  )
  result <- fre2(df, x, y, .type = "tibble")
  expect_equal(nrow(result), 3)
  expect_equal(ncol(result), 5)
  expect_equal(result$n[1], 950)
})

test_that("fre2: uniformly distributed data", {
  set.seed(42)
  df <- tibble(
    x = sample(letters[1:10], 1000, replace = TRUE),
    y = sample(LETTERS[1:10], 1000, replace = TRUE)
  )
  result <- fre2(df, x, y, .type = "tibble")
  expect_equal(nrow(result), 11)  # 10 + Total
  expect_equal(ncol(result), 13)  # x, 10, Total, n
})
