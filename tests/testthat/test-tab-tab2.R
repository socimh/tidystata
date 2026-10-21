# Comprehensive Challenging Test Suite for tab2() Function
# 70+ difficult test scenarios - focusing on edge cases, complexity, and robustness
# All tests designed to run in < 1 minute

# CHALLENGE: Comprehensive testing for tab2
# FUNCTIONS: tab2
# KEY BEHAVIORS: two-way tables
# EDGE CASES: empty cells, marginal totals

# ============================================================================
# CHALLENGING TESTS - Basic Cross-tabulation Complexity
# ============================================================================

test_that("tab2: two numeric variables", {
  df <- tibble::tibble(
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
  df <- tibble::tibble(
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
  withr::local_preserve_seed()
  df <- tibble::tibble(
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
  withr::local_preserve_seed()
  df <- tibble::tibble(
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
  df <- tibble::tibble(
    x = rep(c("A", "B"), 10),
    y = rep(c("X", "Y", "Z"), length.out = 20)
  )
  result_normal <- tab2(df, x, y)
  result_flipped <- tab2(df, x, y, .flip = TRUE)
  expect_equal(nrow(result_normal), ncol(result_flipped) - 1)
  expect_equal(ncol(result_normal) - 1, nrow(result_flipped))
})

test_that("tab2: flip with many levels", {
  df <- tibble::tibble(
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
  df <- tibble::tibble(
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
  df <- tibble::tibble(
    x = c(NA, NA, 1, 1, 2, 2, NA),
    y = c("a", "b", "a", "b", "a", "b", "a")
  )
  result <- tab2(df, x, y)
  expect_true(any(is.na(result[[1]])))
})

test_that("tab2: NAs in column variable only", {
  df <- tibble::tibble(
    x = c(1, 1, 2, 2, 3, 3),
    y = c("a", NA, "b", NA, "a", "b")
  )
  result <- tab2(df, x, y)
  expect_true(any(grepl("NA", names(result))))
})

test_that("tab2: NAs in both variables", {
  df <- tibble::tibble(
    x = c(1, NA, 2, NA, 1),
    y = c("a", "b", NA, NA, "a")
  )
  result <- tab2(df, x, y)
  expect_true(nrow(result) >= 2)
  expect_true(ncol(result) >= 3)
})

test_that("tab2: all rows have at least one NA", {
  df <- tibble::tibble(
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
  df <- tibble::tibble(
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
  df <- tibble::tibble(x = "A", y = "X")
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
  df <- tibble::tibble(x = rep("same", 100), y = rep("value", 100))
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
  df <- tibble::tibble(
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
  df <- tibble::tibble(
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
  df <- tibble::tibble(x = 1:50, y = 51:100)
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
  df <- tibble::tibble(x = character(0), y = character(0))
  result <- tab2(df, x, y)
  expect_equal(nrow(result), 0)
})

# ============================================================================
# CHALLENGING TESTS - Large-ish Data
# ============================================================================

test_that("tab2: 10x10 cross-tabulation", {
  withr::local_preserve_seed()
  set.seed(42)
  df <- tibble::tibble(
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
  withr::local_preserve_seed()
  set.seed(42)
  df <- tibble::tibble(
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
  withr::local_preserve_seed()
  set.seed(42)
  df <- tibble::tibble(
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
  withr::local_preserve_seed()
  set.seed(42)
  df <- tibble::tibble(
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
  df <- tibble::tibble(
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
  df <- tibble::tibble(
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
  df <- tibble::tibble(
    x = c("a", "a", "b", " ", " "),
    y = c("x", "x", "y", "z", "z")
  )
  result <- tab2(df, x, y)
  expect_true(any(result[[1]] == " " | result[[1]] == ""))
})

test_that("tab2: mixed scripts in same variable", {
  df <- tibble::tibble(
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
  df <- tibble::tibble(
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
  df <- tibble::tibble(
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
  df <- tibble::tibble(
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
  df <- tibble::tibble(x = 1:5)
  expect_error(tab2(df, x))
})

test_that("tab2: three variables give every pairwise table", {
  df <- tibble::tibble(x = 1:5, y = 1:5, z = 1:5)
  out <- tab2(df, x, y, z)
  expect_named(out, c("x x y", "x x z", "y x z"))
  expect_identical(out[["x x z"]], tab2(df, x, z))
})

test_that("tab2: NULL input should error", {
  expect_error(tab2(NULL))
})

test_that("tab2: non-existent column should error", {
  df <- tibble::tibble(x = 1:5)
  expect_error(tab2(df, x, y))
})

test_that("tab2: matrix column should error", {
  df <- tibble::tibble(x = 1:4)
  df$y <- matrix(1:8, nrow = 4)
  expect_error(tab2(df, x, y))
})

# ============================================================================
# CHALLENGING TESTS - Numeric Edge Cases
# ============================================================================

test_that("tab2: Inf and -Inf values", {
  df <- tibble::tibble(
    x = c(Inf, Inf, -Inf, -Inf, 0),
    y = c("A", "B", "A", "B", "A")
  )
  result <- tab2(df, x, y)
  expect_true(Inf %in% result[[1]] || -Inf %in% result[[1]])
})

test_that("tab2: very large numbers", {
  df <- tibble::tibble(
    x = c(1e200, 1e200, 2e200, 2e200),
    y = c("A", "B", "A", "B")
  )
  result <- tab2(df, x, y)
  expect_equal(nrow(result), 2)
})

test_that("tab2: very small numbers near zero", {
  df <- tibble::tibble(
    x = c(1e-300, 1e-300, 2e-300, 2e-300),
    y = c("A", "B", "A", "B")
  )
  result <- tab2(df, x, y)
  expect_equal(nrow(result), 2)
})

test_that("tab2: mixed numeric classes (integer vs double)", {
  df <- tibble::tibble(
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
  withr::local_preserve_seed()
  df <- tibble::tibble(
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
  withr::local_preserve_seed()
  df <- tibble::tibble(
    age_group = sample(
      c("18-25", "26-35", "36-50", "50+"),
      500,
      replace = TRUE
    ),
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
  withr::local_preserve_seed()
  df <- tibble::tibble(
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
  withr::local_preserve_seed()
  df <- tibble::tibble(
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
  df <- tibble::tibble(
    x = factor(c("a", "b"), levels = c("a", "b", "c", "d")),
    y = factor(c("x", "y"), levels = c("x", "y", "z"))
  )
  result <- tab2(df, x, y)
  expect_equal(nrow(result), 2)
  expect_equal(ncol(result), 3) # Row key and two observed column levels.
  expect_equal(result[[1]], df$x)
  expect_equal(sort(unlist(result[-1], use.names = FALSE)), c(0L, 0L, 1L, 1L))
})

test_that("tab2: factor levels not alphabetically ordered", {
  df <- tibble::tibble(
    x = factor(c("High", "Med", "Low"), levels = c("Low", "Med", "High")),
    y = c("A", "B", "A")
  )
  result <- tab2(df, x, y)
  expect_equal(as.character(result[[1]][1]), "Low")
})

test_that("tab2: numeric factor vs character", {
  df <- tibble::tibble(
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
  df <- tibble::tibble(a = 1:4, x = 1:4, b = 1:4, y = c("A", "B", "A", "B"))
  result <- tab2(df, 2, 4)
  expect_equal(nrow(result), 4)
})

test_that("tab2: last_col() selection", {
  df <- tibble::tibble(x = 1:4, y = c("A", "B", "A", "B"), z = 1:4)
  result <- tab2(df, 1, dplyr::last_col())
  expect_equal(ncol(result), 5)
})

test_that("tab2: everything() with two columns", {
  df <- tibble::tibble(x = c("A", "B", "A", "B"), y = c(1, 2, 1, 2))
  result <- tab2(df, dplyr::everything())
  expect_equal(nrow(result), 2)
  expect_setequal(names(result)[-1], as.character(unique(df$y)))
  expect_equal(
    unname(colSums(as.matrix(result[-1]))),
    as.numeric(table(df$y)[names(result)[-1]])
  )
})


test_that("cross totals preserve integer storage and promote overflow safely", {
  small <- tibble::tibble(category = "a", x = 2L, y = 3L)
  expect_identical(
    tab2_add_total(small, data.frame())$total,
    c(5L, 5L)
  )
  large <- tibble::tibble(category = "a", x = .Machine$integer.max, y = 1L)
  expect_no_warning(out <- tab2_add_total(large, data.frame()))
  expect_identical(out$total, rep(as.double(.Machine$integer.max) + 1, 2L))
  decimals <- tibble::tibble(category = "a", x = 0.5, y = 1.25)
  expect_identical(
    tab2_add_total(decimals, data.frame())$total,
    c(1.75, 1.75)
  )
})

test_that("tab2() returns every pairwise table for three or more variables", {
  d <- tibble::tibble(
    a = c(1, 1, 2, 2),
    b = c("x", "y", "y", "x"),
    c = c(TRUE, FALSE, TRUE, TRUE),
    w = c(1, 2, 1, 3)
  )
  out <- tab2(d, a, b, c)
  expect_type(out, "list")
  expect_named(out, c("a x b", "a x c", "b x c"))
  expect_identical(out[["a x c"]], tab2(d, a, c))
  totals <- fre2(d, a, b, c, .wt = w)
  expect_identical(totals[["b x c"]], tab2(d, b, c, .total = TRUE, .wt = w))
  messages <- capture_messages(tested <- tab2(d, a, b, c, .chi2 = TRUE))
  expect_identical(
    grep("^-> ", messages, value = TRUE),
    paste0("-> tabulation of ", c("a by b", "a by c", "b by c"))
  )
  expect_identical(
    attr(tested[["b x c"]], "chi2"),
    attr(suppressMessages(tab2(d, b, c, .chi2 = TRUE)), "chi2")
  )
  expect_error(tab2(d, a), "Provide two variables")
  skip_if_not_installed("data.table")
  dt <- data.table::as.data.table(d)
  expect_s3_class(tab2(dt, a, b, c)[[1]], "data.table")
})

test_that("tab2(.by) returns one cross-table per group", {
  d <- tibble::tibble(
    g = c("a", "a", "b", "b", NA),
    x = c(1, 2, 1, 1, 2),
    y = c("u", "v", "u", "u", "v"),
    w = c(1, 3, 1, 1, 1)
  )
  out <- tab2(d, x, y, .by = g)
  expect_type(out, "list")
  expect_named(out, c("g = a", "g = b", "g = NA"))
  expect_identical(out[["g = a"]], tab2(d[1:2, ], x, y))
  expect_identical(out[["g = NA"]], tab2(d[5, ], x, y))
  expect_identical(
    fre2(d, x, y, .by = g)[["g = b"]],
    tab2(d[3:4, ], x, y, .total = TRUE)
  )
  # Weights are evaluated on the whole table and rescaled within each group.
  weighted <- tab2(d, x, y, .by = g, .wt = w, .wt_type = "analytic")
  expect_identical(
    weighted[["g = a"]],
    tab2(d[1:2, ], x, y, .wt = w, .wt_type = "analytic")
  )
  three <- tab2(d, x, y, w, .by = g)
  expect_named(three[["g = a"]], c("x x y", "x x w", "y x w"))
  keys <- tab2(d, x, y, .by = c(g, w))
  expect_true("g = a, w = 1" %in% names(keys))
  expect_message(tab2(d, x, y, .by = g, .chi2 = TRUE), "-> g = a")
})
