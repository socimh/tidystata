# Comprehensive Test Suite for varlist() Function
# Stata-style pattern matching for column selection

# CHALLENGE: Comprehensive testing for varlist
# FUNCTIONS: varlist
# KEY BEHAVIORS: pattern matching, regex support
# EDGE CASES: complex patterns, no matches

# ============================================================================
# CHALLENGING TESTS - Basic Pattern Matching
# ============================================================================

test_that("varlist: exact match", {
  df <- tibble::tibble(x = 1:5, y = 6:10, z = 11:15)
  result <- df %>% dplyr::select(varlist("x"))
  expect_equal(ncol(result), 1)
  expect_equal(names(result), "x")
})

test_that("varlist: wildcard with * (zero or more characters)", {
  df <- tibble::tibble(
    var_1 = 1:5,
    var_2 = 6:10,
    var_10 = 11:15,
    other = 16:20
  )
  result <- df %>% dplyr::select(varlist("var*"))
  expect_equal(ncol(result), 3)
})

test_that("varlist: wildcard at start", {
  df <- tibble::tibble(
    item_1 = 1:5,
    item_2 = 6:10,
    temp_1 = 11:15
  )
  result <- df %>% dplyr::select(varlist("*_1"))
  expect_equal(ncol(result), 2)
})

test_that("varlist: wildcard in middle", {
  df <- tibble::tibble(
    temp_morning = 1:5,
    temp_evening = 6:10,
    pressure_morning = 11:15
  )
  result <- df %>% dplyr::select(varlist("temp*"))
  expect_equal(ncol(result), 2)
})

test_that("varlist: single character with ?", {
  df <- tibble::tibble(
    x1 = 1:5,
    x2 = 6:10,
    x10 = 11:15,
    y1 = 16:20
  )
  result <- df %>% dplyr::select(varlist("x?"))
  expect_equal(ncol(result), 2) # x1 and x2, not x10
})

test_that("varlist: one or more characters with ~", {
  df <- tibble::tibble(
    x1 = 1:5,
    x12 = 6:10,
    x = 11:15,
    y1 = 16:20
  )
  result <- df %>% dplyr::select(varlist("x~"))
  expect_equal(ncol(result), 2) # x1 and x12, not x
})

# ============================================================================
# CHALLENGING TESTS - Range Patterns
# ============================================================================

test_that("varlist: numeric range [1-3]", {
  df <- tibble::tibble(
    item_1 = 1:5,
    item_2 = 6:10,
    item_3 = 11:15,
    item_10 = 16:20
  )
  result <- df %>% dplyr::select(varlist("item_[1-3]"))
  expect_equal(ncol(result), 3)
})

test_that("varlist: letter range [a-c]", {
  df <- tibble::tibble(
    var_a = 1:5,
    var_b = 6:10,
    var_c = 11:15,
    var_d = 16:20
  )
  result <- df %>% dplyr::select(varlist("var_[a-c]"))
  expect_equal(ncol(result), 3)
})

test_that("varlist: combined pattern with range", {
  df <- tibble::tibble(
    q1_score = 1:5,
    q2_score = 6:10,
    q3_score = 11:15,
    q10_score = 16:20
  )
  result <- df %>% dplyr::select(varlist("q[1-3]_score"))
  expect_equal(ncol(result), 3)
})

# ============================================================================
# CHALLENGING TESTS - Multiple Patterns
# ============================================================================

test_that("varlist: multiple patterns with space separation", {
  df <- tibble::tibble(
    temp_1 = 1:5,
    temp_2 = 6:10,
    pressure_1 = 11:15,
    pressure_2 = 16:20
  )
  result <- df %>% dplyr::select(varlist("temp_1 pressure_1"))
  expect_equal(ncol(result), 2)
})

test_that("varlist: multiple wildcards", {
  df <- tibble::tibble(
    var_1_temp = 1:5,
    var_2_temp = 6:10,
    var_1_press = 11:15
  )
  result <- df %>% dplyr::select(varlist("var*_temp"))
  expect_equal(ncol(result), 2)
})

# ============================================================================
# CHALLENGING TESTS - Case Sensitivity
# ============================================================================

test_that("varlist: case insensitive by default", {
  df <- tibble::tibble(
    Temp = 1:5,
    TEMP = 6:10,
    temp = 11:15,
    other = 16:20
  )
  result <- df %>% dplyr::select(varlist("temp"))
  expect_equal(ncol(result), 3)
})

test_that("varlist: case sensitive when specified", {
  df <- tibble::tibble(
    Temp = 1:5,
    TEMP = 6:10,
    temp = 11:15
  )
  result <- df %>% dplyr::select(varlist("temp", ignore.case = FALSE))
  expect_equal(ncol(result), 1)
})

# ============================================================================
# CHALLENGING TESTS - Edge Cases
# ============================================================================

test_that("varlist: no matches returns empty selection", {
  df <- tibble::tibble(x = 1:5, y = 6:10, z = 11:15)
  result <- df %>% dplyr::select(varlist("nonexistent"))
  expect_equal(ncol(result), 0)
})

test_that("varlist: matches all with * alone", {
  df <- tibble::tibble(x = 1:5, y = 6:10, z = 11:15)
  result <- df %>% dplyr::select(varlist("*"))
  expect_equal(ncol(result), 3)
})

test_that("varlist: special characters in names", {
  df <- tibble::tibble(
    `var-1` = 1:5,
    `var_2` = 6:10,
    `var.3` = 11:15
  )
  result <- df %>% dplyr::select(varlist("var*"))
  expect_true(ncol(result) >= 1)
})

test_that("varlist: numeric column names", {
  df <- tibble::tibble(`1` = 1:5, `2` = 6:10, `10` = 11:15)
  result <- df %>% dplyr::select(varlist("1"))
  expect_true(ncol(result) >= 1)
})

# ============================================================================
# CHALLENGING TESTS - Integration with ds()
# ============================================================================

test_that("varlist: used with ds()", {
  df <- tibble::tibble(
    temp_1 = 1:5,
    temp_2 = 6:10,
    pressure_1 = 11:15
  )
  result <- ds(df, varlist("temp*"))
  expect_equal(result, c("temp_1", "temp_2"))
})

test_that("varlist: used with variables()", {
  df <- tibble::tibble(
    q1 = 1:5,
    q2 = 6:10,
    q3 = 11:15,
    other = 16:20
  )
  result <- variables(df, varlist("q?"))
  expect_equal(nrow(result), 3)
})

# ============================================================================
# CHALLENGING TESTS - Real-world Scenarios
# ============================================================================

test_that("varlist: survey question selection", {
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
  questions_1_9 <- survey %>% dplyr::select(varlist("q[1-9]_*"))
  expect_true(ncol(questions_1_9) >= 3)

  # Select all questions
  all_questions <- survey %>% dplyr::select(varlist("q*"))
  expect_equal(ncol(all_questions), 4)
})

test_that("varlist: time series variable selection", {
  withr::local_preserve_seed()
  ts_data <- tibble::tibble(
    date = seq(as.Date("2024-01-01"), by = "day", length.out = 30),
    price_2024 = cumsum(rnorm(30)) + 100,
    volume_2024 = sample(1000:10000, 30),
    price_2023 = cumsum(rnorm(30)) + 95,
    volume_2023 = sample(1000:10000, 30)
  )

  # Select 2024 data
  data_2024 <- ts_data %>% dplyr::select(varlist("*_2024"))
  expect_equal(ncol(data_2024), 2)
  expect_true(all(grepl("2024", names(data_2024))))
})

test_that("varlist: panel data variable selection", {
  withr::local_preserve_seed()
  panel_data <- tibble::tibble(
    country = rep(c("USA", "UK", "DE"), each = 10),
    year = rep(2014:2023, 3),
    gdp_usa = c(rnorm(10, 20000, 1000), rep(NA, 20)),
    gdp_uk = c(rep(NA, 10), rnorm(10, 3000, 200), rep(NA, 10)),
    gdp_de = c(rep(NA, 20), rnorm(10, 4000, 300))
  )

  # Select all gdp variables
  gdp_vars <- panel_data %>% dplyr::select(varlist("gdp*"))
  expect_equal(ncol(gdp_vars), 3)
})

# ============================================================================
# CHALLENGING TESTS - Complex Patterns
# ============================================================================

test_that("varlist: complex combined patterns", {
  df <- tibble::tibble(
    temp_jan_2024 = 1:5,
    temp_feb_2024 = 6:10,
    temp_jan_2023 = 11:15,
    temp_feb_2023 = 16:20,
    pressure_jan_2024 = 21:25
  )

  # Select temp variables from 2024
  temp_2024 <- df %>% dplyr::select(varlist("temp*_2024"))
  expect_equal(ncol(temp_2024), 2)
})

test_that("varlist: pattern with multiple ranges", {
  df <- tibble::tibble(
    item_a1 = 1:5,
    item_a2 = 6:10,
    item_b1 = 11:15,
    item_b2 = 16:20
  )

  # Should error with multiple ranges
  expect_error(df %>% dplyr::select(varlist("item_[a-b][1-2]")))
})

# ============================================================================
# CHALLENGING TESTS - Error Handling
# ============================================================================

test_that("varlist: invalid pattern errors", {
  df <- tibble::tibble(x = 1:5, y = 6:10)
  # Invalid regex pattern should error
  expect_warning(
    expect_error(df %>% dplyr::select(varlist("["))),
    "TRE pattern compilation error"
  )
})

test_that("varlist: NULL pattern", {
  df <- tibble::tibble(x = 1:5)
  expect_error(df %>% dplyr::select(varlist(NULL)))
})

test_that("varlist diagnoses noncharacter patterns without changing selections", {
  for (pattern in list(1, TRUE, NULL, list("x*"), factor("x*"))) {
    expect_error(
      varlist(pattern, vars = c("x1", "x2", "y")),
      "`string` must be a character string"
    )
  }
  expect_identical(varlist("x*", vars = c("x1", "x2", "y")), c(1L, 2L))
  expect_identical(varlist(NA_character_, vars = c("NA", "x")), 1L)
})

test_that("varlist expands numeric ranges in every pattern position", {
  vars <- c("x1", "x2", "x3", "y", "z", "prefix_x1", "x2_tail", "X1")
  expect_no_warning(
    first <- varlist("x[1-2] y", vars = vars)
  )
  expect_identical(first, c(1L, 2L, 4L, 8L))
  expect_identical(varlist("y x[1-2]", vars = vars), c(1L, 2L, 4L, 8L))
  expect_identical(varlist("y x[1-2] z", vars = vars), c(1L, 2L, 4L, 5L, 8L))
})

test_that("varlist anchors complete expanded alternatives", {
  vars <- c("x1", "x12", "x120", "y", "prefix_x1", "x12_tail", "y_tail")
  expect_identical(varlist("x[1-12] y", vars = vars), c(1L, 2L, 4L))
  expect_identical(varlist("y x[1-12]", vars = vars), c(1L, 2L, 4L))
  expect_identical(varlist("x[1-12]", vars = vars), c(1L, 2L))
})

test_that("varlist composes ranged patterns with tidyselect exclusions", {
  data <- tibble::tibble(x1 = 1, x2 = 2, y = 3, x2_tail = 4, X1 = 5)
  expect_identical(ds(data, varlist("x[1-2] y")), c("x1", "x2", "y", "X1"))
  expect_identical(ds(data, -varlist("y x[1-2]")), "x2_tail")
  expect_identical(
    ds(data, varlist("y x[1-2]", ignore.case = FALSE)),
    c("x1", "x2", "y")
  )
})

test_that("varlist supports separate ranged tokens without broadening a token", {
  vars <- c("x1", "x2", "y1", "y2", "prefix_x1", "y2_tail")
  expect_identical(varlist("x[1-2] y[1-2]", vars = vars), 1:4)
  expect_identical(
    varlist("y[a-b] x[1-2]", vars = c(vars, "ya", "yb")),
    c(1L, 2L, 7L, 8L)
  )
  expect_error(varlist("x[1-2][3-4] y", vars = vars), "Only one range")
  expect_error(varlist("y x[2-1]", vars = vars), "smaller number")
  expect_identical(varlist(NA_character_, vars = c("NA", "x")), 1L)
})

test_that("varlist returns positions with explicit variables and keeps matching boundaries", {
  vars <- c("x1", "x2", "x10", "prefix_x1", "X1", "xa", "xb")
  expect_identical(varlist("x[1-2]", vars = vars), c(1L, 2L, 5L))
  expect_identical(varlist("x1", ignore.case = FALSE, vars = vars), 1L)
  expect_identical(varlist("x[a-b]", vars = vars), c(6L, 7L))
  expect_identical(varlist("absent*", vars = vars), integer())
  expect_error(varlist("x[2-1]", vars = vars), "smaller number")
  expect_error(varlist("x[1-2][3-4]", vars = vars), "Only one range")
})

test_that("letter range translation remains compatible with ds and varlist", {
  d <- tibble::tibble(xA = 1:2, xB = 3:4, xC = 5:6, xZ = 7:8)
  expect_no_warning(out <- ds(d, varlist("x[A-C]")))
  expect_identical(out, c("xA", "xB", "xC"))
})
