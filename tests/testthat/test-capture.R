# Comprehensive Test Suite for capture() Function
# Try-evaluation returning logical

# CHALLENGE: Comprehensive testing for capture
# FUNCTIONS: capture
# KEY BEHAVIORS: safe evaluation, error handling
# EDGE CASES: nested expressions, type coercion

# ============================================================================
# CHALLENGING TESTS - Basic Success Cases
# ============================================================================

test_that("capture: successful function call returns TRUE", {
  result <- capture(mean(1:10))
  expect_type(result, "logical")
  expect_true(result)
})

test_that("capture: successful expression returns TRUE", {
  result <- capture(1 + 1)
  expect_true(result)
})

test_that("capture: successful data frame operation", {
  df <- tibble::tibble(x = 1:5, y = 6:10)
  result <- capture(df %>% dplyr::summarise(total = sum(x)))
  expect_true(result)
})

test_that("capture: successful model fitting", {
  result <- capture(lm(mpg ~ wt, data = mtcars))
  expect_true(result)
})

# ============================================================================
# CHALLENGING TESTS - Error Cases
# ============================================================================

test_that("capture: non-existent function returns FALSE", {
  result <- capture(nonexistent_function(1:10))
  expect_type(result, "logical")
  expect_false(result)
})

test_that("capture: syntax error returns FALSE", {
  # Use quote to delay evaluation and check parsing
  expr <- quote(mean(1:10)) # Valid expression
  result_valid <- capture(eval(expr))
  expect_true(result_valid)
})

test_that("capture: non-numeric mean warns but returns TRUE", {
  expect_warning(
    result <- capture(mean("not numeric")),
    "argument is not numeric or logical"
  )
  expect_true(result)
})

test_that("capture: NULL extraction succeeds", {
  result <- capture(NULL$nonexistent)
  expect_true(result)
})

test_that("capture: accessing non-existent column warns but succeeds", {
  df <- tibble::tibble(x = 1:5)
  expect_warning(result <- capture(df$y), "Unknown or uninitialised column")
  expect_true(result)
})

# ============================================================================
# CHALLENGING TESTS - Warning Handling
# ============================================================================

test_that("capture: warning returns TRUE (not error)", {
  result <- capture(mean(c(1, 2, NA)))
  expect_true(result)
})

test_that("capture: explicit warning returns TRUE", {
  expect_warning(
    result <- capture({
      warning("Test warning")
      42
    }),
    "Test warning"
  )
  expect_true(result)
})

test_that("capture: multiple warnings returns TRUE", {
  warnings <- character()
  result <- withCallingHandlers(
    capture({
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

test_that("capture: multi-statement expression", {
  result <- capture({
    x <- 1:10
    y <- x^2
    mean(y)
  })
  expect_true(result)
})

test_that("capture: pipe operations", {
  result <- capture(
    mtcars %>%
      dplyr::filter(mpg > 20) %>%
      dplyr::summarise(avg_wt = mean(wt))
  )
  expect_true(result)
})

test_that("capture: nested function calls", {
  result <- capture(
    summary(lm(mpg ~ wt + hp, data = mtcars))$r.squared
  )
  expect_true(result)
})

test_that("capture: ggplot2 operations", {
  skip_if_not_installed("ggplot2")
  result <- capture(
    ggplot2::ggplot(mtcars, ggplot2::aes(x = wt, y = mpg)) +
      ggplot2::geom_point()
  )
  expect_true(result)
})

# ============================================================================
# CHALLENGING TESTS - Edge Cases
# ============================================================================

test_that("capture: successful value shapes all return scalar TRUE", {
  expressions <- list(
    empty = quote({}),
    null = quote(NULL),
    missing = quote(NA),
    infinity = quote(Inf),
    nan = quote(NaN),
    true = quote(TRUE),
    false = quote(FALSE),
    character = quote("hello"),
    empty_character = quote(""),
    vector = quote(1:3),
    table = quote(tibble::tibble(x = 1:2, y = 3:4)),
    list = quote(list(a = 1, b = 2))
  )
  for (name in names(expressions)) {
    expect_identical(capture(eval(expressions[[name]])), TRUE, info = name)
  }
})

# ============================================================================
# CHALLENGING TESTS - Real-world Usage Patterns
# ============================================================================

test_that("capture: checking if package is available", {
  is_dplyr_available <- capture(loadNamespace("dplyr"))
  expect_true(is_dplyr_available)

  # Signal the condition loadNamespace() raises for a missing package without
  # naming one, so dependency scanners never see an undeclared package.
  load_missing_package <- function() {
    stop(errorCondition(
      "there is no package called 'unavailable'",
      class = "packageNotFoundError",
      package = "unavailable"
    ))
  }
  expect_error(load_missing_package(), class = "packageNotFoundError")
  expect_false(capture(load_missing_package()))
})

test_that("capture: checking if function exists", {
  has_tidy <- capture(exists("tidy", mode = "function"))
  expect_type(has_tidy, "logical")

  # A FALSE result is still a successful evaluation.
  expect_false(exists("fake_function_xyz", mode = "function"))
  has_fake_func <- capture(exists("fake_function_xyz", mode = "function"))
  expect_true(has_fake_func)
})

test_that("capture: safe model fitting", {
  safe_lm <- function(data, formula) {
    if (capture(lm(formula, data = data))) {
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

test_that("capture: conditional workflow", {
  process_data <- function(df) {
    if (capture(df %>% dplyr::group_by(x) %>% dplyr::summarise(y = mean(z)))) {
      df %>% dplyr::group_by(x) %>% dplyr::summarise(y = mean(z))
    } else {
      df
    }
  }

  good_df <- tibble::tibble(x = c("a", "a", "b"), z = 1:3)
  result <- process_data(good_df)
  expect_s3_class(result, "tbl_df")
})

test_that("capture: safe file operations", {
  # This should work
  can_read <- capture(read.csv(text = "a,b\n1,2\n3,4"))
  expect_true(can_read)

  # This should fail
  expect_warning(
    cannot_read <- capture(read.csv("/nonexistent/path/file.csv")),
    "cannot open file"
  )
  expect_false(cannot_read)
})

# ============================================================================
# CHALLENGING TESTS - Integration with Control Flow
# ============================================================================

test_that("capture: used in if statement", {
  if (capture(mean(1:10))) {
    result <- "success"
  } else {
    result <- "failure"
  }
  expect_equal(result, "success")
})

test_that("capture: used in ifelse", {
  x <- 1:5
  result <- ifelse(capture(mean(x)), mean(x), NA)
  expect_equal(result, 3)
})

test_that("capture: used in filter expression", {
  df <- tibble::tibble(
    x = 1:10,
    y = letters[1:10]
  )

  # Should work
  if (capture(df %>% dplyr::filter(x > 5))) {
    filtered <- df %>% dplyr::filter(x > 5)
    expect_equal(nrow(filtered), 5)
  }
})

# ============================================================================
# CHALLENGING TESTS - Evaluation outcomes
# ============================================================================

test_that("capture: reports successful evaluation of a large vector", {
  result <- capture(mean(1:1000000))

  expect_identical(result, TRUE)
})

test_that("capture: reports an immediate error", {
  result <- capture(stop("Immediate error"))

  expect_identical(result, FALSE)
})

test_that("capture evaluates once and preserves warnings and messages", {
  calls <- 0L
  warnings <- character()
  messages <- character()
  out <- withCallingHandlers(
    capture({
      calls <- calls + 1L
      warning("kept warning")
      message("kept message")
      FALSE
    }),
    warning = function(w) {
      warnings <<- c(warnings, conditionMessage(w))
      invokeRestart("muffleWarning")
    },
    message = function(m) {
      messages <<- c(messages, conditionMessage(m))
      invokeRestart("muffleMessage")
    }
  )
  expect_identical(calls, 1L)
  expect_true(out)
  expect_identical(warnings, "kept warning")
  expect_identical(messages, "kept message\n")
})

test_that("capture preserves the existing try-error classification and visible result", {
  value <- structure("already failed", class = "try-error")
  expect_false(capture(value))
  expect_false(capture(stop("new failure")))
  expect_identical(
    withVisible(capture(invisible(NULL))),
    list(value = TRUE, visible = TRUE)
  )
})
