# Comprehensive Challenging Test Suite for tab2() Function
# 70+ difficult test scenarios - focusing on edge cases, complexity, and robustness
# All tests designed to run in < 1 minute

# CHALLENGE: Comprehensive testing for tab2
# FUNCTIONS: tab2
# KEY BEHAVIORS: two-way tables
# EDGE CASES: empty cells, marginal totals

library(testthat)
library(statart)
library(dplyr)
library(tibble)
library(haven)

# ============================================================================
# CHALLENGING TESTS - Basic Cross-tabulation Complexity
# ============================================================================

test_that("tab2: two numeric variables", {
  df <- tibble(
    x = rep(1:5, each = 4),
    y = rep(1:4, 5)
  )
  result <- tab2(df, x, y)
  expect_equal(nrow(result), 5)
  expect_setequal(names(result)[-1], as.character(unique(df$y)))
  expect_equal(
    unname(colSums(as.matrix(result[-1]))),
    as.numeric(table(df$y)[names(result)[-1]])
  )
  expect_equal(sum(as.matrix(result[-1])), 20)
})

test_that("tab2: two character variables", {
  df <- tibble(
    row_var = rep(c("A", "B", "C", "D"), each = 3),
    col_var = rep(c("X", "Y", "Z"), 4)
  )
  result <- tab2(df, row_var, col_var)
  expect_equal(nrow(result), 4)
  expect_setequal(names(result)[-1], as.character(unique(df$col_var)))
  expect_equal(
    unname(colSums(as.matrix(result[-1]))),
    as.numeric(table(df$col_var)[names(result)[-1]])
  )
})

test_that("tab2: numeric row, character column", {
  df <- tibble(
    age_group = rep(1:5, each = 20),
    gender = sample(c("M", "F"), 100, replace = TRUE)
  )
  result <- tab2(df, age_group, gender)
  expect_equal(nrow(result), 5)
  expect_setequal(names(result)[-1], as.character(unique(df$gender)))
  expect_equal(
    unname(colSums(as.matrix(result[-1]))),
    as.numeric(table(df$gender)[names(result)[-1]])
  )
})

test_that("tab2: factor row, numeric column", {
  df <- tibble(
    treatment = factor(rep(c("Control", "Drug A", "Drug B"), each = 30)),
    response_score = sample(1:10, 90, replace = TRUE)
  )
  result <- tab2(df, treatment, response_score)
  expect_s3_class(result[[1]], "factor")
})

# ============================================================================
# CHALLENGING TESTS - Flip Parameter
# ============================================================================

test_that("tab2: .flip=TRUE swaps row and column variables", {
  df <- tibble(
    x = rep(c("A", "B"), 10),
    y = rep(c("X", "Y", "Z"), length.out = 20)
  )
  result_normal <- tab2(df, x, y)
  result_flipped <- tab2(df, x, y, .flip = TRUE)
  expect_equal(nrow(result_normal), ncol(result_flipped) - 1)
  expect_equal(ncol(result_normal) - 1, nrow(result_flipped))
})

test_that("tab2: flip with many levels", {
  df <- tibble(
    rows = rep(letters[1:10], each = 5),
    cols = rep(LETTERS[1:5], 10)
  )
  result <- tab2(df, rows, cols, .flip = TRUE)
  expect_equal(nrow(result), 5)
  expect_setequal(names(result)[-1], as.character(unique(df$rows)))
  expect_equal(
    unname(colSums(as.matrix(result[-1]))),
    as.numeric(table(df$rows)[names(result)[-1]])
  )
})

test_that("tab2: flip preserves cell values", {
  df <- tibble(
    x = c("A", "A", "B", "B"),
    y = c("X", "Y", "X", "Y")
  )
  result1 <- tab2(df, x, y)
  result2 <- tab2(df, x, y, .flip = TRUE)
  expect_equal(
    unname(as.matrix(result1[-1])),
    unname(t(as.matrix(result2[-1])))
  )
  expect_equal(sum(as.matrix(result1[-1])), nrow(df))
})

# ============================================================================
# CHALLENGING TESTS - Missing Value Handling
# ============================================================================

test_that("tab2: NAs in row variable only", {
  df <- tibble(
    x = c(NA, NA, 1, 1, 2, 2, NA),
    y = c("a", "b", "a", "b", "a", "b", "a")
  )
  result <- tab2(df, x, y)
  expect_true(any(is.na(result[[1]])))
})

test_that("tab2: NAs in column variable only", {
  df <- tibble(
    x = c(1, 1, 2, 2, 3, 3),
    y = c("a", NA, "b", NA, "a", "b")
  )
  result <- tab2(df, x, y)
  expect_true(any(grepl("NA", names(result))))
})

test_that("tab2: NAs in both variables", {
  df <- tibble(
    x = c(1, NA, 2, NA, 1),
    y = c("a", "b", NA, NA, "a")
  )
  result <- tab2(df, x, y)
  expect_true(nrow(result) >= 2)
  expect_true(ncol(result) >= 3)
})

test_that("tab2: all rows have at least one NA", {
  df <- tibble(
    x = c(1, NA, 2, NA),
    y = c(NA, "a", NA, "b")
  )
  result <- tab2(df, x, y)
  expect_setequal(names(result)[-1], c("a", "b", "NA"))
  expect_equal(result$`NA`[!is.na(result[[1]])], c(1, 1))
  expect_equal(result$a[is.na(result[[1]])], 1)
  expect_equal(result$b[is.na(result[[1]])], 1)
  expect_equal(sum(as.matrix(result[-1])), nrow(df))
})

test_that("tab2: factor with NA level", {
  df <- tibble(
    x = factor(c("a", "b", NA), exclude = NULL),
    y = c("x", "y", "x")
  )
  result <- tab2(df, x, y)
  # An explicit NA factor level has a valid code, unlike a missing factor code.
  expect_equal(levels(result[[1]]), levels(df$x))
  expect_equal(as.integer(result[[1]]), 1:3)
  expect_equal(rowSums(as.matrix(result[-1])), rep(1, 3))
})

# ============================================================================
# CHALLENGING TESTS - Edge Cases & Extremes
# ============================================================================

test_that("tab2: single row dataset", {
  df <- tibble(x = "A", y = "X")
  result <- tab2(df, x, y)
  expect_equal(nrow(result), 1)
  expect_setequal(names(result)[-1], as.character(unique(df$y)))
  expect_equal(
    unname(colSums(as.matrix(result[-1]))),
    as.numeric(table(df$y)[names(result)[-1]])
  )
  expect_equal(result$X, 1)
})

test_that("tab2: all identical values", {
  df <- tibble(x = rep("same", 100), y = rep("value", 100))
  result <- tab2(df, x, y)
  expect_equal(nrow(result), 1)
  expect_setequal(names(result)[-1], as.character(unique(df$y)))
  expect_equal(
    unname(colSums(as.matrix(result[-1]))),
    as.numeric(table(df$y)[names(result)[-1]])
  )
  expect_equal(result$value, 100)
})

test_that("tab2: row var all unique, column var few levels", {
  df <- tibble(
    x = 1:100,
    y = rep(c("A", "B"), 50)
  )
  result <- tab2(df, x, y)
  expect_equal(nrow(result), 100)
  expect_setequal(names(result)[-1], as.character(unique(df$y)))
  expect_equal(
    unname(colSums(as.matrix(result[-1]))),
    as.numeric(table(df$y)[names(result)[-1]])
  )
})

test_that("tab2: row var few levels, column var all unique", {
  df <- tibble(
    x = rep(c("A", "B"), 50),
    y = 1:100
  )
  result <- tab2(df, x, y)
  expect_equal(nrow(result), 2)
  expect_setequal(names(result)[-1], as.character(unique(df$y)))
  expect_equal(
    unname(colSums(as.matrix(result[-1]))),
    as.numeric(table(df$y)[names(result)[-1]])
  )
})

test_that("tab2: both variables all unique", {
  df <- tibble(x = 1:50, y = 51:100)
  result <- tab2(df, x, y)
  expect_equal(nrow(result), 50)
  expect_setequal(names(result)[-1], as.character(unique(df$y)))
  expect_equal(
    unname(colSums(as.matrix(result[-1]))),
    as.numeric(table(df$y)[names(result)[-1]])
  )
  expect_true(all(as.matrix(result[-1]) %in% c(0, 1)))
  expect_equal(rowSums(as.matrix(result[-1])), rep(1, nrow(df)))
})

test_that("tab2: empty data frame", {
  df <- tibble(x = character(0), y = character(0))
  result <- tab2(df, x, y)
  expect_equal(nrow(result), 0)
})

# ============================================================================
# CHALLENGING TESTS - Large-ish Data
# ============================================================================

test_that("tab2: 10x10 cross-tabulation", {
  set.seed(42)
  df <- tibble(
    x = sample(1:10, 1000, replace = TRUE),
    y = sample(letters[1:10], 1000, replace = TRUE)
  )
  result <- tab2(df, x, y)
  expect_equal(nrow(result), 10)
  expect_setequal(names(result)[-1], as.character(unique(df$y)))
  expect_equal(
    unname(colSums(as.matrix(result[-1]))),
    as.numeric(table(df$y)[names(result)[-1]])
  )
  expect_equal(sum(as.matrix(result[-1])), 1000)
})

test_that("tab2: 50x5 cross-tabulation", {
  set.seed(42)
  df <- tibble(
    x = sample(1:50, 500, replace = TRUE),
    y = sample(LETTERS[1:5], 500, replace = TRUE)
  )
  result <- tab2(df, x, y)
  expect_equal(nrow(result), 50)
  expect_setequal(names(result)[-1], as.character(unique(df$y)))
  expect_equal(
    unname(colSums(as.matrix(result[-1]))),
    as.numeric(table(df$y)[names(result)[-1]])
  )
})

test_that("tab2: 5x50 cross-tabulation", {
  set.seed(42)
  df <- tibble(
    x = sample(LETTERS[1:5], 500, replace = TRUE),
    y = sample(1:50, 500, replace = TRUE)
  )
  result <- tab2(df, x, y)
  expect_equal(nrow(result), 5)
  expect_setequal(names(result)[-1], as.character(unique(df$y)))
  expect_equal(
    unname(colSums(as.matrix(result[-1]))),
    as.numeric(table(df$y)[names(result)[-1]])
  )
})

test_that("tab2: sparse cross-tabulation with many empty cells", {
  set.seed(42)
  df <- tibble(
    x = sample(1:20, 100, replace = TRUE),
    y = sample(1:20, 100, replace = TRUE)
  )
  result <- tab2(df, x, y)
  zero_cells <- sum(result == 0, na.rm = TRUE)
  expect_true(zero_cells > 0)
})

# ============================================================================
# CHALLENGING TESTS - Special Characters & Unicode
# ============================================================================

test_that("tab2: unicode characters in both dimensions", {
  df <- tibble(
    x = c("中文", "中文", "日本語", "日本語"),
    y = c("مرحبا", "مرحبا", "שלום", "שלום")
  )
  result <- tab2(df, x, y)
  expect_equal(nrow(result), 2)
  expect_setequal(names(result)[-1], as.character(unique(df$y)))
  expect_equal(
    unname(colSums(as.matrix(result[-1]))),
    as.numeric(table(df$y)[names(result)[-1]])
  )
})

test_that("tab2: emoji as values", {
  df <- tibble(
    emotion = c("🎉", "🎉", "😢", "😢", "🎉"),
    category = c("A", "B", "A", "B", "A")
  )
  result <- tab2(df, emotion, category)
  expect_equal(nrow(result), 2)
  expect_setequal(names(result)[-1], as.character(unique(df$category)))
  expect_equal(
    unname(colSums(as.matrix(result[-1]))),
    as.numeric(table(df$category)[names(result)[-1]])
  )
})

test_that("tab2: special whitespace characters", {
  df <- tibble(
    x = c("a", "a", "b", " ", " "),
    y = c("x", "x", "y", "z", "z")
  )
  result <- tab2(df, x, y)
  expect_true(any(result[[1]] == " " | result[[1]] == ""))
})

test_that("tab2: mixed scripts in same variable", {
  df <- tibble(
    lang = c("English", "中文", "English", "日本語"),
    region = c("US", "Asia", "UK", "Asia")
  )
  result <- tab2(df, lang, region)
  expect_equal(nrow(result), 3)
  expect_equal(ncol(result), 4)
})

# ============================================================================
# CHALLENGING TESTS - Type Coercion
# ============================================================================

test_that("tab2: Date vs character", {
  df <- tibble(
    date = as.Date(c("2024-01-01", "2024-01-01", "2024-01-02", "2024-01-02")),
    status = c("Active", "Inactive", "Active", "Inactive")
  )
  result <- tab2(df, date, status)
  expect_s3_class(result[[1]], "Date")
  expect_setequal(names(result)[-1], as.character(unique(df$status)))
  expect_equal(
    unname(colSums(as.matrix(result[-1]))),
    as.numeric(table(df$status)[names(result)[-1]])
  )
})

test_that("tab2: logical vs numeric", {
  df <- tibble(
    flag = c(TRUE, TRUE, FALSE, FALSE, TRUE),
    value = c(1, 2, 1, 2, 1)
  )
  result <- tab2(df, flag, value)
  expect_equal(nrow(result), 2)
  expect_setequal(names(result)[-1], as.character(unique(df$value)))
  expect_equal(
    unname(colSums(as.matrix(result[-1]))),
    as.numeric(table(df$value)[names(result)[-1]])
  )
})

test_that("tab2: ordered factor vs regular factor", {
  df <- tibble(
    size = ordered(c("S", "M", "L", "S", "M"), levels = c("S", "M", "L")),
    color = factor(c("Red", "Blue", "Red", "Blue", "Red"))
  )
  result <- tab2(df, size, color)
  expect_s3_class(result[[1]], "ordered")
})

# ============================================================================
# CHALLENGING TESTS - Error Handling & Robustness
# ============================================================================

test_that("tab2: single variable should error", {
  df <- tibble(x = 1:5)
  expect_error(tab2(df, x))
})

test_that("tab2: three variables should error", {
  df <- tibble(x = 1:5, y = 1:5, z = 1:5)
  expect_error(tab2(df, x, y, z))
})

test_that("tab2: NULL input should error", {
  expect_error(tab2(NULL))
})

test_that("tab2: non-existent column should error", {
  df <- tibble(x = 1:5)
  expect_error(tab2(df, x, y))
})

test_that("tab2: matrix column should error", {
  df <- tibble(x = 1:4)
  df$y <- matrix(1:8, nrow = 4)
  expect_error(tab2(df, x, y))
})

# ============================================================================
# CHALLENGING TESTS - Numeric Edge Cases
# ============================================================================

test_that("tab2: Inf and -Inf values", {
  df <- tibble(
    x = c(Inf, Inf, -Inf, -Inf, 0),
    y = c("A", "B", "A", "B", "A")
  )
  result <- tab2(df, x, y)
  expect_true(Inf %in% result[[1]] || -Inf %in% result[[1]])
})

test_that("tab2: very large numbers", {
  df <- tibble(
    x = c(1e200, 1e200, 2e200, 2e200),
    y = c("A", "B", "A", "B")
  )
  result <- tab2(df, x, y)
  expect_equal(nrow(result), 2)
})

test_that("tab2: very small numbers near zero", {
  df <- tibble(
    x = c(1e-300, 1e-300, 2e-300, 2e-300),
    y = c("A", "B", "A", "B")
  )
  result <- tab2(df, x, y)
  expect_equal(nrow(result), 2)
})

test_that("tab2: mixed numeric classes (integer vs double)", {
  df <- tibble(
    int_col = c(1L, 1L, 2L, 2L),
    dbl_col = c(1.0, 1.0, 2.0, 2.0)
  )
  result <- tab2(df, int_col, dbl_col)
  expect_equal(nrow(result), 2)
  expect_setequal(names(result)[-1], as.character(unique(df$dbl_col)))
  expect_equal(
    unname(colSums(as.matrix(result[-1]))),
    as.numeric(table(df$dbl_col)[names(result)[-1]])
  )
})

# ============================================================================
# CHALLENGING TESTS - Real-world Scenarios
# ============================================================================

test_that("tab2: clinical trial data", {
  df <- tibble(
    treatment = sample(c("Drug", "Placebo"), 200, replace = TRUE),
    response = sample(c("Complete", "Partial", "None"), 200, replace = TRUE)
  )
  result <- tab2(df, treatment, response)
  expect_equal(nrow(result), 2)
  expect_setequal(names(result)[-1], as.character(unique(df$response)))
  expect_equal(
    unname(colSums(as.matrix(result[-1]))),
    as.numeric(table(df$response)[names(result)[-1]])
  )
  expect_equal(sum(as.matrix(result[-1])), 200)
})

test_that("tab2: demographic breakdown", {
  df <- tibble(
    age_group = sample(c("18-25", "26-35", "36-50", "50+"), 500, replace = TRUE),
    gender = sample(c("Male", "Female", "Other"), 500, replace = TRUE)
  )
  result <- tab2(df, age_group, gender)
  expect_equal(nrow(result), 4)
  expect_setequal(names(result)[-1], as.character(unique(df$gender)))
  expect_equal(
    unname(colSums(as.matrix(result[-1]))),
    as.numeric(table(df$gender)[names(result)[-1]])
  )
})

test_that("tab2: time series cross-tab", {
  df <- tibble(
    quarter = rep(c("Q1", "Q2", "Q3", "Q4"), each = 25),
    region = sample(c("North", "South", "East", "West"), 100, replace = TRUE)
  )
  result <- tab2(df, quarter, region)
  expect_equal(nrow(result), 4)
  expect_setequal(names(result)[-1], as.character(unique(df$region)))
  expect_equal(
    unname(colSums(as.matrix(result[-1]))),
    as.numeric(table(df$region)[names(result)[-1]])
  )
})

test_that("tab2: survey cross-tabulation", {
  df <- tibble(
    question_1 = sample(c("Yes", "No", "Maybe"), 300, replace = TRUE),
    question_2 = sample(c("Agree", "Disagree", "Neutral"), 300, replace = TRUE)
  )
  result <- tab2(df, question_1, question_2)
  expect_equal(nrow(result), 3)
  expect_setequal(names(result)[-1], as.character(unique(df$question_2)))
  expect_equal(
    unname(colSums(as.matrix(result[-1]))),
    as.numeric(table(df$question_2)[names(result)[-1]])
  )
})

# ============================================================================
# CHALLENGING TESTS - Factor Level Handling
# ============================================================================

test_that("tab2: factor with unused levels", {
  df <- tibble(
    x = factor(c("a", "b"), levels = c("a", "b", "c", "d")),
    y = factor(c("x", "y"), levels = c("x", "y", "z"))
  )
  result <- tab2(df, x, y)
  expect_equal(nrow(result), 2)
  expect_equal(ncol(result), 3)  # Row key and two observed column levels.
  expect_equal(result[[1]], df$x)
  expect_equal(sort(unlist(result[-1], use.names = FALSE)), c(0L, 0L, 1L, 1L))
})

test_that("tab2: factor levels not alphabetically ordered", {
  df <- tibble(
    x = factor(c("High", "Med", "Low"), levels = c("Low", "Med", "High")),
    y = c("A", "B", "A")
  )
  result <- tab2(df, x, y)
  expect_equal(as.character(result[[1]][1]), "Low")
})

test_that("tab2: numeric factor vs character", {
  df <- tibble(
    score = factor(c(1, 2, 1, 2), levels = c(3, 2, 1)),
    pass = c("Yes", "No", "Yes", "No")
  )
  result <- tab2(df, score, pass)
  expect_s3_class(result[[1]], "factor")
})

# ============================================================================
# CHALLENGING TESTS - Tidyselect Integration
# ============================================================================

test_that("tab2: using numeric column positions", {
  df <- tibble(a = 1:4, x = 1:4, b = 1:4, y = c("A", "B", "A", "B"))
  result <- tab2(df, 2, 4)
  expect_equal(nrow(result), 4)
})

test_that("tab2: last_col() selection", {
  df <- tibble(x = 1:4, y = c("A", "B", "A", "B"), z = 1:4)
  result <- tab2(df, 1, last_col())
  expect_equal(ncol(result), 5)
})

test_that("tab2: everything() with two columns", {
  df <- tibble(x = c("A", "B", "A", "B"), y = c(1, 2, 1, 2))
  result <- tab2(df, everything())
  expect_equal(nrow(result), 2)
  expect_setequal(names(result)[-1], as.character(unique(df$y)))
  expect_equal(
    unname(colSums(as.matrix(result[-1]))),
    as.numeric(table(df$y)[names(result)[-1]])
  )
})
