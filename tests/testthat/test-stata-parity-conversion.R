# References produced by data-raw/stata-parity/conversion.do (StataNow 19.5).
conversion_output <- stata_fixture("conversion-output")

test_that("encode matches Stata category codes and decoded text", {
  x <- conversion_output$text
  out <- encode(x)
  expect_identical(vctrs::vec_data(out), conversion_output$code)
  expect_identical(decode(out), conversion_output$decoded)
  expect_identical(
    attr(out, "labels"),
    stats::setNames(1:5, c(" ", "10", "2", "alpha", "beta"))
  )
})

test_that("decode matches Stata labels while retaining unlabelled values", {
  x <- haven::labelled(
    c(10, 20, 99, NA, haven::tagged_na("a"), 10, 20),
    c(No = 10, Yes = 20, Refused = haven::tagged_na("a"))
  )
  text <- decode(x)
  mapped <- !is.na(conversion_output$original_text)
  expect_identical(text[mapped], conversion_output$original_text[mapped])
  # Stata drops the unlabelled code; tidystata retains it by design.
  expect_true(is.na(conversion_output$original_text[3]))
  expect_identical(text[3], "99")
  expect_identical(text[4], NA_character_)
  present <- !is.na(x)
  expect_identical(tostring(x)[present], conversion_output$code_text[present])
  expect_identical(tostring(x)[!present], rep(NA_character_, 2))
  expect_identical(conversion_output$code_text[!present], c(".", ".a"))
})

test_that("fresh encode after decode matches Stata for labelled categories", {
  out <- encode(conversion_output$original_text)
  expect_identical(vctrs::vec_data(out), conversion_output$recoded)
  expect_identical(attr(out, "labels"), c(No = 1L, Refused = 2L, Yes = 3L))
})
