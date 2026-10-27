# stata_recode() against Stata's `recode` (data-raw/stata-parity/recode.do).
output <- stata_fixture("recode-output")
x <- output$x

test_that("stata_recode() matches Stata's recode rules", {
  expect_stata_equal(stata_recode(x, 1:5 ~ 1, 6:10 ~ 2), output$r1, "ranges")
  expect_stata_equal(
    stata_recode(x, 1:5 ~ 1, 6:10 ~ 2, .default = NA),
    output$r2,
    "else = ."
  )
  expect_stata_equal(
    stata_recode(x, min:5 ~ 0, 6:max ~ 1, NA ~ 9),
    output$r3,
    "min, max and missing"
  )
  expect_stata_equal(stata_recode(x, 1 ~ 2, 2 ~ 1), output$r4, "swap")
  expect_stata_equal(
    stata_recode(x, 1:5 ~ 1, 3 ~ 2),
    output$r5,
    "first rule wins"
  )
  expect_stata_equal(stata_recode(x, c(1, 3, 7) ~ 0), output$r6, "value set")
  expect_stata_equal(stata_recode(x, 9 ~ NA), output$r7, "code to missing")
  expect_stata_equal(stata_recode(x, NA ~ 0), output$r8, "missing to code")
  expect_stata_equal(
    stata_recode(x, c(1, 3:5) ~ 1, c(-3, 0) ~ 0),
    output$r9,
    "mixed values and ranges"
  )
})

test_that("stata_recode() labels codes like Stata's (rule = code \"label\")", {
  labelled <- stata_recode(x, Low = min:5 ~ 1, High = 6:max ~ 2)
  expect_stata_equal(as.numeric(labelled), output$r10, "labelled codes")
  decoded <- as.character(haven::as_factor(labelled, levels = "labels"))
  expected <- output$r10_label
  coded <- !is.na(expected)
  expect_identical(decoded[coded], expected[coded])
})
