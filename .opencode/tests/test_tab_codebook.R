# Verification Script: tab1, tab, codebook
# 25 scenarios covering issues 2.1, 2.3, 2.5, 4.3
# Run: Rscript .opencode/reports/test_tab_codebook.R

library(dplyr); library(tibble); library(tidyr); library(tidyselect)
library(stringr); library(purrr); library(rlang); library(pillar); library(vctrs)
library(haven)

source("R/s_try.R"); source("R/s_type.R"); source("R/s_select.R")
source("R/names.R"); source("R/type_conversion.R")
source("R/tab-helpers.R"); source("R/summ-helpers.R"); source("R/tab.R")
source("R/codebook.R")

sw <- dplyr::starwars
pass <- 0; fail <- 0

chk <- function(id, desc, expr, test_fn) {
  tryCatch({
    out <- expr
    ok  <- test_fn(out)
    status <- if (ok) { pass <<- pass + 1; "PASS" } else { fail <<- fail + 1; "FAIL" }
    message(sprintf("[%s] %s: %s", status, id, desc))
    if (!ok) message("  Output: ", paste(capture.output(print(out))[1:3], collapse=" "))
  }, error = function(e) {
    fail <<- fail + 1
    message(sprintf("[ERROR] %s: %s -> %s", id, desc, e$message))
  })
}

message("\n=== tab1 / tab / codebook Verification: 25 Scenarios ===\n")

# --- tab1: ISSUE 2.1 EXPRESSION SUPPORT ---
chk("2.1a", "tab1 accepts boolean expression",
  tab1(sw, tall = height > 180),
  function(o) is.list(o) && "tall" %in% names(o))

chk("2.1b", "tab1 accepts inline expression",
  tab1(sw, name == "Luke Skywalker"),
  function(o) is.list(o) && length(o) == 1)

chk("2.1c", "tab1 accepts named expression",
  tab1(sw, human = species == "Human"),
  function(o) is.list(o) && "human" %in% names(o) && is.logical(o$human$value))

chk("2.1d", "tab1 still works with column names",
  tab1(sw, sex, gender),
  function(o) is.list(o) && all(c("sex","gender") %in% names(o)))

chk("2.1e", "tab1 still works with tidyselect",
  tab1(sw, ends_with("color")),
  function(o) is.list(o) && length(o) == 3)

chk("2.1f", "tab1 with .type=tibble binds rows",
  tab1(sw, sex, gender, .type = "tibble"),
  function(o) is.data.frame(o) && "variable" %in% names(o))

chk("2.1g", "fre1 with expression support",
  fre1(sw, tall = height > 180, .type = "tibble"),
  function(o) is.data.frame(o))

# --- tab: ISSUE 2.3 MISSING VALUES PER GROUP ---
chk("2.3a", "Missing NA rows at bottom of each group",
  {
    df <- data.frame(x=c("a","b",NA,"a","b",NA), g=c("x","x","x","y","y","y"))
    tab(df, x, .by=g)
  },
  function(o) {
    # NA should appear last within each group
    grp_x <- dplyr::filter(o, g == "x")
    grp_y <- dplyr::filter(o, g == "y")
    last_x <- grp_x$x[nrow(grp_x)]
    last_y <- grp_y$x[nrow(grp_y)]
    is.na(last_x) && is.na(last_y)
  })

chk("2.3b", "Without grouping, NA rows still at bottom",
  tab(data.frame(x=c("a",NA,"b","a")), x),
  function(o) is.na(o$x[nrow(o)]))

chk("2.3c", "No NA rows: order unchanged",
  tab(data.frame(x=c("a","b","a","b")), x),
  function(o) nrow(o) == 2 && !any(is.na(o$x)))

# --- tab: ISSUE 2.5 .DESC ---
chk("2.5a", ".desc=TRUE puts largest groups first, NA last",
  tab(sw, sex, .desc=TRUE),
  function(o) {
    non_na <- dplyr::filter(o, !is.na(sex))
    is.na(o$sex[nrow(o)]) && non_na$n[1] >= non_na$n[nrow(non_na)]
  })

chk("2.5b", ".desc=TRUE within groups: largest n first, NA last",
  tab(data.frame(x=c("a","a","b",NA,"a","b","b","b",NA), g=c("p","p","p","p","q","q","q","q","q")),
      x, .by=g, .desc=TRUE),
  function(o) {
    grp_p <- dplyr::filter(o, g == "p")
    grp_q <- dplyr::filter(o, g == "q")
    # NA should be last in each group, and non-NA sorted by desc(n)
    is.na(grp_p$x[nrow(grp_p)]) &&
    is.na(grp_q$x[nrow(grp_q)]) &&
    grp_p$n[1] >= grp_p$n[nrow(grp_p)-1]
  })

chk("2.5c", ".desc=FALSE (default) sorts alphabetically, NA last",
  tab(sw, sex, .desc=FALSE),
  function(o) is.na(o$sex[nrow(o)]))

# --- tab: GENERAL ---
chk("G1", "tab basic usage",
  tab(sw, sex),
  function(o) all(c("sex","n","percent") %in% names(o)))

chk("G2", "tab with expression",
  tab(sw, tall = height > 180),
  function(o) "tall" %in% names(o))

chk("G3", "tab with multiple vars",
  tab(sw, sex, gender),
  function(o) all(c("sex","gender","n") %in% names(o)))

chk("G4", "tab2 cross-tabulation",
  tab2(sw, sex, gender),
  function(o) is.data.frame(o) && ncol(o) > 2)

chk("G5", "fre adds Total row",
  fre(sw, sex, .type="tibble"),
  function(o) any(o[[1]] == "Total", na.rm=TRUE))

# --- codebook: ISSUE 4.3 ---
chk("4.3a", "codebook: no warning with labelled data",
  {
    df_lbl <- data.frame(x=labelled(c(1L,2L,3L), c(a=1L,b=2L)))
    warned <- FALSE
    withCallingHandlers(
      codebook(df_lbl),
      warning=function(w) { warned <<- TRUE; invokeRestart("muffleWarning") }
    )
    warned
  },
  function(o) o == FALSE)

chk("4.3b", "codebook: no warning with starwars",
  {
    warned <- FALSE
    withCallingHandlers(
      codebook(sw),
      warning=function(w) { warned <<- TRUE; invokeRestart("muffleWarning") }
    )
    warned
  },
  function(o) o == FALSE)

# --- codebook: GENERAL ---
chk("C1", "codebook basic output structure",
  codebook(sw),
  function(o) all(c("variable","type","n","unique") %in% names(o)))

chk("C2", "codebook with selection",
  codebook(sw, 1:4),
  function(o) nrow(o) == 4)

chk("C3", "codebook with tidyselect",
  codebook(sw, ends_with("color")),
  function(o) nrow(o) == 3)

chk("C4", "codebook with numeric filter",
  codebook(sw, where(is.numeric)),
  function(o) nrow(o) == 3)

chk("C5", "codebook with expression",
  codebook(sw, height > 0),
  function(o) nrow(o) == 1)

chk("C6", "codebook_var type matches s_type",
  codebook(data.frame(a=1L, b=2.0, c="x", d=TRUE)),
  function(o) "integer" %in% o$type && "double" %in% o$type)

message(sprintf("\n=== Results: %d PASS, %d FAIL ===", pass, fail))
if (fail > 0) quit(status=1)
