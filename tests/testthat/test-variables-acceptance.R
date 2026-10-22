# Numbered public-contract cases. Expected names/labels are explicit fixtures;
# no tidystata internal helper is used to compute expected metadata or matches.
inspect_metadata_label <- function(x, label) {
  attr(x, "label") <- label
  x
}
inspect_metadata_frame <- function(columns) {
  tibble::as_tibble(columns, .name_repair = "minimal")
}
inspect_metadata_expect <- function(
  data,
  expected_names,
  expected_labels = NULL,
  select = NULL
) {
  before <- unserialize(serialize(data, NULL))
  result <- if (is.null(select)) variables(data) else select(data)
  expect_identical(
    class(result),
    if (inherits(data, "data.table")) {
      c("data.table", "data.frame")
    } else if (inherits(data, "tbl_df")) {
      c("tbl_df", "tbl", "data.frame")
    } else {
      "data.frame"
    }
  )
  expect_identical(result$name, expected_names)
  expect_identical(
    names(result),
    if (is.null(expected_labels)) "name" else c("name", "label")
  )
  if (!is.null(expected_labels)) {
    expect_identical(result$label, expected_labels)
  }
  expect_identical(data, before)
  invisible(result)
}
inspect_metadata_cases <- list()
inspect_metadata_add <- function(title, run) {
  inspect_metadata_cases[[length(inspect_metadata_cases) + 1L]] <<- list(
    title = title,
    run = run
  )
}
# 001-025: storage/class independence and imported metadata.
inspect_metadata_values <- list(
  integer = 1:3,
  double = c(1.5, NA, 3),
  logical = c(TRUE, FALSE, NA),
  character = c("a", "b", NA),
  complex = c(1 + 2i, 3 + 0i, NA_complex_),
  raw = as.raw(c(0, 127, 255)),
  factor = factor(c("a", "b", NA)),
  ordered = ordered(c("low", "high", NA), levels = c("low", "high")),
  date = as.Date("2024-02-28") + 0:2,
  datetime = as.POSIXct("2024-02-28", tz = "UTC") + 0:2,
  difftime = as.difftime(c(1, 2, NA), units = "hours"),
  list = list(1, 2:3, NULL),
  nested_list = list(list(a = 1), list(), NULL),
  matrix = matrix(1:6, 3),
  nested_frame = data.frame(inner = 1:3),
  all_missing = rep(NA_real_, 3),
  nan = c(NaN, NA, NaN),
  infinite = c(-Inf, Inf, NA),
  empty_numeric = numeric(),
  empty_character = character(),
  empty_list = list(),
  singleton = 42,
  named = c(first = 1, second = 2, third = 3),
  as_is = I(c("1", "2", "3")),
  classed_numeric = structure(1:3, class = "measurement")
)
for (key in names(inspect_metadata_values)) {
  local({
    value <- inspect_metadata_values[[key]]
    inspect_metadata_add(
      paste("label attribute on", key, "column"),
      function() {
        d <- inspect_metadata_frame(list(
          measure = inspect_metadata_label(value, "Study measure")
        ))
        inspect_metadata_expect(d, "measure", "Study measure")
      }
    )
  })
}
# 026-040: missing, unusual and mixed label attributes.
inspect_metadata_attributes <- list(
  absent = list(NULL, NULL),
  empty = list("", NULL),
  missing = list(NA_character_, NULL),
  multi = list(c("a", "b"), NULL),
  zero_length = list(character(), NULL),
  integer = list(123L, "123"),
  double = list(1.25, "1.25"),
  logical = list(TRUE, "TRUE"),
  date = list(as.Date("2024-02-29"), "2024-02-29"),
  named = list(c(source = "Title"), "Title"),
  whitespace = list(" ", " "),
  newline = list("Line one\nLine two", "Line one\nLine two"),
  unicode = list("\u6536\u5165\u91d1\u989d", "\u6536\u5165\u91d1\u989d"),
  punctuation = list("Income ($), net: 2024?", "Income ($), net: 2024?"),
  literal_na = list("NA", "NA")
)
for (key in names(inspect_metadata_attributes)) {
  local({
    fixture <- inspect_metadata_attributes[[key]]
    inspect_metadata_add(
      paste("normalize", key, "label attribute"),
      function() {
        d <- tibble::tibble(x = inspect_metadata_label(1:2, fixture[[1]]))
        inspect_metadata_expect(d, "x", fixture[[2]])
      }
    )
  })
}
inspect_metadata_select_data <- function() {
  tibble::tibble(
    id = inspect_metadata_label(1:3, "Identifier"),
    income = inspect_metadata_label(c(2, 4, 6), "Annual resources"),
    group = c("A", "B", "A"),
    outcome = inspect_metadata_label(c(TRUE, FALSE, NA), "Response")
  )
}
# 041-060: actual tidyselect operations and metadata alignment.
inspect_metadata_selections <- list(
  one = list(function(d) variables(d, income), "income", "Annual resources"),
  reorder = list(
    function(d) variables(d, outcome, id),
    c("outcome", "id"),
    c("Response", "Identifier")
  ),
  negative = list(
    function(d) variables(d, -income),
    c("id", "group", "outcome"),
    c("Identifier", NA_character_, "Response")
  ),
  range = list(
    function(d) variables(d, id:group),
    c("id", "income", "group"),
    c("Identifier", "Annual resources", NA_character_)
  ),
  starts = list(
    function(d) variables(d, tidyselect::starts_with("i")),
    c("id", "income"),
    c("Identifier", "Annual resources")
  ),
  ends = list(
    function(d) variables(d, tidyselect::ends_with("come")),
    c("income", "outcome"),
    c("Annual resources", "Response")
  ),
  contains = list(
    function(d) variables(d, tidyselect::contains("oup")),
    "group",
    NULL
  ),
  matches = list(
    function(d) variables(d, tidyselect::matches("^i")),
    c("id", "income"),
    c("Identifier", "Annual resources")
  ),
  numeric = list(
    function(d) variables(d, tidyselect::where(is.numeric)),
    c("id", "income"),
    c("Identifier", "Annual resources")
  ),
  character = list(
    function(d) variables(d, tidyselect::where(is.character)),
    "group",
    NULL
  ),
  logical = list(
    function(d) variables(d, tidyselect::where(is.logical)),
    "outcome",
    "Response"
  ),
  all_of = list(
    function(d) variables(d, tidyselect::all_of(c("income", "id"))),
    c("income", "id"),
    c("Annual resources", "Identifier")
  ),
  any_of = list(
    function(d) variables(d, tidyselect::any_of(c("absent", "group"))),
    "group",
    NULL
  ),
  empty = list(
    function(d) variables(d, tidyselect::all_of(character())),
    character(),
    NULL
  ),
  no_match = list(
    function(d) variables(d, tidyselect::starts_with("absent")),
    character(),
    NULL
  ),
  rename = list(
    function(d) variables(d, resources = income),
    "resources",
    "Annual resources"
  ),
  rename_multiple = list(
    function(d) variables(d, result = outcome, key = id),
    c("result", "key"),
    c("Response", "Identifier")
  ),
  repeated = list(function(d) variables(d, id, id), "id", "Identifier"),
  positions = list(
    function(d) variables(d, c(4L, 2L)),
    c("outcome", "income"),
    c("Response", "Annual resources")
  ),
  boolean = list(
    function(d) variables(d, tidyselect::where(is.numeric) & !id),
    "income",
    "Annual resources"
  )
)
for (key in names(inspect_metadata_selections)) {
  local({
    fixture <- inspect_metadata_selections[[key]]
    inspect_metadata_add(paste("tidyselect", key, "aligns labels"), function() {
      inspect_metadata_expect(
        inspect_metadata_select_data(),
        fixture[[2]],
        fixture[[3]],
        fixture[[1]]
      )
    })
  })
}
# 061-075: containers, names and zero dimensions.
inspect_metadata_add("base data frame returns data frame metadata", function() {
  d <- as.data.frame(inspect_metadata_select_data())
  inspect_metadata_expect(
    d,
    names(d),
    c("Identifier", "Annual resources", NA_character_, "Response")
  )
})
inspect_metadata_add(
  "data.table is inspected without modification",
  function() {
    skip_if_not_installed("data.table")
    d <- data.table::as.data.table(inspect_metadata_select_data())
    inspect_metadata_expect(
      d,
      names(d),
      c("Identifier", "Annual resources", NA_character_, "Response")
    )
  }
)
inspect_metadata_add("grouped selection retains grouping variable", function() {
  d <- dplyr::group_by(inspect_metadata_select_data(), group)
  expect_message(
    inspect_metadata_expect(
      d,
      c("group", "income"),
      c(NA_character_, "Annual resources"),
      function(z) variables(z, income)
    ),
    "group"
  )
})
inspect_metadata_add("rowwise tibble retains all names", function() {
  d <- dplyr::rowwise(inspect_metadata_select_data())
  inspect_metadata_expect(
    d,
    names(d),
    c("Identifier", "Annual resources", NA_character_, "Response")
  )
})
inspect_metadata_add("zero-row labelled columns remain visible", function() {
  d <- inspect_metadata_select_data()[integer(), ]
  inspect_metadata_expect(
    d,
    names(d),
    c("Identifier", "Annual resources", NA_character_, "Response")
  )
})
inspect_metadata_add(
  "zero-column base data frame is empty metadata",
  function() inspect_metadata_expect(data.frame(), character())
)
inspect_metadata_add(
  "positive-row zero-column tibble is empty metadata",
  function() {
    inspect_metadata_expect(tibble::new_tibble(list(), nrow = 4), character())
  }
)
inspect_metadata_add("non-syntactic names remain verbatim", function() {
  d <- stats::setNames(
    tibble::tibble(a = 1, b = 2),
    c("annual income", "tax (%)")
  )
  inspect_metadata_expect(d, c("annual income", "tax (%)"))
})
inspect_metadata_add("Unicode names remain verbatim", function() {
  d <- stats::setNames(
    tibble::tibble(a = 1, b = 2),
    c("\u6536\u5165", "caf\u00e9")
  )
  inspect_metadata_expect(d, names(d))
})
inspect_metadata_add(
  "reserved output names do not replace metadata",
  function() {
    d <- tibble::tibble(
      name = inspect_metadata_label(1, "Name field"),
      label = inspect_metadata_label(2, "Label field")
    )
    inspect_metadata_expect(
      d,
      c("name", "label"),
      c("Name field", "Label field")
    )
  }
)
inspect_metadata_add(
  "label-like attribute is not partially matched",
  function() {
    d <- tibble::tibble(x = structure(1:2, labels = "not variable metadata"))
    inspect_metadata_expect(d, "x")
  }
)
inspect_metadata_add(
  "value label map does not become variable label",
  function() {
    d <- tibble::tibble(x = haven::labelled(c(1, 2), c(Yes = 1, No = 2)))
    inspect_metadata_expect(d, "x")
  }
)
inspect_metadata_add(
  "haven variable label is independent of value labels",
  function() {
    d <- tibble::tibble(
      x = haven::labelled(c(1, 2), c(Yes = 1, No = 2), label = "Question")
    )
    inspect_metadata_expect(d, "x", "Question")
  }
)
inspect_metadata_add(
  "SPSS missing metadata preserves variable label",
  function() {
    d <- tibble::tibble(
      x = haven::labelled_spss(c(1, 99), na_values = 99, label = "Question")
    )
    inspect_metadata_expect(d, "x", "Question")
  }
)
inspect_metadata_add("long labels are not truncated", function() {
  txt <- paste(rep("Research metadata", 100), collapse = " ")
  d <- tibble::tibble(x = inspect_metadata_label(1, txt))
  inspect_metadata_expect(d, "x", txt)
})
# 076-085: label shape and input preservation after renaming/filtering.
inspect_metadata_add(
  "mixed valid and invalid labels yield explicit NA",
  function() {
    d <- tibble::tibble(
      a = inspect_metadata_label(1, "A"),
      b = inspect_metadata_label(2, c("B", "C")),
      c = inspect_metadata_label(3, "")
    )
    inspect_metadata_expect(
      d,
      c("a", "b", "c"),
      c("A", NA_character_, NA_character_)
    )
  }
)
inspect_metadata_add(
  "one label shared by several columns remains repeated",
  function() {
    d <- tibble::tibble(
      a = inspect_metadata_label(1, "Common"),
      b = inspect_metadata_label(2, "Common")
    )
    inspect_metadata_expect(d, c("a", "b"), c("Common", "Common"))
  }
)
inspect_metadata_add(
  "column values are never mistaken for metadata",
  function() {
    d <- tibble::tibble(a = "A label in a cell", label = "another cell")
    inspect_metadata_expect(d, c("a", "label"))
  }
)
inspect_metadata_add(
  "dataset-level label does not label each column",
  function() {
    d <- tibble::tibble(a = 1, b = 2)
    attr(d, "label") <- "Whole dataset"
    inspect_metadata_expect(d, c("a", "b"))
  }
)
inspect_metadata_add("nonstandard column attributes are preserved", function() {
  d <- inspect_metadata_select_data()
  attr(d$income, "source") <- list(file = "survey.csv", wave = 3L)
  inspect_metadata_expect(
    d,
    names(d),
    c("Identifier", "Annual resources", NA_character_, "Response")
  )
})
inspect_metadata_add("custom row names do not appear as variables", function() {
  d <- data.frame(a = 1:2, row.names = c("R1", "R2"))
  inspect_metadata_expect(d, "a")
})
inspect_metadata_add("negative zero position selects no columns", function() {
  d <- inspect_metadata_select_data()
  inspect_metadata_expect(d, character(), NULL, function(z) {
    variables(z, integer())
  })
})
inspect_metadata_add(
  "reversed tidyselect range reverses metadata order",
  function() {
    d <- inspect_metadata_select_data()
    inspect_metadata_expect(
      d,
      c("outcome", "group", "income"),
      c("Response", NA_character_, "Annual resources"),
      function(z) variables(z, outcome:income)
    )
  }
)
inspect_metadata_add(
  "selection union keeps first appearance order",
  function() {
    d <- inspect_metadata_select_data()
    inspect_metadata_expect(
      d,
      c("outcome", "id", "income"),
      c("Response", "Identifier", "Annual resources"),
      function(z) variables(z, c(outcome, id), income)
    )
  }
)
inspect_metadata_add(
  "selection complement preserves remaining labels",
  function() {
    d <- inspect_metadata_select_data()
    inspect_metadata_expect(
      d,
      c("id", "income", "outcome"),
      c("Identifier", "Annual resources", "Response"),
      function(z) variables(z, !group)
    )
  }
)
# 086-095: unsupported selection expressions reject rather than invent columns.
inspect_metadata_bad_select <- list(
  missing_name = function(d) variables(d, absent),
  all_of_missing = function(d) variables(d, tidyselect::all_of("absent")),
  out_of_bounds = function(d) variables(d, 99L),
  duplicate_new_names = function(d) variables(d, c(new = id, new = income)),
  computed_numeric = function(d) variables(d, new = income + 1),
  computed_log = function(d) variables(d, new = log(income)),
  computed_character = function(d) variables(d, new = toupper(group)),
  row_predicate = function(d) variables(d, income > 2),
  nonexistent_rename = function(d) variables(d, new = absent),
  fractional_position = function(d) variables(d, 1.5)
)
for (key in names(inspect_metadata_bad_select)) {
  local({
    fn <- inspect_metadata_bad_select[[key]]
    inspect_metadata_add(paste("reject", key, "selection"), function() {
      d <- inspect_metadata_select_data()
      before <- unserialize(serialize(d, NULL))
      expect_error(fn(d))
      expect_identical(d, before)
    })
  })
}
# 096-100: downstream research use and practical metadata sizes.
inspect_metadata_add(
  "metadata joins to research dictionaries by name",
  function() {
    d <- inspect_metadata_select_data()
    x <- variables(d)
    dict <- tibble::tibble(
      name = c("income", "outcome"),
      role = c("exposure", "outcome")
    )
    out <- dplyr::left_join(dict, x, by = "name")
    expect_identical(out$label, c("Annual resources", "Response"))
    expect_identical(out$role, c("exposure", "outcome"))
  }
)
inspect_metadata_add(
  "renamed selection can form a presentation dictionary",
  function() {
    d <- inspect_metadata_select_data()
    out <- variables(d, exposure = income, response = outcome)
    expect_identical(out$name, c("exposure", "response"))
    expect_identical(out$label, c("Annual resources", "Response"))
  }
)
inspect_metadata_add(
  "metadata is invariant to research row filtering",
  function() {
    d <- inspect_metadata_select_data()
    expect_identical(variables(d), variables(d[d$income > 2, ]))
  }
)
inspect_metadata_add(
  "wide dictionary retains 250 labels in column order",
  function() {
    nm <- paste0("q", seq_len(250))
    labs <- paste("Question", seq_len(250))
    cols <- lapply(seq_len(250), function(i) {
      inspect_metadata_label(i, labs[[i]])
    })
    names(cols) <- nm
    inspect_metadata_expect(inspect_metadata_frame(cols), nm, labs)
  }
)
inspect_metadata_add(
  "row binding does not expand the metadata table",
  function() {
    d <- inspect_metadata_select_data()
    expect_identical(variables(d), variables(d[rep(seq_len(nrow(d)), 2L), ]))
  }
)
stopifnot(length(inspect_metadata_cases) == 100L)
for (i in seq_along(inspect_metadata_cases)) {
  local({
    case <- inspect_metadata_cases[[i]]
    test_that(sprintf("variables coverage %03d: %s", i, case$title), {
      case$run()
    })
  })
}

inspect_search_cases <- list()
inspect_search_add <- function(title, run) {
  inspect_search_cases[[length(inspect_search_cases) + 1L]] <<- list(
    title = title,
    run = run
  )
}
inspect_search_frame <- function(nm, labels = NULL) {
  cols <- rep(list(1:2), length(nm))
  names(cols) <- nm
  if (!is.null(labels)) {
    for (i in seq_along(cols)) {
      attr(cols[[i]], "label") <- labels[[i]]
    }
  }
  inspect_metadata_frame(cols)
}
inspect_search_expect <- function(d, query, expected, select = NULL) {
  before <- unserialize(serialize(d, NULL))
  out <- if (is.null(select)) variables_search(d, query) else select(d, query)
  expect_identical(
    class(out),
    if (inherits(d, "data.table")) {
      c("data.table", "data.frame")
    } else if (inherits(d, "tbl_df")) {
      c("tbl_df", "tbl", "data.frame")
    } else {
      "data.frame"
    }
  )
  expect_identical(out$name, expected)
  expect_identical(d, before)
  invisible(out)
}
# 001-040: explicit pattern fixtures, including complete-match versus substring.
inspect_search_patterns <- list(
  substring = list(
    c("income", "income_net", "age"),
    "come",
    c("income", "income_net")
  ),
  uppercase = list(
    c("Income", "INCOME_NET", "age"),
    "income",
    c("Income", "INCOME_NET")
  ),
  mixed_case = list(c("iNcOmE", "other"), "InCoMe", "iNcOmE"),
  exact = list(c("x", "x1", "prefixx"), "^x$", "x"),
  prefix = list(c("x", "x1", "prefixx"), "^x", c("x", "x1")),
  suffix = list(c("x", "x1", "prefixx"), "x$", c("x", "prefixx")),
  missing = list(c("a", "b"), "absent", character()),
  empty = list(c("a", "b"), "", c("a", "b")),
  all_star = list(c("a", "b"), "*", c("a", "b")),
  star_zero = list(c("xy", "xay", "xaay"), "^x*y$", c("xy", "xay", "xaay")),
  star_prefix = list(c("pre1", "pre", "other"), "^pre*$", c("pre1", "pre")),
  star_suffix = list(c("id", "wave_id", "other"), "*id$", c("id", "wave_id")),
  question_exact = list(c("x", "x1", "x12"), "^x?$", "x1"),
  question_substring = list(c("x", "x1", "x12"), "x?", c("x1", "x12")),
  double_question = list(c("x1", "x12", "x123"), "^x??$", "x12"),
  tilde_nonempty = list(c("xy", "xay", "xaay"), "^x~y$", c("xay", "xaay")),
  tilde_suffix = list(c("x", "x1", "x12"), "^x~$", c("x1", "x12")),
  combination = list(
    c("pre_a1", "pre_aa2", "pre_"),
    "^pre_*?$",
    c("pre_a1", "pre_aa2")
  ),
  numeric_single = list(c("q1", "q2", "q3"), "^q[2-2]$", "q2"),
  numeric_multi = list(
    c("q8", "q9", "q10", "q11", "q12", "q13"),
    "^q[9-12]$",
    c("q9", "q10", "q11", "q12")
  ),
  numeric_substring = list(
    c("q1", "q10", "q2", "q21"),
    "q[1-2]",
    c("q1", "q10", "q2", "q21")
  ),
  numeric_anchor = list(
    c("q1", "q10", "xq2x", "q2"),
    "^q[1-2]$",
    c("q1", "q2")
  ),
  numeric_zero = list(c("q0", "q1", "q2"), "^q[0-1]$", c("q0", "q1")),
  numeric_suffix = list(
    c("q9_end", "q10_end", "q11_end", "q10_other"),
    "^q[9-10]_end$",
    c("q9_end", "q10_end")
  ),
  alphabet = list(c("a1", "b1", "c1", "d1"), "^[a-c]1$", c("a1", "b1", "c1")),
  capital_range = list(c("A1", "b1", "D1"), "^[A-C]1$", c("A1", "b1")),
  alternation = list(
    c("income", "wage", "age"),
    "income|wage",
    c("income", "wage")
  ),
  grouped_alternation = list(c("x1", "x2", "x3"), "^x(1|3)$", c("x1", "x3")),
  regex_dot = list(c("a.b", "axb", "ab"), "^a.b$", c("a.b", "axb")),
  literal_dot = list(c("a.b", "axb"), "^a\\.b$", "a.b"),
  literal_plus = list(c("a+b", "aab"), "^a\\+b$", "a+b"),
  literal_parentheses = list(c("a(b)", "ab"), "^a\\(b\\)$", "a(b)"),
  literal_dollar = list(c("cost$", "cost"), "^cost\\$$", "cost$"),
  literal_caret = list(c("^x", "x"), "^\\^x$", "^x"),
  literal_braces = list(c("x{2}", "xx"), "^x\\{2\\}$", "x{2}"),
  literal_pipe = list(c("a|b", "a", "b"), "^a\\|b$", "a|b"),
  spaces = list(
    c("annual income", "annual_tax"),
    "annual income",
    "annual income"
  ),
  hyphen = list(c("pre-tax", "pretax"), "pre-tax", "pre-tax"),
  unicode = list(
    c("\u6536\u5165", "\u5730\u533a"),
    "\u6536\u5165",
    "\u6536\u5165"
  ),
  utf8_question = list(c("x\u6536", "x\u6536\u5165"), "^x?$", "x\u6536")
)
for (key in names(inspect_search_patterns)) {
  local({
    f <- inspect_search_patterns[[key]]
    inspect_search_add(paste("pattern", key), function() {
      inspect_search_expect(inspect_search_frame(f[[1]]), f[[2]], f[[3]])
    })
  })
}
# 041-055: labels are independently searchable; cells and value maps are not.
inspect_search_labels <- list(
  label_only = list(
    c("id", "x"),
    c("Respondent", "Annual income"),
    "income",
    "x"
  ),
  label_case = list(
    c("id", "x"),
    c("Respondent", "Annual INCOME"),
    "income",
    "x"
  ),
  label_exact = list(c("a", "b"), c("Income", "Income total"), "^income$", "a"),
  label_prefix = list(
    c("a", "b"),
    c("Income total", "Net income"),
    "^income",
    "a"
  ),
  label_suffix = list(
    c("a", "b"),
    c("Income total", "Net income"),
    "income$",
    "b"
  ),
  label_wildcard = list(
    c("a", "b"),
    c("Annual household income", "Other"),
    "Annual*income",
    "a"
  ),
  label_question = list(c("a", "b"), c("Wave 1", "Wave 12"), "^Wave ?$", "a"),
  label_tilde = list(
    c("a", "b"),
    c("Netincome", "Net income"),
    "^Net~income$",
    "b"
  ),
  label_range = list(
    c("a", "b", "c"),
    c("Question 9", "Question 10", "Question 11"),
    "^Question [9-10]$",
    c("a", "b")
  ),
  label_unicode = list(
    c("a", "b"),
    c("\u6536\u5165\u91d1\u989d", "Other"),
    "\u91d1\u989d",
    "a"
  ),
  missing_label_name_match = list(
    c("income", "x"),
    c(NA_character_, "Other"),
    "income",
    "income"
  ),
  empty_label_name_match = list(
    c("income", "x"),
    c("", "Other"),
    "income",
    "income"
  ),
  name_label_union = list(
    c("income", "x", "y"),
    c("Other", "Annual income", "Other"),
    "income",
    c("income", "x")
  ),
  duplicate_label = list(
    c("x", "y"),
    c("Income", "Income"),
    "income",
    c("x", "y")
  ),
  metadata_output = list(c("x", "y"), c("Annual income", "Age"), "income", "x")
)
for (key in names(inspect_search_labels)) {
  local({
    f <- inspect_search_labels[[key]]
    inspect_search_add(paste("label", key), function() {
      d <- inspect_search_frame(f[[1]], f[[2]])
      out <- inspect_search_expect(d, f[[3]], f[[4]])
      expected_labels <- f[[2]][match(f[[4]], f[[1]])]
      expected_labels[
        !is.na(expected_labels) & expected_labels == ""
      ] <- NA_character_
      expect_identical(out$label, expected_labels)
    })
  })
}
# 056-070: selection is applied before matching and respects renamed names.
inspect_search_selects <- list(
  reorder = list(
    function(d, q) variables_search(d, q, outcome, income),
    "*",
    c("outcome", "income")
  ),
  exclude_match = list(
    function(d, q) variables_search(d, q, id, group),
    "resources",
    character()
  ),
  include_label = list(
    function(d, q) variables_search(d, q, income, outcome),
    "resources",
    "income"
  ),
  empty = list(
    function(d, q) variables_search(d, q, tidyselect::all_of(character())),
    "*",
    character()
  ),
  starts = list(
    function(d, q) variables_search(d, q, tidyselect::starts_with("i")),
    "i",
    c("id", "income")
  ),
  where_numeric = list(
    function(d, q) variables_search(d, q, tidyselect::where(is.numeric)),
    "*",
    c("id", "income")
  ),
  negative = list(
    function(d, q) variables_search(d, q, -income),
    "*",
    c("id", "group", "outcome")
  ),
  rename_name = list(
    function(d, q) variables_search(d, q, exposure = income),
    "^exposure$",
    "exposure"
  ),
  rename_label = list(
    function(d, q) variables_search(d, q, exposure = income),
    "resources",
    "exposure"
  ),
  original_name_gone = list(
    function(d, q) variables_search(d, q, exposure = income),
    "^income$",
    character()
  ),
  all_of = list(
    function(d, q) {
      variables_search(d, q, tidyselect::all_of(c("group", "outcome")))
    },
    "*",
    c("group", "outcome")
  ),
  any_of = list(
    function(d, q) {
      variables_search(d, q, tidyselect::any_of(c("absent", "income")))
    },
    "*",
    "income"
  ),
  intersection = list(
    function(d, q) variables_search(d, q, tidyselect::where(is.numeric) & !id),
    "*",
    "income"
  ),
  reverse_range = list(
    function(d, q) variables_search(d, q, outcome:income),
    "*",
    c("outcome", "group", "income")
  ),
  duplicate = list(
    function(d, q) variables_search(d, q, income, income),
    "resources",
    "income"
  )
)
for (key in names(inspect_search_selects)) {
  local({
    f <- inspect_search_selects[[key]]
    inspect_search_add(paste("selection", key), function() {
      inspect_search_expect(
        inspect_metadata_select_data(),
        f[[2]],
        f[[3]],
        f[[1]]
      )
    })
  })
}
# 071-080: invalid query inputs must fail, not silently recycle by row.
inspect_search_invalid <- list(
  empty = character(),
  vector = c("income", "id"),
  missing = NA_character_,
  integer = 1L,
  double = 1.5,
  logical = TRUE,
  list = list("income"),
  null = NULL,
  factor = factor("income"),
  vector_with_na = c("income", NA_character_)
)
for (key in names(inspect_search_invalid)) {
  local({
    q <- inspect_search_invalid[[key]]
    inspect_search_add(paste("reject", key, "query"), function() {
      expect_error(
        variables_search(inspect_metadata_select_data(), q),
        "single|one|character|string"
      )
    })
  })
}
# 081-100: errors, empty inputs, container behavior and pipeline integration.
inspect_search_add("decreasing numeric range rejects clearly", function() {
  expect_error(
    variables_search(inspect_search_frame("q1"), "q[12-9]"),
    "smaller"
  )
})
inspect_search_add(
  "two numeric ranges reject rather than mis-match",
  function() {
    expect_error(
      variables_search(inspect_search_frame("q1x1"), "q[1-2]x[1-2]"),
      "one range"
    )
  }
)
inspect_search_add("invalid regex rejects visibly", function() {
  expect_error(variables_search(inspect_search_frame("x"), "("))
})
inspect_search_add("invalid alphabetical range rejects visibly", function() {
  expect_error(variables_search(inspect_search_frame("x"), "[z-a]"))
})
inspect_search_add("unknown selected variable rejects visibly", function() {
  expect_error(variables_search(inspect_metadata_select_data(), "*", absent))
})
inspect_search_add("computed variable selection is unsupported", function() {
  expect_error(variables_search(
    inspect_metadata_select_data(),
    "*",
    new = income + 1
  ))
})
inspect_search_add("empty base dataset returns empty data frame", function() {
  inspect_search_expect(data.frame(), "*", character())
})
inspect_search_add("zero-row dataset still searches metadata", function() {
  d <- inspect_metadata_select_data()[integer(), ]
  inspect_search_expect(d, "resources", "income")
})
inspect_search_add("cell contents are not searchable metadata", function() {
  d <- tibble::tibble(x = c("income", "resources"))
  inspect_search_expect(d, "income", character())
})
inspect_search_add(
  "value label map is not searchable variable metadata",
  function() {
    d <- tibble::tibble(x = haven::labelled(c(1, 2), c(Income = 1, Other = 2)))
    inspect_search_expect(d, "income", character())
  }
)
inspect_search_add(
  "missing-only labels leave name matching usable",
  function() {
    inspect_search_expect(
      inspect_search_frame(c("income", "age"), c(NA_character_, NA_character_)),
      "income",
      "income"
    )
  }
)
inspect_search_add("blank-only labels leave name matching usable", function() {
  inspect_search_expect(
    inspect_search_frame(c("income", "age"), c("", "")),
    "income",
    "income"
  )
})
inspect_search_add(
  "data.table search returns data.table without mutation",
  function() {
    skip_if_not_installed("data.table")
    d <- data.table::as.data.table(inspect_metadata_select_data())
    inspect_search_expect(d, "resources", "income")
  }
)
inspect_search_add(
  "grouped input uses metadata without row grouping",
  function() {
    d <- dplyr::group_by(inspect_metadata_select_data(), group)
    inspect_search_expect(d, "resources", "income")
  }
)
inspect_search_add("base frame search retains label column", function() {
  d <- as.data.frame(inspect_metadata_select_data())
  out <- inspect_search_expect(d, "resources", "income")
  expect_identical(out$label, "Annual resources")
})
inspect_search_add(
  "numeric variable label is coerced before matching",
  function() {
    d <- tibble::tibble(x = inspect_metadata_label(1:2, 123L))
    out <- inspect_search_expect(d, "23", "x")
    expect_identical(out$label, "123")
  }
)
inspect_search_add(
  "programmatic query and all_of form a dictionary pipeline",
  function() {
    d <- inspect_metadata_select_data()
    query <- "resources|response"
    chosen <- c("outcome", "income")
    out <- variables_search(d, query, tidyselect::all_of(chosen))
    expect_identical(out$name, chosen)
    expect_identical(out$label, c("Response", "Annual resources"))
  }
)
inspect_search_add(
  "search result names select downstream research columns",
  function() {
    d <- inspect_metadata_select_data()
    found <- variables_search(d, "resources|response")$name
    out <- dplyr::select(d, tidyselect::all_of(found))
    expect_identical(names(out), c("income", "outcome"))
    expect_identical(out$income, d$income)
  }
)
inspect_search_add(
  "wide label search agrees with independent base substring oracle",
  function() {
    nm <- paste0("q", 1:250)
    labs <- ifelse((1:250) %% 7 == 0, "Exposure annual", "Outcome monthly")
    d <- inspect_search_frame(nm, labs)
    expected <- nm[grepl("annual", labs, ignore.case = TRUE)]
    inspect_search_expect(d, "annual", expected)
  }
)
inspect_search_add(
  "row permutation and duplication cannot change metadata matches",
  function() {
    d <- inspect_metadata_select_data()
    a <- variables_search(d, "resources|response")
    expect_identical(
      a,
      variables_search(d[c(3, 1, 1, 2), ], "resources|response")
    )
  }
)
stopifnot(length(inspect_search_cases) == 100L)
for (i in seq_along(inspect_search_cases)) {
  local({
    case <- inspect_search_cases[[i]]
    test_that(
      sprintf("variables_search coverage %03d: %s", i, case$title),
      {
        case$run()
      }
    )
  })
}
