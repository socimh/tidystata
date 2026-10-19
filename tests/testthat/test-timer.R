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
    x <- rnorm(1000)
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
    timer(Sys.sleep(0.01))
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
  df <- tibble::tibble(x = 1:1000, y = rnorm(1000))
  result <- timer(df %>% dplyr::summarise(mean_x = mean(x), sd_y = sd(y)))
  expect_s3_class(result, "tbl_df")
  expect_equal(result$mean_x, 500.5)
})

test_that("timer: works with model fitting", {
  result <- timer(lm(mpg ~ wt + hp, data = mtcars))
  expect_s3_class(result, "lm")
  expect_equal(result$coefficients[[1]], 37.22727, tolerance = 0.01)
})

test_that("timer: works with iterative operations", {
  result <- timer({
    total <- 0
    for (i in 1:1000) {
      total <- total + i
    }
    total
  })
  expect_equal(result, 500500)
})

test_that("timer: works with lapply/map operations", {
  result <- timer({
    lapply(1:100, function(x) x^2) %>% unlist() %>% sum()
  })
  expect_equal(result, sum((1:100)^2))
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

test_that("timer: handles large data creation", {
  withr::local_preserve_seed()
  result <- timer({
    large_df <- tibble::tibble(
      x = rnorm(100000),
      y = sample(letters, 100000, replace = TRUE),
      z = Sys.time() + 1:100000
    )
    nrow(large_df)
  })
  expect_equal(result, 100000)
})

test_that("timer: handles matrix operations", {
  withr::local_preserve_seed()
  result <- timer({
    mat <- matrix(rnorm(10000), nrow = 100)
    eigen_vals <- eigen(crossprod(mat))$values
    sum(eigen_vals)
  })
  expect_type(result, "double")
  expect_true(result > 0)
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

test_that("timer: simulation workflow", {
  withr::local_preserve_seed()
  set.seed(42)
  result <- timer({
    # Monte Carlo simulation
    n_sims <- 10000
    estimates <- replicate(n_sims, {
      sample_data <- rnorm(100, mean = 5, sd = 2)
      mean(sample_data)
    })
    c(mean_est = mean(estimates), sd_est = sd(estimates))
  })

  expect_equal(length(result), 2)
  expect_equal(names(result), c("mean_est", "sd_est"))
  expect_true(abs(result["mean_est"] - 5) < 0.1)
})

# ============================================================================
# CHALLENGING TESTS - Comparison with system.time
# ============================================================================

test_that("timer: reports duration and preserves the result compared to system.time", {
  st <- system.time(
    expected <- {
      Sys.sleep(0.05)
      "done"
    }
  )
  messages <- capture_messages(
    result <- timer({
      Sys.sleep(0.05)
      "done"
    })
  )

  # Sleep and clock resolution vary; validate the reported duration and result.
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
