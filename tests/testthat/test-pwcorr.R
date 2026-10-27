test_that("pwcorr() uses pairwise deletion and matches cor.test()", {
  out <- pwcorr(lifeexp, lexp, gnppc, safewater)
  expect_named(out, c("var1", "var2", "r", "n", "p"))
  expect_identical(out$var1, c("lexp", "lexp", "gnppc"))
  expect_identical(out$var2, c("gnppc", "safewater", "safewater"))
  for (k in seq_len(nrow(out))) {
    x <- lifeexp[[out$var1[[k]]]]
    y <- lifeexp[[out$var2[[k]]]]
    reference <- stats::cor.test(x, y)
    expect_equal(out$r[[k]], unname(reference$estimate))
    expect_equal(out$p[[k]], reference$p.value)
    expect_identical(out$n[[k]], sum(!is.na(x) & !is.na(y)))
  }
})

test_that("pwcorr() supports Spearman, the wide layout and groups", {
  spearman <- pwcorr(lifeexp, lexp, gnppc, .method = "spearman")
  ok <- stats::complete.cases(lifeexp$lexp, lifeexp$gnppc)
  expect_equal(
    spearman$r,
    stats::cor(lifeexp$lexp[ok], lifeexp$gnppc[ok], method = "spearman")
  )

  wide <- pwcorr(lifeexp, lexp, gnppc, safewater, .wide = TRUE)
  expect_named(wide, c("variable", "lexp", "gnppc", "safewater"))
  expect_equal(diag(as.matrix(wide[-1])), c(1, 1, 1))
  expect_true(is.na(wide$safewater[[1]]))
  long <- pwcorr(lifeexp, lexp, gnppc, safewater)
  expect_equal(wide$lexp[2:3], long$r[1:2])

  grouped <- pwcorr(lifeexp, lexp, gnppc, .by = region)
  expect_named(grouped, c("region", "var1", "var2", "r", "n", "p"))
  expect_identical(nrow(grouped), length(unique(lifeexp$region)))
  europe <- lifeexp[vctrs::vec_data(lifeexp$region) == 1, ]
  expect_equal(
    grouped$r[[1]],
    stats::cor(europe$lexp, europe$gnppc, use = "complete.obs")
  )
  expect_identical(
    pwcorr(dplyr::group_by(lifeexp, region), lexp, gnppc),
    grouped
  )
  grouped_wide <- pwcorr(lifeexp, lexp, gnppc, .by = region, .wide = TRUE)
  expect_identical(nrow(grouped_wide), 2L * nrow(grouped))
})

test_that("pwcorr() selects numeric columns and validates input", {
  data <- tibble::tibble(
    id = c("a", "b", "c", "d"),
    x = c(1, 2, 3, 4),
    y = c(2, 1, 4, 3),
    flag = c(TRUE, FALSE, TRUE, TRUE)
  )
  # Without a selection, non-numeric columns are skipped and logicals used.
  expect_identical(
    pwcorr(data)$var1,
    c("x", "x", "y")
  )
  expect_identical(pwcorr(data)$var2, c("y", "flag", "flag"))
  expect_error(pwcorr(data, x, id), "must be numeric or logical")
  expect_error(pwcorr(data, x), "at least two numeric variables")
  expect_error(pwcorr(data, x, y, .wide = NA), "must be `TRUE` or `FALSE`")
  expect_error(pwcorr(1:3), "must be a data frame")

  constant <- tibble::tibble(x = c(1, 2, 3), y = c(5, 5, 5))
  expect_true(is.na(pwcorr(constant)$r))
  expect_true(is.na(pwcorr(constant)$p))
  perfect <- tibble::tibble(x = c(1, 2, 3), y = c(2, 4, 6))
  expect_equal(pwcorr(perfect)$p, 0)
  two <- tibble::tibble(x = c(1, 2), y = c(2, 1))
  expect_true(is.na(pwcorr(two)$p))

  wide_clash <- tibble::tibble(variable = 1:3, x = c(1, 3, 2))
  expect_error(pwcorr(wide_clash, .wide = TRUE), "rename the variable")
})

test_that("weighted pwcorr() equals replicated data", {
  data <- tibble::tibble(
    x = c(1, 2, 3, 4, NA),
    y = c(2, 1, 4, 3, 5),
    w = c(3, 1, 2, 1, 1)
  )
  replicated <- data[rep(seq_len(nrow(data)), data$w), ]
  weighted <- pwcorr(data, x, y, .wt = w)
  reference <- stats::cor.test(replicated$x, replicated$y)
  expect_equal(weighted$r, unname(reference$estimate))
  expect_equal(weighted$p, reference$p.value)
  expect_equal(weighted$n, 7)
  analytic <- pwcorr(data, x, y, .wt = w, .wt_type = "analytic")
  expect_equal(analytic$r, weighted$r)
  expect_identical(analytic$n, 4L)
  # The weight column is not correlated itself.
  expect_identical(pwcorr(data, .wt = w)$var2, "y")
  expect_error(
    pwcorr(data, x, y, .wt = w, .method = "spearman"),
    "Pearson correlations only"
  )
})

test_that("pwcorr() reports invalid input", {
  d <- tibble::tibble(x = c(1, 2, 3), y = c(2, 1, 3), s = c("a", "b", "c"))
  expect_snapshot(error = TRUE, {
    pwcorr(d, x, y, .wide = NA)
    pwcorr(d, x, s)
    pwcorr(d, x)
    pwcorr(d, x, y, .wt = x, .method = "spearman")
  })
})

test_that("pwcorr() drops SPSS user-missing codes and ranges", {
  data <- tibble::tibble(
    g = c("a", "a", "a", "b", "b", "b", "b"),
    coded = haven::labelled_spss(c(1, 2, 99, 1, 3, 2, 97), na_values = 99),
    ranged = haven::labelled_spss(
      c(2, 1, 4, 98, 1, 3, 4),
      na_range = c(90, 100)
    ),
    y = c(1, 3, 2, 2, 5, 3, 1),
    w = c(2, 1, 1, 3, 1, 2, 1)
  )
  keep <- c(TRUE, TRUE, FALSE, TRUE, TRUE, TRUE, TRUE)
  out <- pwcorr(data, coded, y)
  expect_identical(out$n, 6L)
  expect_equal(out$r, stats::cor(data$y[keep], c(1, 2, 1, 3, 2, 97)))

  both <- pwcorr(data, coded, ranged)
  pair <- c(TRUE, TRUE, FALSE, FALSE, TRUE, TRUE, TRUE)
  expect_identical(both$n, 5L)
  expect_equal(
    both$r,
    stats::cor(c(1, 2, 99, 1, 3, 2, 97)[pair], c(2, 1, 4, 98, 1, 3, 4)[pair])
  )

  grouped <- pwcorr(data, ranged, y, .by = g)
  expect_identical(grouped$n, c(3L, 3L))
  expect_equal(
    grouped$r,
    c(stats::cor(c(2, 1, 4), c(1, 3, 2)), stats::cor(c(1, 3, 4), c(5, 3, 1)))
  )

  weighted <- pwcorr(data, ranged, y, .wt = w)
  rows <- rep(which(c(TRUE, TRUE, TRUE, FALSE, TRUE, TRUE, TRUE)), data$w[-4])
  expect_equal(weighted$n, 8)
  expect_equal(
    weighted$r,
    stats::cor(c(2, 1, 4, 98, 1, 3, 4)[rows], data$y[rows])
  )
})


test_that("weighted pwcorr() ignores zero-weight arithmetic", {
  data <- data.frame(x = c(1, 2, 1e200), y = c(1, 2, 3), w = c(1, 1, 0))
  frequency <- pwcorr(data, x, y, .wt = w)
  expect_equal(frequency$r, stats::cor(data$x[1:2], data$y[1:2]))
  expect_equal(frequency$n, 2)
  expect_true(is.na(frequency$p))
  analytic <- pwcorr(data, x, y, .wt = w, .wt_type = "analytic")
  expect_equal(analytic$r, 1)
  # Analytic n counts complete rows, including the zero-weight row.
  expect_identical(analytic$n, 3L)
  expect_equal(analytic$p, 0)
  expect_equal(pwcorr(data, x, y, .wt = w, .wide = TRUE)$x[2], 1)
})

test_that("analytic pwcorr() is invariant to large common weight scales", {
  data <- data.frame(x = 1:3, y = c(1, 2, 4), w = rep(1e200, 3))
  expected_r <- stats::cor(data$x, data$y)
  statistic <- expected_r * sqrt(1 / (1 - expected_r^2))
  expected_p <- 2 * stats::pt(abs(statistic), df = 1, lower.tail = FALSE)
  for (scale in c(1, 1e108, 1e-200)) {
    out <- pwcorr(data, x, y, .wt = w * scale, .wt_type = "analytic")
    expect_equal(out$r, expected_r)
    expect_equal(out$p, expected_p)
    expect_identical(out$n, 3L)
  }
})

test_that("weighted pwcorr() retains missing and all-zero group counts", {
  data <- data.frame(
    g = rep(c("observed", "zero"), each = 4),
    x = c(1, 2, 3, NA, 1, 2, 3, 4),
    y = c(2, 1, 4, 5, 4, 2, 3, 1),
    w = c(1, 2, 0, 1, 0, 0, 0, NA)
  )
  for (type in c("frequency", "analytic")) {
    expect_message(
      out <- pwcorr(data, x, y, .by = g, .wt = w, .wt_type = type),
      "Excluded 1 row"
    )
    expect_equal(out$n, if (type == "frequency") c(3, 0) else c(3, 3))
    expect_equal(out$r[1], -1)
    expect_true(is.na(out$r[2]))
    expect_true(is.na(out$p[2]))
  }
})


test_that("weighted pwcorr() is invariant to finite variable scales", {
  data <- data.frame(x = c(1, 2, 4), y = c(2, 1, 3), w = c(1, 2, 1))
  rows <- rep(seq_len(nrow(data)), data$w)
  reference <- stats::cor.test(data$x[rows], data$y[rows])
  for (scale in c(1e200, 1e-200)) {
    scaled <- transform(data, x = x * scale, y = y * scale)
    out <- pwcorr(scaled, x, y, .wt = w)
    expect_equal(out$r, unname(reference$estimate))
    expect_equal(out$p, reference$p.value)
    expect_equal(out$n, length(rows))
  }
})


test_that("weighted pwcorr() preserves representable gaps after translation", {
  offsets <- c(0, 1e16)
  for (y in list(c(1, 2, 4), c(2, 5, 3))) {
    x <- c(0, 2, 6)
    expected <- stats::cor(x, y)
    for (x_offset in offsets) {
      for (y_offset in offsets) {
        # Every translated gap remains exactly representable at this offset.
        translated_y <- 2 * y
        data <- data.frame(
          x = x + x_offset,
          y = translated_y + y_offset,
          w = rep(1, 3)
        )
        out <- pwcorr(data, x, y, .wt = w)
        expect_equal(out$r, expected)
        statistic <- expected * sqrt(1 / (1 - expected^2))
        expected_p <- if (abs(expected) >= 1) {
          0
        } else {
          2 * stats::pt(abs(statistic), df = 1, lower.tail = FALSE)
        }
        expect_equal(out$p, expected_p)
        expect_equal(out$n, 3)
      }
    }
  }
})

test_that("weighted pwcorr() handles finite opposite extremes", {
  x <- c(-1, 0, 1)
  y <- c(2, 1, 4)
  data <- data.frame(x = x * 1e308, y = y, w = rep(1, 3))
  expect_equal(pwcorr(data, x, y, .wt = w)$r, stats::cor(x, y))
  data$x[1] <- Inf
  expect_true(is.na(pwcorr(data, x, y, .wt = w)$r))
})


test_that("pwcorr() excludes matrix columns from vector selection", {
  data <- tibble::tibble(
    x = 1:3,
    y = c(3, 1, 2),
    numeric_matrix = matrix(c(1, 2, 3, 3, 2, 1), nrow = 3),
    logical_matrix = matrix(c(TRUE, FALSE, TRUE, FALSE, TRUE, FALSE), nrow = 3)
  )
  expect_error(pwcorr(data, x, numeric_matrix), "must be numeric or logical")
  expect_error(pwcorr(data, x, logical_matrix), "must be numeric or logical")
  expect_identical(pwcorr(data), pwcorr(data, x, y))
})

test_that("pwcorr(.listwise = TRUE) keeps p-values on one common sample", {
  out <- pwcorr(lifeexp, lexp, gnppc, safewater, .listwise = TRUE)
  expect_named(out, c("var1", "var2", "r", "n", "p"))
  common <- corr(lifeexp, lexp, gnppc, safewater)
  expect_identical(out[c("var1", "var2", "r", "n")], common)
  ok <- stats::complete.cases(lifeexp[c("lexp", "gnppc", "safewater")])
  reference <- stats::cor.test(lifeexp$lexp[ok], lifeexp$safewater[ok])
  expect_equal(out$p[[2]], reference$p.value)

  data <- dplyr::mutate(lifeexp, w = dplyr::row_number() %% 3 + 1)
  weighted <- pwcorr(
    data,
    lexp,
    gnppc,
    safewater,
    .wt = w,
    .listwise = TRUE,
    .by = region
  )
  expect_identical(
    weighted[c("region", "var1", "var2", "r", "n")],
    corr(data, lexp, gnppc, safewater, .wt = w, .by = region)
  )
})

test_that("pwcorr(.adjust) counts every pair, as Stata does", {
  d <- tibble::tibble(
    x = c(1, 2, 3, 4, 5, 6),
    y = c(2, 1, 4, 3, 6, 5),
    z = c(1, 1, 1, 1, 1, 1)
  )
  raw <- pwcorr(d, x, y, z)
  expect_true(all(is.na(raw$p[2:3])))
  bonferroni <- pwcorr(d, x, y, z, .adjust = "bonferroni")
  expect_equal(bonferroni$p, pmin(1, 3 * raw$p))
  sidak <- pwcorr(d, x, y, z, .adjust = "sidak")
  expect_equal(sidak$p, pmin(1, 1 - (1 - raw$p)^3))
  expect_identical(bonferroni[c("var1", "var2", "r", "n")], raw[1:4])
})

test_that("pwcorr() validates .listwise and .adjust", {
  d <- tibble::tibble(x = c(1, 2, 3), y = c(2, 1, 3))
  expect_snapshot(error = TRUE, {
    pwcorr(d, x, y, .listwise = "yes")
    pwcorr(d, x, y, .adjust = "holm")
    pwcorr(d, x, y, .wide = TRUE, .adjust = "sidak")
  })
})

test_that("Sidak adjustment preserves very small nonzero p-values", {
  data <- tibble::tibble(x = 1:30, y = 1:30 + rep(c(-1, 1), 15), z = 1)
  raw <- pwcorr(data, x, y)$p
  expect_gt(raw, 0)
  expect_lt(raw, .Machine$double.eps)
  # Adjusting one test is the identity, even below machine epsilon.
  expect_equal(pwcorr(data, x, y, .adjust = "sidak")$p / raw, 1)

  grouped <- dplyr::bind_rows(a = data, b = data, .id = "group")
  out <- pwcorr(grouped, x, y, z, .by = group, .adjust = "sidak")
  # For tiny p, the three-test adjustment is 3p to double precision.
  # Each group includes the two undefined pairs in its own adjustment.
  expect_equal(out$p[c(1, 4)] / raw, c(3, 3))
  expect_true(all(is.na(out$p[c(2, 3, 5, 6)])))
})

test_that("Sidak adjustment retains zero and one p-values", {
  data <- tibble::tibble(x = c(-1, 0, 1), y = c(1, -2, 1), z = x)
  expect_equal(pwcorr(data, .adjust = "sidak")$p, c(1, 0, 1))
})

test_that("weighted correlations retain tiny nonzero variances", {
  data <- tibble::tibble(x = c(0, 1, 2), y = c(1, 0, 2), w = c(1, 1e200, 1))
  # The weighted centered sums tend to Sxx = 2, Syy = 5 and Sxy = 1.
  # At this weight ratio, the correction is below double precision.
  expected <- 1 / sqrt(10)
  for (correlate in list(pwcorr, corr)) {
    out <- correlate(data, x, y, .wt = w, .wt_type = "analytic")
    expect_equal(out$r, expected)
    expect_identical(out$n, 3L)
    if ("p" %in% names(out)) {
      # With n = 3, t = 1/3 has the standard Cauchy distribution.
      expect_equal(out$p, 2 * atan(3) / pi)
    }
    wide <- correlate(data, x, y, .wt = w, .wide = TRUE)
    expect_equal(wide$x[[2]], expected)
  }
})

test_that("native Pearson pairs reproduce the per-pair calculation exactly", {
  set.seed(20261027)
  x <- c(rnorm(30) * 1e-4 + 1e12, NA, 3, Inf)
  y <- c(rnorm(30), 2, NA, 5)
  z <- c(1.7e308, -1.7e308, runif(31))
  constant <- rep(2, 33)
  columns <- list(x = x, y = y, z = z, constant = constant)
  weights <- list(NULL, c(0, runif(31), 0), rep(c(0, 1, 2.5), 11))
  pairs <- utils::combn(length(columns), 2L)
  for (w in weights) {
    for (type in c("frequency", "analytic")) {
      got <- pwcorr_pearson_pairs(columns, w, type)
      expected <- lapply(seq_len(ncol(pairs)), function(k) {
        pwcorr_pair(
          columns[[pairs[1L, k]]],
          columns[[pairs[2L, k]]],
          w,
          "pearson",
          type
        )
      })
      expect_identical(got$r, vapply(expected, `[[`, numeric(1), "r"))
      expect_identical(
        got$n,
        vapply(expected, function(e) as.double(e$n), numeric(1))
      )
      expect_identical(
        pwcorr_pearson_p(got$r, got$n),
        vapply(expected, `[[`, numeric(1), "p")
      )
    }
  }
  empty <- pwcorr_pearson_pairs(
    list(a = double(), b = double()),
    NULL,
    "frequency"
  )
  expect_identical(empty, list(r = NA_real_, n = 0))
})

test_that("native Spearman pairs reproduce the per-pair calculation exactly", {
  set.seed(20261027)
  columns <- list(
    x = c(rnorm(20), NA, 1, 1),
    ties = c(rep(1:3, 7), 2, NA),
    binary = c(rep(c(0, 1, 1), 7), NA, 0),
    big = c(rnorm(22) * 1e10 + 1e15, Inf),
    constant = rep(2, 23)
  )
  pairs <- utils::combn(length(columns), 2L)
  got <- pwcorr_spearman(unname(columns))
  expected <- lapply(seq_len(ncol(pairs)), function(k) {
    pwcorr_pair(
      columns[[pairs[1L, k]]],
      columns[[pairs[2L, k]]],
      NULL,
      "spearman",
      "frequency"
    )
  })
  expect_identical(got$r, vapply(expected, `[[`, numeric(1), "r"))
  expect_identical(
    got$n,
    vapply(expected, function(e) as.double(e$n), numeric(1))
  )
  expect_identical(got$p, vapply(expected, `[[`, numeric(1), "p"))
  small <- pwcorr_spearman(list(c(1, 2, NA, 4), c(2, NA, 3, 1)))
  expect_identical(small$n, 2)
  expect_identical(small$p, NA_real_)
})

test_that("integer and logical columns correlate in place like their doubles", {
  data <- tibble::tibble(
    i = c(3L, 1L, NA, 4L, 1L, 5L, 9L, 2L),
    l = c(TRUE, FALSE, TRUE, NA, TRUE, FALSE, FALSE, TRUE),
    x = c(2.5, 1, 3, 4, NA, 6, 1, 0),
    w = c(1, 2, 1, 3, 1, 2, 1, 0.5)
  )
  doubles <- dplyr::mutate(data, i = as.double(i), l = as.double(l))
  for (args in list(
    list(),
    list(.method = "spearman"),
    list(.wt = quote(w)),
    list(.wt = quote(w), .wt_type = "analytic", .listwise = TRUE),
    list(.wide = TRUE, .method = "spearman")
  )) {
    call <- function(d) rlang::inject(pwcorr(d, i, l, x, !!!args))
    expect_identical(call(data), call(doubles))
  }
  expect_identical(corr(data, i, l, x), corr(doubles, i, l, x))
})

test_that("labelled columns correlate by their codes, with SPSS missing as NA", {
  codes <- c(1L, 2L, 9L, NA, 3L, -1L, 2L, 8L, 4L)
  data <- tibble::tibble(
    spss = haven::labelled_spss(codes, c(Yes = 1L), na_values = 9L),
    tagged = haven::labelled(
      c(1.5, haven::tagged_na("a"), 2, 4, NA, 3, 2.5, 7, 1),
      c(Low = 1.5)
    ),
    x = c(2, 1, 3, 5, 4, 6, 1, 0, 2)
  )
  reference <- dplyr::mutate(
    data,
    spss = labelled_numeric(spss),
    tagged = labelled_numeric(tagged)
  )
  for (method in c("pearson", "spearman")) {
    expect_identical(
      pwcorr(data, .method = method),
      pwcorr(reference, .method = method)
    )
  }
  expect_identical(corr(data), corr(reference))
})
