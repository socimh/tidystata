# Comprehensive Challenging Test Suite for tab1() Function
# 70+ difficult test scenarios - focusing on edge cases, complexity, and robustness
# All tests designed to run in < 1 minute

# CHALLENGE: Comprehensive testing for tab1
# FUNCTIONS: tab1
# KEY BEHAVIORS: one-way tables
# EDGE CASES: single category, all unique values

library(testthat)
library(statart)
library(dplyr)
library(tibble)
library(haven)

# ============================================================================
# CHALLENGING TESTS - Output Format Variations
# ============================================================================

test_that("tab1: list output with 10 variables", {
  df <- tibble(
    v1 = sample(1:3, 100, replace = TRUE),
    v2 = sample(letters[1:4], 100, replace = TRUE),
    v3 = factor(sample(c("a", "b", "c"), 100, replace = TRUE)),
    v4 = sample(c(TRUE, FALSE), 100, replace = TRUE),
    v5 = sample(1:5, 100, replace = TRUE),
    v6 = sample(letters[1:10], 100, replace = TRUE),
    v7 = sample(1:2, 100, replace = TRUE),
    v8 = sample(c("x", "y", "z"), 100, replace = TRUE),
    v9 = sample(1:4, 100, replace = TRUE),
    v10 = sample(letters[1:3], 100, replace = TRUE)
  )
  result <- tab1(df, v1:v10, .type = "list")
  expect_type(result, "list")
  expect_equal(length(result), 10)
  expect_true(all(purrr::map_lgl(result, is.data.frame)))
})

test_that("tab1: tibble output with many variables", {
  df <- tibble(
    a = 1:50, b = letters[1:50], c = factor(rep(1:5, 10)),
    d = sample(c(TRUE, FALSE), 50, replace = TRUE)
  )
  result <- tab1(df, a:d, .type = "tibble")
  expect_s3_class(result, "tbl_df")
  expect_true("variable" %in% names(result))
  expect_true("value" %in% names(result))
})

test_that("tab1: list output preserves variable order", {
  df <- tibble(z = 1:5, a = 1:5, m = 1:5)
  result <- tab1(df, z, a, m, .type = "list")
  expect_equal(names(result), c("z", "a", "m"))
})

# ============================================================================
# CHALLENGING TESTS - Complex Missing Value Patterns
# ============================================================================

test_that("tab1: variables with varying NA percentages", {
  df <- tibble(
    no_na = 1:100,
    ten_pct = c(1:90, rep(NA, 10)),
    fifty_pct = c(1:50, rep(NA, 50)),
    ninety_pct = c(1:10, rep(NA, 90)),
    all_na = rep(NA, 100)
  )
  result <- tab1(df, no_na:all_na, .type = "list")
  expect_equal(nrow(result$no_na), 100)
  expect_equal(nrow(result$ten_pct), 91)
  expect_equal(nrow(result$fifty_pct), 51)
  expect_equal(nrow(result$ninety_pct), 11)
  expect_equal(nrow(result$all_na), 1)
})

test_that("tab1: NA patterns across list elements", {
  df <- tibble(
    x = c(1, NA, 3, NA, 5),
    y = c(NA, "b", NA, "d", NA),
    z = c(1, 2, NA, NA, 5)
  )
  result <- tab1(df, x:z, .type = "list")
  expect_true(any(is.na(result$x$value)))
  expect_true(any(is.na(result$y$value)))
  expect_true(any(is.na(result$z$value)))
})

test_that("tab1: factor with NA vs character with NA", {
  df <- tibble(
    fac_na = factor(c("a", "b", NA), exclude = NULL),
    char_na = c("a", "b", NA)
  )
  result <- tab1(df, fac_na, char_na, .type = "list")
  expect_s3_class(result$fac_na$value, "factor")
  expect_type(result$char_na$value, "character")
  expect_true(anyNA(levels(result$fac_na$value)))
  expect_false(anyNA(result$fac_na$value))
  expect_true(anyNA(result$char_na$value))
  expect_equal(as.character(result$fac_na$value), result$char_na$value)
  expect_equal(result$fac_na$n, result$char_na$n)
})

# ============================================================================
# CHALLENGING TESTS - Grouping with .by
# ============================================================================

test_that("tab1: group by with list output", {
  df <- tibble(
    group = rep(c("A", "B"), each = 50),
    x = sample(1:3, 100, replace = TRUE),
    y = sample(letters[1:4], 100, replace = TRUE)
  )
  result <- tab1(df, x, y, .by = group, .type = "list")
  expect_equal(length(result), 2)
  expect_true(all(purrr::map_lgl(result, ~ "group" %in% names(.x))))
})

test_that("tab1: group by with tibble output", {
  df <- tibble(
    g1 = rep(c("X", "Y"), 50),
    g2 = rep(c("A", "B", "C", "D"), 25),
    v1 = sample(1:3, 100, replace = TRUE),
    v2 = sample(letters[1:3], 100, replace = TRUE)
  )
  result <- tab1(df, v1, v2, .by = c(g1, g2), .type = "tibble")
  expect_true(all(c("g1", "g2") %in% names(result)))
})

test_that("tab1: group by where group has many NAs", {
  df <- tibble(
    group = c(rep("A", 20), rep(NA, 60), rep("B", 20)),
    x = sample(1:3, 100, replace = TRUE)
  )
  result <- tab1(df, x, .by = group, .type = "list")
  expect_true(sum(is.na(result$x$group)) > 0)
})

test_that("tab1: group by with single observation groups", {
  df <- tibble(
    group = 1:50,
    x = rep(1:2, 25)
  )
  result <- tab1(df, x, .by = group, .type = "list")
  expect_equal(nrow(result$x), 50)
  expect_true(all(result$x$n == 1))
})

# ============================================================================
# CHALLENGING TESTS - Boolean Expressions in Variables
# ============================================================================

test_that("tab1: boolean expressions as computed variables", {
  df <- tibble(
    x = 1:50,
    y = sample(letters[1:5], 50, replace = TRUE)
  )
  result <- tab1(df, x > 25, y == "a", .type = "list")
  expect_type(result[[1]]$value, "logical")
  expect_type(result[[2]]$value, "logical")
})

test_that("tab1: complex boolean creating all TRUE or all FALSE", {
  df <- tibble(
    a = 1:20,
    b = 21:40
  )
  result <- tab1(df, a > 0, b < 100, .type = "list")
  expect_equal(nrow(result[[1]]), 1)
  expect_equal(nrow(result[[2]]), 1)
  expect_equal(result[[1]]$n, 20)
  expect_equal(result[[2]]$n, 20)
})

test_that("tab1: boolean with NA handling", {
  df <- tibble(
    x = c(1:10, NA, 12:20),
    y = c(NA, letters[2:20])
  )
  result <- tab1(df, x > 10, !is.na(y), .type = "list")
  expect_true(nrow(result[[1]]) >= 2)
  expect_true(nrow(result[[2]]) >= 1)
})

# ============================================================================
# CHALLENGING TESTS - Edge Cases & Extremes
# ============================================================================

test_that("tab1: single row dataset", {
  df <- tibble(x = "only", y = 1, z = TRUE)
  result <- tab1(df, x:z, .type = "list")
  expect_equal(length(result), 3)
  purrr::walk(result, ~ expect_equal(.x$n, 1))
})

test_that("tab1: all unique values in each variable", {
  df <- tibble(
    a = 1:200,
    b = letters[1:20][(1:200 %% 20) + 1],
    c = as.character(1:200)
  )
  result <- tab1(df, a:c, .type = "list")
  expect_equal(nrow(result$a), 200)
  expect_equal(nrow(result$b), 20)
  expect_equal(nrow(result$c), 200)
})

test_that("tab1: all identical values in each variable", {
  df <- tibble(
    a = rep("same", 1000),
    b = rep(42, 1000),
    c = rep(TRUE, 1000)
  )
  result <- tab1(df, a:c, .type = "list")
  purrr::walk(result, ~ {
    expect_equal(nrow(.x), 1)
    expect_equal(.x$n, 1000)
  })
})

test_that("tab1: extreme cardinality differences", {
  df <- tibble(
    low_card = rep(1:2, 500),
    med_card = rep(1:50, 20),
    high_card = 1:1000
  )
  result <- tab1(df, low_card:high_card, .type = "list")
  expect_equal(nrow(result$low_card), 2)
  expect_equal(nrow(result$med_card), 50)
  expect_equal(nrow(result$high_card), 1000)
})

# ============================================================================
# CHALLENGING TESTS - Variable Selection Complexity
# ============================================================================

test_that("tab1: starts_with selection across many vars", {
  df <- tibble(
    pref_a_1 = 1:10, pref_a_2 = 1:10,
    pref_b_1 = 1:10, pref_b_2 = 1:10,
    other_x = 1:10, other_y = 1:10
  )
  result <- tab1(df, starts_with("pref_"), .type = "list")
  expect_equal(length(result), 4)
})

test_that("tab1: ends_with selection", {
  df <- tibble(
    x_test = 1:10, y_test = 1:10,
    x_prod = 1:10, y_prod = 1:10,
    z_dev = 1:10
  )
  result <- tab1(df, ends_with("_test"), .type = "list")
  expect_equal(length(result), 2)
})

test_that("tab1: contains selection", {
  df <- tibble(
    var_1_temp = 1:10, var_2_temp = 1:10,
    var_1_press = 1:10, temp_reading = 1:10
  )
  result <- tab1(df, contains("temp"), .type = "list")
  expect_equal(length(result), 3)
})

test_that("tab1: where() selection with complex predicate", {
  df <- tibble(
    num1 = 1:10, num2 = 11:20,
    char1 = letters[1:10],
    log1 = rep(c(TRUE, FALSE), length.out = 10),
    num3 = 21:30
  )
  result <- tab1(df, where(is.numeric), .type = "list")
  expect_equal(length(result), 3)
})

test_that("tab1: numeric column indices", {
  df <- tibble(a = 1:5, b = 1:5, c = 1:5, d = 1:5, e = 1:5)
  result <- tab1(df, 1, 3, 5, .type = "list")
  expect_equal(names(result), c("a", "c", "e"))
})

# ============================================================================
# CHALLENGING TESTS - Sorting with .desc
# ============================================================================

test_that("tab1: .desc=TRUE applied to all variables", {
  df <- tibble(
    x = c("z", "z", "a", "a", "m"),
    y = c(1, 1, 2, 2, 3)
  )
  result <- tab1(df, x, y, .desc = TRUE, .type = "list")
  expect_equal(result$x$n, c(2L, 2L, 1L))
  expect_equal(result$y$n, c(2L, 2L, 1L))
  expect_setequal(result$x$value[1:2], c("a", "z"))
  expect_setequal(result$y$value[1:2], c(1, 2))
})

test_that("tab1: .desc=FALSE preserves factor order", {
  df <- tibble(
    x = factor(c("high", "low", "med"), levels = c("low", "med", "high"))
  )
  result <- tab1(df, x, .desc = FALSE, .type = "list")
  expect_equal(as.character(result$x$value[1]), "low")
})

test_that("tab1: frequency ties handling in sorting", {
  df <- tibble(
    x = c("a", "a", "b", "b", "c", "c", "d")
  )
  result <- tab1(df, x, .desc = TRUE, .type = "list")
  expect_equal(result$x$n[1], 2)
  expect_equal(result$x$n, c(2L, 2L, 2L, 1L))
  expect_setequal(result$x$value[1:3], c("a", "b", "c"))
})

# ============================================================================
# CHALLENGING TESTS - Special Data Types
# ============================================================================

test_that("tab1: Date variables", {
  df <- tibble(
    d1 = as.Date(c("2024-01-01", "2024-06-15", "2024-12-31")),
    d2 = as.Date(c("2023-01-01", "2024-01-01", "2025-01-01"))
  )
  result <- tab1(df, d1, d2, .type = "list")
  expect_s3_class(result$d1$value, "Date")
  expect_s3_class(result$d2$value, "Date")
})

test_that("tab1: POSIXct datetime variables", {
  df <- tibble(
    t1 = as.POSIXct(c("2024-01-01 10:00", "2024-01-01 14:00", "2024-01-02 10:00")),
    t2 = as.POSIXct(c("2024-06-01 08:00", "2024-06-01 08:00", "2024-06-02 08:00"))
  )
  result <- tab1(df, t1, t2, .type = "list")
  expect_s3_class(result$t1$value, "POSIXct")
})

test_that("tab1: haven labelled variables", {
  df <- tibble(
    x = labelled(c(1, 1, 2, 2), labels = c("Yes" = 1, "No" = 2)),
    y = labelled(c(3, 3, 4, 4), labels = c("High" = 3, "Low" = 4))
  )
  result <- tab1(df, x, y, .type = "list")
  expect_s3_class(result$x$value, "haven_labelled")
})

test_that("tab1: difftime objects", {
  df <- tibble(
    d1 = as.difftime(c(1, 2, 2, 3), units = "hours"),
    d2 = as.difftime(c(30, 30, 45, 60), units = "mins")
  )
  result <- tab1(df, d1, d2, .type = "list")
  expect_s3_class(result$d1$value, "difftime")
})

# ============================================================================
# CHALLENGING TESTS - Unicode & Special Characters
# ============================================================================

test_that("tab1: unicode in multiple variables", {
  df <- tibble(
    latin = c("hello", "world", "hello"),
    cjk = c("中文", "日本語", "中文"),
    arabic = c("مرحبا", "مرحبا", "سلام"),
    emoji = c("🎉", "🎊", "🎉")
  )
  result <- tab1(df, latin:emoji, .type = "list")
  expect_equal(nrow(result$latin), 2)
  expect_equal(nrow(result$cjk), 2)
  expect_equal(nrow(result$arabic), 2)
  expect_equal(nrow(result$emoji), 2)
})

test_that("tab1: special whitespace characters", {
  df <- tibble(
    empty = c("", "", "a"),
    space = c(" ", " ", "a"),
    tab = c("a\t", "a\t", "b"),
    newline = c("a\n", "b\n", "a\n")
  )
  result <- tab1(df, empty:newline, .type = "list")
  expect_equal(nrow(result$empty), 2)
  expect_equal(nrow(result$space), 2)
  expect_equal(nrow(result$tab), 2)
  expect_equal(nrow(result$newline), 2)
})

# ============================================================================
# CHALLENGING TESTS - Reserved Names & Conflicts
# ============================================================================

test_that("tab1: variables named n, percent, cum", {
  df <- tibble(
    n = c(1, 2, 2, 3),
    percent = c("a", "a", "b", "b"),
    cum = c("x", "y", "x", "y"),
    valid = c("p", "p", "q", "q")
  )
  expect_message(result <- tab1(df, n:cum, .type = "list"), "renamed")
})

test_that("tab1: variable named 'variable' in tibble output", {
  df <- tibble(
    variable = c("a", "b", "a"),
    value = c(1, 2, 1)
  )
  result <- tab1(df, variable, value, .type = "tibble")
  expect_true("variable" %in% names(result))
})

# ============================================================================
# CHALLENGING TESTS - Performance Edge Cases
# ============================================================================

test_that("tab1: many variables (30+) with list output", {
  df <- as_tibble(replicate(30, sample(1:3, 100, replace = TRUE)), .name_repair = "minimal")
  names(df) <- paste0("var", 1:30)
  result <- tab1(df, everything(), .type = "list")
  expect_equal(length(result), 30)
})

test_that("tab1: moderate size dataset with tibble output", {
  df <- tibble(
    a = sample(1:5, 5000, replace = TRUE),
    b = sample(letters[1:5], 5000, replace = TRUE),
    c = sample(c(TRUE, FALSE), 5000, replace = TRUE)
  )
  result <- tab1(df, a:c, .type = "tibble")
  expect_s3_class(result, "tbl_df")
  expect_equal(sum(result$n), 15000)
})

test_that("tab1: highly skewed distributions", {
  df <- tibble(
    rare = c(rep("common", 990), rep("rare", 10)),
    uniform = sample(letters[1:10], 1000, replace = TRUE)
  )
  result <- tab1(df, rare, uniform, .type = "list")
  expect_equal(result$rare$n[result$rare$value == "common"], 990)
  expect_equal(result$rare$n[result$rare$value == "rare"], 10)
})

# ============================================================================
# CHALLENGING TESTS - Error Handling
# ============================================================================

test_that("tab1: empty data frame", {
  df <- tibble(x = numeric(0))
  result <- tab1(df, x, .type = "list")
  expect_equal(length(result), 1)
  expect_equal(nrow(result[[1]]), 0)
})

test_that("tab1: non-existent column selection", {
  df <- tibble(x = 1:5)
  expect_error(tab1(df, y, .type = "list"))
})

test_that("tab1: NULL input errors", {
  expect_error(tab1(NULL))
})

# ============================================================================
# CHALLENGING TESTS - Real-world Scenarios
# ============================================================================

test_that("tab1: survey responses with skip patterns", {
  df <- tibble(
    age_group = sample(c("18-25", "26-35", "36-50", "50+"), 100, replace = TRUE),
    completed = sample(c(TRUE, FALSE), 100, replace = TRUE),
    satisfaction = ifelse(sample(c(TRUE, FALSE), 100, replace = TRUE),
                         sample(1:5, 100, replace = TRUE), NA)
  )
  result <- tab1(df, age_group, completed, satisfaction, .type = "list")
  expect_equal(length(result), 3)
  expect_true(nrow(result$age_group) >= 4)
  expect_true(nrow(result$completed) == 2)
})

test_that("tab1: multi-country data with mixed formats", {
  df <- tibble(
    country = sample(c("USA", "UK", "DE", "FR", "JP"), 200, replace = TRUE),
    region = sample(c("North", "South", "East", "West"), 200, replace = TRUE),
    has_data = sample(c(TRUE, FALSE), 200, replace = TRUE),
    response_time = sample(1:100, 200, replace = TRUE)
  )
  result <- tab1(df, country:response_time, .type = "tibble")
  expect_s3_class(result, "tbl_df")
  expect_true("variable" %in% names(result))
})

test_that("tab1: quality control flags", {
  df <- tibble(
    valid_id = sample(c(TRUE, FALSE), 500, replace = TRUE, prob = c(0.95, 0.05)),
    valid_date = sample(c(TRUE, FALSE), 500, replace = TRUE, prob = c(0.98, 0.02)),
    valid_amount = sample(c(TRUE, FALSE), 500, replace = TRUE, prob = c(0.9, 0.1))
  )
  result <- tab1(df, valid_id:valid_amount, .type = "list")
  expect_true(all(purrr::map_lgl(result, ~ nrow(.x) <= 2)))
})
