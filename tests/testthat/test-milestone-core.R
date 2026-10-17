# Regression contracts for the first maintenance milestone. Expectations use
# scalar base-R calculations and independent group counts, not package helpers.

test_that("milestone as_numeric parses character values without losing positions", {
  expect_equal(
    as_numeric(c("1", "$2,500.50", NA, "3e-2")),
    c(1, 2500.5, NA, 0.03)
  )
  expect_identical(as_numeric(character()), numeric())
})

test_that("milestone variables searches attribute labels without a label column", {
  d <- data.frame(id = 1:3, income = 4:6)
  attr(d$income, "label") <- "Annual household resources"
  expect_equal(
    variables(d)$label,
    c(NA_character_, "Annual household resources")
  )
  expect_identical(variables_search(d, "household")$name, "income")
})

test_that("milestone grouped tab1 keeps missing group keys and group counts", {
  d <- tibble::tibble(g = c("A", "A", "B", NA_character_), x = c(1, 2, 1, 2))
  out <- tab1(d, x, .by = g)$x
  expect_true("g" %in% names(out))
  counts <- dplyr::summarise(out, n = sum(n), .by = g)
  expect_equal(
    counts$n[match(c("A", "B", NA_character_), counts$g)],
    c(2, 1, 1)
  )
})

test_that("milestone fre1 adds totals within each retained group", {
  d <- tibble::tibble(g = c("A", "A", "B", NA_character_), x = c(1, 2, 1, 2))
  out <- fre1(d, x, .by = g, .type = "list")$x
  totals <- out[!is.na(out$value) & out$value == "Total", ]
  expect_equal(
    totals$n[match(c("A", "B", NA_character_), totals$g)],
    c(2, 1, 1)
  )
  expect_equal(totals$percent, rep(100, 3))
})

test_that("milestone frequency defaults remain usable as data", {
  d <- tibble::tibble(x = c("a", "a", "b"), y = c("u", "v", "u"))
  expect_s3_class(fre(d, x), "tbl_df")
  expect_named(fre1(d, x), "x")
  out <- fre2(d, x, y)
  expect_s3_class(out, "tbl_df")
  expect_equal(tail(out$total, 1), 3)
})

test_that("milestone quantile ties stay together after row permutation", {
  x <- c(rep(1, 8), rep(2, 4), rep(3, 4))
  expect_warning(out <- cut_quantile(x, n = 4), "[Cc]ollaps|[Tt]ie|[Ff]ewer")
  expect_true(all(vapply(
    split(as.integer(out), x),
    function(z) length(unique(z)) == 1L,
    logical(1)
  )))
  p <- rev(seq_along(x))
  other <- suppressWarnings(cut_quantile(x[p], n = 4))
  expect_identical(as.integer(other)[order(p)], as.integer(out))
})

test_that("milestone row helpers return atomic vectors with explicit missing semantics", {
  d <- tibble::tibble(a = c(1, NA_real_, 4), b = c(3, NA_real_, NA_real_))
  expect_equal(row_median(d), c(2, NA_real_, 4))
  expect_equal(row_var(d), c(2, NA_real_, NA_real_))
  expect_equal(row_sd(d), c(sqrt(2), NA_real_, NA_real_))
  expect_equal(row_mean(d), c(2, NA_real_, 4))
  expect_equal(row_min(d), c(1, NA_real_, 4))
  expect_equal(row_max(d), c(3, NA_real_, 4))
  expect_equal(row_unique(d), c(2, 1, 2))
})

test_that("milestone reserved grouping count names retain independent keys", {
  d <- tibble::tibble(n = c("A", "A", "B"), x = c(1, 2, 1))
  out <- suppressMessages(tab1(d, x, .by = n))$x
  expect_true(".n" %in% names(out))
  expect_equal(sum(out$n), 3)
  expect_setequal(out$.n, c("A", "B"))
})

# Character parsing must work for real imported columns, including sparse and
# empty ones. These fixtures also catch precision loss and row recycling.
.milestone_parse_cases <- list(
  integers = list(c("1", "2", "3"), c(1, 2, 3)),
  decimals = list(c("1.25", "2.50", "0.01"), c(1.25, 2.5, 0.01)),
  signs = list(c("-2", "+3", "-0.5"), c(-2, 3, -0.5)),
  exponent = list(c("1e5", "2.5e-3", "3E10"), c(1e5, 0.0025, 3e10)),
  dollars = list(c("$1,234.56", "$500.00"), c(1234.56, 500)),
  currency = list(c("\u20ac500.25", "\u00a31,000"), c(500.25, 1000)),
  spaces = list(c(" 1 ", "\t2.5", "3\n"), c(1, 2.5, 3)),
  negative_currency = list(c("$-12.50", "-1,000.25"), c(-12.5, -1000.25)),
  grouped_thousands = list(c("1,234,567", "12,345"), c(1234567, 12345)),
  embedded_units = list(c("10 kg", "20.5 km"), c(10, 20.5)),
  prefixes = list(c("USD 100.5", "EUR 20"), c(100.5, 20)),
  missing_middle = list(c("1", NA, "3"), c(1, NA, 3)),
  missing_edges = list(c(NA, "2", NA), c(NA, 2, NA)),
  entirely_missing = list(rep(NA_character_, 3), rep(NA_real_, 3)),
  empty = list(character(), numeric()),
  singleton = list("42", 42),
  nonnumeric = list(c("apple", "pear"), c(NA_real_, NA_real_)),
  mixed_nonnumeric = list(c("1", "bad", "3"), c(1, NA, 3)),
  blank_values = list(c("", " ", "4"), c(NA, NA, 4)),
  zeros = list(c("0", "-0", "0.000"), c(0, 0, 0)),
  leading_zeros = list(c("00012", "000.125"), c(12, 0.125)),
  small_numbers = list(c("0.000000001", "2e-12"), c(1e-9, 2e-12)),
  large_numbers = list(c("1000000000", "999999999999"), c(1e9, 999999999999))
)
for (.scenario in names(.milestone_parse_cases)) {
  test_that(paste("milestone as_numeric imported character", .scenario), {
    case <- .milestone_parse_cases[[.scenario]]
    before <- case[[1]]
    out <- suppressWarnings(as_numeric(case[[1]]))
    expect_type(out, "double")
    expect_length(out, length(case[[1]]))
    expect_equal(as.vector(out), case[[2]], tolerance = 1e-14)
    expect_identical(case[[1]], before)
    d <- tibble::tibble(raw = case[[1]])
    converted <- suppressWarnings(dplyr::mutate(d, value = as_numeric(raw)))
    expect_equal(as.vector(converted$value), case[[2]], tolerance = 1e-14)
  })
}

.milestone_label <- function(x, label) {
  attr(x, "label") <- label
  x
}
.milestone_metadata_cases <- list(
  no_labels = data.frame(a = 1:3, b = 4:6),
  first_label = data.frame(a = .milestone_label(1:3, "First"), b = 4:6),
  last_label = data.frame(a = 1:3, b = .milestone_label(4:6, "Last")),
  both_labels = data.frame(
    a = .milestone_label(1:3, "First"),
    b = .milestone_label(4:6, "Last")
  ),
  empty_label = data.frame(a = .milestone_label(1:3, ""), b = 4:6),
  missing_label = data.frame(a = .milestone_label(1:3, NA_character_), b = 4:6),
  integer = data.frame(a = .milestone_label(1:3, "Integer")),
  double = data.frame(a = .milestone_label(c(1.5, NA, 3.5), "Measure")),
  logical = data.frame(a = .milestone_label(c(TRUE, FALSE, NA), "Flag")),
  factor = data.frame(
    a = .milestone_label(factor(c("a", "b", NA)), "Category")
  ),
  ordered = data.frame(
    a = .milestone_label(ordered(c("a", "b", "a")), "Ordinal")
  ),
  date = data.frame(a = .milestone_label(as.Date("2024-01-01") + 0:2, "Date")),
  datetime = data.frame(
    a = .milestone_label(as.POSIXct("2024-01-01", tz = "UTC") + 0:2, "Time")
  ),
  haven = data.frame(
    a = haven::labelled(c(1, 2, NA), c(Yes = 1, No = 2), label = "Response")
  ),
  list_column = tibble::tibble(
    a = .milestone_label(list(1, 2:3, NULL), "List")
  ),
  zero_rows = data.frame(a = .milestone_label(numeric(), "Empty measure")),
  zero_columns = data.frame(),
  unicode = stats::setNames(
    data.frame(a = .milestone_label(1:3, "\u5c45\u4f4f\u5730\u533a")),
    "\u5730\u533a"
  ),
  non_syntactic = stats::setNames(
    data.frame(a = .milestone_label(1:3, "Annual income")),
    "annual income"
  ),
  literal_label_column = data.frame(
    label = c("not metadata", "x", "y"),
    a = 1:3
  ),
  literal_name_column = data.frame(
    name = .milestone_label(1:3, "Identifier"),
    a = 4:6
  ),
  tibble = tibble::tibble(a = .milestone_label(1:3, "Tibble measure"), b = 4:6)
)
for (.scenario in names(.milestone_metadata_cases)) {
  test_that(paste("milestone variables attribute metadata", .scenario), {
    d <- .milestone_metadata_cases[[.scenario]]
    before <- unserialize(serialize(d, NULL))
    out <- variables(d)
    expect_s3_class(out, "tbl_df")
    expect_identical(out$name, names(d))
    labels <- lapply(d, attr, which = "label", exact = TRUE)
    expected <- vapply(
      labels,
      function(x) {
        if (is.null(x) || is.na(x) || identical(x, "")) NA_character_ else x
      },
      character(1)
    )
    if (any(!is.na(expected))) {
      expect_identical(out$label, unname(expected))
    } else {
      expect_false("label" %in% names(out))
    }
    expect_identical(d, before)
  })
}

.milestone_search_data <- tibble::tibble(
  id = .milestone_label(1:3, "Respondent number"),
  income = .milestone_label(4:6, "Annual household resources"),
  region = .milestone_label(c("a", "b", "a"), "\u5c45\u4f4f\u5730\u533a"),
  unlabelled = c("household text", "x", "y")
)

for (.scenario in names(.milestone_metadata_cases)) {
  test_that(paste("milestone codebook attribute metadata", .scenario), {
    d <- .milestone_metadata_cases[[.scenario]]
    before <- unserialize(serialize(d, NULL))
    out <- codebook(d)
    expect_s3_class(out, "tbl_df")
    expect_identical(out$variable, names(d))
    expect_equal(
      out$n,
      unname(vapply(d, function(x) sum(!is.na(x)), integer(1)))
    )
    expected_labels <- vapply(
      d,
      function(x) {
        label <- attr(x, "label", exact = TRUE)
        if (is.null(label) || is.na(label) || identical(label, "")) {
          NA_character_
        } else {
          label
        }
      },
      character(1)
    )
    if (any(!is.na(expected_labels))) {
      expect_identical(out$label, unname(expected_labels))
    } else {
      expect_false("label" %in% names(out))
    }
    expect_identical(d, before)
  })
}
.milestone_search_cases <- list(
  label_only = list("household", "income"),
  label_case = list("HOUSEHOLD", "income"),
  label_wildcard = list("Annual*resources", "income"),
  label_question = list("Respondent numbe?", "id"),
  label_one_or_more = list("Annual~resources", "income"),
  unicode = list("\u5730\u533a", "region"),
  name_exact = list("income", "income"),
  name_case = list("INCOME", "income"),
  name_wildcard = list("inc*", "income"),
  name_question = list("reg?on", "region"),
  name_one_or_more = list("un~led", "unlabelled"),
  substring = list("come", "income"),
  no_match = list("absent-field", character()),
  all_names = list("*", names(.milestone_search_data)),
  empty_pattern = list("", names(.milestone_search_data)),
  ordered_selection = list("*", c("region", "id"), c("region", "id")),
  selection_excludes_match = list("household", character(), c("id", "region")),
  selection_includes_match = list("resources", "income", c("income", "region")),
  omitted_metadata = list("unlabelled", "unlabelled", "unlabelled"),
  ignore_cell_content = list("text", character()),
  mixed_name_and_label = list("r", c("id", "income", "region"))
)
for (.scenario in names(.milestone_search_cases)) {
  test_that(paste("milestone variables_search names and metadata", .scenario), {
    case <- .milestone_search_cases[[.scenario]]
    vars <- if (length(case) > 2L) case[[3]] else names(.milestone_search_data)
    before <- unserialize(serialize(.milestone_search_data, NULL))
    out <- variables_search(
      .milestone_search_data,
      case[[1]],
      tidyselect::all_of(vars)
    )
    expect_s3_class(out, "tbl_df")
    expect_identical(out$name, case[[2]])
    expect_identical(.milestone_search_data, before)
  })
}
test_that("milestone variables empty and reordered selection retain their metadata", {
  expect_identical(
    variables(.milestone_search_data, tidyselect::all_of(character()))$name,
    character()
  )
  expect_identical(
    variables(.milestone_search_data, region, id)$name,
    c("region", "id")
  )
  expect_identical(variables_search(data.frame(), "*")$name, character())
})

.milestone_row_cases <- list(
  doubles = data.frame(a = c(1.5, 2.5, 3.5), b = c(3, 6, 9), c = c(-1, 0, 1)),
  integers = data.frame(a = 1:4, b = 4:1),
  logical = data.frame(a = c(TRUE, FALSE, NA), b = c(FALSE, TRUE, TRUE)),
  mixed_storage = data.frame(
    a = 1:3,
    b = c(1.5, 2, 3.5),
    c = c(TRUE, FALSE, TRUE)
  ),
  partial_missing = data.frame(
    a = c(1, NA, 5),
    b = c(NA, 2, 3),
    c = c(3, 4, NA)
  ),
  all_missing_row = data.frame(a = c(1, NA, 4), b = c(3, NA, NA)),
  all_missing_data = data.frame(a = rep(NA_real_, 3), b = rep(NA_integer_, 3)),
  nan_and_na = data.frame(
    a = c(NaN, NA, 1),
    b = c(NA, NaN, NaN),
    c = c(NA, NaN, 2)
  ),
  positive_infinity = data.frame(a = c(Inf, 1), b = c(2, Inf)),
  negative_infinity = data.frame(a = c(-Inf, 1), b = c(2, -Inf)),
  opposing_infinity = data.frame(a = c(Inf, -Inf), b = c(-Inf, Inf)),
  one_column = data.frame(a = c(1, NA, 3)),
  one_row = data.frame(a = 2, b = 8, c = 5),
  duplicates = data.frame(a = c(2, 2, 4), b = c(2, 2, 4), c = c(2, 2, NA)),
  negative_values = data.frame(a = c(-5, -2), b = c(-1, -8)),
  large_values = data.frame(a = c(1e100, 2e100), b = c(3e100, 4e100)),
  small_values = data.frame(a = c(1e-100, 2e-100), b = c(3e-100, 4e-100)),
  zero_rows = data.frame(a = numeric(), b = integer(), c = logical()),
  zero_columns = structure(
    list(),
    class = "data.frame",
    row.names = c(NA_integer_, -3L)
  ),
  entirely_empty = data.frame(),
  null_input = NULL,
  non_syntactic = stats::setNames(
    data.frame(a = 1:3, b = 3:1),
    c("a value", "\u53d8\u91cf")
  ),
  tibble = tibble::tibble(a = c(1, 2, NA), b = c(4, 2, 5)),
  mixed_missing_repeats = data.frame(
    a = c(NA, 3, 2),
    b = c(NaN, 3, NA),
    c = c(4, 3, 2)
  )
)
.milestone_row_reference <- function(d, operation) {
  vapply(
    seq_len(nrow(d)),
    function(i) {
      x <- as.numeric(unlist(d[i, , drop = FALSE], use.names = FALSE))
      observed <- x[!is.na(x)]
      switch(
        operation,
        row_sum = sum(observed),
        row_mean = if (length(observed)) mean(observed) else NA_real_,
        row_min = if (length(observed)) min(observed) else NA_real_,
        row_max = if (length(observed)) max(observed) else NA_real_,
        row_median = if (length(observed)) {
          stats::median(observed)
        } else {
          NA_real_
        },
        row_var = if (length(observed) > 1L) stats::var(observed) else NA_real_,
        row_sd = if (length(observed) > 1L) stats::sd(observed) else NA_real_,
        row_unique = length(unique(observed)) + as.integer(anyNA(x)),
        row_miss = sum(is.na(x)),
        row_non_miss = sum(!is.na(x))
      )
    },
    numeric(1)
  )
}
.milestone_row_functions <- c(
  "row_mean",
  "row_sum",
  "row_min",
  "row_max",
  "row_median",
  "row_var",
  "row_sd",
  "row_unique",
  "row_miss",
  "row_non_miss"
)
for (.function_name in .milestone_row_functions) {
  for (.scenario in names(.milestone_row_cases)) {
    test_that(paste("milestone", .function_name, "row semantics", .scenario), {
      d <- .milestone_row_cases[[.scenario]]
      row_fn <- get(.function_name, mode = "function")
      if (is.null(d) || ncol(d) == 0L) {
        expect_error(row_fn(d), "[Cc]olumn|[Nn]umeric|[Ee]mpty|NULL")
      } else {
        before <- unserialize(serialize(d, NULL))
        expected <- .milestone_row_reference(d, .function_name)
        extrema <- .function_name %in% c("row_min", "row_max")
        storage <- typeof(unlist(d, use.names = FALSE))
        if (extrema && storage == "logical") {
          expected <- as.logical(expected)
        }
        if (extrema && storage == "integer") {
          expected <- as.integer(expected)
        }
        out <- suppressWarnings(row_fn(d))
        expect_true(is.atomic(out))
        expect_true(is.numeric(out) || is.logical(out))
        expect_null(dim(out))
        expect_length(out, nrow(d))
        expect_equal(out, expected, tolerance = 1e-12)
        if (!.function_name %in% c("row_unique", "row_miss", "row_non_miss")) {
          expect_type(out, if (extrema) storage else "double")
        }
        expect_identical(d, before)
        in_mutate <- suppressWarnings(dplyr::mutate(
          tibble::as_tibble(d),
          observed = row_fn(tidyselect::everything())
        ))
        expect_equal(in_mutate$observed, expected, tolerance = 1e-12)
        expect_identical(d, before)
      }
    })
  }
}
for (.function_name in setdiff(
  .milestone_row_functions,
  c("row_miss", "row_non_miss")
)) {
  test_that(
    paste(
      "milestone",
      .function_name,
      "rejects unsupported columns without mutation"
    ),
    {
      row_fn <- get(.function_name, mode = "function")
      for (x in list(c("1", "2"), factor(c("1", "2")), list(1, 2))) {
        d <- tibble::tibble(a = 1:2, b = x)
        before <- unserialize(serialize(d, NULL))
        expect_error(row_fn(d), "[Nn]umeric|[Ll]ogical|[Cc]olumn|[Ss]upport")
        expect_identical(d, before)
      }
    }
  )
}

.milestone_quantile_cases <- list(
  quartiles = list(x = 1:100, n = 4),
  deciles = list(x = 1:100, n = 10),
  halves = list(x = 1:20, n = 2),
  one_interval = list(x = 1:8, n = 1),
  negative = list(x = -20:-1, n = 4),
  fractional = list(x = c(0.1, 0.3, 0.8, 2.1, 4.2, 9.9), n = 3),
  uneven_sample = list(x = c(2, 4, 7, 11, 13, 18, 29), n = 4),
  shuffled = list(x = c(8, 1, 6, 3, 4, 7, 2, 5), n = 4),
  missing_edges = list(x = c(NA, 1:12, NA), n = 3),
  missing_middle = list(x = c(1:5, NA, 6:10), n = 4),
  nan_missing = list(x = c(1:5, NaN, 6:10), n = 2),
  two_values = list(x = rep(c(1, 2), each = 20), n = 2),
  two_values_collapsed = list(x = rep(c(1, 2), each = 20), n = 4),
  lower_plateau = list(x = c(rep(1, 12), 2:5), n = 4),
  upper_plateau = list(x = c(1:4, rep(5, 12)), n = 4),
  middle_plateau = list(x = rep(c(1, 2, 3), c(4, 8, 4)), n = 4),
  plateau_with_missing = list(x = c(NA, rep(c(1, 2), each = 20), NA), n = 4),
  labels = list(x = 1:20, n = 4, labels = c("Q1", "Q2", "Q3", "Q4")),
  collapsed_labels = list(
    x = rep(c(1, 2), each = 20),
    n = 4,
    labels = c("Low", "High")
  ),
  integer_codes = list(x = 1:20, n = 4, labels = FALSE),
  collapsed_integer_codes = list(
    x = rep(c(1, 2), each = 20),
    n = 4,
    labels = FALSE
  ),
  more_bins_than_rows = list(x = c(1, 3, 9), n = 6),
  asymmetric_duplicates = list(x = c(rep(-4, 4), rep(0, 8), 2, 4, 8, 16), n = 4)
)
for (.scenario in names(.milestone_quantile_cases)) {
  test_that(
    paste("milestone cut_quantile stable value boundaries", .scenario),
    {
      case <- .milestone_quantile_cases[[.scenario]]
      before <- case$x
      raw_breaks <- stats::quantile(
        case$x,
        probs = seq(0, 1, length.out = case$n + 1L),
        na.rm = TRUE
      )
      breaks <- unique(raw_breaks)
      if (length(breaks) < length(raw_breaks)) {
        expect_warning(
          out <- do.call(cut_quantile, case),
          "[Cc]ollaps|[Tt]ie|[Ff]ewer"
        )
      } else {
        expect_no_warning(out <- do.call(cut_quantile, case))
      }
      expected <- base::cut(
        case$x,
        breaks,
        include.lowest = TRUE,
        labels = case$labels,
        ordered_result = TRUE
      )
      expect_equal(out, expected)
      expect_identical(is.na(out), is.na(case$x))
      expect_identical(case$x, before)
      codes <- as.integer(out)
      for (value in unique(case$x[!is.na(case$x)])) {
        expect_length(unique(codes[!is.na(case$x) & case$x == value]), 1L)
      }
      p <- rev(seq_along(case$x))
      shuffled <- case
      shuffled$x <- case$x[p]
      other <- suppressWarnings(do.call(cut_quantile, shuffled))
      expect_identical(as.integer(other)[order(p)], codes)
      if (identical(case$labels, FALSE)) {
        expect_type(out, "integer")
      } else {
        expect_s3_class(out, "ordered")
        expect_equal(nlevels(out), length(breaks) - 1L)
      }
    }
  )
}
.milestone_invalid_quantiles <- list(
  constant = list(x = rep(4, 10)),
  empty = list(x = numeric()),
  all_missing = list(x = rep(NA_real_, 4)),
  all_nan = list(x = rep(NaN, 4)),
  complex_values = list(x = c(1 + 1i, 2 + 1i)),
  matrix_values = list(x = matrix(1:4, nrow = 2)),
  character = list(x = c("1", "2")),
  factor = list(x = factor(c(1, 2))),
  zero_bins = list(x = 1:10, n = 0),
  negative_bins = list(x = 1:10, n = -1),
  fractional_bins = list(x = 1:10, n = 2.5),
  missing_bins = list(x = 1:10, n = NA_real_),
  infinite_bins = list(x = 1:10, n = Inf),
  character_bins = list(x = 1:10, n = "4"),
  vector_bins = list(x = 1:10, n = c(2, 4)),
  absent_bins = list(x = 1:10, n = numeric()),
  short_labels = list(x = 1:20, n = 4, labels = c("L", "H")),
  long_labels = list(x = 1:20, n = 2, labels = letters[1:4]),
  collapsed_original_labels = list(
    x = rep(c(1, 2), each = 20),
    n = 4,
    labels = letters[1:4]
  ),
  null_values = list(x = NULL)
)
for (.scenario in names(.milestone_invalid_quantiles)) {
  test_that(paste("milestone cut_quantile validates", .scenario), {
    case <- .milestone_invalid_quantiles[[.scenario]]
    expect_error(suppressWarnings(do.call(cut_quantile, case)))
  })
}

.milestone_group_base <- tibble::tibble(
  g = c("A", "A", "B", "B", "B", "C"),
  x = c(1, 2, 1, NA, 2, 1),
  y = c("u", "v", "u", "v", NA, "u")
)
.milestone_group_case <- function(d, keys = "g", vars = "x", grouped = FALSE) {
  list(data = d, keys = keys, vars = vars, grouped = grouped)
}
.milestone_group_cases <- list(
  unequal_sizes = .milestone_group_case(.milestone_group_base),
  missing_key = .milestone_group_case(dplyr::mutate(
    .milestone_group_base,
    g = replace(g, 6, NA_character_)
  )),
  entirely_missing_key = .milestone_group_case(dplyr::mutate(
    .milestone_group_base,
    g = NA_character_
  )),
  integer_keys = .milestone_group_case(dplyr::mutate(
    .milestone_group_base,
    g = c(1L, 1L, 2L, 2L, 2L, 3L)
  )),
  logical_keys = .milestone_group_case(dplyr::mutate(
    .milestone_group_base,
    g = c(TRUE, TRUE, FALSE, FALSE, NA, NA)
  )),
  factor_keys = .milestone_group_case(dplyr::mutate(
    .milestone_group_base,
    g = factor(g, levels = c("A", "B", "C", "unused"))
  )),
  ordered_keys = .milestone_group_case(dplyr::mutate(
    .milestone_group_base,
    g = ordered(g, levels = c("C", "B", "A"))
  )),
  date_keys = .milestone_group_case(dplyr::mutate(
    .milestone_group_base,
    g = as.Date("2024-01-01") + c(0, 0, 1, 1, 1, 2)
  )),
  two_keys = .milestone_group_case(
    dplyr::mutate(.milestone_group_base, h = c(1, 2, 1, 1, 2, 1)),
    keys = c("g", "h")
  ),
  two_missing_keys = .milestone_group_case(
    dplyr::mutate(
      .milestone_group_base,
      g = c("A", "A", NA, NA, "B", "B"),
      h = c(1, NA, 1, NA, 1, NA)
    ),
    keys = c("g", "h")
  ),
  non_syntactic_key = .milestone_group_case(
    dplyr::rename(.milestone_group_base, `group name` = g),
    keys = "group name"
  ),
  numeric_values = .milestone_group_case(dplyr::mutate(
    .milestone_group_base,
    x = x / 2
  )),
  factor_values = .milestone_group_case(dplyr::mutate(
    .milestone_group_base,
    x = factor(x, levels = 1:3)
  )),
  ordered_values = .milestone_group_case(dplyr::mutate(
    .milestone_group_base,
    x = ordered(x)
  )),
  logical_values = .milestone_group_case(dplyr::mutate(
    .milestone_group_base,
    x = x == 1
  )),
  labelled_values = .milestone_group_case(dplyr::mutate(
    .milestone_group_base,
    x = haven::labelled(x, c(Yes = 1, No = 2))
  )),
  multiple_variables = .milestone_group_case(
    .milestone_group_base,
    vars = c("x", "y")
  ),
  existing_grouping = .milestone_group_case(
    .milestone_group_base,
    vars = c("x", "y"),
    grouped = TRUE
  ),
  one_row_per_group = .milestone_group_case(dplyr::mutate(
    .milestone_group_base,
    g = letters[1:6]
  )),
  same_value_each_group = .milestone_group_case(dplyr::mutate(
    .milestone_group_base,
    x = 1
  )),
  missing_values_group = .milestone_group_case(dplyr::mutate(
    .milestone_group_base,
    x = ifelse(g == "B", NA_real_, x)
  )),
  reserved_n_key = .milestone_group_case(
    dplyr::rename(.milestone_group_base, n = g),
    keys = "n"
  )
)
.milestone_group_key <- function(d, keys) {
  parts <- lapply(d[keys], function(x) {
    ifelse(is.na(x), "<missing-key>", as.character(x))
  })
  do.call(paste, c(parts, sep = "\r"))
}
for (.function_name in c("tab1", "fre1")) {
  for (.scenario in names(.milestone_group_cases)) {
    test_that(
      paste("milestone", .function_name, "preserves groups", .scenario),
      {
        case <- .milestone_group_cases[[.scenario]]
        d <- case$data
        before <- unserialize(serialize(d, NULL))
        vars <- case$vars
        keys <- case$keys
        fn <- get(.function_name, mode = "function")
        if (case$grouped) {
          d <- dplyr::group_by(d, dplyr::across(tidyselect::all_of(keys)))
          out <- fn(d, tidyselect::all_of(vars), .type = "list")
        } else {
          out <- fn(
            d,
            tidyselect::all_of(vars),
            .by = tidyselect::all_of(keys),
            .type = "list"
          )
        }
        expect_named(out, vars)
        expected_counts <- table(.milestone_group_key(case$data, keys))
        output_keys <- ifelse(keys == "n", ".n", keys)
        for (measure in vars) {
          frame <- out[[measure]]
          expect_s3_class(frame, "tbl_df")
          expect_true(all(output_keys %in% names(frame)))
          if (.function_name == "fre1") {
            totals <- frame[!is.na(frame$value) & frame$value == "Total", ]
            total_keys <- .milestone_group_key(totals, output_keys)
            expect_setequal(total_keys, names(expected_counts))
            expect_equal(totals$n, as.numeric(expected_counts[total_keys]))
            expect_equal(totals$percent, rep(100, length(expected_counts)))
            ordinary <- frame[
              is.na(frame$value) |
                !frame$value %in% c("Total", "Valid Total", "Missing Total"),
            ]
          } else {
            ordinary <- frame
          }
          observed_counts <- tapply(
            ordinary$n,
            .milestone_group_key(ordinary, output_keys),
            sum
          )
          observed_percent <- tapply(
            ordinary$percent,
            .milestone_group_key(ordinary, output_keys),
            sum
          )
          expect_equal(
            as.numeric(observed_counts[names(expected_counts)]),
            as.numeric(expected_counts)
          )
          expect_equal(
            as.numeric(observed_percent[names(expected_counts)]),
            rep(100, length(expected_counts))
          )
        }
        expect_identical(case$data, before)
      }
    )
  }
}

.milestone_frequency_cases <- list(
  balanced = tibble::tibble(
    x = c("a", "a", "b", "b"),
    y = c("u", "v", "u", "v")
  ),
  unequal_margins = tibble::tibble(
    x = c("a", "a", "a", "b", "b"),
    y = c("u", "u", "v", "u", "v")
  ),
  singleton = tibble::tibble(x = "a", y = "u"),
  sparse_cross = tibble::tibble(x = c("a", "b", "c"), y = c("u", "v", "w")),
  integers = tibble::tibble(x = c(1L, 2L, 1L), y = c(3L, 4L, 3L)),
  doubles = tibble::tibble(x = c(1.5, 2.5, 1.5), y = c(0.1, 0.2, 0.1)),
  negative = tibble::tibble(x = c(-1, -2, -1), y = c(-3, -4, -3)),
  logical = tibble::tibble(x = c(TRUE, FALSE, TRUE), y = c(TRUE, TRUE, FALSE)),
  factor = tibble::tibble(
    x = factor(c("a", "b", "a")),
    y = factor(c("u", "u", "v"))
  ),
  ordered = tibble::tibble(
    x = ordered(c("a", "b", "a")),
    y = ordered(c("u", "u", "v"))
  ),
  date = tibble::tibble(
    x = as.Date("2024-01-01") + c(0, 1, 0),
    y = c("u", "v", "u")
  ),
  missing_x = tibble::tibble(x = c("a", NA, "b"), y = c("u", "u", "v")),
  missing_y = tibble::tibble(x = c("a", "a", "b"), y = c("u", NA, "v")),
  both_missing = tibble::tibble(
    x = c("a", NA, "b", NA),
    y = c("u", "u", NA, NA)
  ),
  all_x_missing = tibble::tibble(
    x = rep(NA_character_, 3),
    y = c("u", "u", "v")
  ),
  all_y_missing = tibble::tibble(
    x = c("a", "a", "b"),
    y = rep(NA_character_, 3)
  ),
  labelled = tibble::tibble(
    x = haven::labelled(c(1, 2, 1), c(Yes = 1, No = 2)),
    y = c("u", "v", "u")
  ),
  unicode = tibble::tibble(
    x = c("\u4e2d", "\u6587", "\u4e2d"),
    y = c("u", "v", "u")
  ),
  repeated_rows = tibble::tibble(
    x = rep(c("a", "b"), c(10, 3)),
    y = rep(c("u", "v"), c(10, 3))
  ),
  one_category = tibble::tibble(x = rep("a", 4), y = rep("u", 4)),
  data_frame = data.frame(x = c("a", "a", "b"), y = c("u", "v", "u"))
)
for (.function_name in c("fre", "fre1", "fre2")) {
  for (.scenario in names(.milestone_frequency_cases)) {
    test_that(
      paste(
        "milestone",
        .function_name,
        "data defaults and conserved counts",
        .scenario
      ),
      {
        d <- .milestone_frequency_cases[[.scenario]]
        before <- unserialize(serialize(d, NULL))
        if (.function_name == "fre") {
          out <- fre(d, x)
          expect_s3_class(out, "tbl_df")
          totals <- out[!is.na(out$x) & out$x == "Total", ]
          expect_equal(totals$n, nrow(d))
          expect_equal(totals$percent, 100)
          expect_equal(out, fre(d, x, .type = "tibble"))
        } else if (.function_name == "fre1") {
          out <- fre1(d, x, y)
          expect_named(out, c("x", "y"))
          expect_false(inherits(out, "flextable"))
          for (frame in out) {
            expect_s3_class(frame, "tbl_df")
            totals <- frame[!is.na(frame$value) & frame$value == "Total", ]
            expect_equal(totals$n, nrow(d))
            expect_equal(totals$percent, 100)
          }
          expect_equal(out, fre1(d, x, y, .type = "list"))
        } else {
          out <- fre2(d, x, y)
          expect_s3_class(out, "tbl_df")
          expect_equal(tail(out$total, 1), nrow(d))
          expect_equal(sum(head(out$total, -1)), nrow(d))
          numeric_columns <- setdiff(names(out), c(names(out)[1], "total"))
          expect_equal(
            as.numeric(out[nrow(out), numeric_columns]),
            as.numeric(colSums(as.data.frame(out[
              -nrow(out),
              numeric_columns,
              drop = FALSE
            ])))
          )
          expect_equal(out, fre2(d, x, y, .type = "tibble"))
        }
        expect_identical(d, before)
      }
    )
  }
}
test_that("milestone optional frequency formatting remains explicit", {
  skip_if_not_installed("flextable")
  d <- .milestone_frequency_cases$unequal_margins
  expect_s3_class(fre(d, x, .type = "flextable"), "flextable")
  expect_s3_class(fre1(d, x, y, .type = "flextable"), "flextable")
  expect_s3_class(fre2(d, x, y, .type = "flextable"), "flextable")
  expect_s3_class(fre1(d, x, y, .type = "tibble"), "tbl_df")
})

for (.function_name in .milestone_row_functions) {
  test_that(
    paste(
      "milestone",
      .function_name,
      "accepts an explicit pick within mutate"
    ),
    {
      d <- tibble::tibble(a = c(1, NA, 4), b = c(3, NA, NA), excluded = 100)
      row_fn <- get(.function_name, mode = "function")
      expected <- .milestone_row_reference(d[c("a", "b")], .function_name)
      out <- dplyr::mutate(d, observed = row_fn(dplyr::pick(a, b)))
      expect_equal(out$observed, expected)
      expect_identical(out$excluded, d$excluded)
    }
  )
  test_that(
    paste(
      "milestone",
      .function_name,
      "accepts a data frame argument within mutate"
    ),
    {
      d <- tibble::tibble(a = c(1, NA, 4), b = c(3, NA, NA), excluded = 100)
      selected <- as.data.frame(d[c("a", "b")])
      row_fn <- get(.function_name, mode = "function")
      expected <- .milestone_row_reference(selected, .function_name)
      out <- dplyr::mutate(d, observed = row_fn(selected))
      expect_equal(out$observed, expected)
      expect_identical(out$excluded, d$excluded)
      counter <- new.env(parent = emptyenv())
      counter$n <- 0L
      computed <- dplyr::mutate(
        d,
        observed = row_fn({
          counter$n <- counter$n + 1L
          selected
        })
      )
      expect_equal(computed$observed, expected)
      expect_identical(counter$n, 1L)
    }
  )
  test_that(
    paste(
      "milestone",
      .function_name,
      "keeps selection errors visible within mutate"
    ),
    {
      d <- tibble::tibble(a = 1:3, b = 3:1)
      row_fn <- get(.function_name, mode = "function")
      expect_error(
        dplyr::mutate(d, observed = row_fn(a, missing_column)),
        "missing_column"
      )
      expect_error(
        dplyr::mutate(d, observed = row_fn(dplyr::pick(a, missing_column))),
        "missing_column"
      )
    }
  )
}

for (.scenario in names(.milestone_frequency_cases)) {
  test_that(
    paste("milestone tab preserves counts and missing categories", .scenario),
    {
      d <- .milestone_frequency_cases[[.scenario]]
      out <- tab(d, x)
      counts <- as.vector(table(d$x, useNA = "ifany"))
      expect_equal(sort(out$n), sort(counts[counts > 0L]))
      expect_equal(sum(out$n), nrow(d))
      expect_equal(sum(out$percent), 100)
      if (anyNA(d$x)) {
        expect_true(is.na(tail(out$x, 1L)))
      }
      if (all(is.na(d$x))) expect_true(all(is.na(out$valid)))
    }
  )
  for (.format_function in c("fre", "fre1", "fre2")) {
    test_that(
      paste("milestone optional formatted counts", .format_function, .scenario),
      {
        skip_if_not_installed("flextable")
        d <- .milestone_frequency_cases[[.scenario]]
        before <- unserialize(serialize(d, NULL))
        out <- switch(
          .format_function,
          fre = fre(d, x, .type = "flextable"),
          fre1 = fre1(d, x, y, .type = "flextable"),
          fre2 = fre2(d, x, y, .type = "flextable")
        )
        expect_s3_class(out, "flextable")
        displayed <- out$body$dataset
        if (.format_function == "fre2") {
          expect_equal(tail(displayed$total, 1L), nrow(d))
        } else {
          label_column <- if (.format_function == "fre") "x" else "value"
          totals <- displayed[
            !is.na(displayed[[label_column]]) &
              displayed[[label_column]] == "Total",
          ]
          expect_true(nrow(totals) > 0L)
          expect_equal(totals$n, rep(nrow(d), nrow(totals)))
        }
        expect_identical(d, before)
      }
    )
  }
}
