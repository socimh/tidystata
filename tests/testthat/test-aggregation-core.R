test_that("native tabulation counts compact integer keys in row order", {
  values <- c(2L, 1L, 2L, 1L, 3L, 2L)
  other <- c(1L, 2L, 1L, 2L, 1L, 1L)
  range <- tab_integer_range(values)
  expect_identical(range, c(1L, 3L, 0L))
  other_range <- tab_integer_range(other)
  out <- tab_count_dense(
    values,
    range,
    other,
    other_range,
    integer(),
    NULL,
    TRUE
  )
  expect_identical(out[[1]], c(2L, 1L, 5L))
  expect_identical(out[[2]], c(2L, 3L, 1L))
  weights <- c(1e16, 1, 1, 2, 0, 0)
  weighted <- tab_count_dense(
    values,
    range,
    other,
    other_range,
    integer(),
    weights,
    TRUE
  )
  expect_identical(weighted[[1]], out[[1]])
  expect_identical(weighted[[2]], c(3, sum(weights[c(1, 3)]), 0))
  expect_identical(
    tab_count_dense(values, range, other, other_range, integer(), NULL, FALSE)[[
      1
    ]],
    c(1L, 5L, 2L)
  )
  missing <- c(NA_integer_, NA_integer_)
  expect_identical(tab_integer_range(missing), c(0L, 0L, 1L))
  expect_identical(
    tab_count_dense(
      missing,
      tab_integer_range(missing),
      c(1L, 1L),
      c(1L, 1L, 0L),
      integer(),
      NULL,
      TRUE
    )[[2]],
    2L
  )
  expect_identical(tab_integer_range(c(TRUE, FALSE, NA)), c(0L, 2L, 1L))
  expect_null(tab_integer_range(c(1L, .Machine$integer.max)))
  expect_null(tab_count_dense(
    values,
    c(1L, 4L, 0L),
    other,
    other_range,
    integer(),
    NULL,
    TRUE
  ))
  expect_error(
    tab_count_dense(
      0L,
      c(1L, 1L, 0L),
      1L,
      c(1L, 1L, 0L),
      integer(),
      NULL,
      TRUE
    ),
    "identity"
  )
  dictionary <- tab_character_id(c("z", "a", "z", NA_character_), 3L)
  expect_identical(dictionary[[1]], c(1L, 2L, 1L, 3L))
  expect_identical(dictionary[[2]], c(1L, 2L, 4L))
  expect_null(tab_character_id(c("a", "b"), 1L))
  latin <- iconv("\u00e9", "UTF-8", "latin1")
  expect_identical(
    tab_character_id(c(latin, enc2utf8(latin)), 1L)[[1]],
    c(1L, 1L)
  )
  deferred <- as.character(seq_len(30))
  expect_identical(tab_character_id(deferred, 30L)[[1]], seq_len(30))
  bytes <- rawToChar(as.raw(255))
  Encoding(bytes) <- "bytes"
  expect_null(tab_character_id(bytes, 1L))
})

test_that("native summary scratch preserves base statistics and raw identities", {
  x <- c(1, 3, 5, 9, 7, 7, Inf, Inf)
  locs <- list(1:4, 5:6, 7:8, integer())
  statistics <- c("mean", "sd", "min", "max", "sum", "median", "mad", "q1")
  actual <- stats::setNames(
    group_summary_dbl(x, locs, statistics, 0.25, c(rep(0L, 7), 1L), TRUE),
    statistics
  )
  references <- list(
    mean = mean,
    sd = stats::sd,
    min = min,
    max = max,
    sum = sum,
    median = stats::median,
    mad = stats::mad,
    q1 = function(x) stats::quantile(x, .25, type = 2, names = FALSE)
  )
  for (statistic in statistics) {
    expected <- vapply(
      locs,
      function(loc) {
        if (length(loc)) references[[statistic]](x[loc]) else NA_real_
      },
      numeric(1)
    )
    expect_identical(actual[[statistic]], expected)
  }
  precise <- c(1.1631413954272694, 0.87510317068316645, -0.97328754163643316)
  expect_identical(
    group_summary_dbl(precise, list(1:3), "sd", numeric(), 0L, TRUE)[[1]],
    stats::sd(precise)
  )
  expect_identical(
    group_unique_id(c(1L, 2L, 1L, 3L, 1L, 1L, 4L, 4L), locs),
    c(3L, 1L, 1L, 0L)
  )
})

test_that("native weighted summaries retain count-only and underflow paths", {
  weights <- c(1e-308, 1e308)
  statistic <- "sum"
  single <- group_weighted_summary_dbl(
    c(1e308, 0),
    weights,
    list(1:2),
    TRUE,
    FALSE,
    statistic,
    numeric(),
    0L
  )
  grouped <- group_weighted_summary_dbl(
    rep(c(1e308, 0), 2),
    rep(weights, 2),
    list(1:2, 3:4),
    TRUE,
    TRUE,
    statistic,
    numeric(),
    0L
  )
  expect_identical(single[[1]], 0)
  expect_identical(grouped[[1]], rep(1e308 * 1e-308, 2))
  data <- data.frame(
    g = rep(1:2, each = 2),
    x = rep(c(1e308, 0), 2),
    w = rep(weights, 2)
  )
  expect_identical(
    summ(data, x, .wt = w, .wt_type = "analytic", .stat = "sum")$sum,
    0
  )
  expect_identical(
    summ(data, x, .by = g, .wt = w, .wt_type = "analytic", .stat = "sum")$sum,
    grouped[[1]]
  )
  expect_identical(
    group_weighted_summary_dbl(
      NULL,
      c(0, 0.5, 1.5),
      list(1:3, integer()),
      FALSE,
      TRUE,
      "n",
      numeric(),
      0L
    )[[1]],
    c(2, 0)
  )
  expect_error(
    group_summary_dbl(1, list(0L), "mean", numeric(), 0L, TRUE),
    "index"
  )
  expect_error(group_unique_id(1L, list(2L)), "index")
})

test_that("fractional weighted infinite spreads preserve grouped NaN results", {
  data <- data.frame(
    g = rep(1:2, each = 2),
    x = rep(c(Inf, -1e-308), 2),
    w = rep(c(1, 1e-308), 2)
  )
  statistics <- c("sd", "se")
  grouped <- summ(data, x, .by = g, .wt = w, .stat = statistics)
  expect_true(all(is.nan(unlist(grouped[statistics]))))
  single <- summ(data[1:2, ], x, .wt = w, .stat = statistics)
  expect_true(all(is.na(unlist(single[statistics]))))
  expect_false(any(is.nan(unlist(single[statistics]))))
})

test_that("large native percentile scratch preserves ties and nonfinite order", {
  values <- rep(c(-0, 0, 9, -5, 3, Inf), 400)
  statistics <- c("p0", "median", "q1", "p100", "mad")
  out <- group_summary_dbl(
    values,
    list(seq_along(values)),
    statistics,
    c(0, .25, 1),
    c(1L, 0L, 2L, 3L, 0L),
    FALSE
  )
  expect_identical(out[[1]], min(values))
  expect_identical(out[[2]], stats::median(values))
  expect_identical(out[[3]], unname(stats::quantile(values, .25, type = 2)))
  expect_identical(out[[4]], max(values))
  expect_identical(out[[5]], stats::mad(values))
  zero <- rep(c(-0, 0), 1200)
  expect_identical(
    1 / group_summary_dbl(zero, list(seq_along(zero)), "p0", 0, 1L, FALSE)[[1]],
    -Inf
  )
})

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
  out <- tab2(data, a, b, .wt = w)
  expect_named(out, c("a \\ b", "c", "b"))
  expect_identical(out[[1]], c("a", "z"))
  expect_equal(out$c, c(2, 0))
  expect_equal(out$b, c(3, 1.5))
  expect_type(tab2(data, a, b)$b, "integer")
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
  expect_equal(nrow(tab2(data, g, x, .wt = w)), 0L)
  missing <- data.frame(x = c(NA_real_, NA_real_), w = c(0, 2))
  expect_warning(
    out <- summ(missing, x, .wt = w, .stat = c("n", "mean", "sd", "median")),
    "entirely missing"
  )
  expect_equal(out$n, 0)
  expect_true(all(is.na(unlist(out[c("mean", "sd", "median")]))))
})

test_that("matrix columns can't give column headers", {
  data <- tibble::tibble(a = 1:3, b = matrix(1:6, 3))
  expect_error(tab2(data, a, b), "`b` has several columns")
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
    per_group(function(x) quantile(x, 0.25, type = 2, names = FALSE))
  )
  expect_identical(
    out$p37,
    per_group(function(x) quantile(x, 0.37, type = 2, names = FALSE))
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
        q1 = stats::quantile(x, 0.25, type = 2, names = FALSE),
        p37 = stats::quantile(x, 0.37, type = 2, names = FALSE),
        median = stats::median(x),
        mad = stats::mad(x),
        mean = center,
        sd = spread,
        skew = mean((x - center)^3) / mean((x - center)^2)^1.5,
        kurtosis = mean((x - center)^4) / mean((x - center)^2)^2
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
    data$w <- rep(c(0, .5, 1, 2), length.out = nrow(data))
    for (type in c("frequency", "analytic")) {
      actual <- summ(
        data,
        x,
        .by = g,
        .wt = w,
        .wt_type = type,
        .stat = statistics
      )
      separate <- dplyr::bind_rows(lapply(split(data, data$g), function(group) {
        summ(group, x, .wt = w, .wt_type = type, .stat = statistics)
      }))
      expect_identical(
        as.list(actual[statistics]),
        as.list(separate[statistics])
      )
    }
  }
})

test_that("compact tabulations preserve raw keys, order and fallback classes", {
  cases <- list(
    c(NA_real_, NaN, -0, 0, Inf, -Inf, 3),
    c("z", "a", "\u9999\u6e2f", "", NA, "z", "a"),
    factor(c("b", "a", NA, "b", "a", "b", "a"), levels = c("unused", "b", "a")),
    haven::labelled(c(1, 2, 1, NA, 2, 1, 2), c(one = 1, two = 2)),
    as.Date("2024-01-01") + c(1, 2, NA, 1, 2, 1, 2),
    list(NULL, 1, 2, 1, 2, NULL, 1)
  )
  repetitions <- 15000L
  for (value in cases) {
    data <- tibble::tibble(
      g = rep(c(2L, 1L, 2L, 1L, 2L, 1L, 2L), repetitions),
      value = rep(value, repetitions),
      w = rep(c(0, .5, 1, 2, 3, 0, 1), repetitions)
    )
    before <- data
    for (columns in list(c("g", "value"), c("value", "g"))) {
      for (weights in list(NULL, data$w)) {
        expected <- vctrs::vec_locate_sorted_groups(
          data[columns],
          nan_distinct = TRUE
        )
        counts <- if (is.null(weights)) {
          lengths(expected$loc)
        } else {
          vapply(expected$loc, function(loc) sum(weights[loc]), numeric(1))
        }
        actual <- aggregation_counts(data[columns], weights)
        expect_identical(actual, c(as.list(expected$key), list(n = counts)))
      }
    }
    expect_identical(data, before)
  }
})
