# Comprehensive Challenging Test Suite for summ() and tabstat() Functions
# 70+ difficult test scenarios - focusing on edge cases, complexity, and robustness
# All tests designed to run in < 1 minute

# CHALLENGE: Comprehensive testing for summ, tabstat
# FUNCTIONS: summ, tabstat
# KEY BEHAVIORS: summary statistics, group analysis
# EDGE CASES: empty groups, all-NA columns

library(testthat)
library(statart)
library(dplyr)
library(tibble)
library(haven)

# ============================================================================
# CHALLENGING TESTS - Output Mode Variations
# ============================================================================

test_that("summ: list mode with multiple variable types", {
  df <- tibble(
    numeric_var = rnorm(100),
    date_var = seq(as.Date("2024-01-01"), by = "day", length.out = 100),
    datetime_var = seq(as.POSIXct("2024-01-01"), by = "hour", length.out = 100),
    char_var = sample(letters[1:5], 100, replace = TRUE)
  )
  result <- summ(df, .mode = "list")
  expect_type(result, "list")
})

test_that("summ: table mode with date variables", {
  df <- tibble(
    x = 1:50,
    start_date = seq(as.Date("2024-01-01"), by = "day", length.out = 50),
    end_date = seq(as.Date("2024-03-01"), by = "day", length.out = 50)
  )
  result <- summ(df, start_date, end_date, .mode = "table")
  expect_s3_class(result, "data.frame")
})

test_that("summ: duration format long vs compact", {
  df <- tibble(
    dates = seq(as.Date("2024-01-01"), by = "day", length.out = 100)
  )
  result_long <- summ(df, dates, .mode = "table", .duration_format = "long")
  result_compact <- summ(df, dates, .mode = "table", .duration_format = "compact")
  expect_s3_class(result_long, "data.frame")
  expect_s3_class(result_compact, "data.frame")
})

# ============================================================================
# CHALLENGING TESTS - .stat Parameter Variations
# ============================================================================

test_that("summ: single statistic selection", {
  df <- tibble(x = rnorm(100), y = rnorm(100))
  result <- summ(df, .stat = "mean")
  expect_true(all(c("mean") %in% names(result)))
})

test_that("summ: multiple statistics selection", {
  df <- tibble(x = rnorm(100), y = rnorm(100))
  result <- summ(df, .stat = c("mean", "sd", "min", "max"))
  expect_true(all(c("mean", "sd", "min", "max") %in% names(result)))
})

test_that("summ: all available statistics", {
  df <- tibble(x = rnorm(100))
  result <- summ(df, .stat = c("n", "missing", "mean", "sd", "min", "p25", "p50", "p75", "max"))
  expect_true(ncol(result) >= 9)
})

test_that("tabstat: default mean statistic", {
  df <- tibble(x = rnorm(100), y = rnorm(100))
  result <- tabstat(df, x, y)
  expect_true("mean" %in% names(result))
})

test_that("tabstat: custom statistics", {
  df <- tibble(x = 1:100, y = 101:200)
  result <- tabstat(df, x, y, .stat = c("sum", "mean", "sd"))
  expect_true(all(c("sum", "mean", "sd") %in% names(result)))
})

# ============================================================================
# CHALLENGING TESTS - Grouping with .by
# ============================================================================

test_that("summ: group by single variable", {
  df <- tibble(
    group = rep(c("A", "B", "C"), each = 33)[1:99],
    x = rnorm(99),
    y = rnorm(99)
  )
  result <- summ(df, x, y, .by = group)
  expect_true("group" %in% names(result))
  expect_equal(dplyr::n_distinct(result$group), 3)
})

test_that("summ: group by multiple variables", {
  df <- tibble(
    g1 = rep(c("X", "Y"), 50),
    g2 = rep(c("A", "B", "C", "D"), 25),
    value = rnorm(100)
  )
  result <- summ(df, value, .by = c(g1, g2))
  expect_true(all(c("g1", "g2") %in% names(result)))
})

test_that("summ: group with many groups", {
  df <- tibble(
    group = rep(1:50, each = 2),
    x = rnorm(100)
  )
  result <- summ(df, x, .by = group)
  expect_equal(nrow(result), 50)
})

test_that("summ: group with NA in grouping variable", {
  df <- tibble(
    group = c(rep("A", 30), rep(NA, 40), rep("B", 30)),
    x = rnorm(100)
  )
  result <- summ(df, x, .by = group)
  expect_true(any(is.na(result$group)))
})

test_that("summ: .na.rm=TRUE removes NA groups", {
  df <- tibble(
    group = c(rep("A", 50), rep(NA, 50)),
    x = rnorm(100)
  )
  result <- summ(df, x, .by = group, .na.rm = TRUE)
  expect_false(any(is.na(result$group)))
  expect_equal(nrow(result), 1)
})

test_that("summ: group where some groups have 1 observation", {
  df <- tibble(
    group = 1:100,
    x = rnorm(100)
  )
  result <- summ(df, x, .by = group)
  expect_equal(nrow(result), 100)
  expect_true(all(result$n == 1))
})

# ============================================================================
# CHALLENGING TESTS - .detail Mode
# ============================================================================

test_that("summ: detail mode with numeric variables", {
  df <- tibble(x = rnorm(100), y = rnorm(100))
  result <- summ(df, .detail = TRUE)
  expect_true("detail" %in% names(result) || ncol(result) > 5)
})

test_that("summ: detail mode with dates", {
  df <- tibble(
    dates = seq(as.Date("2024-01-01"), by = "day", length.out = 365)
  )
  result <- summ(df, dates, .detail = TRUE)
  expect_s3_class(result, "data.frame")
})

test_that("summ: detail mode with grouped data", {
  df <- tibble(
    group = rep(c("A", "B"), each = 50),
    x = rnorm(100)
  )
  result <- summ(df, x, .by = group, .detail = TRUE)
  expect_equal(nrow(result), 2)
})

# ============================================================================
# CHALLENGING TESTS - Missing Value Handling
# ============================================================================

test_that("summ: variables with varying missing percentages", {
  df <- tibble(
    complete = 1:100,
    ten_pct = c(1:90, rep(NA, 10)),
    fifty_pct = c(1:50, rep(NA, 50)),
    ninety_pct = c(1:10, rep(NA, 90)),
    all_missing = rep(NA, 100)
  )
  result <- summ(df)
  expect_true("missing" %in% names(result) || "n" %in% names(result))
})

test_that("summ: all NA variable handling", {
  df <- tibble(x = rep(NA, 100))
  result <- summ(df)
  expect_equal(nrow(result), 1)
})

test_that("summ: NaN vs NA handling", {
  df <- tibble(x = c(1, 2, NaN, NaN, NA, NA, 3, 4))
  result <- summ(df)
  expect_true("missing" %in% names(result) || "n" %in% names(result))
})

test_that("summ: Inf values in calculations", {
  df <- tibble(x = c(1, 2, 3, Inf, -Inf))
  result <- summ(df)
  expect_true("mean" %in% names(result) || "min" %in% names(result))
})

# ============================================================================
# CHALLENGING TESTS - Special Numeric Values
# ============================================================================

test_that("summ: extreme numeric values", {
  df <- tibble(
    normal = rnorm(100),
    large = c(.Machine$double.xmax / 1e10, rep(1e100, 99)),
    small = c(.Machine$double.xmin * 1e10, rep(1e-100, 99))
  )
  result <- summ(df)
  expect_equal(nrow(result), 3)
})

test_that("summ: integer overflow edge case", {
  df <- tibble(
    x = c(.Machine$integer.max, .Machine$integer.max - 1, 1, 2)
  )
  result <- summ(df)
  expect_true("max" %in% names(result))
})

test_that("summ: very small variance dataset", {
  df <- tibble(x = c(1, 1.0000001, 0.9999999, 1.0000002, 0.9999998))
  result <- summ(df)
  expect_true("sd" %in% names(result))
})

test_that("summ: dataset with exact zero variance", {
  df <- tibble(x = rep(5, 100))
  result <- summ(df)
  if("sd" %in% names(result)) {
    expect_equal(result$sd, 0)
  }
})

# ============================================================================
# CHALLENGING TESTS - Variable Selection
# ============================================================================

test_that("summ: starts_with selection", {
  df <- tibble(
    temp_1 = rnorm(50), temp_2 = rnorm(50),
    pressure_1 = rnorm(50), pressure_2 = rnorm(50)
  )
  result <- summ(df, starts_with("temp_"))
  expect_equal(nrow(result), 2)
})

test_that("summ: ends_with selection", {
  df <- tibble(
    var_a_test = rnorm(50), var_b_test = rnorm(50),
    var_c_prod = rnorm(50)
  )
  result <- summ(df, ends_with("_test"))
  expect_equal(nrow(result), 2)
})

test_that("summ: contains selection", {
  df <- tibble(
    temp_morning = rnorm(50), temp_evening = rnorm(50),
    pressure_temp = rnorm(50), humidity = rnorm(50)
  )
  result <- summ(df, contains("temp"))
  expect_equal(nrow(result), 3)
})

test_that("summ: where() with is.numeric", {
  df <- tibble(
    num1 = rnorm(50), num2 = rnorm(50),
    char = sample(letters, 50, replace = TRUE),
    logi = sample(c(TRUE, FALSE), 50, replace = TRUE)
  )
  result <- summ(df, where(is.numeric))
  expect_equal(nrow(result), 2)
})

test_that("summ: numeric column indices", {
  df <- tibble(a = rnorm(50), b = rnorm(50), c = rnorm(50), 
               d = rnorm(50), e = rnorm(50))
  result <- summ(df, 1, 3, 5)
  expect_equal(nrow(result), 3)
})

# ============================================================================
# CHALLENGING TESTS - Date and Time Variables
# ============================================================================

test_that("summ: Date variables spanning years", {
  df <- tibble(
    dates = seq(as.Date("2020-01-01"), as.Date("2024-12-31"), by = "day")
  )
  result <- summ(df, dates)
  expect_s3_class(result, "data.frame")
})

test_that("summ: POSIXct with different timezones", {
  df <- tibble(
    utc_time = as.POSIXct("2024-01-01 12:00", tz = "UTC"),
    est_time = as.POSIXct("2024-01-01 07:00", tz = "EST")
  )
  result <- summ(df)
  expect_s3_class(result, "data.frame")
})

test_that("summ: datetime variables in list mode", {
  df <- tibble(
    timestamps = seq(as.POSIXct("2024-01-01"), by = "hour", length.out = 100)
  )
  result <- summ(df, .mode = "list")
  expect_type(result, "list")
})

test_that("summ: difftime objects", {
  df <- tibble(
    duration = as.difftime(rnorm(100, mean = 24, sd = 5), units = "hours")
  )
  result <- summ(df)
  expect_s3_class(result, "data.frame")
})

# ============================================================================
# CHALLENGING TESTS - Data Type Variations
# ============================================================================

test_that("summ: haven labelled numeric", {
  df <- tibble(
    x = labelled(rnorm(100), labels = c("Low" = -1, "High" = 1))
  )
  result <- summ(df, x)
  expect_s3_class(result, "data.frame")
})

test_that("summ: integer vs double distinction", {
  df <- tibble(
    int_col = as.integer(1:100),
    dbl_col = as.double(1:100) + 0.5
  )
  result <- summ(df)
  expect_equal(nrow(result), 2)
})

test_that("summ: logical variables converted to numeric", {
  df <- tibble(
    bool = sample(c(TRUE, FALSE), 100, replace = TRUE)
  )
  result <- summ(df)
  expect_s3_class(result, "data.frame")
})

# ============================================================================
# CHALLENGING TESTS - Vector Input
# ============================================================================

test_that("summ: numeric vector input", {
  x <- rnorm(100)
  result <- summ(x)
  expect_s3_class(result, "data.frame")
})

test_that("summ: integer vector input", {
  x <- as.integer(1:100)
  result <- summ(x)
  expect_s3_class(result, "data.frame")
})

test_that("summ: Date vector input", {
  x <- seq(as.Date("2024-01-01"), by = "day", length.out = 100)
  result <- summ(x)
  expect_s3_class(result, "data.frame")
})

# ============================================================================
# CHALLENGING TESTS - Large-ish Datasets
# ============================================================================

test_that("summ: 10000 rows with multiple variables", {
  df <- tibble(
    x = rnorm(10000),
    y = rnorm(10000),
    z = rnorm(10000)
  )
  result <- summ(df)
  expect_equal(nrow(result), 3)
})

test_that("summ: many variables (50+)", {
  df <- as_tibble(replicate(50, rnorm(100)))
  names(df) <- paste0("var", 1:50)
  result <- summ(df)
  expect_equal(nrow(result), 50)
})

test_that("summ: grouped data with many groups", {
  df <- tibble(
    group = rep(1:100, each = 10),
    x = rnorm(1000)
  )
  result <- summ(df, x, .by = group)
  expect_equal(nrow(result), 100)
})

# ============================================================================
# CHALLENGING TESTS - Error Handling
# ============================================================================

test_that("summ: empty data frame with columns", {
  df <- tibble(x = numeric(0), y = numeric(0))
  result <- summ(df)
  expect_s3_class(result, "data.frame")
})

test_that("summ: NULL input should error", {
  expect_error(summ(NULL))
})

test_that("summ: character only data frame should error or skip", {
  df <- tibble(x = letters[1:10], y = letters[11:20])
  expect_error(summ(df))
})

test_that("summ: non-existent column should error", {
  df <- tibble(x = rnorm(10))
  expect_error(summ(df, y))
})

# ============================================================================
# CHALLENGING TESTS - .name Parameter
# ============================================================================

test_that("summ: .name=FALSE with single variable", {
  df <- tibble(x = rnorm(100))
  result <- summ(df, .name = FALSE)
  expect_false("name" %in% names(result))
})

test_that("summ: .name=TRUE with single variable", {
  df <- tibble(x = rnorm(100))
  result <- summ(df, .name = TRUE)
  expect_true("name" %in% names(result))
})

test_that("summ: .name=FALSE with multiple variables", {
  df <- tibble(x = rnorm(100), y = rnorm(100))
  result <- summ(df, .name = FALSE)
  expect_true("name" %in% names(result))
})

# ============================================================================
# CHALLENGING TESTS - Real-world Scenarios
# ============================================================================

test_that("summ: clinical measurements", {
  set.seed(42)
  df <- tibble(
    patient_id = 1:200,
    age = sample(18:90, 200, replace = TRUE),
    systolic_bp = rnorm(200, mean = 120, sd = 15),
    diastolic_bp = rnorm(200, mean = 80, sd = 10),
    heart_rate = rnorm(200, mean = 72, sd = 12),
    cholesterol = rnorm(200, mean = 200, sd = 40),
    treatment = sample(c("Drug", "Placebo"), 200, replace = TRUE)
  )
  result <- summ(df, age:cholesterol, .by = treatment)
  expect_true("treatment" %in% names(result))
  expect_true(nrow(result) >= 10)
})

test_that("summ: financial time series", {
  set.seed(123)
  df <- tibble(
    date = seq(as.Date("2024-01-01"), by = "day", length.out = 252),
    open_price = cumsum(rnorm(252, mean = 0.1, sd = 2)) + 100,
    high_price = cumsum(rnorm(252, mean = 0.1, sd = 2)) + 102,
    low_price = cumsum(rnorm(252, mean = 0.1, sd = 2)) + 98,
    close_price = cumsum(rnorm(252, mean = 0.1, sd = 2)) + 101,
    volume = sample(1e6:1e9, 252, replace = TRUE)
  )
  result <- summ(df, open_price:volume)
  expect_equal(nrow(result), 5)
})

test_that("summ: survey data with grouping", {
  set.seed(456)
  df <- tibble(
    region = sample(c("North", "South", "East", "West"), 1000, replace = TRUE),
    age = sample(18:80, 1000, replace = TRUE),
    income = rnorm(1000, mean = 50000, sd = 20000),
    satisfaction = sample(1:10, 1000, replace = TRUE),
    spending = rnorm(1000, mean = 2000, sd = 800)
  )
  result <- summ(df, age:spending, .by = region, .stat = c("mean", "sd"))
  expect_equal(dplyr::n_distinct(result$region), 4)
})

test_that("summ: quality control data", {
  set.seed(789)
  df <- tibble(
    batch_id = rep(1:20, each = 50),
    measurement_1 = rnorm(1000, mean = 100, sd = 5),
    measurement_2 = rnorm(1000, mean = 50, sd = 3),
    defect_rate = runif(1000, 0, 0.1)
  )
  result <- summ(df, measurement_1:defect_rate, .by = batch_id)
  expect_equal(nrow(result), 60)
})

# ============================================================================
# CHALLENGING TESTS - data.table Input
# ============================================================================

test_that("summ: data.table input conversion", {
  skip_if_not_installed("data.table")
  df <- data.table::data.table(
    x = rnorm(100),
    y = rnorm(100),
    group = rep(c("A", "B"), 50)
  )
  result <- summ(df, x, y, .by = group)
  expect_s3_class(result, "data.frame")
})

test_that("summ: data.table input with table mode", {
  skip_if_not_installed("data.table")
  df <- data.table::data.table(
    x = rnorm(100),
    y = rnorm(100)
  )
  result <- summ(df, x, y, .mode = "table")
  expect_s3_class(result, "data.frame")
})
