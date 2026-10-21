weighted <- tibble::tibble(
  g = c("a", "a", "a", "b", "b"),
  x = c(10, 20, 40, 5, 5),
  w = c(3, 1, 1, 2, 2)
)
# Integer frequency weights must equal replicating each row w times.
replicated <- weighted[rep(seq_len(nrow(weighted)), weighted$w), ]

test_that("frequency-weighted tabulations equal replicated data", {
  out <- tab(weighted, x, .wt = w)
  expect_equal(out$n, as.double(tab(replicated, x)$n))
  expect_equal(out$percent, tab(replicated, x)$percent)
  expect_equal(
    fre(weighted, x, .by = g, .wt = w)$n,
    as.double(fre(replicated, x, .by = g)$n)
  )
  expect_equal(
    tab(weighted, x, .wt = w, .total = TRUE),
    fre(weighted, x, .wt = w)
  )
  stacked <- tab1(weighted, g, x, .wt = w, .type = "tibble")
  expect_equal(
    stacked$n,
    as.double(tab1(replicated, g, x, .type = "tibble")$n)
  )
  cross <- xtab(weighted, g, x, .wt = w, .total = TRUE)
  expect_equal(
    as.matrix(cross[-1]),
    as.matrix(xtab(replicated, g, x, .total = TRUE)[-1]) * 1
  )
})

test_that("non-integer frequency weights sum like dplyr::count(wt =)", {
  data <- tibble::tibble(x = c("a", "a", "b"), w = c(0.5, 1.25, 2))
  expect_equal(tab(data, x, .wt = w)$n, c(1.75, 2))
  expect_equal(
    tab(data, x, .wt = w)$n,
    dplyr::count(data, x, wt = w)$n
  )
})

test_that("analytic weights rescale to the rows of each group", {
  out <- tab(weighted, x, .by = g, .wt = w, .wt_type = "analytic")
  expect_equal(out$n, c(1.8, 0.6, 0.6, 2))
  expect_equal(
    out$percent,
    tab(weighted, x, .by = g, .wt = w)$percent
  )
  overall <- tab(weighted, g, .wt = w, .wt_type = "analytic")
  expect_equal(sum(overall$n), nrow(weighted))
})

test_that("the weight column is not tabulated or summarised by default", {
  expect_false("w" %in% names(tab(weighted, .wt = w)))
  # `g` is dropped as non-numeric; `w` must not be summarised either.
  summary <- suppressWarnings(summ(weighted, .wt = w, .name = TRUE))
  expect_identical(summary$name, "x")
  expect_true("w" %in% names(tab(weighted, x, w, .wt = w)))
})

test_that("weighted summaries equal replicated data and Stata's formulas", {
  stats <- c("n", "mean", "sd", "se", "sum", "min", "max", "skew", "kurtosis")
  out <- summ(weighted, x, .wt = w, .stat = stats)
  reference <- summ(replicated, x, .stat = stats)
  for (statistic in setdiff(stats, "n")) {
    expect_equal(out[[statistic]], reference[[statistic]])
  }
  expect_equal(out$n, 9)
  # Stata's weighted percentile rule matches replication for integer weights.
  expect_equal(summ(weighted, x, .wt = w, .stat = "p50")$p50, 10)
  expect_equal(summ(weighted, x, .wt = w, .stat = "p50", .by = g)$p50, c(10, 5))
  # Exact cumulative-weight ties average neighbouring values, as in Stata.
  tie <- tibble::tibble(x = c(1, 2), w = c(1, 1))
  expect_equal(summ(tie, x, .wt = w, .stat = "p50")$p50, 1.5)
})

test_that("analytic weights keep means and use the observation count", {
  out <- summ(
    weighted,
    x,
    .by = g,
    .wt = w,
    .wt_type = "analytic",
    .stat = c("n", "mean", "sd")
  )
  expect_equal(out$n, c(3, 2))
  expect_equal(out$mean, c(18, 5))
  # Stata: weights rescaled to sum to N, variance divided by N - 1.
  scaled <- c(3, 1, 1) * 3 / 5
  expect_equal(
    out$sd[[1]],
    sqrt(sum(scaled * (c(10, 20, 40) - 18)^2) / 2)
  )
  expect_equal(
    tabstat(weighted, x, .by = g, .wt = w)$mean,
    c(18, 5)
  )
})

test_that("missing, negative and malformed weights are handled", {
  data <- tibble::tibble(x = c(1, 2, 3), w = c(1, NA, 2))
  expect_message(
    out <- tab(data, x, .wt = w),
    "Excluded 1 row with missing weights"
  )
  expect_equal(out$x, c(1, 3))
  expect_message(summ(data, x, .wt = w), "Excluded 1 row")
  expect_error(
    tab(tibble::tibble(x = 1, w = -1), x, .wt = w),
    "must not be negative"
  )
  expect_error(tab(weighted, x, .wt = g), "must be a numeric")
  expect_error(tab(weighted, x, .wt = c(1, 2)), "one value per row")
  expect_equal(tab(c(1, 1, 2), .wt = c(2, 1, 1))$n, c(3, 1))
})

test_that("xtile() uses weighted cutpoints like Stata's xtile [w]", {
  codes <- xtile(weighted$x, 2, wt = weighted$w, labels = FALSE)
  reference <- xtile(replicated$x, 2, labels = FALSE)
  expect_identical(codes, reference[match(weighted$x, replicated$x)])
  expect_identical(
    xtile(c(1, 2, 3), 2, wt = c(1, NA, 1), labels = FALSE),
    c(1L, NA, 2L)
  )
  expect_error(
    xtile(1:4, 2, method = "rank", wt = rep(1, 4)),
    "not supported"
  )
  panel <- tibble::tibble(g = rep(1:2, each = 4), x = c(1:4, 11:14), w = 1:8)
  grouped <- dplyr::mutate(
    dplyr::group_by(panel, g),
    q = xtile(x, 2, wt = w)
  )
  expect_type(grouped$q, "integer")
  expect_identical(grouped$q, c(1L, 1L, 1L, 2L, 1L, 1L, 1L, 2L))
})


test_that("analytic tabulation rescales finite weights without overflow", {
  data <- data.frame(x = letters[1:3], w = rep(1e308, 3))
  out <- tab(data, x, .wt = w, .wt_type = "analytic")
  expect_equal(out$n, rep(1, 3))
  expect_equal(out$percent, rep(100 / 3, 3))

  grouped <- data.frame(
    g = c("large", "large", "small", "small", "zero", "zero", "missing"),
    x = c("a", "b", "a", "b", "a", "b", "a"),
    w = c(1.2e308, 6e307, 1e-300, 2e-300, 0, 0, NA)
  )
  expect_message(
    out <- tab(grouped, x, .by = g, .wt = w, .wt_type = "analytic"),
    "Excluded 1 row"
  )
  expect_identical(out$g, rep(c("large", "small", "zero"), each = 2))
  expect_equal(out$n, c(4 / 3, 2 / 3, 2 / 3, 4 / 3, 0, 0))
  expect_true(all(is.nan(out$percent[out$g == "zero"])))
  grouped$w[1:4] <- c(2, 1, 1, 2)
  expect_message(
    reference <- tab(grouped, x, .by = g, .wt = w, .wt_type = "analytic"),
    "Excluded 1 row"
  )
  expect_equal(out, reference)
  empty <- data[integer(), ]
  expect_equal(nrow(tab(empty, x, .wt = w, .wt_type = "analytic")), 0L)
})
