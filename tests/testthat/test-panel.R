# Expected values come from StataNow 19: `xtset id year` then L.x, L2.x, F.x,
# F2.x, D.x and D2.x (and the delta(5), %tm and %tq variants below).
annual <- tibble::tibble(
  id = c(1, 1, 1, 1, 2, 2, 2, 2, 3, 4, 4, 4, 4),
  year = c(
    2002,
    2001,
    2005,
    2004,
    2003,
    2001,
    2002,
    NA,
    2001,
    2001,
    2002,
    2003,
    2004
  ),
  x = c(12, 10, 18, 15, 33, 31, 32, 99, 40, 1, NA, 4, 9)
)

test_that("s_lag(), s_lead() and s_diff() match Stata's L., F. and D.", {
  out <- dplyr::mutate(
    annual,
    l1 = s_lag(x, time = year),
    l2 = s_lag(x, 2, time = year),
    f1 = s_lead(x, time = year),
    f2 = s_lead(x, 2, time = year),
    d1 = s_diff(x, time = year),
    d2 = s_diff(x, 2, time = year),
    .by = id
  )
  expect_identical(out$l1, c(10, NA, 15, NA, 32, NA, 31, NA, NA, NA, 1, NA, 4))
  expect_identical(out$l2, c(NA, NA, NA, 12, 31, NA, NA, NA, NA, NA, NA, 1, NA))
  expect_identical(out$f1, c(NA, 12, NA, 18, NA, 32, 33, NA, NA, NA, 4, 9, NA))
  expect_identical(out$f2, c(15, NA, NA, NA, NA, 33, NA, NA, NA, 4, 9, NA, NA))
  expect_identical(out$d1, c(2, NA, 3, NA, 1, NA, 1, NA, NA, NA, NA, NA, 5))
  expect_identical(out$d2, c(NA, NA, NA, NA, 0, NA, NA, NA, NA, NA, NA, NA, NA))
  # Grouped data give the same result as .by.
  grouped <- dplyr::mutate(
    dplyr::group_by(annual, id),
    l1 = s_lag(x, time = year)
  )
  expect_identical(grouped$l1, out$l1)
  # dplyr::lag() would use the 2002 value as the lag of 2004.
  expect_false(identical(
    dplyr::lag(annual$x[order(annual$id, annual$year)])[[4]],
    NA_real_
  ))
})

test_that("delta and Date units match Stata's delta(), %tm and %tq", {
  fives <- tibble::tibble(
    id = c(1, 1, 1, 2, 2, 2),
    year = c(2000, 2005, 2015, 2000, 2010, 2005),
    x = c(1, 3, 8, 2, 7, 4)
  )
  out <- dplyr::mutate(
    fives,
    l1 = s_lag(x, time = year, delta = 5),
    f1 = s_lead(x, time = year, delta = 5),
    d1 = s_diff(x, time = year, delta = 5),
    .by = id
  )
  expect_identical(out$l1, c(NA, 1, NA, NA, 4, 2))
  expect_identical(out$f1, c(3, NA, NA, 4, NA, 7))
  expect_identical(out$d1, c(NA, 2, NA, NA, 3, 2))

  monthly <- tibble::tibble(
    id = c(1, 1, 1, 1, 2, 2, 2, 2),
    date = as.Date(c(
      "2024-01-31",
      "2024-02-29",
      "2024-03-01",
      "2024-05-15",
      "2023-12-31",
      "2024-01-01",
      "2024-03-31",
      "2024-04-30"
    )),
    x = c(5, 7, 4, 6, 1, 2, 3, 5)
  )
  out <- dplyr::mutate(
    monthly,
    l1 = s_lag(x, time = date, unit = "month"),
    f1 = s_lead(x, time = date, unit = "month"),
    d1 = s_diff(x, time = date, unit = "month"),
    .by = id
  )
  expect_identical(out$l1, c(NA, 5, 7, NA, NA, 1, NA, 3))
  expect_identical(out$f1, c(7, 4, NA, NA, 2, NA, 5, NA))
  expect_identical(out$d1, c(NA, 2, -3, NA, NA, 1, NA, 2))

  quarterly <- tibble::tibble(
    id = c(1, 1, 1, 2, 2, 2),
    date = as.Date(c(
      "2023-12-31",
      "2024-01-15",
      "2024-06-30",
      "2024-02-01",
      "2024-05-31",
      "2024-08-31"
    )),
    x = c(2, 3, 5, 10, 11, 15)
  )
  out <- dplyr::mutate(
    quarterly,
    l1 = s_lag(x, time = date, unit = "quarter"),
    l2 = s_lag(x, 2, time = date, unit = "quarter"),
    f1 = s_lead(x, time = date, unit = "quarter"),
    .by = id
  )
  expect_identical(out$l1, c(NA, 2, 3, NA, 10, 11))
  expect_identical(out$l2, c(NA, NA, 2, NA, NA, 10))
  expect_identical(out$f1, c(3, 5, NA, 11, 15, NA))
})

test_that("Date days, weeks and years compare whole periods", {
  days <- as.Date(c("2024-03-01", "2024-02-29", "2024-03-03"))
  expect_identical(s_lag(1:3, time = days), c(2L, NA, NA))
  # Monday 2024-03-04 starts a new week; Sunday 2024-03-03 ends the last.
  weeks <- as.Date(c("2024-02-26", "2024-03-03", "2024-03-04"))
  expect_error(s_lag(1:3, time = weeks, unit = "week"), "Repeated time")
  expect_identical(
    s_lag(1:2, time = weeks[c(1, 3)], unit = "week"),
    c(NA, 1L)
  )
  years <- as.Date(c("2023-12-31", "2024-01-01"))
  expect_identical(s_lead(c(5, 6), time = years, unit = "year"), c(6, NA))
})

test_that("panel operators keep the type of x and handle edge cases", {
  time <- c(3, 1, 2)
  expect_identical(s_lag(c("c", "a", "b"), time = time), c("b", NA, "a"))
  f <- factor(c("c", "a", "b"))
  expect_identical(s_lag(f, time = time), factor(c("b", NA, "a"), levels(f)))
  labelled <- haven::labelled(c(3, 1, 2), c(low = 1), label = "Score")
  expect_identical(
    s_lag(labelled, time = time),
    haven::labelled(c(2, NA, 1), c(low = 1), label = "Score")
  )
  expect_identical(
    s_lead(labelled, time = time),
    haven::labelled(c(NA, 2, 3), c(low = 1), label = "Score")
  )
  expect_identical(s_lag(1:3, 0, time = time), 1:3)
  expect_identical(s_diff(c(3, 1, 2), 0, time = time), c(3, 1, 2))
  expect_identical(s_diff(c(TRUE, FALSE), time = 1:2), c(NA, -1))
  expect_identical(s_lag(numeric(), time = numeric()), numeric())
  expect_identical(s_lag(c(1, 2), time = c(NA, 1)), c(NA_real_, NA_real_))
  expect_identical(
    s_lag(1:2, time = haven::labelled(c(2001, 2002))),
    c(NA, 1L)
  )
  # SPSS user-missing codes are missing times and missing values.
  expect_identical(
    s_lag(
      1:3,
      time = haven::labelled_spss(c(2001, 2002, 9999), na_values = 9999)
    ),
    c(NA, 1L, NA)
  )
  expect_identical(
    s_diff(haven::labelled_spss(c(10, 12, 99), na_values = 99), time = 1:3),
    c(NA, 2, NA)
  )
})

test_that("shifts preserve SPSS metadata without changing the input", {
  x <- haven::labelled_spss(
    c(10, 99, 12),
    labels = c(start = 10, refused = 99),
    na_values = 99,
    label = "Survey score"
  )
  before <- x
  expected <- x[c(NA_integer_, 1L, 2L)]
  expect_identical(s_lag(x, time = 1:3), expected)
  expect_identical(s_lead(x, time = 1:3), x[c(2L, 3L, NA_integer_)])
  expect_identical(x, before)
})

test_that("daylight-saving transitions follow documented local periods", {
  # Construct instants in UTC so skipped and repeated local hours are unambiguous.
  spring <- as.POSIXct(
    c("2024-03-10 06:30:00", "2024-03-10 07:30:00", "2024-03-10 08:30:00"),
    tz = "UTC"
  )
  attr(spring, "tzone") <- "America/New_York"
  expect_identical(s_lag(1:3, time = spring, unit = "hour"), c(NA, NA, 2L))
  expect_identical(s_lead(1:3, time = spring, unit = "hour"), c(NA, 3L, NA))
  expect_identical(s_lag(1:3, time = spring, delta = 3600), c(NA, 1L, 2L))
  autumn <- as.POSIXct(
    c("2024-11-03 05:30:00", "2024-11-03 06:30:00"),
    tz = "UTC"
  )
  attr(autumn, "tzone") <- "America/New_York"
  expect_error(s_lag(1:2, time = autumn, unit = "hour"), "Repeated time")
  expect_identical(s_lag(1:2, time = autumn, delta = 3600), c(NA, 1L))
})

test_that("date-times compare local clock periods", {
  # Asia/Kolkata is UTC+5:30, so local hours differ from UTC hours.
  times <- as.POSIXct(
    c("2024-03-01 10:15:00", "2024-03-01 11:40:00", "2024-03-01 13:05:00"),
    tz = "Asia/Kolkata"
  )
  expect_identical(s_lag(1:3, time = times, unit = "hour"), c(NA, 1L, NA))
  expect_identical(s_lead(1:3, time = times, unit = "hour"), c(2L, NA, NA))
  # The default unit is the second.
  expect_identical(s_lag(1:3, time = times), c(NA_integer_, NA, NA))
  expect_identical(
    s_lag(1:3, time = times, unit = "minute", delta = 85),
    c(NA, 1L, 2L)
  )
  expect_error(s_lag(1:3, time = times, unit = "day"), "Repeated time")
  days <- as.POSIXct(c("2024-01-31 23:00", "2024-02-01 01:00"), tz = "UTC")
  expect_identical(s_lag(1:2, time = days, unit = "day"), c(NA, 1L))
  expect_identical(s_lag(1:2, time = days, unit = "month"), c(NA, 1L))
  stamps <- as.POSIXlt(
    c("2024-01-01 00:00:00", "2024-01-01 00:00:05"),
    tz = "UTC"
  )
  expect_identical(s_lag(1:2, time = stamps, delta = 5), c(NA, 1L))
  expect_error(
    s_lag(1:2, time = days, unit = "decade"),
    "must be one of"
  )
})

test_that("period classes need no unit", {
  # zoo's yearmon and yearqtr are the year plus the elapsed fraction of it;
  # they are built directly so that zoo is not needed. tsibble's yearweek,
  # yearmonth and yearquarter go through their as.Date() methods.
  months <- structure(2024 + c(0, 1, 3) / 12, class = "yearmon")
  expect_identical(s_lag(c(5, 7, 4), time = months), c(NA, 5, NA))
  quarters <- structure(c(2023.75, 2024, 2024.5), class = "yearqtr")
  expect_identical(s_lead(c(1, 2, 3), time = quarters), c(2, NA, NA))
  expect_identical(
    s_lag(c(5, 7, 4), time = months, unit = "month"),
    c(NA, 5, NA)
  )
  expect_error(s_lag(1:3, time = months, unit = "day"), "omit `unit`")
})

test_that("ordered factors use level order as the time sequence", {
  waves <- c("Wave 1", "Wave 2", "Wave 3", "Wave 10")
  panel <- tibble::tibble(
    id = c(1, 1, 1, 2, 2),
    # Respondent 1 skipped Wave 2, an unused level for that panel.
    wave = factor(
      c("Wave 3", "Wave 1", "Wave 10", "Wave 1", "Wave 2"),
      levels = waves,
      ordered = TRUE
    ),
    occupation = c("teacher", "clerk", "teacher", "nurse", "nurse")
  )
  out <- dplyr::mutate(
    panel,
    previous = s_lag(occupation, time = wave),
    following = s_lead(occupation, time = wave),
    .by = id
  )
  # Wave 10 follows Wave 3 in level order, unlike in sorted text.
  expect_identical(out$previous, c(NA, NA, "teacher", NA, "nurse"))
  expect_identical(out$following, c("teacher", NA, NA, "nurse", NA))
  expect_identical(
    s_lag(1:2, time = factor(c("a", NA), ordered = TRUE)),
    c(NA_integer_, NA)
  )
  expect_identical(
    s_lag(
      1:3,
      time = factor(c("a", "c", "e"), letters[1:5], ordered = TRUE),
      delta = 2
    ),
    c(NA, 1L, 2L)
  )
  expect_error(
    s_lag(1:2, time = factor(c("a", "b"), ordered = TRUE), unit = "month"),
    "dates and date-times"
  )
})

test_that("s_diff() of dates and date-times gives difftimes", {
  dates <- as.Date(c("2024-01-01", "2024-01-11", "2024-02-01"))
  out <- s_diff(dates, time = 1:3)
  expect_s3_class(out, "difftime")
  expect_identical(units(out), "days")
  expect_equal(as.numeric(out), c(NA, 10, 21))
  expect_equal(as.numeric(s_diff(dates, 2, time = 1:3)), c(NA, NA, 11))
  stamps <- as.POSIXct(c("2024-01-01 00:00", "2024-01-01 01:30"), tz = "UTC")
  out <- s_diff(stamps, time = 1:2)
  expect_identical(units(out), "secs")
  expect_equal(as.numeric(out), c(NA, 5400))
  gaps <- as.difftime(c(1, 4), units = "hours")
  expect_equal(as.numeric(s_diff(gaps, time = 1:2)), c(NA, 3))
})

test_that("panel operators validate their input", {
  expect_error(s_lag(1:3), "`time` must be supplied")
  expect_error(s_lag(1:3, time = 1:2), "same length")
  # Without the panel identifier, years repeat across panels.
  expect_error(
    dplyr::mutate(annual, l1 = s_lag(x, time = year)),
    "Supply the panel identifier"
  )
  # With it, the hint points to the repeats instead.
  repeated <- tibble::tibble(id = 1, year = c(2001, 2001), x = 1:2)
  expect_error(
    dplyr::mutate(repeated, l1 = s_lag(x, time = year), .by = id),
    "once per panel"
  )
  expect_error(s_lag(1:2, time = c("a", "b")), "Convert it first")
  expect_error(
    s_lag(1:2, time = factor(c("W1", "W2"))),
    "levels need not be in time order"
  )
  expect_error(s_lag(1:2, time = list(1, 2)), "not a list")
  expect_error(s_lag(1:2, time = 1:2, unit = "month"), "dates and date-times")
  expect_error(
    s_lag(1:2, time = as.Date(c("2024-01-01", "2024-02-01")), unit = "decade"),
    "must be one of"
  )
  expect_error(
    s_lag(1:2, -1, time = 1:2),
    "whole number larger than or equal to 0"
  )
  expect_error(
    s_lead(1:2, 1.5, time = 1:2),
    "whole number larger than or equal to 0"
  )
  expect_error(s_lag(1:2, time = 1:2, delta = 0), "must be positive")
  expect_error(
    s_diff(letters[1:2], time = 1:2),
    "must be a numeric or logical vector"
  )
})

test_that("lags of distinct times match the earlier time exactly", {
  x <- c(10, 12, 15, 13, 20, 9)
  times <- list(
    c(2001, 2002, 2004, 2003, 2005, 2000),
    c(-Inf, 1, 2, 3, 4, Inf),
    c(-1, -0, 1, 2.5, 3.5, 7),
    c(1, NA, 2, 3, NaN, 4)
  )
  for (time in times) {
    expect_identical(
      s_lag(x, time = time),
      x[match(time - 1, time, incomparables = NA)]
    )
    expect_identical(
      s_lead(x, 2, time = time),
      x[match(time + 2, time, incomparables = NA)]
    )
    previous <- match(time - 1, time, incomparables = NA)
    once <- x - x[previous]
    expect_identical(s_diff(x, 2, time = time), once - once[previous])
  }
  expect_error(s_lag(1:3, time = c(-0, 0, 1)), "such as 0")
  expect_error(s_lag(1:4, time = c(3, 1, 2, 1)), "such as 1")
  expect_error(s_diff(1:3, 0, time = c(1, 1, 2)), "Repeated time values")
})

test_that("panel operators report invalid input", {
  expect_snapshot(error = TRUE, {
    s_lag(1:3)
    s_lag(1:3, n = -1, time = 1:3)
    s_lag(1:3, time = 1:2)
    s_lag(1:3, time = 1:3, delta = 0)
    s_lag(1:3, time = c(1, 1, 2))
    s_lag(1:3, time = c("a", "b", "c"))
    s_lag(1:3, time = factor(c("a", "b", "c")))
    s_lag(1:3, time = 1:3, unit = "day")
    s_diff(letters[1:3], time = 1:3)
  })
})
