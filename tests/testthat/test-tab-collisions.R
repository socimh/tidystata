# Regression contracts for category names that overlap tabulation metadata.

for (.function_name in c("tab2", "fre2")) {
  test_that(paste(.function_name, "preserves categories matching the row variable name"), {
    fn <- get(.function_name, mode = "function")
    d <- tibble::tibble(
      row = c("A", "A", "A", "B", "B", "B"),
      col = c("row", "row", "other", "row", "third", "third")
    )
    before <- d
    out <- fn(d, row, col)
    expect_identical(names(out)[1], "row \\ col")
    expect_equal(out[[1]][1:2], c("A", "B"))
    expect_equal(out$row[1:2], c(2, 1))
    expect_equal(out$other[1:2], c(1, 0))
    expect_equal(out$third[1:2], c(0, 2))
    if (.function_name == "fre2") {
      expect_equal(out$total, c(3, 3, 6))
      expect_equal(out$row[3], 3)
      expect_equal(out$other[3], 1)
      expect_equal(out$third[3], 2)
    }
    expect_identical(d, before)
  })

  test_that(paste(.function_name, "preserves collisions after flipping variables"), {
    fn <- get(.function_name, mode = "function")
    d <- tibble::tibble(
      first = c("second", "second", "other", "other"),
      second = c("first", "second", "second", "second")
    )
    before <- d
    out <- fn(d, first, second, .flip = TRUE)
    expect_identical(names(out)[1], "second \\ first")
    expect_equal(out[[1]][1:2], c("first", "second"))
    expect_equal(out$second[1:2], c(1, 1))
    expect_equal(out$other[1:2], c(0, 2))
    if (.function_name == "fre2") {
      expect_equal(out$total, c(1, 3, 4))
      expect_equal(out$second[3], 2)
      expect_equal(out$other[3], 2)
    }
    expect_identical(d, before)
  })

  test_that(paste(.function_name, "preserves n and internal-looking categories"), {
    fn <- get(.function_name, mode = "function")
    d <- tibble::tibble(
      row = c("A", "A", "B", "B", "B"),
      col = c("n", "...tmp", "n", "...tmp", "...tmp")
    )
    before <- d
    out <- fn(d, row, col)
    expect_equal(out$n[1:2], c(1, 1))
    expect_equal(out$...tmp[1:2], c(1, 2))
    expect_setequal(names(out)[-1],
      c("n", "...tmp", if (.function_name == "fre2") "total"))
    if (.function_name == "fre2") {
      expect_equal(out$n[3], 2)
      expect_equal(out$...tmp[3], 3)
      expect_equal(out$total, c(2, 3, 5))
    }
    expect_identical(d, before)
  })

  test_that(paste(.function_name, "rejects ambiguous output labels explicitly"), {
    fn <- get(.function_name, mode = "function")
    combined <- tibble::tibble(row = c("A", "B"), col = c("row \\ col", "other"))
    missing <- tibble::tibble(row = c("A", "B"), col = c("NA", NA_character_))
    expect_error(fn(combined, row, col), "Names must be unique")
    expect_error(fn(missing, row, col), "must be unique")
    expect_identical(combined$col, c("row \\ col", "other"))
    expect_identical(missing$col, c("NA", NA_character_))
  })
}

test_that("fre2 rejects a total category before it can overwrite observed counts", {
  d <- tibble::tibble(row = c("A", "A", "B"), col = c("total", "other", "total"))
  before <- d
  expect_error(fre2(d, row, col), "category.*total.*reserved.*Recode")
  expect_error(fre2(d, col, row, .flip = TRUE), "category.*total.*reserved.*Recode")
  expect_identical(d, before)
  out <- tab2(d, row, col)
  expect_equal(out$total, c(1, 1))
  expect_equal(out$other, c(1, 0))
})
