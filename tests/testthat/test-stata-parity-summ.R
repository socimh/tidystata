# summ() and tabstat() against Stata's `summarize, detail` and `_pctile`
# (data-raw/stata-parity/summ.do).
input <- stata_fixture("summ-input")
reference <- stata_fixture("summ-output")
stata_names <- c(
  n = "N",
  mean = "mean",
  sd = "sd",
  skew = "skewness",
  kurtosis = "kurtosis",
  min = "min",
  max = "max",
  sum = "sum",
  p1 = "p1",
  p5 = "p5",
  p10 = "p10",
  p25 = "p25",
  median = "p50",
  p75 = "p75",
  p90 = "p90",
  p95 = "p95",
  p99 = "p99",
  p2.5 = "p2_5",
  p30 = "p30",
  p33 = "p33",
  p66.6 = "p66_6"
)

summ_like_stata <- function(data, wt, ...) {
  if (wt == "none") {
    return(summ(data, x, .stat = names(stata_names), ...))
  }
  summ(
    data,
    x,
    .stat = names(stata_names),
    .wt = !!rlang::sym(wt),
    .wt_type = if (wt == "fw") "frequency" else "analytic",
    ...
  )
}

test_that("summ() matches summarize, detail by group and weight type", {
  for (wt in c("none", "fw", "aw")) {
    expected <- reference[reference$wt == wt, ]
    out <- summ_like_stata(input, wt, .by = g)
    expect_identical(out$g, expected$g)
    for (statistic in names(stata_names)) {
      expect_stata_equal(
        out[[statistic]],
        expected[[stata_names[[statistic]]]],
        label = paste(wt, statistic)
      )
    }
  }
})

test_that("summ() matches Stata one group at a time", {
  # A single group takes the per-group code path rather than the batched one.
  for (wt in c("none", "fw", "aw")) {
    for (group in unique(input$g)) {
      expected <- reference[reference$wt == wt & reference$g == group, ]
      out <- summ_like_stata(input[input$g == group, ], wt)
      for (statistic in names(stata_names)) {
        expect_stata_equal(
          out[[statistic]],
          expected[[stata_names[[statistic]]]],
          label = paste(wt, group, statistic)
        )
      }
    }
  }
})

test_that("tabstat() uses the same Stata percentiles", {
  out <- tabstat(input, x, .by = g, .stat = c("p10", "median", "p90"))
  expected <- reference[reference$wt == "none", ]
  expect_stata_equal(out$p10, expected$p10)
  expect_stata_equal(out$median, expected$p50)
  expect_stata_equal(out$p90, expected$p90)
})
