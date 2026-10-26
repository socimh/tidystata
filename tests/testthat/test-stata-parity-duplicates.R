# duplicates_tag() and duplicates_report() against Stata's `duplicates tag`
# (data-raw/stata-parity/duplicates.do).
reference <- stata_fixture("duplicates-tag")
keys <- reference[c("a", "b")]

test_that("duplicates_tag() matches duplicates tag, with missing values equal", {
  expect_identical(duplicates_tag(keys)$dup, as.integer(reference$dup))
  expect_identical(duplicates_tag(keys, a)$dup, as.integer(reference$dup_a))
})

test_that("duplicates_report() matches duplicates report", {
  # Stata: copies 1, 2, 3 with 3, 2 and 3 observations and 0, 1, 2 surplus.
  report <- duplicates_report(keys)
  expect_equal(report$copies, c(1, 2, 3))
  expect_equal(report$observations, c(3, 2, 3))
  expect_equal(report$surplus, c(0, 1, 2))
})


test_that("isid() agrees with Stata on valid, repeated and missing keys", {
  input <- stata_fixture("isid-input")
  input$code[is.na(input$code)] <- ""
  expected <- stata_fixture("isid-output")
  for (i in seq_len(nrow(expected))) {
    rows <- as.integer(strsplit(expected$rows[[i]], " ", fixed = TRUE)[[1L]])
    keys <- strsplit(expected$keys[[i]], " ", fixed = TRUE)[[1L]]
    data <- input[match(rows, input$row), ]
    if (expected$rc[[i]] == 0L) {
      expect_identical(
        suppressMessages(isid(
          data,
          dplyr::all_of(keys),
          .missing = as.logical(expected$missing[[i]])
        )),
        data,
        info = expected$case[[i]]
      )
    } else {
      expect_identical(expected$rc[[i]], 459L)
      expect_error(
        isid(
          data,
          dplyr::all_of(keys),
          .missing = as.logical(expected$missing[[i]])
        ),
        "should never be missing|not uniquely identify",
        info = expected$case[[i]]
      )
    }
  }
})
