# Comprehensive Test Suite for set_seed() Function
# Seed setting with pipeline support

# CHALLENGE: Comprehensive testing for set_seed
# FUNCTIONS: set_seed
# KEY BEHAVIORS: reproducibility, pipeline integration
# EDGE CASES: parallel processing, multiple seeds

# ============================================================================
# CHALLENGING TESTS - Basic Reproducibility
# ============================================================================

test_that("set_seed: same seed produces same random numbers", {
  withr::local_preserve_seed()
  result1 <- rnorm(5) %>% set_seed(123)
  result2 <- rnorm(5) %>% set_seed(123)

  expect_equal(result1, result2)
})

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
# CHALLENGING TESTS - Sample Function
# ============================================================================

test_that("set_seed: reproducible sampling", {
  withr::local_preserve_seed()
  sample1 <- sample(1:100, 10) %>% set_seed(123)
  sample2 <- sample(1:100, 10) %>% set_seed(123)

  expect_equal(sample1, sample2)
})

test_that("set_seed: reproducible sampling with replacement", {
  withr::local_preserve_seed()
  sample1 <- sample(letters, 20, replace = TRUE) %>% set_seed(42)
  sample2 <- sample(letters, 20, replace = TRUE) %>% set_seed(42)

  expect_equal(sample1, sample2)
})

# ============================================================================
# CHALLENGING TESTS - Distribution Functions
# ============================================================================

test_that("set_seed: reproducible normal distribution", {
  withr::local_preserve_seed()
  dist1 <- rnorm(100, mean = 10, sd = 2) %>% set_seed(123)
  dist2 <- rnorm(100, mean = 10, sd = 2) %>% set_seed(123)

  expect_equal(dist1, dist2)
  expect_equal(mean(dist1), mean(dist2), tolerance = 1e-10)
})

test_that("set_seed: reproducible uniform distribution", {
  withr::local_preserve_seed()
  dist1 <- runif(100, min = 0, max = 10) %>% set_seed(456)
  dist2 <- runif(100, min = 0, max = 10) %>% set_seed(456)

  expect_equal(dist1, dist2)
})

test_that("set_seed: reproducible poisson distribution", {
  withr::local_preserve_seed()
  dist1 <- rpois(100, lambda = 5) %>% set_seed(789)
  dist2 <- rpois(100, lambda = 5) %>% set_seed(789)

  expect_equal(dist1, dist2)
})

test_that("set_seed: reproducible binomial distribution", {
  withr::local_preserve_seed()
  dist1 <- rbinom(100, size = 10, prob = 0.3) %>% set_seed(111)
  dist2 <- rbinom(100, size = 10, prob = 0.3) %>% set_seed(111)

  expect_equal(dist1, dist2)
})

# ============================================================================
# CHALLENGING TESTS - Complex Operations
# ============================================================================

test_that("set_seed: reproducible data frame generation", {
  withr::local_preserve_seed()
  generate_data <- function() {
    tibble::tibble(
      x = rnorm(100),
      y = rnorm(100),
      group = sample(letters[1:3], 100, replace = TRUE)
    )
  }

  df1 <- generate_data() %>% set_seed(12345)
  df2 <- generate_data() %>% set_seed(12345)

  expect_equal(df1, df2)
})

test_that("set_seed: reproducible model data", {
  withr::local_preserve_seed()
  generate_model_data <- function() {
    tibble::tibble(
      x = rnorm(100),
      y = 2 + 3 * x + rnorm(100, sd = 0.5)
    )
  }

  data1 <- generate_model_data() %>% set_seed(999)
  data2 <- generate_model_data() %>% set_seed(999)

  expect_equal(data1, data2)

  # Fit models and compare coefficients
  model1 <- lm(y ~ x, data = data1)
  model2 <- lm(y ~ x, data = data2)
  expect_equal(coef(model1), coef(model2))
})

test_that("set_seed: reproducible bootstrap", {
  withr::local_preserve_seed()
  bootstrap_mean <- function(data, n_bootstrap = 100) {
    replicate(n_bootstrap, {
      sample(data, length(data), replace = TRUE) %>% mean()
    })
  }

  data <- rnorm(50)

  boot1 <- bootstrap_mean(data) %>% set_seed(555)
  boot2 <- bootstrap_mean(data) %>% set_seed(555)

  expect_equal(boot1, boot2)
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
# CHALLENGING TESTS - Integration with dplyr
# ============================================================================

test_that("set_seed: reproducible sampling in mutate", {
  withr::local_preserve_seed()
  df <- tibble::tibble(group = rep(c("A", "B"), each = 50))

  set.seed(123)
  result1 <- df %>% dplyr::mutate(random = rnorm(dplyr::n()))

  set.seed(123)
  result2 <- df %>% dplyr::mutate(random = rnorm(dplyr::n()))

  expect_equal(result1$random, result2$random)
})

test_that("set_seed: reproducible group-wise sampling", {
  withr::local_preserve_seed()
  df <- tibble::tibble(
    group = rep(c("A", "B", "C"), each = 20),
    value = 1:60
  )

  sample_n_groups <- function(df, n) {
    groups <- unique(df$group)
    selected <- sample(groups, n)
    df %>% dplyr::filter(group %in% selected)
  }

  result1 <- sample_n_groups(df, 2) %>% set_seed(888)
  result2 <- sample_n_groups(df, 2) %>% set_seed(888)

  expect_equal(result1, result2)
})

# ============================================================================
# CHALLENGING TESTS - Real-world Scenarios
# ============================================================================

test_that("set_seed: reproducible train/test split", {
  withr::local_preserve_seed()
  split_data <- function(data, train_frac = 0.8) {
    n <- nrow(data)
    train_idx <- sample(1:n, round(n * train_frac))
    list(
      train = data[train_idx, ],
      test = data[-train_idx, ]
    )
  }

  data <- tibble::tibble(
    x = rnorm(100),
    y = rnorm(100),
    z = sample(letters[1:5], 100, replace = TRUE)
  )

  split1 <- split_data(data) %>% set_seed(42)
  split2 <- split_data(data) %>% set_seed(42)

  expect_equal(split1$train, split2$train)
  expect_equal(split1$test, split2$test)
})

test_that("set_seed: reproducible simulation", {
  withr::local_preserve_seed()
  simulate_experiment <- function(n_subjects = 100) {
    tibble::tibble(
      subject_id = 1:n_subjects,
      group = sample(c("Control", "Treatment"), n_subjects, replace = TRUE),
      baseline = rnorm(n_subjects, mean = 50, sd = 10),
      followup = rnorm(n_subjects, mean = 55, sd = 12)
    )
  }

  exp1 <- simulate_experiment() %>% set_seed(2024)
  exp2 <- simulate_experiment() %>% set_seed(2024)

  expect_equal(exp1, exp2)
})

test_that("set_seed: reproducible cross-validation", {
  withr::local_preserve_seed()
  create_cv_folds <- function(data, k = 5) {
    n <- nrow(data)
    fold_ids <- sample(rep(1:k, length.out = n))
    fold_ids
  }

  data <- tibble::tibble(x = rnorm(100), y = rnorm(100))

  folds1 <- create_cv_folds(data) %>% set_seed(321)
  folds2 <- create_cv_folds(data) %>% set_seed(321)

  expect_equal(folds1, folds2)
})

# ============================================================================
# CHALLENGING TESTS - Seed Persistence
# ============================================================================

test_that("set_seed: subsequent random operations continue from the seeded state", {
  withr::local_preserve_seed()
  # First operation with seed
  result1 <- rnorm(5) %>% set_seed(123)

  # Second operation without seed - should use continued RNG state
  result2 <- rnorm(5)

  # Third operation with same seed as first
  result3 <- rnorm(5) %>% set_seed(123)

  # result1 and result3 should be equal
  expect_equal(result1, result3)

  # result2 should be different (continued from different state)
  expect_false(identical(result1, result2))
})

test_that("set_seed() works in a pipeline and alone", {
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
