
library(dplyr)
library(lme4)
library(broom)
library(broom.mixed)

# Source necessary files
source("R/s_try.R")
source("R/s_type.R")
source("R/s_select.R")
source("R/names.R")
source("R/esttab.R")
source("R/tab.R")
source("R/tab-helpers.R")
source("R/summ.R")
source("R/summ-helpers.R")
source("R/cut.R")
source("R/type_conversion.R")
source("R/variables.R")
source("R/na_conversion.R")

message("--- Testing esttab with lmer ---")
tryCatch({
  m1 <- lmer(Reaction ~ Days + (Days | Subject), sleepstudy)
  print(esttab(m1))
}, error = function(e) {
  message("Error in esttab(lmer): ", e$message)
})

message("\n--- Testing esttab error handling ---")
tryCatch({
  esttab("not a model")
}, error = function(e) {
  message("Error in esttab(invalid): ", e$message)
})

message("\n--- Testing esttab custom format ---")
tryCatch({
  m_lm <- lm(mpg ~ wt + hp, data = mtcars)
  print(esttab(m_lm, format = "{estimate} (p={p.value})"))
}, error = function(e) {
  message("Error in esttab(custom format): ", e$message)
})

message("\n--- Testing esttab with stats ---")
tryCatch({
  m_lm <- lm(mpg ~ wt + hp, data = mtcars)
  print(esttab(m_lm, stats = c("n.obs", "r.squared", "AIC")))
}, error = function(e) {
  message("Error in esttab(stats): ", e$message)
})

message("\n--- Testing esttab with Stata-like stats ---")
tryCatch({
  m_lm <- lm(mpg ~ wt + hp, data = mtcars)
  print(esttab(m_lm, stats = c("N", "r2", "aic")))
}, error = function(e) {
  message("Error in esttab(Stata-like stats): ", e$message)
})
