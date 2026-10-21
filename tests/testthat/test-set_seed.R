# Comprehensive Test Suite for set_seed() Function
# Seed setting with pipeline support

# CHALLENGE: Comprehensive testing for set_seed
# FUNCTIONS: set_seed
# KEY BEHAVIORS: reproducibility, pipeline integration
# EDGE CASES: parallel processing, multiple seeds

# ============================================================================
# CHALLENGING TESTS - Basic Reproducibility
# ============================================================================

test_that("set_seed: different seeds produce different random numbers", {
  withr::local_preserve_seed()
  result1 <- rnorm(5) %>% set_seed(123)
  result2 <- rnorm(5) %>% set_seed(456)

  expect_false(identical(result1, result2))
})

test_that("set_seed: returns the function result", {
  withr::local_preserve_seed()
  result <- mean(1:10) %>% set_seed(42)
  expect_equal(result, 5.5)
})

# ============================================================================
# CHALLENGING TESTS - Edge Cases
# ============================================================================

test_that("set_seed: negative seed works", {
  withr::local_preserve_seed()
  result1 <- rnorm(5) %>% set_seed(-123)
  result2 <- rnorm(5) %>% set_seed(-123)

  expect_equal(result1, result2)
})

test_that("set_seed: zero seed works", {
  withr::local_preserve_seed()
  result1 <- rnorm(5) %>% set_seed(0)
  result2 <- rnorm(5) %>% set_seed(0)

  expect_equal(result1, result2)
})

test_that("set_seed: very large seed works", {
  withr::local_preserve_seed()
  result1 <- rnorm(5) %>% set_seed(1e9)
  result2 <- rnorm(5) %>% set_seed(1e9)

  expect_equal(result1, result2)
})

test_that("set_seed: non-integer seed (coerced)", {
  withr::local_preserve_seed()
  result1 <- rnorm(5) %>% set_seed(123.7)
  result2 <- rnorm(5) %>% set_seed(123)

  # Should be equivalent since seed is coerced to integer
  expect_equal(result1, result2)
})

test_that("set_seed: NULL function returns NULL", {
  withr::local_preserve_seed()
  result <- NULL %>% set_seed(42)
  expect_null(result)
})

# ============================================================================
# CHALLENGING TESTS - Chained Operations
# ============================================================================

test_that("set_seed: works in chained pipeline", {
  withr::local_preserve_seed()
  result <- 1:100 %>%
    sample(10) %>%
    sort() %>%
    set_seed(123)

  expect_type(result, "integer")
  expect_equal(length(result), 10)
})

test_that("set_seed: multiple random operations with same seed", {
  withr::local_preserve_seed()
  operation <- function() {
    list(
      normal = rnorm(5),
      uniform = runif(5),
      sample = sample(letters, 5)
    )
  }

  result1 <- operation() %>% set_seed(777)
  result2 <- operation() %>% set_seed(777)

  expect_equal(result1, result2)
})

# ============================================================================
# CHALLENGING TESTS - Seed Persistence
# ============================================================================

test_that("set_seed() works in a pipeline and alone", {
  withr::local_preserve_seed()
  set_seed(20261020)
  first <- stats::runif(2)
  set.seed(20261020)
  expect_identical(first, stats::runif(2))
  expect_invisible(set_seed(1))
  expect_null(set_seed(seed = 1))
  set_seed(seed = 7)
  first <- stats::runif(1)
  set.seed(7)
  expect_identical(first, stats::runif(1))
  piped <- sample(1:10, 3) %>% set_seed(123)
  set.seed(123)
  expect_identical(piped, sample(1:10, 3))
  expect_error(set_seed(), "Supply a seed")
  expect_error(set_seed("a"), "needs one number as the seed")
  expect_error(set_seed(c(1, 2)), "needs one number as the seed")
  expect_error(set_seed(NA_real_), "needs one number as the seed")
})

test_that("set_seed seeds before evaluation and leaves the advanced global RNG state", {
  local({
    old <- get0(".Random.seed", envir = .GlobalEnv, inherits = FALSE)
    on.exit(
      if (is.null(old)) {
        rm(".Random.seed", envir = .GlobalEnv)
      } else {
        assign(".Random.seed", old, envir = .GlobalEnv)
      }
    )
    set.seed(419)
    expected <- stats::runif(3)
    expected_state <- .Random.seed
    expected_next <- stats::runif(1)
    calls <- 0L
    out <- set_seed(
      {
        calls <- calls + 1L
        stats::runif(3)
      },
      419
    )
    expect_identical(calls, 1L)
    expect_identical(out, expected)
    expect_identical(.Random.seed, expected_state)
    expect_identical(stats::runif(1), expected_next)
  })
})

test_that("set_seed keeps RNG effects when the expression fails", {
  local({
    old <- get0(".Random.seed", envir = .GlobalEnv, inherits = FALSE)
    on.exit(
      if (is.null(old)) {
        rm(".Random.seed", envir = .GlobalEnv)
      } else {
        assign(".Random.seed", old, envir = .GlobalEnv)
      }
    )
    set.seed(117)
    stats::runif(2)
    expected_state <- .Random.seed
    expect_error(
      set_seed(
        {
          stats::runif(2)
          stop("seeded failure")
        },
        117
      ),
      "seeded failure"
    )
    expect_identical(.Random.seed, expected_state)
  })
})

test_that("set_seed preserves result attributes and invisible expressions", {
  local({
    old <- get0(".Random.seed", envir = .GlobalEnv, inherits = FALSE)
    on.exit(
      if (is.null(old)) {
        rm(".Random.seed", envir = .GlobalEnv)
      } else {
        assign(".Random.seed", old, envir = .GlobalEnv)
      }
    )
    value <- structure(1:2, label = "Seeded result")
    expect_identical(
      withVisible(set_seed(invisible(value), 1)),
      list(value = value, visible = FALSE)
    )
  })
})

test_that("set_seed rejects an invalid seed before forcing the expression", {
  calls <- 0L
  expect_error(
    set_seed(
      {
        calls <- calls + 1L
        1
      },
      NA_integer_
    ),
    "not a valid integer"
  )
  expect_identical(calls, 0L)
})

test_that("set_seed() reports a missing or invalid seed", {
  expect_snapshot(error = TRUE, {
    set_seed()
    set_seed("a")
  })
})


test_that("set_seed evaluates a data-mask expression after setting its seed", {
  withr::local_preserve_seed()
  data <- tibble::tibble(g = c("a", "a", "b"), id = 1:3)
  set.seed(19)
  expected <- stats::runif(3)
  out <- data |>
    dplyr::mutate(draw = stats::runif(dplyr::n())) |>
    set_seed(19)
  expect_identical(out, dplyr::mutate(data, draw = expected))
})
