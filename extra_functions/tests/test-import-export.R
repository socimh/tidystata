# Comprehensive Test Suite for Import/Export Functions
# read_data() and write_data()

# CHALLENGE: Comprehensive testing for read_data, write_data
# FUNCTIONS: read_data, write_data
# KEY BEHAVIORS: data import/export, format conversion
# EDGE CASES: encoding issues, large files

library(testthat)
library(statart)
library(dplyr)
library(tibble)

# Create temporary directory for tests
temp_dir <- tempdir()

# ============================================================================
# CHALLENGING TESTS - CSV Files
# ============================================================================

test_that("read_data/write_data: CSV roundtrip", {
  df <- tibble(
    x = 1:5,
    y = letters[1:5],
    z = c(TRUE, FALSE, TRUE, FALSE, TRUE)
  )
  
  file_path <- file.path(temp_dir, "test.csv")
  write_data(df, file_path)
  result <- read_data(file_path)
  
  expect_s3_class(result, "tbl_df")
  expect_equal(nrow(result), 5)
  unlink(file_path)
})

test_that("write_data: CSV preserves data types as best as possible", {
  df <- tibble(
    int_col = 1:5,
    dbl_col = c(1.1, 2.2, 3.3, 4.4, 5.5),
    chr_col = letters[1:5]
  )
  
  file_path <- file.path(temp_dir, "test_types.csv")
  write_data(df, file_path)
  result <- read_data(file_path)
  
  expect_equal(nrow(result), 5)
  expect_equal(ncol(result), 3)
  unlink(file_path)
})

test_that("read_data: CSV with various delimiters", {
  df <- tibble(x = 1:3, y = letters[1:3])
  
  # Test TSV
  tsv_path <- file.path(temp_dir, "test.tsv")
  write_data(df, tsv_path)
  result_tsv <- read_data(tsv_path)
  expect_equal(nrow(result_tsv), 3)
  unlink(tsv_path)
})

# ============================================================================
# CHALLENGING TESTS - RDS Files
# ============================================================================

test_that("read_data/write_data: RDS roundtrip preserves all types", {
  df <- tibble(
    int_col = 1:5,
    dbl_col = c(1.5, 2.5, 3.5, 4.5, 5.5),
    chr_col = letters[1:5],
    fct_col = factor(letters[1:5]),
    logi_col = c(TRUE, FALSE, TRUE, FALSE, TRUE),
    date_col = seq(as.Date("2024-01-01"), by = "day", length.out = 5)
  )
  
  file_path <- file.path(temp_dir, "test.rds")
  write_data(df, file_path)
  result <- read_data(file_path)
  
  expect_equal(result, df)
  unlink(file_path)
})

# ============================================================================
# CHALLENGING TESTS - RData Files
# ============================================================================

test_that("read_data/write_data: RData format", {
  df <- tibble(x = 1:5, y = letters[1:5])
  
  file_path <- file.path(temp_dir, "test.RData")
  write_data(df, file_path)
  # RData loads into environment, returns invisibly
  expect_true(file.exists(file_path))
  unlink(file_path)
})

# ============================================================================
# CHALLENGING TESTS - Excel Files
# ============================================================================

test_that("read_data/write_data: Excel roundtrip (if openxlsx available)", {
  skip_if_not_installed("openxlsx")
  skip_if_not_installed("readxl")
  
  df <- tibble(
    x = 1:5,
    y = letters[1:5],
    z = rnorm(5)
  )
  
  file_path <- file.path(temp_dir, "test.xlsx")
  write_data(df, file_path)
  result <- read_data(file_path)
  
  expect_s3_class(result, "tbl_df")
  expect_equal(nrow(result), 5)
  unlink(file_path)
})

test_that("read_data: Excel with multiple sheets", {
  skip_if_not_installed("openxlsx")
  skip_if_not_installed("readxl")
  
  df1 <- tibble(a = 1:3, b = letters[1:3])
  df2 <- tibble(c = 4:6, d = letters[4:6])
  
  file_path <- file.path(temp_dir, "test_multi.xlsx")
  wb <- openxlsx::createWorkbook()
  openxlsx::addWorksheet(wb, "Sheet1")
  openxlsx::addWorksheet(wb, "Sheet2")
  openxlsx::writeData(wb, "Sheet1", df1)
  openxlsx::writeData(wb, "Sheet2", df2)
  openxlsx::saveWorkbook(wb, file_path, overwrite = TRUE)
  
  # Read first sheet by default
  result <- read_data(file_path)
  expect_equal(nrow(result), 3)
  
  unlink(file_path)
})

# ============================================================================
# CHALLENGING TESTS - Stata DTA Files
# ============================================================================

test_that("read_data/write_data: Stata DTA roundtrip", {
  skip_if_not_installed("haven")
  
  df <- tibble(
    id = 1:5,
    value = c(10.5, 20.3, 15.7, 8.9, 12.4),
    category = c("A", "B", "A", "C", "B")
  )
  
  file_path <- file.path(temp_dir, "test.dta")
  write_data(df, file_path)
  result <- read_data(file_path)
  
  expect_s3_class(result, "tbl_df")
  expect_equal(nrow(result), 5)
  unlink(file_path)
})

test_that("read_data/write_data: Stata with labelled data", {
  skip_if_not_installed("haven")
  
  df <- tibble(
    x = haven::labelled(
      c(1, 2, 1, 2),
      labels = c(Yes = 1, No = 2),
      label = "Response"
    ),
    y = 1:4
  )
  
  file_path <- file.path(temp_dir, "test_labelled.dta")
  write_data(df, file_path)
  result <- read_data(file_path)
  
  expect_s3_class(result, "tbl_df")
  expect_equal(nrow(result), 4)
  unlink(file_path)
})

# ============================================================================
# CHALLENGING TESTS - SPSS SAV Files
# ============================================================================

test_that("read_data/write_data: SPSS SAV roundtrip", {
  skip_if_not_installed("haven")
  
  df <- tibble(
    id = 1:5,
    score = c(85, 92, 78, 88, 95),
    group = c("A", "B", "A", "B", "A")
  )
  
  file_path <- file.path(temp_dir, "test.sav")
  write_data(df, file_path)
  result <- read_data(file_path)
  
  expect_s3_class(result, "tbl_df")
  expect_equal(nrow(result), 5)
  unlink(file_path)
})

# ============================================================================
# CHALLENGING TESTS - Feather Files
# ============================================================================

test_that("read_data/write_data: Feather roundtrip", {
  skip_if_not_installed("arrow")
  
  df <- tibble(
    x = 1:1000,
    y = rnorm(1000),
    z = sample(letters, 1000, replace = TRUE)
  )
  
  file_path <- file.path(temp_dir, "test.feather")
  write_data(df, file_path)
  result <- read_data(file_path)
  
  expect_equal(nrow(result), 1000)
  expect_equal(ncol(result), 3)
  unlink(file_path)
})

# ============================================================================
# CHALLENGING TESTS - JSON Files
# ============================================================================

test_that("read_data/write_data: JSON roundtrip", {
  df <- tibble(
    x = 1:5,
    y = letters[1:5],
    z = c(TRUE, FALSE, TRUE, FALSE, TRUE)
  )
  
  file_path <- file.path(temp_dir, "test.json")
  write_data(df, file_path)
  result <- read_data(file_path)
  
  expect_type(result, "list")
  expect_equal(length(result), 3)
  unlink(file_path)
})

# ============================================================================
# CHALLENGING TESTS - Edge Cases
# ============================================================================

test_that("write_data: empty data frame", {
  df <- tibble(x = numeric(0), y = character(0))
  
  file_path <- file.path(temp_dir, "empty.csv")
  write_data(df, file_path)
  result <- read_data(file_path)
  
  expect_equal(nrow(result), 0)
  unlink(file_path)
})

test_that("write_data: single row", {
  df <- tibble(x = 1, y = "a", z = TRUE)
  
  file_path <- file.path(temp_dir, "single.csv")
  write_data(df, file_path)
  result <- read_data(file_path)
  
  expect_equal(nrow(result), 1)
  unlink(file_path)
})

test_that("write_data: large data frame", {
  df <- tibble(
    id = 1:10000,
    value = rnorm(10000),
    category = sample(letters[1:5], 10000, replace = TRUE)
  )
  
  file_path <- file.path(temp_dir, "large.csv")
  write_data(df, file_path)
  result <- read_data(file_path)
  
  expect_equal(nrow(result), 10000)
  unlink(file_path)
})

test_that("read_data: non-existent file errors", {
  expect_error(read_data("/nonexistent/path/file.csv"))
})

test_that("read_data: unsupported format errors", {
  expect_error(read_data("test.unknown"))
})

test_that("write_data: unsupported format errors", {
  df <- tibble(x = 1)
  expect_error(write_data(df, "test.unknown"))
})

# ============================================================================
# CHALLENGING TESTS - Special Characters and Encoding
# ============================================================================

test_that("write_data: handles unicode characters", {
  df <- tibble(
    latin = c("hello", "world"),
    cjk = c("中文", "日本語"),
    emoji = c("🎉", "🎊")
  )
  
  file_path <- file.path(temp_dir, "unicode.csv")
  write_data(df, file_path)
  result <- read_data(file_path)
  
  expect_equal(nrow(result), 2)
  unlink(file_path)
})

test_that("write_data: handles special characters in column names", {
  df <- tibble(
    `var with spaces` = 1:3,
    `var-with-dashes` = 4:6,
    `var.with.dots` = 7:9
  )
  
  file_path <- file.path(temp_dir, "special_names.csv")
  write_data(df, file_path)
  result <- read_data(file_path)
  
  expect_equal(nrow(result), 3)
  unlink(file_path)
})

# ============================================================================
# CHALLENGING TESTS - NA Handling
# ============================================================================

test_that("read_data/write_data: preserves NA values", {
  df <- tibble(
    x = c(1, NA, 3, NA, 5),
    y = c("a", NA, "c", NA, "e"),
    z = c(TRUE, NA, FALSE, NA, TRUE)
  )
  
  file_path <- file.path(temp_dir, "with_na.csv")
  write_data(df, file_path)
  result <- read_data(file_path)
  
  expect_equal(sum(is.na(result[[1]])), 2)
  unlink(file_path)
})

# ============================================================================
# CHALLENGING TESTS - Real-world Scenarios
# ============================================================================

test_that("import/export: survey data workflow", {
  survey_data <- tibble(
    respondent_id = 1:100,
    q1_gender = sample(c("M", "F"), 100, replace = TRUE),
    q2_age = sample(18:80, 100, replace = TRUE),
    q3_satisfaction = sample(1:5, 100, replace = TRUE),
    completion_time = runif(100, 1, 10)
  )
  
  # Export to CSV
  csv_path <- file.path(temp_dir, "survey.csv")
  write_data(survey_data, csv_path)
  
  # Re-import
  imported <- read_data(csv_path)
  expect_equal(nrow(imported), 100)
  expect_equal(ncol(imported), 5)
  
  unlink(csv_path)
})

test_that("import/export: time series data", {
  ts_data <- tibble(
    date = seq(as.Date("2024-01-01"), by = "day", length.out = 30),
    value = cumsum(rnorm(30)),
    volume = sample(1000:10000, 30)
  )
  
  # Save as RDS for full type preservation
  rds_path <- file.path(temp_dir, "timeseries.rds")
  write_data(ts_data, rds_path)
  
  imported <- read_data(rds_path)
  expect_s3_class(imported$date, "Date")
  
  unlink(rds_path)
})

test_that("import/export: cross-format compatibility", {
  df <- tibble(
    id = 1:10,
    value = rnorm(10),
    category = sample(letters[1:3], 10, replace = TRUE)
  )
  
  # Write to multiple formats
  csv_path <- file.path(temp_dir, "multi.csv")
  rds_path <- file.path(temp_dir, "multi.rds")
  
  write_data(df, csv_path)
  write_data(df, rds_path)
  
  # Read back
  from_csv <- read_data(csv_path)
  from_rds <- read_data(rds_path)
  
  # RDS should preserve exactly
  expect_equal(from_rds, df)
  
  unlink(csv_path)
  unlink(rds_path)
})
