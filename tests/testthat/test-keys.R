panel <- tibble::tibble(
  id = c(1, 1, 2, 2, 3),
  wave = c(1, 2, 1, 1, 1),
  score = c(5, 6, 7, 7, 8)
)

test_that("isid() returns data invisibly when keys are unique", {
  unique_rows <- panel[-4, ]
  expect_invisible(isid(unique_rows, id, wave))
  expect_identical(isid(unique_rows, id, wave), unique_rows)
  expect_identical(isid(dplyr::distinct(panel)), dplyr::distinct(panel))
})

test_that("isid() reports repeated keys and missing values", {
  expect_error(
    isid(panel, id),
    "Variable `id` does not uniquely identify the rows: 2 values appear more than once (4 rows)",
    fixed = TRUE
  )
  expect_error(
    isid(panel, id, wave),
    "1 value appears more than once (2 rows)",
    fixed = TRUE
  )
  missing <- tibble::tibble(id = c(1, NA))
  expect_error(isid(missing, id), "should never be missing")
  expect_invisible(isid(missing, id, .missing = TRUE))
  expect_error(
    isid(tibble::tibble(id = c(NA, NA)), id, .missing = TRUE),
    "does not uniquely identify"
  )
  expect_identical(capture(isid(panel[-4, ], id, wave)), panel[-4, ])
  expect_invisible(capture(isid(panel, id)))
  expect_null(capture(isid(panel, id)))
  expect_error(isid(panel, id, .missing = NA), "must be `TRUE` or `FALSE`")
  expect_error(isid(1:3), "must be a data frame")
})

test_that("duplicates_report() matches Stata's copies table", {
  out <- duplicates_report(panel, id)
  expect_identical(
    out,
    tibble::tibble(
      copies = c(1L, 2L),
      observations = c(1L, 4L),
      surplus = c(0L, 2L)
    )
  )
  all_columns <- duplicates_report(panel)
  expect_identical(all_columns$copies, c(1L, 2L))
  expect_identical(all_columns$surplus, c(0L, 1L))
})

test_that("duplicates_tag() counts the other rows sharing keys", {
  out <- duplicates_tag(panel, id)
  expect_identical(out$dup, c(1L, 1L, 1L, 1L, 0L))
  expect_identical(names(out), c(names(panel), "dup"))
  expect_identical(
    duplicates_tag(panel, .name = "n_dup")$n_dup,
    c(0L, 0L, 1L, 1L, 0L)
  )
  expect_error(duplicates_tag(panel, .name = "id"), "already exists")
  grouped <- dplyr::group_by(panel, id)
  expect_s3_class(duplicates_tag(grouped, wave), "grouped_df")
})

test_that("duplicates_list() returns sets in key order with positions", {
  out <- duplicates_list(panel, id, wave)
  expect_identical(out$.row, c(3L, 4L))
  expect_identical(out$.dup_group, c(1L, 1L))
  expect_identical(nrow(duplicates_list(panel, id, wave, score)), 2L)
  expect_identical(nrow(duplicates_list(dplyr::distinct(panel))), 0L)
})

test_that("duplicate metadata never replaces input columns", {
  for (name in c(".row", ".dup_group")) {
    data <- tibble::tibble(id = c(1L, 1L), original = c("a", "b"))
    names(data)[2L] <- name
    before <- data
    expect_error(duplicates_list(data, id), "already exists")
    expect_identical(data, before)
    # The same schema must be safe even when no duplicated rows remain.
    expect_error(duplicates_list(data[0, ], id), "already exists")
  }
})

test_that("row-returning duplicate functions retain grouping and row identity", {
  data <- tibble::tibble(
    g = factor(c("b", "a", "b", "a"), levels = c("a", "b", "unused")),
    id = c(2L, 1L, 2L, 3L),
    value = c("first", "second", "third", "fourth")
  )
  grouped <- dplyr::group_by(data, g, .drop = FALSE)
  before <- grouped
  listed <- duplicates_list(grouped, id)
  expected <- dplyr::dplyr_row_slice(grouped, c(1L, 3L))
  expect_identical(listed[names(grouped)], expected)
  expect_identical(listed$.row, c(1L, 3L))
  expect_identical(listed$.dup_group, c(1L, 1L))
  expect_identical(dplyr::group_data(listed), dplyr::group_data(expected))
  expect_identical(dplyr::group_vars(duplicates_tag(grouped, id)), "g")
  expect_message(
    dropped <- duplicates_drop(grouped, id, .force = TRUE),
    "1 row removed"
  )
  expect_identical(dropped, dplyr::dplyr_row_slice(grouped, c(1L, 2L, 4L)))
  empty <- duplicates_list(grouped[0, ], id)
  expect_identical(dplyr::group_data(empty), dplyr::group_data(grouped[0, ]))
  expect_identical(grouped, before)
})

test_that("survey preparation, key checks, joins and panel summaries compose", {
  raw <- tibble::tibble(
    id = c("a", "a", "a", "b", "b", "b"),
    wave = c(2L, 1L, 4L, 1L, 2L, 3L),
    score = c("12", "10", "15", "20", "25", "99")
  )
  before <- raw
  prepared <- dplyr::mutate(
    raw,
    score = haven::labelled_spss(destring(score), na_values = 99)
  )
  expect_invisible(isid(prepared, id, wave))
  joined <- stata_merge(
    prepared,
    tibble::tibble(id = c("a", "b"), region = c("north", "south")),
    "m:1",
    by = "id",
    assert = "match",
    report = FALSE
  )
  out <- dplyr::mutate(
    joined,
    change = stata_diff(score, time = wave),
    .by = id
  )
  expect_identical(out$change, c(2, NA, NA, NA, 5, NA))
  expect_message(
    summary <- summ(out, score, .by = region, .stat = c("n", "mean", "miss_n")),
    "labelled variable"
  )
  expect_identical(summary$region, c("north", "south"))
  expect_equal(summary$n, c(3, 2))
  expect_equal(summary$mean, c(37 / 3, 22.5))
  expect_equal(summary$miss_n, c(0, 1))
  counts <- tab(out, region)
  expect_identical(counts$region, c("north", "south"))
  expect_identical(counts$n, c(3L, 3L))
  expect_equal(counts$percent, c(50, 50))
  expect_identical(raw, before)
})

test_that("duplicates_drop() keeps first rows and guards against data loss", {
  expect_message(out <- duplicates_drop(panel), "(1 row removed)", fixed = TRUE)
  expect_identical(out, panel[-4, ])
  expect_error(duplicates_drop(panel, id), "differ in other columns")
  expect_message(
    forced <- duplicates_drop(panel, id, .force = TRUE),
    "(2 rows removed)",
    fixed = TRUE
  )
  expect_identical(forced$id, c(1, 2, 3))
  # Exact copies on the selected keys drop without .force.
  expect_message(
    same <- duplicates_drop(panel, id, wave),
    "(1 row removed)",
    fixed = TRUE
  )
  expect_identical(same, panel[-4, ])
})

test_that("duplicates treat missing values as equal, as Stata does", {
  data <- tibble::tibble(x = c(NA, NA, 1))
  expect_identical(duplicates_tag(data)$dup, c(1L, 1L, 0L))
})

test_that("duplicate identity distinguishes NaN and stored SPSS missing codes", {
  tagged <- tibble::tibble(
    id = c(NA, haven::tagged_na("a"), haven::tagged_na("b"), NaN, NaN, 1)
  )
  expect_identical(duplicates_tag(tagged, id)$dup, c(2L, 2L, 2L, 1L, 1L, 0L))
  expect_error(isid(tagged, id, .missing = TRUE), "does not uniquely identify")
  spss <- tibble::tibble(
    id = haven::labelled_spss(
      c(98, 99, 98, 97, 99, NA),
      na_values = 99,
      na_range = c(97, 98)
    )
  )
  expect_identical(duplicates_tag(spss, id)$dup, c(1L, 1L, 1L, 0L, 1L, 0L))
  distinct_codes <- spss[c(1, 2, 4, 6), ]
  expect_error(isid(distinct_codes, id), "should never be missing")
  expect_identical(
    suppressMessages(isid(distinct_codes, id, .missing = TRUE)),
    distinct_codes
  )
})

test_that("key functions keep data.frame and data.table containers", {
  frame <- as.data.frame(panel)
  expect_s3_class(suppressMessages(duplicates_drop(frame)), "data.frame")
  expect_false(inherits(suppressMessages(duplicates_drop(frame)), "tbl_df"))
  skip_if_not_installed("data.table")
  table <- data.table::as.data.table(panel)
  expect_s3_class(suppressMessages(duplicates_drop(table)), "data.table")
  expect_s3_class(duplicates_tag(table, id), "data.table")
  expect_false("dup" %in% names(table))
  expect_s3_class(duplicates_list(table, id), "data.table")
})

test_that("key checks report invalid input and repeated keys", {
  d <- tibble::tibble(id = c(1, 1, NA), x = 1:3)
  expect_snapshot(error = TRUE, {
    isid(d, id, .missing = NA)
    isid(d, id)
    isid(d, id, .missing = TRUE)
    duplicates_tag(d, id, .name = "")
    duplicates_tag(d, id, .name = "x")
    duplicates_drop(d, id)
    isid(1:3)
  })
})


test_that("isid() confirms a single or composite key and preserves its data", {
  single <- tibble::tibble(id = c(3L, 1L, 2L), score = c(8, 5, 7))
  expect_message(
    checked <- withVisible(isid(single, id)),
    "Variable `id` uniquely identifies the rows.",
    fixed = TRUE
  )
  expect_identical(checked$value, single)
  expect_false(checked$visible)
  unique_panel <- dplyr::distinct(panel)
  expect_message(
    checked <- withVisible(isid(unique_panel, id, wave)),
    "Variables `id`, `wave` together uniquely identify the rows.",
    fixed = TRUE
  )
  expect_identical(checked$value, unique_panel)
  expect_false(checked$visible)
  expect_output(suppressMessages(isid(single, id)), NA)
  expect_message(
    silent <- withVisible(suppressMessages(isid(single, id))),
    NA
  )
  expect_identical(silent$value, single)
  expect_false(silent$visible)
  expect_identical(
    suppressMessages(
      unique_panel |> isid(id, wave) |> dplyr::mutate(next_wave = wave + 1)
    ),
    dplyr::mutate(unique_panel, next_wave = wave + 1)
  )
  expect_identical(
    suppressMessages(isid(unique_panel, dplyr::all_of(c("id", "wave")))),
    unique_panel
  )
})

test_that("isid() rejects empty string keys unless missing values are allowed", {
  for (id in list(
    c("a", ""),
    factor(c("a", "")),
    haven::labelled(c("a", ""))
  )) {
    data <- tibble::tibble(id = id)
    before <- data
    expect_error(isid(data, id), "should never be missing")
    expect_identical(suppressMessages(isid(data, id, .missing = TRUE)), data)
    expect_identical(data, before)
  }
  unused_empty_level <- tibble::tibble(
    id = factor(c("a", "b"), levels = c("", "a", "b"))
  )
  expect_identical(
    suppressMessages(isid(unused_empty_level, id)),
    unused_empty_level
  )
  whitespace <- tibble::tibble(id = c("a", " ", "  "))
  expect_identical(suppressMessages(isid(whitespace, id)), whitespace)
  for (id in list(
    c("", ""),
    c(NA_character_, NA_character_),
    c(NA_real_, NA_real_)
  )) {
    expect_error(
      isid(tibble::tibble(id = id), id, .missing = TRUE),
      "does not uniquely identify"
    )
  }
  composite <- tibble::tibble(id = c("", ""), wave = 1:2)
  expect_identical(
    suppressMessages(isid(composite, id, wave, .missing = TRUE)),
    composite
  )
  expect_error(isid(composite, id, wave), "should never be missing")
})

test_that("isid() keeps labelled missingness and validates the renamed option", {
  for (id in list(
    c(1, NA_real_),
    c(1, NaN),
    haven::labelled(c(1, haven::tagged_na("a"))),
    haven::labelled_spss(c(1, 99), na_values = 99),
    haven::labelled_spss(c(1, 98), na_range = c(97, 99))
  )) {
    data <- tibble::tibble(id = id)
    expect_error(isid(data, id), "should never be missing")
    expect_identical(suppressMessages(isid(data, id, .missing = TRUE)), data)
  }
  expect_identical(formals(isid)$.missing, FALSE)
  expect_false(".missok" %in% names(formals(isid)))
  expect_error(isid(tibble::tibble(id = 1:2), id, .missok = TRUE))
  expect_error(
    isid(tibble::tibble(id = 1:2), id, .missing = NA),
    "must be `TRUE` or `FALSE`"
  )
  expect_message(
    expect_error(isid(panel, id), "does not uniquely identify"),
    NA
  )
  expect_message(
    expect_error(isid(tibble::tibble(id = ""), id), "should never be missing"),
    NA
  )
})

test_that("isid() preserves grouped and empty inputs while checking globally", {
  grouped <- dplyr::group_by(dplyr::distinct(panel), id)
  before <- grouped
  expect_identical(suppressMessages(isid(grouped, id, wave)), before)
  expect_identical(grouped, before)
  expect_error(
    isid(dplyr::group_by(tibble::tibble(g = c("a", "b"), id = c(1, 1)), g), id),
    "does not uniquely identify"
  )
  empty <- grouped[0, ]
  expect_message(
    checked <- withVisible(isid(empty, id, wave)),
    "No rows to check.",
    fixed = TRUE
  )
  expect_identical(checked$value, empty)
  expect_false(checked$visible)
  frame <- as.data.frame(dplyr::distinct(panel))
  expect_identical(suppressMessages(isid(frame, id, wave)), frame)
})

test_that("isid() preserves data.table inputs without adding metadata", {
  skip_if_not_installed("data.table")
  data <- data.table::as.data.table(dplyr::distinct(panel))
  before <- data.table::copy(data)
  expect_identical(suppressMessages(isid(data, id, wave)), before)
  expect_identical(data, before)
})

test_that("isid() success messages name the checked keys", {
  expect_snapshot({
    isid(tibble::tibble(id = 1:2), id)
    isid(dplyr::distinct(panel), id, wave)
    isid(panel[0, ], id, wave)
  })
})
