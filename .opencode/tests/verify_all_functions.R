# Master Verification Script: Capture Actual Function Outputs
# This script runs all functions and prints actual results for manual verification
# Run: Rscript .opencode/tests/verify_all_functions.R

library(dplyr)
library(tibble)
library(tidyr)
library(tidyselect)
library(stringr)
library(purrr)
library(rlang)
library(pillar)
library(vctrs)
library(lme4)

# Load statart package (needed for compiled C++ functions in row operations)
# Install from local source if needed
devtools::load_all(".", quiet = TRUE)

cat("\n========================================\n")
cat("MASTER VERIFICATION: ACTUAL OUTPUTS\n")
cat("========================================\n\n")

# ============================================
# PART 1: summ() / tabstat()
# ============================================
cat("\n\n========================================\n")
cat("PART 1: summ() / tabstat()\n")
cat("========================================\n")

cat("\n--- Test 1.1: Basic numeric summary ---\n")
print(summ(mtcars, mpg))

cat("\n--- Test 1.2: Multiple numeric variables ---\n")
print(summ(mtcars, mpg, hp, wt))

cat("\n--- Test 1.3: Group by one variable ---\n")
print(summ(mtcars, mpg, .by = cyl))

cat("\n--- Test 1.4: tabstat() wrapper ---\n")
print(tabstat(mtcars, .by = cyl))

cat("\n--- Test 1.5: Custom .stat selection ---\n")
print(summ(mtcars, mpg, .stat = c("mean", "sd")))

cat("\n--- Test 1.6: .detail = TRUE ---\n")
print(summ(mtcars, mpg, .detail = TRUE))

cat("\n--- Test 2.1: Inf/-Inf handling ---\n")
print(summ(data.frame(x = c(1, 2, Inf, -Inf, 3))))

cat("\n--- Test 3.1: Date formatting (table mode) ---\n")
print(summ(data.frame(d = as.Date(c("2020-01-01", "2021-06-15", "2022-12-31"))), .mode = "table"))

cat("\n--- Test 3.1b: Date formatting (list mode with long duration) ---\n")
result <- summ(data.frame(d = as.Date(c("2020-01-01", "2021-06-15", "2022-12-31"))), .duration_format = "long")
print(result)
cat("\nStructure:\n")
print(str(result))

cat("\n--- Test 3.3: POSIXct formatting ---\n")
print(summ(data.frame(dt = as.POSIXct(c("2020-01-01 12:00", "2021-06-15 08:30"), tz = "UTC"))))

cat("\n--- Test 4.1: .na.rm=TRUE ---\n")
print(summ(data.frame(x = c(1, 2, 3, 4), g = c("a", "a", NA, "b")), .by = g, .na.rm = TRUE))

cat("\n--- Test 5.1: .name=FALSE ---\n")
print(summ(mtcars, mpg, .name = FALSE))

cat("\n--- Test 6.4: Zero-variance column ---\n")
print(summ(data.frame(x = rep(5, 10))))

# ============================================
# PART 2: tab() / tab1() / fre() / codebook()
# ============================================
cat("\n\n========================================\n")
cat("PART 2: tab() / tab1() / fre() / codebook()\n")
cat("========================================\n")

sw <- dplyr::starwars

cat("\n--- Test 2.1a: tab1 with boolean expression ---\n")
result <- tab1(sw, tall = height > 180)
print(result)

cat("\n--- Test 2.1d: tab1 with column names ---\n")
result <- tab1(sw, sex, gender)
print(result)

cat("\n--- Test G1: tab basic usage ---\n")
print(tab(sw, sex))

cat("\n--- Test G3: tab with multiple vars ---\n")
print(tab(sw, sex, gender))

cat("\n--- Test G4: tab2 cross-tabulation ---\n")
print(tab2(sw, sex, gender))

cat("\n--- Test G5: fre with Total row ---\n")
print(fre(sw, sex, .type = "tibble"))

cat("\n--- Test 2.3a: Missing NA rows at bottom ---\n")
df <- data.frame(x = c("a", "b", NA, "a", "b", NA), g = c("x", "x", "x", "y", "y", "y"))
print(tab(df, x, .by = g))

cat("\n--- Test 2.5a: .desc=TRUE ---\n")
print(tab(sw, sex, .desc = TRUE))

cat("\n--- Test C1: codebook basic output ---\n")
print(codebook(sw))

cat("\n--- Test C3: codebook with tidyselect ---\n")
print(codebook(sw, ends_with("color")))

cat("\n--- Test C4: codebook with numeric filter ---\n")
print(codebook(sw, where(is.numeric)))

# ============================================
# PART 3: esttab()
# ============================================
cat("\n\n========================================\n")
cat("PART 3: esttab()\n")
cat("========================================\n")

cat("\n--- Test 1.1: Simple linear regression ---\n")
model1 <- lm(mpg ~ wt, data = mtcars)
print(esttab(model1))

cat("\n--- Test 1.2: Multiple regression ---\n")
model2 <- lm(mpg ~ wt + hp + disp, data = mtcars)
print(esttab(model2))

cat("\n--- Test 1.3: Logistic regression ---\n")
mtcars$am_factor <- factor(mtcars$am)
model3 <- glm(am_factor ~ wt + mpg, data = mtcars, family = binomial)
print(esttab(model3))

cat("\n--- Test 1.4: Linear mixed effects (lmer) ---\n")
set.seed(123)
sleepstudy_test <- sleepstudy[sample(nrow(sleepstudy), 100), ]
model4 <- lmer(Reaction ~ Days + (1 | Subject), data = sleepstudy_test)
print(esttab(model4))

cat("\n--- Test 1.6: Regression with factors ---\n")
model6 <- lm(mpg ~ wt + factor(cyl), data = mtcars)
print(esttab(model6))

cat("\n--- Test 3.4: Statistics n.obs and r.squared ---\n")
print(esttab(model1, stats = c("n.obs", "r.squared")))

cat("\n--- Test 3.1: Custom format ---\n")
print(esttab(model1, format = "{estimate} ({std.error})"))

# ============================================
# PART 4: cut_quantile() / row functions
# ============================================
cat("\n\n========================================\n")
cat("PART 4: cut_quantile() / row functions\n")
cat("========================================\n")

cat("\n--- Test 4.1a: cut_quantile heavy ties ---\n")
x <- c(rep(1, 40), rep(2, 60))
print(table(cut_quantile(x, n = 2)))

cat("\n--- Test 4.1c: cut_quantile normal case ---\n")
print(table(cut_quantile(1:100, n = 4)))

cat("\n--- Test 4.1e: cut_quantile with NA ---\n")
print(table(cut_quantile(c(1:98, NA, NA), n = 4), useNA = "ifany"))

cat("\n--- Test R1: row_min on tibble ---\n")
df <- tibble(a = c(1, 2, 3), b = c(3, 2, 1), c = c(2, 3, 1))
print(row_min(df))

cat("\n--- Test R2: row_max on tibble ---\n")
print(row_max(df))

cat("\n--- Test R3: row_mean ---\n")
print(row_mean(df))

cat("\n--- Test R4: row_sum ---\n")
print(row_sum(df))

cat("\n--- Test R5: row_miss ---\n")
df_na <- tibble(a = c(1, NA, 3), b = c(NA, 2, 1), c = c(2, 3, NA))
print(row_miss(df_na))

cat("\n--- Test R6: row_non_miss ---\n")
print(row_non_miss(df_na))

# ============================================
# PART 5: timer() / s_select() / fre()
# ============================================
cat("\n\n========================================\n")
cat("PART 5: timer() / s_select() / fre()\n")
cat("========================================\n")

cat("\n--- Test T1: timer sub-second ---\n")
result <- timer(Sys.sleep(0.1))

cat("\n--- Test T3: timer minutes ---\n")
# Simulated: timer would show format for longer operations

cat("\n--- Test S3: s_select with valid columns ---\n")
df <- data.frame(a = 1:5, b = 6:10, c = 11:15)
print(s_select(df, a, b))

cat("\n--- Test S4: s_select with expressions ---\n")
print(s_select(df, a, d = b * 2))

cat("\n--- Test S5: s_select empty returns full data ---\n")
print(s_select(df))

cat("\n--- Test F2: fre Total row ---\n")
print(fre(mtcars, cyl, .type = "tibble"))

cat("\n--- Test F7: fre with .by group ---\n")
print(fre(mtcars, gear, .by = cyl, .type = "tibble"))

cat("\n\n========================================\n")
cat("VERIFICATION COMPLETE\n")
cat("========================================\n")
