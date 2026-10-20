# Independent one-way acceptance: each numbered case runs for both exports.
# The oracle counts original values with base match/tabulate, not statart helpers.
oneway_cases <- list()
oneway_add <- function(title, check) {
  oneway_cases[[length(oneway_cases) + 1L]] <<- list(
    title = title,
    check = check
  )
}
oneway_check <- function(fn, frequency, x, desc = FALSE) {
  d <- tibble::tibble(x = x)
  before <- d
  out <- fn(d, x, .desc = desc)$x
  expect_s3_class(out, "tbl_df")
  expect_false(dplyr::is_grouped_df(out))
  if (!length(x)) {
    expect_equal(nrow(out), 0L)
    expect_identical(out$n, integer())
  } else {
    keys <- unique(x)
    counts <- tabulate(match(x, keys), nbins = length(keys))
    # Use each value's base representation; frequency output adds string labels.
    labels <- as.character(keys)
    observed <- if (frequency) out[!is.na(out$cum), ] else out
    expect_equal(nrow(observed), length(keys))
    idx <- match(as.character(observed$value), labels)
    expect_false(anyNA(idx))
    expect_equal(observed$n, counts[idx])
    expect_equal(observed$percent, 100 * counts[idx] / length(x))
    missing <- is.na(keys)[idx]
    valid_n <- sum(!is.na(x))
    expected_valid <- ifelse(
      missing | valid_n == 0,
      NA_real_,
      100 * counts[idx] / valid_n
    )
    expect_equal(observed$valid, expected_valid)
    expect_equal(observed$cum, cumsum(observed$percent))
    expect_equal(observed$valid_cum, cumsum(expected_valid))
    expect_false(any(diff(as.integer(missing)) < 0L))
    if (desc) {
      expect_true(all(diff(observed$n[!missing]) <= 0))
    }
    if (!frequency) {
      expect_identical(class(out$value), class(x))
    }
    if (frequency) {
      expect_identical(tail(out$value, 1L), "Total")
      expect_equal(tail(out$n, 1L), length(x))
      expect_equal(tail(out$percent, 1L), 100)
      expect_true(is.na(tail(out$cum, 1L)))
      subtotal <- out$value == "Valid Total" & !is.na(out$value)
      expect_equal(
        sum(subtotal),
        as.integer(sum(!is.na(keys)) > 1L && anyNA(x))
      )
      if (any(subtotal)) expect_equal(out$n[subtotal], valid_n)
    }
  }
  expect_identical(d, before)
}
oneway_vectors <- list(
  "positive integers" = c(1L, 1L, 2L, 3L),
  "negative integers" = c(-3L, -2L, -2L, -1L),
  "mixed signs" = c(-1, 0, 0, 1),
  "one observation" = 7,
  "constant nonzero" = rep(7, 5),
  "constant zero" = rep(0, 4),
  "all unique" = 1:7,
  "unbalanced categories" = c(rep(1, 9), 2, 3),
  "fractional values" = c(0.1, 0.1, 0.2, 0.3),
  "very small distinct values" = c(1e-100, 2e-100, 1e-100),
  "very large values" = c(1e100, 2e100, 1e100),
  "integer storage endpoints" = c(
    -.Machine$integer.max,
    .Machine$integer.max,
    0
  ),
  "positive infinity" = c(Inf, 1, Inf),
  "negative infinity" = c(-Inf, 0, -Inf),
  "both infinities" = c(-Inf, Inf, -Inf),
  "NA at both ends" = c(NA, 2, 2, 1, NA),
  "single observed value and missing" = c(1, NA, NA),
  "multiple observed values and missing" = c(1, 2, 2, NA),
  "all numeric NA" = rep(NA_real_, 3),
  "empty doubles" = numeric(),
  "empty integers" = integer(),
  "logical balance" = c(TRUE, FALSE, TRUE, FALSE),
  "logical missing" = c(TRUE, FALSE, NA, TRUE),
  "all logical missing" = rep(NA, 3),
  "empty logicals" = logical(),
  "text repeated" = c("b", "a", "a", "c"),
  "text missing" = c("a", NA, "b", "a"),
  "empty strings are values" = c("", "a", "", NA),
  "whitespace is significant" = c("a", " a", "a ", "a"),
  "literal NA versus missing" = c("NA", NA, "NA", "x"),
  "case sensitive categories" = c("a", "A", "a"),
  "punctuation categories" = c("x/y", "x\\y", "x/y"),
  "Unicode categories" = c("\u4e2d\u6587", "\u4e2d\u6587", "\u6536\u5165"),
  "empty text" = character(),
  "all text missing" = rep(NA_character_, 3),
  "factor order and unused levels" = factor(
    c("b", "a", "b"),
    levels = c("b", "a", "unused")
  ),
  "factor missing" = factor(c("a", NA, "b", "a")),
  "ordered factor" = ordered(
    c("low", "high", "low"),
    levels = c("low", "mid", "high")
  ),
  "empty factor retains levels" = factor(character(), levels = c("a", "b")),
  "all missing factor" = factor(c(NA, NA), levels = c("a", "b")),
  "leap day dates" = as.Date(c("2024-02-29", "2024-03-01", "2024-02-29")),
  "dates with missing" = as.Date(c("2024-01-01", NA, "2024-01-02")),
  "empty dates" = as.Date(character()),
  "UTC datetime" = as.POSIXct("2024-01-01", tz = "UTC") + c(0, 60, 0),
  "datetime missing" = as.POSIXct("2024-01-01", tz = "UTC") + c(NA, 0, 60, 0),
  "empty datetime" = as.POSIXct(character(), tz = "UTC"),
  "difftime hours" = as.difftime(c(1, 2, 1), units = "hours"),
  "descending frequency numeric" = c(1, 2, 2, 3, 3, 3, NA),
  "descending frequency text" = c("c", "b", "b", "a", "a", "a", NA),
  "ten thousand observations" = rep(1:10, length.out = 10000L)
)
for (i in seq_along(oneway_vectors)) {
  local({
    x <- oneway_vectors[[i]]
    title <- names(oneway_vectors)[[i]]
    descending <- i %in% c(48L, 49L)
    oneway_add(title, function(fn, frequency) {
      oneway_check(fn, frequency, x, descending)
    })
  })
}
oneway_data <- function() {
  tibble::tibble(
    g = c("B", "A", NA, "A", "B", NA),
    x = c(1, 1, NA, 2, 1, 3),
    y = c("a", "b", "b", NA, "b", "a")
  )
}
oneway_group_check <- function(out, frequency, d, group = "g") {
  expect_true(group %in% names(out))
  for (key in unique(d[[group]])) {
    idx <- if (is.na(key)) {
      is.na(d[[group]])
    } else {
      !is.na(d[[group]]) & d[[group]] == key
    }
    oi <- if (is.na(key)) {
      is.na(out[[group]])
    } else {
      !is.na(out[[group]]) & out[[group]] == key
    }
    o <- out[oi, ]
    observed <- if (frequency) o[!is.na(o$cum), ] else o
    expect_equal(sum(observed$n), sum(idx))
    expect_equal(sum(observed$percent), 100)
    if (any(!is.na(d$x[idx]))) {
      expect_equal(sum(observed$valid, na.rm = TRUE), 100)
    }
    if (frequency) expect_equal(tail(o$n, 1), sum(idx))
  }
}
oneway_add(
  "base data frame returns list of data frames",
  function(fn, frequency) {
    d <- data.frame(x = c(1, 1, 2), y = c("a", "b", "a"))
    before <- d
    out <- fn(d)
    expect_named(out, c("x", "y"))
    for (frame in out) {
      expect_identical(class(frame), "data.frame")
    }
    expect_identical(d, before)
  }
)
oneway_add("tibble output variable ordering", function(fn, frequency) {
  out <- fn(tibble::tibble(z = 1:2, a = 3:4), z, a, .type = "tibble")
  expect_identical(unique(out$variable), c("z", "a"))
  expect_s3_class(out, "tbl_df")
})
oneway_add("mixed numeric character table", function(fn, frequency) {
  out <- fn(
    tibble::tibble(x = c(1, 1, 2), y = c("a", "b", "a")),
    .type = "tibble"
  )
  expect_type(out$value, "character")
  expect_identical(unique(out$variable), c("x", "y"))
  expect_equal(out$n[out$variable == "x"][1:2], c(2, 1))
})
oneway_add("integer double table is compatible", function(fn, frequency) {
  out <- fn(tibble::tibble(x = 1:2, y = c(1.5, 1.5)), .type = "tibble")
  expect_type(out$value, if (frequency) "character" else "double")
  expect_equal(out$n[out$variable == "y"][[1]], 2)
})
oneway_add("all factor table with different levels", function(fn, frequency) {
  out <- fn(
    tibble::tibble(x = factor(c("a", "b")), y = factor(c("b", "c"))),
    .type = "tibble"
  )
  expect_equal(out$n[!is.na(out$cum)], rep(1, 4))
  expect_equal(as.character(out$value[!is.na(out$cum)]), c("a", "b", "b", "c"))
})
oneway_add("group missing keys retained", function(fn, frequency) {
  d <- oneway_data()
  oneway_group_check(fn(d, x, .by = g)$x, frequency, d)
})
oneway_add(
  "inherited group matches explicit grouping",
  function(fn, frequency) {
    d <- oneway_data()
    expect_identical(fn(dplyr::group_by(d, g), x), fn(d, x, .by = g))
  }
)
oneway_add(
  "explicit group overrides existing grouping",
  function(fn, frequency) {
    d <- oneway_data()
    expect_identical(fn(dplyr::group_by(d, y), x, .by = g), fn(d, x, .by = g))
  }
)
oneway_add(
  "multiple group keys use within-key denominator",
  function(fn, frequency) {
    d <- tibble::tibble(
      g = c("A", "A", "A", "B"),
      h = c(1, 1, 2, 2),
      x = c(1, 2, NA, 2)
    )
    out <- fn(d, x, .by = c(g, h))$x
    expect_named(
      out,
      c("g", "h", "value", "n", "percent", "cum", "valid", "valid_cum")
    )
    expect_equal(out$percent[!is.na(out$cum)], c(50, 50, 100, 100))
  }
)
oneway_add(
  "factor group unused levels produce no phantom rows",
  function(fn, frequency) {
    d <- oneway_data()
    d$g <- factor(d$g, levels = c("B", "A", "unused"))
    out <- fn(d, x, .by = g)$x
    expect_false(any(out$g == "unused", na.rm = TRUE))
    oneway_group_check(out, frequency, d)
  }
)
oneway_add("numeric grouping keys retained", function(fn, frequency) {
  d <- oneway_data()
  d$g <- c(1, 2, NA, 2, 1, NA)
  out <- fn(d, x, .by = g)$x
  expect_type(out$g, "double")
  oneway_group_check(out, frequency, d)
})
oneway_add("zero-row grouped selection", function(fn, frequency) {
  d <- oneway_data()[FALSE, ]
  out <- fn(d, x, .by = g)$x
  expect_named(
    out,
    c("g", "value", "n", "percent", "cum", "valid", "valid_cum")
  )
  expect_equal(nrow(out), 0)
})
oneway_add("no measured variables list", function(fn, frequency) {
  expect_length(fn(oneway_data(), tidyselect::starts_with("absent")), 0)
})
oneway_add("no measured variables table", function(fn, frequency) {
  out <- fn(oneway_data(), tidyselect::starts_with("absent"), .type = "tibble")
  expect_named(
    out,
    c("variable", "value", "n", "percent", "cum", "valid", "valid_cum")
  )
  expect_equal(nrow(out), 0)
})
oneway_add("group-only selection is empty", function(fn, frequency) {
  out <- fn(oneway_data(), g, .by = g, .type = "tibble")
  expect_equal(nrow(out), 0)
  expect_type(out$g, "character")
})
oneway_add("starts_with selection", function(fn, frequency) {
  expect_named(
    fn(
      tibble::tibble(x1 = 1:2, x2 = 2:3, y = 3:4),
      tidyselect::starts_with("x")
    ),
    c("x1", "x2")
  )
})
oneway_add("negative selection", function(fn, frequency) {
  expect_named(fn(oneway_data(), -g), c("x", "y"))
})
oneway_add("programmatic all_of selection", function(fn, frequency) {
  columns <- c("y", "x")
  expect_named(fn(oneway_data(), tidyselect::all_of(columns)), columns)
})
oneway_add("renamed selected variable", function(fn, frequency) {
  out <- fn(oneway_data(), renamed = x)
  expect_named(out, "renamed")
  expect_equal(sum(out[[1]]$n[!is.na(out[[1]]$cum)]), 6)
})
oneway_add("computed logical expression", function(fn, frequency) {
  out <- fn(oneway_data(), positive = x > 1)$positive
  expect_equal(out$n[!is.na(out$cum)], c(3, 2, 1))
})
oneway_add("computed arithmetic expression", function(fn, frequency) {
  out <- fn(oneway_data(), parity = x %% 2)$parity
  expect_equal(out$n[!is.na(out$cum)], c(1, 4, 1))
})
oneway_add("data pronoun expression", function(fn, frequency) {
  out <- fn(oneway_data(), parity = .data$x %% 2)$parity
  expect_equal(out$n[!is.na(out$cum)], c(1, 4, 1))
})
oneway_add("environment pronoun expression", function(fn, frequency) {
  threshold <- 1
  out <- fn(oneway_data(), high = x > .env$threshold)$high
  expect_equal(out$n[!is.na(out$cum)], c(3, 2, 1))
})
oneway_add("nonsyntactic column names", function(fn, frequency) {
  d <- tibble::tibble(`annual income` = c(1, 1, 2))
  expect_named(fn(d, `annual income`), "annual income")
})
oneway_add("Unicode column names", function(fn, frequency) {
  d <- tibble::tibble(x = c(1, 1, 2))
  names(d) <- "\u6536\u5165"
  out <- fn(d, tidyselect::everything())
  expect_named(out, names(d))
})
oneway_add("reserved measured name keeps its name", function(fn, frequency) {
  # Measured names become list names, never output columns, so cannot collide.
  d <- tibble::tibble(n = c("a", "b", "a"))
  expect_no_message(out <- fn(d, n))
  expect_named(out, "n")
  expect_equal(out[[1]]$n[1:2], c(2, 1))
})
oneway_add("reserved value group is renamed", function(fn, frequency) {
  d <- oneway_data()
  names(d)[1] <- "value"
  expect_message(out <- fn(d, x, .by = value), "renamed")
  expect_true(".value" %in% names(out$x))
})
oneway_add(
  "reserved group name with occupied dotted destination errors",
  function(fn, frequency) {
    d <- tibble::tibble(n = 1:2, .n = 3:4, x = 1:2)
    expect_message(
      expect_error(fn(d, x, .by = c(n, .n)), "new name is also taken"),
      "renamed"
    )
    expect_named(fn(tibble::tibble(n = 1:2, .n = 3:4)), c("n", ".n"))
  }
)
oneway_add("matrix column rejected", function(fn, frequency) {
  d <- tibble::tibble(x = matrix(1:4, nrow = 2))
  expect_error(fn(d), "Matrix")
})
oneway_add("nested data frame column rejected", function(fn, frequency) {
  d <- tibble::tibble(x = data.frame(a = 1:2))
  expect_error(fn(d), "Matrix")
})
oneway_add("invalid output type rejected", function(fn, frequency) {
  expect_error(fn(oneway_data(), x, .type = "wrong"), "must be one of")
})
oneway_add("missing selected column rejected", function(fn, frequency) {
  expect_error(fn(oneway_data(), absent), "absent")
})
oneway_add("missing grouping column rejected", function(fn, frequency) {
  expect_error(fn(oneway_data(), x, .by = absent), "absent")
})
oneway_add("NA descending flag rejected", function(fn, frequency) {
  expect_error(
    fn(oneway_data(), x, .desc = NA),
    "single.*logical|missing value"
  )
})
oneway_add("vector descending flag rejected", function(fn, frequency) {
  expect_error(
    fn(oneway_data(), x, .desc = c(TRUE, FALSE)),
    "single.*logical|length"
  )
})
oneway_add("list values count complete identities", function(fn, frequency) {
  d <- tibble::tibble(x = list(1:2, 2:1, 1:2))
  before <- d
  out <- fn(d)$x
  expect_equal(out$n[!is.na(out$cum)], c(2, 1))
  expect_identical(d, before)
})
oneway_add("nested lists count without flattening", function(fn, frequency) {
  a <- list(k = list(1:3))
  b <- list(k = list(3:1))
  d <- tibble::tibble(x = list(a, b, a))
  out <- fn(d)$x
  expect_equal(out$n[!is.na(out$cum)], c(2, 1))
})
oneway_add("NULL list entries remain categories", function(fn, frequency) {
  d <- tibble::tibble(x = list(NULL, 1, NULL))
  out <- fn(d)$x
  observed <- out[!is.na(out$cum), ]
  expect_equal(sort(observed$n), c(1, 2))
  if (!frequency) {
    expect_equal(observed$n[vapply(observed$value, is.null, logical(1))], 2)
  } else {
    expect_equal(observed$n[observed$value == "NULL"], 2)
  }
  expect_equal(sum(out$valid, na.rm = TRUE), 100)
})
oneway_add(
  "variable labels and input attributes preserved",
  function(fn, frequency) {
    d <- oneway_data()
    attr(d$x, "label") <- "income"
    before <- d
    out <- fn(d, x)
    expect_identical(d, before)
    expect_equal(sum(out$x$n[!is.na(out$x$cum)]), nrow(d))
  }
)
oneway_add(
  "labelled numeric values use original frequencies",
  function(fn, frequency) {
    d <- tibble::tibble(
      x = haven::labelled(c(1, 2, 1, NA), c(one = 1, two = 2))
    )
    out <- fn(d)$x
    expect_equal(out$n[!is.na(out$cum)], c(2, 1, 1))
    if (frequency) {
      expect_equal(out$value[1:2], c("one", "two"))
    } else {
      expect_s3_class(out$value, "haven_labelled")
    }
  }
)
oneway_add(
  "SPSS user missing excluded from valid denominator",
  function(fn, frequency) {
    d <- tibble::tibble(
      x = haven::labelled_spss(c(1, 2, 99, NA, 1), na_values = 99)
    )
    out <- fn(d)$x
    o <- out[!is.na(out$cum), ]
    expect_equal(o$n, c(2, 1, 1, 1))
    expect_equal(o$valid[1:2], c(200 / 3, 100 / 3))
    expect_true(all(is.na(o$valid[3:4])))
  }
)
oneway_add("tagged missing values retain count mass", function(fn, frequency) {
  d <- tibble::tibble(x = haven::labelled(c(1, haven::tagged_na("a"), NA, 1)))
  out <- fn(d)$x
  o <- out[!is.na(out$cum), ]
  expect_equal(sum(o$n), 4)
  expect_equal(sum(o$n[is.na(o$valid)]), 2)
  expect_equal(o$valid[!is.na(o$valid)], 100)
})
oneway_add("data table input unchanged", function(fn, frequency) {
  skip_if_not_installed("data.table")
  d <- data.table::data.table(x = c(1, 1, 2))
  before <- data.table::copy(d)
  out <- fn(d, x)
  expect_named(out, "x")
  expect_identical(d, before)
  expect_identical(class(out$x), c("data.table", "data.frame"))
})
oneway_add(
  "grouped descending order within each group",
  function(fn, frequency) {
    d <- tibble::tibble(
      g = rep(c("A", "B"), each = 5),
      x = c(1, 2, 2, 2, NA, 1, 1, 2, 2, 2)
    )
    out <- fn(d, x, .by = g, .desc = TRUE)$x
    observed <- out[!is.na(out$cum), ]
    expect_equal(observed$n, c(3, 1, 1, 3, 2))
    expect_equal(observed$cum, c(60, 80, 100, 60, 100))
  }
)
oneway_add("permutation preserves counts and order", function(fn, frequency) {
  d <- oneway_data()
  expect_identical(fn(d, x, y), fn(d[c(6, 4, 2, 5, 1, 3), ], x, y))
})
oneway_add(
  "duplication doubles counts preserves percentages",
  function(fn, frequency) {
    d <- oneway_data()
    a <- fn(d, x)$x
    b <- fn(dplyr::bind_rows(d, d), x)$x
    expect_equal(b$n, a$n * 2)
    expect_identical(b$value, a$value)
    expect_equal(b$percent, a$percent)
    expect_equal(b$valid, a$valid)
  }
)
oneway_add(
  "observed Total label is retained alongside marginal row",
  function(fn, frequency) {
    out <- fn(tibble::tibble(x = c("Total", "Total", "a")))$x
    expect_equal(out$n[out$value == "Total"], if (frequency) c(2, 3) else 2)
    expect_equal(sum(out$n[!is.na(out$cum)]), 3)
  }
)
oneway_add(
  "measured variables keep distinct missing denominators",
  function(fn, frequency) {
    d <- tibble::tibble(x = c(1, 2, NA, NA), y = c(1, 2, 2, NA))
    out <- fn(d)
    expect_equal(out$x$valid[1:2], c(50, 50))
    expect_equal(out$y$valid[1:2], c(100 / 3, 200 / 3))
  }
)
oneway_add(
  "grouped table includes variable identity and independent totals",
  function(fn, frequency) {
    d <- oneway_data()
    out <- fn(d, x, y, .by = g, .type = "tibble")
    expect_identical(unique(out$variable), c("x", "y"))
    expect_true("g" %in% names(out))
    for (v in c("x", "y")) {
      expect_equal(sum(out$n[out$variable == v & !is.na(out$cum)]), nrow(d))
    }
  }
)
oneway_add(
  "two variables with equal values remain separate",
  function(fn, frequency) {
    d <- tibble::tibble(x = c(1, 1, 2), y = c(1, 1, 2))
    out <- fn(d)
    expect_named(out, c("x", "y"))
    expect_identical(out$x, out$y)
  }
)
stopifnot(length(oneway_cases) == 100L)
for (oneway_function in c("tab1", "fre1")) {
  for (oneway_i in seq_along(oneway_cases)) {
    local({
      function_name <- oneway_function
      case <- oneway_cases[[oneway_i]]
      id <- oneway_i
      test_that(
        sprintf("%s coverage %03d: %s", function_name, id, case$title),
        {
          case$check(
            get(function_name, mode = "function"),
            function_name == "fre1"
          )
        }
      )
    })
  }
}
