# Independent Stata output from data-raw/stata-parity/corr.do.
input <- stata_fixture("corr-input")
reference <- stata_fixture("corr-output")

test_that("corr() matches Stata correlate on a common complete sample", {
  for (wt in c("none", "fw", "aw", "aw0")) {
    for (group in -1:1) {
      data <- if (group == -1) input else input[input$g == group, ]
      out <- if (wt == "none") {
        corr(data, x, y, z)
      } else if (wt == "aw0") {
        corr(data, x, y, z, .wt = aw0, .wt_type = "analytic")
      } else {
        corr(
          data,
          x,
          y,
          z,
          .wt = fw,
          .wt_type = if (wt == "fw") "frequency" else "analytic"
        )
      }
      expected <- reference[reference$wt == wt & reference$group == group, ]
      expect_identical(
        paste(out$var1, out$var2),
        paste(expected$v1, expected$v2)
      )
      expect_stata_equal(out$r, expected$rho, label = paste(wt, group, "r"))
      expect_equal(as.numeric(out$n), expected$n, label = paste(wt, group, "n"))
    }
  }
})
