# Comprehensive Test Suite for s_type() and s_unit() Functions
# Type detection and unit extraction

# CHALLENGE: Comprehensive testing for s_type, s_unit
# FUNCTIONS: s_type, s_unit
# KEY BEHAVIORS: type detection, unit extraction
# EDGE CASES: ambiguous types, compound units

library(testthat)
library(statart)
library(dplyr)
library(tibble)
library(haven)

# ============================================================================
# CHALLENGING TESTS - s_type() Basic Types
# ============================================================================

test_that("s_type: integer vector", {
  x <- 1:5
  result <- s_type(x)
  expect_type(result, "character")
  expect_equal(result, "integer")
})

test_that("s_type: double vector", {
  x <- c(1.5, 2.5, 3.5)
  result <- s_type(x)
  expect_equal(result, "double")
})

test_that("s_type: character vector", {
  x <- letters[1:5]
  result <- s_type(x)
  expect_equal(result, "character")
})

test_that("s_type: logical vector", {
  x <- c(TRUE, FALSE, TRUE)
  result <- s_type(x)
  expect_equal(result, "logical")
})

test_that("s_type: factor", {
  x <- factor(c("a", "b", "c"))
  result <- s_type(x)
  expect_equal(result, "factor")
})

test_that("s_type: ordered factor", {
  x <- ordered(c("low", "medium", "high"))
  result <- s_type(x)
  expect_equal(result, "ordered")
})

test_that("s_type: abbreviation mode", {
  x <- 1:5
  result_full <- s_type(x, .abbr = FALSE)
  result_abbr <- s_type(x, .abbr = TRUE)
  expect_equal(result_full, "integer")
  expect_equal(result_abbr, "int")
})

# ============================================================================
# CHALLENGING TESTS - s_type() Date/Time Types
# ============================================================================

test_that("s_type: Date", {
  x <- as.Date(c("2024-01-01", "2024-06-15"))
  result <- s_type(x)
  expect_equal(result, "date")
})

test_that("s_type: POSIXct (datetime)", {
  x <- as.POSIXct(c("2024-01-01 10:00:00", "2024-06-15 14:30:00"))
  result <- s_type(x)
  expect_equal(result, "datetime")
})

test_that("s_type: difftime (duration)", {
  x <- as.difftime(c(1, 2, 3), units = "hours")
  result <- s_type(x)
  expect_equal(result, "duration")
})

test_that("s_type: hms time", {
  skip_if_not_installed("hms")
  x <- hms::as_hms(c("08:00:00", "12:00:00"))
  result <- s_type(x)
  expect_type(result, "character")
})

# ============================================================================
# CHALLENGING TESTS - s_type() Complex Types
# ============================================================================

test_that("s_type: haven labelled", {
  x <- labelled(c(1, 2, 1), labels = c(Yes = 1, No = 2))
  result <- s_type(x)
  expect_type(result, "character")
  expect_true(grepl("label|lbl", result))
})

test_that("s_type: list", {
  x <- list(1, 2, 3)
  result <- s_type(x)
  expect_type(result, "character")
})

test_that("s_type: data frame", {
  x <- tibble(a = 1:5, b = 6:10)
  result <- s_type(x)
  expect_type(result, "character")
})

test_that("s_type: complex numbers", {
  x <- c(1+2i, 3+4i)
  result <- s_type(x)
  expect_equal(result, "complex")
})

test_that("s_type: function", {
  x <- mean
  result <- s_type(x)
  expect_equal(result, "function")
})

# ============================================================================
# CHALLENGING TESTS - s_type() Edge Cases
# ============================================================================

test_that("s_type: NA vector", {
  x <- c(NA, NA, NA)
  result <- s_type(x)
  expect_type(result, "character")
})

test_that("s_type: empty vector", {
  x <- numeric(0)
  result <- s_type(x)
  expect_type(result, "character")
})

test_that("s_type: single element", {
  x <- 42
  result <- s_type(x)
  expect_equal(result, "double")
})

test_that("s_type: Inf values", {
  x <- c(1, Inf, -Inf)
  result <- s_type(x)
  expect_equal(result, "double")
})

test_that("s_type: NaN values", {
  x <- c(1, NaN, 3)
  result <- s_type(x)
  expect_equal(result, "double")
})

# ============================================================================
# CHALLENGING TESTS - s_type() Within Data Frames
# ============================================================================

test_that("s_type: applied to each column with summarise", {
  df <- tibble(
    int_col = 1:5,
    dbl_col = c(1.5, 2.5, 3.5, 4.5, 5.5),
    chr_col = letters[1:5],
    fct_col = factor(letters[1:5]),
    logi_col = c(TRUE, FALSE, TRUE, FALSE, TRUE)
  )
  
  result <- df %>%
    summarise(across(everything(), s_type))
  
  expect_s3_class(result, "tbl_df")
  expect_equal(result$int_col, "integer")
  expect_equal(result$dbl_col, "double")
  expect_equal(result$chr_col, "character")
  expect_equal(result$fct_col, "factor")
  expect_equal(result$logi_col, "logical")
})

test_that("s_type: within mutate for type checking", {
  df <- tibble(
    x = 1:5,
    y = letters[1:5]
  )
  
  result <- df %>%
    mutate(x_type = s_type(x), y_type = s_type(y))
  
  expect_equal(result$x_type[1], "integer")
  expect_equal(result$y_type[1], "character")
})

# ============================================================================
# CHALLENGING TESTS - s_unit()
# ============================================================================

test_that("s_unit: units object", {
  skip_if_not_installed("units")
  x <- units::set_units(c(1, 2, 3), "m")
  result <- s_unit(x)
  expect_type(result, "character")
  expect_false(is.na(result))
})

test_that("s_unit: difftime with units", {
  x <- as.difftime(c(1, 2, 3), units = "hours")
  result <- s_unit(x)
  expect_type(result, "character")
  expect_false(is.na(result))
})

test_that("s_unit: hms time", {
  skip_if_not_installed("hms")
  x <- hms::as_hms(c("08:00:00", "12:00:00"))
  result <- s_unit(x)
  expect_type(result, "character")
})

test_that("s_unit: regular numeric returns NA", {
  x <- 1:5
  result <- s_unit(x)
  expect_true(is.na(result))
})

test_that("s_unit: character returns NA", {
  x <- letters[1:5]
  result <- s_unit(x)
  expect_true(is.na(result))
})

test_that("s_unit: factor returns NA", {
  x <- factor(c("a", "b", "c"))
  result <- s_unit(x)
  expect_true(is.na(result))
})

# ============================================================================
# CHALLENGING TESTS - Integration with Codebook Workflow
# ============================================================================

test_that("s_type: used in codebook workflow", {
  df <- tibble(
    id = 1:100,
    income = rnorm(100, 50000, 10000),
    gender = sample(c("M", "F"), 100, replace = TRUE),
    score = sample(1:100, 100)
  )
  
  # Simulate codebook variable summary
  var_summary <- df %>%
    summarise(across(everything(), list(
      type = s_type,
      n = ~ sum(!is.na(.))
    )))
  
  expect_s3_class(var_summary, "tbl_df")
})

test_that("s_type: type validation function", {
  is_numeric_type <- function(x) {
    type <- s_type(x, .abbr = TRUE)
    type %in% c("int", "dbl")
  }
  
  expect_true(is_numeric_type(1:5))
  expect_true(is_numeric_type(c(1.5, 2.5)))
  expect_false(is_numeric_type(letters[1:5]))
  expect_false(is_numeric_type(factor(c("a", "b"))))
})

# ============================================================================
# CHALLENGING TESTS - Real-world Scenarios
# ============================================================================

test_that("s_type: data audit workflow", {
  audit_data <- tibble(
    transaction_id = 1:1000,
    amount = rnorm(1000, 100, 20),
    currency = sample(c("USD", "EUR", "GBP"), 1000, replace = TRUE),
    timestamp = Sys.time() + 1:1000,
    is_valid = sample(c(TRUE, FALSE), 1000, replace = TRUE)
  )
  
  # Get type summary for all columns
  type_summary <- audit_data %>%
    summarise(across(everything(), s_type))
  
  expect_equal(type_summary$transaction_id, "integer")
  expect_equal(type_summary$amount, "double")
  expect_equal(type_summary$currency, "character")
  expect_equal(type_summary$is_valid, "logical")
})

test_that("s_type: ETL pipeline type checking", {
  raw_data <- tibble(
    id = as.character(1:100),  # IDs stored as character
    value = rep(c("100.5", "200.3", "150.0"), length.out = 100),  # Values as character
    date = rep(c("2024-01-01", "2024-01-02", "2024-01-03"), length.out = 100)  # Dates as character
  )
  
  # Check types before conversion
  original_types <- raw_data %>%
    summarise(across(everything(), s_type))
  
  expect_equal(unique(unlist(original_types)), "character")
  
  # After conversion
  clean_data <- raw_data %>%
    mutate(
      id = as.integer(id),
      value = as.numeric(value),
      date = as.Date(date)
    )
  
  clean_types <- clean_data %>%
    summarise(across(everything(), s_type))
  
  expect_equal(clean_types$id, "integer")
  expect_equal(clean_types$value, "double")
  expect_equal(clean_types$date, "date")
})
