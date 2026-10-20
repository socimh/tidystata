# Headless acceptance: all calls run without opening a data viewer. Viewer
# forwarding cases use an explicitly labelled stub and do not test GUI rendering.
# Keep the public return value, selection and pipeline behavior under test.

browse_case <- function(id, title, code) {
  test_that(sprintf("browse coverage %03d: %s", id, title), code())
}
browse_frame <- function() {
  tibble::tibble(
    id = 1:4,
    score = c(2, NA, 6, 8),
    group = c("A", "A", "B", "B")
  )
}
browse_same <- function(expr, expected) {
  actual <- withVisible(expr)
  expect_identical(actual$value, expected)
  expect_false(actual$visible)
}

browse_case(1, "tibble returns unchanged and invisibly", function() {
  x <- browse_frame()
  browse_same(browse(x), x)
})
browse_case(2, "base data frame class and row names survive", function() {
  x <- data.frame(a = 1:3, row.names = c("r3", "r1", "r2"))
  browse_same(browse(x), x)
})
browse_case(3, "data.table no-selection identity", function() {
  skip_if_not_installed("data.table")
  x <- data.table::data.table(a = 1:3, b = letters[1:3])
  browse_same(browse(x), x)
})
browse_case(4, "zero-row typed input", function() {
  x <- tibble::tibble(a = integer(), b = character(), c = as.Date(character()))
  browse_same(browse(x), x)
})
browse_case(5, "zero-column input retains row count", function() {
  x <- tibble::tibble(.rows = 4L)
  browse_same(browse(x), x)
})
browse_case(6, "completely empty tibble", function() {
  x <- tibble::tibble()
  browse_same(browse(x), x)
})
browse_case(7, "single row input", function() {
  x <- browse_frame()[1, ]
  browse_same(browse(x), x)
})
browse_case(8, "single column input", function() {
  x <- tibble::tibble(a = c(1, NA_real_))
  browse_same(browse(x), x)
})
browse_case(9, "wide input preserves every name", function() {
  x <- tibble::as_tibble(setNames(rep(list(1:2), 150), paste0("v", 1:150)))
  browse_same(browse(x), x)
})
browse_case(10, "large input does not truncate returned rows", function() {
  x <- tibble::tibble(id = seq_len(10000), score = seq_len(10000) / 3)
  browse_same(browse(x), x)
})
browse_case(11, "bare column selection", function() {
  x <- browse_frame()
  browse_same(browse(x, score), x["score"])
})
browse_case(12, "selection reorders columns", function() {
  x <- browse_frame()
  browse_same(browse(x, group, id), x[c("group", "id")])
})
browse_case(13, "inclusive column range", function() {
  x <- browse_frame()
  browse_same(browse(x, id:score), x[c("id", "score")])
})
browse_case(14, "negative selection", function() {
  x <- browse_frame()
  browse_same(browse(x, -score), x[c("id", "group")])
})
browse_case(15, "integer position selection", function() {
  x <- browse_frame()
  browse_same(browse(x, 3, 1), x[c(3, 1)])
})
browse_case(16, "everything selection", function() {
  x <- browse_frame()
  browse_same(browse(x, dplyr::everything()), x)
})
browse_case(17, "starts_with selector", function() {
  x <- tibble::tibble(q1 = 1:2, q2 = 3:4, id = 5:6)
  browse_same(browse(x, dplyr::starts_with("q")), x[c("q1", "q2")])
})
browse_case(18, "ends_with selector", function() {
  x <- tibble::tibble(pre_x = 1:2, post_x = 3:4, pre_y = 5:6)
  browse_same(browse(x, dplyr::ends_with("_x")), x[1:2])
})
browse_case(19, "contains selector", function() {
  x <- tibble::tibble(a_score_x = 1:2, score = 3:4, id = 5:6)
  browse_same(browse(x, dplyr::contains("score")), x[1:2])
})
browse_case(20, "regular expression selector", function() {
  x <- tibble::tibble(q1 = 1:2, q2 = 3:4, q10 = 5:6)
  browse_same(browse(x, dplyr::matches("^q[12]$")), x[1:2])
})
browse_case(21, "numeric type predicate", function() {
  x <- browse_frame()
  browse_same(browse(x, dplyr::where(is.numeric)), x[1:2])
})
browse_case(22, "character type predicate", function() {
  x <- browse_frame()
  browse_same(browse(x, dplyr::where(is.character)), x["group"])
})
browse_case(23, "predicate sees observed column contents", function() {
  x <- browse_frame()
  browse_same(browse(x, dplyr::where(anyNA)), x["score"])
})
browse_case(24, "rename existing selected column", function() {
  x <- browse_frame()
  expected <- x["score"]
  names(expected) <- "outcome"
  browse_same(browse(x, outcome = score), expected)
})
browse_case(25, "duplicate selections retain first position", function() {
  x <- browse_frame()
  browse_same(browse(x, id, score, id), x[c("id", "score")])
})
browse_case(26, "all_of respects external vector order", function() {
  x <- browse_frame()
  columns <- c("group", "score")
  browse_same(browse(x, dplyr::all_of(columns)), x[columns])
})
browse_case(27, "any_of ignores unknown external names", function() {
  x <- browse_frame()
  browse_same(browse(x, dplyr::any_of(c("missing", "id"))), x["id"])
})
browse_case(28, "unmatched helper yields zero columns", function() {
  x <- browse_frame()
  browse_same(browse(x, dplyr::starts_with("absent_")), x[integer()])
})
browse_case(29, "explicit NULL yields zero columns", function() {
  x <- browse_frame()
  browse_same(browse(x, NULL), x[integer()])
})
browse_case(30, "negative everything yields zero columns", function() {
  x <- browse_frame()
  browse_same(browse(x, -dplyr::everything()), x[integer()])
})
browse_case(31, "computed arithmetic column", function() {
  x <- browse_frame()
  browse_same(
    browse(x, doubled = score * 2),
    tibble::tibble(doubled = x$score * 2)
  )
})
browse_case(32, "computed logical column retains missing values", function() {
  x <- browse_frame()
  browse_same(browse(x, high = score > 5), tibble::tibble(high = x$score > 5))
})
browse_case(33, "computed scalar recycles to row count", function() {
  x <- browse_frame()
  browse_same(browse(x, flag = TRUE), tibble::tibble(flag = rep(TRUE, 4)))
})
browse_case(34, "sequential computations see preceding columns", function() {
  x <- browse_frame()
  expected <- tibble::tibble(y = x$score * 2, z = x$score * 2 + 1)
  browse_same(browse(x, y = score * 2, z = y + 1), expected)
})
browse_case(35, "computed character transformation", function() {
  x <- browse_frame()
  browse_same(
    browse(x, label = paste0(group, id)),
    tibble::tibble(label = paste0(x$group, x$id))
  )
})
browse_case(36, "computed row index", function() {
  x <- browse_frame()
  browse_same(
    browse(x, position = seq_along(id)),
    tibble::tibble(position = 1:4)
  )
})
browse_case(37, "data pronoun accesses a column", function() {
  x <- browse_frame()
  browse_same(browse(x, y = .data$score + 1), tibble::tibble(y = x$score + 1))
})
browse_case(
  38,
  "environment pronoun accesses an external constant",
  function() {
    x <- browse_frame()
    offset <- 10
    browse_same(
      browse(x, y = score + .env$offset),
      tibble::tibble(y = x$score + offset)
    )
  }
)
browse_case(39, "empty computed numeric column", function() {
  x <- tibble::tibble(a = numeric())
  browse_same(browse(x, y = a * 2), tibble::tibble(y = numeric()))
})
browse_case(40, "computed missing replacement", function() {
  x <- browse_frame()
  browse_same(
    browse(x, y = dplyr::coalesce(score, 0)),
    tibble::tibble(y = c(2, 0, 6, 8))
  )
})
browse_case(41, "grouped no-selection object preserves metadata", function() {
  x <- dplyr::group_by(browse_frame(), group)
  browse_same(browse(x), x)
})
browse_case(42, "explicit grouped selection retains key", function() {
  x <- dplyr::group_by(browse_frame(), group)
  expected <- dplyr::group_by(
    tibble::tibble(group = x$group, score = x$score),
    group
  )
  expect_message(
    result <- withVisible(browse(x, score)),
    "Adding missing grouping"
  )
  expect_identical(result$value, expected)
  expect_false(result$visible)
})
browse_case(43, "grouped calculation uses group denominators", function() {
  x <- dplyr::group_by(browse_frame(), group)
  expected <- dplyr::group_by(
    tibble::tibble(group = x$group, centered = c(0, NA, -1, 1)),
    group
  )
  browse_same(browse(x, centered = score - mean(score, na.rm = TRUE)), expected)
})
browse_case(44, "multiple grouping keys survive", function() {
  x <- dplyr::group_by(browse_frame(), group, id)
  expected <- dplyr::group_by(
    tibble::tibble(group = x$group, id = x$id, score = x$score),
    group,
    id
  )
  browse_same(browse(x, group, id, score), expected)
})
browse_case(45, "unused factor group levels remain", function() {
  x <- tibble::tibble(g = factor(c("A", "A"), levels = c("A", "B")), a = 1:2)
  x <- dplyr::group_by(x, g, .drop = FALSE)
  browse_same(browse(x, dplyr::everything()), x)
})
browse_case(46, "rowwise no-selection identity", function() {
  x <- dplyr::rowwise(browse_frame())
  browse_same(browse(x), x)
})
browse_case(47, "rowwise selected columns preserve rowwise class", function() {
  x <- dplyr::rowwise(browse_frame())
  expected <- dplyr::rowwise(browse_frame()[c("id", "score")])
  browse_same(browse(x, id, score), expected)
})
browse_case(
  48,
  "rowwise list computations return one value per row",
  function() {
    x <- dplyr::rowwise(tibble::tibble(values = list(1:3, 5:6)))
    expected <- dplyr::rowwise(tibble::tibble(total = c(6L, 11L)))
    browse_same(browse(x, total = sum(values)), expected)
  }
)
browse_case(49, "missing grouping key is retained", function() {
  x <- dplyr::group_by(tibble::tibble(g = c("A", NA_character_), a = 1:2), g)
  browse_same(browse(x, dplyr::everything()), x)
})
browse_case(50, "empty grouped data preserves groups", function() {
  x <- dplyr::group_by(tibble::tibble(g = character(), a = double()), g)
  browse_same(browse(x, g, a), x)
})
browse_case(51, "factor levels and ordering survive selection", function() {
  x <- tibble::tibble(
    a = ordered(c("low", NA), levels = c("low", "mid", "high")),
    b = 1:2
  )
  browse_same(browse(x, a), x["a"])
})
browse_case(52, "Date values retain class", function() {
  x <- tibble::tibble(a = as.Date(c("2024-02-29", NA)), b = 1:2)
  browse_same(browse(x, a), x["a"])
})
browse_case(53, "datetime timezone and fractions survive", function() {
  x <- tibble::tibble(
    a = as.POSIXct(
      c(0.25, 3600.75),
      origin = "1970-01-01",
      tz = "Asia/Shanghai"
    )
  )
  browse_same(browse(x, a), x)
})
browse_case(54, "difftime units survive selection", function() {
  x <- tibble::tibble(a = as.difftime(c(1, 2), units = "hours"), b = 1:2)
  browse_same(browse(x, a), x["a"])
})
browse_case(55, "logical missing and observed values unchanged", function() {
  x <- tibble::tibble(a = c(TRUE, FALSE, NA), b = 1:3)
  browse_same(browse(x, a), x["a"])
})
browse_case(56, "complex column retains real and imaginary values", function() {
  x <- tibble::tibble(a = c(1 + 2i, NA_complex_), b = 1:2)
  browse_same(browse(x, a), x["a"])
})
browse_case(57, "raw column bytes survive selection", function() {
  x <- tibble::tibble(a = as.raw(c(0, 255)), b = 1:2)
  browse_same(browse(x, a), x["a"])
})
browse_case(58, "nonfinite numeric values are not formatted away", function() {
  x <- tibble::tibble(a = c(NA_real_, NaN, Inf, -Inf, -0), b = 1:5)
  browse_same(browse(x, a), x["a"])
})
browse_case(59, "nested list column identities survive", function() {
  x <- tibble::tibble(a = list(NULL, list(k = 1:2), c(1, NA)), b = 1:3)
  browse_same(browse(x, a), x["a"])
})
browse_case(60, "matrix column shape and dimnames survive", function() {
  x <- tibble::tibble(
    a = matrix(1:6, 3, dimnames = list(NULL, c("u", "v"))),
    b = 1:3
  )
  browse_same(browse(x, a), x["a"])
})
browse_case(61, "nested data-frame column survives", function() {
  x <- tibble::tibble(a = tibble::tibble(inner = 1:3), b = 1:3)
  browse_same(browse(x, a), x["a"])
})
browse_case(62, "haven labels and tagged missing values survive", function() {
  skip_if_not_installed("haven")
  x <- tibble::tibble(
    a = haven::labelled(c(1, haven::tagged_na("a")), c(Yes = 1)),
    b = 1:2
  )
  browse_same(browse(x, a), x["a"])
})
browse_case(63, "SPSS user-missing metadata survives", function() {
  skip_if_not_installed("haven")
  x <- tibble::tibble(
    a = haven::labelled_spss(c(1, 99), labels = c(Yes = 1), na_values = 99),
    b = 1:2
  )
  browse_same(browse(x, a), x["a"])
})
browse_case(64, "units metadata survives", function() {
  skip_if_not_installed("units")
  x <- tibble::tibble(a = units::set_units(1:2, "cm"), b = 1:2)
  browse_same(browse(x, a), x["a"])
})
browse_case(65, "integer64 exact values survive", function() {
  skip_if_not_installed("bit64")
  x <- tibble::tibble(
    a = bit64::as.integer64(c("9007199254740993", "9007199254740995")),
    b = 1:2
  )
  browse_same(browse(x, a), x["a"])
})
browse_case(66, "variable label attribute survives selection", function() {
  x <- browse_frame()
  attr(x$score, "label") <- "Survey score"
  browse_same(browse(x, score), x["score"])
})
browse_case(67, "dataset custom attribute survives no selection", function() {
  x <- browse_frame()
  attr(x, "provenance") <- list(wave = 2L)
  browse_same(browse(x), x)
})
browse_case(68, "base selection preserves custom row names", function() {
  x <- data.frame(a = 1:2, b = 3:4, row.names = c("case-2", "case-1"))
  browse_same(browse(x, b), x["b"])
})
browse_case(
  69,
  "data.table selection retains class without input mutation",
  function() {
    skip_if_not_installed("data.table")
    x <- data.table::data.table(a = 1:3, b = 4:6)
    before <- data.table::copy(x)
    result <- withVisible(browse(x, b))
    expect_s3_class(result$value, "data.table")
    expect_identical(result$value$b, 4:6)
    expect_false(result$visible)
    expect_identical(x, before)
  }
)
browse_case(
  70,
  "selection never modifies original labels or names",
  function() {
    x <- browse_frame()
    attr(x$score, "label") <- "Score"
    before <- x
    y <- browse(x, value = score * 2)
    expect_identical(x, before)
    expect_identical(names(y), "value")
  }
)
browse_case(71, "spaces in column names", function() {
  x <- tibble::tibble(`survey score` = 1:2, id = 3:4)
  browse_same(browse(x, `survey score`), x["survey score"])
})
browse_case(72, "punctuation in column names", function() {
  x <- tibble::tibble(`score (%)` = 1:2, `a-b` = 3:4)
  browse_same(browse(x, `a-b`, `score (%)`), x[c("a-b", "score (%)")])
})
browse_case(73, "Unicode names selected programmatically", function() {
  columns <- c("\u6536\u5165", "\u5e74\u9f84")
  x <- tibble::as_tibble(setNames(list(1:2, 3:4), columns))
  browse_same(browse(x, dplyr::all_of(columns[2])), x[columns[2]])
})
browse_case(74, "Unicode cell contents are not transliterated", function() {
  x <- tibble::tibble(
    text = c("\u5317\u4eac", "caf\u00e9", "\U0001f642"),
    id = 1:3
  )
  browse_same(browse(x, text), x["text"])
})
browse_case(75, "reserved-looking names selected explicitly", function() {
  x <- tibble::tibble(`NA` = 1:2, `TRUE` = 3:4, `.data` = 5:6)
  browse_same(browse(x, dplyr::all_of(c(".data", "NA"))), x[c(".data", "NA")])
})
browse_case(76, "embracing wrapper supports column selection", function() {
  wrapper <- function(data, column) browse(data, {{ column }})
  x <- browse_frame()
  browse_same(wrapper(x, score), x["score"])
})
browse_case(77, "forwarded dots preserve selector order", function() {
  wrapper <- function(data, ...) browse(data, ...)
  x <- browse_frame()
  browse_same(wrapper(x, group, id), x[c("group", "id")])
})
browse_case(78, "injected expression performs computation", function() {
  x <- browse_frame()
  expression <- rlang::expr(score * 3)
  browse_same(browse(x, y = !!expression), tibble::tibble(y = x$score * 3))
})
browse_case(79, "dynamic output name works", function() {
  x <- browse_frame()
  output <- "doubled"
  browse_same(
    browse(x, !!output := score * 2),
    tibble::tibble(doubled = x$score * 2)
  )
})
browse_case(80, "spliced selection expressions", function() {
  x <- browse_frame()
  columns <- rlang::syms(c("group", "score"))
  browse_same(browse(x, !!!columns), x[c("group", "score")])
})
browse_case(81, "unknown bare column errors clearly", function() {
  expect_error(browse(browse_frame(), absent), "Neither|exist|not found")
})
browse_case(82, "all_of rejects missing requested column", function() {
  expect_error(
    browse(browse_frame(), dplyr::all_of(c("id", "absent"))),
    "absent"
  )
})
browse_case(83, "out of range scalar position errors", function() {
  # Unnamed positions must exist; name a value to create a constant column.
  expect_error(browse(browse_frame(), 99L), "position 99")
  browse_same(
    browse(browse_frame(), constant = 99L),
    tibble::tibble(constant = rep(99L, 4))
  )
})
browse_case(84, "incompatible computed length errors", function() {
  expect_error(browse(browse_frame(), y = c(10, 20)), "Neither|size")
})
browse_case(
  85,
  "duplicate output name uses sequential data-mask overwrite",
  function() {
    x <- browse_frame()
    browse_same(browse(x, new = id, new = score), tibble::tibble(new = x$score))
  }
)
browse_case(86, "computed expression failure remains informative", function() {
  expect_error(browse(browse_frame(), y = stop("browse-probe")), "browse-probe")
})
browse_case(87, "atomic input with selection errors", function() {
  expect_error(browse(1:3, first), "Neither|applicable|data")
})
browse_case(88, "duplicate input names reject selection", function() {
  x <- data.frame(a = 1:2, b = 3:4)
  names(x) <- c("a", "a")
  expect_error(browse(x, dplyr::everything()), "Neither|unique|duplicat")
})
browse_case(89, "filter then browse then model preparation", function() {
  x <- browse_frame()
  result <- x |>
    dplyr::filter(!is.na(score)) |>
    browse(id, score) |>
    dplyr::mutate(y = score / 2)
  expect_identical(
    result,
    tibble::tibble(id = c(1L, 3L, 4L), score = c(2, 6, 8), y = c(1, 3, 4))
  )
  expect_identical(x, browse_frame())
})
browse_case(90, "browse feeds grouped research summaries", function() {
  result <- browse_frame() |>
    browse(group, score) |>
    dplyr::summarise(mean_score = mean(score, na.rm = TRUE), .by = group)
  expect_identical(
    result,
    tibble::tibble(group = c("A", "B"), mean_score = c(2, 7))
  )
  expect_identical(names(result), c("group", "mean_score"))
})
browse_case(91, "browse feeds a base regression pipeline", function() {
  x <- tibble::tibble(x = 1:5, y = 2 + 3 * (1:5), unused = letters[1:5])
  fit <- x |> browse(x, y) |> stats::lm(formula = y ~ x)
  expect_equal(unname(coef(fit)), c(2, 3), tolerance = 1e-12)
  expect_identical(stats::nobs(fit), 5L)
})
browse_case(92, "browse feeds joins without changing keys", function() {
  x <- tibble::tibble(id = c(3L, 1L), score = c(30, 10), extra = TRUE)
  result <- x |>
    browse(id, score) |>
    dplyr::left_join(tibble::tibble(id = 1:3, weight = c(2, 3, 4)), by = "id")
  expect_identical(result$id, c(3L, 1L))
  expect_identical(result$weight, c(4, 2))
})
browse_case(93, "browse feeds long reshaping", function() {
  x <- tibble::tibble(id = 1:2, wave1 = c(2, 4), wave2 = c(3, 5), junk = 0)
  result <- x |>
    browse(id, dplyr::starts_with("wave")) |>
    tidyr::pivot_longer(-id, names_to = "wave", values_to = "score")
  expect_identical(result$id, c(1L, 1L, 2L, 2L))
  expect_identical(result$score, c(2, 3, 4, 5))
})
browse_case(
  94,
  "input and successful all_of selector evaluate once",
  function() {
    state <- new.env()
    state$n <- 0L
    state$selections <- 0L
    input <- function() {
      state$n <- state$n + 1L
      browse_frame()
    }
    choose <- function() {
      state$selections <- state$selections + 1L
      "score"
    }
    result <- browse(input(), dplyr::all_of(choose()))
    expect_identical(state$n, 1L)
    expect_identical(result, browse_frame()["score"])
    expect_identical(state$selections, 1L)
  }
)
browse_case(95, "resolved data-mask computation executes once", function() {
  state <- new.env()
  state$n <- 0L
  add_one <- function(x) {
    force(x)
    state$n <- state$n + 1L
    x + 1
  }
  x <- browse_frame()
  result <- browse(x, y = add_one(score))
  expect_identical(state$n, 1L)
  expect_identical(result, tibble::tibble(y = x$score + 1))
})
browse_case(96, "type predicate executes once per column", function() {
  state <- new.env()
  state$n <- 0L
  predicate <- function(x) {
    state$n <- state$n + 1L
    is.numeric(x)
  }
  x <- browse_frame()
  result <- browse(x, dplyr::where(predicate))
  expect_identical(state$n, 3L)
  expect_identical(result, x[1:2])
})
browse_case(97, "single computed warning is preserved", function() {
  compute <- function(x) {
    warning("browse-computation-warning")
    x * 2
  }
  x <- browse_frame()
  warnings <- character()
  result <- withCallingHandlers(
    browse(x, y = compute(score)),
    warning = function(w) {
      warnings <<- c(warnings, conditionMessage(w))
      invokeRestart("muffleWarning")
    }
  )
  expect_length(warnings, 1L)
  expect_match(warnings, "browse-computation-warning", fixed = TRUE)
  expect_identical(result, tibble::tibble(y = x$score * 2))
})
browse_case(
  98,
  "viewer forwarding stub receives unchanged input once",
  function() {
    state <- new.env()
    state$calls <- list()
    local_mocked_bindings(
      view = function(x, ...) {
        state$calls[[length(state$calls) + 1L]] <- x
        invisible(x)
      },
      .package = "tibble"
    )
    x <- browse_frame()
    browse_same(browse(x), x)
    expect_identical(state$calls, list(x))
  }
)
browse_case(
  99,
  "viewer forwarding stub receives selected data once",
  function() {
    state <- new.env()
    state$calls <- list()
    local_mocked_bindings(
      view = function(x, ...) {
        state$calls[[length(state$calls) + 1L]] <- x
        invisible(x)
      },
      .package = "tibble"
    )
    x <- browse_frame()
    browse_same(browse(x, score), x["score"])
    expect_identical(state$calls, list(x["score"]))
  }
)
browse_case(100, "viewer forwarding stub error propagates", function() {
  local_mocked_bindings(
    view = function(x, ...) stop("viewer-stub-failure"),
    .package = "tibble"
  )
  x <- browse_frame()
  before <- x
  expect_error(browse(x, score), "viewer-stub-failure")
  expect_identical(x, before)
})
