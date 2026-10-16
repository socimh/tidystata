# Comprehensive Test Suite for set_seed() Function
# Seed setting with pipeline support

# CHALLENGE: Comprehensive testing for set_seed
# FUNCTIONS: set_seed
# KEY BEHAVIORS: reproducibility, pipeline integration
# EDGE CASES: parallel processing, multiple seeds

library(testthat)
library(statart)
library(dplyr)
library(tibble)

# ============================================================================
# CHALLENGING TESTS - Basic Reproducibility
# ============================================================================

test_that("set_seed: same seed produces same random numbers", {
  result1 <- rnorm(5) %>% set_seed(123)
  result2 <- rnorm(5) %>% set_seed(123)

  expect_equal(result1, result2)
})

test_that("set_seed: different seeds produce different random numbers", {
  result1 <- rnorm(5) %>% set_seed(123)
  result2 <- rnorm(5) %>% set_seed(456)

  expect_false(identical(result1, result2))
})

test_that("set_seed: returns the function result", {
  result <- mean(1:10) %>% set_seed(42)
  expect_equal(result, 5.5)
})

# ============================================================================
# CHALLENGING TESTS - Sample Function
# ============================================================================

test_that("set_seed: reproducible sampling", {
  sample1 <- sample(1:100, 10) %>% set_seed(123)
  sample2 <- sample(1:100, 10) %>% set_seed(123)

  expect_equal(sample1, sample2)
})

test_that("set_seed: reproducible sampling with replacement", {
  sample1 <- sample(letters, 20, replace = TRUE) %>% set_seed(42)
  sample2 <- sample(letters, 20, replace = TRUE) %>% set_seed(42)

  expect_equal(sample1, sample2)
})

# ============================================================================
# CHALLENGING TESTS - Distribution Functions
# ============================================================================

test_that("set_seed: reproducible normal distribution", {
  dist1 <- rnorm(100, mean = 10, sd = 2) %>% set_seed(123)
  dist2 <- rnorm(100, mean = 10, sd = 2) %>% set_seed(123)

  expect_equal(dist1, dist2)
  expect_equal(mean(dist1), mean(dist2), tolerance = 1e-10)
})

test_that("set_seed: reproducible uniform distribution", {
  dist1 <- runif(100, min = 0, max = 10) %>% set_seed(456)
  dist2 <- runif(100, min = 0, max = 10) %>% set_seed(456)

  expect_equal(dist1, dist2)
})

test_that("set_seed: reproducible poisson distribution", {
  dist1 <- rpois(100, lambda = 5) %>% set_seed(789)
  dist2 <- rpois(100, lambda = 5) %>% set_seed(789)

  expect_equal(dist1, dist2)
})

test_that("set_seed: reproducible binomial distribution", {
  dist1 <- rbinom(100, size = 10, prob = 0.3) %>% set_seed(111)
  dist2 <- rbinom(100, size = 10, prob = 0.3) %>% set_seed(111)

  expect_equal(dist1, dist2)
})

# ============================================================================
# CHALLENGING TESTS - Complex Operations
# ============================================================================

test_that("set_seed: reproducible data frame generation", {
  generate_data <- function() {
    tibble(
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
  generate_model_data <- function() {
    tibble(
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
  result1 <- rnorm(5) %>% set_seed(-123)
  result2 <- rnorm(5) %>% set_seed(-123)

  expect_equal(result1, result2)
})

test_that("set_seed: zero seed works", {
  result1 <- rnorm(5) %>% set_seed(0)
  result2 <- rnorm(5) %>% set_seed(0)

  expect_equal(result1, result2)
})

test_that("set_seed: very large seed works", {
  result1 <- rnorm(5) %>% set_seed(1e9)
  result2 <- rnorm(5) %>% set_seed(1e9)

  expect_equal(result1, result2)
})

test_that("set_seed: non-integer seed (coerced)", {
  result1 <- rnorm(5) %>% set_seed(123.7)
  result2 <- rnorm(5) %>% set_seed(123)

  # Should be equivalent since seed is coerced to integer
  expect_equal(result1, result2)
})

test_that("set_seed: NULL function returns NULL", {
  result <- NULL %>% set_seed(42)
  expect_null(result)
})

# ============================================================================
# CHALLENGING TESTS - Chained Operations
# ============================================================================

test_that("set_seed: works in chained pipeline", {
  result <- 1:100 %>%
    sample(10) %>%
    sort() %>%
    set_seed(123)

  expect_type(result, "integer")
  expect_equal(length(result), 10)
})

test_that("set_seed: multiple random operations with same seed", {
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
  df <- tibble(group = rep(c("A", "B"), each = 50))

  set.seed(123)
  result1 <- df %>% mutate(random = rnorm(n()))

  set.seed(123)
  result2 <- df %>% mutate(random = rnorm(n()))

  expect_equal(result1$random, result2$random)
})

test_that("set_seed: reproducible group-wise sampling", {
  df <- tibble(
    group = rep(c("A", "B", "C"), each = 20),
    value = 1:60
  )

  sample_n_groups <- function(df, n) {
    groups <- unique(df$group)
    selected <- sample(groups, n)
    df %>% filter(group %in% selected)
  }

  result1 <- sample_n_groups(df, 2) %>% set_seed(888)
  result2 <- sample_n_groups(df, 2) %>% set_seed(888)

  expect_equal(result1, result2)
})

# ============================================================================
# CHALLENGING TESTS - Real-world Scenarios
# ============================================================================

test_that("set_seed: reproducible train/test split", {
  split_data <- function(data, train_frac = 0.8) {
    n <- nrow(data)
    train_idx <- sample(1:n, round(n * train_frac))
    list(
      train = data[train_idx, ],
      test = data[-train_idx, ]
    )
  }

  data <- tibble(
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
  simulate_experiment <- function(n_subjects = 100) {
    tibble(
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
  create_cv_folds <- function(data, k = 5) {
    n <- nrow(data)
    fold_ids <- sample(rep(1:k, length.out = n))
    fold_ids
  }

  data <- tibble(x = rnorm(100), y = rnorm(100))

  folds1 <- create_cv_folds(data) %>% set_seed(321)
  folds2 <- create_cv_folds(data) %>% set_seed(321)

  expect_equal(folds1, folds2)
})

# ============================================================================
# CHALLENGING TESTS - Seed Persistence
# ============================================================================

test_that("set_seed: subsequent random operations continue from the seeded state", {
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
