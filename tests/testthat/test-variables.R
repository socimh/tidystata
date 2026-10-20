test_that("milestone variables searches attribute labels without a label column", {
  d <- data.frame(id = 1:3, income = 4:6)
  attr(d$income, "label") <- "Annual household resources"
  expect_equal(
    variables(d)$label,
    c(NA_character_, "Annual household resources")
  )
  expect_identical(variables_search(d, "household")$name, "income")
})

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
    expect_identical(class(out), class(d))
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
    expect_identical(class(out), class(d))
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

# Public-contract regressions, independent of implementation helpers.
for (.bad_query in list(
  character(),
  c("a", "b"),
  NA_character_,
  1,
  TRUE,
  list("a"),
  factor("a")
)) {
  local({
    bad <- .bad_query
    test_that(
      paste(
        "variables_search validates query",
        paste(capture.output(dput(bad)), collapse = "")
      ),
      {
        d <- tibble::tibble(a = 1:2, b = 3:4)
        before <- d
        expect_error(
          variables_search(d, bad),
          "`string` must be a single string",
          fixed = TRUE
        )
        expect_error(
          variables_search(d[, FALSE], bad),
          "`string` must be a single string",
          fixed = TRUE
        )
        expect_identical(d, before)
      }
    )
  })
}

test_that("variables_search preserves empty-string all-variable search", {
  d <- tibble::tibble(z = 1:2, a = 3:4)
  expect_identical(variables_search(d, "")$name, c("z", "a"))
})

test_that("variables_search accepts letter ranges without numeric-coercion warnings", {
  d <- tibble::tibble(item_a = 1:2, item_b = 3:4, item_c = 5:6, item_z = 7:8)
  before <- d
  expect_no_warning(out <- variables_search(d, "^item_[a-c]$"))
  expect_identical(out$name, c("item_a", "item_b", "item_c"))
  expect_identical(d, before)
})

test_that("variables_search() reports an invalid query", {
  d <- tibble::tibble(a = 1)
  expect_snapshot(error = TRUE, {
    variables_search(d, c("a", "b"))
    variables_search(d, NA_character_)
  })
})
