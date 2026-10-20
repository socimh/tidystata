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
  europe <- lifeexp[lifeexp$region == 1, ]
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
  expect_error(pwcorr(data, x, y, .wide = NA), "single TRUE or FALSE")
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
  reference <- pwcorr(replicated, x, y)
  expect_equal(weighted$r, reference$r)
  expect_equal(weighted$p, reference$p)
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
