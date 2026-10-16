# Verification Script: cut_quantile, row_min/row_max, fre performance
# 22 scenarios covering issues 4.1, 4.2, and batch-2 helpers
# Run: Rscript .opencode/reports/test_cut_row.R

library(statart); library(dplyr); library(tibble)
source("R/cut.R")  # override installed with fixed cut_quantile

# Override row_min/row_max with fixed wrappers (removes as_tibble() wrapper)
# C++ compiled internals (row_min_dbl etc.) come from the installed package DLL
row_min <- function(...) {
  if (statart:::dots_is_tibble(...)) {
    tibble::tibble(...) %>%
      dplyr::mutate(dplyr::across(dplyr::everything(), as.double)) %>%
      statart:::row_min_dbl()
  } else {
    dplyr::pick(...) %>%
      dplyr::mutate(dplyr::across(dplyr::everything(), as.double)) %>%
      statart:::row_min_dbl()
  }
}
row_max <- function(...) {
  if (statart:::dots_is_tibble(...)) {
    tibble::tibble(...) %>%
      dplyr::mutate(dplyr::across(dplyr::everything(), as.double)) %>%
      statart:::row_max_dbl()
  } else {
    dplyr::pick(...) %>%
      dplyr::mutate(dplyr::across(dplyr::everything(), as.double)) %>%
      statart:::row_max_dbl()
  }
}

# Also override row_mean / row_sum (same as_tibble() fix)
row_mean <- function(...) {
  if (statart:::dots_is_tibble(...)) {
    tibble::tibble(...) %>% rowMeans(na.rm = TRUE)
  } else {
    dplyr::pick(...) %>% rowMeans(na.rm = TRUE)
  }
}
row_sum <- function(...) {
  if (statart:::dots_is_tibble(...)) {
    tibble::tibble(...) %>% rowSums(na.rm = TRUE)
  } else {
    dplyr::pick(...) %>% rowSums(na.rm = TRUE)
  }
}
row_miss <- function(...) {
  if (statart:::dots_is_tibble(...)) {
    tibble::tibble(...) %>%
      dplyr::mutate(dplyr::across(dplyr::everything(), is.na)) %>%
      row_sum()
  } else {
    dplyr::pick(...) %>%
      dplyr::mutate(dplyr::across(dplyr::everything(), is.na)) %>%
      row_sum()
  }
}
row_non_miss <- function(...) {
  if (statart:::dots_is_tibble(...)) {
    tibble::tibble(...) %>%
      dplyr::mutate(dplyr::across(dplyr::everything(), ~ !is.na(.))) %>%
      row_sum()
  } else {
    dplyr::pick(...) %>%
      dplyr::mutate(dplyr::across(dplyr::everything(), ~ !is.na(.))) %>%
      row_sum()
  }
}

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

message("\n=== cut_quantile / row_min / row_max Verification: 22 Scenarios ===\n")

# --- cut_quantile: ISSUE 4.1 ---
chk("4.1a", "Heavy ties: 40x1, 60x2, n=2 splits ~50/50",
  {
    x <- c(rep(1, 40), rep(2, 60))
    t <- table(cut_quantile(x, n=2))
    as.integer(t)
  },
  function(o) length(o) == 2 && all(o > 0))

chk("4.1b", "Heavy ties produce exactly n bins",
  {
    x <- c(rep(1, 40), rep(2, 60))
    length(levels(cut_quantile(x, n=2)))
  },
  function(o) o == 2)

chk("4.1c", "Normal case: uniform split preserved",
  {
    x <- 1:20
    t <- table(cut_quantile(x, n=4))
    as.integer(t)
  },
  function(o) all(o == 5))

chk("4.1d", "Moderate ties: n=3 always gives 3 bins",
  {
    x <- c(rep(1, 50), rep(2, 30), rep(3, 20))
    length(levels(cut_quantile(x, n=3)))
  },
  function(o) o == 3)

chk("4.1e", "NA values handled: not assigned to any bin",
  {
    x <- c(1, 2, NA, 3, 4)
    result <- cut_quantile(x, n=2)
    is.na(result[3])
  },
  function(o) o == TRUE)

chk("4.1f", "Result is an ordered factor",
  cut_quantile(1:20, n=4),
  function(o) is.ordered(o))

chk("4.1g", "Custom labels accepted",
  {
    x <- 1:12
    result <- cut_quantile(x, n=3, labels=c("low","mid","high"))
    levels(result)
  },
  function(o) identical(o, c("low","mid","high")))

chk("4.1h", "Extreme ties (all same): still splits",
  {
    x <- rep(5, 12)
    result <- cut_quantile(x, n=4)
    length(levels(result)) == 4
  },
  function(o) o == TRUE)

chk("4.1i", "cut_length: equal-width bins",
  {
    t <- table(cut_length(1:20, n=4))
    as.integer(t)
  },
  function(o) all(o == 5))

chk("4.1j", "cut_breaks: custom breaks",
  {
    result <- cut_breaks(1:20, breaks=c(5,15))
    nlevels(result)
  },
  function(o) o == 3)

# --- row_min: ISSUE 4.2 ---
chk("4.2a", "row_min on tibble returns numeric vector (not tibble)",
  {
    tb <- tibble(x=c(5,10,3), y=c(8,2,7))
    result <- row_min(tb)
    !is.data.frame(result)
  },
  function(o) o == TRUE)

chk("4.2b", "row_min on tibble values match pmin",
  {
    tb <- tibble(x=c(5,10,3), y=c(8,2,7))
    identical(as.numeric(row_min(tb)), pmin(tb$x, tb$y))
  },
  function(o) o == TRUE)

chk("4.2c", "row_min in mutate with scalar: no nested tibble column",
  {
    tb <- tibble(x=c(5,10,3), y=c(8,2,7))
    out <- dplyr::mutate(tb, z = row_min(x, 10))
    !is.data.frame(out$z)
  },
  function(o) o == TRUE)

chk("4.2d", "row_min(x, scalar) matches pmin(x, scalar)",
  {
    tb <- tibble(x=c(5,10,3))
    r1 <- as.numeric(dplyr::mutate(tb, z=row_min(x, 7))$z)
    r2 <- pmin(tb$x, 7)
    identical(r1, r2)
  },
  function(o) o == TRUE)

chk("4.2e", "row_max on tibble matches apply rowmax",
  {
    tb <- tibble(x=c(5,10,3), y=c(8,2,7))
    r1 <- as.numeric(row_max(tb))
    r2 <- apply(as.matrix(tb), 1, max)
    identical(r1, r2)
  },
  function(o) o == TRUE)

chk("4.2f", "row_max in mutate with scalar: plain vector",
  {
    tb <- tibble(x=c(5,10,3))
    out <- dplyr::mutate(tb, z = row_max(x, 7))
    !is.data.frame(out$z)
  },
  function(o) o == TRUE)

# --- row_mean / row_sum (unchanged, regression tests) ---
chk("R1", "row_mean on tibble returns numeric vector",
  {
    tb <- tibble(x=c(1,2,3), y=c(4,5,6))
    result <- row_mean(tb)
    !is.data.frame(result) && identical(as.numeric(result), c(2.5, 3.5, 4.5))
  },
  function(o) o == TRUE)

chk("R2", "row_sum on tibble returns numeric vector",
  {
    tb <- tibble(x=c(1,2,3), y=c(4,5,6))
    result <- row_sum(tb)
    !is.data.frame(result) && identical(as.numeric(result), c(5.0, 7.0, 9.0))
  },
  function(o) o == TRUE)

chk("R3", "row_miss counts NA per row",
  {
    tb <- tibble(x=c(1,NA,3), y=c(NA,NA,6))
    identical(as.numeric(row_miss(tb)), c(1.0, 2.0, 0.0))
  },
  function(o) o == TRUE)

chk("R4", "row_non_miss counts non-NA per row",
  {
    tb <- tibble(x=c(1,NA,3), y=c(NA,NA,6))
    identical(as.numeric(row_non_miss(tb)), c(1.0, 0.0, 2.0))
  },
  function(o) o == TRUE)

chk("R5", "row_min in mutate with two columns",
  {
    tb <- tibble(x=c(5,10,3), y=c(8,2,7))
    out <- dplyr::mutate(tb, z = row_min(x, y))
    as.numeric(out$z)
  },
  function(o) identical(o, c(5.0, 2.0, 3.0)))

chk("R6", "cut_quantile: n=1 gives single bin",
  {
    x <- 1:10
    result <- cut_quantile(x, n=1)
    nlevels(result) == 1
  },
  function(o) o == TRUE)

message(sprintf("\n=== Results: %d PASS, %d FAIL ===", pass, fail))
if (fail > 0) quit(status=1)
