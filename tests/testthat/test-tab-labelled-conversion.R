test_that("as_character handles tagged missing values without a labels attribute", {
  x <- haven::labelled(c(1, haven::tagged_na("a"), NA, 1))
  before <- x
  expect_identical(as_character(x), c("1", NA_character_, NA_character_, "1"))
  expect_identical(x, before)
})
test_that("as_character retains labels when tagged missing values have labels", {
  x <- haven::labelled(c(1, 2, haven::tagged_na("a"), NA), c(one = 1, two = 2))
  before <- x
  expect_identical(
    as_character(x),
    c("one", "two", NA_character_, NA_character_)
  )
  expect_identical(x, before)
})
