for (.fn in c("tab1", "fre1")) {
  test_that(paste("milestone review retains variable group keys", .fn), {
    d <- data.frame(variable = c("A", "A", "B"), x = c(1, 2, 1))
    fn <- get(.fn, mode = "function")
    for (type in c("list", "tibble")) {
      out <- suppressMessages(fn(d, x, .by = variable, .type = type))
      frame <- if (type == "list") out$x else out
      expect_true(".variable" %in% names(frame))
      expect_setequal(frame$.variable, c("A", "B"))
      if (type == "tibble") expect_true(all(frame$variable == "x"))
    }
    d$.variable <- 1:3
    expect_error(suppressMessages(fn(
      d, tidyselect::all_of(c("x", ".variable")), .by = variable
    )), "Rename fails")
  })
}

.review_row_expected <- list(
  row_mean = c(2, 3, 4), row_sum = c(4, 6, 8),
  row_min = c(1, 2, 3), row_max = c(3, 4, 5),
  row_median = c(2, 3, 4), row_var = rep(2, 3), row_sd = rep(sqrt(2), 3),
  row_unique = rep(2, 3), row_miss = rep(0, 3), row_non_miss = rep(2, 3)
)
for (.fn in names(.review_row_expected)) {
  test_that(paste("milestone review accepts general data frame expressions", .fn), {
    d <- tibble::tibble(x = 1:3, y = 3:5)
    fn <- get(.fn, mode = "function")
    expected <- .review_row_expected[[.fn]]
    expect_equal(dplyr::mutate(d, z = fn(d[c("x", "y")]))$z, expected)
    expect_equal(dplyr::mutate(d, z = fn(identity(dplyr::pick(x, y))))$z,
                 expected)
    counter <- new.env(parent = emptyenv())
    counter$n <- 0L
    producer <- function() {
      counter$n <- counter$n + 1L
      d
    }
    expect_equal(dplyr::mutate(d, z = fn(producer()))$z, expected)
    expect_identical(counter$n, 1L)
    expect_equal(dplyr::mutate(d, z = fn(dplyr::where(is.numeric)))$z,
                 expected)
  })
}
