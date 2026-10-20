test_that("calendar spreads are difftime columns with one unit per column", {
  day <- tibble::tibble(
    g = c(1, 1, 2, 2, 2),
    day = as.Date("2024-01-01") + c(0, 1, 0, 3, 9)
  )
  out <- summ(day, .by = g, .stat = c("sd", "se", "iqr", "mad"))
  for (statistic in c("sd", "se", "iqr", "mad")) {
    expect_s3_class(out[[statistic]], "difftime")
    expect_identical(units(out[[statistic]]), "days")
  }
  expect_equal(as.numeric(out$sd), c(sd(0:1), sd(c(0, 3, 9))))
  # A sub-day spread keeps its value instead of rounding to "0d".
  expect_equal(
    as.numeric(out$se, units = "hours")[[1L]],
    sd(0:1) / sqrt(2) * 24
  )

  stamp <- tibble::tibble(
    g = c(1, 1, 2, 2),
    tm = as.POSIXct("2024-01-01 09:00", tz = "UTC") + c(0, 7200, 0, 3600)
  )
  spread <- summ(stamp, .by = g, .stat = "sd")
  expect_identical(units(spread$sd), "hours")
  expect_equal(
    as.numeric(spread$sd, units = "secs"),
    c(sd(c(0, 7200)), sd(c(0, 3600)))
  )
})

test_that("hms times of day summarise as clock times", {
  skip_if_not_installed("hms")
  clock <- hms::as_hms(c(3600, 5400, 7200, NA))
  out <- summ(clock, .stat = c("n", "mean", "min", "max", "sd"))
  expect_identical(out$type, "time")
  expect_identical(out$mean, "01:30:00")
  expect_identical(out$min, "01:00:00")
  expect_identical(out$max, "02:00:00")
  expect_identical(units(out$sd), "mins")
  expect_equal(as.numeric(out$sd), 30)
  mixed <- summ(tibble::tibble(x = 1:2, clock = hms::as_hms(c(60, 120))))
  expect_named(mixed, c("numeric", "time"))
})

test_that("table mode keeps numeric spreads and records their unit", {
  input <- tibble::tibble(
    x = c(1, 2.123456789, 3),
    day = as.Date("2024-01-01") + 0:2
  )
  out <- summ(input, .mode = "table", .stat = c("mean", "sd"))
  expect_type(out$sd, "double")
  expect_identical(out$type, c("dbl", "date [days]"))
  expect_equal(out$sd, c(sd(input$x), 1))
  expect_identical(out$mean[[1L]], "2.041152")
})

test_that("a piped vector is named value", {
  piped <- c(1, 2, 3) %>% summ(.name = TRUE, .stat = "mean")
  expect_identical(piped$name, "value")
  expect_identical(summ(c(1, 2), .name = TRUE)$name, "c(1, 2)")
})

test_that(".by expressions give an actionable error", {
  input <- tibble::tibble(x = 1:3, y = 4:6)
  expect_error(summ(input, y, .by = x > 1), "Create the grouping column first")
  expect_error(tab(input, y, .by = x > 1), "must select existing columns")
  expect_no_error(summ(input, y, .by = c(x)))
})

test_that("fre(), tab1() and fre1() accept atomic vectors like tab()", {
  x <- c(1, 1, 2, NA)
  expect_identical(
    fre(x),
    fre(tibble::tibble(value = x))
  )
  expect_identical(tab1(x), tab1(tibble::tibble(value = x)))
  expect_identical(fre1(x), fre1(tibble::tibble(value = x)))
  expect_error(fre(x, value), "omit selectors")
  expect_error(fre1(x, .by = value), "omit `.by`")
})

test_that("xtile() accepts logical dummies and labels = TRUE", {
  dummy <- c(TRUE, FALSE, TRUE, FALSE, FALSE)
  expect_identical(
    xtile(dummy, 2, labels = FALSE),
    xtile(as.integer(dummy), 2, labels = FALSE)
  )
  expect_identical(xtile(1:4, 2, labels = TRUE), xtile(1:4, 2))
  expect_error(xtile("a"), "numeric or logical")
})

test_that("grouped xtile() returns group-relative integer codes", {
  data <- dplyr::group_by(
    tibble::tibble(k = rep(1:2, each = 4), a = c(1:4, 11:14)),
    k
  )
  out <- dplyr::mutate(data, q = xtile(a, 2))
  expect_identical(out$q, rep(c(1L, 1L, 2L, 2L), 2))
  ungrouped <- dplyr::mutate(dplyr::ungroup(data), q = xtile(a, 2))
  expect_s3_class(ungrouped$q, "ordered")
})

test_that("row helpers can use grouping columns in grouped mutate()", {
  data <- dplyr::group_by(tibble::tibble(k = c(1, 1, 2), a = c(3, 0, 1)), k)
  out <- dplyr::mutate(data, s = row_sum(k, a), m = row_min(k, a))
  expect_identical(out$s, c(4, 1, 3))
  expect_identical(out$m, pmin(c(1, 1, 2), c(3, 0, 1)))
  expect_error(
    dplyr::mutate(data, s = row_sum(k, missing_column)),
    "missing_column"
  )
})

test_that("slice and print helpers accept sf data", {
  skip_if_not_installed("sf")
  nc <- sf::st_read(system.file("shape/nc.shp", package = "sf"), quiet = TRUE)
  sliced <- slice_headtail(nc, 2)
  expect_s3_class(sliced, "sf")
  expect_identical(nrow(sliced), 2L)
  expect_identical(nrow(slice_interval(nc, 3)), 3L)
  expect_output(print_interval(nc[1:3], n = 2), "rows omitted")
})
