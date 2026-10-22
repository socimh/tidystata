# Compare installed packages using identical fixed inputs and visible timings.
args <- commandArgs(trailingOnly = TRUE)
stopifnot(length(args) == 2L)
library(tidystata, lib.loc = args[[1L]])
prefix <- args[[2L]]
company <- paste0("\u9999\u6e2f-company-", seq_len(21))
large <- data.frame(
  keep = seq_len(200000) <= 37L,
  company = rep(company, length.out = 200000)
)
small <- large[large$keep, , drop = FALSE]
numeric_data <- data.frame(
  g = rep(seq_len(20), each = 1000),
  x = sin(seq_len(20000)),
  day = as.Date("2024-01-01") + seq_len(20000) %% 1000
)
jobs <- list(
  tab_small = function() tab(small, company, .desc = TRUE),
  fre_small = function() fre(small, company, .desc = TRUE),
  fre_pipeline = function() {
    fre(dplyr::filter(large, keep), company, .desc = TRUE)
  },
  summ_mean = function() summ(numeric_data, x, .by = g, .stat = "mean"),
  summ_detail = function() summ(numeric_data, x, .by = g, .detail = TRUE),
  summ_calendar_mean = function() {
    summ(numeric_data, day, .by = g, .stat = "mean")
  }
)
# Fixed synthetic workloads cover setup overhead, row count, group count and width.
set.seed(20261019)
workload <- function(n, groups, columns = 2L) {
  out <- data.frame(g = rep(seq_len(groups), length.out = n))
  for (j in seq_len(columns)) {
    out[[paste0("x", j)]] <- stats::rnorm(n)
  }
  out$category <- sample(c(letters, NA_character_), n, replace = TRUE)
  out$x1[seq.int(1L, n, by = 23L)] <- NA_real_
  out
}
small_numeric <- workload(1000L, 10L)
large_numeric <- workload(1000000L, 100L)
many_groups <- workload(100000L, 10000L)
wide_numeric <- workload(10000L, 100L, 40L)
jobs <- c(
  jobs,
  list(
    tab_ordinary = function() tab(small_numeric, category),
    summ_ordinary = function() summ(small_numeric, x1, x2),
    tab_large = function() tab(large_numeric, category, .by = g),
    summ_large = function() summ(large_numeric, x1, x2, .by = g),
    tab_many_groups = function() tab(many_groups, category, .by = g),
    summ_many_groups = function() summ(many_groups, x1, x2, .by = g),
    summ_many_groups_detail = function() {
      summ(many_groups, x1, x2, .by = g, .detail = TRUE)
    },
    summ_wide = function() summ(wide_numeric, dplyr::starts_with("x"), .by = g)
  )
)
# Metadata-heavy and distinct-counting workloads for the second performance pass.
wide_codebook <- as.data.frame(stats::setNames(
  replicate(1000L, sample.int(30L, 1000L, replace = TRUE), simplify = FALSE),
  paste0("x", seq_len(1000L))
))
cross <- data.frame(
  a = rep(seq_len(2000L), 5L),
  b = rep(letters[1:5], each = 2000L)
)
jobs <- c(
  jobs,
  list(
    summ_unique_large = function() {
      summ(large_numeric, x1, x2, .stat = "unique")
    },
    summ_unique_many_groups = function() {
      summ(many_groups, x1, .by = g, .stat = "unique")
    },
    codebook_small = function() codebook(small_numeric),
    codebook_large = function() codebook(large_numeric),
    codebook_wide = function() codebook(wide_codebook),
    type_wide = function() lapply(wide_codebook, s_type),
    unit_wide = function() lapply(wide_codebook, s_unit),
    fre2_cross_large = function() xtab(cross, a, b, .total = TRUE)
  )
)
if (requireNamespace("flextable", quietly = TRUE)) {
  jobs$fre_rich <- function() fre(small, company, .type = "flextable")
}
large_numeric$w <- rep(c(0, 0.5, 1, 3), length.out = nrow(large_numeric))
many_groups$w <- rep(c(0, 0.5, 1, 3), length.out = nrow(many_groups))
wide_numeric$day <- as.Date("2024-01-01") + seq_len(nrow(wide_numeric))
wide_numeric$time <- as.POSIXct("2024-01-01", tz = "UTC") +
  seq_len(nrow(wide_numeric))
jobs <- c(
  jobs,
  list(
    tab1_wide = function() tab1(wide_numeric, x1:x10, .by = g),
    fre_many_groups = function() {
      fre(many_groups, category, .by = g, .group_order = "frequency")
    },
    tab_weighted = function() tab(large_numeric, category, .by = g, .wt = w),
    xtab_weighted = function() {
      xtab(large_numeric, category, g, .wt = w, .total = TRUE)
    },
    summ_weighted_mean = function() {
      summ(large_numeric, x1, x2, .by = g, .wt = w, .stat = "mean")
    },
    summ_weighted_count = function() {
      summ(large_numeric, x1, x2, .by = g, .wt = w, .stat = "n")
    },
    summ_weighted_detail = function() {
      summ(many_groups, x1, .by = g, .wt = w, .detail = TRUE)
    },
    summ_mixed = function() summ(wide_numeric, x1, day, time, .by = g)
  )
)
# Capture value, visibility and ordered diagnostics independently of timings.
records <- lapply(jobs, function(job) {
  diagnostics <- character()
  result <- withCallingHandlers(
    withVisible(job()),
    warning = function(c) {
      diagnostics <<- c(diagnostics, paste0("warning: ", conditionMessage(c)))
      invokeRestart("muffleWarning")
    },
    message = function(c) {
      diagnostics <<- c(diagnostics, paste0("message: ", conditionMessage(c)))
      invokeRestart("muffleMessage")
    }
  )
  list(result = result, diagnostics = diagnostics)
})
# Flextable embeds generated ids; existing rich-output tests cover its contract.
records$fre_rich <- NULL
saveRDS(records, paste0(prefix, "-outputs.rds"))
exports <- getNamespaceExports("tidystata")
saveRDS(
  lapply(stats::setNames(exports, exports), function(name) {
    object <- getExportedValue("tidystata", name)
    if (is.function(object)) formals(object) else class(object)
  }),
  paste0(prefix, "-interfaces.rds")
)
writeLines(capture.output(sessionInfo()), paste0(prefix, "-session.txt"))
results <- lapply(names(jobs), function(name) {
  job <- jobs[[name]]
  warmup_start <- proc.time()[["elapsed"]]
  invisible(job())
  warmup_elapsed <- proc.time()[["elapsed"]] - warmup_start
  # Time roughly 100 ms per batch, including calls below clock resolution.
  batch_size <- min(100L, max(1L, ceiling(0.1 / max(warmup_elapsed, 0.001))))
  elapsed <- replicate(7L, {
    start <- proc.time()[["elapsed"]]
    for (i in seq_len(batch_size)) {
      invisible(job())
    }
    (proc.time()[["elapsed"]] - start) / batch_size
  })
  # Allocation profiling includes preparation and output construction.
  allocated <- NA_real_
  if (isTRUE(capabilities("profmem"))) {
    profile <- tempfile("tidystata-allocation-")
    utils::Rprofmem(profile)
    invisible(job())
    utils::Rprofmem(NULL)
    records <- readLines(profile, warn = FALSE)
    sizes <- suppressWarnings(as.numeric(sub(" .*", "", records)))
    allocated <- sum(sizes, na.rm = TRUE)
  }
  cat(name, "median seconds:", stats::median(elapsed), "\n")
  data.frame(
    job = name,
    allocated_bytes = allocated,
    median_seconds = stats::median(elapsed),
    min_seconds = min(elapsed),
    max_seconds = max(elapsed),
    repetitions = 7L,
    batch_size = batch_size
  )
})
out <- do.call(rbind, results)
print(out, row.names = FALSE)
utils::write.csv(out, paste0(prefix, "-timings.csv"), row.names = FALSE)
# This measurement is diagnostic, not a timing-dependent pass/fail assertion.
counter <- new.env(parent = emptyenv())
counter$n <- 0L
assign(".problems2_quantile_counter", counter, envir = .GlobalEnv)
trace(
  "quantile",
  where = asNamespace("stats"),
  print = FALSE,
  tracer = quote({
    .problems2_counter <- get(".problems2_quantile_counter", envir = .GlobalEnv)
    .problems2_counter$n <- .problems2_counter$n + 1L
  })
)
invisible(summ(seq_len(100), .stat = "mean"))
untrace("quantile", where = asNamespace("stats"))
cat("Mean-only quantile calls:", counter$n, "\n")
writeLines(as.character(counter$n), paste0(prefix, "-quantile-calls.txt"))
