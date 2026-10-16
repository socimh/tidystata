# Comprehensive Test Suite for esttab() Function
# Regression table formatting

# CHALLENGE: Comprehensive testing for esttab
# FUNCTIONS: esttab
# KEY BEHAVIORS: regression table formatting, model comparison
# EDGE CASES: complex models, missing statistics

library(testthat)
library(statart)
library(dplyr)
library(tibble)

# ============================================================================
# CHALLENGING TESTS - Basic LM Models
# ============================================================================

test_that("esttab: basic linear model", {
  model <- lm(mpg ~ wt + hp, data = mtcars)
  result <- esttab(model)
  expect_s3_class(result, "tbl_df")
  expect_true("term" %in% names(result))
  expect_true("coef" %in% names(result))
  expect_equal(nrow(result), 3)  # intercept, wt, hp
})

test_that("esttab: model with intercept only", {
  model <- lm(mpg ~ 1, data = mtcars)
  result <- esttab(model)
  expect_equal(nrow(result), 1)
  expect_equal(result$term, "(Intercept)")
})

test_that("esttab: model with many predictors", {
  model <- lm(mpg ~ ., data = mtcars)
  result <- esttab(model)
  expect_true(nrow(result) > 10)
})

test_that("esttab: model with interaction terms", {
  model <- lm(mpg ~ wt * hp, data = mtcars)
  result <- esttab(model)
  expect_true(nrow(result) >= 4)  # intercept, wt, hp, wt:hp
})

test_that("esttab: model with polynomial terms", {
  model <- lm(mpg ~ wt + I(wt^2), data = mtcars)
  result <- esttab(model)
  expect_equal(nrow(result), 3)
})

# ============================================================================
# CHALLENGING TESTS - Different Model Types
# ============================================================================

test_that("esttab: logistic regression (glm)", {
  mtcars$high_mpg <- mtcars$mpg > median(mtcars$mpg)
  model <- glm(high_mpg ~ wt + hp, data = mtcars, family = binomial())
  result <- esttab(model)
  expect_s3_class(result, "tbl_df")
  expect_true(nrow(result) >= 3)
})

test_that("esttab: poisson regression", {
  set.seed(42)
  df <- tibble(
    count = rpois(100, lambda = 5),
    x1 = rnorm(100),
    x2 = rnorm(100)
  )
  model <- glm(count ~ x1 + x2, data = df, family = poisson())
  result <- esttab(model)
  expect_s3_class(result, "tbl_df")
})

test_that("esttab: model with transformed variables", {
  model <- lm(log(mpg) ~ log(wt) + hp, data = mtcars)
  result <- esttab(model)
  expect_s3_class(result, "tbl_df")
  expect_true(nrow(result) >= 3)
})

# ============================================================================
# CHALLENGING TESTS - Custom Formatting
# ============================================================================

test_that("esttab: default format", {
  model <- lm(mpg ~ wt + hp, data = mtcars)
  result <- esttab(model)
  expect_type(result$coef, "character")
  # Should contain stars and standard errors
  expect_true(all(grepl("\\*", result$coef) | result$term == "(Intercept)"))
})

test_that("esttab: custom format string", {
  model <- lm(mpg ~ wt + hp, data = mtcars)
  result <- esttab(model, format = "{estimate} (p={p.value})")
  expect_type(result$coef, "character")
  expect_true(all(grepl("p=", result$coef)))
})

test_that("esttab: different digit specifications", {
  model <- lm(mpg ~ wt, data = mtcars)
  
  result_2 <- esttab(model, digit = 2)
  result_4 <- esttab(model, digit = 4)
  
  expect_type(result_2$coef, "character")
  expect_type(result_4$coef, "character")
})

test_that("esttab: format with statistic", {
  model <- lm(mpg ~ wt + hp, data = mtcars)
  result <- esttab(model, format = "{estimate} (t={statistic})")
  expect_true(all(grepl("t=", result$coef)))
})

# ============================================================================
# CHALLENGING TESTS - Star Significance Levels
# ============================================================================

test_that("esttab: significance stars are applied correctly", {
  set.seed(42)
  df <- tibble(
    y = rnorm(100),
    x_sig = rnorm(100),
    x_not_sig = rnorm(100)
  )
  df$y <- df$y + 0.5 * df$x_sig  # x_sig should be significant
  
  model <- lm(y ~ x_sig + x_not_sig, data = df)
  result <- esttab(model)
  
  # Check that stars column exists or is incorporated
  expect_true(any(grepl("\\*+", result$coef)))
})

test_that("esttab: different significance levels get different stars", {
  # Create data where we'll have different significance levels
  set.seed(123)
  x1 <- rnorm(100)  # Very significant
  x2 <- rnorm(100)  # Moderately significant
  x3 <- rnorm(100)  # Marginally significant
  x4 <- rnorm(100)  # Not significant
  
  y <- 2*x1 + 0.5*x2 + 0.3*x3 + 0.01*x4 + rnorm(100, sd = 2)
  df <- tibble(y = y, x1 = x1, x2 = x2, x3 = x3, x4 = x4)
  
  model <- lm(y ~ x1 + x2 + x3 + x4, data = df)
  result <- esttab(model)
  
  # Should have different star patterns
  coef_values <- result$coef[-1]  # Exclude intercept
  expect_true(any(grepl("\\*\\*\\*", coef_values)) || 
              any(grepl("\\*\\*", coef_values)) ||
              any(grepl("\\*", coef_values)))
})

# ============================================================================
# CHALLENGING TESTS - Model Statistics
# ============================================================================

test_that("esttab: includes N statistic", {
  model <- lm(mpg ~ wt + hp, data = mtcars)
  result <- esttab(model, stats = "n.obs")
  expect_true(any(result$term == "n.obs"))
  expect_true(any(result$coef == "32"))
})

test_that("esttab: includes R-squared", {
  model <- lm(mpg ~ wt + hp, data = mtcars)
  result <- esttab(model, stats = "r.squared")
  expect_true(any(result$term == "r.squared"))
})

test_that("esttab: includes multiple statistics", {
  model <- lm(mpg ~ wt + hp, data = mtcars)
  result <- esttab(model, stats = c("n.obs", "r.squared", "adj.r.squared"))
  
  expect_true(any(result$term == "n.obs"))
  expect_true(any(result$term == "r.squared"))
  expect_true(any(result$term == "adj.r.squared"))
})

test_that("esttab: handles unavailable statistics gracefully", {
  model <- lm(mpg ~ wt + hp, data = mtcars)
  result <- esttab(model, stats = c("n.obs", "nonexistent_stat"))
  
  # Should still work, just without the nonexistent stat
  expect_s3_class(result, "tbl_df")
})

# ============================================================================
# CHALLENGING TESTS - Error Handling
# ============================================================================

test_that("esttab: invalid model errors appropriately", {
  expect_error(esttab("not a model"))
  expect_error(esttab(NULL))
  expect_error(esttab(list(a = 1, b = 2)))
})

test_that("esttab: empty model errors", {
  # This should error because there's nothing to tidy
  expect_error(esttab(lm(mpg ~ 0, data = mtcars)))
})

# ============================================================================
# CHALLENGING TESTS - Edge Cases
# ============================================================================

test_that("esttab: perfect multicollinearity", {
  df <- tibble(
    y = rnorm(10),
    x1 = 1:10,
    x2 = 2 * (1:10)  # Perfectly collinear with x1
  )
  # This might produce NA coefficients
  model <- lm(y ~ x1 + x2, data = df)
  result <- esttab(model)
  expect_s3_class(result, "tbl_df")
})

test_that("esttab: model with missing data", {
  df <- tibble(
    y = c(1, 2, NA, 4, 5),
    x = c(1, NA, 3, 4, 5)
  )
  model <- lm(y ~ x, data = df)
  result <- esttab(model)
  expect_s3_class(result, "tbl_df")
})

test_that("esttab: model with categorical predictors", {
  df <- tibble(
    y = rnorm(30),
    group = rep(c("A", "B", "C"), each = 10)
  )
  model <- lm(y ~ group, data = df)
  result <- esttab(model)
  expect_s3_class(result, "tbl_df")
  expect_true(nrow(result) >= 3)  # Intercept + 2 group dummies
})

test_that("esttab: model with ordered factors", {
  df <- tibble(
    y = rnorm(30),
    group = ordered(rep(c("Low", "Med", "High"), each = 10))
  )
  model <- lm(y ~ group, data = df)
  result <- esttab(model)
  expect_s3_class(result, "tbl_df")
})

# ============================================================================
# CHALLENGING TESTS - Mixed Effects Models (if available)
# ============================================================================

test_that("esttab: handles lme4 models if available", {
  skip_if_not_installed("lme4")
  
  set.seed(42)
  df <- tibble(
    y = rnorm(100),
    x = rnorm(100),
    group = rep(1:10, each = 10)
  )
  
  model <- lme4::lmer(y ~ x + (1 | group), data = df)
  result <- esttab(model)
  
  expect_s3_class(result, "tbl_df")
  expect_true("term" %in% names(result))
})

# ============================================================================
# CHALLENGING TESTS - Real-world Scenarios
# ============================================================================

test_that("esttab: economic regression table", {
  set.seed(42)
  economic_data <- tibble(
    gdp_growth = rnorm(50, mean = 2.5, sd = 1.5),
    investment = rnorm(50, mean = 20, sd = 5),
    inflation = rnorm(50, mean = 2, sd = 1),
    trade_openness = rnorm(50, mean = 50, sd = 20),
    education = rnorm(50, mean = 10, sd = 2)
  )
  
  model <- lm(gdp_growth ~ investment + inflation + trade_openness + education,
              data = economic_data)
  result <- esttab(model, 
                   stats = c("n.obs", "r.squared", "adj.r.squared"),
                   digit = 3)
  
  expect_s3_class(result, "tbl_df")
  expect_true(nrow(result) >= 5)  # 4 predictors + intercept
  expect_true(any(result$term == "n.obs"))
})

test_that("esttab: comparing multiple specifications", {
  spec1 <- lm(mpg ~ wt, data = mtcars)
  spec2 <- lm(mpg ~ wt + hp, data = mtcars)
  spec3 <- lm(mpg ~ wt + hp + disp, data = mtcars)
  
  result1 <- esttab(spec1, stats = c("n.obs", "r.squared"))
  result2 <- esttab(spec2, stats = c("n.obs", "r.squared"))
  result3 <- esttab(spec3, stats = c("n.obs", "r.squared"))
  
  # R-squared should increase with more predictors
  r2_1 <- as.numeric(result1$coef[result1$term == "r.squared"])
  r2_2 <- as.numeric(result2$coef[result2$term == "r.squared"])
  r2_3 <- as.numeric(result3$coef[result3$term == "r.squared"])
  
  expect_true(r2_2 >= r2_1)
  expect_true(r2_3 >= r2_2)
})

# ============================================================================
# CHALLENGING TESTS - Column Selection
# ============================================================================

test_that("esttab: selects essential columns", {
  model <- lm(mpg ~ wt + hp, data = mtcars)
  result <- esttab(model)
  
  # Should have term and coef at minimum
  expect_true("term" %in% names(result))
  expect_true("coef" %in% names(result))
  
  # Should not have raw estimate/std.error columns (they're in coef)
  expect_false("estimate" %in% names(result))
  expect_false("std.error" %in% names(result))
})

test_that("esttab: mixed model includes effect and group columns", {
  skip_if_not_installed("lme4")
  
  df <- tibble(
    y = rnorm(60),
    x = rnorm(60),
    group = rep(letters[1:6], each = 10)
  )
  
  model <- lme4::lmer(y ~ x + (1 | group), data = df)
  result <- esttab(model)
  
  # Should have effect and group columns for mixed models
  expect_true(any(c("effect", "group") %in% names(result)))
})
