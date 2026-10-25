preview_test_data <- function(n = 30L) {
  tibble::tibble(
    id = seq_len(n),
    marker = sprintf("row%03d", seq_len(n)),
    group = rep(c("a", "b", "c"), length.out = n),
    value = seq_len(n) / 2
  )
}

preview_test_output <- function(x, ...) {
  withr::local_options(cli.num_colors = 1L, pillar.width = 120L)
  paste(capture.output(print(x, width = 120, ...)), collapse = "\n")
}

preview_test_markers <- function(x, ...) {
  output <- preview_test_output(x, ...)
  regmatches(output, gregexpr("row[0-9]{3}", output))[[1]]
}

expect_preview_matches <- function(actual, expected) {
  expect_s3_class(actual, "tidystata_preview")
  expect_identical(unpreview_table(actual), expected)
}

test_that("preview constructor retains every row and every column", {
  data <- preview_test_data(100)
  original <- serialize(data, NULL)
  result <- preview_table(data)
  expect_s3_class(result, c("tidystata_preview", "tbl_df", "tbl", "data.frame"))
  expect_identical(dim(result), c(100L, 4L))
  expect_identical(result$value, data$value)
  expect_identical(result$marker[50], "row050")
  expect_identical(unpreview_table(result), data)
  expect_identical(serialize(data, NULL), original)
})

test_that("default preview displays first five and last five rows", {
  data <- preview_test_data(100)
  output <- preview_test_output(preview_table(data))
  expect_identical(
    preview_test_markers(preview_table(data)),
    data$marker[c(1:5, 96:100)]
  )
  expect_match(output, "100")
  expect_match(output, "90")
  expect_match(output, "(?m)^\\s*96\\s+96\\s+row096", perl = TRUE)
})

test_that("headtail uses a total budget with the odd row assigned to the head", {
  data <- preview_test_data()
  expect_identical(
    preview_test_markers(preview_table(data, n = 5)),
    data$marker[c(1:3, 29:30)]
  )
  expect_identical(preview_test_markers(preview_table(data, n = 1)), "row001")
  expect_identical(
    preview_test_markers(preview_table(data, n = 2)),
    data$marker[c(1, 30)]
  )
})

test_that("interval previews span the current table including its endpoints", {
  data <- preview_test_data(21)
  expect_identical(
    preview_test_markers(preview_table(data, style = "interval", n = 5)),
    data$marker[c(1, 6, 11, 16, 21)]
  )
  expect_identical(
    preview_test_markers(preview_table(data, style = "interval", n = 1)),
    "row001"
  )
})

test_that("short tables and infinite budgets display all rows without duplicates", {
  for (size in c(0L, 1L, 4L, 10L, 11L)) {
    data <- preview_test_data(size)
    for (style in c("headtail", "interval")) {
      expected <- if (size <= 10L) data$marker else data$marker[c(1:5, 7:11)]
      if (style == "interval" && size > 10L) {
        expected <- data$marker[round(seq(1, size, length.out = 10))]
      }
      expect_identical(
        preview_test_markers(preview_table(data, style = style)),
        expected
      )
      expect_identical(
        preview_test_markers(preview_table(data, style = style, n = Inf)),
        data$marker
      )
    }
  }
})

test_that("zero column tables retain their actual row count", {
  data <- tibble::new_tibble(list(), nrow = 12L)
  result <- preview_table(data, n = 3)
  expect_identical(dim(result), c(12L, 0L))
  expect_identical(unpreview_table(result), data)
  expect_match(preview_test_output(result), "12")
  expect_no_error(print(result))
})

test_that("preview arguments reject invalid budgets and styles", {
  data <- preview_test_data()
  invalid <- list(
    NULL,
    integer(),
    NA_real_,
    NaN,
    -Inf,
    0,
    -1,
    1.5,
    c(1, 2),
    "5",
    TRUE
  )
  for (n in invalid) {
    expect_error(preview_table(data, n = n), "positive|integer")
    expect_error(slice_headtail(data, n = n), "positive|integer")
    expect_error(slice_interval(data, n = n), "positive|integer")
  }
  expect_error(preview_table(data, style = "random"))
  expect_error(preview_table(data, style = NA_character_))
  expect_error(preview_table(data, style = character()))
})

test_that("preview accepts base data frames and rejects unsupported containers", {
  data <- data.frame(a = 1:3, b = letters[1:3])
  expect_preview_matches(preview_table(data), data)
  expect_error(preview_table(1:3))
  expect_error(preview_table(list(a = 1:3)))
  expect_error(preview_table(matrix(1:4, ncol = 2)))
  unknown <- structure(
    tibble::tibble(a = 1:3),
    class = c("unknown_tbl", "tbl_df", "tbl", "data.frame")
  )
  expect_error(preview_table(unknown))
  lazy <- structure(list(), class = c("tbl_lazy", "tbl"))
  expect_error(preview_table(lazy))
})

test_that("classed and list columns remain unchanged", {
  data <- tibble::tibble(
    date = as.Date("2020-01-01") + 0:2,
    time = as.POSIXct("2020-01-01", tz = "UTC") + 0:2,
    factor = factor(c("b", "a", NA), levels = c("b", "a")),
    labelled = haven::labelled(c(1, 2, NA), c(yes = 1, no = 2)),
    list = list(1:3, NULL, list(x = TRUE))
  )
  result <- preview_table(data)
  expect_identical(unpreview_table(result), data)
  for (name in names(data)) {
    expect_identical(result[[name]], data[[name]])
  }
  expect_no_error(print(result))
})

test_that("wrapping again changes settings without stacking classes", {
  data <- preview_test_data(21)
  result <- preview_table(preview_table(data), style = "interval", n = 3)
  expect_identical(sum(class(result) == "tidystata_preview"), 1L)
  expect_identical(preview_test_markers(result), data$marker[c(1, 11, 21)])
  expect_identical(unpreview_table(result), data)
  expect_identical(unpreview_table(data), data)
})

test_that("printing returns the original object invisibly without mutation", {
  data <- preview_table(preview_test_data(), style = "interval", n = 4)
  original <- serialize(data, NULL)
  capture.output(result <- withVisible(print(data)))
  expect_false(result$visible)
  expect_identical(result$value, data)
  expect_identical(serialize(data, NULL), original)
  expect_identical(length(preview_test_markers(data, n = Inf)), 30L)
  expect_identical(length(preview_test_markers(data)), 4L)
})

test_that("explicit conversions remove preview without changing table values", {
  data <- preview_test_data()
  result <- preview_table(data)
  expect_identical(tibble::as_tibble(result), data)
  expect_identical(as.data.frame(result), as.data.frame(data))
  expect_identical(result[["value"]], data$value)
  expect_identical(result[, "value", drop = TRUE], data$value)
})

test_that("ordinary dplyr edits retain values and preview settings", {
  data <- preview_test_data()
  wrapped <- preview_table(data, style = "interval", n = 3)
  operations <- list(
    function(x) dplyr::mutate(x, doubled = value * 2),
    function(x) dplyr::transmute(x, marker, doubled = value * 2),
    function(x) dplyr::filter(x, id %% 2 == 0),
    function(x) dplyr::arrange(x, dplyr::desc(id)),
    function(x) dplyr::select(x, marker, value),
    function(x) dplyr::rename(x, measure = value),
    function(x) dplyr::relocate(x, marker),
    function(x) dplyr::distinct(x, group, .keep_all = TRUE),
    function(x) dplyr::slice(x, c(20, 2, 10, 1, 5)),
    function(x) dplyr::slice_head(x, n = 12),
    function(x) dplyr::slice_tail(x, n = 12)
  )
  for (operation in operations) {
    actual <- operation(wrapped)
    expected <- operation(data)
    expect_preview_matches(actual, expected)
    expect_identical(
      preview_test_markers(actual),
      expected$marker[round(seq(1, nrow(expected), length.out = 3))]
    )
  }
})

test_that("base subsetting and replacement retain preview on table results", {
  data <- preview_test_data()
  wrapped <- preview_table(data, n = 3)
  expect_preview_matches(wrapped[c(30, 1, 15), ], data[c(30, 1, 15), ])
  expect_preview_matches(
    wrapped[c("marker", "value")],
    data[c("marker", "value")]
  )
  expect_preview_matches(wrapped[FALSE, ], data[FALSE, ])
  wrapped$value[2] <- 900
  data$value[2] <- 900
  expect_preview_matches(wrapped, data)
  wrapped[["extra"]] <- seq_len(nrow(data))
  data[["extra"]] <- seq_len(nrow(data))
  expect_preview_matches(wrapped, data)
  wrapped[1, "value"] <- 700
  data[1, "value"] <- 700
  expect_preview_matches(wrapped, data)
  wrapped$extra <- NULL
  data$extra <- NULL
  expect_preview_matches(wrapped, data)
  names(wrapped)[names(wrapped) == "value"] <- "measure"
  names(data)[names(data) == "value"] <- "measure"
  expect_preview_matches(wrapped, data)
  expect_identical(length(preview_test_markers(wrapped)), 3L)
})

test_that("printed row numbers refer to the edited table", {
  data <- preview_test_data(100)
  result <- dplyr::arrange(
    dplyr::filter(preview_table(data, n = 2), id > 50),
    dplyr::desc(id)
  )
  output <- preview_test_output(result)
  expect_identical(preview_test_markers(result), c("row100", "row051"))
  expect_match(output, "(?m)^\\s*1\\s+100\\s+row100", perl = TRUE)
  expect_match(output, "(?m)^\\s*50\\s+51\\s+row051", perl = TRUE)
})

test_that("grouping transitions preserve settings and correct grouping metadata", {
  data <- preview_test_data()
  grouped <- dplyr::group_by(data, group)
  result <- dplyr::group_by(preview_table(data, n = 3), group)
  expect_preview_matches(result, grouped)
  expect_identical(dplyr::group_data(result), dplyr::group_data(grouped))
  expect_preview_matches(dplyr::ungroup(result), data)
  expect_preview_matches(preview_table(grouped), grouped)
  added <- dplyr::group_by(result, even = id %% 2, .add = TRUE)
  expected <- dplyr::group_by(grouped, even = id %% 2, .add = TRUE)
  expect_preview_matches(added, expected)
  expect_preview_matches(
    dplyr::ungroup(added, even),
    dplyr::ungroup(expected, even)
  )
  expect_identical(length(preview_test_markers(added)), 3L)
})

test_that("grouped row and column edits recompute groups as dplyr does", {
  data <- dplyr::group_by(preview_test_data(), group)
  wrapped <- preview_table(data, n = 3)
  operations <- list(
    function(x) dplyr::filter(x, id > 10),
    function(x) dplyr::slice(x, 1:2),
    function(x) dplyr::mutate(x, value = value - mean(value)),
    function(x) dplyr::mutate(x, group = "one"),
    function(x) dplyr::arrange(x, dplyr::desc(value)),
    function(x) dplyr::rename(x, category = group),
    function(x) x[c(30, 1, 20), ]
  )
  for (operation in operations) {
    actual <- operation(wrapped)
    expected <- operation(data)
    expect_preview_matches(actual, expected)
    expect_identical(dplyr::group_data(actual), dplyr::group_data(expected))
  }
  names(wrapped)[names(wrapped) == "group"] <- "category"
  names(data)[names(data) == "group"] <- "category"
  expect_preview_matches(wrapped, data)
  expect_identical(dplyr::group_vars(wrapped), "category")
})

test_that("rowwise transitions and edits retain correct grouping", {
  data <- preview_test_data()
  expected <- dplyr::rowwise(data, group)
  result <- dplyr::rowwise(preview_table(data), group)
  expect_preview_matches(result, expected)
  expect_preview_matches(preview_table(expected), expected)
  expect_preview_matches(
    dplyr::mutate(result, total = sum(c(id, value))),
    dplyr::mutate(expected, total = sum(c(id, value)))
  )
  expect_preview_matches(dplyr::slice(result, 1), dplyr::slice(expected, 1))
  expect_preview_matches(dplyr::ungroup(result), data)
})

test_that("summaries preserve preview and follow requested output grouping", {
  data <- dplyr::group_by(preview_test_data(), group)
  for (groups in c("drop", "drop_last", "keep", "rowwise")) {
    actual <- dplyr::summarise(
      preview_table(data),
      total = sum(value),
      .groups = groups
    )
    expected <- dplyr::summarise(data, total = sum(value), .groups = groups)
    expect_preview_matches(actual, expected)
    expect_identical(dplyr::group_data(actual), dplyr::group_data(expected))
  }
  plain <- dplyr::ungroup(data)
  expect_preview_matches(
    dplyr::summarise(preview_table(plain), total = sum(value), .by = group),
    dplyr::summarise(plain, total = sum(value), .by = group)
  )
  expect_preview_matches(
    dplyr::reframe(preview_table(data), value = range(value)),
    dplyr::reframe(data, value = range(value))
  )
})

test_that("joins retain the left table policy and ordinary dplyr values", {
  left <- preview_test_data()
  right <- tibble::tibble(
    id = c(1L, 15L, 31L),
    label = c("one", "middle", "new")
  )
  joins <- list(
    dplyr::left_join,
    dplyr::right_join,
    dplyr::inner_join,
    dplyr::full_join,
    dplyr::semi_join,
    dplyr::anti_join
  )
  for (join in joins) {
    actual <- join(
      preview_table(left, n = 2),
      preview_table(right, n = 1),
      by = "id"
    )
    expected <- join(left, right, by = "id")
    expect_preview_matches(actual, expected)
    if (nrow(expected) > 2L && all(!is.na(expected$marker))) {
      expect_identical(
        preview_test_markers(actual),
        expected$marker[c(1, nrow(expected))]
      )
    }
    expect_false(inherits(
      join(left, preview_table(right), by = "id"),
      "tidystata_preview"
    ))
  }
  grouped <- dplyr::group_by(left, group)
  expect_preview_matches(
    dplyr::left_join(preview_table(grouped), right, by = "id"),
    dplyr::left_join(grouped, right, by = "id")
  )
})

test_that("row binding uses first table settings and retains every row", {
  first <- preview_test_data(20)
  second <- preview_test_data(10)
  second$marker <- sprintf("row%03d", 21:30)
  result <- dplyr::bind_rows(
    preview_table(first, n = 2),
    preview_table(second, n = 5)
  )
  expect_preview_matches(result, dplyr::bind_rows(first, second))
  expect_identical(preview_test_markers(result), c("row001", "row030"))
  expect_false(inherits(
    dplyr::bind_rows(first, preview_table(second)),
    "tidystata_preview"
  ))
  grouped <- dplyr::group_by(first, group)
  expect_preview_matches(
    dplyr::bind_rows(preview_table(grouped), second),
    dplyr::bind_rows(grouped, second)
  )
})

test_that("pivots preserve settings while respecting their changed table structure", {
  skip_if_not_installed("tidyr")
  data <- tibble::tibble(
    id = 1:20,
    marker = sprintf("row%03d", 1:20),
    a = 1:20,
    b = 21:40
  )
  result <- tidyr::pivot_longer(preview_table(data, n = 3), c(a, b))
  expected <- tidyr::pivot_longer(data, c(a, b))
  expect_preview_matches(result, expected)
  expect_identical(
    preview_test_markers(result),
    c("row001", "row001", "row020")
  )
  expect_preview_matches(
    tidyr::pivot_wider(result, names_from = name, values_from = value),
    data
  )
  grouped <- dplyr::group_by(data, id)
  expect_preview_matches(
    tidyr::pivot_longer(preview_table(grouped), c(a, b)),
    tidyr::pivot_longer(grouped, c(a, b))
  )
})

test_that("pivot selectors retain caller context without extra evaluations", {
  skip_if_not_installed("tidyr")
  data <- tibble::tibble(id = 1:3, a = 1:3, b = 4:6)
  calls <- 0L
  choose <- function() {
    calls <<- calls + 1L
    c("a", "b")
  }
  longer <- tidyr::pivot_longer(
    preview_table(data),
    tidyselect::all_of(choose())
  )
  expect_identical(calls, 1L)
  expect_preview_matches(longer, tidyr::pivot_longer(data, c(a, b)))
  local_longer <- function(x, columns) {
    tidyr::pivot_longer(x, tidyselect::all_of(columns))
  }
  expect_preview_matches(
    local_longer(preview_table(data), c("a", "b")),
    local_longer(data, c("a", "b"))
  )
  calls <- 0L
  choose_names <- function() {
    calls <<- calls + 1L
    "name"
  }
  wider <- tidyr::pivot_wider(
    longer,
    names_from = tidyselect::all_of(choose_names())
  )
  wrapped_calls <- calls
  calls <- 0L
  tidyr::pivot_wider(
    unpreview_table(longer),
    names_from = tidyselect::all_of(choose_names())
  )
  expect_identical(wrapped_calls, calls)
  expect_preview_matches(wider, data)
  local_wider <- function(x, names_column, values_column) {
    tidyr::pivot_wider(
      x,
      names_from = tidyselect::all_of(names_column),
      values_from = tidyselect::all_of(values_column)
    )
  }
  expect_preview_matches(local_wider(longer, "name", "value"), data)
})

test_that("preview omission footers respect width and footer limits", {
  data <- preview_table(tibble::tibble(id = 1:100), n = 2)
  output <- format(data, width = 35)
  footer <- output[grepl("^#", output)][-1L]
  expect_true(any(grepl("omitted", footer)))
  expect_true(all(nchar(footer, type = "width") <= 35L))
  expect_false(any(grepl("omitted", format(data, max_footer_lines = 0))))
  for (style in c("headtail", "interval")) {
    single <- preview_table(tibble::tibble(id = 1:100), style = style, n = 1)
    output <- paste(format(single), collapse = "\n")
    expect_match(output, "99.*omitted")
    expect_false(grepl("middle|between", output))
  }
})

test_that("legacy slice helpers return real unique subsets", {
  for (size in c(0L, 1L, 4L, 20L)) {
    data <- preview_test_data(size)
    expected_head <- if (size <= 5) data else data[c(1:3, 19:20), ]
    expected_interval <- if (size <= 5) data else data[c(1, 6, 10, 15, 20), ]
    expect_identical(slice_headtail(data, n = 5), expected_head)
    expect_identical(slice_interval(data, n = 5), expected_interval)
    expect_identical(slice_headtail(data, n = Inf), data)
    expect_identical(slice_interval(data, n = Inf), data)
  }
  grouped <- dplyr::group_by(preview_test_data(), group)
  expect_identical(slice_headtail(grouped, n = 2), grouped[c(1, 30), ])
  expect_identical(slice_interval(grouped, n = 3), grouped[c(1, 16, 30), ])
  wrapped <- preview_table(grouped, n = 1)
  expect_preview_matches(slice_headtail(wrapped, n = 3), grouped[c(1, 2, 30), ])
  expect_identical(
    preview_test_markers(slice_headtail(wrapped, n = 3)),
    "row001"
  )
})

test_that("one time printers retain their original input and visibility", {
  data <- preview_test_data(30)
  original <- serialize(data, NULL)
  for (printer in list(print_headtail, print_interval)) {
    output <- capture.output(
      result <- withVisible(printer(data, n = 3, width = 100))
    )
    expect_false(result$visible)
    expect_identical(result$value, data)
    expect_identical(serialize(data, NULL), original)
    expect_true(any(grepl("row001", output)))
    expect_true(any(grepl("row030", output)))
    expect_error(printer(data, n = 0))
  }
})


test_that("preview printing preserves duplicate and empty column names", {
  for (column_names in list(c("a", "a"), c("", "b"))) {
    data <- tibble::as_tibble(
      stats::setNames(list(1:20, 21:40), column_names),
      .name_repair = "minimal"
    )
    for (input in list(data, as.data.frame(data))) {
      names(input) <- column_names
      x <- preview_table(input)
      expect_no_error(format(x))
      expect_identical(names(x), column_names)
      expect_identical(x[[1]], 1:20)
      expect_identical(x[[2]], 21:40)
    }
  }
})

test_that("print_all() prints every row and column and returns the input", {
  data <- tibble::tibble(id = 1:40, value = (1:40)^2)
  printed <- capture.output(out <- print_all(data))
  expect_identical(out, data)
  expect_true(any(grepl("^ *40 +40 +1600", printed)))
  expect_false(any(grepl("more rows", printed)))
  capture.output(expect_invisible(print_all(data)))

  wide <- as.data.frame(matrix(1:60, 2))
  printed <- withr::with_options(
    list(width = 60),
    capture.output(print_all(wide))
  )
  expect_true(any(grepl("V30", printed)))
  expect_false(any(grepl("more variable", printed)))

  grouped <- dplyr::group_by(data, id > 20)
  expect_identical(
    suppressMessages(capture.output(r <- print_all(grouped)) |> length() > 40),
    TRUE
  )
  expect_identical(r, grouped)

  skip_if_not_installed("data.table")
  table <- data.table::as.data.table(data)
  printed <- capture.output(out <- print_all(table))
  expect_identical(out, table)
  expect_true(any(grepl("1600", printed)))
})

test_that("historical previews and repeated timers preserve complete values", {
  d <- tibble::tibble(id = 1:25, x = letters[1:25])
  expect_output(returned <- print_interval(d, n = Inf, width = Inf), "25")
  expect_identical(returned, d)
  preview <- preview_table(d, "interval", n = 5)
  changed <- dplyr::mutate(preview, id = id + 1L)
  expect_s3_class(changed, "tidystata_preview")
  expect_identical(unpreview_table(changed)$id, 2:26)
  expect_identical(
    tidystata:::duration_to_chr(as.difftime(61, units = "secs")),
    "1m1s"
  )
  calls <- 0L
  messages <- character()
  result <- withCallingHandlers(
    {
      value <- timer({
        calls <- calls + 1L
        1:5
      })
      timer(sum(value))
    },
    message = function(condition) {
      messages <<- c(messages, conditionMessage(condition))
      invokeRestart("muffleMessage")
    }
  )
  expect_identical(calls, 1L)
  expect_equal(result, 15)
  expect_length(messages, 2L)
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

test_that("slicing retains explicit row names and regenerates automatic ones", {
  automatic <- data.frame(x = 1:8)
  explicit <- data.frame(x = 1:8, row.names = letters[1:8])
  expect_identical(
    rownames(slice_headtail(automatic, n = 4)),
    as.character(1:4)
  )
  expect_identical(
    rownames(slice_headtail(explicit, n = 4)),
    letters[c(1, 2, 7, 8)]
  )
  expect_identical(
    rownames(slice_interval(automatic, n = 3)),
    as.character(1:3)
  )
  expect_identical(
    rownames(slice_interval(explicit, n = 3)),
    letters[c(1, 4, 8)]
  )
})

test_that("previews report invalid input", {
  expect_snapshot(error = TRUE, {
    preview_table(1:3)
    preview_table(tibble::tibble(x = 1), n = 0)
    slice_headtail(tibble::tibble(x = 1), n = 2.5)
  })
})

test_that("print_all() accepts a console width", {
  data <- tibble::tibble(x = 1)
  expect_output(out <- print_all(data, width = 80), "x")
  expect_identical(out, data)
})
