# Properties that must hold on any data: row order, grouping, weights,
# missing rows, round trips and independent references. Inputs are drawn
# from fixed seeds and include ties, missing values and a missing group key;
# references use base R, not the production helpers.

stress_random_frame <- function(seed, n = 40L) {
  withr::with_seed(seed, {
    x <- round(stats::rnorm(n, 10, 5), 1)
    x[sample.int(n, 4L)] <- NA
    x[sample.int(n, 6L)] <- x[1:6]
    y <- round(x * 0.5 + stats::rnorm(n), 2)
    y[sample.int(n, 3L)] <- NA
    tibble::tibble(
      x = x,
      y = y,
      k = sample(c(1L, 2L, 3L, NA), n, replace = TRUE),
      f = factor(
        sample(c("lo", "mid", "hi", NA), n, replace = TRUE),
        levels = c("lo", "mid", "hi", "none")
      ),
      s = sample(c("b", "a", "B", "", NA), n, replace = TRUE),
      g = sample(c("p", "q", "r", NA), n, replace = TRUE, prob = c(4, 4, 3, 1)),
      w = sample(1:4, n, replace = TRUE)
    )
  })
}

stress_seeds <- c(20261027L, 1L, 99L)

stress_permute <- function(d, seed) {
  withr::with_seed(seed, d[sample.int(nrow(d)), ])
}

stress_replicate <- function(d, w = d$w) {
  d[rep(seq_len(nrow(d)), w), ]
}

expect_same_table <- function(object, expected, label = NULL) {
  expect_equal(
    as.data.frame(object),
    as.data.frame(expected),
    tolerance = 1e-10,
    label = label
  )
}

# Row order ----------------------------------------------------------------

test_that("stress invariant: summaries and tables ignore row order", {
  skip_if_not_installed("withr")
  for (seed in stress_seeds) {
    d <- stress_random_frame(seed)
    p <- stress_permute(d, seed + 1L)
    expect_same_table(
      summ(p, x, y, .detail = TRUE),
      summ(d, x, y, .detail = TRUE)
    )
    expect_same_table(summ(p, x, .by = g), summ(d, x, .by = g))
    expect_same_table(summ(p, x, .wt = w), summ(d, x, .wt = w))
    expect_same_table(tab(p, f), tab(d, f))
    expect_same_table(tab(p, s), tab(d, s))
    expect_same_table(tab(p, k, .by = g), tab(d, k, .by = g))
    expect_same_table(tab2(p, f, g), tab2(d, f, g))
    expect_same_table(fre(p, s), fre(d, s))
    expect_same_table(corr(p, x, y), corr(d, x, y))
    expect_same_table(pwcorr(p, x, y, k), pwcorr(d, x, y, k))
    expect_same_table(spearman(p, x, y), spearman(d, x, y))
    expect_same_table(misstable(p, x, y, f), misstable(d, x, y, f))
    expect_same_table(duplicates_report(p, k, g), duplicates_report(d, k, g))
  }
})

test_that("stress invariant: row-wise results follow their rows", {
  skip_if_not_installed("withr")
  for (seed in stress_seeds) {
    d <- stress_random_frame(seed)
    d$id <- seq_len(nrow(d))
    add <- function(data) {
      data |>
        dplyr::mutate(
          q = xtile(x, 4),
          z = std(x),
          share = pc(w),
          m = row_mean(x, y),
          first = is_first(g)
        ) |>
        dplyr::arrange(id)
    }
    p <- stress_permute(d, seed + 2L)
    ordered <- add(d)
    shuffled <- add(p)
    expect_identical(shuffled$q, ordered$q)
    expect_equal(shuffled$z, ordered$z, tolerance = 1e-12)
    expect_equal(shuffled$share, ordered$share, tolerance = 1e-12)
    expect_equal(shuffled$m, ordered$m, tolerance = 1e-12)
    # Which row is first depends on order; the number of first rows does not.
    expect_identical(sum(shuffled$first), sum(ordered$first))
  }
})

# Grouping -----------------------------------------------------------------

test_that("stress invariant: grouped summaries equal per-group summaries", {
  skip_if_not_installed("withr")
  for (seed in stress_seeds) {
    d <- stress_random_frame(seed)
    keys <- sort(unique(d$g), na.last = TRUE)
    by_group <- summ(d, x, .by = g, .detail = TRUE)
    grouped <- summ(dplyr::group_by(d, g), x, .detail = TRUE)
    expect_same_table(grouped, by_group)
    for (i in seq_along(keys)) {
      part <- d[if (is.na(keys[i])) is.na(d$g) else d$g %in% keys[i], ]
      alone <- summ(part, x, .detail = TRUE)
      expect_same_table(by_group[i, names(alone)], alone, label = keys[i])
    }
    by_corr <- corr(d, x, y, .by = g)
    for (key in stats::na.omit(keys)) {
      alone <- corr(d[d$g %in% key, ], x, y)
      row <- by_corr[by_corr$g %in% key, names(alone)]
      expect_same_table(row, alone, label = key)
    }
  }
})

test_that("stress invariant: grouped tabulations equal per-group tabulations", {
  skip_if_not_installed("withr")
  d <- stress_random_frame(20261027L)
  by_group <- tab(d, f, .by = g)
  for (key in stats::na.omit(unique(d$g))) {
    alone <- tab(d[d$g %in% key, ], f)
    rows <- by_group[by_group$g %in% key, names(alone)]
    expect_same_table(rows, alone, label = key)
  }
})

test_that("stress invariant: grouped mutate helpers equal per-group calls", {
  skip_if_not_installed("withr")
  for (seed in stress_seeds) {
    d <- stress_random_frame(seed)
    d <- d[!is.na(d$g), ]
    out <- dplyr::mutate(
      d,
      z = std(x),
      share = pc(w),
      q = xtile(x, 2),
      .by = g
    )
    for (key in unique(d$g)) {
      rows <- d$g == key
      expect_equal(out$z[rows], as.numeric(std(d$x[rows])), tolerance = 1e-12)
      expect_equal(
        out$share[rows],
        as.numeric(pc(d$w[rows])),
        tolerance = 1e-12
      )
      # Grouped cuts return group-relative integer codes.
      expect_identical(out$q[rows], as.integer(xtile(d$x[rows], 2)))
    }
  }
})

# Weights ------------------------------------------------------------------

test_that("stress invariant: unit weights equal unweighted results", {
  skip_if_not_installed("withr")
  for (seed in stress_seeds) {
    d <- stress_random_frame(seed)
    d$one <- 1
    expect_same_table(
      summ(d, x, y, .wt = one, .detail = TRUE),
      summ(d, x, y, .detail = TRUE)
    )
    expect_same_table(tab(d, f, .wt = one), tab(d, f))
    expect_same_table(corr(d, x, y, .wt = one), corr(d, x, y))
    expect_identical(xtile(d$x, 4, wt = d$one), xtile(d$x, 4))
  }
})

test_that("stress invariant: frequency weights equal replicated rows", {
  skip_if_not_installed("withr")
  for (seed in stress_seeds) {
    d <- stress_random_frame(seed)
    r <- stress_replicate(d)
    # unique, miss_n and valid_pct count unweighted rows by contract.
    weighted_stats <- function(t) {
      t[setdiff(names(t), c("unique", "miss_n", "valid_pct"))]
    }
    expect_same_table(
      weighted_stats(summ(d, x, y, .wt = w, .detail = TRUE)),
      weighted_stats(summ(r, x, y, .detail = TRUE))
    )
    expect_same_table(
      weighted_stats(summ(d, x, .by = g, .wt = w)),
      weighted_stats(summ(r, x, .by = g))
    )
    expect_same_table(tab(d, f, .wt = w), tab(r, f))
    expect_same_table(tab2(d, f, g, .wt = w), tab2(r, f, g))
    expect_same_table(corr(d, x, y, .wt = w), corr(r, x, y))
    weighted <- pwcorr(d, x, y, .wt = w)
    replicated <- pwcorr(r, x, y)
    expect_same_table(
      weighted[c("var1", "var2", "r", "n")],
      replicated[c("var1", "var2", "r", "n")]
    )
    codes <- xtile(d$x, 4, wt = d$w)
    expect_identical(codes[rep(seq_len(nrow(d)), d$w)], xtile(r$x, 4))
  }
})

test_that("stress invariant: analytic weights ignore their scale", {
  skip_if_not_installed("withr")
  for (seed in stress_seeds) {
    d <- stress_random_frame(seed)
    d$w3 <- d$w * 3.5
    stats <- c("n", "mean", "sd", "min", "max")
    one <- summ(d, x, .wt = w, .wt_type = "analytic")
    scaled <- summ(d, x, .wt = w3, .wt_type = "analytic")
    expect_same_table(scaled[stats], one[stats])
    expect_same_table(
      corr(d, x, y, .wt = w3, .wt_type = "analytic")["r"],
      corr(d, x, y, .wt = w, .wt_type = "analytic")["r"]
    )
  }
})

# Missing rows -------------------------------------------------------------

test_that("stress invariant: an all-missing row changes only missing counts", {
  skip_if_not_installed("withr")
  for (seed in stress_seeds) {
    d <- stress_random_frame(seed)
    padded <- dplyr::bind_rows(d, d[NA_integer_, ])
    stats <- c("n", "mean", "sd", "min", "max")
    expect_same_table(summ(padded, x, y)[stats], summ(d, x, y)[stats])
    expect_same_table(corr(padded, x, y), corr(d, x, y))
    valid <- function(t) t[!is.na(t$f), c("f", "valid")]
    expect_same_table(valid(tab(padded, f)), valid(tab(d, f)))
    expect_identical(
      misstable(padded, x)$miss_n,
      misstable(d, x)$miss_n + 1L
    )
  }
})

# Round trips --------------------------------------------------------------

test_that("stress invariant: tostring() and destring() round-trip numbers", {
  # Values with at most 15 significant digits, the documented precision.
  x <- c(
    0,
    1.5,
    -2.25,
    1 / 4,
    123456789,
    1e15,
    1e-5,
    1.234e-10,
    1e100,
    -1e300,
    NA
  )
  # Base R's fixed-decimal parser can differ by a few ulps on ARM.
  for (value in x) {
    expect_equal(destring(tostring(value)), value, tolerance = 1e-14)
  }
  expect_identical(destring(tostring(-0)), 0)
  i <- c(.Machine$integer.max, -.Machine$integer.max, 0L, NA)
  expect_identical(destring(tostring(i)), as.numeric(i))
})

test_that("stress invariant: mvencode() and mvdecode() are inverses", {
  skip_if_not_installed("withr")
  for (seed in stress_seeds) {
    x <- stress_random_frame(seed)$x
    expect_identical(mvdecode(mvencode(x, -999), -999), x)
    expect_identical(sum(mvencode(x, -999) == -999), sum(is.na(x)))
  }
})

test_that("stress invariant: panel operators agree with a time lookup", {
  skip_if_not_installed("withr")
  for (seed in stress_seeds) {
    panel <- withr::with_seed(seed, {
      tibble::tibble(
        id = rep(1:4, each = 6),
        time = as.vector(replicate(4, sort(sample(1:9, 6)))),
        x = round(stats::rnorm(24), 2)
      )
    })
    panel$x[c(3, 11)] <- NA
    out <- dplyr::mutate(
      panel,
      lag1 = stata_lag(x, time = time),
      lag2 = stata_lag(x, 2, time = time),
      lead1 = stata_lead(x, time = time),
      diff1 = stata_diff(x, time = time),
      .by = id
    )
    lookup <- function(shift) {
      key <- paste(panel$id, panel$time + shift)
      panel$x[match(key, paste(panel$id, panel$time))]
    }
    expect_identical(out$lag1, lookup(-1))
    expect_identical(out$lag2, lookup(-2))
    expect_identical(out$lead1, lookup(1))
    expect_equal(out$diff1, panel$x - lookup(-1), tolerance = 1e-12)
  }
})

test_that("stress invariant: dropping duplicates leaves an identifying key", {
  skip_if_not_installed("withr")
  for (seed in stress_seeds) {
    d <- stress_random_frame(seed)
    dropped <- duplicates_drop(d, k, g, .force = TRUE)
    expect_identical(nrow(dropped), nrow(dplyr::distinct(d, k, g)))
    expect_message(isid(dropped, k, g, .missing = TRUE))
    expect_identical(
      sum(duplicates_tag(d, k, g)$dup > 0),
      sum(
        duplicated(d[c("k", "g")]) | duplicated(d[c("k", "g")], fromLast = TRUE)
      )
    )
  }
})

test_that("stress invariant: many-to-one merges keep every master row", {
  skip_if_not_installed("withr")
  for (seed in stress_seeds) {
    d <- stress_random_frame(seed)
    d <- d[!is.na(d$k), ]
    using <- tibble::tibble(k = c(1L, 2L, 4L), label = c("one", "two", "four"))
    merged <- stata_merge(
      d,
      using,
      relationship = "m:1",
      by = "k",
      keep = c("master", "match"),
      report = FALSE
    )
    expect_identical(nrow(merged), nrow(d))
    expect_identical(merged$label, using$label[match(merged$k, using$k)])
  }
})

# Independent references ---------------------------------------------------

test_that("stress invariant: row functions match base R references", {
  skip_if_not_installed("withr")
  m <- withr::with_seed(20261027L, {
    m <- matrix(round(stats::rnorm(60, 0, 10)), ncol = 3)
    m[sample.int(60, 15)] <- NA
    m[1, ] <- NA
    m[2, ] <- c(Inf, 1, NA)
    m[3, ] <- c(5, 5, 5)
    m
  })
  d <- tibble::tibble(a = m[, 1], b = m[, 2], c = m[, 3])
  ref <- function(f, empty) {
    apply(m, 1, function(v) {
      v <- v[!is.na(v)]
      if (length(v)) f(v) else empty
    })
  }
  out <- dplyr::mutate(
    d,
    mean = row_mean(a, b, c),
    sum = row_sum(a, b, c),
    min = row_min(a, b, c),
    max = row_max(a, b, c),
    median = row_median(a, b, c),
    sd = row_sd(a, b, c),
    var = row_var(a, b, c),
    miss = row_miss(a, b, c),
    non_miss = row_non_miss(a, b, c),
    nvals = row_nvals(a, b, c)
  )
  expect_equal(out$mean, ref(mean, NA_real_))
  expect_equal(out$sum, ref(sum, 0))
  expect_equal(out$min, ref(min, NA_real_))
  expect_equal(out$max, ref(max, NA_real_))
  expect_equal(out$median, ref(stats::median, NA_real_))
  spread <- function(v) if (length(v) > 1L) stats::var(v) else NA_real_
  expect_equal(out$var, ref(spread, NA_real_))
  expect_equal(out$sd, sqrt(ref(spread, NA_real_)))
  expect_identical(out$miss, as.integer(rowSums(is.na(m))))
  expect_identical(out$non_miss, as.integer(rowSums(!is.na(m))))
  expect_identical(
    out$nvals,
    as.integer(ref(function(v) length(unique(v)), 0L))
  )
})

test_that("stress invariant: quantile codes are monotone and bounded", {
  skip_if_not_installed("withr")
  for (seed in stress_seeds) {
    d <- stress_random_frame(seed)
    for (k in c(2L, 3L, 5L, 10L)) {
      codes <- suppressWarnings(xtile(d$x, k))
      expect_identical(is.na(codes), is.na(d$x))
      ok <- !is.na(d$x)
      ord <- order(d$x[ok])
      expect_false(is.unsorted(as.integer(codes[ok])[ord]))
      expect_lte(max(as.integer(codes), na.rm = TRUE), k)
      # Equal values share a code.
      expect_identical(
        lengths(tapply(as.integer(codes[ok]), d$x[ok], unique)),
        rep(1L, length(unique(d$x[ok]))),
        ignore_attr = TRUE
      )
    }
  }
})

test_that("stress invariant: cut_breaks() codes match findInterval()", {
  skip_if_not_installed("withr")
  for (seed in stress_seeds) {
    x <- stress_random_frame(seed)$x
    breaks <- c(5, 10, 12.5)
    codes <- as.integer(cut_breaks(x, breaks = breaks))
    expect_identical(codes, findInterval(x, breaks) + 1L)
    widths <- cut_length(x, 4)
    ok <- !is.na(x)
    expect_false(is.unsorted(as.integer(widths[ok])[order(x[ok])]))
  }
})

# Session settings ---------------------------------------------------------

test_that("stress invariant: results do not depend on warn or collation", {
  skip_if_not_installed("withr")
  d <- stress_random_frame(20261027L)
  calls <- function() {
    list(
      summ(d, x, y, .detail = TRUE),
      tab(d, s),
      tab2(d, s, g),
      fre(d, f),
      corr(d, x, y),
      dplyr::mutate(d, q = xtile(x, 3), m = row_mean(x, y), z = std(x))
    )
  }
  reference <- calls()
  expect_identical(withr::with_options(list(warn = 2), calls()), reference)
  expect_identical(withr::with_collate("C", calls()), reference)
  expect_identical(
    withr::with_options(
      list(digits = 3, scipen = 100, OutDec = ","),
      calls()
    ),
    reference
  )
})

# Regressions for defects these invariants found.

test_that("S-006 tostring() keeps 15 significant digits for large values", {
  x <- c(1e100, -1e200, 1e308, 123456789012345678901234, .Machine$double.xmax)
  out <- tostring(x)
  expect_identical(out[[1]], paste0("1", strrep("0", 100)))
  expect_identical(out[[2]], paste0("-1", strrep("0", 200)))
  expect_identical(
    out[[4]],
    paste0("123456789012346", strrep("0", 9))
  )
  expect_identical(out[[5]], paste0("179769313486232", strrep("0", 294)))
  digits <- nchar(gsub("^-|0+$", "", out))
  expect_true(all(digits <= 15))
  # Fixed and exponential parsing can round differently on ARM. Check each
  # magnitude separately so large values cannot mask errors in smaller ones.
  for (i in seq_len(4L)) {
    expect_equal(
      destring(out[[i]]),
      as.numeric(sprintf("%.14e", x[[i]])),
      tolerance = 1e-14
    )
  }
  tiny <- tostring(c(1.234e-10, -2e-7, 5e-324))
  expect_identical(tiny[1:2], c("0.0000000001234", "-0.0000002"))
  # Text retains the subnormal's digits even when base R's parser underflows.
  expect_identical(
    tiny[[3]],
    paste0("0.", strrep("0", 323), "494065645841247")
  )
})

test_that("S-007 tostring() and interval labels ignore OutDec", {
  skip_if_not_installed("withr")
  withr::local_options(OutDec = ",")
  x <- c(1.5e-10, 2.5, 1e20)
  expect_identical(
    tostring(x),
    c("0.00000000015", "2.5", "100000000000000000000")
  )
  expect_identical(destring(tostring(x)), x)
  expect_identical(
    levels(cut_breaks(c(0.5, 1.5, 2.5), breaks = 1.25)),
    c("[0.5,1.25)", "[1.25,2.5]")
  )
  expect_identical(
    levels(xtile(c(2.8, 6.6, 12.6, 22), 2)),
    c("[2.8,9.6]", "(9.6,22]")
  )
  # The caller's option is restored.
  expect_identical(getOption("OutDec"), ",")
})
