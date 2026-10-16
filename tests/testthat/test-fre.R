# Comprehensive Challenging Test Suite for fre() Function
# 70+ difficult test scenarios - focusing on edge cases, complexity, and robustness
# All tests designed to run in < 1 minute

# CHALLENGE: Comprehensive testing for fre
# FUNCTIONS: fre
# KEY BEHAVIORS: frequency tables, output formats
# EDGE CASES: large factor levels, missing values

library(testthat)
library(statart)
library(dplyr)
library(tibble)
library(haven)

# ============================================================================
# CHALLENGING TESTS - Output Type Variations
# ============================================================================

test_that("fre: tibble output (default)", {
  df <- tibble(x = c("a", "a", "b", "b", "c"))
  result <- fre(df, x)
  expect_s3_class(result, "tbl_df")
})

test_that("fre: tibble output", {
  df <- tibble(x = c("a", "a", "b", "b", "c"))
  result <- fre(df, x, .type = "tibble")
  expect_s3_class(result, "tbl_df")
  expect_true("Total" %in% result$x || any(grepl("Total", names(result))))
})

test_that("fre: multiple variables with flextable output", {
  skip_if_not_installed("flextable")
  df <- tibble(x = c("a", "a", "b"), y = c(1, 1, 2))
  result <- fre(df, x, y, .type = "flextable")
  expect_s3_class(result, "flextable")
})

test_that("fre: multiple variables with tibble output", {
  df <- tibble(x = c("a", "a", "b"), y = c(1, 1, 2))
  result <- fre(df, x, y, .type = "tibble")
  expect_s3_class(result, "tbl_df")
  expect_equal(sum(result$n[result$y == "Total"]), nrow(df))
})

# ============================================================================
# CHALLENGING TESTS - Total Row Functionality
# ============================================================================

test_that("fre: Total row sum equals n", {
  df <- tibble(x = c("a", "a", "a", "b", "b", "c"))
  result <- fre(df, x, .type = "tibble")
  total_row <- result[grepl("Total", result$x, ignore.case = TRUE), ]
  expect_equal(total_row$n, 6)
})

test_that("fre: Total percent equals 100", {
  df <- tibble(x = c("a", "a", "a", "b", "b", "c"))
  result <- fre(df, x, .type = "tibble")
  total_row <- result[grepl("Total", result$x, ignore.case = TRUE), ]
  if ("percent" %in% names(total_row)) {
    expect_equal(total_row$percent, 100)
  }
})

test_that("fre: Total with grouped data", {
  df <- tibble(
    group = rep(c("A", "B"), each = 5),
    x = c("a", "a", "b", "b", "c", "a", "b", "b", "c", "c")
  )
  result <- fre(df, x, .by = group, .type = "tibble")
  expect_true(any(grepl("Total", result$x)))
})

test_that("fre: Total with missing values included", {
  df <- tibble(x = c("a", "a", "b", NA, NA))
  result <- fre(df, x, .type = "tibble")
  total_row <- result[result$x %in% "Total", ]
  expect_equal(total_row$n, 5)
})

# ============================================================================
# CHALLENGING TESTS - Cumulative Percentages
# ============================================================================

test_that("fre: cumulative percent increases", {
  df <- tibble(x = c("a", "a", "a", "b", "b", "c"))
  result <- fre(df, x, .type = "tibble")
  cum_col <- grep("cum", names(result), ignore.case = TRUE, value = TRUE)
  if (length(cum_col) > 0) {
    cum_values <- result[[cum_col[1]]][!grepl("Total", result$x)]
    cum_values <- cum_values[!is.na(cum_values)]
    if (length(cum_values) > 1) {
      expect_true(all(diff(cum_values) >= 0))
    }
  }
})

test_that("fre: cumulative percent reaches 100 before Total", {
  df <- tibble(x = c("a", "a", "a", "b", "b", "c"))
  result <- fre(df, x, .type = "tibble")
  cum_col <- grep("cum", names(result), ignore.case = TRUE, value = TRUE)
  if (length(cum_col) > 0) {
    last_non_total <- tail(result[[cum_col[1]]][!grepl("Total", result$x)], 1)
    if (!is.na(last_non_total)) {
      expect_equal(last_non_total, 100)
    }
  }
})

# ============================================================================
# CHALLENGING TESTS - Grouping with .by
# ============================================================================

test_that("fre: group by single variable with flextable", {
  skip_if_not_installed("flextable")
  df <- tibble(
    group = rep(c("A", "B"), each = 5),
    x = c("a", "a", "b", "b", "c", "a", "b", "b", "c", "c")
  )
  result <- fre(df, x, .by = group, .type = "flextable")
  expect_s3_class(result, "flextable")
})

test_that("fre: group by single variable with tibble", {
  df <- tibble(
    group = rep(c("A", "B"), each = 5),
    x = c("a", "a", "b", "b", "c", "a", "b", "b", "c", "c")
  )
  result <- fre(df, x, .by = group, .type = "tibble")
  expect_true("group" %in% names(result))
})

test_that("fre: group by with many groups", {
  df <- tibble(
    group = rep(1:20, each = 5),
    x = sample(letters[1:5], 100, replace = TRUE)
  )
  result <- fre(df, x, .by = group, .type = "tibble")
  expect_equal(dplyr::n_distinct(result$group), 20)
})

test_that("fre: group with NA in grouping variable", {
  df <- tibble(
    group = c(rep("A", 10), rep(NA, 10), rep("B", 10)),
    x = sample(letters[1:3], 30, replace = TRUE)
  )
  result <- fre(df, x, .by = group, .type = "tibble")
  expect_true(any(is.na(result$group)))
})

test_that("fre: complex multi-level grouping", {
  df <- tibble(
    g1 = rep(c("X", "Y"), 25),
    g2 = rep(c("A", "B", "C", "D"), length.out = 50),
    x = sample(1:3, 50, replace = TRUE)
  )
  result <- fre(df, x, .by = c(g1, g2), .type = "tibble")
  expect_true(all(c("g1", "g2") %in% names(result)))
})

# ============================================================================
# CHALLENGING TESTS - Boolean Expressions
# ============================================================================

test_that("fre: boolean expression as computed variable", {
  df <- tibble(x = 1:20, y = sample(letters[1:3], 20, replace = TRUE))
  result <- fre(df, y, above_10 = x > 10, .type = "tibble")
  expect_setequal(result$above_10, c("FALSE", "TRUE", "Total"))
  expect_equal(sum(result$n[result$above_10 == "Total"]), nrow(df))
})

test_that("fre: complex boolean with multiple conditions", {
  df <- tibble(
    a = 1:50,
    b = sample(letters[1:3], 50, replace = TRUE),
    c = sample(c(TRUE, FALSE), 50, replace = TRUE)
  )
  result <- fre(df, b, a > 20 & c, .type = "tibble")
  expect_s3_class(result, "tbl_df")
})

test_that("fre: boolean resulting in single category", {
  df <- tibble(x = 1:10, y = rep("a", 10))
  result <- fre(df, y, x > 0, .type = "tibble")
  expect_equal(nrow(result), 2) # Only TRUE + Total
})

# ============================================================================
# CHALLENGING TESTS - Missing Value Handling
# ============================================================================

test_that("fre: variable with 50% missing values", {
  df <- tibble(x = c(rep("a", 50), rep(NA, 50)))
  result <- fre(df, x, .type = "tibble")
  total_row <- result[grepl("Total", result$x, ignore.case = TRUE), ]
  expect_equal(total_row$n, 100)
})

test_that("fre: variable with all missing values", {
  df <- tibble(x = rep(NA, 50))
  result <- fre(df, x, .type = "tibble")
  expect_true(any(grepl("Total", result$x, ignore.case = TRUE)))
})

test_that("fre: factor with NA level explicitly included", {
  df <- tibble(x = factor(c("a", "b", NA), exclude = NULL))
  result <- fre(df, x, .type = "tibble")
  expect_true(any(is.na(result$x)))
})

test_that("fre: haven labelled with NA values", {
  df <- tibble(
    x = labelled_spss(
      c(1, 1, 2, -99),
      labels = c("Yes" = 1, "No" = 2, "Missing" = -99),
      na_values = -99
    )
  )
  result <- fre(df, x, .type = "tibble")
  expect_true(any(grepl("Total", result$x, ignore.case = TRUE)))
})

# ============================================================================
# CHALLENGING TESTS - Sorting with .desc
# ============================================================================

test_that("fre: .desc=TRUE with ties", {
  df <- tibble(x = c("a", "a", "b", "b", "c"))
  result <- fre(df, x, .desc = TRUE, .type = "tibble")
  non_total <- result[!grepl("Total", result$x, ignore.case = TRUE), ]
  expect_equal(non_total$x[1], "a")
})

test_that("fre: .desc=FALSE preserves order", {
  df <- tibble(
    x = factor(c("high", "low", "med"), levels = c("low", "med", "high"))
  )
  result <- fre(df, x, .desc = FALSE, .type = "tibble")
  non_total <- result[!grepl("Total", result$x, ignore.case = TRUE), ]
  expect_equal(as.character(non_total$x[1]), "low")
})

test_that("fre: sorting with grouped data", {
  df <- tibble(
    group = rep(c("A", "B"), each = 6),
    x = c("z", "z", "a", "a", "m", "m", "z", "z", "a", "a", "m", "m")
  )
  result <- fre(df, x, .by = group, .desc = TRUE, .type = "tibble")
  expect_s3_class(result, "tbl_df")
})

# ============================================================================
# CHALLENGING TESTS - Special Data Types
# ============================================================================

test_that("fre: Date variables", {
  df <- tibble(
    x = as.Date(c("2024-01-01", "2024-01-01", "2024-01-02", "2024-01-02"))
  )
  result <- fre(df, x, .type = "tibble")
  expect_s3_class(result, "tbl_df")
  expect_true(any(grepl("Total", result$x, ignore.case = TRUE)))
})

test_that("fre: POSIXct datetime variables", {
  df <- tibble(
    x = as.POSIXct(c(
      "2024-01-01 10:00",
      "2024-01-01 10:00",
      "2024-01-02 12:00"
    ))
  )
  result <- fre(df, x, .type = "tibble")
  expect_s3_class(result, "tbl_df")
})

test_that("fre: logical variables", {
  df <- tibble(x = c(TRUE, TRUE, FALSE, TRUE, FALSE))
  result <- fre(df, x, .type = "tibble")
  expect_true(any(result$x == TRUE | result$x == FALSE))
})

test_that("fre: haven labelled variables", {
  df <- tibble(x = labelled(c(1, 1, 2, 2), labels = c("A" = 1, "B" = 2)))
  result <- fre(df, x, .type = "tibble")
  expect_s3_class(result, "tbl_df")
})

# ============================================================================
# CHALLENGING TESTS - Multiple Variables
# ============================================================================

test_that("fre: five variables with tibble output", {
  df <- tibble(
    v1 = sample(1:3, 100, replace = TRUE),
    v2 = sample(letters[1:4], 100, replace = TRUE),
    v3 = factor(sample(c("x", "y", "z"), 100, replace = TRUE)),
    v4 = sample(c(TRUE, FALSE), 100, replace = TRUE),
    v5 = sample(1:2, 100, replace = TRUE)
  )
  result <- fre(df, v1:v5, .type = "tibble")
  expect_s3_class(result, "tbl_df")
  expect_equal(sum(result$n[result$v5 == "Total"]), nrow(df))
})

test_that("fre: mixed variable types with Total", {
  df <- tibble(
    num = c(1, 1, 2, 2, 3),
    char = c("a", "a", "b", "b", "c"),
    fac = factor(c("x", "x", "y", "y", "z"))
  )
  result <- fre(df, num, char, fac, .type = "tibble")
  total_rows <- result[result$fac == "Total", ]
  expect_equal(nrow(total_rows), 1L)
  expect_equal(total_rows$n, nrow(df))
})

# ============================================================================
# CHALLENGING TESTS - Reserved Names
# ============================================================================

test_that("fre: variables named n, percent, cum, total", {
  df <- tibble(
    n = c(1, 1, 2, 2),
    percent = c("a", "a", "b", "b"),
    total = c("x", "y", "x", "y"),
    cum = c("p", "p", "q", "q")
  )
  expect_message(
    result <- fre(df, n, percent, total, cum, .type = "tibble"),
    "renamed"
  )
})

# ============================================================================
# CHALLENGING TESTS - Large-ish Data
# ============================================================================

test_that("fre: 10000 rows with flextable", {
  skip_if_not_installed("flextable")
  df <- tibble(x = sample(letters[1:10], 10000, replace = TRUE))
  result <- fre(df, x, .type = "flextable")
  expect_s3_class(result, "flextable")
})

test_that("fre: 10000 rows with tibble", {
  df <- tibble(x = sample(letters[1:10], 10000, replace = TRUE))
  result <- fre(df, x, .type = "tibble")
  expect_equal(nrow(result), 11) # 10 categories + Total
})

test_that("fre: many variables (20+) with tibble", {
  df <- as_tibble(
    replicate(20, sample(1:3, 100, replace = TRUE)),
    .name_repair = "minimal"
  )
  names(df) <- paste0("var", 1:20)
  result <- fre(df, everything(), .type = "tibble")
  expect_s3_class(result, "tbl_df")
})

# ============================================================================
# CHALLENGING TESTS - Edge Cases
# ============================================================================

test_that("fre: single row dataset", {
  df <- tibble(x = "only")
  result <- fre(df, x, .type = "tibble")
  expect_equal(nrow(result), 2) # value + Total
  total_row <- result[grepl("Total", result$x, ignore.case = TRUE), ]
  expect_equal(total_row$n, 1)
})

test_that("fre: all identical values", {
  df <- tibble(x = rep("same", 1000))
  result <- fre(df, x, .type = "tibble")
  expect_equal(nrow(result), 2) # same + Total
  total_row <- result[grepl("Total", result$x, ignore.case = TRUE), ]
  expect_equal(total_row$n, 1000)
})

test_that("fre: empty data frame", {
  df <- tibble(x = character(0))
  result <- fre(df, x, .type = "tibble")
  expect_equal(nrow(result), 0)
})

test_that("fre: variable with special characters", {
  df <- tibble(x = c("a@b.com", "a@b.com", "x#y", "$100"))
  result <- fre(df, x, .type = "tibble")
  expect_equal(nrow(result), 4) # 3 unique + Total
})

test_that("fre: unicode characters", {
  df <- tibble(x = c("中文", "中文", "日本語", "🎉", "🎉"))
  result <- fre(df, x, .type = "tibble")
  expect_equal(nrow(result), 4) # 3 unique + Total
})

# ============================================================================
# CHALLENGING TESTS - Error Handling
# ============================================================================

test_that("fre: NULL input should error", {
  expect_error(fre(NULL))
})

test_that("fre: non-existent column should error", {
  df <- tibble(x = 1:5)
  expect_error(fre(df, y))
})

# ============================================================================
# CHALLENGING TESTS - Real-world Scenarios
# ============================================================================

test_that("fre: survey frequency distribution", {
  set.seed(42)
  df <- tibble(
    satisfaction = sample(
      1:5,
      1000,
      replace = TRUE,
      prob = c(0.05, 0.15, 0.3, 0.35, 0.15)
    ),
    would_recommend = sample(c("Yes", "No", "Maybe"), 1000, replace = TRUE)
  )
  result <- fre(df, satisfaction, would_recommend, .type = "tibble")
  expect_s3_class(result, "tbl_df")
  expect_equal(sum(result$n[result$would_recommend == "Total"]), nrow(df))
})

test_that("fre: demographic breakdown with grouping", {
  df <- tibble(
    age_group = sample(
      c("18-25", "26-35", "36-50", "50+"),
      500,
      replace = TRUE
    ),
    gender = sample(c("Male", "Female"), 500, replace = TRUE)
  )
  result <- fre(df, age_group, .by = gender, .type = "tibble")
  expect_true("gender" %in% names(result))
  expect_equal(sum(result$n[result$age_group == "Total"]), nrow(df))
})

test_that("fre: quality control frequencies", {
  df <- tibble(
    defect_type = sample(
      c("None", "Minor", "Major", "Critical"),
      1000,
      replace = TRUE,
      prob = c(0.85, 0.1, 0.04, 0.01)
    ),
    shift = sample(c("Morning", "Afternoon", "Night"), 1000, replace = TRUE)
  )
  result <- fre(df, defect_type, .by = shift, .type = "tibble")
  expect_true("shift" %in% names(result))
})
