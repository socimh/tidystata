# Time the core function families on fixed inputs, optionally beside reference
# implementations from other packages. References are diagnostic only; they are
# not dependencies and need not match statart's missing-value or class rules.
# Usage: Rscript benchmark_core.R <library> <prefix> [--references] [--profile]
#   [--filter=regex]
args <- commandArgs(trailingOnly = TRUE)
stopifnot(length(args) >= 2L)
library(statart, lib.loc = args[[1L]])
prefix <- args[[2L]]
references <- "--references" %in% args
filter <- sub("^--filter=", "", grep("^--filter=", args, value = TRUE))
dir.create(dirname(prefix), recursive = TRUE, showWarnings = FALSE)
reference_available <- function(package) {
  references && requireNamespace(package, quietly = TRUE)
}

set.seed(20261019)
with_missing <- function(x, every) {
  x[seq.int(1L, length(x), by = every)] <- NA
  x
}
n <- 1000000L
long <- data.frame(
  g10 = rep(seq_len(10L), length.out = n),
  g10k = rep(seq_len(10000L), length.out = n),
  w = rep(c(0, 0.5, 1, 3), length.out = n)
)
for (j in seq_len(5L)) {
  long[[paste0("x", j)]] <- with_missing(stats::rnorm(n), 20L + j)
}
long$cat <- sample(c(letters[1:10], NA), n, replace = TRUE)
long_x <- long[paste0("x", 1:5)]
long_int <- as.data.frame(lapply(1:5, function(j) {
  with_missing(sample.int(4L, n, replace = TRUE), 30L + j)
}))
wide <- as.data.frame(stats::setNames(
  lapply(seq_len(50L), function(j) with_missing(stats::rnorm(100000L), 40L + j)),
  paste0("v", seq_len(50L))
))
# Balanced panel: 10,000 ids observed over 100 years, rows unsorted.
panel <- data.frame(
  id = rep(seq_len(10000L), each = 100L),
  year = rep(1921L:2020L, times = 10000L)
)
panel$x <- stats::rnorm(nrow(panel))
panel <- panel[sample.int(nrow(panel)), ]
rownames(panel) <- NULL
duplicated_rows <- rbind(panel[1:900000, ], panel[1:100000, ])
codes <- long$x1
codes[seq.int(5L, n, by = 50L)] <- -99
codes[seq.int(7L, n, by = 50L)] <- -98
numbers_text <- format(round(long$x2, 4), trim = TRUE)
dummy_small <- data.frame(cat = sample(c(letters[1:10], NA), 100000L, TRUE))
dummy_wide <- data.frame(
  cat = sample(c(sprintf("c%03d", 1:500), NA), 20000L, TRUE)
)
correlations <- wide[1:20]
using <- data.frame(g10k = seq_len(10000L), z = stats::rnorm(10000L))

jobs <- list()
add <- function(name, family, statart, ...) {
  jobs[[name]] <<- list(
    family = family,
    statart = statart,
    references = Filter(Negate(is.null), list(...))
  )
}
ref <- function(package, fn) if (reference_available(package)) fn

# Row calculations: long (1e6 x 5) and wide (1e5 x 50) inputs.
for (shape in c("long", "wide")) {
  data <- if (shape == "long") long_x else wide
  local({
    data <- data
    add(
      paste0("row_sum_", shape), "row", function() row_sum(data),
      base = function() rowSums(as.matrix(data), na.rm = TRUE),
      Rfast = ref("Rfast", function() Rfast::rowsums(as.matrix(data)))
    )
    add(
      paste0("row_mean_", shape), "row", function() row_mean(data),
      matrixStats = ref("matrixStats", function() {
        matrixStats::rowMeans2(as.matrix(data), na.rm = TRUE)
      }),
      Rfast = ref("Rfast", function() Rfast::rowmeans(as.matrix(data)))
    )
    add(
      paste0("row_max_", shape), "row", function() row_max(data),
      matrixStats = ref("matrixStats", function() {
        matrixStats::rowMaxs(as.matrix(data), na.rm = TRUE)
      }),
      Rfast = ref("Rfast", function() {
        Rfast::rowMaxs(as.matrix(data), value = TRUE)
      })
    )
    add(
      paste0("row_min_", shape), "row", function() row_min(data),
      matrixStats = ref("matrixStats", function() {
        matrixStats::rowMins(as.matrix(data), na.rm = TRUE)
      })
    )
    add(
      paste0("row_median_", shape), "row", function() row_median(data),
      matrixStats = ref("matrixStats", function() {
        matrixStats::rowMedians(as.matrix(data), na.rm = TRUE)
      }),
      Rfast = ref("Rfast", function() Rfast::rowMedians(as.matrix(data)))
    )
    add(
      paste0("row_sd_", shape), "row", function() row_sd(data),
      matrixStats = ref("matrixStats", function() {
        matrixStats::rowSds(as.matrix(data), na.rm = TRUE)
      }),
      Rfast = ref("Rfast", function() {
        Rfast::rowVars(as.matrix(data), std = TRUE)
      })
    )
    add(
      paste0("row_var_", shape), "row", function() row_var(data),
      matrixStats = ref("matrixStats", function() {
        matrixStats::rowVars(as.matrix(data), na.rm = TRUE)
      })
    )
    add(
      paste0("row_unique_", shape), "row", function() row_unique(data)
    )
    add(
      paste0("row_miss_", shape), "row", function() row_miss(data),
      base = function() rowSums(is.na(data))
    )
  })
}
add("row_unique_int", "row", function() row_unique(long_int))
add("row_nvals_int", "row", function() row_nvals(long_int))
add("row_nvals_dbl", "row", function() row_nvals(long[paste0("x", 1:5)]))
add(
  "row_mean_mutate", "row",
  function() dplyr::mutate(long_x, m = row_mean(x1, x2, x3, x4, x5)),
  base = function() {
    dplyr::mutate(long_x, m = rowMeans(cbind(x1, x2, x3, x4, x5), na.rm = TRUE))
  }
)

# Keys, duplicates and first-row flags on the unsorted panel.
add(
  "isid_panel", "keys", function() isid(panel, id, year),
  data.table = ref("data.table", function() {
    anyDuplicated(data.table::as.data.table(panel), by = c("id", "year")) == 0L
  })
)
add(
  "duplicates_report", "keys", function() duplicates_report(duplicated_rows),
  data.table = ref("data.table", function() {
    data.table::as.data.table(duplicated_rows)[, .N, by = names(duplicated_rows)][
      , .N, by = "N"
    ]
  })
)
add(
  "duplicates_report_id", "keys", function() duplicates_report(panel, id),
  base = function() table(tabulate(panel$id))
)
add(
  "duplicates_tag", "keys", function() duplicates_tag(duplicated_rows),
  collapse = ref("collapse", function() {
    collapse::GRPN(duplicated_rows, expand = TRUE) - 1L
  })
)
add(
  "duplicates_drop", "keys", function() duplicates_drop(duplicated_rows),
  base = function() duplicated_rows[!duplicated(duplicated_rows), ]
)
add(
  "is_first_id", "keys", function() is_first(panel$id),
  base = function() !duplicated(panel$id)
)
add(
  "is_first_two", "keys", function() is_first(panel$id, panel$year),
  collapse = ref("collapse", function() {
    !collapse::fduplicated(list(panel$id, panel$year))
  })
)
add(
  "assert_rows", "keys",
  function() assert(long, x1 > -10 | is.na(x1), g10 >= 1),
  base = function() stopifnot(all(long$x1 > -10 | is.na(long$x1)), all(long$g10 >= 1))
)
add(
  "s_merge_m1", "keys",
  function() s_merge(long, using, "m:1", by = "g10k", .report = FALSE),
  dplyr = function() {
    dplyr::left_join(long, using, by = "g10k", relationship = "many-to-one")
  }
)

# Panel operators.
# A fixed permutation (7919 is prime to n), leaving the random stream unchanged.
shuffled_time <- (seq_len(n) * 7919) %% n + 1
add(
  "s_lag_single", "panel",
  function() s_lag(long$x1, time = seq_len(n)),
  data.table = ref("data.table", function() data.table::shift(long$x1))
)
add(
  "s_lag_unsorted", "panel",
  function() s_lag(long$x1, time = shuffled_time),
  collapse = ref("collapse", function() collapse::flag(long$x1, 1L, t = shuffled_time))
)
add(
  "s_diff_two", "panel",
  function() s_diff(long$x1, 2L, time = seq_len(n)),
  collapse = ref("collapse", function() collapse::fdiff(long$x1, 1L, 2L, t = seq_len(n)))
)
add(
  "s_lag_grouped", "panel",
  function() dplyr::mutate(panel, l = s_lag(x, time = year), .by = id),
  collapse = ref("collapse", function() {
    collapse::flag(panel$x, 1L, g = panel$id, t = panel$year)
  })
)
add(
  "s_diff_grouped", "panel",
  function() dplyr::mutate(panel, d = s_diff(x, time = year), .by = id),
  collapse = ref("collapse", function() {
    collapse::fdiff(panel$x, 1L, g = panel$id, t = panel$year)
  })
)

# Binning and egen-style transforms.
add(
  "xtile_10", "transform", function() xtile(long$x1, 10),
  base = function() {
    findInterval(
      long$x1,
      stats::quantile(long$x1, 1:9 / 10, na.rm = TRUE, names = FALSE),
      left.open = TRUE
    ) + 1L
  }
)
add("xtile_10_weighted", "transform", function() xtile(long$x1, 10, wt = long$w))
add(
  "xtile_grouped", "transform",
  function() dplyr::mutate(long, q = xtile(x1, 4), .by = g10k)
)
add(
  "std_grouped", "transform",
  function() dplyr::mutate(long, s = std(x1), .by = g10k),
  collapse = ref("collapse", function() collapse::fscale(long$x1, g = long$g10k))
)
add(
  "pc_grouped", "transform",
  function() dplyr::mutate(long, p = pc(x1), .by = g10k),
  collapse = ref("collapse", function() {
    100 * collapse::fsum(long$x1, g = long$g10k, TRA = "/")
  })
)
add("std_single", "transform", function() std(long$x1))
add(
  "as_dummy_10", "transform", function() as_dummy(dummy_small, cat),
  base = function() stats::model.matrix(~ cat - 1, dummy_small)
)
add(
  "as_dummy_500", "transform", function() as_dummy(dummy_wide, cat),
  base = function() stats::model.matrix(~ cat - 1, dummy_wide)
)

# Conversions.
add(
  "mvdecode_two", "conversion", function() mvdecode(codes, c(-98, -99)),
  base = function() replace(codes, codes %in% c(-98, -99), NA)
)
add(
  "mvencode", "conversion", function() mvencode(long$x1, -99),
  base = function() replace(long$x1, is.na(long$x1), -99)
)
add(
  "destring", "conversion", function() destring(numbers_text),
  base = function() as.numeric(numbers_text)
)
add(
  "tostring", "conversion", function() tostring(long$x2),
  base = function() as.character(long$x2)
)

# Summaries, correlations and missingness.
add(
  "summ_detail_10k", "summary",
  function() summ(long, x1, .by = g10k, .detail = TRUE),
  data.table = ref("data.table", function() {
    data.table::as.data.table(long)[
      , as.list(stats::quantile(
        x1, c(.01, .05, .1, .25, .5, .75, .9, .95, .99),
        na.rm = TRUE, names = FALSE
      )),
      by = "g10k"
    ]
  })
)
add("summ_detail_10", "summary", function() summ(long, x1, .by = g10, .detail = TRUE))
add("summ_detail_one", "summary", function() summ(long, x1, .detail = TRUE))
add(
  "summ_default_10k", "summary",
  function() summ(long, x1, x2, .by = g10k),
  collapse = ref("collapse", function() {
    collapse::fsummarise(
      collapse::fgroup_by(long, g10k),
      dplyr::across(c(x1, x2), list(n = collapse::fnobs, mean = collapse::fmean,
        sd = collapse::fsd, min = collapse::fmin, max = collapse::fmax))
    )
  })
)
add(
  "summ_weighted_detail_10k", "summary",
  function() summ(long, x1, .by = g10k, .wt = w, .detail = TRUE)
)
add(
  "tab_weighted_10k", "summary",
  function() tab(long, cat, .by = g10k, .wt = w),
  data.table = ref("data.table", function() {
    data.table::as.data.table(long)[, list(n = sum(w)), by = c("g10k", "cat")]
  })
)
add(
  "tab2_weighted_10k", "summary",
  function() tab2(long, g10k, cat, .wt = w),
  data.table = ref("data.table", function() {
    data.table::dcast(
      data.table::as.data.table(long), g10k ~ cat,
      value.var = "w", fun.aggregate = sum
    )
  })
)
add(
  "tab_10k", "summary", function() tab(long, cat, .by = g10k),
  data.table = ref("data.table", function() {
    data.table::as.data.table(long)[, .N, by = c("g10k", "cat")]
  })
)
add(
  "pwcorr_20", "summary", function() pwcorr(correlations),
  base = function() stats::cor(correlations, use = "pairwise.complete.obs")
)
add(
  "misstable_50", "summary", function() misstable(wide),
  base = function() colSums(is.na(wide))
)
add("misstable_patterns", "summary", function() misstable(wide[1:10], .patterns = TRUE))
add(
  "codebook_long", "summary", function() codebook(long)
)

if (length(filter)) {
  jobs <- jobs[grepl(filter, names(jobs))]
}

quiet <- function(job) {
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
}

# With --profile, report where each selected statart job spends its time.
if ("--profile" %in% args) {
  for (name in names(jobs)) {
    profile <- tempfile("statart-profile-")
    utils::Rprof(profile, interval = 0.005)
    for (i in 1:3) invisible(quiet(jobs[[name]]$statart))
    utils::Rprof(NULL)
    summary <- utils::summaryRprof(profile)
    cat("\n==", name, "(", summary$sampling.time / 3, "s per call )\n")
    print(utils::head(summary$by.total[, c("total.pct", "self.pct")], 14L))
    print(utils::head(summary$by.self[, c("self.pct"), drop = FALSE], 6L))
  }
  quit(save = "no")
}

# Hashes of value, visibility and diagnostics compare installations exactly
# without storing every large result.
records <- lapply(jobs, function(job) rlang::hash(quiet(job$statart)))
saveRDS(records, paste0(prefix, "-hashes.rds"))

time_job <- function(job) {
  invisible(quiet(job))
  warmup_start <- proc.time()[["elapsed"]]
  invisible(quiet(job))
  warmup_elapsed <- proc.time()[["elapsed"]] - warmup_start
  # Time roughly 100 ms per batch, including calls below clock resolution.
  batch_size <- min(100L, max(1L, ceiling(0.1 / max(warmup_elapsed, 0.001))))
  elapsed <- replicate(7L, {
    start <- proc.time()[["elapsed"]]
    for (i in seq_len(batch_size)) {
      invisible(quiet(job))
    }
    (proc.time()[["elapsed"]] - start) / batch_size
  })
  allocated <- NA_real_
  if (isTRUE(capabilities("profmem"))) {
    profile <- tempfile("statart-allocation-")
    utils::Rprofmem(profile)
    invisible(quiet(job))
    utils::Rprofmem(NULL)
    sizes <- suppressWarnings(as.numeric(sub(" .*", "", readLines(profile, warn = FALSE))))
    allocated <- sum(sizes, na.rm = TRUE)
  }
  c(
    median_seconds = stats::median(elapsed),
    min_seconds = min(elapsed),
    max_seconds = max(elapsed),
    batch_size = batch_size,
    allocated_bytes = allocated
  )
}

rows <- list()
for (name in names(jobs)) {
  job <- jobs[[name]]
  implementations <- c(list(statart = job$statart), job$references)
  for (impl in names(implementations)) {
    timing <- tryCatch(time_job(implementations[[impl]]), error = function(e) {
      cat("  ", name, impl, "failed:", conditionMessage(e), "\n")
      NULL
    })
    if (is.null(timing)) next
    cat(sprintf("%-26s %-12s %10.2f ms\n", name, impl, 1000 * timing[["median_seconds"]]))
    rows[[length(rows) + 1L]] <- data.frame(
      job = name,
      family = job$family,
      implementation = impl,
      t(timing)
    )
  }
}
out <- do.call(rbind, rows)
utils::write.csv(out, paste0(prefix, "-timings.csv"), row.names = FALSE)
writeLines(capture.output(sessionInfo()), paste0(prefix, "-session.txt"))
