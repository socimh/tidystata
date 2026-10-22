test_that("weighted requests do not evaluate unrequested quantiles", {
  testthat::local_mocked_bindings(
    weighted_quantile = function(...) stop("Unrequested weighted quantile"),
    .package = "tidystata"
  )
  data <- data.frame(g = c(2, 1, 2, 1), x = c(1, 3, 5, NA), w = c(1, 2, 3, 4))
  expect_equal(summ(data, x, .wt = w, .stat = "mean")$mean, 22 / 6)
  expect_equal(summ(data, x, .wt = w, .stat = "n")$n, 6)
  expect_equal(tabstat(data, x, .by = g, .wt = w)$mean, c(3, 4))
})

test_that("weighted type-only summaries retain one row per variable and group", {
  data <- data.frame(g = c(2, 1, 2), x = 1:3, w = c(1, 0, 2))
  expect_identical(summ(data, x, .wt = w, .stat = "type")$type, "int")
  expect_identical(
    summ(data, x, .by = g, .wt = w, .stat = "type")$type,
    c("int", "int")
  )
})

test_that("frequency cumulative values are isolated within groups", {
  data <- data.frame(
    g = rep(1:3, each = 3),
    x = rep(c(1, 2, NA), 3),
    w = c(0, 0, 0, 1e16, 1, 2, 1, 2, 1)
  )
  out <- tab(data, x, .by = g, .wt = w)
  expect_true(all(is.nan(out$cum[1:3])))
  expect_equal(out$cum[7:9], c(25, 75, 100))
  expect_equal(out$valid_cum[7:8], c(100 / 3, 100))
  expect_true(is.na(out$valid_cum[[9]]))
})

test_that("cross tabulation fills native counts and preserves identity", {
  data <- data.frame(
    a = c("z", "a", "z", "a"),
    b = factor(c("b", "c", "b", "b"), levels = c("c", "b")),
    w = c(0.5, 2, 1, 3)
  )
  out <- xtab(data, a, b, .wt = w)
  expect_named(out, c("a \\ b", "c", "b"))
  expect_identical(out[[1]], c("a", "z"))
  expect_equal(out$c, c(2, 0))
  expect_equal(out$b, c(3, 1.5))
  expect_type(xtab(data, a, b)$b, "integer")
})

test_that("weighted counts skip numeric conversion and preserve row counts", {
  testthat::local_mocked_bindings(
    as_numeric = function(...) stop("Unrequested numeric conversion"),
    .package = "tidystata"
  )
  data <- data.frame(
    g = c(1, 1, 2, 2),
    x = c(5, NA, 5, 6),
    w = c(0, 3, 0.5, 1.5)
  )
  stats <- c("n", "unique", "miss_n", "valid_pct")
  out <- summ(data, x, .by = g, .wt = w, .stat = stats)
  expect_equal(out$n, c(0, 2))
  expect_identical(out$unique, c(1L, 2L))
  expect_identical(out$miss_n, c(1L, 0L))
  expect_equal(out$valid_pct, c(0.5, 1))
})

test_that("prepared weights stay aligned after missing-key and weight filtering", {
  data <- data.frame(
    g = c(NA, 2, 1, 2, 1),
    x = c(100, 4, 8, 10, 12),
    w = c(99, NA, 0.5, 1.5, 2)
  )
  before <- data
  expect_message(
    out <- summ(
      data,
      x,
      .by = g,
      .missing = FALSE,
      .wt = 2 * w,
      .stat = c("n", "mean")
    ),
    "Excluded 1 row"
  )
  expect_equal(out$n, c(5, 3))
  expect_equal(out$mean, c(11.2, 10))
  expect_message(counts <- tab(data, x, .by = g, .wt = w), "Excluded 1 row")
  expect_equal(counts$n, c(0.5, 2, 1.5, 99))
  expect_identical(data, before)
})

test_that("shared summary groups retain calendar and nonnumeric families", {
  data <- tibble::tibble(
    g = c(2, 1, 2),
    x = c(1, 3, 5),
    day = as.Date("2024-01-01") + c(0, 2, 4),
    text = c("a", "b", "a"),
    w = c(1, 2, 3)
  )
  before <- data
  expect_warning(
    out <- suppressMessages(summ(
      data,
      x,
      day,
      text,
      .keep_all = TRUE,
      .by = g,
      .wt = w,
      .stat = c("mean", "unique")
    )),
    "non-numeric"
  )
  expect_equal(out$numeric$mean, c(3, NA, 4, NA))
  expect_identical(out$numeric$unique, c(1L, 1L, 2L, 1L))
  expect_identical(out$date$mean, c("2024-01-03", "2024-01-04"))
  expect_identical(data, before)
})

test_that("excluded custom columns do not evaluate missingness methods", {
  registry <- get(".__S3MethodsTable__.", envir = asNamespace("base"))
  registerS3method(
    "is.na",
    "tidystata_aggregation_opaque",
    function(x) stop("Excluded missingness evaluated"),
    envir = asNamespace("base")
  )
  withr::defer(rm("is.na.tidystata_aggregation_opaque", envir = registry))
  data <- tibble::tibble(
    x = 1:3,
    opaque = structure(letters[1:3], class = "tidystata_aggregation_opaque")
  )
  expect_warning(
    out <- summ(data, .stat = "mean"),
    "opaque is non-numeric and thus removed"
  )
  expect_equal(out$mean, 2)
})

test_that("analytic frequency grouping matches separately scaled groups", {
  data <- data.frame(
    g = c(2, NA, NaN, 2, NA, NaN),
    x = c("a", "b", "a", "b", "a", "b"),
    w = c(0, 0.5, 0, 1.5, 2, 0)
  )
  grouped <- tab(data, x, .by = g, .wt = w, .wt_type = "analytic", .desc = TRUE)
  for (loc in list(c(1L, 4L), c(2L, 5L), c(3L, 6L))) {
    key <- data$g[loc[[1]]]
    rows <- if (is.nan(key)) {
      is.nan(grouped$g)
    } else if (is.na(key)) {
      is.na(grouped$g) & !is.nan(grouped$g)
    } else {
      !is.na(grouped$g) & grouped$g == key
    }
    expected <- tab(
      data[loc, ],
      x,
      .wt = w,
      .wt_type = "analytic",
      .desc = TRUE
    )
    expect_equal(as.list(grouped[rows, names(expected)]), as.list(expected))
  }
})

test_that("weighted percentile preparation preserves ties and zero weights", {
  data <- data.frame(x = c(1, 3, 9, 1000, NA), w = c(0.5, 0.5, 1, 0, 4))
  out <- summ(
    data,
    x,
    .wt = w,
    .stat = c("n", "unique", "q1", "median", "q3", "mad", "p0", "p100")
  )
  expect_equal(out$n, 2)
  expect_identical(out$unique, 4L)
  expect_equal(
    unlist(out[c("q1", "median", "q3")], use.names = FALSE),
    c(2, 6, 9)
  )
  expect_equal(out$mad, 1.4826 * 3)
  expect_equal(out$p0, 1)
  expect_equal(out$p100, 9)
  analytic <- summ(
    data,
    x,
    .wt = w,
    .wt_type = "analytic",
    .stat = c("n", "q1", "median", "q3")
  )
  expect_equal(analytic$n, 4)
  expect_equal(analytic[c("q1", "median", "q3")], out[c("q1", "median", "q3")])
})

test_that("weighted empty and missing inputs retain their established shape", {
  data <- data.frame(g = integer(), x = double(), w = double())
  out <- summ(data, x, .by = g, .wt = w, .stat = c("n", "mean", "median"))
  expect_equal(nrow(out), 0L)
  expect_type(out$n, "double")
  expect_equal(nrow(xtab(data, g, x, .wt = w)), 0L)
  missing <- data.frame(x = c(NA_real_, NA_real_), w = c(0, 2))
  expect_warning(
    out <- summ(missing, x, .wt = w, .stat = c("n", "mean", "sd", "median")),
    "entirely missing"
  )
  expect_equal(out$n, 0)
  expect_true(all(is.na(unlist(out[c("mean", "sd", "median")]))))
})

test_that("matrix column headers retain the pivot boundary diagnostic", {
  data <- tibble::tibble(a = 1:3, b = matrix(1:6, 3))
  expect_error(xtab(data, a, b), "Can't recycle")
})

test_that("native group sums follow sum() and cumsum() for missing values", {
  x <- c(1, NA, 2, 1, NaN, NA, 0 / 0, 1, 1e16, 1, -1e16)
  locs <- list(1:3, 4:6, 7:8, 9:11, integer())
  actual <- group_sum_dbl(x, locs)
  expected <- vapply(locs, function(loc) sum(x[loc]), numeric(1))
  # R permits either missing payload when arithmetic combines NA and NaN;
  # instrumentation/compiler choices can change which wins (see ?is.finite).
  mixed <- vapply(
    locs,
    function(loc) {
      values <- x[loc]
      any(is.na(values) & !is.nan(values)) && any(is.nan(values))
    },
    logical(1)
  )
  expect_identical(actual[!mixed], expected[!mixed])
  expect_true(all(is.na(actual[mixed])))
  cumulative <- rep(NA_real_, length(x))
  for (loc in locs) {
    cumulative[loc] <- cumsum(x[loc])
  }
  # Base cumsum() also changed which of NA or NaN wins between R versions.
  running <- group_cumsum_dbl(x, locs)
  mixed_rows <- unlist(locs[mixed])
  expect_identical(running[-mixed_rows], cumulative[-mixed_rows])
  expect_identical(is.na(running[mixed_rows]), is.na(cumulative[mixed_rows]))
  expect_identical(
    running[mixed_rows][!is.na(running[mixed_rows])],
    cumulative[mixed_rows][!is.na(cumulative[mixed_rows])]
  )
  expect_identical(
    group_mean_dbl(c(1e308, 1e308, 0.1, 0.2, Inf, -Inf), list(1:2, 3:4, 5:6)),
    c(mean(c(1e308, 1e308)), mean(c(0.1, 0.2)), NaN)
  )
})

test_that("zero-weight groups keep undefined percentages", {
  data <- tibble::tibble(
    g = c(1, 1, 2, 2, 2),
    x = c("a", NA, "a", "b", NA),
    w = c(0, 0, 1, 2, 1)
  )
  out <- tab(data, x, .by = g, .wt = w)
  expect_true(all(is.nan(out$percent[out$g == 1])))
  expect_identical(out$valid[out$g == 1], c(NA_real_, NA_real_))
  expect_identical(out$cum[out$g == 2], c(25, 75, 100))
})

test_that("many small groups summarise like per-group base statistics", {
  withr::local_seed(20261020)
  data <- tibble::tibble(
    g = rep(1:30, length.out = 300),
    x = round(rnorm(300), 1)
  )
  data$x[data$g == 1] <- NA
  data$x[data$g == 2] <- c(Inf, rep(NA, 9))
  data$x[data$g == 3] <- c(1e308, 1e308, 2, 3, rep(NA, 6))
  out <- summ(
    data,
    x,
    .by = g,
    .stat = c("median", "mad", "q1", "p37", "mean", "sum", "skew", "unique")
  )
  per_group <- function(fn) {
    vapply(
      split(data$x, data$g),
      function(x) {
        x <- x[!is.na(x)]
        if (length(x)) fn(x) else NA_real_
      },
      numeric(1),
      USE.NAMES = FALSE
    )
  }
  expect_identical(out$median, per_group(median))
  expect_identical(out$mad, per_group(mad))
  expect_identical(
    out$q1,
    per_group(function(x) quantile(x, 0.25, names = FALSE))
  )
  expect_identical(
    out$p37,
    per_group(function(x) quantile(x, 0.37, names = FALSE))
  )
  expect_identical(out$mean, per_group(mean))
  expect_identical(out$sum, per_group(sum))
  expect_identical(
    out$unique,
    vapply(
      split(data$x, data$g),
      function(x) {
        length(unique(x[!is.na(x)]))
      },
      integer(1),
      USE.NAMES = FALSE
    )
  )
})

test_that("native group extrema and variances follow min(), max() and sd()", {
  segments <- list(
    c(3, -0, 0, 1),
    c(0, -0),
    c(2, NaN, 1),
    c(NaN, NA, 5),
    c(Inf, -Inf),
    7,
    numeric(),
    c(1e308, 1e308, -1e308),
    c(1e16, 1e16 + 2, 1e16 + 4)
  )
  values <- unlist(segments)
  sizes <- lengths(segments)
  base <- function(fn) {
    vapply(
      segments,
      function(x) if (length(x)) fn(x) else NA_real_,
      numeric(1)
    )
  }
  expect_identical(group_min_dbl(values, sizes), base(min))
  expect_identical(group_max_dbl(values, sizes), base(max))
  expect_identical(sqrt(group_var_dbl(values, sizes)), base(stats::sd))
  expect_error(group_var_dbl(values, sizes[-1]), "add up")
})

test_that("native weighted percentiles follow Stata's weighted rule", {
  segments <- list(
    list(x = c(1, 2, 3, 4), w = c(1, 1, 1, 1)),
    list(x = c(-0, 0, 0, 5), w = c(0, 2, 2, 0)),
    list(x = c(1, 1, 2, 9), w = c(0.1, 0.2, 0.3, 0.4)),
    list(x = c(4, 5), w = c(0, 0)),
    list(x = numeric(), w = numeric())
  )
  probs <- c(0, 0.1, 0.25, 0.5, 0.75, 1)
  out <- group_weighted_quantile_dbl(
    unlist(lapply(segments, `[[`, "x")),
    unlist(lapply(segments, `[[`, "w")),
    vapply(segments, function(s) length(s$x), integer(1)),
    probs
  )
  expected <- t(vapply(
    segments,
    function(s) weighted_quantile(s$x, s$w, probs),
    numeric(length(probs))
  ))
  expect_identical(matrix(out, nrow = length(segments)), expected)
})

test_that("weighted summaries of many groups equal one group at a time", {
  withr::local_seed(20261020)
  data <- tibble::tibble(
    g = rep(1:40, length.out = 400),
    x = round(rnorm(400) * 3),
    w = sample(c(0, 0.5, 1, 2), 400, replace = TRUE)
  )
  data$x[data$g == 1] <- NA
  data$w[data$g == 2] <- 0
  data$x[data$g == 3] <- c(Inf, 1, rep(NA, 8))
  stats <- c(
    "n",
    "unique",
    "miss_n",
    "valid_pct",
    "min",
    "p10",
    "q1",
    "median",
    "mean",
    "q3",
    "max",
    "sd",
    "mad",
    "iqr",
    "se",
    "skew",
    "kurtosis",
    "sum"
  )
  for (type in c("frequency", "analytic")) {
    many <- summ(data, x, .by = g, .wt = w, .wt_type = type, .stat = stats)
    one <- dplyr::bind_rows(lapply(split(data, data$g), function(group) {
      if (all(is.na(group$x))) {
        expect_warning(
          out <- summ(group, x, .wt = w, .wt_type = type, .stat = stats),
          "entirely missing"
        )
        return(out)
      }
      summ(group, x, .wt = w, .wt_type = type, .stat = stats)
    }))
    expect_identical(as.list(many[stats]), as.list(one[stats]))
  }
})


test_that("summary statistics agree across the observed group-size boundary", {
  statistics <- c(
    "n",
    "q1",
    "p37",
    "median",
    "mad",
    "mean",
    "sd",
    "skew",
    "kurtosis"
  )
  for (size in c(999L, 1000L, 1001L)) {
    # Missing rows do not count toward the average observed-size threshold.
    values <- ((seq_len(size) * 17) %% 101)^2 / 13
    data <- data.frame(
      g = rep(c("a", "b"), each = size + 2L),
      x = c(values, NA, NaN, -values / 7 + 3, NA, NaN)
    )
    out <- summ(data, x, .by = g, .stat = statistics)
    expect_identical(out$n, rep(size, 2))
    reference <- lapply(split(data$x, data$g), function(x) {
      x <- x[!is.na(x)]
      center <- mean(x)
      spread <- stats::sd(x)
      c(
        q1 = stats::quantile(x, 0.25, names = FALSE),
        p37 = stats::quantile(x, 0.37, names = FALSE),
        median = stats::median(x),
        mad = stats::mad(x),
        mean = center,
        sd = spread,
        skew = mean((x - center)^3) / spread^3,
        kurtosis = mean((x - center)^4) / spread^4 - 3
      )
    })
    for (statistic in setdiff(statistics, "n")) {
      expected <- vapply(reference, `[[`, numeric(1), statistic)
      expect_equal(
        out[[statistic]],
        unname(expected),
        info = paste(size, statistic)
      )
    }
  }
})
