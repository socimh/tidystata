# Comprehensive Test Suite for browse() Function
# Interactive data browsing (Stata-style)

# CHALLENGE: Comprehensive testing for browse
# FUNCTIONS: browse
# KEY BEHAVIORS: interactive data browsing, display modes
# EDGE CASES: large datasets, console width

# ============================================================================
# CHALLENGING TESTS - Basic Functionality
# ============================================================================

test_that("browse: returns input data frame invisibly", {
  df <- tibble::tibble(x = 1:5, y = 6:10)
  result <- browse(df)
  expect_equal(result, df)
})

test_that("browse: with no selection shows all columns", {
  df <- tibble::tibble(x = 1:5, y = 6:10, z = 11:15)
  result <- browse(df)
  expect_equal(ncol(result), 3)
})

test_that("browse: with column selection", {
  df <- tibble::tibble(x = 1:5, y = 6:10, z = 11:15)
  result <- browse(df, x, z)
  expect_equal(ncol(result), 2)
  expect_equal(names(result), c("x", "z"))
})

test_that("browse: with tidyselect helpers", {
  df <- tibble::tibble(
    temp_1 = 1:5,
    temp_2 = 6:10,
    pressure_1 = 11:15,
    pressure_2 = 16:20
  )
  result <- browse(df, dplyr::starts_with("temp"))
  expect_equal(ncol(result), 2)
  expect_true(all(grepl("^temp", names(result))))
})

# ============================================================================
# CHALLENGING TESTS - Column Selection Patterns
# ============================================================================

test_that("browse: with column range", {
  df <- tibble::tibble(a = 1:5, b = 6:10, c = 11:15, d = 16:20)
  result <- browse(df, b:d)
  expect_equal(ncol(result), 3)
  expect_equal(names(result), c("b", "c", "d"))
})

test_that("browse: with where() selection", {
  df <- tibble::tibble(
    num1 = 1:5,
    num2 = 6:10,
    char = letters[1:5],
    logi = c(TRUE, FALSE, TRUE, FALSE, TRUE)
  )
  result <- browse(df, dplyr::where(is.numeric))
  expect_equal(ncol(result), 2)
})

test_that("browse: reorders columns", {
  df <- tibble::tibble(a = 1:5, b = 6:10, c = 11:15)
  result <- browse(df, c, a)
  expect_equal(names(result), c("c", "a"))
})

# ============================================================================
# CHALLENGING TESTS - Data Types
# ============================================================================

test_that("browse: handles various data types", {
  df <- tibble::tibble(
    int_col = 1:5,
    dbl_col = c(1.5, 2.5, 3.5, 4.5, 5.5),
    chr_col = letters[1:5],
    fct_col = factor(letters[1:5]),
    logi_col = c(TRUE, FALSE, TRUE, FALSE, TRUE),
    date_col = seq(as.Date("2024-01-01"), by = "day", length.out = 5)
  )
  result <- browse(df)
  expect_equal(ncol(result), 6)
})

test_that("browse: handles haven labelled data", {
  skip_if_not_installed("haven")
  df <- tibble::tibble(
    x = haven::labelled(1:5, labels = c(Low = 1, High = 5)),
    y = 6:10
  )
  result <- browse(df, x)
  expect_equal(ncol(result), 1)
})

# ============================================================================
# CHALLENGING TESTS - Edge Cases
# ============================================================================

test_that("browse: single column data frame", {
  df <- tibble::tibble(only = 1:5)
  result <- browse(df)
  expect_equal(ncol(result), 1)
})

test_that("browse: empty data frame with columns", {
  df <- tibble::tibble(x = numeric(0), y = character(0))
  result <- browse(df)
  expect_equal(nrow(result), 0)
  expect_equal(ncol(result), 2)
})

test_that("browse: many columns", {
  df <- tibble::as_tibble(replicate(100, 1:5), .name_repair = "minimal")
  names(df) <- paste0("var", 1:100)
  result <- browse(df)
  expect_equal(ncol(result), 100)
})

test_that("browse: single row", {
  df <- tibble::tibble(x = 1, y = 2, z = 3)
  result <- browse(df, x, y)
  expect_equal(nrow(result), 1)
  expect_equal(ncol(result), 2)
})

# ============================================================================
# CHALLENGING TESTS - Special Column Names
# ============================================================================

test_that("browse: columns with spaces in names", {
  df <- tibble::tibble(
    `var with spaces` = 1:5,
    `another var` = 6:10
  )
  result <- browse(df, `var with spaces`)
  expect_equal(ncol(result), 1)
})

test_that("browse: columns with special characters", {
  df <- tibble::tibble(
    `var-1` = 1:5,
    `var.2` = 6:10,
    `var_3` = 11:15
  )
  result <- browse(df)
  expect_equal(ncol(result), 3)
})

# ============================================================================
# CHALLENGING TESTS - Real-world Scenarios
# ============================================================================

test_that("browse: survey data exploration", {
  withr::local_preserve_seed()
  survey <- tibble::tibble(
    respondent_id = 1:100,
    q1_gender = sample(c("M", "F"), 100, replace = TRUE),
    q2_age = sample(18:80, 100, replace = TRUE),
    q3_income = sample(1:10, 100, replace = TRUE),
    q4_satisfaction = sample(1:5, 100, replace = TRUE),
    completion_time = runif(100, 1, 10)
  )

  # Browse only demographic questions
  demo_vars <- browse(
    survey,
    respondent_id,
    dplyr::starts_with("q1"),
    dplyr::starts_with("q2")
  )
  expect_equal(ncol(demo_vars), 3)
})

test_that("browse: time series data inspection", {
  withr::local_preserve_seed()
  ts_data <- tibble::tibble(
    date = seq(as.Date("2024-01-01"), by = "day", length.out = 30),
    open_price = cumsum(rnorm(30)) + 100,
    high_price = cumsum(rnorm(30)) + 102,
    low_price = cumsum(rnorm(30)) + 98,
    close_price = cumsum(rnorm(30)) + 101,
    volume = sample(1000000:10000000, 30)
  )

  # Browse only price columns
  price_data <- browse(ts_data, date, dplyr::ends_with("_price"))
  expect_equal(ncol(price_data), 5)
})

test_that("browse: model diagnostics data", {
  withr::local_preserve_seed()
  model_data <- tibble::tibble(
    observation = 1:100,
    fitted = rnorm(100),
    residual = rnorm(100),
    std_residual = rnorm(100),
    leverage = runif(100),
    cooks_d = runif(100, 0, 1)
  )

  # Browse diagnostic measures
  diagnostics <- browse(
    model_data,
    observation,
    residual,
    std_residual,
    cooks_d
  )
  expect_equal(ncol(diagnostics), 4)
})

# ============================================================================
# CHALLENGING TESTS - Pipeline Integration
# ============================================================================

test_that("browse: works in dplyr pipeline", {
  result <- mtcars %>%
    dplyr::filter(mpg > 20) %>%
    dplyr::select(mpg, wt, hp) %>%
    browse(mpg, wt, hp)

  expected <- mtcars %>% dplyr::filter(mpg > 20) %>% dplyr::select(mpg, wt, hp)
  expect_identical(result, expected)
  expect_true(all(result$mpg > 20))
})

test_that("browse: chain with other operations", {
  result <- starwars %>%
    dplyr::select(name:mass) %>%
    dplyr::filter(!is.na(mass)) %>%
    browse(name, mass)

  expect_false(any(is.na(result$mass)))
})

# ============================================================================
# CHALLENGING TESTS - data.table Compatibility
# ============================================================================

test_that("browse: works with data.table", {
  skip_if_not_installed("data.table")
  dt <- data.table::data.table(x = 1:5, y = 6:10, z = 11:15)
  result <- browse(dt, x, y)
  expect_s3_class(result, "data.table")
  expect_equal(ncol(result), 2)
})
