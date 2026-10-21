# Comprehensive Test Suite for row_* Functions
# Row-wise operations: row_mean, row_sum, row_max, row_min, row_median, row_var, row_sd, row_unique, row_miss, row_non_miss

# CHALLENGE: Comprehensive testing for row_mean, row_sum, row_max, row_min, row_median, row_var, row_sd
# FUNCTIONS: row_mean, row_sum, row_max, row_min, row_median, row_var, row_sd
# KEY BEHAVIORS: row-wise aggregation, missing value handling
# EDGE CASES: all-NA rows, single column

# ============================================================================
# CHALLENGING TESTS - row_mean
# ============================================================================

test_that("row_mean: basic calculation with tibble input", {
  tb <- tibble::tibble(x = 1:10, y = 11:20, z = 21:30)
  result <- row_mean(tb)
  expect_type(result, "double")
  expect_equal(length(result), 10)
  expect_equal(result[1], 11) # mean of 1, 11, 21
  expect_equal(result[10], 20) # mean of 10, 20, 30
})

test_that("row_mean: with missing values", {
  tb <- tibble::tibble(
    x = c(1, 2, NA, 4),
    y = c(NA, 2, 3, 4),
    z = c(1, NA, 3, 4)
  )
  result <- row_mean(tb)
  expect_equal(result[1], 1) # only x and z available
  expect_equal(result[2], 2) # only x and y available
  expect_equal(result[3], 3) # only y and z available
  expect_equal(result[4], 4) # all available
})

test_that("row_mean: all NA row returns NA", {
  tb <- tibble::tibble(x = c(1, NA), y = c(2, NA), z = c(3, NA))
  result <- row_mean(tb)
  expect_equal(result[1], 2)
  expect_true(is.na(result[2]))
})

test_that("row_mean: single column returns that column", {
  tb <- tibble::tibble(x = 1:5)
  result <- row_mean(tb)
  expect_equal(result, as.double(1:5))
})

test_that("row_mean: within mutate context", {
  tb <- tibble::tibble(x = 1:5, y = 6:10)
  result <- tb %>% dplyr::mutate(mean_xy = row_mean(x, y))
  expect_equal(result$mean_xy, c(3.5, 4.5, 5.5, 6.5, 7.5))
})

test_that("row_mean: with large numbers", {
  tb <- tibble::tibble(x = c(1e10, 1e10), y = c(1e10, 1e10), z = c(1e10, 1e10))
  result <- row_mean(tb)
  expect_equal(result, c(1e10, 1e10))
})

test_that("row_mean: with small numbers", {
  tb <- tibble::tibble(x = c(1e-10, 1e-10), y = c(1e-10, 1e-10))
  result <- row_mean(tb)
  expect_equal(result, c(1e-10, 1e-10))
})

# ============================================================================
# CHALLENGING TESTS - row_sum
# ============================================================================

test_that("row_sum: basic calculation", {
  tb <- tibble::tibble(x = 1:5, y = 6:10, z = 11:15)
  result <- row_sum(tb)
  expect_equal(result, c(18, 21, 24, 27, 30))
})

test_that("row_sum: with missing values", {
  tb <- tibble::tibble(x = c(1, NA, 3), y = c(NA, 2, 3), z = c(1, 2, NA))
  result <- row_sum(tb)
  expect_equal(result[1], 2) # 1 + 1
  expect_equal(result[2], 4) # 2 + 2
  expect_equal(result[3], 6) # 3 + 3
})

test_that("row_sum: within mutate context", {
  tb <- tibble::tibble(x = 1:5, y = 6:10)
  result <- tb %>% dplyr::mutate(sum_xy = row_sum(x, y))
  expect_equal(result$sum_xy, c(7, 9, 11, 13, 15))
})

test_that("row_sum: empty tibble returns numeric(0)", {
  tb <- tibble::tibble(x = numeric(0), y = numeric(0))
  result <- row_sum(tb)
  expect_equal(length(result), 0)
})

# ============================================================================
# CHALLENGING TESTS - row_max
# ============================================================================

test_that("row_max: basic calculation", {
  tb <- tibble::tibble(x = c(1, 5, 3), y = c(4, 2, 6), z = c(2, 3, 1))
  result <- row_max(tb)
  expect_type(result, "double")
  expect_equal(result, c(4, 5, 6))
})

test_that("row_max: handles NA values correctly", {
  tb <- tibble::tibble(x = c(1, NA, 3), y = c(4, 2, NA))
  result <- row_max(tb)
  expect_equal(result[1], 4)
  expect_equal(result[2], 2)
  expect_equal(result[3], 3)
})

test_that("row_max: all NA in a row returns NA", {
  tb <- tibble::tibble(x = c(1, NA), y = c(2, NA))
  result <- row_max(tb)
  expect_equal(result[1], 2)
  expect_true(is.na(result[2]))
})

test_that("row_max: within mutate returns plain vector", {
  tb <- tibble::tibble(x = 1:5, y = 5:1)
  result <- tb %>% dplyr::mutate(max_val = row_max(x, y))
  expect_type(result$max_val, "integer")
  expect_equal(result$max_val, c(5, 4, 3, 4, 5))
})

test_that("row_max: with Inf values", {
  tb <- tibble::tibble(x = c(1, Inf, 3), y = c(Inf, 2, -Inf))
  result <- row_max(tb)
  expect_equal(result, c(Inf, Inf, 3))
})

test_that("row_max: single column returns that column", {
  tb <- tibble::tibble(x = c(1, 5, 3))
  result <- row_max(tb)
  expect_equal(result, c(1, 5, 3))
})

# ============================================================================
# CHALLENGING TESTS - row_min
# ============================================================================

test_that("row_min: basic calculation", {
  tb <- tibble::tibble(x = c(4, 2, 6), y = c(1, 5, 3), z = c(3, 1, 2))
  result <- row_min(tb)
  expect_equal(result, c(1, 1, 2))
})

test_that("row_min: handles NA values correctly", {
  tb <- tibble::tibble(x = c(4, NA, 3), y = c(1, 2, NA))
  result <- row_min(tb)
  expect_equal(result[1], 1)
  expect_equal(result[2], 2)
  expect_equal(result[3], 3)
})

test_that("row_min: within mutate returns plain vector", {
  tb <- tibble::tibble(x = 1:5, y = 5:1)
  result <- tb %>% dplyr::mutate(min_val = row_min(x, y))
  expect_type(result$min_val, "integer")
  expect_equal(result$min_val, c(1, 2, 3, 2, 1))
})

test_that("row_min: with -Inf values", {
  tb <- tibble::tibble(x = c(1, -Inf, 3), y = c(-Inf, 2, Inf))
  result <- row_min(tb)
  expect_equal(result, c(-Inf, -Inf, 3))
})

# ============================================================================
# CHALLENGING TESTS - row_median
# ============================================================================

test_that("row_median: basic calculation with odd number of columns", {
  tb <- tibble::tibble(x = c(1, 4, 7), y = c(2, 5, 8), z = c(3, 6, 9))
  result <- row_median(tb)
  expect_equal(result, c(2, 5, 8))
})

test_that("row_median: with even number of columns", {
  tb <- tibble::tibble(x = c(1, 4), y = c(3, 6))
  result <- row_median(tb)
  expect_equal(result, c(2, 5))
})

test_that("row_median: with missing values", {
  tb <- tibble::tibble(x = c(1, NA, 5), y = c(NA, 2, NA), z = c(3, 4, 6))
  result <- row_median(tb)
  expect_equal(result[1], 2) # median of 1, 3
  expect_equal(result[2], 3) # median of 2, 4
  expect_equal(result[3], 5.5) # median of 5, 6
})

test_that("row_median: within mutate context", {
  tb <- tibble::tibble(x = c(1, 10, 5), y = c(5, 2, 8), z = c(10, 5, 2))
  result <- tb %>% dplyr::mutate(med = row_median(x, y, z))
  expect_equal(result$med, c(5, 5, 5))
})

# ============================================================================
# CHALLENGING TESTS - row_var
# ============================================================================

test_that("row_var: basic calculation", {
  tb <- tibble::tibble(x = c(1, 2), y = c(3, 4), z = c(5, 6))
  result <- row_var(tb)
  expect_type(result, "double")
  expect_true(all(result > 0))
})

test_that("row_var: zero variance for identical values", {
  tb <- tibble::tibble(x = c(5, 5), y = c(5, 5), z = c(5, 5))
  result <- row_var(tb)
  expect_equal(result, c(0, 0))
})

test_that("row_var: with missing values", {
  tb <- tibble::tibble(x = c(1, NA, 3), y = c(3, 2, NA), z = c(5, 4, 5))
  result <- row_var(tb)
  expect_true(all(result[!is.na(result)] >= 0))
})

test_that("row_var: single non-NA value returns NA", {
  tb <- tibble::tibble(x = c(1, NA), y = c(NA, 2), z = c(NA, NA))
  result <- row_var(tb)
  expect_true(is.na(result[1])) # only one non-NA
})

# ============================================================================
# CHALLENGING TESTS - row_sd
# ============================================================================

test_that("row_sd: basic calculation", {
  tb <- tibble::tibble(x = c(1, 2, 3), y = c(5, 6, 7), z = c(9, 10, 11))
  result <- row_sd(tb)
  expect_type(result, "double")
  expect_equal(result[1], sqrt(var(c(1, 5, 9))), tolerance = 0.001)
})

test_that("row_sd: zero sd for identical values", {
  tb <- tibble::tibble(x = c(5, 5), y = c(5, 5), z = c(5, 5))
  result <- row_sd(tb)
  expect_equal(result, c(0, 0))
})

test_that("row_sd: related to row_var", {
  tb <- tibble::tibble(x = c(1, 2, 3), y = c(4, 5, 6), z = c(7, 8, 9))
  var_result <- row_var(tb)
  sd_result <- row_sd(tb)
  expect_equal(sqrt(var_result), sd_result, tolerance = 0.001)
})

test_that("row_sd: within mutate context", {
  tb <- tibble::tibble(x = 1:5, y = 6:10, z = 11:15)
  result <- tb %>% dplyr::mutate(sd_val = row_sd(x, y, z))
  expect_type(result$sd_val, "double")
  expect_true(all(result$sd_val > 0))
})

# ============================================================================
# CHALLENGING TESTS - row_unique
# ============================================================================

test_that("row_unique: basic calculation", {
  tb <- tibble::tibble(x = c(1, 2, 1), y = c(1, 2, 2), z = c(1, 2, 3))
  result <- row_unique(tb)
  expect_equal(result, c(1, 1, 3))
})

test_that("row_unique: NA values counted as unique", {
  tb <- tibble::tibble(x = c(1, NA, 1), y = c(NA, NA, 1), z = c(1, NA, 2))
  result <- row_unique(tb)
  expect_equal(result[1], 2) # 1 and NA
  expect_equal(result[2], 1) # only NA
  expect_equal(result[3], 2) # 1, 1, 2 -> unique: 1, 2
})

test_that("row_unique: all identical returns 1", {
  tb <- tibble::tibble(x = c(5, 5), y = c(5, 5), z = c(5, 5))
  result <- row_unique(tb)
  expect_equal(result, c(1, 1))
})

test_that("row_unique: within mutate context", {
  tb <- tibble::tibble(x = c(1, 2, 3), y = c(1, 2, 4), z = c(1, 3, 5))
  result <- tb %>% dplyr::mutate(unique_count = row_unique(x, y, z))
  expect_equal(result$unique_count, c(1, 2, 3))
})

# ============================================================================
# CHALLENGING TESTS - row_miss
# ============================================================================

test_that("row_miss: counts missing values correctly", {
  tb <- tibble::tibble(x = c(1, NA, NA), y = c(NA, 2, NA), z = c(1, 2, NA))
  result <- row_miss(tb)
  expect_equal(result, c(1, 1, 3))
})

test_that("row_miss: no missing values returns 0", {
  tb <- tibble::tibble(x = 1:3, y = 4:6, z = 7:9)
  result <- row_miss(tb)
  expect_equal(result, c(0, 0, 0))
})

test_that("row_miss: all missing returns number of columns", {
  tb <- tibble::tibble(x = c(NA, NA), y = c(NA, NA), z = c(NA, NA))
  result <- row_miss(tb)
  expect_equal(result, c(3, 3))
})

test_that("row_miss: within mutate context", {
  tb <- tibble::tibble(x = c(1, NA, 3), y = c(NA, 2, NA))
  result <- tb %>% dplyr::mutate(miss_count = row_miss(x, y))
  expect_equal(result$miss_count, c(1, 1, 1))
})

# ============================================================================
# CHALLENGING TESTS - row_non_miss
# ============================================================================

test_that("row_non_miss: counts non-missing values correctly", {
  tb <- tibble::tibble(x = c(1, NA, NA), y = c(NA, 2, NA), z = c(1, 2, NA))
  result <- row_non_miss(tb)
  expect_equal(result, c(2, 2, 0))
})

test_that("row_non_miss: no missing values returns ncol", {
  tb <- tibble::tibble(x = 1:3, y = 4:6, z = 7:9)
  result <- row_non_miss(tb)
  expect_equal(result, c(3, 3, 3))
})

test_that("row_non_miss: all missing returns 0", {
  tb <- tibble::tibble(x = c(NA, NA), y = c(NA, NA))
  result <- row_non_miss(tb)
  expect_equal(result, c(0, 0))
})

test_that("row_non_miss: complements row_miss", {
  tb <- tibble::tibble(
    x = c(1, NA, 3, NA),
    y = c(NA, 2, 3, NA),
    z = c(1, 2, NA, NA)
  )
  miss_count <- row_miss(tb)
  non_miss_count <- row_non_miss(tb)
  expect_equal(miss_count + non_miss_count, rep(3, 4))
})

# ============================================================================
# CHALLENGING TESTS - Complex Scenarios
# ============================================================================

test_that("row functions: mixed data types coerce to numeric", {
  tb <- tibble::tibble(
    x = c(TRUE, FALSE, TRUE),
    y = c(1L, 2L, 3L),
    z = c(1.5, 2.5, 3.5)
  )
  result_mean <- row_mean(tb)
  result_sum <- row_sum(tb)
  expect_type(result_mean, "double")
  expect_type(result_sum, "double")
})

test_that("row functions: single row tibble", {
  tb <- tibble::tibble(x = 1, y = 2, z = 3)
  expect_equal(row_mean(tb), 2)
  expect_equal(row_sum(tb), 6)
  expect_equal(row_max(tb), 3)
  expect_equal(row_min(tb), 1)
})

test_that("row functions: many columns", {
  withr::local_preserve_seed()
  tb <- tibble::as_tibble(
    replicate(50, rnorm(10)),
    .name_repair = ~ paste0("x", seq_along(.x))
  )
  result <- row_mean(tb)
  expect_equal(length(result), 10)
  expect_type(result, "double")
})

test_that("row functions: retain row order and exact totals", {
  tb <- tibble::tibble(x = c(1, NA, -2), y = c(2, 3, NA), z = c(4, 5, 6))
  expect_identical(row_sum(tb), c(7, 8, 4))
})

test_that("row functions: combining multiple operations in mutate", {
  tb <- tibble::tibble(x = c(1, 2, NA), y = c(4, NA, 6), z = c(7, 8, 9))
  result <- tb %>%
    dplyr::mutate(
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
  tb <- tibble::tibble(
    x = c(.Machine$double.xmax / 1e10, 1e100),
    y = c(1e100, .Machine$double.xmax / 1e10)
  )
  result_mean <- row_mean(tb)
  result_sum <- row_sum(tb)
  expected_sum <- rep(.Machine$double.xmax / 1e10 + 1e100, 2)
  expect_true(all(is.finite(result_mean)))
  expect_true(all(is.finite(result_sum)))
  expect_equal(result_mean, expected_sum / 2)
  expect_equal(result_sum, expected_sum)
})

test_that("row functions: handle NaN correctly", {
  tb <- tibble::tibble(x = c(1, NaN, 3), y = c(NaN, 2, 3), z = c(1, 2, NaN))
  result_mean <- row_mean(tb)
  expect_equal(result_mean[1], 1) # mean of 1, 1
  expect_equal(result_mean[2], 2) # mean of 2, 2
  expect_equal(result_mean[3], 3) # mean of 3, 3
})

# ============================================================================
# CHALLENGING TESTS - Error Handling
# ============================================================================

test_that("row functions: empty tibble with no columns", {
  tb <- tibble::tibble(.rows = 5)
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
  withr::local_preserve_seed()
  set.seed(42)
  survey <- tibble::tibble(
    q1 = sample(1:5, 100, replace = TRUE),
    q2 = sample(1:5, 100, replace = TRUE),
    q3 = sample(1:5, 100, replace = TRUE),
    q4 = sample(1:5, 100, replace = TRUE),
    q5 = sample(1:5, 100, replace = TRUE)
  )
  result <- survey %>%
    dplyr::mutate(
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
  withr::local_preserve_seed()
  df <- tibble::tibble(
    check1 = sample(c(TRUE, FALSE), 50, replace = TRUE),
    check2 = sample(c(TRUE, FALSE), 50, replace = TRUE),
    check3 = sample(c(TRUE, FALSE), 50, replace = TRUE)
  )
  result <- df %>%
    dplyr::mutate(
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

# ============================================================================
# Native kernels and dplyr context detection
# ============================================================================

test_that("row sums and means equal rowSums() and rowMeans() exactly", {
  df <- data.frame(
    a = c(1e16, NA, Inf, 0.1, -0, NA, 1e308),
    b = c(1, NA, -Inf, 0.2, -0, 3, 1e308),
    c = c(-1e16, NaN, 1, 0.3, NA, NA, -1e308)
  )
  sums <- rowSums(as.matrix(df), na.rm = TRUE)
  means <- rowMeans(as.matrix(df), na.rm = TRUE)
  means[rowSums(!is.na(df)) == 0L] <- NA_real_
  expect_identical(row_sum(df), sums)
  expect_identical(row_mean(df), means)
  expect_identical(row_sum(df)[[1]], 1)
})

test_that("native extrema, spread and distinct counts keep their rules", {
  df <- data.frame(
    a = c(2, NA, -0, NaN, 1, Inf),
    b = c(2, NA, 0, 1, NA, -Inf),
    c = c(1, NaN, 0, 1, 3, Inf)
  )
  expect_identical(row_max(df), c(2, NA, 0, 1, 3, Inf))
  expect_identical(row_min(df), c(1, NA, -0, 1, 1, -Inf))
  expect_identical(row_unique(df), c(2L, 1L, 1L, 2L, 3L, 2L))
  expect_identical(row_nvals(df), c(2L, 0L, 1L, 1L, 2L, 2L))
  expect_identical(row_median(df), c(2, NA, 0, 1, 2, Inf))
  expect_equal(row_sd(df)[1:3], c(sd(c(2, 2, 1)), NA, 0))
  expect_identical(row_var(df[6, ]), NaN)
  expect_identical(row_max(df[0, ]), numeric())
  expect_identical(row_unique(df["a"]), c(1L, 1L, 1L, 1L, 1L, 1L))
})

test_that("row helpers detect mutate() through wrapper functions", {
  df <- tibble::tibble(g = c(1, 1, 2), x = c(1, 3, 5), y = c(3, 5, 7))
  wrapper <- function(...) row_mean(...)
  expect_identical(
    dplyr::mutate(df, m = wrapper(x, y), .by = g)$m,
    c(2, 4, 6)
  )
  expect_identical(wrapper(df[c("x", "y")]), c(2, 4, 6))
  expect_identical(row_sum(df$x, df$y), c(4, 8, 12))
})

test_that("row kernels read logical and integer columns directly", {
  df <- data.frame(
    x = c(1L, NA, 3L, 3L, NA),
    y = c(1.5, 2, NA, NaN, NA),
    z = c(TRUE, NA, FALSE, TRUE, NA)
  )
  doubles <- as.matrix(data.frame(lapply(df, as.double)))
  observed <- rowSums(!is.na(doubles))
  means <- rowMeans(doubles, na.rm = TRUE)
  means[observed == 0L] <- NA_real_
  expect_identical(row_mean(df), means)
  expect_identical(row_sum(df), rowSums(doubles, na.rm = TRUE))
  expect_identical(row_sum(df, na.rm = FALSE), c(3.5, NA, NA, NA, NA))
  expect_identical(
    is.na(row_var(df, na.rm = FALSE)),
    c(FALSE, TRUE, TRUE, TRUE, TRUE)
  )
  expect_identical(row_max(df[c("x", "z")]), c(1L, NA, 3L, 3L, NA))
  expect_identical(row_miss(df), c(0L, 2L, 1L, 1L, 3L))
  expect_identical(row_non_miss(df), c(3L, 1L, 2L, 2L, 0L))
  expect_identical(row_nvals(df), c(2L, 1L, 2L, 2L, 0L))
})

test_that("missing-value counts keep each class's is.na() method", {
  df <- tibble::tibble(
    p = haven::labelled_spss(c(1, 99, NA), na_values = 99),
    s = c("a", NA, "b"),
    l = list(1, NA, NULL),
    q = c(2, 3, NA)
  )
  expect_identical(row_miss(df), as.integer(rowSums(is.na(df))))
  expect_identical(row_non_miss(df), c(4L, 1L, 2L))
  expect_identical(row_sum(df[c("p", "q")], na.rm = FALSE), c(3, NA, NA))
})

test_that("milestone row helpers return atomic vectors with explicit missing semantics", {
  d <- tibble::tibble(a = c(1, NA_real_, 4), b = c(3, NA_real_, NA_real_))
  expect_equal(row_median(d), c(2, NA_real_, 4))
  expect_equal(row_var(d), c(2, NA_real_, NA_real_))
  expect_equal(row_sd(d), c(sqrt(2), NA_real_, NA_real_))
  expect_equal(row_mean(d), c(2, NA_real_, 4))
  expect_equal(row_min(d), c(1, NA_real_, 4))
  expect_equal(row_max(d), c(3, NA_real_, 4))
  expect_equal(row_unique(d), c(2, 1, 2))
})

.milestone_row_cases <- list(
  doubles = data.frame(a = c(1.5, 2.5, 3.5), b = c(3, 6, 9), c = c(-1, 0, 1)),
  integers = data.frame(a = 1:4, b = 4:1),
  logical = data.frame(a = c(TRUE, FALSE, NA), b = c(FALSE, TRUE, TRUE)),
  mixed_storage = data.frame(
    a = 1:3,
    b = c(1.5, 2, 3.5),
    c = c(TRUE, FALSE, TRUE)
  ),
  partial_missing = data.frame(
    a = c(1, NA, 5),
    b = c(NA, 2, 3),
    c = c(3, 4, NA)
  ),
  all_missing_row = data.frame(a = c(1, NA, 4), b = c(3, NA, NA)),
  all_missing_data = data.frame(a = rep(NA_real_, 3), b = rep(NA_integer_, 3)),
  nan_and_na = data.frame(
    a = c(NaN, NA, 1),
    b = c(NA, NaN, NaN),
    c = c(NA, NaN, 2)
  ),
  positive_infinity = data.frame(a = c(Inf, 1), b = c(2, Inf)),
  negative_infinity = data.frame(a = c(-Inf, 1), b = c(2, -Inf)),
  opposing_infinity = data.frame(a = c(Inf, -Inf), b = c(-Inf, Inf)),
  one_column = data.frame(a = c(1, NA, 3)),
  one_row = data.frame(a = 2, b = 8, c = 5),
  duplicates = data.frame(a = c(2, 2, 4), b = c(2, 2, 4), c = c(2, 2, NA)),
  negative_values = data.frame(a = c(-5, -2), b = c(-1, -8)),
  large_values = data.frame(a = c(1e100, 2e100), b = c(3e100, 4e100)),
  small_values = data.frame(a = c(1e-100, 2e-100), b = c(3e-100, 4e-100)),
  zero_rows = data.frame(a = numeric(), b = integer(), c = logical()),
  zero_columns = structure(
    list(),
    class = "data.frame",
    row.names = c(NA_integer_, -3L)
  ),
  entirely_empty = data.frame(),
  null_input = NULL,
  non_syntactic = stats::setNames(
    data.frame(a = 1:3, b = 3:1),
    c("a value", "\u53d8\u91cf")
  ),
  tibble = tibble::tibble(a = c(1, 2, NA), b = c(4, 2, 5)),
  mixed_missing_repeats = data.frame(
    a = c(NA, 3, 2),
    b = c(NaN, 3, NA),
    c = c(4, 3, 2)
  )
)

.milestone_row_reference <- function(d, operation) {
  vapply(
    seq_len(nrow(d)),
    function(i) {
      x <- as.numeric(unlist(d[i, , drop = FALSE], use.names = FALSE))
      observed <- x[!is.na(x)]
      switch(
        operation,
        row_sum = sum(observed),
        row_mean = if (length(observed)) mean(observed) else NA_real_,
        row_min = if (length(observed)) min(observed) else NA_real_,
        row_max = if (length(observed)) max(observed) else NA_real_,
        row_median = if (length(observed)) {
          stats::median(observed)
        } else {
          NA_real_
        },
        row_var = if (length(observed) > 1L) stats::var(observed) else NA_real_,
        row_sd = if (length(observed) > 1L) stats::sd(observed) else NA_real_,
        row_unique = length(unique(observed)) + as.integer(anyNA(x)),
        row_miss = sum(is.na(x)),
        row_non_miss = sum(!is.na(x))
      )
    },
    numeric(1)
  )
}

.milestone_row_functions <- c(
  "row_mean",
  "row_sum",
  "row_min",
  "row_max",
  "row_median",
  "row_var",
  "row_sd",
  "row_unique",
  "row_miss",
  "row_non_miss"
)

for (.function_name in .milestone_row_functions) {
  for (.scenario in names(.milestone_row_cases)) {
    test_that(paste("milestone", .function_name, "row semantics", .scenario), {
      d <- .milestone_row_cases[[.scenario]]
      row_fn <- get(.function_name, mode = "function")
      if (is.null(d) || ncol(d) == 0L) {
        expect_error(row_fn(d), "[Cc]olumn|[Nn]umeric|[Ee]mpty|NULL")
      } else {
        before <- unserialize(serialize(d, NULL))
        # Windows' C locale cannot translate Unicode names in base matrix
        # conversion. Keep this fixture in a UTF-8 locale for both references.
        if (.scenario == "non_syntactic" && .Platform$OS.type == "windows") {
          withr::local_locale(c(LC_CTYPE = "English_United States.utf8"))
        }
        expected <- .milestone_row_reference(d, .function_name)
        extrema <- .function_name %in% c("row_min", "row_max")
        storage <- typeof(unlist(d, use.names = FALSE))
        if (extrema && storage == "logical") {
          expected <- as.logical(expected)
        }
        if (extrema && storage == "integer") {
          expected <- as.integer(expected)
        }
        out <- expect_no_warning(row_fn(d))
        expect_true(is.atomic(out))
        expect_true(is.numeric(out) || is.logical(out))
        expect_null(dim(out))
        expect_length(out, nrow(d))
        expect_equal(out, expected, tolerance = 1e-12)
        if (!.function_name %in% c("row_unique", "row_miss", "row_non_miss")) {
          expect_type(out, if (extrema) storage else "double")
        }
        expect_identical(d, before)
      }
    })
  }
}

for (.function_name in setdiff(
  .milestone_row_functions,
  c("row_miss", "row_non_miss")
)) {
  test_that(
    paste(
      "milestone",
      .function_name,
      "rejects unsupported columns without mutation"
    ),
    {
      row_fn <- get(.function_name, mode = "function")
      for (x in list(c("1", "2"), factor(c("1", "2")), list(1, 2))) {
        d <- tibble::tibble(a = 1:2, b = x)
        before <- unserialize(serialize(d, NULL))
        expect_error(row_fn(d), "[Nn]umeric|[Ll]ogical|[Cc]olumn|[Ss]upport")
        expect_identical(d, before)
      }
    }
  )
}

for (.function_name in .milestone_row_functions) {
  test_that(
    paste(
      "milestone",
      .function_name,
      "accepts a data frame argument within mutate"
    ),
    {
      d <- tibble::tibble(a = c(1, NA, 4), b = c(3, NA, NA), excluded = 100)
      selected <- as.data.frame(d[c("a", "b")])
      row_fn <- get(.function_name, mode = "function")
      expected <- .milestone_row_reference(selected, .function_name)
      out <- dplyr::mutate(d, observed = row_fn(selected))
      expect_equal(out$observed, expected)
      expect_identical(out$excluded, d$excluded)
      counter <- new.env(parent = emptyenv())
      counter$n <- 0L
      computed <- dplyr::mutate(
        d,
        observed = row_fn({
          counter$n <- counter$n + 1L
          selected
        })
      )
      expect_equal(computed$observed, expected)
      expect_identical(counter$n, 1L)
    }
  )
  test_that(
    paste(
      "milestone",
      .function_name,
      "keeps selection errors visible within mutate"
    ),
    {
      d <- tibble::tibble(a = 1:3, b = 3:1)
      row_fn <- get(.function_name, mode = "function")
      expect_error(
        dplyr::mutate(d, observed = row_fn(a, missing_column)),
        "missing_column"
      )
      expect_error(
        dplyr::mutate(d, observed = row_fn(dplyr::pick(a, missing_column))),
        "missing_column"
      )
    }
  )
}

.review_row_expected <- list(
  row_mean = c(2, 4, 3, NA_real_),
  row_sum = c(4, 4, 3, 0),
  row_min = c(1, 4, 3, NA_real_),
  row_max = c(3, 4, 3, NA_real_),
  row_median = c(2, 4, 3, NA_real_),
  row_var = c(2, NA_real_, NA_real_, NA_real_),
  row_sd = c(sqrt(2), NA_real_, NA_real_, NA_real_),
  row_unique = c(2, 2, 2, 1),
  row_miss = c(0, 1, 1, 2),
  row_non_miss = c(2, 1, 1, 0)
)

for (.fn in names(.review_row_expected)) {
  test_that(
    paste("milestone review accepts general data frame expressions", .fn),
    {
      d <- tibble::tibble(x = c(1, NA, 3, NA), y = c(3, 4, NA, NA))
      fn <- get(.fn, mode = "function")
      expected <- .review_row_expected[[.fn]]
      expect_equal(dplyr::mutate(d, z = fn(d[c("x", "y")]))$z, expected)
      expect_equal(
        dplyr::mutate(d, z = fn(identity(dplyr::pick(x, y))))$z,
        expected
      )
      counter <- new.env(parent = emptyenv())
      counter$n <- 0L
      producer <- function() {
        counter$n <- counter$n + 1L
        d
      }
      expect_equal(dplyr::mutate(d, z = fn(producer()))$z, expected)
      expect_identical(counter$n, 1L)
      expect_equal(
        dplyr::mutate(d, z = fn(dplyr::where(is.numeric)))$z,
        expected
      )
    }
  )
}

test_that("missing categories and row missing counts retain their positions", {
  d <- tibble::tibble(g = c("a", "a", "b", "b"), x = c(1, NA, 2, NA))
  out <- tab(d, x, .by = g)
  expect_identical(out$g, c("a", "a", "b", "b"))
  expect_identical(is.na(out$x), c(FALSE, TRUE, FALSE, TRUE))
  expect_equal(out$cum, c(50, 100, 50, 100))
  counts <- dplyr::mutate(d, observed = row_non_miss(x))
  expect_identical(counts$observed, c(1L, 0L, 1L, 0L))
  expect_equal(row_max(d["x"]), d$x)
})

test_that("row helpers can use grouping columns in grouped mutate()", {
  data <- dplyr::group_by(tibble::tibble(k = c(1, 1, 2), a = c(3, 0, 1)), k)
  out <- dplyr::mutate(data, s = row_sum(k, a), m = row_min(k, a))
  expect_identical(out$s, c(4, 1, 3))
  expect_identical(out$m, pmin(c(1, 1, 2), c(3, 0, 1)))
  expect_error(
    dplyr::mutate(data, s = row_sum(k, missing_column)),
    "missing_column"
  )
})

test_that("PROBLEMS2 row sums consume na.rm rather than adding it", {
  data <- tibble::tibble(a = c(1, NA, NA), b = c(NA, 2, NA))
  expect_identical(row_sum(data, na.rm = TRUE), c(1, 2, 0))
  expect_identical(row_sum(data, na.rm = FALSE), rep(NA_real_, 3))
  expect_identical(row_sum(data), c(1, 2, 0))
  out <- dplyr::mutate(data, sum = row_sum(a, b, na.rm = FALSE))
  expect_identical(out$sum, rep(NA_real_, 3))
  expect_identical(row_sum(data[FALSE, ], na.rm = FALSE), numeric())
  for (bad in list(NA, 1, logical(), c(TRUE, FALSE))) {
    expect_error(row_sum(data, na.rm = bad), "na.rm")
  }
})

test_that("PROBLEMS2 row sums respect original labelled missing masks", {
  data <- tibble::tibble(
    a = haven::labelled_spss(c(1, 99, 3), na_values = 99),
    b = c(4, 5, haven::tagged_na("a"))
  )
  expect_identical(row_sum(data, na.rm = TRUE), c(5, 5, 3))
  expect_identical(row_sum(data, na.rm = FALSE), c(5, NA_real_, NA_real_))
})

test_that("PROBLEMS2 extrema accept explicit constants without changing selectors", {
  data <- tibble::tibble(x = c(1, 4, NA), y = c(3, 2, NA))
  # Constants never fill rows whose selected values are all missing (as pmin).
  expect_identical(row_min(data, .values = 0.5), c(0.5, 0.5, NA))
  expect_identical(row_max(data, .values = list(2, c(5, 1, NA))), c(5, 4, NA))
  out <- dplyr::mutate(
    data,
    cap = row_min(x, .values = 0.5),
    positional = row_min(c(1, 2)),
    multiple = row_max(x, .values = list(2, c(5, 1, NA)))
  )
  expect_identical(out$cap, c(0.5, 0.5, NA))
  expect_identical(out$positional, c(1, 2, NA_real_))
  expect_identical(out$multiple, c(5, 4, NA))
  expect_error(row_min(data, .values = 1:2), "length")
  expect_error(row_min(data, .values = list(NULL)), "length")
  expect_error(row_min(data, .values = list(list(1))), "one-dimensional")
  expect_error(row_min(data, .values = 1 + 1i), "ordering")
})

test_that("PROBLEMS2 explicit extrema values retain classes and group sizes", {
  dates <- as.Date(c("2024-01-01", "2024-01-03"))
  data <- tibble::tibble(x = dates)
  expect_identical(row_max(data, .values = dates[2]), rep(dates[2], 2))
  expect_identical(row_min(data[FALSE, ], .values = dates[1]), dates[FALSE])
  expect_identical(row_min(tibble::tibble(x = 1:2), .values = 0L), c(0L, 0L))
  grouped <- tibble::tibble(g = c(1, 1, 2), x = c(1, 3, 2)) |>
    dplyr::group_by(g) |>
    dplyr::mutate(value = row_max(x, .values = seq_len(dplyr::n())))
  expect_identical(grouped$value, c(1, 3, 2))
  expect_error(row_min(data, .values = 1), "incompatible")
  missing <- haven::labelled_spss(c(99, 2), na_values = 99)
  expect_identical(
    as.double(row_min(tibble::tibble(x = missing), .values = missing[2])),
    c(NA, 2)
  )
  expect_identical(row_min(tibble::tibble(x = 1:2), .values = list()), 1:2)
})

test_that("PROBLEMS2 extrema treat numeric literals as values like pmin", {
  wide <- tibble::as_tibble(stats::setNames(as.list(1:12), paste0("v", 1:12)))
  wide <- wide[c(1, 1), ]
  wide$v10 <- c(10, 50)
  wide$x <- c(3, 30)
  expect_identical(dplyr::mutate(wide, y = row_min(x, 10))$y, pmin(wide$x, 10))
  expect_identical(dplyr::mutate(wide, y = row_max(x, 10))$y, pmax(wide$x, 10))
  d <- tibble::tibble(id = 1:3, p = c(.2, .7, NA))
  expect_identical(dplyr::mutate(d, y = row_min(p, .5))$y, pmin(d$p, .5))
  expect_identical(dplyr::mutate(d, y = row_min(p, 1))$y, pmin(d$p, 1))
  expect_identical(dplyr::mutate(d, y = row_max(p, -1))$y, pmax(d$p, -1))
  cap <- .5
  expect_identical(dplyr::mutate(d, y = row_min(p, cap))$y, pmin(d$p, .5))
  expect_identical(row_min(d$p, .5), pmin(d$p, .5))
  grouped <- dplyr::mutate(dplyr::group_by(d, id > 1), y = row_min(p, .5))
  expect_identical(grouped$y, pmin(d$p, .5))
  floor0 <- function(v) row_max(v, .values = 0)
  three <- tibble::tibble(a = c(1, 2, 1), b = c(10, 20, 30), c = 1:3)
  expect_identical(dplyr::mutate(three, z = floor0(a))$z, c(1, 2, 1))
  expect_identical(dplyr::mutate(three, z = row_min(a, b))$z, c(1, 2, 1))
})

test_that("PROBLEMS2 row helpers consume na.rm instead of adding a column", {
  d <- tibble::tibble(a = c(1, NA, NA), b = c(3, 2, NA))
  expect_identical(row_mean(d, na.rm = FALSE), c(2, NA, NA))
  expect_identical(row_mean(d, na.rm = TRUE), row_mean(d))
  expect_identical(row_max(d, na.rm = FALSE), c(3, NA, NA))
  expect_identical(row_min(d, na.rm = FALSE), c(1, NA, NA))
  expect_identical(row_median(d, na.rm = FALSE), c(2, NA, NA))
  expect_identical(row_sd(d, na.rm = FALSE), c(stats::sd(c(1, 3)), NA, NA))
  expect_identical(row_var(d, na.rm = FALSE), c(stats::var(c(1, 3)), NA, NA))
  expect_identical(
    dplyr::mutate(d, m = row_mean(a, b, na.rm = FALSE))$m,
    c(2, NA, NA)
  )
  for (fun in list(row_unique, row_miss, row_non_miss)) {
    expect_error(fun(d, na.rm = TRUE), "na.rm")
  }
  expect_error(row_mean(d, na.rm = NA), "na.rm")
})

test_that("row_nvals() ignores missing values like egenmore's rownvals()", {
  a <- c(1, 1, NA, NA)
  b <- c(2, 1, NA, 4)
  c <- c(NA, 1, 3, 4)
  expect_identical(row_nvals(a, b, c), c(2L, 1L, 1L, 1L))
  expect_identical(row_unique(a, b, c), c(3L, 1L, 2L, 2L))
  data <- tibble::tibble(a, b, c)
  expect_identical(
    dplyr::mutate(data, n = row_nvals(a:c))$n,
    row_nvals(a, b, c)
  )
  expect_error(row_nvals(a, b, .missing = NA), ".missing")
})

# Focused behavior contracts before row/binning style adoption.
# Numeric references use base R, with the documented all-missing exceptions.

row_contract_functions <- c(
  "row_mean",
  "row_sum",
  "row_min",
  "row_max",
  "row_median",
  "row_var",
  "row_sd",
  "row_unique",
  "row_miss",
  "row_non_miss"
)


test_that("row contracts: typed zero-row inputs return plain empty vectors", {
  data <- tibble::tibble(a = numeric(), b = integer())
  for (name in row_contract_functions) {
    out <- get(name, mode = "function")(data)
    expect_true(is.atomic(out), info = name)
    expect_length(out, 0)
    expect_null(dim(out))
  }
})

test_that("row contracts: a single observed column has undefined sample variance", {
  data <- tibble::tibble(a = c(1, NA, 5))
  expect_equal(row_var(data), rep(NA_real_, 3))
  expect_equal(row_sd(data), rep(NA_real_, 3))
  expect_equal(row_sum(data), c(1, 0, 5))
  expect_equal(row_mean(data), c(1, NA_real_, 5))
})

test_that("row contracts: logical and integer inputs remain unmodified", {
  data <- tibble::tibble(
    a = structure(c(1L, 2L, NA_integer_), label = "First item"),
    b = c(TRUE, FALSE, NA)
  )
  before <- serialize(data, NULL)
  expect_equal(row_sum(data), c(2, 2, 0))
  expect_equal(row_var(data), c(0, 2, NA_real_))
  expect_identical(serialize(data, NULL), before)
})

test_that("row contracts: explicit pick and bare selectors agree in mutate", {
  data <- tibble::tibble(a = c(1, NA, 3), b = c(3, NA, 5), id = 1:3)
  for (name in row_contract_functions) {
    fn <- get(name, mode = "function")
    out <- dplyr::mutate(
      data,
      bare = fn(a, b),
      explicit = fn(dplyr::pick(a, b))
    )
    expect_equal(out$bare, .milestone_row_reference(data[c("a", "b")], name))
    expect_identical(out$explicit, out$bare)
    all_columns <- dplyr::mutate(
      data[c("a", "b")],
      observed = fn(tidyselect::everything())
    )
    expect_identical(all_columns$observed, out$bare)
  }
})

test_that("row contracts: grouped mutate preserves grouping and row order", {
  data <- dplyr::group_by(
    tibble::tibble(g = c("b", "a", "b"), a = c(1, NA, 3), b = c(3, 5, 5)),
    g
  )
  out <- dplyr::mutate(data, total = row_sum(a, b), variance = row_var(a, b))
  expect_identical(dplyr::group_vars(out), "g")
  expect_identical(out$g, data$g)
  expect_equal(out$total, c(4, 5, 8))
  expect_equal(out$variance, c(2, NA_real_, 2))
})

test_that("row contracts: an accepted data-frame expression runs once", {
  calls <- new.env(parent = emptyenv())
  calls$n <- 0L
  data <- tibble::tibble(a = c(1, NA), b = c(3, 5))
  out <- dplyr::mutate(
    data,
    total = row_sum({
      calls$n <- calls$n + 1L
      tibble::tibble(a = a, b = b)
    })
  )
  expect_identical(calls$n, 1L)
  expect_equal(out$total, c(4, 5))
})

test_that("row contracts: accepted data-frame warnings are replayed once", {
  calls <- new.env(parent = emptyenv())
  calls$n <- 0L
  warnings <- character()
  selected <- tibble::tibble(a = c(1, NA), b = c(3, 5))
  make_data <- function() {
    calls$n <- calls$n + 1L
    warning("intentional row input warning", call. = FALSE)
    selected
  }
  out <- withCallingHandlers(
    dplyr::mutate(selected, total = row_sum(make_data())),
    warning = function(condition) {
      warnings <<- c(warnings, conditionMessage(condition))
      invokeRestart("muffleWarning")
    }
  )
  expect_identical(calls$n, 1L)
  expect_length(warnings, 1)
  expect_match(warnings, "intentional row input warning")
  expect_equal(out$total, c(4, 5))
})

test_that("row contracts: counts accept nonnumeric columns and return integers", {
  data <- tibble::tibble(
    text = c("", NA, "x"),
    category = factor(c(NA, "a", "a")),
    nested = list(NULL, NA, 1:2)
  )
  expect_identical(row_miss(data), c(1L, 2L, 0L))
  expect_identical(row_non_miss(data), c(2L, 1L, 3L))
})

test_that("row contracts: arithmetic helpers reject character columns clearly", {
  data <- tibble::tibble(a = c("1", "2"))
  for (name in c("row_sum", "row_mean", "row_median", "row_var", "row_sd")) {
    expect_error(get(name, mode = "function")(data), "numeric or logical")
  }
})

test_that("row helpers report invalid input", {
  d <- tibble::tibble(a = 1:2, b = c("x", "y"), d = as.Date("2020-01-01") + 0:1)
  expect_snapshot(error = TRUE, {
    row_mean(d$a, na.rm = NA)
    row_unique(d$a, na.rm = TRUE)
    row_nvals(d$a, na.rm = TRUE)
    row_mean(d$a, d$b)
    row_sum(d$d, d$d + 1)
    row_max(d$a, .values = list(1:3))
    row_max(d$a, factor(c("u", "v")))
    dplyr::mutate(d, m = row_mean(tidyselect::where(is.list)))
  })
})
