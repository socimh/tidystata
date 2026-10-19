test_that("summary requests avoid unrequested expensive statistics", {
  testthat::local_mocked_bindings(
    quantile = function(...) stop("Unrequested quantile calculation"),
    sd = function(...) stop("Unrequested SD calculation"),
    .package = "stats"
  )
  testthat::local_mocked_bindings(
    skew = function(...) stop("Unrequested skew calculation"),
    kurtosis = function(...) stop("Unrequested kurtosis calculation"),
    .package = "statart"
  )
  expect_equal(summ(1:100, .stat = "mean")$mean, 50.5)
  expect_equal(summ(1:100, .stat = "n")$n, 100)
  day <- as.Date("2024-01-01") + 0:2
  expect_equal(summ(day, .stat = "mean")$mean, "2024-01-02")
  moment <- as.POSIXct("2024-01-01", tz = "UTC") + c(0, 120)
  expect_equal(summ(moment, .stat = "mean")$mean, "2024-01-01 00:01")
})

test_that("summary percentile names retain requested order and type-7 values", {
  x <- c(-9, 0, 3, 8, 24, NA_real_)
  requested <- c("p97.5", "p0", "p2.5", "q1", "p25", "p100", "p97.5")
  out <- summ(x, .stat = requested, .name = TRUE)
  expect_named(out, c("name", "type", unique(requested)))
  expect_equal(
    unlist(out[unique(requested)], use.names = FALSE),
    unname(stats::quantile(x, c(.975, 0, .025, .25, .25, 1), na.rm = TRUE))
  )
  day <- as.Date("2024-01-01") + c(0, 10)
  expect_equal(summ(day, .stat = "p2.5")$p2.5, "2024-01-01")
  moment <- as.POSIXct("2024-01-01", tz = "UTC") + c(0, 3600)
  expect_equal(summ(moment, .stat = "p2.5")$p2.5, "2024-01-01 00:01")
  labelled <- haven::labelled_spss(c(0, 100, 999), na_values = 999)
  expect_warning(
    observed <- summ(labelled, .stat = c("p2.5", "p97.5")),
    "labelled"
  )
  expect_equal(observed$p2.5, 2.5)
  expect_equal(observed$p97.5, 97.5)
  collision <- tibble::tibble(p2.5 = c("b", "a"), x = c(0, 10))
  expect_message(
    by_percentile <- summ(
      collision,
      x,
      .by = p2.5,
      .stat = "p2.5",
      .name = TRUE
    ),
    "Grouping column.*renamed"
  )
  expect_named(by_percentile, c(".p2.5", "name", "type", "p2.5"))
  # Groups are sorted by key by default: "a" (x = 10) before "b" (x = 0).
  expect_equal(by_percentile$.p2.5, c("a", "b"))
  expect_equal(by_percentile$p2.5, c(10, 0))
  for (invalid in c("p-1", "p101", "pNaN", "p2.5.1")) {
    expect_error(summ(x, .stat = invalid), "Unsupported statistic")
  }
})

test_that("sorted mixed summaries preserve selection order across type families", {
  input <- tibble::tibble(
    g = c("b", "a"),
    x = 1:2,
    day = as.Date("2024-01-01") + 0:1
  )
  out <- summ(input, day, x, .by = g, .mode = "table", .sort = TRUE)
  expect_equal(out$g, c("a", "a", "b", "b"))
  expect_equal(out$name, c("day", "x", "day", "x"))
  grouped <- dplyr::group_by(input, g)
  expect_equal(summ(grouped, x, .sort = TRUE)$g, c("a", "b"))
  zero <- summ(input[0, ], .by = g, .sort = TRUE, .drop_empty = TRUE)
  expect_equal(nrow(zero$numeric), 0L)
  expect_equal(nrow(zero$date), 0L)
})

test_that("summary sorting uses key values and preserves measured-variable order", {
  input <- tibble::tibble(
    g = factor(c("low", "high", "low", NA), levels = c("high", "low")),
    h = c(2, 1, 1, 0),
    x = 1:4,
    y = 5:8
  )
  for (fn in list(summ, tabstat)) {
    out <- fn(input, y, x, .by = c(g, h), .sort = TRUE, .stat = "mean")
    expect_equal(
      as.character(out$g),
      rep(c("high", "low", "low", NA), each = 2)
    )
    expect_equal(out$h, rep(c(1, 1, 2, 0), each = 2))
    expect_equal(out$name, rep(c("y", "x"), 4))
    expect_equal(
      fn(input, x, .by = g, .stat = "n", .sort = FALSE)$g,
      input$g[c(1, 2, 4)]
    )
    expect_equal(
      fn(input, x, .by = g, .stat = "n")$g,
      factor(c("high", "low", NA), levels = c("high", "low"))
    )
    expect_error(fn(input, .sort = NA), "single TRUE or FALSE")
  }
})

test_that("summary empty-row removal is independent of missing-key removal", {
  input <- tibble::tibble(
    g = c("b", "a", NA),
    x = c(NA_real_, 2, 3),
    day = as.Date(c("2024-01-01", NA, "2024-01-03"))
  )
  for (fn in list(summ, tabstat)) {
    out <- fn(input, .by = g, .drop_empty = TRUE, .stat = "mean")
    expect_equal(out$numeric$g, c("a", NA))
    expect_equal(out$date$g, c("b", NA))
    expect_false("n" %in% names(out$numeric))
    combined <- fn(
      input,
      .by = g,
      .drop_empty = TRUE,
      .na.rm = TRUE,
      .mode = "table",
      .stat = "mean",
      .sort = TRUE
    )
    expect_equal(combined$g, c("a", "b"))
    expect_equal(combined$name, c("x", "day"))
    expect_error(fn(input, .drop_empty = 1), "single TRUE or FALSE")
  }
  expect_warning(
    empty <- summ(c(NA_real_, NA_real_), .drop_empty = TRUE, .stat = "mean"),
    "entirely missing"
  )
  expect_equal(nrow(empty), 0L)
  expect_named(empty, c("type", "mean"))
})

test_that("rank cuts balance ties deterministically and restore missing positions", {
  x <- c(4, 1, 1, NA, 4, 1, 2, 9)
  out <- cut_quantile(x, n = 3, method = "rank", labels = FALSE)
  expect_identical(out, c(2L, 1L, 1L, NA_integer_, 3L, 1L, 2L, 3L))
  expect_equal(as.integer(table(out)), c(3L, 2L, 2L))
  expect_identical(cut_quantile(x, n = 3, method = "rank", labels = FALSE), out)
  constant <- cut_quantile(rep(5, 5), n = 2, method = "rank")
  expect_true(is.ordered(constant))
  expect_equal(levels(constant), c("1", "2"))
  expect_equal(as.integer(constant), c(1L, 1L, 1L, 2L, 2L))
  expect_warning(
    scarce <- cut_quantile(c(4, NA, 2), n = 4, method = "rank"),
    "observations"
  )
  expect_equal(levels(scarce), c("1", "2"))
  expect_equal(as.integer(scarce), c(2L, NA_integer_, 1L))
  expect_equal(
    levels(cut_quantile(
      1:4,
      n = 2,
      method = "rank",
      labels = c("low", "high")
    )),
    c("low", "high")
  )
  expect_error(
    cut_quantile(1:4, n = 2, method = "rank", labels = "x"),
    "length 2"
  )
  expect_error(cut_quantile(NA_real_, method = "rank"), "non-missing")
  expect_identical(
    cut_quantile(
      c(Inf, -Inf, NA, NaN, 0),
      n = 2,
      method = "rank",
      labels = FALSE
    ),
    c(2L, 1L, NA_integer_, NA_integer_, 1L)
  )
  expect_identical(
    cut_quantile(8, n = 1, method = "rank", labels = FALSE),
    1L
  )
  expect_error(cut_quantile(1:5, method = "wrong"), "arg")
  expect_error(
    cut_quantile(1:5, n = 1 + 1i, method = "rank"),
    "positive integer"
  )
})

test_that("default quantile cuts never merge distinct values", {
  dummy <- rep(0:1, c(7, 3))
  expect_no_warning(two <- cut_quantile(dummy, 2))
  expect_identical(as.integer(two), as.integer(dummy) + 1L)
  expect_identical(levels(two), c("[0,0]", "(0,1]"))
  expect_warning(
    codes <- cut_quantile(rep(0:1, c(3, 8)), 10, labels = FALSE),
    "2 groups"
  )
  expect_identical(codes, rep(1:2, c(3, 8)))
  expect_warning(
    three <- cut_quantile(rep(1:3, c(500, 300, 200)), 10, labels = FALSE),
    "3 groups"
  )
  expect_identical(sort(unique(three)), 1:3)
  expect_identical(as.integer(table(three)), c(500L, 300L, 200L))
  expect_warning(
    labelled <- cut_quantile(dummy, 10, labels = c("no", "yes")),
    "2 groups"
  )
  expect_identical(as.character(labelled), ifelse(dummy == 1, "yes", "no"))
  expect_no_warning(even <- cut_quantile(1:8, 4, labels = FALSE))
  expect_identical(even, rep(1:4, each = 2))
  expect_identical(
    levels(cut_quantile(1:8, 4)),
    c("[1,2.75]", "(2.75,4.5]", "(4.5,6.25]", "(6.25,8]")
  )
  expect_identical(
    cut_quantile(c(NA, 1:4), 2, labels = FALSE),
    c(NA, 1L, 1L, 2L, 2L)
  )
})

test_that("summary defaults sort groups like tab and hide a single name", {
  levels <- c("low", "middle", "high")
  d <- tibble::tibble(
    edu = factor(c("high", "middle", NA, "low", "high"), levels = levels),
    x = 1:5
  )
  out <- summ(d, x, .by = "edu")
  expect_identical(as.character(out$edu), c(levels, NA))
  expect_identical(
    as.character(out$edu),
    as.character(unique(tab(d, x, .by = edu)$edu))
  )
  expect_identical(
    as.character(summ(dplyr::group_by(d, edu), x)$edu),
    c(levels, NA)
  )
  expect_false("name" %in% names(out))
  expect_true("name" %in% names(summ(d, x, .by = edu, .name = TRUE)))
  expect_true("name" %in% names(summ(dplyr::mutate(d, y = x), .by = edu)))
  expect_identical(
    as.character(summ(d, x, .by = edu, .sort = FALSE)$edu),
    c("high", "middle", NA, "low")
  )
})

test_that("tabstat detail, calendar skips and datetime zones", {
  expect_true(all(
    c("median", "sd", "sum") %in% names(tabstat(1:5, .detail = TRUE))
  ))
  expect_identical(names(tabstat(1:5)), c("type", "mean"))
  mixed <- tibble::tibble(x = 1:2, day = as.Date("2024-01-01") + 0:1)
  expect_warning(total <- summ(mixed, .stat = "sum"), "skipped: day")
  expect_identical(total$sum, 3)
  expect_error(summ(mixed["day"], .stat = "sum"), "sum.*date")
  hk <- as.POSIXct(
    c("2024-03-01 09:00", "2024-03-02 09:00"),
    tz = "Asia/Hong_Kong"
  )
  zoned <- summ(hk)
  expect_identical(zoned$min, "2024-03-01 09:00")
  expect_identical(zoned$max, "2024-03-02 09:00")
})
