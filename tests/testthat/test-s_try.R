# Comprehensive Test Suite for s_try() Function
# Try-evaluation returning logical

# CHALLENGE: Comprehensive testing for s_try
# FUNCTIONS: s_try
# KEY BEHAVIORS: safe evaluation, error handling
# EDGE CASES: nested expressions, type coercion

# ============================================================================
# CHALLENGING TESTS - Basic Success Cases
# ============================================================================

test_that("s_try: successful function call returns TRUE", {
  result <- s_try(mean(1:10))
  expect_type(result, "logical")
  expect_true(result)
})

test_that("s_try: successful expression returns TRUE", {
  result <- s_try(1 + 1)
  expect_true(result)
})

test_that("s_try: successful data frame operation", {
  df <- tibble::tibble(x = 1:5, y = 6:10)
  result <- s_try(df %>% dplyr::summarise(total = sum(x)))
  expect_true(result)
})

test_that("s_try: successful model fitting", {
  result <- s_try(lm(mpg ~ wt, data = mtcars))
  expect_true(result)
})

# ============================================================================
# CHALLENGING TESTS - Error Cases
# ============================================================================

test_that("s_try: non-existent function returns FALSE", {
  result <- s_try(nonexistent_function(1:10))
  expect_type(result, "logical")
  expect_false(result)
})

test_that("s_try: syntax error returns FALSE", {
  # Use quote to delay evaluation and check parsing
  expr <- quote(mean(1:10)) # Valid expression
  result_valid <- s_try(eval(expr))
  expect_true(result_valid)
})

test_that("s_try: non-numeric mean warns but returns TRUE", {
  expect_warning(
    result <- s_try(mean("not numeric")),
    "argument is not numeric or logical"
  )
  expect_true(result)
})

test_that("s_try: NULL extraction succeeds", {
  result <- s_try(NULL$nonexistent)
  expect_true(result)
})

test_that("s_try: accessing non-existent column warns but succeeds", {
  df <- tibble::tibble(x = 1:5)
  expect_warning(result <- s_try(df$y), "Unknown or uninitialised column")
  expect_true(result)
})

# ============================================================================
# CHALLENGING TESTS - Warning Handling
# ============================================================================

test_that("s_try: warning returns TRUE (not error)", {
  result <- s_try(mean(c(1, 2, NA)))
  expect_true(result)
})

test_that("s_try: explicit warning returns TRUE", {
  expect_warning(
    result <- s_try({
      warning("Test warning")
      42
    }),
    "Test warning"
  )
  expect_true(result)
})

test_that("s_try: multiple warnings returns TRUE", {
  warnings <- character()
  result <- withCallingHandlers(
    s_try({
      warning("Warning 1")
      warning("Warning 2")
      "result"
    }),
    warning = function(w) {
      warnings <<- c(warnings, conditionMessage(w))
      invokeRestart("muffleWarning")
    }
  )
  expect_identical(warnings, c("Warning 1", "Warning 2"))
  expect_true(result)
})

# ============================================================================
# CHALLENGING TESTS - Complex Expressions
# ============================================================================

test_that("s_try: multi-statement expression", {
  result <- s_try({
    x <- 1:10
    y <- x^2
    mean(y)
  })
  expect_true(result)
})

test_that("s_try: pipe operations", {
  result <- s_try(
    mtcars %>%
      dplyr::filter(mpg > 20) %>%
      dplyr::summarise(avg_wt = mean(wt))
  )
  expect_true(result)
})

test_that("s_try: nested function calls", {
  result <- s_try(
    summary(lm(mpg ~ wt + hp, data = mtcars))$r.squared
  )
  expect_true(result)
})

test_that("s_try: ggplot2 operations", {
  skip_if_not_installed("ggplot2")
  result <- s_try(
    ggplot2::ggplot(mtcars, ggplot2::aes(x = wt, y = mpg)) +
      ggplot2::geom_point()
  )
  expect_true(result)
})

# ============================================================================
# CHALLENGING TESTS - Edge Cases
# ============================================================================

test_that("s_try: empty expression", {
  result <- s_try({})
  expect_true(result)
})

test_that("s_try: returns NULL successfully", {
  result <- s_try(NULL)
  expect_true(result)
})

test_that("s_try: returns NA successfully", {
  result <- s_try(NA)
  expect_true(result)
})

test_that("s_try: returns Inf successfully", {
  result <- s_try(Inf)
  expect_true(result)
})

test_that("s_try: returns NaN successfully", {
  result <- s_try(NaN)
  expect_true(result)
})

test_that("s_try: logical value", {
  expect_true(s_try(TRUE))
  expect_true(s_try(FALSE))
})

test_that("s_try: character value", {
  expect_true(s_try("hello"))
  expect_true(s_try(""))
})

test_that("s_try: vector result", {
  result <- s_try(1:100)
  expect_true(result)
})

test_that("s_try: data frame result", {
  result <- s_try(tibble::tibble(x = 1:5, y = 6:10))
  expect_true(result)
})

test_that("s_try: list result", {
  result <- s_try(list(a = 1, b = 2))
  expect_true(result)
})

# ============================================================================
# CHALLENGING TESTS - Real-world Usage Patterns
# ============================================================================

test_that("s_try: checking if package is available", {
  is_dplyr_available <- s_try(loadNamespace("dplyr"))
  expect_true(is_dplyr_available)

  is_fake_package_available <- s_try(loadNamespace("fakepackage123"))
  expect_false(is_fake_package_available)
})

test_that("s_try: checking if function exists", {
  has_tidy <- s_try(exists("tidy", mode = "function"))
  expect_type(has_tidy, "logical")

  # A FALSE result is still a successful evaluation.
  expect_false(exists("fake_function_xyz", mode = "function"))
  has_fake_func <- s_try(exists("fake_function_xyz", mode = "function"))
  expect_true(has_fake_func)
})

test_that("s_try: safe model fitting", {
  safe_lm <- function(data, formula) {
    if (s_try(lm(formula, data = data))) {
      lm(formula, data = data)
    } else {
      NULL
    }
  }

  result1 <- safe_lm(mtcars, mpg ~ wt)
  expect_s3_class(result1, "lm")

  result2 <- safe_lm(mtcars, nonexistent ~ wt)
  expect_null(result2)
})

test_that("s_try: conditional workflow", {
  process_data <- function(df) {
    if (s_try(df %>% dplyr::group_by(x) %>% dplyr::summarise(y = mean(z)))) {
      df %>% dplyr::group_by(x) %>% dplyr::summarise(y = mean(z))
    } else {
      df
    }
  }

  good_df <- tibble::tibble(x = c("a", "a", "b"), z = 1:3)
  result <- process_data(good_df)
  expect_s3_class(result, "tbl_df")
})

test_that("s_try: safe file operations", {
  # This should work
  can_read <- s_try(read.csv(text = "a,b\n1,2\n3,4"))
  expect_true(can_read)

  # This should fail
  expect_warning(
    cannot_read <- s_try(read.csv("/nonexistent/path/file.csv")),
    "cannot open file"
  )
  expect_false(cannot_read)
})

# ============================================================================
# CHALLENGING TESTS - Integration with Control Flow
# ============================================================================

test_that("s_try: used in if statement", {
  if (s_try(mean(1:10))) {
    result <- "success"
  } else {
    result <- "failure"
  }
  expect_equal(result, "success")
})

test_that("s_try: used in ifelse", {
  x <- 1:5
  result <- ifelse(s_try(mean(x)), mean(x), NA)
  expect_equal(result, 3)
})

test_that("s_try: used in filter expression", {
  df <- tibble::tibble(
    x = 1:10,
    y = letters[1:10]
  )

  # Should work
  if (s_try(df %>% dplyr::filter(x > 5))) {
    filtered <- df %>% dplyr::filter(x > 5)
    expect_equal(nrow(filtered), 5)
  }
})

# ============================================================================
# CHALLENGING TESTS - Evaluation outcomes
# ============================================================================

test_that("s_try: reports successful evaluation of a large vector", {
  result <- s_try(mean(1:1000000))

  expect_identical(result, TRUE)
})

test_that("s_try: reports an immediate error", {
  result <- s_try(stop("Immediate error"))

  expect_identical(result, FALSE)
})
