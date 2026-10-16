# Comprehensive Test Suite for row_* Functions
# Row-wise operations: row_mean, row_sum, row_max, row_min, row_median, row_var, row_sd, row_unique, row_miss, row_non_miss

# CHALLENGE: Comprehensive testing for row_mean, row_sum, row_max, row_min, row_median, row_var, row_sd
# FUNCTIONS: row_mean, row_sum, row_max, row_min, row_median, row_var, row_sd
# KEY BEHAVIORS: row-wise aggregation, missing value handling
# EDGE CASES: all-NA rows, single column

library(testthat)
library(statart)
library(dplyr)
library(tibble)

# ============================================================================
# CHALLENGING TESTS - row_mean
# ============================================================================

test_that("row_mean: basic calculation with tibble input", {
  tb <- tibble(x = 1:10, y = 11:20, z = 21:30)
  result <- row_mean(tb)
  expect_type(result, "double")
  expect_equal(length(result), 10)
  expect_equal(result[1], 11)  # mean of 1, 11, 21
  expect_equal(result[10], 20) # mean of 10, 20, 30
})

test_that("row_mean: with missing values", {
  tb <- tibble(x = c(1, 2, NA, 4), y = c(NA, 2, 3, 4), z = c(1, NA, 3, 4))
  result <- row_mean(tb)
  expect_equal(result[1], 1)   # only x and z available
  expect_equal(result[2], 2)   # only x and y available
  expect_equal(result[3], 3)   # only y and z available
  expect_equal(result[4], 4)   # all available
})

test_that("row_mean: all NA row returns NA", {
  tb <- tibble(x = c(1, NA), y = c(2, NA), z = c(3, NA))
  result <- row_mean(tb)
  expect_equal(result[1], 2)
  expect_true(is.na(result[2]))
})

test_that("row_mean: single column returns that column", {
  tb <- tibble(x = 1:5)
  result <- row_mean(tb)
  expect_equal(result, as.double(1:5))
})

test_that("row_mean: within mutate context", {
  tb <- tibble(x = 1:5, y = 6:10)
  result <- tb %>% mutate(mean_xy = row_mean(x, y))
  expect_equal(result$mean_xy, c(3.5, 4.5, 5.5, 6.5, 7.5))
})

test_that("row_mean: with large numbers", {
  tb <- tibble(x = c(1e10, 1e10), y = c(1e10, 1e10), z = c(1e10, 1e10))
  result <- row_mean(tb)
  expect_equal(result, c(1e10, 1e10))
})

test_that("row_mean: with small numbers", {
  tb <- tibble(x = c(1e-10, 1e-10), y = c(1e-10, 1e-10))
  result <- row_mean(tb)
  expect_equal(result, c(1e-10, 1e-10))
})

# ============================================================================
# CHALLENGING TESTS - row_sum
# ============================================================================

test_that("row_sum: basic calculation", {
  tb <- tibble(x = 1:5, y = 6:10, z = 11:15)
  result <- row_sum(tb)
  expect_equal(result, c(18, 21, 24, 27, 30))
})

test_that("row_sum: with missing values", {
  tb <- tibble(x = c(1, NA, 3), y = c(NA, 2, 3), z = c(1, 2, NA))
  result <- row_sum(tb)
  expect_equal(result[1], 2)  # 1 + 1
  expect_equal(result[2], 4)  # 2 + 2
  expect_equal(result[3], 6)  # 3 + 3
})

test_that("row_sum: within mutate context", {
  tb <- tibble(x = 1:5, y = 6:10)
  result <- tb %>% mutate(sum_xy = row_sum(x, y))
  expect_equal(result$sum_xy, c(7, 9, 11, 13, 15))
})

test_that("row_sum: empty tibble returns numeric(0)", {
  tb <- tibble(x = numeric(0), y = numeric(0))
  result <- row_sum(tb)
  expect_equal(length(result), 0)
})

# ============================================================================
# CHALLENGING TESTS - row_max
# ============================================================================

test_that("row_max: basic calculation", {
  tb <- tibble(x = c(1, 5, 3), y = c(4, 2, 6), z = c(2, 3, 1))
  result <- row_max(tb)
  expect_type(result, "double")
  expect_equal(result, c(4, 5, 6))
})

test_that("row_max: handles NA values correctly", {
  tb <- tibble(x = c(1, NA, 3), y = c(4, 2, NA))
  result <- row_max(tb)
  expect_equal(result[1], 4)
  expect_equal(result[2], 2)
  expect_equal(result[3], 3)
})

test_that("row_max: all NA in a row returns NA", {
  tb <- tibble(x = c(1, NA), y = c(2, NA))
  result <- row_max(tb)
  expect_equal(result[1], 2)
  expect_true(is.na(result[2]))
})

test_that("row_max: within mutate returns plain vector", {
  tb <- tibble(x = 1:5, y = 5:1)
  result <- tb %>% mutate(max_val = row_max(x, y))
  expect_type(result$max_val, "double")
  expect_equal(result$max_val, c(5, 4, 3, 4, 5))
})

test_that("row_max: with Inf values", {
  tb <- tibble(x = c(1, Inf, 3), y = c(Inf, 2, -Inf))
  result <- row_max(tb)
  expect_equal(result, c(Inf, Inf, 3))
})

test_that("row_max: single column returns that column", {
  tb <- tibble(x = c(1, 5, 3))
  result <- row_max(tb)
  expect_equal(result, c(1, 5, 3))
})

# ============================================================================
# CHALLENGING TESTS - row_min
# ============================================================================

test_that("row_min: basic calculation", {
  tb <- tibble(x = c(4, 2, 6), y = c(1, 5, 3), z = c(3, 1, 2))
  result <- row_min(tb)
  expect_equal(result, c(1, 1, 2))
})

test_that("row_min: handles NA values correctly", {
  tb <- tibble(x = c(4, NA, 3), y = c(1, 2, NA))
  result <- row_min(tb)
  expect_equal(result[1], 1)
  expect_equal(result[2], 2)
  expect_equal(result[3], 3)
})

test_that("row_min: within mutate returns plain vector", {
  tb <- tibble(x = 1:5, y = 5:1)
  result <- tb %>% mutate(min_val = row_min(x, y))
  expect_type(result$min_val, "double")
  expect_equal(result$min_val, c(1, 2, 3, 2, 1))
})

test_that("row_min: with -Inf values", {
  tb <- tibble(x = c(1, -Inf, 3), y = c(-Inf, 2, Inf))
  result <- row_min(tb)
  expect_equal(result, c(-Inf, -Inf, 3))
})

# ============================================================================
# CHALLENGING TESTS - row_median
# ============================================================================

test_that("row_median: basic calculation with odd number of columns", {
  tb <- tibble(x = c(1, 4, 7), y = c(2, 5, 8), z = c(3, 6, 9))
  result <- row_median(tb)
  expect_equal(result, c(2, 5, 8))
})

test_that("row_median: with even number of columns", {
  tb <- tibble(x = c(1, 4), y = c(3, 6))
  result <- row_median(tb)
  expect_equal(result, c(2, 5))
})

test_that("row_median: with missing values", {
  tb <- tibble(x = c(1, NA, 5), y = c(NA, 2, NA), z = c(3, 4, 6))
  result <- row_median(tb)
  expect_equal(result[1], 2)  # median of 1, 3
  expect_equal(result[2], 3)  # median of 2, 4
  expect_equal(result[3], 5.5) # median of 5, 6
})

test_that("row_median: within mutate context", {
  tb <- tibble(x = c(1, 10, 5), y = c(5, 2, 8), z = c(10, 5, 2))
  result <- tb %>% mutate(med = row_median(x, y, z))
  expect_equal(result$med, c(5, 5, 5))
})

# ============================================================================
# CHALLENGING TESTS - row_var
# ============================================================================

test_that("row_var: basic calculation", {
  tb <- tibble(x = c(1, 2), y = c(3, 4), z = c(5, 6))
  result <- row_var(tb)
  expect_type(result, "double")
  expect_true(all(result > 0))
})

test_that("row_var: zero variance for identical values", {
  tb <- tibble(x = c(5, 5), y = c(5, 5), z = c(5, 5))
  result <- row_var(tb)
  expect_equal(result, c(0, 0))
})

test_that("row_var: with missing values", {
  tb <- tibble(x = c(1, NA, 3), y = c(3, 2, NA), z = c(5, 4, 5))
  result <- row_var(tb)
  expect_true(all(result[!is.na(result)] >= 0))
})

test_that("row_var: single non-NA value returns NA", {
  tb <- tibble(x = c(1, NA), y = c(NA, 2), z = c(NA, NA))
  result <- row_var(tb)
  expect_true(is.na(result[1]))  # only one non-NA
})

# ============================================================================
# CHALLENGING TESTS - row_sd
# ============================================================================

test_that("row_sd: basic calculation", {
  tb <- tibble(x = c(1, 2, 3), y = c(5, 6, 7), z = c(9, 10, 11))
  result <- row_sd(tb)
  expect_type(result, "double")
  expect_equal(result[1], sqrt(var(c(1, 5, 9))), tolerance = 0.001)
})

test_that("row_sd: zero sd for identical values", {
  tb <- tibble(x = c(5, 5), y = c(5, 5), z = c(5, 5))
  result <- row_sd(tb)
  expect_equal(result, c(0, 0))
})

test_that("row_sd: related to row_var", {
  tb <- tibble(x = c(1, 2, 3), y = c(4, 5, 6), z = c(7, 8, 9))
  var_result <- row_var(tb)
  sd_result <- row_sd(tb)
  expect_equal(sqrt(var_result), sd_result, tolerance = 0.001)
})

test_that("row_sd: within mutate context", {
  tb <- tibble(x = 1:5, y = 6:10, z = 11:15)
  result <- tb %>% mutate(sd_val = row_sd(x, y, z))
  expect_type(result$sd_val, "double")
  expect_true(all(result$sd_val > 0))
})

# ============================================================================
# CHALLENGING TESTS - row_unique
# ============================================================================

test_that("row_unique: basic calculation", {
  tb <- tibble(x = c(1, 2, 1), y = c(1, 2, 2), z = c(1, 2, 3))
  result <- row_unique(tb)
  expect_equal(result, c(1, 1, 3))
})

test_that("row_unique: NA values counted as unique", {
  tb <- tibble(x = c(1, NA, 1), y = c(NA, NA, 1), z = c(1, NA, 2))
  result <- row_unique(tb)
  expect_equal(result[1], 2)  # 1 and NA
  expect_equal(result[2], 1)  # only NA
  expect_equal(result[3], 2)  # 1, 1, 2 -> unique: 1, 2
})

test_that("row_unique: all identical returns 1", {
  tb <- tibble(x = c(5, 5), y = c(5, 5), z = c(5, 5))
  result <- row_unique(tb)
  expect_equal(result, c(1, 1))
})

test_that("row_unique: within mutate context", {
  tb <- tibble(x = c(1, 2, 3), y = c(1, 2, 4), z = c(1, 3, 5))
  result <- tb %>% mutate(unique_count = row_unique(x, y, z))
  expect_equal(result$unique_count, c(1, 2, 3))
})

# ============================================================================
# CHALLENGING TESTS - row_miss
# ============================================================================

test_that("row_miss: counts missing values correctly", {
  tb <- tibble(x = c(1, NA, NA), y = c(NA, 2, NA), z = c(1, 2, NA))
  result <- row_miss(tb)
  expect_equal(result, c(1, 1, 3))
})

test_that("row_miss: no missing values returns 0", {
  tb <- tibble(x = 1:3, y = 4:6, z = 7:9)
  result <- row_miss(tb)
  expect_equal(result, c(0, 0, 0))
})

test_that("row_miss: all missing returns number of columns", {
  tb <- tibble(x = c(NA, NA), y = c(NA, NA), z = c(NA, NA))
  result <- row_miss(tb)
  expect_equal(result, c(3, 3))
})

test_that("row_miss: within mutate context", {
  tb <- tibble(x = c(1, NA, 3), y = c(NA, 2, NA))
  result <- tb %>% mutate(miss_count = row_miss(x, y))
  expect_equal(result$miss_count, c(1, 1, 1))
})

# ============================================================================
# CHALLENGING TESTS - row_non_miss
# ============================================================================

test_that("row_non_miss: counts non-missing values correctly", {
  tb <- tibble(x = c(1, NA, NA), y = c(NA, 2, NA), z = c(1, 2, NA))
  result <- row_non_miss(tb)
  expect_equal(result, c(2, 2, 0))
})

test_that("row_non_miss: no missing values returns ncol", {
  tb <- tibble(x = 1:3, y = 4:6, z = 7:9)
  result <- row_non_miss(tb)
  expect_equal(result, c(3, 3, 3))
})

test_that("row_non_miss: all missing returns 0", {
  tb <- tibble(x = c(NA, NA), y = c(NA, NA))
  result <- row_non_miss(tb)
  expect_equal(result, c(0, 0))
})

test_that("row_non_miss: complements row_miss", {
  tb <- tibble(x = c(1, NA, 3, NA), y = c(NA, 2, 3, NA), z = c(1, 2, NA, NA))
  miss_count <- row_miss(tb)
  non_miss_count <- row_non_miss(tb)
  expect_equal(miss_count + non_miss_count, rep(3, 4))
})

# ============================================================================
# CHALLENGING TESTS - Complex Scenarios
# ============================================================================

test_that("row functions: mixed data types coerce to numeric", {
  tb <- tibble(x = c(TRUE, FALSE, TRUE), y = c(1L, 2L, 3L), z = c(1.5, 2.5, 3.5))
  result_mean <- row_mean(tb)
  result_sum <- row_sum(tb)
  expect_type(result_mean, "double")
  expect_type(result_sum, "double")
})

test_that("row functions: single row tibble", {
  tb <- tibble(x = 1, y = 2, z = 3)
  expect_equal(row_mean(tb), 2)
  expect_equal(row_sum(tb), 6)
  expect_equal(row_max(tb), 3)
  expect_equal(row_min(tb), 1)
})

test_that("row functions: many columns", {
  tb <- as_tibble(replicate(50, rnorm(10)),
                  .name_repair = ~ paste0("x", seq_along(.x)))
  result <- row_mean(tb)
  expect_equal(length(result), 10)
  expect_type(result, "double")
})

test_that("row functions: many rows", {
  tb <- tibble(x = rnorm(10000), y = rnorm(10000), z = rnorm(10000))
  result <- row_sum(tb)
  expect_equal(length(result), 10000)
})

test_that("row functions: combining multiple operations in mutate", {
  tb <- tibble(x = c(1, 2, NA), y = c(4, NA, 6), z = c(7, 8, 9))
  result <- tb %>%
    mutate(
      mean_val = row_mean(x, y, z),
      sum_val = row_sum(x, y, z),
      max_val = row_max(x, y, z),
      min_val = row_min(x, y, z),
      miss_val = row_miss(x, y, z),
      non_miss_val = row_non_miss(x, y, z)
    )
  expect_equal(ncol(result), 9)
  expect_equal(result$miss_val + result$non_miss_val, c(3, 3, 3))
})

test_that("row functions: extreme values don't cause overflow", {
  tb <- tibble(x = c(.Machine$double.xmax / 1e10, 1e100), 
               y = c(1e100, .Machine$double.xmax / 1e10))
  result_mean <- row_mean(tb)
  result_sum <- row_sum(tb)
  expect_true(all(is.finite(result_mean) | is.infinite(result_mean)))
  expect_true(all(is.finite(result_sum) | is.infinite(result_sum)))
})

test_that("row functions: handle NaN correctly", {
  tb <- tibble(x = c(1, NaN, 3), y = c(NaN, 2, 3), z = c(1, 2, NaN))
  result_mean <- row_mean(tb)
  expect_equal(result_mean[1], 1)  # mean of 1, 1
  expect_equal(result_mean[2], 2)  # mean of 2, 2
  expect_equal(result_mean[3], 3)  # mean of 3, 3
})

# ============================================================================
# CHALLENGING TESTS - Error Handling
# ============================================================================

test_that("row functions: empty tibble with no columns", {
  tb <- tibble(.rows = 5)
  expect_error(row_mean(tb))
  expect_error(row_sum(tb))
})

test_that("row functions: NULL input errors appropriately", {
  expect_error(row_mean(NULL))
  expect_error(row_sum(NULL))
  expect_error(row_max(NULL))
  expect_error(row_min(NULL))
})

# ============================================================================
# CHALLENGING TESTS - Real-world Scenarios
# ============================================================================

test_that("row functions: survey scoring scenario", {
  set.seed(42)
  survey <- tibble(
    q1 = sample(1:5, 100, replace = TRUE),
    q2 = sample(1:5, 100, replace = TRUE),
    q3 = sample(1:5, 100, replace = TRUE),
    q4 = sample(1:5, 100, replace = TRUE),
    q5 = sample(1:5, 100, replace = TRUE)
  )
  result <- survey %>%
    mutate(
      total_score = row_sum(q1:q5),
      mean_score = row_mean(q1:q5),
      max_score = row_max(q1:q5),
      min_score = row_min(q1:q5)
    )
  expect_true(all(result$total_score >= 5 & result$total_score <= 25))
  expect_true(all(result$mean_score >= 1 & result$mean_score <= 5))
  expect_equal(result$total_score / 5, result$mean_score, tolerance = 0.001)
})

test_that("row functions: data quality check scenario", {
  df <- tibble(
    check1 = sample(c(TRUE, FALSE), 50, replace = TRUE),
    check2 = sample(c(TRUE, FALSE), 50, replace = TRUE),
    check3 = sample(c(TRUE, FALSE), 50, replace = TRUE)
  )
  result <- df %>%
    mutate(
      passed_checks = row_non_miss(check1, check2, check3),
      failed_checks = row_miss(check1, check2, check3)
    )
  expect_equal(result$passed_checks + result$failed_checks, rep(3, 50))
})

# ============================================================================
# CHALLENGING TESTS - data.table compatibility
# ============================================================================

test_that("row functions: work with data.table input", {
  skip_if_not_installed("data.table")
  dt <- data.table::data.table(x = 1:10, y = 11:20, z = 21:30)
  result <- row_mean(dt)
  expect_equal(length(result), 10)
  expect_equal(result[1], 11)
})
