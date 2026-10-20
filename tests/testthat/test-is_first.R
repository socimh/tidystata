test_that("is_first() flags one row per group like egen tag()", {
  id <- c(2, 1, 2, 1, 3)
  expect_identical(is_first(id), c(TRUE, TRUE, FALSE, FALSE, TRUE))
  year <- c(2001, 2001, 2001, 2002, 2001)
  expect_identical(is_first(id, year), c(TRUE, TRUE, FALSE, TRUE, TRUE))
  expect_identical(sum(is_first(id)), length(unique(id)))
  expect_identical(is_first(c("a", "b", "a")), c(TRUE, TRUE, FALSE))
  expect_identical(is_first(integer()), logical())
})

test_that("is_first() treats missing keys like Stata's tag()", {
  id <- c(1, NA, 1, NA)
  expect_identical(is_first(id), c(TRUE, FALSE, FALSE, FALSE))
  expect_identical(is_first(id, .missing = TRUE), c(TRUE, TRUE, FALSE, FALSE))
  expect_identical(
    is_first(c(1, 1), c(NA, 2)),
    c(FALSE, TRUE)
  )
})

test_that("is_first() without arguments flags the first row of each group", {
  panel <- tibble::tibble(id = c(1, 1, 2, 2, 2), year = 1:5)
  out <- dplyr::mutate(panel, first = is_first(), .by = id)
  expect_identical(out$first, c(TRUE, FALSE, TRUE, FALSE, FALSE))
  grouped <- dplyr::mutate(dplyr::group_by(panel, id), first = is_first())
  expect_identical(grouped$first, out$first)
  expect_identical(
    dplyr::filter(panel, is_first(id))$year,
    c(1L, 3L)
  )
})

test_that("is_first() validates its input", {
  expect_error(is_first(), "Supply the variables")
  expect_error(is_first(1:2, 1:3), "same length")
  expect_error(is_first(1:2, .missing = NA), "single TRUE or FALSE")
})
