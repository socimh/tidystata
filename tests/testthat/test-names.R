# Comprehensive Test Suite for Names and Variables Functions
# ds, ds_as_column, names_as_column, variables, variables_search

# CHALLENGE: Comprehensive testing for ds, ds_as_column, names_as_column, variables
# FUNCTIONS: ds, ds_as_column, names_as_column, variables
# KEY BEHAVIORS: variable listing, name manipulation
# EDGE CASES: special characters, long names

# ============================================================================
# CHALLENGING TESTS - ds()
# ============================================================================

test_that("ds: basic column names listing", {
  df <- tibble::tibble(x = 1:5, y = 6:10, z = 11:15)
  result <- ds(df)
  expect_type(result, "character")
  expect_equal(result, c("x", "y", "z"))
})

test_that("ds: empty data frame returns character(0)", {
  df <- tibble::tibble(.rows = 5)
  result <- ds(df)
  expect_equal(length(result), 0)
})

test_that("ds: single column data frame", {
  df <- tibble::tibble(only_col = 1:5)
  result <- ds(df)
  expect_equal(result, "only_col")
})

test_that("ds: many columns", {
  df <- tibble::as_tibble(replicate(100, 1:5), .name_repair = "minimal")
  names(df) <- paste0("var", 1:100)
  result <- ds(df)
  expect_equal(length(result), 100)
})

test_that("ds: with tidyselect - starts_with", {
  df <- tibble::tibble(temp_1 = 1:5, temp_2 = 6:10, pressure = 11:15)
  result <- ds(df, dplyr::starts_with("temp"))
  expect_equal(result, c("temp_1", "temp_2"))
})

test_that("ds: with tidyselect - ends_with", {
  df <- tibble::tibble(var_a_test = 1:5, var_b_test = 6:10, var_c_prod = 11:15)
  result <- ds(df, dplyr::ends_with("_test"))
  expect_equal(result, c("var_a_test", "var_b_test"))
})

test_that("ds: with tidyselect - contains", {
  df <- tibble::tibble(
    temp_morning = 1:5,
    temp_evening = 6:10,
    pressure = 11:15
  )
  result <- ds(df, dplyr::contains("temp"))
  expect_equal(result, c("temp_morning", "temp_evening"))
})

test_that("ds: with tidyselect - where(is.numeric)", {
  df <- tibble::tibble(
    num1 = 1:5,
    num2 = 6:10,
    char = letters[1:5],
    logi = c(TRUE, FALSE, TRUE, FALSE, TRUE)
  )
  result <- ds(df, dplyr::where(is.numeric))
  expect_equal(result, c("num1", "num2"))
})

test_that("ds: with column indices", {
  df <- tibble::tibble(a = 1:5, b = 6:10, c = 11:15, d = 16:20)
  result <- ds(df, 1, 3)
  expect_equal(result, c("a", "c"))
})

test_that("ds: with column range", {
  df <- tibble::tibble(a = 1:5, b = 6:10, c = 11:15, d = 16:20)
  result <- ds(df, b:d)
  expect_equal(result, c("b", "c", "d"))
})

test_that("ds: with everything()", {
  df <- tibble::tibble(x = 1:5, y = 6:10, z = 11:15)
  result <- ds(df, dplyr::everything())
  expect_equal(result, c("x", "y", "z"))
})

test_that("ds: special characters in names", {
  df <- tibble::tibble(
    `var with spaces` = 1:5,
    `var.with.dots` = 6:10,
    `var_with_underscores` = 11:15
  )
  result <- ds(df)
  expect_true("var with spaces" %in% result)
  expect_true("var.with.dots" %in% result)
})

test_that("ds: non-existent selection returns empty", {
  df <- tibble::tibble(x = 1:5, y = 6:10)
  result <- ds(df, dplyr::starts_with("nonexistent"))
  expect_equal(length(result), 0)
})

# ============================================================================
# CHALLENGING TESTS - names_as_column() and ds_as_column()
# ============================================================================

test_that("names_as_column: basic functionality", {
  df <- tibble::tibble(x = 1:5, y = 6:10, z = 11:15)
  result <- names_as_column(df)
  expect_s3_class(result, "tbl_df")
  expect_equal(names(result), "name")
  expect_equal(result$name, c("x", "y", "z"))
})

test_that("names_as_column: empty data frame", {
  df <- tibble::tibble(.rows = 5)
  result <- names_as_column(df)
  expect_equal(nrow(result), 0)
})

test_that("names_as_column: with selection", {
  df <- tibble::tibble(temp_1 = 1:5, temp_2 = 6:10, pressure = 11:15)
  result <- names_as_column(df, dplyr::starts_with("temp"))
  expect_equal(nrow(result), 2)
  expect_equal(result$name, c("temp_1", "temp_2"))
})

test_that("names_as_column: returns tibble with one column", {
  df <- tibble::tibble(a = 1:3, b = 4:6, c = 7:9)
  result <- names_as_column(df)
  expect_equal(ncol(result), 1)
  expect_equal(nrow(result), 3)
})

test_that("ds_as_column: alias works correctly", {
  df <- tibble::tibble(x = 1:5, y = 6:10)
  result_ds <- ds_as_column(df)
  result_names <- names_as_column(df)
  expect_equal(result_ds, result_names)
})

# ============================================================================
# CHALLENGING TESTS - variables()
# ============================================================================

test_that("variables: basic functionality", {
  df <- tibble::tibble(x = 1:5, y = 6:10, z = 11:15)
  result <- variables(df)
  expect_s3_class(result, "tbl_df")
  expect_true("name" %in% names(result))
  expect_equal(result$name, c("x", "y", "z"))
})

test_that("variables: with labels from haven data", {
  df <- tibble::tibble(
    id = 1:5,
    income = haven::labelled(1:5 * 10000, label = "Annual Income"),
    age = haven::labelled(20:24, label = "Respondent Age")
  )
  result <- variables(df)
  expect_s3_class(result, "tbl_df")
  expect_true("name" %in% names(result))
})

test_that("variables: with selection", {
  df <- tibble::tibble(
    temp_1 = 1:5,
    temp_2 = 6:10,
    pressure_1 = 11:15,
    pressure_2 = 16:20
  )
  result <- variables(df, dplyr::starts_with("temp"))
  expect_equal(nrow(result), 2)
  expect_equal(result$name, c("temp_1", "temp_2"))
})

test_that("variables: empty selection returns empty tibble", {
  df <- tibble::tibble(x = 1:5, y = 6:10)
  result <- variables(df, dplyr::starts_with("nonexistent"))
  expect_equal(nrow(result), 0)
})

test_that("variables: preserves column order", {
  df <- tibble::tibble(z = 1:5, a = 6:10, m = 11:15)
  result <- variables(df)
  expect_equal(result$name, c("z", "a", "m"))
})

# ============================================================================
# CHALLENGING TESTS - variables_search()
# ============================================================================

test_that("variables_search: basic name search", {
  df <- tibble::tibble(
    temperature = 1:5,
    temp_max = 6:10,
    pressure = 11:15,
    humidity = 16:20
  )
  result <- variables_search(df, "temp")
  expect_equal(nrow(result), 2)
  expect_true(all(grepl("temp", result$name, ignore.case = TRUE)))
})

test_that("variables_search: case insensitive by default", {
  df <- tibble::tibble(
    Temperature = 1:5,
    TEMP_MAX = 6:10,
    pressure = 11:15
  )
  result <- variables_search(df, "temp")
  expect_equal(nrow(result), 2)
})

test_that("variables_search: wildcard with *", {
  df <- tibble::tibble(
    var_1 = 1:5,
    var_2 = 6:10,
    var_10 = 11:15,
    other = 16:20
  )
  result <- variables_search(df, "var*")
  expect_equal(nrow(result), 3)
})

test_that("variables_search: single character with ?", {
  df <- tibble::tibble(
    x1 = 1:5,
    x2 = 6:10,
    x10 = 11:15,
    y1 = 16:20
  )
  result <- variables_search(df, "x?")
  expect_setequal(result$name, c("x1", "x2", "x10"))
  anchored <- variables_search(df, "^x?$")
  expect_setequal(anchored$name, c("x1", "x2"))
})

test_that("variables_search: numeric range", {
  df <- tibble::tibble(
    item_1 = 1:5,
    item_2 = 6:10,
    item_3 = 11:15,
    item_10 = 16:20,
    other = 21:25
  )
  result <- variables_search(df, "item_[1-3]")
  expect_setequal(result$name, c("item_1", "item_2", "item_3", "item_10"))
  anchored <- variables_search(df, "^item_[1-3]$")
  expect_setequal(anchored$name, c("item_1", "item_2", "item_3"))
})

test_that("variables_search: no matches returns empty tibble", {
  df <- tibble::tibble(x = 1:5, y = 6:10, z = 11:15)
  result <- variables_search(df, "nonexistent")
  expect_equal(nrow(result), 0)
})

test_that("variables_search: searches in labels if available", {
  df <- tibble::tibble(
    inc = haven::labelled(1:5, label = "Income in USD"),
    wage = haven::labelled(6:10, label = "Hourly Wage"),
    age = haven::labelled(11:15, label = "Respondent Age")
  )
  result <- variables_search(df, "income")
  expect_true(nrow(result) >= 1)
})

test_that("variables_search: combined with additional selection", {
  df <- tibble::tibble(
    temp_1 = 1:5,
    temp_2 = 6:10,
    temp_3 = 11:15,
    pressure_1 = 16:20
  )
  result <- variables_search(df, "temp")
  expect_equal(nrow(result), 3)
})

# ============================================================================
# CHALLENGING TESTS - Integration with dplyr
# ============================================================================

test_that("names functions: work in dplyr pipeline", {
  result <- mtcars %>%
    dplyr::select(mpg, cyl, disp) %>%
    ds()

  expect_equal(result, c("mpg", "cyl", "disp"))
})

test_that("names functions: chain multiple operations", {
  result <- mtcars %>%
    ds(dplyr::starts_with("d"))

  expect_true("disp" %in% result)
  expect_true("drat" %in% result)
})

test_that("variables: work in dplyr pipeline", {
  result <- mtcars %>%
    dplyr::select(dplyr::where(is.numeric)) %>%
    variables()

  expect_identical(class(result), "data.frame")
  expect_true(nrow(result) > 0)
})

# ============================================================================
# CHALLENGING TESTS - Real-world Scenarios
# ============================================================================

test_that("names functions: survey variable exploration", {
  withr::local_preserve_seed()
  survey_data <- tibble::tibble(
    respondent_id = 1:100,
    q1_gender = sample(c("M", "F"), 100, replace = TRUE),
    q2_age = sample(18:80, 100, replace = TRUE),
    q3_income = sample(1:10, 100, replace = TRUE),
    q4_satisfaction = sample(1:5, 100, replace = TRUE),
    completion_time = runif(100, 1, 10)
  )

  # Find all question variables
  questions <- ds(survey_data, dplyr::starts_with("q"))
  expect_equal(length(questions), 4)

  # Search for specific question types
  demo_vars <- variables_search(survey_data, "gender|age")
  expect_true(nrow(demo_vars) >= 2)
})

test_that("names functions: time series variable selection", {
  withr::local_preserve_seed()
  ts_data <- tibble::tibble(
    date = seq(as.Date("2024-01-01"), by = "day", length.out = 30),
    price_open = cumsum(rnorm(30, 0.1, 1)) + 100,
    price_high = cumsum(rnorm(30, 0.1, 1)) + 102,
    price_low = cumsum(rnorm(30, 0.1, 1)) + 98,
    price_close = cumsum(rnorm(30, 0.1, 1)) + 101,
    volume = sample(1000000:10000000, 30)
  )

  # Get all price columns
  price_vars <- ds(ts_data, dplyr::starts_with("price"))
  expect_equal(length(price_vars), 4)

  # Get column names as column for documentation
  var_list <- names_as_column(ts_data, dplyr::starts_with("price"))
  expect_equal(nrow(var_list), 4)
})

# ============================================================================
# CHALLENGING TESTS - data.table Compatibility
# ============================================================================

test_that("names functions: work with data.table", {
  skip_if_not_installed("data.table")

  dt <- data.table::data.table(x = 1:5, y = 6:10, z = 11:15)

  result <- ds(dt)
  expect_type(result, "character")
  expect_equal(result, c("x", "y", "z"))

  result_vars <- variables(dt)
  expect_identical(class(result_vars), c("data.table", "data.frame"))
})

# ============================================================================
# CHALLENGING TESTS - Wide inputs
# ============================================================================

test_that("names functions: retain every name of a wide data frame", {
  withr::local_preserve_seed()
  df <- tibble::as_tibble(replicate(1000, rnorm(10)), .name_repair = "minimal")
  names(df) <- paste0("var", 1:1000)

  result <- ds(df)

  expect_equal(length(result), 1000)
  expect_identical(result, paste0("var", seq_len(1000)))
})
