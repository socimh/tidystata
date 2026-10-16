
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

message("\n--- Testing tab1 with expressions ---")
tryCatch({
  df <- data.frame(temp = c(26, 26, 39, 40))
  # User said tab1() does not work with expressions
  print(tab1(df, t1 = temp == 26))
}, error = function(e) {
  message("Error in tab1(expression): ", e$message)
})

message("\n--- Testing summ with Inf ---")
tryCatch({
  df_inf <- data.frame(x = c(1, 2, Inf, -Inf, 5))
  print(summ(df_inf))
}, error = function(e) {
  message("Error in summ(Inf): ", e$message)
})

message("\n--- Testing summ with datetime ---")
tryCatch({
  df_time <- data.frame(
    dt = as.POSIXct(c("2023-01-01", "2023-01-02", "2023-01-03"))
  )
  print(summ(df_time))
}, error = function(e) {
  message("Error in summ(datetime): ", e$message)
})

message("\n--- Testing cut_quantile ---")
tryCatch({
  x2 <- c(rep(1, 40), rep(2, 60))
  # User says cut_quantile(x, 2) may not split equally
  print(table(cut_quantile(x2, 2)))
}, error = function(e) {
  message("Error in cut_quantile: ", e$message)
})
