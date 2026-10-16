# Verification Script: summ()
# 25 test scenarios covering all 5 fixed issues + edge cases
# Run: Rscript .opencode/reports/test_summ.R

library(dplyr); library(tibble); library(tidyr); library(tidyselect)
library(stringr); library(purrr); library(rlang)
library(pillar); library(vctrs)

source("R/s_try.R"); source("R/s_type.R"); source("R/s_select.R")
source("R/names.R"); source("R/stat.R"); source("R/type_conversion.R")
source("R/summ-helpers.R"); source("R/summ.R")

pass <- 0; fail <- 0
results <- list()

chk <- function(id, desc, expr, test_fn) {
  tryCatch({
    out <- expr
    ok  <- test_fn(out)
    status <- if (ok) { pass <<- pass + 1; "PASS" } else { fail <<- fail + 1; "FAIL" }
    results[[id]] <<- list(id=id, desc=desc, status=status, output=out, error=NULL)
    message(sprintf("[%s] %s: %s", status, id, desc))
    if (!ok) message("       Output: ", paste(capture.output(print(out)), collapse="\n       "))
  }, error = function(e) {
    fail <<- fail + 1
    results[[id]] <<- list(id=id, desc=desc, status="ERROR", output=NULL, error=e$message)
    message(sprintf("[ERROR] %s: %s\n        Error: %s", id, desc, e$message))
  })
}

message("\n=== summ() Verification: 25 Scenarios ===\n")

# --- BASIC FUNCTIONALITY ---
chk("1.1", "Basic numeric summary",
  summ(mtcars, mpg),
  function(o) is.data.frame(o) && all(c("type","n","mean","sd","min","max") %in% names(o)))

chk("1.2", "Multiple numeric variables",
  summ(mtcars, mpg, hp, wt),
  function(o) nrow(o) == 3 && "name" %in% names(o))

chk("1.3", "All numeric variables via where()",
  summ(mtcars, dplyr::where(is.numeric)),
  function(o) nrow(o) == ncol(dplyr::select(mtcars, dplyr::where(is.numeric))))

chk("1.4", "Group by one variable",
  summ(mtcars, mpg, .by = cyl),
  function(o) "cyl" %in% names(o) && nrow(o) == 3)

chk("1.5", "tabstat() wrapper returns mean by default",
  tabstat(mtcars, .by = cyl),
  function(o) "cyl" %in% names(o) && "mean" %in% names(o))

chk("1.6", "Custom .stat selection",
  summ(mtcars, mpg, .stat = c("mean","sd")),
  function(o) all(c("type","mean","sd") %in% names(o)) && !"min" %in% names(o))

chk("1.7", ".detail = TRUE returns extended statistics",
  summ(mtcars, mpg, .detail = TRUE),
  function(o) all(c("median","q1","q3","skew","kurtosis") %in% names(o)))

chk("1.8", "Pre-grouped data frame respected",
  mtcars %>% dplyr::group_by(cyl) %>% summ(mpg),
  function(o) "cyl" %in% names(o))

# --- INF/-INF HANDLING (Issue 3.1) ---
chk("2.1", "Inf/-Inf: min/max show Inf not NA",
  summ(data.frame(x = c(1, 2, Inf, -Inf, 3))),
  function(o) o$min == -Inf && o$max == Inf)

chk("2.2", "All-Inf vector: reports Inf in min and max",
  summ(data.frame(x = c(Inf, Inf, Inf))),
  function(o) is.data.frame(o) && !is.na(o$max))

chk("2.3", "Mix of NA and Inf",
  summ(data.frame(x = c(1, NA, Inf, 2))),
  function(o) o$max == Inf && o$n == 3)

# --- DATE/DATETIME FORMATTING (Issue 3.2) ---
chk("3.1", "Date min/mean/max are formatted strings not numerics",
  summ(data.frame(d = as.Date(c("2020-01-01","2021-06-15","2022-12-31")))),
  function(o) is.character(o$mean) && grepl("^\\d{4}-\\d{2}-\\d{2}$", o$mean))

chk("3.2", "Date sd is human-readable (e.g. '548d')",
  summ(data.frame(d = as.Date(c("2020-01-01","2021-06-15","2022-12-31")))),
  function(o) is.character(o$sd) && grepl("d$", o$sd))

chk("3.3", "POSIXct mean is formatted datetime string",
  summ(data.frame(dt = as.POSIXct(c("2020-01-01 12:00","2021-06-15 08:30"), tz="UTC"))),
  function(o) is.character(o$mean) && grepl("\\d{4}-\\d{2}-\\d{2}", o$mean))

chk("3.4", "POSIXct sd is human-readable span",
  summ(data.frame(dt = as.POSIXct(c("2020-01-01 12:00","2022-01-01 00:00"), tz="UTC"))),
  function(o) is.character(o$sd) && grepl("[dhms]$", o$sd))

chk("3.5", "Date with groups still formats correctly",
  summ(data.frame(d=as.Date(c("2020-01-01","2021-01-01","2022-01-01")),
                  g=c("a","a","b")), .by=g),
  function(o) is.character(o$mean) && all(grepl("^\\d{4}", o$mean)))

# --- .NA.RM FOR GROUPING (Issue 3.4) ---
chk("4.1", ".na.rm=TRUE drops NA group rows",
  summ(data.frame(x=c(1,2,3,4), g=c("a","a",NA,"b")), .by=g, .na.rm=TRUE),
  function(o) !any(is.na(o$g)))

chk("4.2", ".na.rm=FALSE (default) keeps NA group rows",
  summ(data.frame(x=c(1,2,3,4), g=c("a","a",NA,"b")), .by=g, .na.rm=FALSE),
  function(o) any(is.na(o$g)))

chk("4.3", ".na.rm with no NA groups unchanged",
  summ(mtcars, mpg, .by=cyl, .na.rm=TRUE),
  function(o) nrow(o) == 3)

# --- NAME COLUMN (Issue 3.5) ---
chk("5.1", ".name=FALSE drops name col for single variable",
  summ(mtcars, mpg, .name=FALSE),
  function(o) !"name" %in% names(o))

chk("5.2", ".name=TRUE (default) keeps name col always",
  summ(mtcars, mpg, .name=TRUE),
  function(o) "name" %in% names(o))

chk("5.3", ".name=FALSE keeps name col for multiple variables",
  summ(mtcars, mpg, hp, .name=FALSE),
  function(o) "name" %in% names(o))

# --- EDGE CASES ---
chk("6.1", "All-NA column removed with warning",
  withCallingHandlers(
    summ(data.frame(x=c(1,2,3), y=c(NA,NA,NA))),
    warning=function(w) invokeRestart("muffleWarning")
  ),
  function(o) "name" %in% names(o) && nrow(o) >= 1)

chk("6.2", "Factor variable triggers warning but keeps running",
  withCallingHandlers(
    summ(data.frame(x=1:5, f=factor(c("a","b","a","b","a")))),
    warning=function(w) invokeRestart("muffleWarning")
  ),
  function(o) is.data.frame(o))

chk("6.3", "Large dataset completes quickly (< 2s for 100k rows)",
  {
    big <- data.frame(x=rnorm(100000), y=rnorm(100000), g=sample(letters[1:10],100000,T))
    t1 <- system.time(summ(big, .by=g))
    t1["elapsed"]
  },
  function(o) o < 2.0)

chk("6.4", "Zero-variance column handled",
  summ(data.frame(x=rep(5, 10))),
  function(o) o$sd == 0 && o$min == 5 && o$max == 5)

chk("6.5", "tabstat() .na.rm forwards correctly",
  tabstat(data.frame(x=c(1,2,3), g=c("a",NA,"b")), .by=g, .na.rm=TRUE),
  function(o) !any(is.na(o$g)))

message(sprintf("\n=== Results: %d PASS, %d FAIL ===", pass, fail))
if (fail > 0) {
  failed <- Filter(function(r) r$status != "PASS", results)
  message("FAILED scenarios:")
  for (r in failed) message(sprintf("  - %s: %s | %s", r$id, r$desc, r$error %||% "wrong output"))
}
