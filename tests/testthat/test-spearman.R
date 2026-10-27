test_that("spearman() uses one complete sample unless .pairwise = TRUE", {
  out <- spearman(lifeexp, lexp, gnppc, safewater)
  expect_named(out, c("var1", "var2", "r", "n", "p"))
  ok <- stats::complete.cases(lifeexp[c("lexp", "gnppc", "safewater")])
  expect_identical(out$n, rep(sum(ok), 3L))
  expect_equal(
    out$r[[1]],
    stats::cor(lifeexp$lexp[ok], lifeexp$gnppc[ok], method = "spearman")
  )
  expect_identical(
    out,
    pwcorr(
      lifeexp,
      lexp,
      gnppc,
      safewater,
      .method = "spearman",
      .listwise = TRUE
    )
  )
  expect_identical(
    spearman(lifeexp, lexp, gnppc, safewater, .pairwise = TRUE),
    pwcorr(lifeexp, lexp, gnppc, safewater, .method = "spearman")
  )
})

test_that("spearman() supports groups, the wide layout and adjustment", {
  grouped <- spearman(lifeexp, lexp, gnppc, .by = region)
  expect_named(grouped, c("region", "var1", "var2", "r", "n", "p"))
  expect_identical(
    spearman(dplyr::group_by(lifeexp, region), lexp, gnppc),
    grouped
  )
  wide <- spearman(lifeexp, lexp, gnppc, safewater, .wide = TRUE)
  expect_named(wide, c("variable", "lexp", "gnppc", "safewater"))
  long <- spearman(lifeexp, lexp, gnppc, safewater)
  expect_equal(wide$lexp[2:3], long$r[1:2])
  sidak <- spearman(lifeexp, lexp, gnppc, safewater, .adjust = "sidak")
  expect_equal(sidak$p, pmin(1, 1 - (1 - long$p)^3))
})

test_that("spearman() p-values fall back to the normal approximation", {
  # Three observations: Stata uses sqrt(n - 1) * rho with a normal reference.
  d <- tibble::tibble(x = c(1, 2, 3), y = c(1, 3, 2))
  out <- spearman(d, x, y)
  expect_equal(out$p, 2 * stats::pnorm(-sqrt(2) * 0.5))
  # Stata 19.5 reports Prob = .0028581234031695 for a perfect correlation of
  # six observations: the fitted beta range is wider than the attainable one.
  perfect <- spearman(tibble::tibble(x = 1:6, y = c(2, 4, 6, 8, 10, 12)), x, y)
  expect_identical(perfect$r, 1)
  expect_equal(perfect$p, 0.0028581234031695192, tolerance = 1e-12)
  # Stata reports rho = 1 for a constant variable; tidystata returns NA.
  constant <- spearman(tibble::tibble(x = 1:5, y = 1), x, y)
  expect_true(is.na(constant$r))
  expect_true(is.na(constant$p))
})

test_that("spearman() reports invalid input", {
  d <- tibble::tibble(x = c(1, 2, 3), y = c(2, 1, 3), s = c("a", "b", "c"))
  expect_snapshot(error = TRUE, {
    spearman(d, x, y, .pairwise = NA)
    spearman(d, x, s)
    spearman(d, x, y, .wide = TRUE, .adjust = "bonferroni")
    spearman(d, x, y, .adjust = "holm")
  })
})


test_that("spearman() retains rho but omits inference for two observations", {
  out <- spearman(data.frame(x = c(1, 2), y = c(2, 1)), x, y)
  expect_identical(out$n, 2L)
  expect_equal(out$r, -1)
  expect_true(is.na(out$p))
})
