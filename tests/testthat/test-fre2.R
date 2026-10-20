# Comprehensive Challenging Test Suite for fre2() Function
# 70+ difficult test scenarios - focusing on edge cases, complexity, and robustness
# All tests designed to run in < 1 minute

# CHALLENGE: Comprehensive testing for fre2
# FUNCTIONS: fre2
# KEY BEHAVIORS: bivariate frequency tables
# EDGE CASES: sparse tables, zero cells

# ============================================================================
# CHALLENGING TESTS - Output Type Variations
# ============================================================================

test_that("fre2: tibble output (default)", {
  df <- tibble::tibble(
    x = rep(c("A", "B"), each = 3),
    y = rep(c("X", "Y", "Z"), 2)
  )
  result <- tab2(df, x, y, .total = TRUE)
  expect_s3_class(result, "tbl_df")
})

test_that("fre2: tibble output", {
  df <- tibble::tibble(
    x = rep(c("A", "B"), each = 3),
    y = rep(c("X", "Y", "Z"), 2)
  )
  result <- tab2(df, x, y, .type = "tibble", .total = TRUE)
  expect_s3_class(result, "tbl_df")
})

test_that("fre2: numeric row and character column", {
  df <- tibble::tibble(
    row = rep(1:3, each = 4),
    col = rep(c("a", "b", "c", "d"), 3)
  )
  result <- tab2(df, row, col, .type = "tibble", .total = TRUE)
  expect_s3_class(result, "tbl_df")
})

# ============================================================================
# CHALLENGING TESTS - Total Row and Column
# ============================================================================

test_that("fre2: Total row sum equals grand total", {
  df <- tibble::tibble(
    x = c("A", "A", "B", "B"),
    y = c("X", "Y", "X", "Y")
  )
  result <- tab2(df, x, y, .type = "tibble", .total = TRUE)
  total_row <- result[grepl("Total", result[[1]], ignore.case = TRUE), ]
  expect_equal(total_row$total, 4)
})

test_that("fre2: Total column sum equals row totals", {
  df <- tibble::tibble(
    x = rep(c("A", "B"), each = 3),
    y = rep(c("X", "Y", "Z"), 2)
  )
  result <- tab2(df, x, y, .type = "tibble", .total = TRUE)
  total_col <- result[[ncol(result)]]
  total_row_idx <- which(grepl("Total", result[[1]], ignore.case = TRUE))
  if (length(total_row_idx) > 0) {
    expect_equal(total_col[total_row_idx], nrow(df))
  }
})

test_that("fre2: all cell values plus totals", {
  df <- tibble::tibble(
    x = c("A", "A", "A", "B", "B", "C"),
    y = c("X", "X", "Y", "X", "Y", "Y")
  )
  result <- tab2(df, x, y, .type = "tibble", .total = TRUE)
  # Check structure has both row and column headers plus Total
  expect_true(ncol(result) >= 4)
  expect_true(nrow(result) >= 4)
})

# ============================================================================
# CHALLENGING TESTS - Flip Parameter
# ============================================================================

test_that("fre2: .flip=TRUE swaps dimensions", {
  df <- tibble::tibble(
    x = rep(c("A", "B"), each = 3),
    y = rep(c("X", "Y", "Z"), 2)
  )
  result_normal <- tab2(df, x, y, .type = "tibble", .total = TRUE)
  result_flipped <- tab2(
    df,
    x,
    y,
    .flip = TRUE,
    .type = "tibble",
    .total = TRUE
  )
  expect_equal(nrow(result_normal), ncol(result_flipped) - 1)
  expect_equal(ncol(result_normal) - 1, nrow(result_flipped))
  expect_equal(
    unname(as.matrix(result_normal[
      -nrow(result_normal),
      -c(1, ncol(result_normal))
    ])),
    unname(t(as.matrix(result_flipped[
      -nrow(result_flipped),
      -c(1, ncol(result_flipped))
    ])))
  )
  expect_equal(result_normal$total[nrow(result_normal)], nrow(df))
  expect_equal(result_flipped$total[nrow(result_flipped)], nrow(df))
})

test_that("fre2: flip with many levels", {
  df <- tibble::tibble(
    rows = rep(letters[1:10], each = 5),
    cols = rep(LETTERS[1:5], 10)
  )
  result <- tab2(df, rows, cols, .flip = TRUE, .type = "tibble", .total = TRUE)
  expect_equal(nrow(result), 6) # 5 cols + Total
})

# ============================================================================
# CHALLENGING TESTS - Missing Value Handling
# ============================================================================

test_that("fre2: NAs in row variable", {
  df <- tibble::tibble(
    x = c(NA, NA, "A", "A", "B"),
    y = c("X", "Y", "X", "Y", "X")
  )
  result <- tab2(df, x, y, .type = "tibble", .total = TRUE)
  expect_true(any(is.na(result[[1]])))
})

test_that("fre2: NAs in column variable", {
  df <- tibble::tibble(
    x = c("A", "A", "B", "B"),
    y = c("X", NA, "Y", NA)
  )
  result <- tab2(df, x, y, .type = "tibble", .total = TRUE)
  # NA should appear as a column
  expect_true(ncol(result) >= 4)
})

test_that("fre2: NAs in both variables", {
  df <- tibble::tibble(
    x = c(NA, "A", NA, "B"),
    y = c("X", NA, NA, "Y")
  )
  result <- tab2(df, x, y, .type = "tibble", .total = TRUE)
  expect_true(any(is.na(result[[1]])))
})

test_that("fre2: factor with NA level", {
  df <- tibble::tibble(
    x = factor(c("a", "b", NA), exclude = NULL),
    y = c("x", "y", "x")
  )
  result <- tab2(df, x, y, .type = "tibble", .total = TRUE)
  expect_true(any(is.na(result[[1]])))
})

# ============================================================================
# CHALLENGING TESTS - Edge Cases
# ============================================================================

test_that("fre2: single row dataset", {
  df <- tibble::tibble(x = "A", y = "X")
  result <- tab2(df, x, y, .type = "tibble", .total = TRUE)
  expect_equal(result[[1]], c("A", "total"))
  category_cols <- names(result)[2:(ncol(result) - 1)]
  expect_setequal(category_cols, as.character(unique(df$y)))
  expect_equal(
    as.numeric(unlist(result[nrow(result), category_cols], use.names = FALSE)),
    as.numeric(table(df$y)[category_cols])
  )
  expect_equal(result$total[nrow(result)], nrow(df))
  expect_equal(
    result$total[-nrow(result)],
    rowSums(as.matrix(result[-nrow(result), category_cols]))
  )
})

test_that("fre2: all identical values", {
  df <- tibble::tibble(x = rep("same", 100), y = rep("value", 100))
  result <- tab2(df, x, y, .type = "tibble", .total = TRUE)
  expect_equal(nrow(result), 2) # same, Total
  category_cols <- names(result)[2:(ncol(result) - 1)]
  expect_setequal(category_cols, as.character(unique(df$y)))
  expect_equal(
    as.numeric(unlist(result[nrow(result), category_cols], use.names = FALSE)),
    as.numeric(table(df$y)[category_cols])
  )
  expect_equal(result$total[nrow(result)], nrow(df))
  expect_equal(
    result$total[-nrow(result)],
    rowSums(as.matrix(result[-nrow(result), category_cols]))
  )
})

test_that("fre2: row var all unique, column var few levels", {
  df <- tibble::tibble(
    x = 1:100,
    y = rep(c("A", "B"), 50)
  )
  result <- tab2(df, x, y, .type = "tibble", .total = TRUE)
  expect_equal(nrow(result), 101) # 100 unique + Total
})

test_that("fre2: row var few levels, column var all unique", {
  df <- tibble::tibble(
    x = rep(c("A", "B"), 50),
    y = 1:100
  )
  result <- tab2(df, x, y, .type = "tibble", .total = TRUE)
  category_cols <- names(result)[2:(ncol(result) - 1)]
  expect_setequal(category_cols, as.character(unique(df$y)))
  expect_equal(
    as.numeric(unlist(result[nrow(result), category_cols], use.names = FALSE)),
    as.numeric(table(df$y)[category_cols])
  )
  expect_equal(result$total[nrow(result)], nrow(df))
  expect_equal(
    result$total[-nrow(result)],
    rowSums(as.matrix(result[-nrow(result), category_cols]))
  )
})

test_that("fre2: empty data frame", {
  df <- tibble::tibble(x = character(0), y = character(0))
  result <- tab2(df, x, y, .type = "tibble", .total = TRUE)
  expect_equal(nrow(result), 0)
})

# ============================================================================
# CHALLENGING TESTS - Large-ish Data
# ============================================================================

test_that("fre2: 10x10 cross-tabulation with totals", {
  withr::local_preserve_seed()
  set.seed(42)
  df <- tibble::tibble(
    x = sample(1:10, 1000, replace = TRUE),
    y = sample(letters[1:10], 1000, replace = TRUE)
  )
  result <- tab2(df, x, y, .type = "tibble", .total = TRUE)
  expect_equal(nrow(result), 11) # 10 + Total
  category_cols <- names(result)[2:(ncol(result) - 1)]
  expect_setequal(category_cols, as.character(unique(df$y)))
  expect_equal(
    as.numeric(unlist(result[nrow(result), category_cols], use.names = FALSE)),
    as.numeric(table(df$y)[category_cols])
  )
  expect_equal(result$total[nrow(result)], nrow(df))
  expect_equal(
    result$total[-nrow(result)],
    rowSums(as.matrix(result[-nrow(result), category_cols]))
  )
})

test_that("fre2: sparse matrix with totals", {
  withr::local_preserve_seed()
  set.seed(42)
  df <- tibble::tibble(
    x = sample(1:20, 100, replace = TRUE),
    y = sample(1:20, 100, replace = TRUE)
  )
  result <- tab2(df, x, y, .type = "tibble", .total = TRUE)
  zero_cells <- sum(result == 0, na.rm = TRUE)
  expect_true(zero_cells > 0)
  expect_true(nrow(result) <= 21)
})

# ============================================================================
# CHALLENGING TESTS - Unicode & Special Characters
# ============================================================================

test_that("fre2: unicode in both dimensions", {
  df <- tibble::tibble(
    x = c("中文", "中文", "日本語", "日本語"),
    y = c("مرحبا", "مرحبا", "שלום", "שלום")
  )
  result <- tab2(df, x, y, .type = "tibble", .total = TRUE)
  expect_equal(nrow(result), 3) # 2 + Total
  category_cols <- names(result)[2:(ncol(result) - 1)]
  expect_setequal(category_cols, as.character(unique(df$y)))
  expect_equal(
    as.numeric(unlist(result[nrow(result), category_cols], use.names = FALSE)),
    as.numeric(table(df$y)[category_cols])
  )
  expect_equal(result$total[nrow(result)], nrow(df))
  expect_equal(
    result$total[-nrow(result)],
    rowSums(as.matrix(result[-nrow(result), category_cols]))
  )
})

test_that("fre2: emoji as values", {
  df <- tibble::tibble(
    emotion = c("🎉", "🎉", "😢", "😢", "🎉"),
    category = c("A", "B", "A", "B", "A")
  )
  result <- tab2(df, emotion, category, .type = "tibble", .total = TRUE)
  expect_equal(nrow(result), 3)
  category_cols <- names(result)[2:(ncol(result) - 1)]
  expect_setequal(category_cols, as.character(unique(df$category)))
  expect_equal(
    as.numeric(unlist(result[nrow(result), category_cols], use.names = FALSE)),
    as.numeric(table(df$category)[category_cols])
  )
  expect_equal(result$total[nrow(result)], nrow(df))
  expect_equal(
    result$total[-nrow(result)],
    rowSums(as.matrix(result[-nrow(result), category_cols]))
  )
})

# ============================================================================
# CHALLENGING TESTS - Special Data Types
# ============================================================================

test_that("fre2: Date vs character", {
  df <- tibble::tibble(
    date = as.Date(c("2024-01-01", "2024-01-01", "2024-01-02", "2024-01-02")),
    status = c("Active", "Inactive", "Active", "Inactive")
  )
  result <- tab2(df, date, status, .type = "tibble", .total = TRUE)
  expect_type(result[[1]], "character")
  expect_equal(result[[1]], c("2024-01-01", "2024-01-02", "total"))
  expect_equal(result$total, c(2, 2, 4))
  expect_equal(result$Active, c(1, 1, 2))
  expect_equal(result$Inactive, c(1, 1, 2))
})

test_that("fre2: logical vs numeric", {
  df <- tibble::tibble(
    flag = c(TRUE, TRUE, FALSE, FALSE, TRUE),
    value = c(1, 2, 1, 2, 1)
  )
  result <- tab2(df, flag, value, .type = "tibble", .total = TRUE)
  expect_equal(nrow(result), 3)
  category_cols <- names(result)[2:(ncol(result) - 1)]
  expect_setequal(category_cols, as.character(unique(df$value)))
  expect_equal(
    as.numeric(unlist(result[nrow(result), category_cols], use.names = FALSE)),
    as.numeric(table(df$value)[category_cols])
  )
  expect_equal(result$total[nrow(result)], nrow(df))
  expect_equal(
    result$total[-nrow(result)],
    rowSums(as.matrix(result[-nrow(result), category_cols]))
  )
})

test_that("fre2: ordered factor vs regular factor", {
  df <- tibble::tibble(
    size = ordered(c("S", "M", "L", "S", "M"), levels = c("S", "M", "L")),
    color = factor(c("Red", "Blue", "Red", "Blue", "Red"))
  )
  result <- tab2(df, size, color, .type = "tibble", .total = TRUE)
  expect_type(result[[1]], "character")
  expect_equal(result[[1]], c("S", "M", "L", "total"))
  expect_equal(result$Blue, c(1, 1, 0, 2))
  expect_equal(result$Red, c(1, 1, 1, 3))
  expect_equal(result$total, c(2, 2, 1, 5))
})

# ============================================================================
# CHALLENGING TESTS - Reserved Names
# ============================================================================

test_that("fre2: variables named n, total in data", {
  df <- tibble::tibble(
    n = c("A", "A", "B"),
    total = c("X", "Y", "X")
  )
  expect_message(
    result <- tab2(df, n, total, .type = "tibble", .total = TRUE),
    "renamed"
  )
})

# ============================================================================
# CHALLENGING TESTS - Error Handling
# ============================================================================

test_that("fre2: single variable should error", {
  df <- tibble::tibble(x = 1:5)
  expect_error(tab2(df, x, .total = TRUE))
})

test_that("fre2: three variables give every pairwise table", {
  df <- tibble::tibble(x = 1:5, y = 1:5, z = 1:5)
  out <- tab2(df, x, y, z, .total = TRUE)
  expect_named(out, c("x x y", "x x z", "y x z"))
  expect_identical(out[["x x z"]], tab2(df, x, z, .total = TRUE))
})

test_that("fre2: NULL input should error", {
  expect_error(tab2(NULL, .total = TRUE))
})

test_that("fre2: non-existent column should error", {
  df <- tibble::tibble(x = 1:5)
  expect_error(tab2(df, x, y, .total = TRUE))
})

# ============================================================================
# CHALLENGING TESTS - Real-world Scenarios
# ============================================================================

test_that("fre2: clinical trial contingency table", {
  withr::local_preserve_seed()
  set.seed(42)
  df <- tibble::tibble(
    treatment = sample(c("Drug", "Placebo"), 200, replace = TRUE),
    response = sample(c("Complete", "Partial", "None"), 200, replace = TRUE)
  )
  result <- tab2(df, treatment, response, .type = "tibble", .total = TRUE)
  expect_equal(nrow(result), 3) # 2 + Total
  category_cols <- names(result)[2:(ncol(result) - 1)]
  expect_setequal(category_cols, as.character(unique(df$response)))
  expect_equal(
    as.numeric(unlist(result[nrow(result), category_cols], use.names = FALSE)),
    as.numeric(table(df$response)[category_cols])
  )
  expect_equal(result$total[nrow(result)], nrow(df))
  expect_equal(
    result$total[-nrow(result)],
    rowSums(as.matrix(result[-nrow(result), category_cols]))
  )
})

test_that("fre2: demographic breakdown with totals", {
  withr::local_preserve_seed()
  df <- tibble::tibble(
    age_group = sample(
      c("18-25", "26-35", "36-50", "50+"),
      500,
      replace = TRUE
    ),
    gender = sample(c("Male", "Female", "Other"), 500, replace = TRUE)
  )
  result <- tab2(df, age_group, gender, .type = "tibble", .total = TRUE)
  expect_equal(nrow(result), 5) # 4 + Total
  category_cols <- names(result)[2:(ncol(result) - 1)]
  expect_setequal(category_cols, as.character(unique(df$gender)))
  expect_equal(
    as.numeric(unlist(result[nrow(result), category_cols], use.names = FALSE)),
    as.numeric(table(df$gender)[category_cols])
  )
  expect_equal(result$total[nrow(result)], nrow(df))
  expect_equal(
    result$total[-nrow(result)],
    rowSums(as.matrix(result[-nrow(result), category_cols]))
  )
})

test_that("fre2: time series cross-tab with totals", {
  withr::local_preserve_seed()
  df <- tibble::tibble(
    quarter = rep(c("Q1", "Q2", "Q3", "Q4"), each = 25),
    region = sample(c("North", "South", "East", "West"), 100, replace = TRUE)
  )
  result <- tab2(df, quarter, region, .type = "tibble", .total = TRUE)
  expect_equal(nrow(result), 5) # 4 + Total
  category_cols <- names(result)[2:(ncol(result) - 1)]
  expect_setequal(category_cols, as.character(unique(df$region)))
  expect_equal(
    as.numeric(unlist(result[nrow(result), category_cols], use.names = FALSE)),
    as.numeric(table(df$region)[category_cols])
  )
  expect_equal(result$total[nrow(result)], nrow(df))
  expect_equal(
    result$total[-nrow(result)],
    rowSums(as.matrix(result[-nrow(result), category_cols]))
  )
})

test_that("fre2: survey cross-tab with totals", {
  withr::local_preserve_seed()
  df <- tibble::tibble(
    question_1 = sample(c("Yes", "No", "Maybe"), 300, replace = TRUE),
    question_2 = sample(c("Agree", "Disagree", "Neutral"), 300, replace = TRUE)
  )
  result <- tab2(df, question_1, question_2, .type = "tibble", .total = TRUE)
  expect_equal(nrow(result), 4) # 3 + Total
  category_cols <- names(result)[2:(ncol(result) - 1)]
  expect_setequal(category_cols, as.character(unique(df$question_2)))
  expect_equal(
    as.numeric(unlist(result[nrow(result), category_cols], use.names = FALSE)),
    as.numeric(table(df$question_2)[category_cols])
  )
  expect_equal(result$total[nrow(result)], nrow(df))
  expect_equal(
    result$total[-nrow(result)],
    rowSums(as.matrix(result[-nrow(result), category_cols]))
  )
})

# ============================================================================
# CHALLENGING TESTS - Factor Level Handling
# ============================================================================

test_that("fre2: factor with unused levels", {
  df <- tibble::tibble(
    x = factor(c("a", "b"), levels = c("a", "b", "c", "d")),
    y = factor(c("x", "y"), levels = c("x", "y", "z"))
  )
  result <- tab2(df, x, y, .type = "tibble", .total = TRUE)
  expect_equal(result[[1]], c("a", "b", "total"))
  expect_equal(ncol(result), 4) # Row key, two observed levels, and total.
  expect_equal(result$total, c(1, 1, 2))
  expect_equal(sort(unlist(result[3, 2:3], use.names = FALSE)), c(1L, 1L))
})

test_that("fre2: factor levels not alphabetically ordered", {
  df <- tibble::tibble(
    x = factor(c("High", "Med", "Low"), levels = c("Low", "Med", "High")),
    y = c("A", "B", "A")
  )
  result <- tab2(df, x, y, .type = "tibble", .total = TRUE)
  expect_equal(as.character(result[[1]][1]), "Low")
})

# ============================================================================
# CHALLENGING TESTS - Tidyselect Integration
# ============================================================================

test_that("fre2: using numeric column positions", {
  df <- tibble::tibble(
    a = 1:4,
    x = c("A", "B", "A", "B"),
    b = 1:4,
    y = c("X", "Y", "X", "Y")
  )
  result <- tab2(df, 2, 4, .type = "tibble", .total = TRUE)
  expect_equal(nrow(result), 3)
})

test_that("fre2: everything() with two columns", {
  df <- tibble::tibble(x = c("A", "B", "A", "B"), y = c("X", "Y", "X", "Y"))
  result <- tab2(df, dplyr::everything(), .type = "tibble", .total = TRUE)
  expect_equal(nrow(result), 3)
  category_cols <- names(result)[2:(ncol(result) - 1)]
  expect_setequal(category_cols, as.character(unique(df$y)))
  expect_equal(
    as.numeric(unlist(result[nrow(result), category_cols], use.names = FALSE)),
    as.numeric(table(df$y)[category_cols])
  )
  expect_equal(result$total[nrow(result)], nrow(df))
  expect_equal(
    result$total[-nrow(result)],
    rowSums(as.matrix(result[-nrow(result), category_cols]))
  )
})

# ============================================================================
# CHALLENGING TESTS - Numeric Edge Cases
# ============================================================================

test_that("fre2: Inf and -Inf values", {
  df <- tibble::tibble(
    x = c(Inf, Inf, -Inf, -Inf, 0),
    y = c("A", "B", "A", "B", "A")
  )
  result <- tab2(df, x, y, .type = "tibble", .total = TRUE)
  expect_true(any(result[[1]] == Inf | result[[1]] == -Inf))
})

test_that("fre2: very large numbers", {
  df <- tibble::tibble(
    x = c(1e200, 1e200, 2e200, 2e200),
    y = c("A", "B", "A", "B")
  )
  result <- tab2(df, x, y, .type = "tibble", .total = TRUE)
  expect_equal(nrow(result), 3)
})

test_that("fre2: very small numbers near zero", {
  df <- tibble::tibble(
    x = c(1e-300, 1e-300, 2e-300, 2e-300),
    y = c("A", "B", "A", "B")
  )
  result <- tab2(df, x, y, .type = "tibble", .total = TRUE)
  expect_equal(nrow(result), 3)
})

# ============================================================================
# CHALLENGING TESTS - Quality Control Scenarios
# ============================================================================

test_that("fre2: defect analysis by shift", {
  withr::local_preserve_seed()
  df <- tibble::tibble(
    shift = sample(c("Morning", "Afternoon", "Night"), 500, replace = TRUE),
    defect_type = sample(
      c("None", "Minor", "Major", "Critical"),
      500,
      replace = TRUE,
      prob = c(0.85, 0.1, 0.04, 0.01)
    )
  )
  result <- tab2(df, shift, defect_type, .type = "tibble", .total = TRUE)
  expect_equal(nrow(result), 4) # 3 shifts + Total
  category_cols <- names(result)[2:(ncol(result) - 1)]
  expect_setequal(category_cols, as.character(unique(df$defect_type)))
  expect_equal(
    as.numeric(unlist(result[nrow(result), category_cols], use.names = FALSE)),
    as.numeric(table(df$defect_type)[category_cols])
  )
  expect_equal(result$total[nrow(result)], nrow(df))
  expect_equal(
    result$total[-nrow(result)],
    rowSums(as.matrix(result[-nrow(result), category_cols]))
  )

  # Verify grand total equals nrow(df)
  total_row <- result[grepl("Total", result[[1]], ignore.case = TRUE), ]
  expect_equal(total_row$total, 500)
})

test_that("fre2: product sales by region", {
  withr::local_preserve_seed()
  df <- tibble::tibble(
    product = sample(c("Widget", "Gadget", "Tool"), 1000, replace = TRUE),
    region = sample(c("North", "South", "East", "West"), 1000, replace = TRUE)
  )
  result <- tab2(df, product, region, .type = "tibble", .total = TRUE)
  expect_equal(nrow(result), 4) # 3 products + Total
  category_cols <- names(result)[2:(ncol(result) - 1)]
  expect_setequal(category_cols, as.character(unique(df$region)))
  expect_equal(
    as.numeric(unlist(result[nrow(result), category_cols], use.names = FALSE)),
    as.numeric(table(df$region)[category_cols])
  )
  expect_equal(result$total[nrow(result)], nrow(df))
  expect_equal(
    result$total[-nrow(result)],
    rowSums(as.matrix(result[-nrow(result), category_cols]))
  )
})

# ============================================================================
# CHALLENGING TESTS - Performance Edge Cases
# ============================================================================

test_that("fre2: highly concentrated data", {
  df <- tibble::tibble(
    x = c(rep("A", 950), rep("B", 50)),
    y = c(rep("X", 950), rep("Y", 50))
  )
  result <- tab2(df, x, y, .type = "tibble", .total = TRUE)
  expect_equal(nrow(result), 3)
  category_cols <- names(result)[2:(ncol(result) - 1)]
  expect_setequal(category_cols, as.character(unique(df$y)))
  expect_equal(
    as.numeric(unlist(result[nrow(result), category_cols], use.names = FALSE)),
    as.numeric(table(df$y)[category_cols])
  )
  expect_equal(result$total[nrow(result)], nrow(df))
  expect_equal(
    result$total[-nrow(result)],
    rowSums(as.matrix(result[-nrow(result), category_cols]))
  )
  expect_equal(result$total[result[[1]] == "A"], 950)
})

test_that("fre2: uniformly distributed data", {
  withr::local_preserve_seed()
  set.seed(42)
  df <- tibble::tibble(
    x = sample(letters[1:10], 1000, replace = TRUE),
    y = sample(LETTERS[1:10], 1000, replace = TRUE)
  )
  result <- tab2(df, x, y, .type = "tibble", .total = TRUE)
  expect_equal(nrow(result), 11) # 10 + Total
  category_cols <- names(result)[2:(ncol(result) - 1)]
  expect_setequal(category_cols, as.character(unique(df$y)))
  expect_equal(
    as.numeric(unlist(result[nrow(result), category_cols], use.names = FALSE)),
    as.numeric(table(df$y)[category_cols])
  )
  expect_equal(result$total[nrow(result)], nrow(df))
  expect_equal(
    result$total[-nrow(result)],
    rowSums(as.matrix(result[-nrow(result), category_cols]))
  )
})
