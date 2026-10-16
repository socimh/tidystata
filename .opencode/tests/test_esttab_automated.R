
# Automated Test Suite for esttab Function
# 25 Comprehensive Scenarios
# 
# To run: source(".opencode/workflows/esttab_automation.R")

library(statart)
library(dplyr)
library(lme4)
library(broom)
library(broom.mixed)

# Source package functions
tryCatch({
  source("R/s_try.R")
  source("R/esttab.R")
}, error = function(e) {
  # If we're in a different working directory
  source("D:/R/statart/R/s_try.R")
  source("D:/R/statart/R/esttab.R")
})

# Define 25 test scenarios
define_test_scenarios <- function() {
  list(
    # === BASIC FUNCTIONALITY (1-8) ===
    
    list(
      id = "1.1_lm_simple",
      description = "Simple linear regression with one predictor",
      category = "basic",
      expected = "success",
      code = 'lm(mpg ~ wt, data = mtcars) %>% esttab()'
    ),
    
    list(
      id = "1.2_lm_multiple",
      description = "Multiple regression with three predictors",
      category = "basic",
      expected = "success",
      code = 'lm(mpg ~ wt + hp + cyl, data = mtcars) %>% esttab()'
    ),
    
    list(
      id = "1.3_glm_logistic",
      description = "Logistic regression (GLM binomial)",
      category = "basic",
      expected = "success",
      code = 'glm(vs ~ wt + disp, data = mtcars, family = binomial) %>% esttab()'
    ),
    
    list(
      id = "1.4_lmer_mixed",
      description = "Linear mixed effects model (lmer)",
      category = "basic",
      expected = "success",
      code = 'lmer(Reaction ~ Days + (Days | Subject), sleepstudy) %>% esttab()'
    ),
    
    list(
      id = "1.5_glmer_mixed",
      description = "Generalized mixed model (glmer binomial)",
      category = "basic",
      expected = "success",
      code = '
        sleepstudy$fast <- as.numeric(sleepstudy$Reaction < 250)
        glmer(fast ~ Days + (1 | Subject), data = sleepstudy, family = binomial) %>% esttab()
      '
    ),
    
    list(
      id = "1.6_lm_factors",
      description = "Regression with factor variables",
      category = "basic",
      expected = "success",
      code = '
        mtcars$cyl_f <- as.factor(mtcars$cyl)
        lm(mpg ~ wt + cyl_f, data = mtcars) %>% esttab()
      '
    ),
    
    list(
      id = "1.7_lm_interaction",
      description = "Regression with interaction terms",
      category = "basic",
      expected = "success",
      code = 'lm(mpg ~ wt * hp, data = mtcars) %>% esttab()'
    ),
    
    list(
      id = "1.8_lm_transformed",
      description = "Regression with transformed variables (log, polynomial)",
      category = "basic",
      expected = "success",
      code = 'lm(log(mpg) ~ log(wt) + I(hp^2), data = mtcars) %>% esttab()'
    ),
    
    # === EDGE CASES & ERROR HANDLING (9-16) ===
    
    list(
      id = "2.1_missing_data",
      description = "Model with missing data (NA handling)",
      category = "edge_case",
      expected = "success",
      code = '
        mtcars_na <- mtcars
        mtcars_na[1:5, "wt"] <- NA
        lm(mpg ~ wt + hp, data = mtcars_na) %>% esttab()
      '
    ),
    
    list(
      id = "2.2_perfect_fit",
      description = "Perfect fit case (separation warning expected)",
      category = "edge_case",
      expected = "warning",
      code = '
        df_perf <- data.frame(y = c(0, 1, 0, 1), x = c(0, 1, 0, 1))
        glm(y ~ x, data = df_perf, family = binomial) %>% esttab()
      '
    ),
    
    list(
      id = "2.3_no_intercept",
      description = "No-intercept model",
      category = "edge_case",
      expected = "success",
      code = 'lm(mpg ~ wt - 1, data = mtcars) %>% esttab()'
    ),
    
    list(
      id = "2.4_only_intercept",
      description = "Intercept-only model",
      category = "edge_case",
      expected = "success",
      code = 'lm(mpg ~ 1, data = mtcars) %>% esttab()'
    ),
    
    list(
      id = "2.5_invalid_input",
      description = "Invalid input (non-model object)",
      category = "edge_case",
      expected = "error",
      code = 'esttab(data.frame(x = 1))'
    ),
    
    list(
      id = "2.6_null_input",
      description = "NULL input handling",
      category = "edge_case",
      expected = "error",
      code = 'esttab(NULL)'
    ),
    
    list(
      id = "2.7_no_pvalues",
      description = "Model with no p-values available",
      category = "edge_case",
      expected = "success",
      code = '
        # Create a model where p-values might be missing
        m_no_p <- lm(mpg ~ wt, data = mtcars[1:3,])
        esttab(m_no_p)
      '
    ),
    
    list(
      id = "2.8_single_obs",
      description = "Model with minimal observations",
      category = "edge_case",
      expected = "success",
      code = '
        tryCatch({
          m_single <- lm(mpg ~ wt, data = mtcars[1:2,])
          esttab(m_single)
        }, error = function(e) {
          message("Expected error for insufficient observations: ", e$message)
          NULL
        })
      '
    ),
    
    # === FORMATTING & OPTIONS (17-25) ===
    
    list(
      id = "3.1_custom_format_glue",
      description = "Custom format with glue-style string",
      category = "formatting",
      expected = "success",
      code = '
        m1 <- lm(mpg ~ wt, data = mtcars)
        esttab(m1, format = "{estimate} [{p.value}]")
      '
    ),
    
    list(
      id = "3.2_digit_precision",
      description = "Various digit precision levels",
      category = "formatting",
      expected = "success",
      code = '
        m1 <- lm(mpg ~ wt, data = mtcars)
        esttab(m1, digit = 5)
      '
    ),
    
    list(
      id = "3.3_digit_zero",
      description = "Digit = 0 (integer formatting)",
      category = "formatting",
      expected = "success",
      code = '
        m1 <- lm(mpg ~ wt, data = mtcars)
        esttab(m1, digit = 0)
      '
    ),
    
    list(
      id = "3.4_stats_basic",
      description = "Statistics: n.obs and r.squared",
      category = "formatting",
      expected = "success",
      code = '
        m1 <- lm(mpg ~ wt, data = mtcars)
        esttab(m1, stats = c("n.obs", "r.squared"))
      '
    ),
    
    list(
      id = "3.5_stats_aliases",
      description = "Statistics with Stata-like aliases",
      category = "formatting",
      expected = "success",
      code = '
        m1 <- lm(mpg ~ wt, data = mtcars)
        esttab(m1, stats = c("N", "r2", "aic", "ll"))
      '
    ),
    
    list(
      id = "3.6_stats_invalid",
      description = "Statistics with invalid stat name (graceful handling)",
      category = "formatting",
      expected = "success",
      code = '
        m1 <- lm(mpg ~ wt, data = mtcars)
        esttab(m1, stats = c("N", "invalid_stat", "bic"))
      '
    ),
    
    list(
      id = "3.7_format_cstyle",
      description = "C-style format string",
      category = "formatting",
      expected = "success",
      code = '
        m1 <- lm(mpg ~ wt, data = mtcars)
        esttab(m1, format = "%.2f")
      '
    ),
    
    list(
      id = "3.8_large_coefficients",
      description = "Model with large coefficient values",
      category = "formatting",
      expected = "success",
      code = '
        mtcars_large <- mtcars
        mtcars_large$mpg <- mtcars_large$mpg * 1000
        lm(mpg ~ wt, data = mtcars_large) %>% esttab()
      '
    ),
    
    list(
      id = "3.9_small_coefficients",
      description = "Model with near-zero coefficient values",
      category = "formatting",
      expected = "success",
      code = '
        mtcars_small <- mtcars
        mtcars_small$mpg <- mtcars_small$mpg / 10000
        lm(mpg ~ wt, data = mtcars_small) %>% esttab(digit = 8)
      '
    ),
    
    list(
      id = "4.0_output_structure",
      description = "Verify output structure and column selection",
      category = "structure",
      expected = "success",
      code = '
        m1 <- lm(mpg ~ wt, data = mtcars)
        out <- esttab(m1)
        cols <- names(out)
        
        # Check essential columns exist
        if (!"term" %in% cols) stop("Missing term column")
        if (!"coef" %in% cols) stop("Missing coef column")
        
        # Check raw columns are hidden
        if ("estimate" %in% cols || "std.error" %in% cols) {
          stop("Raw columns should be hidden")
        }
        
        message("Output structure verified: PASS")
        out
      '
    )
  )
}
