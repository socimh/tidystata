# Comprehensive Test Suite for timer() Function
# Timing function for code execution

# CHALLENGE: Comprehensive testing for timer
# FUNCTIONS: timer
# KEY BEHAVIORS: execution timing, performance measurement
# EDGE CASES: very fast/slow operations, nested timing

# ============================================================================
# CHALLENGING TESTS - Basic Timing
# ============================================================================

test_that("timer: measures simple expression", {
  result <- capture_messages(
    timer(mean(1:1000))
  )
  expect_true(length(result) > 0)
  expect_true(any(grepl("Time spent", result)))
})

test_that("timer: returns the evaluated result invisibly", {
  result <- timer(sum(1:10))
  expect_equal(result, 55)
})

test_that("timer: works with pipe operations", {
  result <- 1:100 %>% mean() %>% timer()
  expect_equal(result, 50.5)
})

test_that("timer: handles complex expressions", {
  withr::local_preserve_seed()
  result <- timer({
    x <- c(-2, 0, 1, 4)
    y <- summary(x)
    y
  })
  expect_type(result, "double")
  expect_equal(length(result), 6)
})

# ============================================================================
# CHALLENGING TESTS - Duration Format
# ============================================================================

test_that("timer: duration formatting covers unit boundaries without waiting", {
  seconds <- c(0, 0.012, 0.999, 1, 1.25, 59.99, 60, 65.9, 3599, 3600, 3780)
  expected <- c(
    "0.000s",
    "0.012s",
    "0.999s",
    "1.00s",
    "1.25s",
    "59.99s",
    "1m0s",
    "1m5s",
    "59m59s",
    "1h0m",
    "1h3m"
  )
  actual <- vapply(
    seconds,
    function(x) {
      statart:::duration_to_chr(as.difftime(x, units = "secs"))
    },
    character(1)
  )
  expect_identical(actual, expected)
  expect_identical(
    statart:::duration_to_chr(as.difftime(1.5, units = "hours")),
    "1h30m"
  )
})

test_that("timer: displays sub-second timing", {
  result <- capture_messages(
    timer(invisible(NULL))
  )
  expect_true(any(grepl("Time spent", result)))
  # Should show milliseconds format
  expect_true(
    any(grepl("\\d+\\.\\d+s", result)) ||
      any(grepl("\\d+\\.\\d{2,3}s", result))
  )
})

test_that("timer: displays seconds format", {
  expect_identical(
    statart:::duration_to_chr(as.difftime(5.23, units = "secs")),
    "5.23s"
  )
})

test_that("timer: displays minutes format for longer operations", {
  expect_identical(
    statart:::duration_to_chr(as.difftime(2 + 5 / 60, units = "mins")),
    "2m5s"
  )
})

# ============================================================================
# CHALLENGING TESTS - Various Input Types
# ============================================================================

test_that("timer: works with data frame operations", {
  withr::local_preserve_seed()
  df <- tibble::tibble(x = 1:4, y = c(-1, 2, 0, 3))
  result <- timer(df %>% dplyr::summarise(mean_x = mean(x), sd_y = sd(y)))
  expect_s3_class(result, "tbl_df")
  expect_equal(result$mean_x, 2.5)
})

test_that("timer: works with model fitting", {
  result <- timer(lm(mpg ~ wt + hp, data = mtcars))
  expect_s3_class(result, "lm")
  expect_equal(result$coefficients[[1]], 37.22727, tolerance = 0.01)
})

test_that("timer: works with iterative operations", {
  result <- timer({
    total <- 0
    for (i in 1:4) {
      total <- total + i
    }
    total
  })
  expect_equal(result, 10)
})

test_that("timer: works with lapply/map operations", {
  result <- timer({
    lapply(1:4, function(x) x^2) %>% unlist() %>% sum()
  })
  expect_equal(result, 30)
})

# ============================================================================
# CHALLENGING TESTS - Edge Cases
# ============================================================================

test_that("timer: handles very quick operations", {
  result <- timer(1 + 1)
  expect_equal(result, 2)
  messages <- capture_messages(timer(1 + 1))
  expect_true(any(grepl("Time spent", messages)))
})

test_that("timer: handles NULL result", {
  result <- timer(NULL)
  expect_null(result)
  messages <- capture_messages(timer(NULL))
  expect_true(any(grepl("Time spent", messages)))
})

test_that("timer: handles NA result", {
  result <- timer(NA)
  expect_true(is.na(result))
})

test_that("timer: handles errors in expression", {
  expect_error(timer(stop("Test error")))
})

test_that("timer: handles warnings in expression", {
  result <- NULL
  messages <- capture_messages({
    expect_warning(
      result <- timer({
        warning("Test warning")
        42
      }),
      "Test warning"
    )
  })
  expect_equal(result, 42)
  expect_true(any(grepl("Time spent", messages)))
})

# ============================================================================
# CHALLENGING TESTS - Chained Operations
# ============================================================================

test_that("timer: works with multiple pipes", {
  result <- mtcars %>%
    dplyr::filter(mpg > 20) %>%
    dplyr::summarise(avg_wt = mean(wt)) %>%
    timer()

  expected <- mtcars %>%
    dplyr::filter(mpg > 20) %>%
    dplyr::summarise(avg_wt = mean(wt))
  expect_identical(result, expected)
  expect_equal(nrow(result), 1)
})

test_that("timer: works with nested function calls", {
  result <- timer({
    data <- head(mtcars, 10)
    fit <- lm(mpg ~ wt, data = data)
    predict(fit, newdata = tail(mtcars, 5))
  })
  expect_type(result, "double")
  expect_equal(length(result), 5)
})

# ============================================================================
# CHALLENGING TESTS - Memory-Intensive Operations
# ============================================================================

test_that("timer: handles data creation and preserves the complete object", {
  expected <- tibble::tibble(x = 1:3, y = letters[1:3])
  result <- timer(tibble::tibble(x = 1:3, y = letters[1:3]))
  expect_identical(result, expected)
})

test_that("timer: handles matrix operations", {
  result <- timer({
    mat <- matrix(1:6, nrow = 2)
    crossprod(mat)
  })
  expect_identical(result, matrix(c(5, 11, 17, 11, 25, 39, 17, 39, 61), 3))
})

# ============================================================================
# CHALLENGING TESTS - Real-world Scenarios
# ============================================================================

test_that("timer: data analysis workflow", {
  analysis_result <- capture_messages({
    result <- timer({
      # Simulate a data analysis pipeline
      data <- mtcars

      # Data cleaning
      clean_data <- data %>%
        dplyr::filter(!is.na(mpg)) %>%
        dplyr::mutate(hp_per_cyl = hp / cyl)

      # Summary statistics
      stats <- clean_data %>%
        dplyr::group_by(cyl) %>%
        dplyr::summarise(
          avg_mpg = mean(mpg),
          avg_hp = mean(hp),
          count = dplyr::n()
        )

      # Model fitting
      model <- lm(mpg ~ wt + hp + cyl, data = clean_data)

      list(stats = stats, model_r2 = summary(model)$r.squared)
    })
    result
  })

  expect_true(any(grepl("Time spent", analysis_result)))
})

test_that("timer: repeated calls evaluate each expression once", {
  state <- new.env(parent = emptyenv())
  state$calls <- 0L
  result <- timer(replicate(3, {
    state$calls <- state$calls + 1L
    state$calls * 2L
  }))
  expect_identical(state$calls, 3L)
  expect_identical(result, c(2L, 4L, 6L))
})

# ============================================================================
# CHALLENGING TESTS - Comparison with system.time
# ============================================================================

test_that("timer: reports duration and preserves the result compared to system.time", {
  st <- system.time(
    expected <- {
      "done"
    }
  )
  messages <- capture_messages(
    result <- timer({
      "done"
    })
  )

  # Clock resolution varies; validate the reported duration and result.
  expect_true(is.finite(st[["elapsed"]]))
  expect_identical(result, expected)
  expect_length(messages, 1)
  expect_match(
    trimws(messages),
    "^Time spent: [0-9]+(h[0-9]+m|m[0-9]+s|[.][0-9]+s)$"
  )
})

# ============================================================================
# CHALLENGING TESTS - Error Recovery
# ============================================================================

test_that("timer: does not suppress error messages", {
  expect_error(
    timer(stop("Custom error message")),
    "Custom error message"
  )
})

test_that("timer: preserves call stack on error", {
  inner_fn <- function() {
    stop("Inner error")
  }

  outer_fn <- function() {
    timer(inner_fn())
  }

  expect_error(outer_fn(), "Inner error")
})

test_that("PROBLEMS2 timer reports failures optionally and preserves the error", {
  original <- structure(
    list(message = "test failure", call = quote(original_call())),
    class = c("problems2_error", "error", "condition")
  )
  count <- 0L
  messages <- character()
  error <- withCallingHandlers(
    tryCatch(
      timer(
        {
          count <- count + 1L
          stop(original)
        },
        on_error = TRUE
      ),
      error = identity
    ),
    message = function(m) {
      messages <<- c(messages, conditionMessage(m))
      invokeRestart("muffleMessage")
    }
  )
  expect_identical(error, original)
  expect_identical(count, 1L)
  expect_length(messages, 1)
  expect_match(messages, "[Ff]ailed.*[Tt]ime|[Tt]ime.*[Ff]ailed")
  messages <- character()
  withCallingHandlers(
    tryCatch(timer(stop(original), on_error = FALSE), error = identity),
    message = function(m) {
      messages <<- c(messages, conditionMessage(m))
      invokeRestart("muffleMessage")
    }
  )
  expect_length(messages, 0)
  # Failed elapsed time is reported by default; the error call is not rewritten.
  messages <- character()
  failure <- withCallingHandlers(
    tryCatch(timer(stop("plain failure")), error = identity),
    message = function(m) {
      messages <<- c(messages, conditionMessage(m))
      invokeRestart("muffleMessage")
    }
  )
  expect_length(messages, 1)
  expect_match(messages, "Failed execution")
  expect_identical(conditionMessage(failure), "plain failure")
  expect_false(grepl("withCallingHandlers", deparse(conditionCall(failure))[1]))
  expect_false(
    suppressMessages(withVisible(timer(42, on_error = TRUE)))$visible
  )
  expect_identical(
    statart:::duration_to_chr(as.difftime(61, units = "secs")),
    "1m1s"
  )
  for (bad in list(NA, 1, logical(), c(TRUE, FALSE))) {
    expect_error(timer(42, on_error = bad), "on_error", fixed = TRUE)
  }
})

test_that("PROBLEMS2 failure timing keeps warnings and nested timing intact", {
  result <- NULL
  expect_warning(
    suppressMessages(
      result <- timer(
        {
          warning("original warning")
          42
        },
        on_error = TRUE
      )
    ),
    "original warning"
  )
  expect_identical(result, 42)
  count <- 0L
  messages <- character()
  withCallingHandlers(
    result <- timer(
      timer(
        {
          count <- count + 1L
          42
        },
        on_error = TRUE
      ),
      on_error = TRUE
    ),
    message = function(m) {
      messages <<- c(messages, conditionMessage(m))
      invokeRestart("muffleMessage")
    }
  )
  expect_identical(result, 42)
  expect_identical(count, 1L)
  expect_length(messages, 2)
})

test_that("timer evaluates its promise once and returns the exact object invisibly", {
  calls <- 0L
  value <- structure(list(x = 1:2), class = "timed_result", note = "preserved")
  expect_message(
    out <- withVisible(timer({
      calls <- calls + 1L
      value
    })),
    "^Time spent: "
  )
  expect_identical(calls, 1L)
  expect_identical(out, list(value = value, visible = FALSE))
})

test_that("timer propagates the original error without a message when disabled", {
  condition <- structure(
    list(message = "timed failure", call = NULL),
    class = c("timed_error", "error", "condition")
  )
  messages <- character()
  err <- withCallingHandlers(
    tryCatch(timer(stop(condition), on_error = FALSE), error = identity),
    message = function(m) {
      messages <<- c(messages, conditionMessage(m))
      invokeRestart("muffleMessage")
    }
  )
  expect_identical(err, condition)
  expect_length(messages, 0L)
})

test_that("timer() reports invalid input", {
  expect_snapshot(error = TRUE, {
    timer(1, on_error = NA)
  })
})
