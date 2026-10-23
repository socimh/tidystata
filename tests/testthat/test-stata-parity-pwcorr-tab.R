# pwcorr() and tab2(.chi2 = TRUE) against Stata's `pwcorr, sig obs` and
# `tabulate, chi2 V` (data-raw/stata-parity/pwcorr_tab.do).
input <- stata_fixture("pwcorr-input")
correlations <- stata_fixture("pwcorr-output")
chi2 <- stata_fixture("tab-chi2")

test_that("pwcorr() matches pwcorr, sig obs", {
  for (wt in c("none", "fw")) {
    out <- if (wt == "none") {
      pwcorr(input, x, y, z)
    } else {
      pwcorr(input, x, y, z, .wt = fw)
    }
    expected <- correlations[
      correlations$wt == wt & correlations$v1 < correlations$v2,
    ]
    expect_identical(paste(out$var1, out$var2), paste(expected$v1, expected$v2))
    expect_stata_equal(out$r, expected$rho, label = paste(wt, "r"))
    expect_stata_equal(out$p, expected$p, label = paste(wt, "p"))
    expect_equal(as.numeric(out$n), expected$n, label = paste(wt, "n"))
  }
})

test_that("tab2(.chi2 = TRUE) matches tabulate, chi2 V", {
  # tabulate leaves out rows with a missing category.
  complete <- input[!is.na(input$r) & !is.na(input$c), ]
  for (wt in c("none", "fw")) {
    out <- if (wt == "none") {
      tab2(complete, r, c, .chi2 = TRUE)
    } else {
      tab2(complete, r, c, .chi2 = TRUE, .wt = fw)
    }
    test <- attr(out, "chi2")
    expected <- chi2[chi2$wt == wt, ]
    expect_equal(test$n, expected$N)
    expect_stata_equal(test$statistic, expected$chi2)
    expect_stata_equal(test$p_value, expected$p)
    expect_stata_equal(test$cramers_v, expected$cramers_v)
  }
})
