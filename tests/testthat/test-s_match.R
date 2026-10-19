# Comprehensive Test Suite for s_match() Function
# Stata-style pattern matching for column selection

# CHALLENGE: Comprehensive testing for s_match
# FUNCTIONS: s_match
# KEY BEHAVIORS: pattern matching, regex support
# EDGE CASES: complex patterns, no matches

# ============================================================================
# CHALLENGING TESTS - Basic Pattern Matching
# ============================================================================

test_that("s_match: exact match", {
  df <- tibble::tibble(x = 1:5, y = 6:10, z = 11:15)
  result <- df %>% dplyr::select(s_match("x"))
  expect_equal(ncol(result), 1)
  expect_equal(names(result), "x")
})

test_that("s_match: wildcard with * (zero or more characters)", {
  df <- tibble::tibble(
    var_1 = 1:5,
    var_2 = 6:10,
    var_10 = 11:15,
    other = 16:20
  )
  result <- df %>% dplyr::select(s_match("var*"))
  expect_equal(ncol(result), 3)
})

test_that("s_match: wildcard at start", {
  df <- tibble::tibble(
    item_1 = 1:5,
    item_2 = 6:10,
    temp_1 = 11:15
  )
  result <- df %>% dplyr::select(s_match("*_1"))
  expect_equal(ncol(result), 2)
})

test_that("s_match: wildcard in middle", {
  df <- tibble::tibble(
    temp_morning = 1:5,
    temp_evening = 6:10,
    pressure_morning = 11:15
  )
  result <- df %>% dplyr::select(s_match("temp*"))
  expect_equal(ncol(result), 2)
})

test_that("s_match: single character with ?", {
  df <- tibble::tibble(
    x1 = 1:5,
    x2 = 6:10,
    x10 = 11:15,
    y1 = 16:20
  )
  result <- df %>% dplyr::select(s_match("x?"))
  expect_equal(ncol(result), 2) # x1 and x2, not x10
})

test_that("s_match: one or more characters with ~", {
  df <- tibble::tibble(
    x1 = 1:5,
    x12 = 6:10,
    x = 11:15,
    y1 = 16:20
  )
  result <- df %>% dplyr::select(s_match("x~"))
  expect_equal(ncol(result), 2) # x1 and x12, not x
})

# ============================================================================
# CHALLENGING TESTS - Range Patterns
# ============================================================================

test_that("s_match: numeric range [1-3]", {
  df <- tibble::tibble(
    item_1 = 1:5,
    item_2 = 6:10,
    item_3 = 11:15,
    item_10 = 16:20
  )
  result <- df %>% dplyr::select(s_match("item_[1-3]"))
  expect_equal(ncol(result), 3)
})

test_that("s_match: letter range [a-c]", {
  df <- tibble::tibble(
    var_a = 1:5,
    var_b = 6:10,
    var_c = 11:15,
    var_d = 16:20
  )
  result <- df %>% dplyr::select(s_match("var_[a-c]"))
  expect_equal(ncol(result), 3)
})

test_that("s_match: combined pattern with range", {
  df <- tibble::tibble(
    q1_score = 1:5,
    q2_score = 6:10,
    q3_score = 11:15,
    q10_score = 16:20
  )
  result <- df %>% dplyr::select(s_match("q[1-3]_score"))
  expect_equal(ncol(result), 3)
})

# ============================================================================
# CHALLENGING TESTS - Multiple Patterns
# ============================================================================

test_that("s_match: multiple patterns with space separation", {
  df <- tibble::tibble(
    temp_1 = 1:5,
    temp_2 = 6:10,
    pressure_1 = 11:15,
    pressure_2 = 16:20
  )
  result <- df %>% dplyr::select(s_match("temp_1 pressure_1"))
  expect_equal(ncol(result), 2)
})

test_that("s_match: multiple wildcards", {
  df <- tibble::tibble(
    var_1_temp = 1:5,
    var_2_temp = 6:10,
    var_1_press = 11:15
  )
  result <- df %>% dplyr::select(s_match("var*_temp"))
  expect_equal(ncol(result), 2)
})

# ============================================================================
# CHALLENGING TESTS - Case Sensitivity
# ============================================================================

test_that("s_match: case insensitive by default", {
  df <- tibble::tibble(
    Temp = 1:5,
    TEMP = 6:10,
    temp = 11:15,
    other = 16:20
  )
  result <- df %>% dplyr::select(s_match("temp"))
  expect_equal(ncol(result), 3)
})

test_that("s_match: case sensitive when specified", {
  df <- tibble::tibble(
    Temp = 1:5,
    TEMP = 6:10,
    temp = 11:15
  )
  result <- df %>% dplyr::select(s_match("temp", ignore.case = FALSE))
  expect_equal(ncol(result), 1)
})

# ============================================================================
# CHALLENGING TESTS - Edge Cases
# ============================================================================

test_that("s_match: no matches returns empty selection", {
  df <- tibble::tibble(x = 1:5, y = 6:10, z = 11:15)
  result <- df %>% dplyr::select(s_match("nonexistent"))
  expect_equal(ncol(result), 0)
})

test_that("s_match: matches all with * alone", {
  df <- tibble::tibble(x = 1:5, y = 6:10, z = 11:15)
  result <- df %>% dplyr::select(s_match("*"))
  expect_equal(ncol(result), 3)
})

test_that("s_match: special characters in names", {
  df <- tibble::tibble(
    `var-1` = 1:5,
    `var_2` = 6:10,
    `var.3` = 11:15
  )
  result <- df %>% dplyr::select(s_match("var*"))
  expect_true(ncol(result) >= 1)
})

test_that("s_match: numeric column names", {
  df <- tibble::tibble(`1` = 1:5, `2` = 6:10, `10` = 11:15)
  result <- df %>% dplyr::select(s_match("1"))
  expect_true(ncol(result) >= 1)
})

# ============================================================================
# CHALLENGING TESTS - Integration with ds()
# ============================================================================

test_that("s_match: used with ds()", {
  df <- tibble::tibble(
    temp_1 = 1:5,
    temp_2 = 6:10,
    pressure_1 = 11:15
  )
  result <- ds(df, s_match("temp*"))
  expect_equal(result, c("temp_1", "temp_2"))
})

test_that("s_match: used with variables()", {
  df <- tibble::tibble(
    q1 = 1:5,
    q2 = 6:10,
    q3 = 11:15,
    other = 16:20
  )
  result <- variables(df, s_match("q?"))
  expect_equal(nrow(result), 3)
})

# ============================================================================
# CHALLENGING TESTS - Real-world Scenarios
# ============================================================================

test_that("s_match: survey question selection", {
  withr::local_preserve_seed()
  survey <- tibble::tibble(
    respondent_id = 1:100,
    q1_satisfaction = sample(1:5, 100, replace = TRUE),
    q2_recommend = sample(c("Yes", "No"), 100, replace = TRUE),
    q3_age = sample(18:80, 100, replace = TRUE),
    q10_feedback = sample(c("Good", "Bad"), 100, replace = TRUE),
    completion_time = runif(100, 1, 10)
  )

  # Select questions 1-9 (excluding q10)
  questions_1_9 <- survey %>% dplyr::select(s_match("q[1-9]_*"))
  expect_true(ncol(questions_1_9) >= 3)

  # Select all questions
  all_questions <- survey %>% dplyr::select(s_match("q*"))
  expect_equal(ncol(all_questions), 4)
})

test_that("s_match: time series variable selection", {
  withr::local_preserve_seed()
  ts_data <- tibble::tibble(
    date = seq(as.Date("2024-01-01"), by = "day", length.out = 30),
    price_2024 = cumsum(rnorm(30)) + 100,
    volume_2024 = sample(1000:10000, 30),
    price_2023 = cumsum(rnorm(30)) + 95,
    volume_2023 = sample(1000:10000, 30)
  )

  # Select 2024 data
  data_2024 <- ts_data %>% dplyr::select(s_match("*_2024"))
  expect_equal(ncol(data_2024), 2)
  expect_true(all(grepl("2024", names(data_2024))))
})

test_that("s_match: panel data variable selection", {
  withr::local_preserve_seed()
  panel_data <- tibble::tibble(
    country = rep(c("USA", "UK", "DE"), each = 10),
    year = rep(2014:2023, 3),
    gdp_usa = c(rnorm(10, 20000, 1000), rep(NA, 20)),
    gdp_uk = c(rep(NA, 10), rnorm(10, 3000, 200), rep(NA, 10)),
    gdp_de = c(rep(NA, 20), rnorm(10, 4000, 300))
  )

  # Select all gdp variables
  gdp_vars <- panel_data %>% dplyr::select(s_match("gdp*"))
  expect_equal(ncol(gdp_vars), 3)
})

# ============================================================================
# CHALLENGING TESTS - Complex Patterns
# ============================================================================

test_that("s_match: complex combined patterns", {
  df <- tibble::tibble(
    temp_jan_2024 = 1:5,
    temp_feb_2024 = 6:10,
    temp_jan_2023 = 11:15,
    temp_feb_2023 = 16:20,
    pressure_jan_2024 = 21:25
  )

  # Select temp variables from 2024
  temp_2024 <- df %>% dplyr::select(s_match("temp*_2024"))
  expect_equal(ncol(temp_2024), 2)
})

test_that("s_match: pattern with multiple ranges", {
  df <- tibble::tibble(
    item_a1 = 1:5,
    item_a2 = 6:10,
    item_b1 = 11:15,
    item_b2 = 16:20
  )

  # Should error with multiple ranges
  expect_error(df %>% dplyr::select(s_match("item_[a-b][1-2]")))
})

# ============================================================================
# CHALLENGING TESTS - Error Handling
# ============================================================================

test_that("s_match: invalid pattern errors", {
  df <- tibble::tibble(x = 1:5, y = 6:10)
  # Invalid regex pattern should error
  expect_warning(
    expect_error(df %>% dplyr::select(s_match("["))),
    "TRE pattern compilation error"
  )
})

test_that("s_match: NULL pattern", {
  df <- tibble::tibble(x = 1:5)
  expect_error(df %>% dplyr::select(s_match(NULL)))
})
