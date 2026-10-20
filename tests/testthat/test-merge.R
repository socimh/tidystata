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
  expect_silent(s_merge(people, income, "1:1", by = "id", .report = FALSE))
})

test_that("relationships are checked before joining", {
  members <- tibble::tibble(hh = c(1, 1, 2), person = 1:3)
  households <- tibble::tibble(hh = 1:2, region = c("north", "south"))
  out <- s_merge(members, households, "m:1", by = "hh", .report = FALSE)
  expect_identical(out$region, c("north", "north", "south"))
  expect_error(
    s_merge(members, households, "1:1", by = "hh", .report = FALSE),
    "does not uniquely identify rows in the master data"
  )
  expect_error(
    s_merge(households, members, "m:1", by = "hh", .report = FALSE),
    "does not uniquely identify rows in the using data"
  )
  expect_identical(
    nrow(s_merge(households, members, "1:m", by = "hh", .report = FALSE)),
    3L
  )
  expect_error(s_merge(people, income, by = "id"), "Specify the key")
  expect_error(s_merge(people, income, "m:m", by = "id"), "should be one of")
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
    .keep = "match",
    .report = FALSE
  )
  expect_identical(matched$id, c(2L, 3L))
  expect_error(
    s_merge(
      people,
      income,
      "1:1",
      by = "id",
      .assert = "match",
      .report = FALSE
    ),
    "found 1 master only row\\(s\\) and 1 using only row\\(s\\)"
  )
  expect_no_error(
    s_merge(
      people,
      income,
      "1:1",
      by = "id",
      .assert = c("master", "using", "match"),
      .report = FALSE
    )
  )
  bare <- s_merge(
    people,
    income,
    "1:1",
    by = "id",
    .generate = NULL,
    .report = FALSE
  )
  expect_identical(names(bare), c("id", "age", "income"))
  named <- s_merge(
    people,
    income,
    "1:1",
    by = "id",
    .generate = "_merge",
    .report = FALSE
  )
  expect_true("_merge" %in% names(named))
  expect_error(
    s_merge(people, income, "1:1", by = "id", .generate = "age"),
    "already exists"
  )
  expect_error(
    s_merge(people, income, "1:1", by = "id", .keep = "both"),
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
      .report = FALSE
    ),
    "Kept the values from `.data`.*`age`"
  )
  expect_identical(out$age, c(30, 41, 25))
  expect_identical(out$job, c("a", "b", NA))
})

test_that("missing keys match each other and containers are kept", {
  left <- data.frame(id = c(NA, 1), x = 1:2)
  right <- data.frame(id = c(NA, 2), y = 3:4)
  out <- s_merge(left, right, "1:1", by = "id", .report = FALSE)
  expect_identical(
    as.character(out$.merge),
    c("matched", "master only", "using only")
  )
  expect_false(inherits(out, "tbl_df"))
  skip_if_not_installed("data.table")
  table <- data.table::as.data.table(people)
  expect_s3_class(
    s_merge(table, income, "1:1", by = "id", .report = FALSE),
    "data.table"
  )
})
