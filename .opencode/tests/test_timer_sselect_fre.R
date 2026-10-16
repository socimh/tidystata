# Verification Script: timer, s_select, fre performance
# 22 scenarios covering batch 3 improvements
# Run: Rscript .opencode/reports/test_timer_sselect_fre.R

library(dplyr); library(tibble); library(tidyr); library(tidyselect)
library(stringr); library(purrr); library(rlang)
source("R/s_try.R"); source("R/s_type.R"); source("R/s_select.R")
source("R/names.R"); source("R/type_conversion.R")
source("R/tab-helpers.R"); source("R/summ-helpers.R"); source("R/tab.R")
source("R/timer.R")

sw <- dplyr::starwars
pass <- 0; fail <- 0

chk <- function(id, desc, expr, test_fn) {
  tryCatch({
    out <- expr
    ok  <- test_fn(out)
    status <- if (ok) { pass <<- pass + 1; "PASS" } else { fail <<- fail + 1; "FAIL" }
    message(sprintf("[%s] %s: %s", status, id, desc))
    if (!ok) message("  Output: ", paste(deparse(out), collapse=" "))
  }, error = function(e) {
    fail <<- fail + 1
    message(sprintf("[ERROR] %s: %s -> %s", id, desc, e$message))
  })
}

message("\n=== timer / s_select / fre Verification: 22 Scenarios ===\n")

# --- timer: compact output format ---
chk("T1", "Sub-second: format 0.Xs",
  duration_to_chr(0.05),
  function(o) grepl("^0\\.", o) && grepl("s$", o))

chk("T2", "Seconds (1-59): format X.XXs",
  duration_to_chr(5.23),
  function(o) grepl("^5\\.2", o) && grepl("s$", o))

chk("T3", "Minutes: format XmYs",
  duration_to_chr(75),
  function(o) grepl("^1m", o) && grepl("s$", o))

chk("T4", "Minutes no seconds edge: '2m0s'",
  duration_to_chr(120),
  function(o) o == "2m0s")

chk("T5", "Hours: format XhYm",
  duration_to_chr(3700),
  function(o) grepl("^1h", o) && grepl("m$", o))

chk("T6", "Hours no minutes: '2h0m'",
  duration_to_chr(7200),
  function(o) o == "2h0m")

chk("T7", "timer() returns value invisibly",
  {
    result <- timer(42)
    result
  },
  function(o) o == 42)

chk("T8", "timer() emits a message",
  {
    msgs <- character(0)
    withCallingHandlers(
      timer(1 + 1),
      message = function(m) { msgs <<- c(msgs, conditionMessage(m)); invokeRestart("muffleMessage") }
    )
    msgs
  },
  function(o) length(o) > 0 && grepl("Time spent", o[1]))

chk("T9", "Compact format: no 'hours'/'mins'/'secs' in output",
  {
    c(duration_to_chr(5), duration_to_chr(75), duration_to_chr(3700))
  },
  function(o) !any(grepl("hours|mins|secs", o)))

# --- s_select: better error messages ---
chk("S1", "Error message mentions column name",
  tryCatch(s_select(mtcars, nonexistent_col), error = function(e) e$message),
  function(o) grepl("nonexistent_col", o))

chk("S2", "Error message explains both select() and mutate() failed",
  tryCatch(s_select(mtcars, xyz_123), error = function(e) e$message),
  function(o) grepl("select.*error|select() error", o) && grepl("mutate.*error|mutate() error", o))

chk("S3", "s_select still works with valid column names",
  s_select(mtcars, mpg, cyl),
  function(o) all(c("mpg","cyl") %in% names(o)) && nrow(o) == 32)

chk("S4", "s_select still works with expressions",
  s_select(mtcars, large = mpg > 20),
  function(o) "large" %in% names(o) && is.logical(o$large))

chk("S5", "s_select empty ... returns full data",
  s_select(mtcars),
  function(o) ncol(o) == ncol(mtcars))

chk("S6", "s_select error has informative detail (both error messages shown)",
  tryCatch(s_select(sw, fake_var), error = function(e) e$message),
  function(o) nchar(o) > 50)

# --- fre: performance ---
chk("F1", "fre() is within 3x time of tab() on 100k rows",
  {
    big <- data.frame(x=sample(letters[1:5], 100000, TRUE), stringsAsFactors=FALSE)
    t_tab <- system.time(tab(big, x))["elapsed"]
    t_fre <- system.time(fre(big, x, .type="tibble"))["elapsed"]
    t_fre / max(t_tab, 0.001)
  },
  function(o) o < 3)

chk("F2", "fre() Total row present",
  fre(sw, sex, .type="tibble"),
  function(o) any(o[[1]] == "Total", na.rm=TRUE))

chk("F3", "fre() Valid Total row present when missing values exist",
  fre(sw, sex, .type="tibble"),
  function(o) any(o[[1]] == "Valid Total", na.rm=TRUE))

chk("F4", "fre() Total n equals nrow of input data",
  {
    out <- fre(sw, sex, .type="tibble")
    total_row <- out[!is.na(out[[1]]) & out[[1]] == "Total", ]
    total_row$n == nrow(sw)
  },
  function(o) isTRUE(o))

chk("F5", "fre() with no missing: no Valid Total row",
  {
    out <- fre(data.frame(x=c("a","b","a")), x, .type="tibble")
    !any(out[[1]] == "Valid Total", na.rm=TRUE)
  },
  function(o) o == TRUE)

chk("F6", "fre1() with tibble type works",
  fre1(sw, sex, gender, .type="tibble"),
  function(o) is.data.frame(o) && "variable" %in% names(o))

chk("F7", "fre() with .by group works",
  fre(sw, sex, .by=gender, .type="tibble"),
  function(o) "gender" %in% names(o))

message(sprintf("\n=== Results: %d PASS, %d FAIL ===", pass, fail))
if (fail > 0) quit(status=1)
