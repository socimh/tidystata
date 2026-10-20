# One hundred independent selection scenarios are run through each public name
# listing entry point. Expected names come from explicit fixtures, not ds(),
# select(), or another statart function used as a reference implementation.
inspect_names_columns <- c(
  "id",
  "alpha",
  "alpha_end",
  "BETA",
  "text",
  "flag",
  "grade",
  "day",
  "payload",
  "clock",
  "elapsed"
)
inspect_names_fixture <- function() {
  tibble::tibble(
    id = 1:3,
    alpha = c(1, NA_real_, 3),
    alpha_end = c(2.5, 5.5, 8.5),
    BETA = c(NA_real_, 0, 1),
    text = c("one", "two", NA_character_),
    flag = c(TRUE, FALSE, NA),
    grade = factor(c("low", "high", "low"), levels = c("low", "high")),
    day = as.Date(c("2024-02-28", "2024-02-29", NA_character_)),
    payload = list(NULL, c(1, 2), list(a = "b")),
    clock = as.POSIXct(
      c("2024-02-28 00:00:00", "2024-02-29 12:00:00", NA),
      tz = "UTC"
    ),
    elapsed = as.difftime(c(1, 2, NA), units = "hours")
  )
}

inspect_names_cases <- list()
inspect_names_case <- function(id, title, body) {
  inspect_names_cases[[length(inspect_names_cases) + 1L]] <<-
    list(id = as.integer(id), title = title, body = body)
}

inspect_names_case(
  1,
  "[schema] default listing preserves input column order",
  function(api, check) {
    check(api(inspect_names_fixture()), inspect_names_columns)
  }
)
inspect_names_case(
  2,
  "[schema] base data frames ignore row-name identities",
  function(api, check) {
    input <- data.frame(
      second = 1:2,
      first = 3:4,
      row.names = c("person-2", "person-1")
    )
    check(api(input), c("second", "first"), container = "frame")
  }
)
inspect_names_case(
  3,
  "[empty] zero observations retain the complete typed schema",
  function(api, check) {
    input <- inspect_names_fixture()[0, ]
    check(api(input), inspect_names_columns)
  }
)
inspect_names_case(
  4,
  "[empty] positive row count without columns has no names",
  function(api, check) {
    check(api(tibble::tibble(.rows = 7)), character())
  }
)
inspect_names_case(
  5,
  "[empty] zero rows and zero columns produce a typed empty result",
  function(api, check) {
    check(api(tibble::tibble()), character())
  }
)
inspect_names_case(
  6,
  "[schema] a single column is retained without scalar simplification",
  function(api, check) {
    check(api(tibble::tibble(only = c(NA_real_, Inf))), "only")
  }
)
inspect_names_case(
  7,
  "[schema] wide inputs retain every exact name in source order",
  function(api, check) {
    expected <- paste0("measurement_", seq_len(1000))
    input <- as.data.frame(setNames(rep(list(1:2), 1000), expected))
    check(api(input), expected, container = "frame")
  }
)
inspect_names_case(
  8,
  "[types] matrix and nested-frame columns remain single variables",
  function(api, check) {
    input <- tibble::tibble(
      matrix_value = matrix(1:6, nrow = 3),
      nested = data.frame(a = 1:3, b = 4:6),
      plain = 7:9
    )
    check(api(input), c("matrix_value", "nested", "plain"))
  }
)
inspect_names_case(
  9,
  "[types] labels and custom column attributes do not replace names",
  function(api, check) {
    input <- tibble::tibble(
      age = structure(1:3, label = "Age in years"),
      income = structure(c(2, 4, 6), note = "scaled")
    )
    before <- input
    check(api(input), c("age", "income"))
    expect_identical(input, before)
  }
)
inspect_names_case(
  10,
  "[grouping] default listing keeps original position of grouping columns",
  function(api, check) {
    input <- dplyr::group_by(tibble::tibble(x = 1:3, g = c("b", "a", "b")), g)
    check(api(input), c("x", "g"))
  }
)
inspect_names_case(
  11,
  "[grouping] omitted group keys are restored before selected variables",
  function(api, check) {
    input <- dplyr::group_by(tibble::tibble(x = 1:3, g = c("b", "a", "b")), g)
    expect_message(out <- api(input, x), "Adding missing grouping variables")
    check(out, c("g", "x"))
  }
)
inspect_names_case(
  12,
  "[grouping] multiple omitted group keys retain grouping declaration order",
  function(api, check) {
    input <- dplyr::group_by(
      tibble::tibble(x = 1:3, g = c("b", "a", "b"), h = 1:3),
      h,
      g
    )
    expect_message(out <- api(input, x), "Adding missing grouping variables")
    check(out, c("h", "g", "x"))
  }
)
inspect_names_case(
  13,
  "[grouping] explicit exclusion cannot remove a grouping key",
  function(api, check) {
    input <- dplyr::group_by(
      tibble::tibble(g = c("a", "a"), x = 1:2, y = 3:4),
      g
    )
    expect_message(out <- api(input, -g), "Adding missing grouping variables")
    check(out, c("g", "x", "y"))
  }
)
inspect_names_case(
  14,
  "[grouping] explicitly selected keys respect requested selection order",
  function(api, check) {
    input <- dplyr::group_by(
      tibble::tibble(g = c("a", "a"), x = 1:2, y = 3:4),
      g
    )
    check(api(input, y, g), c("y", "g"))
  }
)
inspect_names_case(
  15,
  "[grouping] everything does not move a grouping key already selected",
  function(api, check) {
    input <- dplyr::group_by(
      tibble::tibble(x = 1:2, g = c("a", "b"), y = 3:4),
      g
    )
    check(api(input, dplyr::everything()), c("x", "g", "y"))
  }
)
inspect_names_case(
  16,
  "[grouping] renaming a grouping key returns its new name",
  function(api, check) {
    input <- dplyr::group_by(tibble::tibble(g = c("a", "b"), x = 1:2), g)
    check(api(input, cohort = g, x), c("cohort", "x"))
  }
)
inspect_names_case(
  17,
  "[grouping] an empty selection on grouped data retains only the keys",
  function(api, check) {
    input <- dplyr::group_by(tibble::tibble(g = c("a", "b"), x = 1:2), g)
    expect_message(
      out <- api(input, dplyr::any_of("absent")),
      "Adding missing grouping variables"
    )
    check(out, "g")
  }
)
inspect_names_case(
  18,
  "[grouping] type selection retains a nonnumeric grouping key",
  function(api, check) {
    input <- dplyr::group_by(
      tibble::tibble(text = c("a", "b"), x = 1:2, flag = c(TRUE, FALSE)),
      text
    )
    expect_message(
      out <- api(input, dplyr::where(is.numeric)),
      "Adding missing grouping variables"
    )
    check(out, c("text", "x"))
  }
)
inspect_names_case(
  19,
  "[grouping] rowwise data without identifier keys allow ordinary selection",
  function(api, check) {
    input <- dplyr::rowwise(tibble::tibble(x = 1:2, y = list(1:3, NULL)))
    check(api(input, y), "y")
  }
)
inspect_names_case(
  20,
  "[grouping] rowwise identifier keys are restored when omitted",
  function(api, check) {
    input <- dplyr::rowwise(tibble::tibble(id = c("p2", "p1"), x = 1:2), id)
    expect_message(out <- api(input, x), "Adding missing grouping variables")
    check(out, c("id", "x"))
  }
)
inspect_names_case(
  21,
  "[selection] a bare column name selects exactly that variable",
  function(api, check) {
    check(api(inspect_names_fixture(), alpha), "alpha")
  }
)
inspect_names_case(
  22,
  "[selection] a literal string selects a named column",
  function(api, check) {
    check(api(inspect_names_fixture(), "text"), "text")
  }
)
inspect_names_case(
  23,
  "[selection] a literal string vector specifies output order",
  function(api, check) {
    check(
      api(inspect_names_fixture(), c("flag", "id", "text")),
      c("flag", "id", "text")
    )
  }
)
inspect_names_case(
  24,
  "[selection] a positive integer selects by position",
  function(api, check) {
    check(api(inspect_names_fixture(), 4), "BETA")
  }
)
inspect_names_case(
  25,
  "[selection] a vector of positions preserves the requested permutation",
  function(api, check) {
    check(
      api(inspect_names_fixture(), c(5, 1, 3)),
      c("text", "id", "alpha_end")
    )
  }
)
inspect_names_case(
  26,
  "[selection] a named range includes both endpoints",
  function(api, check) {
    check(
      api(inspect_names_fixture(), alpha:flag),
      c("alpha", "alpha_end", "BETA", "text", "flag")
    )
  }
)
inspect_names_case(
  27,
  "[selection] a reverse range reverses selected source order",
  function(api, check) {
    check(
      api(inspect_names_fixture(), flag:alpha),
      c("flag", "text", "BETA", "alpha_end", "alpha")
    )
  }
)
inspect_names_case(
  28,
  "[selection] negative names remove columns without reordering the remainder",
  function(api, check) {
    check(api(inspect_names_fixture(), -alpha), inspect_names_columns[-2])
  }
)
inspect_names_case(
  29,
  "[selection] negative positions exclude nonadjacent columns",
  function(api, check) {
    check(
      api(inspect_names_fixture(), -c(1, 3, 8)),
      inspect_names_columns[-c(1, 3, 8)]
    )
  }
)
inspect_names_case(
  30,
  "[selection] a concatenation of bare names sets explicit order",
  function(api, check) {
    check(
      api(inspect_names_fixture(), c(day, flag, alpha)),
      c("day", "flag", "alpha")
    )
  }
)
inspect_names_case(
  31,
  "[selection] repeated selections do not duplicate names",
  function(api, check) {
    check(api(inspect_names_fixture(), alpha, id, alpha, id), c("alpha", "id"))
  }
)
inspect_names_case(
  32,
  "[rename] a renamed repeated source has one selected output name",
  function(api, check) {
    check(api(inspect_names_fixture(), measure = alpha, alpha), "measure")
  }
)
inspect_names_case(
  33,
  "[rename] renaming a single column returns only the replacement",
  function(api, check) {
    check(api(inspect_names_fixture(), respondent_id = id), "respondent_id")
  }
)
inspect_names_case(
  34,
  "[rename] multiple renamed selections preserve argument order",
  function(api, check) {
    check(
      api(inspect_names_fixture(), response = text, measure = alpha),
      c("response", "measure")
    )
  }
)
inspect_names_case(
  35,
  "[rename] renamed variables followed by everything are not duplicated",
  function(api, check) {
    check(
      api(inspect_names_fixture(), measure = alpha, dplyr::everything()),
      c("measure", inspect_names_columns[-2])
    )
  }
)
inspect_names_case(
  36,
  "[rename] named all_of mappings rename and reorder programmatically",
  function(api, check) {
    mapping <- c(response = "text", respondent = "id")
    check(
      api(inspect_names_fixture(), dplyr::all_of(mapping)),
      c("response", "respondent")
    )
  }
)
inspect_names_case(
  37,
  "[rename] named any_of mappings ignore absent sources and retain aliases",
  function(api, check) {
    mapping <- c(
      response = "text",
      missing_alias = "not_here",
      respondent = "id"
    )
    check(
      api(inspect_names_fixture(), dplyr::any_of(mapping)),
      c("response", "respondent")
    )
  }
)
inspect_names_case(
  38,
  "[programmatic] all_of follows external name order",
  function(api, check) {
    wanted <- c("payload", "day", "id")
    check(api(inspect_names_fixture(), dplyr::all_of(wanted)), wanted)
  }
)
inspect_names_case(
  39,
  "[programmatic] any_of drops unknown names without changing known order",
  function(api, check) {
    wanted <- c("absent", "day", "also_absent", "alpha")
    check(
      api(inspect_names_fixture(), dplyr::any_of(wanted)),
      c("day", "alpha")
    )
  }
)
inspect_names_case(
  40,
  "[empty] all_of accepts an empty character selection",
  function(api, check) {
    check(api(inspect_names_fixture(), dplyr::all_of(character())), character())
  }
)
inspect_names_case(
  41,
  "[empty] any_of with no existing names returns no variables",
  function(api, check) {
    check(
      api(inspect_names_fixture(), dplyr::any_of(c("none", "absent"))),
      character()
    )
  }
)
inspect_names_case(
  42,
  "[empty] an explicit empty integer selection returns no variables",
  function(api, check) {
    check(api(inspect_names_fixture(), integer()), character())
  }
)
inspect_names_case(
  43,
  "[empty] NULL is an empty tidyselect specification",
  function(api, check) {
    check(api(inspect_names_fixture(), NULL), character())
  }
)
inspect_names_case(
  44,
  "[empty] excluding everything yields no names",
  function(api, check) {
    check(api(inspect_names_fixture(), -dplyr::everything()), character())
  }
)
inspect_names_case(
  45,
  "[helpers] starts_with is case insensitive by default",
  function(api, check) {
    check(
      api(inspect_names_fixture(), dplyr::starts_with("A")),
      c("alpha", "alpha_end")
    )
  }
)
inspect_names_case(
  46,
  "[helpers] starts_with can enforce case-sensitive matching",
  function(api, check) {
    check(
      api(
        inspect_names_fixture(),
        dplyr::starts_with("B", ignore.case = FALSE)
      ),
      "BETA"
    )
    check(
      api(
        inspect_names_fixture(),
        dplyr::starts_with("b", ignore.case = FALSE)
      ),
      character()
    )
  }
)
inspect_names_case(
  47,
  "[helpers] ends_with uses case insensitive suffix matching",
  function(api, check) {
    check(
      api(inspect_names_fixture(), dplyr::ends_with("A")),
      c("alpha", "BETA")
    )
  }
)
inspect_names_case(
  48,
  "[helpers] ends_with can enforce case-sensitive suffix matching",
  function(api, check) {
    check(
      api(inspect_names_fixture(), dplyr::ends_with("A", ignore.case = FALSE)),
      "BETA"
    )
  }
)
inspect_names_case(
  49,
  "[helpers] contains treats punctuation literally rather than as regex",
  function(api, check) {
    input <- tibble::tibble(`a.b` = 1, axb = 2, `c.d` = 3)
    check(api(input, dplyr::contains(".")), c("a.b", "c.d"))
  }
)
inspect_names_case(
  50,
  "[helpers] matches accepts anchored regular expressions",
  function(api, check) {
    check(
      api(inspect_names_fixture(), dplyr::matches("^(alpha|text)$")),
      c("alpha", "text")
    )
  }
)
inspect_names_case(
  51,
  "[helpers] regex matching respects explicit case sensitivity",
  function(api, check) {
    check(
      api(
        inspect_names_fixture(),
        dplyr::matches("^beta$", ignore.case = FALSE)
      ),
      character()
    )
    check(
      api(
        inspect_names_fixture(),
        dplyr::matches("^BETA$", ignore.case = FALSE)
      ),
      "BETA"
    )
  }
)
inspect_names_case(
  52,
  "[helpers] helper vectors combine matches in helper-pattern order",
  function(api, check) {
    input <- tibble::tibble(pre_a = 1, post_a = 2, pre_b = 3, post_b = 4)
    check(
      api(input, dplyr::starts_with(c("post", "pre"))),
      c("post_a", "post_b", "pre_a", "pre_b")
    )
  }
)
inspect_names_case(
  53,
  "[helpers] num_range matches only requested numeric suffixes",
  function(api, check) {
    input <- tibble::tibble(q1 = 1, q2 = 2, q3 = 3, q10 = 4, other = 5)
    check(api(input, dplyr::num_range("q", c(3, 1))), c("q3", "q1"))
  }
)
inspect_names_case(
  54,
  "[helpers] num_range width distinguishes zero-padded suffixes",
  function(api, check) {
    input <- tibble::tibble(q1 = 1, q01 = 2, q02 = 3, q10 = 4)
    check(api(input, dplyr::num_range("q", 1:2, width = 2)), c("q01", "q02"))
  }
)
inspect_names_case(
  55,
  "[types] numeric predicates include integers but exclude dates and logicals",
  function(api, check) {
    check(
      api(inspect_names_fixture(), dplyr::where(is.numeric)),
      c("id", "alpha", "alpha_end", "BETA")
    )
  }
)
inspect_names_case(
  56,
  "[types] integer predicates distinguish stored integer columns",
  function(api, check) {
    check(api(inspect_names_fixture(), dplyr::where(is.integer)), "id")
  }
)
inspect_names_case(
  57,
  "[types] logical predicates keep all-missing and observed logical columns",
  function(api, check) {
    input <- tibble::tibble(
      flag = c(TRUE, NA),
      all_missing = c(NA, NA),
      numeric = c(1, 2)
    )
    check(api(input, dplyr::where(is.logical)), c("flag", "all_missing"))
  }
)
inspect_names_case(
  58,
  "[types] character predicates do not include factor columns",
  function(api, check) {
    check(api(inspect_names_fixture(), dplyr::where(is.character)), "text")
  }
)
inspect_names_case(
  59,
  "[types] factor predicates recognize ordered and unordered categories",
  function(api, check) {
    input <- tibble::tibble(
      grade = factor("low"),
      rank = ordered("high"),
      text = "low"
    )
    check(api(input, dplyr::where(is.factor)), c("grade", "rank"))
  }
)
inspect_names_case(
  60,
  "[types] inheritance predicates distinguish dates from datetimes",
  function(api, check) {
    check(
      api(inspect_names_fixture(), dplyr::where(~ inherits(.x, "Date"))),
      "day"
    )
  }
)
inspect_names_case(
  61,
  "[types] list predicates keep list and nested-frame columns",
  function(api, check) {
    input <- tibble::tibble(
      payload = list(NULL, 1),
      nested = data.frame(x = 1:2),
      atomic = 1:2
    )
    check(api(input, dplyr::where(is.list)), c("payload", "nested"))
  }
)
inspect_names_case(
  62,
  "[types] custom predicates can select by variable attributes",
  function(api, check) {
    input <- tibble::tibble(
      age = structure(1:2, label = "Age"),
      raw = 3:4,
      income = structure(c(5, 6), label = "Income")
    )
    check(
      api(input, dplyr::where(~ !is.null(attr(.x, "label", exact = TRUE)))),
      c("age", "income")
    )
  }
)
inspect_names_case(
  63,
  "[composition] intersection combines name and type predicates",
  function(api, check) {
    check(
      api(
        inspect_names_fixture(),
        dplyr::starts_with("a") & dplyr::where(is.double)
      ),
      c("alpha", "alpha_end")
    )
  }
)
inspect_names_case(
  64,
  "[composition] union combines disjoint predicates in source order",
  function(api, check) {
    check(
      api(
        inspect_names_fixture(),
        dplyr::where(is.character) | dplyr::where(is.factor)
      ),
      c("text", "grade")
    )
  }
)
inspect_names_case(
  65,
  "[composition] complement excludes every matching helper variable",
  function(api, check) {
    check(
      api(inspect_names_fixture(), !dplyr::starts_with("alpha")),
      inspect_names_columns[-c(2, 3)]
    )
  }
)
inspect_names_case(
  66,
  "[composition] an exclusion refines a previously selected helper set",
  function(api, check) {
    check(
      api(inspect_names_fixture(), dplyr::where(is.numeric), -id),
      c("alpha", "alpha_end", "BETA")
    )
  }
)
inspect_names_case(
  67,
  "[composition] overlapping helpers deduplicate at first occurrence",
  function(api, check) {
    check(
      api(
        inspect_names_fixture(),
        dplyr::ends_with("a"),
        dplyr::starts_with("alpha")
      ),
      c("alpha", "BETA", "alpha_end")
    )
  }
)
inspect_names_case(
  68,
  "[helpers] last_col addresses the actual final variable",
  function(api, check) {
    check(api(inspect_names_fixture(), dplyr::last_col()), "elapsed")
  }
)
inspect_names_case(
  69,
  "[helpers] last_col supports offsets from the final variable",
  function(api, check) {
    check(api(inspect_names_fixture(), dplyr::last_col(2)), "payload")
  }
)
inspect_names_case(
  70,
  "[programmatic] spliced selection expressions retain expression order",
  function(api, check) {
    selections <- rlang::exprs(day, alpha, flag)
    check(
      api(inspect_names_fixture(), !!!selections),
      c("day", "alpha", "flag")
    )
  }
)
inspect_names_case(
  71,
  "[programmatic] embracing forwards a caller selection into each entry point",
  function(api, check) {
    wrapper <- function(input, cols) api(input, {{ cols }})
    check(wrapper(inspect_names_fixture(), c(text, alpha)), c("text", "alpha"))
  }
)
inspect_names_case(
  72,
  "[programmatic] injected symbols select variables without string parsing",
  function(api, check) {
    selected <- rlang::sym("payload")
    check(api(inspect_names_fixture(), !!selected), "payload")
  }
)
inspect_names_case(
  73,
  "[programmatic] all_of resolves an enclosing function argument",
  function(api, check) {
    wrapper <- function(input, columns) api(input, dplyr::all_of(columns))
    check(
      wrapper(inspect_names_fixture(), c("day", "clock")),
      c("day", "clock")
    )
  }
)
inspect_names_case(
  74,
  "[programmatic] all_of avoids ambiguity with a same-named data column",
  function(api, check) {
    columns <- c("y", "x")
    input <- tibble::tibble(columns = c("wrong", "wrong"), x = 1:2, y = 3:4)
    check(api(input, dplyr::all_of(columns)), c("y", "x"))
  }
)
inspect_names_case(
  75,
  "[programmatic] conditional selection uses explicit caller decisions",
  function(api, check) {
    pick_numeric <- TRUE
    check(
      api(
        inspect_names_fixture(),
        if (pick_numeric) dplyr::where(is.numeric) else "text"
      ),
      c("id", "alpha", "alpha_end", "BETA")
    )
    pick_numeric <- FALSE
    check(
      api(
        inspect_names_fixture(),
        if (pick_numeric) dplyr::where(is.numeric) else "text"
      ),
      "text"
    )
  }
)
inspect_names_case(
  76,
  "[names] Unicode names retain their exact code points and order",
  function(api, check) {
    expected <- c("\u6536\u5165", "\u00e2ge", "\u03b2", "plain")
    input <- tibble::as_tibble(setNames(rep(list(1:2), 4), expected))
    check(api(input), expected)
  }
)
inspect_names_case(
  77,
  "[names] Unicode names support strict programmatic reordering",
  function(api, check) {
    source_names <- c("\u6536\u5165", "\u00e2ge", "\u03b2")
    input <- tibble::as_tibble(setNames(rep(list(1:2), 3), source_names))
    selected <- c("\u03b2", "\u6536\u5165")
    check(api(input, dplyr::all_of(selected)), selected)
  }
)
inspect_names_case(
  78,
  "[names] names with spaces support literal tidyselect syntax",
  function(api, check) {
    input <- tibble::tibble(`annual income` = 1:2, `age in years` = 3:4)
    check(
      api(input, `age in years`, `annual income`),
      c("age in years", "annual income")
    )
  }
)
inspect_names_case(
  79,
  "[names] punctuation in names is preserved by strict string selection",
  function(api, check) {
    input <- tibble::tibble(
      `a+b` = 1:2,
      `x[1]` = 3:4,
      `a.b` = 5:6,
      `100%` = 7:8
    )
    check(
      api(input, dplyr::all_of(c("100%", "x[1]", "a+b"))),
      c("100%", "x[1]", "a+b")
    )
  }
)
inspect_names_case(
  80,
  "[names] pronoun-like column names are addressable with all_of",
  function(api, check) {
    input <- tibble::tibble(.data = 1:2, .env = 3:4, name = 5:6, value = 7:8)
    check(
      api(input, dplyr::all_of(c(".env", ".data", "name"))),
      c(".env", ".data", "name")
    )
  }
)
inspect_names_case(
  81,
  "[names] long variable names are not truncated",
  function(api, check) {
    expected <- c(paste(rep("long_measurement", 30), collapse = "_"), "short")
    input <- tibble::as_tibble(setNames(list(1:2, 3:4), expected))
    check(api(input), expected)
    check(api(input, dplyr::all_of(expected[1])), expected[1])
  }
)
inspect_names_case(
  82,
  "[names] default listing reports duplicate raw names without repairing them",
  function(api, check) {
    input <- setNames(data.frame(a = 1:2, b = 3:4), c("same", "same"))
    check(api(input), c("same", "same"), container = "frame")
  }
)
inspect_names_case(
  83,
  "[errors] tidyselect rejects ambiguous duplicated source names",
  function(api, check) {
    input <- setNames(data.frame(a = 1:2, b = 3:4), c("same", "same"))
    expect_error(api(input, dplyr::everything()), "unique|duplicated")
  }
)
inspect_names_case(
  84,
  "[names] leading and trailing spaces are significant in strict selection",
  function(api, check) {
    input <- tibble::as_tibble(setNames(
      list(1:2, 3:4, 5:6),
      c("x", " x", "x ")
    ))
    check(api(input, dplyr::all_of(c("x ", "x", " x"))), c("x ", "x", " x"))
  }
)
inspect_names_case(
  85,
  "[names] case-distinct names remain separate under exact selection",
  function(api, check) {
    input <- tibble::tibble(age = 1:2, Age = 3:4, AGE = 5:6)
    check(api(input, dplyr::all_of(c("AGE", "age"))), c("AGE", "age"))
  }
)
inspect_names_case(
  86,
  "[preservation] renaming selections leave source data and attributes unchanged",
  function(api, check) {
    input <- inspect_names_fixture()
    attr(input, "study") <- "panel"
    attr(input$alpha, "label") <- "Baseline exposure"
    before <- input
    check(
      api(input, exposure = alpha, respondent = id),
      c("exposure", "respondent")
    )
    expect_identical(input, before)
  }
)
inspect_names_case(
  87,
  "[preservation] grouped selection leaves keys and group metadata unchanged",
  function(api, check) {
    input <- dplyr::group_by(
      tibble::tibble(
        g = factor(c("b", "a"), levels = c("a", "b", "c")),
        x = 1:2
      ),
      g,
      .drop = FALSE
    )
    before <- input
    expect_message(out <- api(input, x), "Adding missing grouping variables")
    check(out, c("g", "x"))
    expect_identical(input, before)
  }
)
inspect_names_case(
  88,
  "[classes] data table selection does not modify names or keys by reference",
  function(api, check) {
    skip_if_not_installed("data.table")
    input <- data.table::data.table(
      id = c(2L, 1L),
      value = c(3, 4),
      flag = c(TRUE, FALSE)
    )
    data.table::setkeyv(input, "id")
    before <- data.table::copy(input)
    check(
      api(input, response = value, id),
      c("response", "id"),
      container = "table"
    )
    expect_identical(input, before)
    expect_identical(data.table::key(input), "id")
  }
)
inspect_names_case(
  89,
  "[classes] a data-frame subclass produces the standard names result",
  function(api, check) {
    input <- structure(
      data.frame(x = 1:2, y = 3:4),
      class = c("inspection_example", "data.frame")
    )
    before <- input
    check(api(input, y, x), c("y", "x"), container = "frame")
    expect_identical(input, before)
  }
)
inspect_names_case(
  90,
  "[pipeline] names extracted from a selection can drive a later mutate",
  function(api, check) {
    input <- tibble::tibble(
      id = 1:2,
      score_a = c(2, 4),
      score_b = c(3, 6),
      note = c("a", "b")
    )
    out <- input |> api(dplyr::starts_with("score"))
    check(out, c("score_a", "score_b"))
    selected <- if (is.character(out)) out else out$name
    transformed <- dplyr::mutate(
      input,
      dplyr::across(dplyr::all_of(selected), ~ .x * 10)
    )
    expect_identical(transformed$id, 1:2)
    expect_equal(transformed$score_a, c(20, 40))
    expect_equal(transformed$score_b, c(30, 60))
    expect_identical(transformed$note, c("a", "b"))
  }
)
inspect_names_case(
  91,
  "[selection] negative selection of all named columns yields no variables",
  function(api, check) {
    check(api(tibble::tibble(a = 1:2, b = 3:4), -c(a, b)), character())
  }
)
inspect_names_case(
  92,
  "[empty] helpers on a zero-column frame return no variables",
  function(api, check) {
    input <- tibble::tibble(.rows = 2)
    check(api(input, dplyr::everything()), character())
    check(api(input, dplyr::where(is.numeric)), character())
  }
)
inspect_names_case(
  93,
  "[errors] an unknown bare column reports the missing variable",
  function(api, check) {
    expect_error(
      api(inspect_names_fixture(), missing_measure),
      "missing_measure"
    )
  }
)
inspect_names_case(
  94,
  "[errors] strict all_of reports unknown requested names",
  function(api, check) {
    requested <- c("alpha", "not_recorded")
    expect_error(
      api(inspect_names_fixture(), dplyr::all_of(requested)),
      "not_recorded"
    )
  }
)
inspect_names_case(
  95,
  "[errors] a positive out-of-bounds index reports absent positions",
  function(api, check) {
    expect_error(api(inspect_names_fixture(), 100), "100|past the end")
  }
)
inspect_names_case(
  96,
  "[errors] an out-of-bounds negative index is rejected",
  function(api, check) {
    expect_error(api(inspect_names_fixture(), -100), "100|past the end")
  }
)
inspect_names_case(
  97,
  "[composition] signed tidyselect vectors apply exclusion after inclusion",
  function(api, check) {
    check(api(inspect_names_fixture(), c(1, 2, -2, 5)), c("id", "text"))
  }
)
inspect_names_case(
  98,
  "[errors] logical selection is rejected rather than recycled across columns",
  function(api, check) {
    expect_error(
      api(inspect_names_fixture(), TRUE),
      "logical|numeric or character"
    )
  }
)
inspect_names_case(
  99,
  "[errors] renaming distinct sources to a duplicate name is rejected",
  function(api, check) {
    expect_error(
      api(inspect_names_fixture(), duplicate = alpha, duplicate = id),
      "unique|duplicated"
    )
  }
)
inspect_names_case(
  100,
  "[errors] selection requires data-frame input rather than an atomic scalar",
  function(api, check) {
    expect_error(api(42, dplyr::everything()), "select|data.frame|data frame")
  }
)

stopifnot(
  length(inspect_names_cases) == 100L,
  identical(vapply(inspect_names_cases, `[[`, integer(1), "id"), seq_len(100L))
)

for (function_name in c("ds", "ds_as_column", "ds_as_column")) {
  local({
    api <- getExportedValue("statart", function_name)
    check <- function(out, expected, container = "tibble") {
      if (identical(function_name, "ds")) {
        expect_identical(out, expected)
      } else {
        expected_table <- switch(
          container,
          tibble = tibble::tibble(name = expected),
          frame = data.frame(name = expected),
          table = data.table::data.table(name = expected)
        )
        expect_identical(out, expected_table)
      }
    }
    for (case in inspect_names_cases) {
      test_that(
        sprintf("%s coverage %03d: %s", function_name, case$id, case$title),
        {
          case$body(api, check)
        }
      )
    }
  })
}
