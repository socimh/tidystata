# pwcorr() options and spearman() against Stata's `pwcorr, sig obs` with
# aweights, listwise, bonferroni and sidak, and `spearman, stats(rho obs p)`
# with and without pw (data-raw/stata-parity/pwcorr_options.do).
input <- stata_fixture("pwcorr-input")
reference <- stata_fixture("pwcorr-options-output")

test_that("pwcorr() options and spearman() match Stata", {
  cases <- list(
    pwcorr = pwcorr(input, x, y, z, .wt = fw, .wt_type = "analytic"),
    listwise = pwcorr(input, x, y, z, .listwise = TRUE),
    listwise_fw = pwcorr(input, x, y, z, .wt = fw, .listwise = TRUE),
    bonferroni = pwcorr(input, x, y, z, .adjust = "bonferroni"),
    sidak = pwcorr(input, x, y, z, .adjust = "sidak"),
    spearman = spearman(input, x, y, z),
    spearman_pw = spearman(input, x, y, z, .pairwise = TRUE),
    spearman_pw_bon = spearman(
      input,
      x,
      y,
      z,
      .pairwise = TRUE,
      .adjust = "bonferroni"
    ),
    spearman_sidak = spearman(input, x, y, z, .adjust = "sidak")
  )
  for (case in names(cases)) {
    out <- cases[[case]]
    cmd <- sub("_fw$", "", case)
    wt <- if (case == "pwcorr") {
      "aw"
    } else if (case == "listwise_fw") {
      "fw"
    } else {
      "none"
    }
    expected <- reference[reference$cmd == cmd & reference$wt == wt, ]
    expect_identical(nrow(expected), 3L, label = case)
    expect_identical(paste(out$var1, out$var2), paste(expected$v1, expected$v2))
    expect_stata_equal(out$r, expected$rho, label = paste(case, "r"))
    expect_stata_equal(out$p, expected$p, label = paste(case, "p"))
    expect_equal(as.numeric(out$n), expected$n, label = paste(case, "n"))
  }
})

test_that("spearman() matches Stata with ties and small samples", {
  ties <- stata_fixture("spearman-ties-input")
  expected <- stata_fixture("spearman-ties-output")
  out <- rbind(
    spearman(ties, a, b),
    spearman(ties, a, b, .by = g)[c("var1", "var2", "r", "n", "p")]
  )
  expect_stata_equal(out$r, expected$rho, label = "r")
  expect_stata_equal(out$p, expected$p, label = "p")
  expect_equal(as.numeric(out$n), expected$n, label = "n")
})
