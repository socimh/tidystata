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

test_that("is_first() treats SPSS user-missing keys as missing", {
  coded <- haven::labelled_spss(c(1, 99, 1, 99), na_values = 99)
  expect_identical(is_first(coded), c(TRUE, FALSE, FALSE, FALSE))
  expect_identical(
    is_first(coded, .missing = TRUE),
    c(TRUE, TRUE, FALSE, FALSE)
  )
  ranged <- haven::labelled_spss(c(97, 2, 98), na_range = c(90, 100))
  expect_identical(is_first(ranged), c(FALSE, TRUE, FALSE))
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

test_that("no-argument is_first() includes groups with missing keys", {
  data <- tibble::tibble(id = c(1, 1, NA, NA))
  out <- dplyr::mutate(
    data,
    explicit = is_first(id),
    shortcut = is_first(),
    shortcut_missing = is_first(.missing = TRUE),
    .by = id
  )
  expect_identical(out$explicit, c(TRUE, FALSE, FALSE, FALSE))
  expect_identical(out$shortcut, c(TRUE, FALSE, TRUE, FALSE))
  expect_identical(out$shortcut_missing, out$shortcut)
})

test_that("is_first() validates its input", {
  expect_error(is_first(), "Supply the variables")
  expect_error(is_first(1:2, 1:3), "same length")
  expect_error(is_first(1:2, .missing = NA), "must be `TRUE` or `FALSE`")
})

test_that("is_first() reports invalid input", {
  expect_snapshot(error = TRUE, {
    is_first(1:2, .missing = NA)
    is_first()
    is_first(1:2, 1:3)
  })
})

test_that("data-frame arguments contribute each of their columns", {
  data <- tibble::tibble(id = c(1, 1, 2, 2), year = c(1, 1, 1, NA))
  out <- dplyr::mutate(data, first = is_first(pick(id, year)))
  expect_identical(out$first, c(TRUE, FALSE, TRUE, FALSE))
  expect_identical(
    is_first(data, .missing = TRUE),
    is_first(data$id, data$year, .missing = TRUE)
  )
})
