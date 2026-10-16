
library(statart)
library(dplyr)
library(lme4)
library(broom)
library(broom.mixed)

# Load package
# devtools::load_all()
source("R/s_try.R")
source("R/esttab.R")

# 1. Basic LM example
message("\n--- 1. Basic LM Model ---")
m_lm <- lm(mpg ~ wt + hp, data = mtcars)
print(esttab(m_lm))

# 2. Custom Formatting
message("\n--- 2. Custom Formatting ---")
print(esttab(m_lm, format = "{estimate} (p={p.value})"))

# 3. With Statistics
message("\n--- 3. With Statistics ---")
print(esttab(m_lm, stats = c("N", "r2", "aic")))

# 4. Mixed Model (lmer) - The Bug Fix
message("\n--- 4. Mixed Model (lmer) ---")
m_lmer <- lmer(Reaction ~ Days + (Days | Subject), sleepstudy)
print(esttab(m_lmer))

# 5. Invalid Input
message("\n--- 5. Invalid Input (Error Check) ---")
tryCatch({
  esttab("not a model")
}, error = function(e) {
  message("Correctly caught error: ", e$message)
})
