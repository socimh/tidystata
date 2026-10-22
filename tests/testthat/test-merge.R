people <- tibble::tibble(id = 1:3, age = c(30, 41, 25))
income <- tibble::tibble(id = c(2L, 3L, 4L), income = c(10, 20, 30))

test_that("s_merge() keeps all rows and records Stata's _merge groups", {
  expect_message(
    out <- s_merge(people, income, "1:1", by = "id"),
    "Not matched"
  )
  expect_identical(out$id, c(1L, 2L, 3L, 4L))
  expect_identical(out$age, c(30, 41, 25, NA))
  expect_identical(out$income, c(NA, 10, 20, 30))
  expect_identical(
    as.character(out$.merge),
    c("master only", "matched", "matched", "using only")
  )
  expect_identical(
    levels(out$.merge),
    c("master only", "using only", "matched")
  )
})

test_that("the merge report counts each group", {
  report <- merge_report(
    c(master = 1L, using = 1L, match = 2L),
    ".merge"
  )
  lines <- strsplit(report, "\n", fixed = TRUE)[[1]]
  expect_match(lines[[3]], "Not matched +2$")
  expect_match(lines[[4]], "from master +1 +\\(\\.merge == \"master only\"\\)")
  expect_match(lines[[7]], "Matched +2 +\\(\\.merge == \"matched\"\\)")
  expect_silent(s_merge(people, income, "1:1", by = "id", report = FALSE))
})

test_that("relationships are checked before joining", {
  members <- tibble::tibble(hh = c(1, 1, 2), person = 1:3)
  households <- tibble::tibble(hh = 1:2, region = c("north", "south"))
  out <- s_merge(members, households, "m:1", by = "hh", report = FALSE)
  expect_identical(out$region, c("north", "north", "south"))
  expect_error(
    s_merge(members, households, "1:1", by = "hh", report = FALSE),
    "does not uniquely identify rows in the master data"
  )
  expect_error(
    s_merge(households, members, "m:1", by = "hh", report = FALSE),
    "does not uniquely identify rows in the using data"
  )
  expect_identical(
    nrow(s_merge(households, members, "1:m", by = "hh", report = FALSE)),
    3L
  )
  expect_error(s_merge(people, income, by = "id"), "Specify the key")
  expect_error(s_merge(people, income, "m:m", by = "id"), "must be one of")
  expect_error(
    s_merge(people, income, "1:1", by = "pid"),
    "not found in `.data`"
  )
})

test_that(".keep, .assert and .generate follow Stata's options", {
  matched <- s_merge(
    people,
    income,
    "1:1",
    by = "id",
    keep = "match",
    report = FALSE
  )
  expect_identical(matched$id, c(2L, 3L))
  expect_error(
    s_merge(
      people,
      income,
      "1:1",
      by = "id",
      assert = "match",
      report = FALSE
    ),
    "found 1 master only row\\(s\\) and 1 using only row\\(s\\)"
  )
  expect_no_error(
    s_merge(
      people,
      income,
      "1:1",
      by = "id",
      assert = c("master", "using", "match"),
      report = FALSE
    )
  )
  bare <- s_merge(
    people,
    income,
    "1:1",
    by = "id",
    generate = NULL,
    report = FALSE
  )
  expect_identical(names(bare), c("id", "age", "income"))
  named <- s_merge(
    people,
    income,
    "1:1",
    by = "id",
    generate = "_merge",
    report = FALSE
  )
  expect_true("_merge" %in% names(named))
  expect_error(
    s_merge(people, income, "1:1", by = "id", generate = "age"),
    "already exists"
  )
  expect_error(
    s_merge(people, income, "1:1", by = "id", keep = "both"),
    "must contain"
  )
})

test_that("keys with different names and shared columns follow Stata", {
  other <- tibble::tibble(
    person = c(1L, 2L),
    age = c(99, 99),
    job = c("a", "b")
  )
  expect_message(
    out <- s_merge(
      people,
      other,
      "1:1",
      by = c(id = "person"),
      report = FALSE
    ),
    "Kept the values from `.data`.*`age`"
  )
  expect_identical(out$age, c(30, 41, 25))
  expect_identical(out$job, c("a", "b", NA))
})

test_that("composite renamed keys keep master order and user marker columns", {
  master <- dplyr::group_by(
    tibble::tibble(
      hh = c(2L, 1L, 2L, 1L),
      wave = c(2L, 1L, 2L, 2L),
      .tidystata_in_master = c("m1", "m2", "m3", "m4")
    ),
    hh
  )
  using <- tibble::tibble(
    household = c(1L, 2L, 3L),
    period = c(1L, 2L, 1L),
    value = c(10, 20, 30),
    .tidystata_in_using = c("u1", "u2", "u3")
  )
  before_master <- master
  before_using <- using
  join <- function(left, right) {
    s_merge(
      left,
      right,
      "m:1",
      by = c(hh = "household", wave = "period"),
      report = FALSE
    )
  }
  match_levels <- c("master only", "using only", "matched")
  expected <- tibble::tibble(
    hh = c(2L, 1L, 2L, 1L, 3L),
    wave = c(2L, 1L, 2L, 2L, 1L),
    .tidystata_in_master = c("m1", "m2", "m3", "m4", NA),
    value = c(20, 10, 20, NA, 30),
    .tidystata_in_using = c("u2", "u1", "u2", NA, "u3"),
    .merge = factor(
      c("matched", "matched", "matched", "master only", "using only"),
      levels = match_levels
    )
  )
  expect_identical(join(master, using), expected)
  expect_identical(
    join(master, using[0, ]),
    tibble::tibble(
      hh = master$hh,
      wave = master$wave,
      .tidystata_in_master = master$.tidystata_in_master,
      value = rep(NA_real_, 4),
      .tidystata_in_using = rep(NA_character_, 4),
      .merge = factor(rep("master only", 4), levels = match_levels)
    )
  )
  expect_identical(
    join(master[0, ], using),
    tibble::tibble(
      hh = using$household,
      wave = using$period,
      .tidystata_in_master = rep(NA_character_, 3),
      value = using$value,
      .tidystata_in_using = using$.tidystata_in_using,
      .merge = factor(rep("using only", 3), levels = match_levels)
    )
  )
  expect_identical(join(master[0, ], using[0, ]), expected[0, ])
  expect_identical(master, before_master)
  expect_identical(using, before_using)
})

test_that("missing keys match each other and containers are kept", {
  left <- data.frame(id = c(NA, 1), x = 1:2)
  right <- data.frame(id = c(NA, 2), y = 3:4)
  out <- s_merge(left, right, "1:1", by = "id", report = FALSE)
  expect_identical(
    as.character(out$.merge),
    c("matched", "master only", "using only")
  )
  expect_false(inherits(out, "tbl_df"))
  skip_if_not_installed("data.table")
  table <- data.table::as.data.table(people)
  expect_s3_class(
    s_merge(table, income, "1:1", by = "id", report = FALSE),
    "data.table"
  )
})

test_that("s_merge() reports invalid input and failed assertions", {
  expect_snapshot(error = TRUE, {
    s_merge(people, 1:3, "1:1", by = "id")
    s_merge(people, income)
    s_merge(people, income, "1:1", by = 1)
    s_merge(people, income, "1:1", by = "id", keep = "both")
    s_merge(people, income, "1:1", by = "missing_key")
    s_merge(people, income, "1:1", by = "id", generate = "age")
    s_merge(
      tibble::tibble(id = c(1, 1)),
      income,
      "1:1",
      by = "id",
      report = FALSE
    )
    s_merge(people, income, "1:1", by = "id", assert = "match")
  })
})
