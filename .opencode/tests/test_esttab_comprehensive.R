
library(statart)
library(dplyr)
library(lme4)
library(broom)
library(broom.mixed)

# Load package functions (simulating package load)
source("R/s_try.R")
source("R/esttab.R")

message("=== Starting Comprehensive Verification for esttab (20+ Scenarios) ===")

# --- 1. Basic Linear Model ---
message("\n--- 1. Basic LM Model ---")
m1 <- lm(mpg ~ wt, data = mtcars)
print(esttab(m1))

# --- 2. Multiple Regression ---
message("\n--- 2. Multiple Regression ---")
m2 <- lm(mpg ~ wt + hp + cyl, data = mtcars)
print(esttab(m2))

# --- 3. GLM (Logistic) ---
message("\n--- 3. GLM (Logistic) ---")
m3 <- glm(vs ~ wt + disp, data = mtcars, family = binomial)
print(esttab(m3))

# --- 4. Mixed Model (lmer) ---
message("\n--- 4. Mixed Model (lmer) ---")
m4 <- lmer(Reaction ~ Days + (Days | Subject), sleepstudy)
print(esttab(m4))

# --- 5. Mixed Model (glmer) ---
message("\n--- 5. Mixed Model (glmer) ---")
# Create binary response for demonstration
sleepstudy$fast <- as.numeric(sleepstudy$Reaction < 250)
m5 <- glmer(fast ~ Days + (1 | Subject), data = sleepstudy, family = binomial)
print(esttab(m5))

# --- 6. Model with Factors ---
message("\n--- 6. Model with Factors ---")
mtcars$cyl_f <- as.factor(mtcars$cyl)
m6 <- lm(mpg ~ wt + cyl_f, data = mtcars)
print(esttab(m6))

# --- 7. Model with Interaction Terms ---
message("\n--- 7. Model with Interaction Terms ---")
m7 <- lm(mpg ~ wt * hp, data = mtcars)
print(esttab(m7))

# --- 8. Model with Transformations ---
message("\n--- 8. Model with Transformations ---")
m8 <- lm(log(mpg) ~ log(wt) + I(hp^2), data = mtcars)
print(esttab(m8))

# --- 9. Model with Missing Data ---
message("\n--- 9. Model with Missing Data ---")
mtcars_na <- mtcars
mtcars_na[1:5, "wt"] <- NA
m9 <- lm(mpg ~ wt + hp, data = mtcars_na)
print(esttab(m9))

# --- 10. Perfect Fit / Warning Case ---
message("\n--- 10. Perfect Fit (Warning Check) ---")
df_perf <- data.frame(y = c(0, 1, 0, 1), x = c(0, 1, 0, 1))
m10 <- glm(y ~ x, data = df_perf, family = binomial)
# Should handle high SEs/warnings gracefully
print(esttab(m10))

# --- 11. Custom Format String ---
message("\n--- 11. Custom Format String ---")
print(esttab(m1, format = "{estimate} [{p.value}]"))

# --- 12. Stats Argument (Basic) ---
message("\n--- 12. Stats Argument (Basic) ---")
print(esttab(m1, stats = c("n.obs", "r.squared")))

# --- 13. Stats Argument (Aliases) ---
message("\n--- 13. Stats Argument (Aliases) ---")
print(esttab(m1, stats = c("N", "r2", "aic", "ll")))

# --- 14. Digit Argument ---
message("\n--- 14. Digit Argument ---")
print(esttab(m1, digit = 5))

# --- 15. Stats Not In Model ---
message("\n--- 15. Stats Not In Model (Graceful Handling) ---")
# 'logLik' might not be in some simple broom outputs or named differently
print(esttab(m1, stats = c("N", "invalid_stat")))

# --- 16. Invalid Object Error ---
message("\n--- 16. Invalid Object Error ---")
tryCatch({
  esttab(data.frame(x=1))
}, error = function(e) message("Caught expected error: ", e$message))

# --- 17. No Intercept Model ---
message("\n--- 17. No Intercept Model ---")
m17 <- lm(mpg ~ wt - 1, data = mtcars)
print(esttab(m17))

# --- 18. Only Intercept Model ---
message("\n--- 18. Only Intercept Model ---")
m18 <- lm(mpg ~ 1, data = mtcars)
print(esttab(m18))

# --- 19. Specific Format with Glue ---
message("\n--- 19. Specific Format with Glue ---")
print(esttab(m1, format = "b={estimate}"))

# --- 20. Output Structure Verification ---
message("\n--- 20. Output Structure Verification ---")
out <- esttab(m1)
cols <- names(out)
message("Columns present: ", paste(cols, collapse = ", "))
if (!all(c("term", "coef") %in% cols)) stop("Missing essential columns")
if (any(c("estimate", "std.error") %in% cols)) stop("Failed to hide raw columns")
message("Structure check passed.")

message("\n=== Verification Complete ===")
