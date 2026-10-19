# Compare installed packages using identical fixed inputs and visible timings.
args <- commandArgs(trailingOnly = TRUE)
stopifnot(length(args) == 2L)
library(statart, lib.loc = args[[1L]])
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
if (requireNamespace("flextable", quietly = TRUE)) {
  jobs$fre_rich <- function() fre(small, company, .type = "flextable")
}
results <- lapply(names(jobs), function(name) {
  job <- jobs[[name]]
  invisible(job())
  elapsed <- replicate(7L, {
    start <- proc.time()[["elapsed"]]
    for (i in seq_len(3L)) {
      invisible(job())
    }
    (proc.time()[["elapsed"]] - start) / 3
  })
  data.frame(
    job = name,
    median_seconds = stats::median(elapsed),
    min_seconds = min(elapsed),
    max_seconds = max(elapsed),
    repetitions = 7L,
    batch_size = 3L
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
