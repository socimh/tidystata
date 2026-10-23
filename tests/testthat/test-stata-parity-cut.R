# xtile() and cut_breaks() against Stata's `xtile` and `egen cut()`
# (data-raw/stata-parity/xtile.do).
input <- stata_fixture("summ-input")
groups <- stata_fixture("xtile-output")
cuts <- stata_fixture("cut-output")

test_that("xtile() matches Stata's xtile, nquantiles()", {
  for (n in c(2, 3, 4, 5, 10)) {
    for (group in unique(input$g)) {
      rows <- input$g == group & !is.na(input$x)
      x <- input$x[rows]
      expected <- groups[[paste0("q", n)]][rows]
      if (anyNA(expected) || length(unique(x)) == 1L) {
        # Stata refuses more groups than observations plus one, and xtile()
        # refuses constant vectors.
        next
      }
      label <- paste("n =", n, "group", group)
      expect_identical(
        suppressWarnings(xtile(x, n, labels = FALSE)),
        as.integer(expected),
        label = label
      )
      for (wt in c("fw", "aw")) {
        expect_identical(
          suppressWarnings(xtile(x, n, labels = FALSE, wt = input[[wt]][rows])),
          as.integer(groups[[paste0(substr(wt, 1, 1), "q", n)]][rows]),
          label = paste(label, wt)
        )
      }
    }
  }
})

test_that("cut_breaks() uses egen cut()'s left-closed intervals", {
  x <- cuts$x
  observed <- !is.na(x)
  # egen cut(), at(0 2.5 5 10) codes each value by the lower break; values
  # outside the breaks are missing in Stata, and fall in the end intervals
  # of cut_breaks(), which always spans the observed range.
  coded <- cut_breaks(x, breaks = c(0, 2.5, 5, 10), labels = FALSE)
  lower <- c(min(x, na.rm = TRUE), 0, 2.5, 5, 10)[coded]
  inside <- observed & !is.na(cuts$c_in)
  expect_identical(lower[inside], cuts$c_in[inside])
  expect_identical(coded[inside] - 2L, as.integer(cuts$c_inic[inside]))
  # Including the end points, egen cut(), at(-10 0 2.5 5 10 40) agrees on
  # every value it codes (it leaves the maximum, 40, missing).
  wide <- cut_breaks(x, breaks = c(-10, 0, 2.5, 5, 10, 40), labels = FALSE)
  inside <- observed & !is.na(cuts$c_ic)
  expect_identical(wide[inside] - 1L, as.integer(cuts$c_ic[inside]))
})
