# Independent public-contract cases: the oracle counts integer category codes
# with base R table(), never tidystata's counting or margin helpers.
cross_cases <- list()
cross_add <- function(id, title, check) {
  cross_cases[[length(cross_cases) + 1L]] <<-
    list(id = as.integer(id), title = title, check = check)
}
cross_assert <- function(
  out,
  x,
  y,
  header,
  totals,
  row_labels = NULL,
  expected_class = c("tbl_df", "tbl", "data.frame")
) {
  ux <- unique(x)
  uy <- unique(y)
  x_codes <- match(x, ux)
  y_codes <- match(y, uy)
  expected <- unclass(table(
    factor(x_codes, levels = seq_along(ux)),
    factor(y_codes, levels = seq_along(uy))
  ))
  expect_identical(class(out), expected_class)
  expect_false(dplyr::is_grouped_df(out))
  expect_identical(names(out)[1], header)
  if (!length(x)) {
    expect_equal(nrow(out), 0L)
    return(invisible(out))
  }
  nr <- length(ux)
  nc <- length(uy)
  cat_cols <- if (totals) names(out)[-c(1L, ncol(out))] else names(out)[-1L]
  column_labels <- as.character(uy)
  column_labels[is.na(column_labels)] <- "NA"
  expect_setequal(cat_cols, column_labels)
  expect_equal(nrow(out), nr + as.integer(totals))
  if (is.null(row_labels)) {
    row_labels <- if (totals && inherits(x, "haven_labelled")) {
      as.character(haven::as_factor(ux))
    } else {
      as.character(ux)
    }
  }
  row_pos <- match(as.character(out[[1]][seq_len(nr)]), row_labels)
  col_pos <- match(cat_cols, column_labels)
  expect_false(anyNA(row_pos))
  expect_setequal(row_pos, seq_along(ux))
  expect_false(anyNA(col_pos))
  actual <- as.matrix(as.data.frame(out)[seq_len(nr), cat_cols, drop = FALSE])
  expect_equal(
    unname(actual),
    unname(expected[row_pos, col_pos, drop = FALSE]),
    ignore_attr = TRUE
  )
  expect_equal(sum(actual), length(x))
  expect_true(all(actual >= 0 & actual == floor(actual)))
  if (totals) {
    expect_identical(names(out)[ncol(out)], "total")
    expect_identical(out[[1]][nr + 1L], "total")
    expect_equal(out$total[seq_len(nr)], as.numeric(rowSums(actual)))
    expect_equal(
      as.numeric(unlist(
        as.data.frame(out)[nr + 1L, cat_cols, drop = FALSE],
        use.names = FALSE
      )),
      as.numeric(colSums(actual))
    )
    expect_equal(out$total[nr + 1L], length(x))
  } else {
    expect_equal(class(out[[1]]), class(x))
  }
  invisible(out)
}
cross_run <- function(fn, x, y, flip = FALSE, row_name = "x", col_name = "y") {
  df <- tibble::tibble(x = x, y = y)
  names(df) <- c(row_name, col_name)
  out <- fn(df, .flip = flip)
  if (flip) {
    cross_assert(
      out,
      y,
      x,
      paste(col_name, row_name, sep = " \\ "),
      identical(fn, tidystata::fre2)
    )
  } else {
    cross_assert(
      out,
      x,
      y,
      paste(row_name, col_name, sep = " \\ "),
      identical(fn, tidystata::fre2)
    )
  }
}

# Different category domains and observed/missing category combinations.
cross_vectors <- list(
  list(
    "balanced character grid",
    rep(c("A", "B"), each = 3),
    rep(c("X", "Y", "Z"), 2)
  ),
  list(
    "asymmetric repeated cells",
    c("B", "A", "B", "A", "A"),
    c("z", "x", "z", "y", "x")
  ),
  list("single observed pair", "A", "X"),
  list("one row category", rep("A", 7), c("x", "x", "y", "z", "y", "x", "z")),
  list("one column category", c("a", "b", "a", "c"), rep("X", 4)),
  list("diagonal absent cells", c("A", "B", "C"), c("X", "Y", "Z")),
  list("integer row categories", c(3L, 1L, 3L, 2L), c("x", "y", "y", "x")),
  list(
    "double column categories",
    c("a", "b", "a", "b"),
    c(-2.5, 0, -2.5, 4.25)
  ),
  list(
    "logical in both dimensions",
    c(TRUE, FALSE, TRUE, FALSE),
    c(FALSE, FALSE, TRUE, NA)
  ),
  list("partially missing rows", c("a", NA, "a", NA), c("x", "x", "y", "y")),
  list("partially missing columns", c("a", "b", "a", "b"), c("x", NA, NA, "x")),
  list(
    "missing values in both dimensions",
    c("a", NA, "b", NA),
    c(NA, "x", "y", NA)
  ),
  list("entirely missing rows", rep(NA_character_, 3), c("x", "y", "x")),
  list("entirely missing columns", c("a", "b", "a"), rep(NA_character_, 3)),
  list(
    "both dimensions entirely missing",
    rep(NA_real_, 4),
    rep(NA_character_, 4)
  ),
  list(
    "NaN and NA are separate row identities",
    c(NaN, NA, NaN, 2),
    c("x", "x", "y", "x")
  ),
  list(
    "NaN and NA are separate column identities",
    c("a", "b", "a", "b"),
    c(NaN, NA, NaN, 2)
  ),
  list(
    "positive and negative infinities",
    c(-Inf, 0, Inf, Inf),
    c("x", "y", "x", "y")
  ),
  list("signed zero is one category", c(-0, 0, 0, 1), c("x", "x", "y", "x")),
  list(
    "large magnitude numeric rows",
    c(1e200, 2e200, 1e200),
    c("x", "y", "y")
  ),
  list(
    "tiny distinct numeric rows",
    c(1e-300, 2e-300, 1e-300),
    c("x", "y", "y")
  ),
  list(
    "row factors retain unused levels",
    factor(c("b", "a", "b"), levels = c("c", "b", "a")),
    c("x", "y", "y")
  ),
  list(
    "column factors exclude unobserved categories",
    c("a", "b", "a"),
    factor(c("z", "x", "z"), levels = c("unused", "z", "x"))
  ),
  list(
    "ordered factors in both dimensions",
    ordered(c("low", "high", "low"), c("high", "low")),
    ordered(c("yes", "no", "yes"), c("no", "yes"))
  ),
  list(
    "factor missing codes",
    factor(c("a", NA, "b", NA), levels = c("b", "a", "unused")),
    c("x", "y", "x", "x")
  ),
  list(
    "Date row class",
    as.Date(c("2024-02-29", "2024-03-01", "2024-02-29")),
    c("x", "y", "y")
  ),
  list(
    "Date column labels",
    c("a", "b", "a"),
    as.Date(c("2024-02-29", "2024-03-01", "2024-02-29"))
  ),
  list(
    "POSIXct row timestamps",
    as.POSIXct(
      c("2024-01-01 01:00:00", "2024-01-01 02:00:00", "2024-01-01 01:00:00"),
      tz = "UTC"
    ),
    c("x", "y", "y")
  ),
  list(
    "difftime hour categories",
    as.difftime(c(2, 1, 2), units = "hours"),
    c("x", "y", "y")
  ),
  list("complex row identities", c(1 + 2i, 1 + 2i, -1 + 0i), c("x", "y", "x")),
  list(
    "non-ASCII row categories",
    c("\u4e2d\u6587", "\u65e5\u672c\u8a9e", "\u4e2d\u6587"),
    c("x", "y", "y")
  ),
  list(
    "non-ASCII column categories",
    c("a", "b", "a"),
    c(
      "\u0645\u0631\u062d\u0628\u0627",
      "\u05e9\u05dc\u05d5\u05dd",
      "\u0645\u0631\u062d\u0628\u0627"
    )
  ),
  list(
    "emoji categories",
    c("\U0001f389", "\U0001f622", "\U0001f389"),
    c("x", "y", "y")
  ),
  list(
    "whitespace row categories remain distinct",
    c("", " ", "\t", "\n", ""),
    c("x", "x", "y", "y", "y")
  ),
  list(
    "punctuation column labels",
    c("a", "b", "a", "b"),
    c("a b", "a-b", "a.b", "a_b")
  ),
  list(
    "literal NA row category and missing row",
    c("NA", NA, "NA"),
    c("x", "x", "y")
  ),
  list(
    "column categories equal original variable names",
    c("a", "b", "a"),
    c("x", "y", "x")
  ),
  list(
    "factor with an explicit NA level",
    factor(c("a", NA, "b"), exclude = NULL),
    c("x", "x", "y")
  ),
  list(
    "integer boundaries",
    c(-.Machine$integer.max, .Machine$integer.max, 0),
    c("x", "y", "x")
  ),
  list(
    "leading zeros in character categories",
    c("01", "1", "001", "01"),
    c("X", "X", "Y", "Y")
  )
)
for (i in seq_along(cross_vectors)) {
  local({
    id <- i
    item <- cross_vectors[[i]]
    cross_add(id, item[[1]], function(fn) cross_run(fn, item[[2]], item[[3]]))
  })
}

cross_add(41, "flip rectangular data and margins", function(fn) {
  cross_run(fn, c("a", "a", "b", "c", "c"), c("x", "y", "x", "y", "y"), TRUE)
})
cross_add(42, "flip mixed missing categories", function(fn) {
  cross_run(fn, c("a", NA, "b", NA), c(NA, "x", NA, "y"), TRUE)
})
cross_add(43, "flip numeric and logical domains", function(fn) {
  cross_run(fn, c(3, 1, 2, 1), c(TRUE, FALSE, TRUE, NA), TRUE)
})
cross_add(44, "flip factors with unused levels", function(fn) {
  cross_run(
    fn,
    factor(c("b", "a", "b"), c("a", "b", "unused")),
    ordered(c("z", "x", "z"), c("z", "x", "unused")),
    TRUE
  )
})
cross_add(45, "permuting observations preserves cells", function(fn) {
  x <- c("b", "a", "c", "a", NA, "b")
  y <- c("x", "z", "y", "x", "x", "z")
  cross_run(fn, x[c(6, 2, 4, 1, 5, 3)], y[c(6, 2, 4, 1, 5, 3)])
})
cross_add(46, "replicating observations triples every count", function(fn) {
  cross_run(fn, rep(c("a", "b", "a", NA), 3), rep(c("x", "y", "y", "x"), 3))
})
cross_add(47, "deterministic 10000-row dense grid", function(fn) {
  i <- seq_len(10000)
  cross_run(fn, (i %% 17L), paste0("C", (i * 7L) %% 13L))
})
cross_add(48, "high-cardinality sparse cells", function(fn) {
  cross_run(fn, seq_len(80), paste0("C", rev(seq_len(80))))
})
cross_add(49, "highly unbalanced observations", function(fn) {
  cross_run(fn, c(rep("a", 997), rep("b", 3)), c(rep("x", 998), "y", "z"))
})
cross_add(
  50,
  "filtered complete observations use filtered denominator",
  function(fn) {
    df <- tibble::tibble(x = c("a", NA, "b", "a"), y = c("x", "y", NA, "z"))
    df <- df[complete.cases(df), ]
    cross_assert(fn(df), df$x, df$y, "x \\ y", identical(fn, tidystata::fre2))
  }
)

cross_select <- function(fn, df, out, x = df$x, y = df$y, header = "x \\ y") {
  cross_assert(out, x, y, header, identical(fn, tidystata::fre2))
}
cross_fixture <- function() {
  tibble::tibble(x = c("a", "b", "a"), y = c("X", "Y", "Y"), z = 1:3)
}
cross_add(51, "numeric positions select two variables", function(fn) {
  df <- cross_fixture()
  cross_select(fn, df, fn(df, 1, 2))
})
cross_add(52, "contiguous range selection", function(fn) {
  df <- cross_fixture()
  cross_select(fn, df, fn(df, x:y))
})
cross_add(53, "negative selection excludes extra columns", function(fn) {
  df <- cross_fixture()
  cross_select(fn, df, fn(df, -z))
})
cross_add(54, "all_of programmatic character selection", function(fn) {
  df <- cross_fixture()
  vars <- c("x", "y")
  cross_select(fn, df, fn(df, tidyselect::all_of(vars)))
})
cross_add(55, "starts_with helper", function(fn) {
  df <- cross_fixture()
  names(df)[1:2] <- c("cat_x", "cat_y")
  cross_select(
    fn,
    df,
    fn(df, tidyselect::starts_with("cat_")),
    df$cat_x,
    df$cat_y,
    "cat_x \\ cat_y"
  )
})
cross_add(56, "where helper selects character columns", function(fn) {
  df <- cross_fixture()
  cross_select(fn, df, fn(df, tidyselect::where(is.character)))
})
cross_add(57, "renaming both selected variables", function(fn) {
  df <- cross_fixture()
  cross_select(fn, df, fn(df, left = x, right = y), header = "left \\ right")
})
cross_add(58, "selection order determines dimensions", function(fn) {
  df <- cross_fixture()
  cross_select(fn, df, fn(df, y, x), df$y, df$x, "y \\ x")
})
cross_add(59, "computed logical category", function(fn) {
  df <- cross_fixture()
  cross_select(fn, df, fn(df, high = z > 1, y), df$z > 1, df$y, "high \\ y")
})
cross_add(60, "computed arithmetic category", function(fn) {
  df <- cross_fixture()
  cross_select(
    fn,
    df,
    fn(df, bucket = z %% 2, y),
    df$z %% 2,
    df$y,
    "bucket \\ y"
  )
})
cross_add(61, "non-syntactic input names", function(fn) {
  cross_run(
    fn,
    c("a", "b", "a"),
    c("X", "Y", "Y"),
    row_name = "row key",
    col_name = "column-key"
  )
})
cross_add(
  62,
  "Unicode input names with explicit C-locale diagnostics",
  function(fn) {
    # Windows R/dplyr warns when a UTF-8 name becomes an environment binding
    # under LC_CTYPE=C. Capture only this known diagnostic, not other warnings.
    expected_native_warning <- .Platform$OS.type == "windows" &&
      identical(Sys.getlocale("LC_CTYPE"), "C")
    diagnostics <- character()
    withCallingHandlers(
      cross_run(
        fn,
        c("a", "b", "a"),
        c("X", "Y", "Y"),
        row_name = "\u6536\u5165",
        col_name = "\u5206\u7c7b"
      ),
      warning = function(w) {
        msg <- conditionMessage(w)
        if (
          expected_native_warning &&
            grepl("unable to translate", msg, fixed = TRUE) &&
            grepl("native encoding", msg, fixed = TRUE)
        ) {
          diagnostics <<- c(diagnostics, msg)
          invokeRestart("muffleWarning")
        }
      }
    )
    if (expected_native_warning) {
      expect_gt(length(diagnostics), 0L)
    } else {
      expect_length(diagnostics, 0L)
    }
  }
)
cross_add(63, "reserved count variable renamed with notice", function(fn) {
  df <- tibble::tibble(n = c("a", "b", "a"), y = c("X", "Y", "Y"))
  expect_message(out <- fn(df), "renamed")
  cross_assert(out, df$n, df$y, ".n \\ y", identical(fn, tidystata::fre2))
})
cross_add(64, "reserved total variable renamed with notice", function(fn) {
  df <- tibble::tibble(x = c("a", "b", "a"), total = c("X", "Y", "Y"))
  expect_message(out <- fn(df), "renamed")
  cross_assert(
    out,
    df$x,
    df$total,
    "x \\ .total",
    identical(fn, tidystata::fre2)
  )
})
cross_add(65, "two reserved names renamed together", function(fn) {
  df <- tibble::tibble(percent = c("a", "b", "a"), valid = c("X", "Y", "Y"))
  expect_message(out <- fn(df), "renamed")
  cross_assert(
    out,
    df$percent,
    df$valid,
    ".percent \\ .valid",
    identical(fn, tidystata::fre2)
  )
})
cross_add(66, "reserved rename target collision errors", function(fn) {
  df <- tibble::tibble(n = c("a", "b"), .n = c("X", "Y"))
  expect_message(expect_error(fn(df), "new name is also taken"), "renamed")
})
cross_add(67, "combined header category collision errors", function(fn) {
  df <- tibble::tibble(x = c("a", "b"), y = c("x \\ y", "z"))
  expect_error(fn(df), "unique|duplicate", ignore.case = TRUE)
})
cross_add(
  68,
  "literal NA versus missing column collision errors",
  function(fn) {
    df <- tibble::tibble(x = c("a", "b"), y = c("NA", NA))
    expect_error(fn(df), "unique|duplicate", ignore.case = TRUE)
  }
)
cross_add(69, "column total reserved only for frequency margins", function(fn) {
  df <- tibble::tibble(x = c("a", "b", "a"), y = c("total", "z", "total"))
  if (identical(fn, tidystata::fre2)) {
    expect_error(fn(df), "reserved for totals")
  } else {
    cross_assert(fn(df), df$x, df$y, "x \\ y", FALSE)
  }
})
cross_add(70, "flipping moves total column category into rows", function(fn) {
  cross_run(fn, c("a", "b", "a"), c("total", "z", "total"), TRUE)
})
cross_add(71, "literal Total column is case-sensitive", function(fn) {
  cross_run(fn, c("a", "b", "a"), c("Total", "z", "Total"))
})
cross_add(72, "dotted and numeric-looking column categories", function(fn) {
  cross_run(fn, c("a", "b", "a", "b"), c(".n", "01", "1", "...tmp"))
})
cross_add(
  73,
  "observed row named total is not conflated with margin",
  function(fn) {
    out <- cross_run(fn, c("total", "other", "total"), c("X", "X", "Y"))
    expect_equal(
      sum(out[[1]] == "total"),
      if (identical(fn, tidystata::fre2)) 2 else 1
    )
  }
)
cross_add(74, "reserved names after flip use renamed header", function(fn) {
  df <- tibble::tibble(n = c("a", "b", "a"), percent = c("X", "Y", "Y"))
  expect_message(out <- fn(df, .flip = TRUE), "renamed")
  cross_assert(
    out,
    df$percent,
    df$n,
    ".percent \\ .n",
    identical(fn, tidystata::fre2)
  )
})
cross_add(
  75,
  "literal NA column without actual missing is valid",
  function(fn) {
    cross_run(fn, c("a", "b", "a"), c("NA", "z", "NA"))
  }
)

cross_add(76, "zero-row character input returns empty table", function(fn) {
  cross_run(fn, character(), character())
})
cross_add(77, "zero-row typed input preserves row key class", function(fn) {
  out <- cross_run(
    fn,
    as.Date(character()),
    factor(character(), levels = c("X", "Y"))
  )
  expect_s3_class(out[[1]], "Date")
})
cross_add(78, "empty tidyselect selection returns zero columns", function(fn) {
  out <- fn(cross_fixture(), tidyselect::starts_with("absent"))
  expect_s3_class(out, "tbl_df")
  expect_equal(dim(out), c(0L, 0L))
})
cross_add(79, "explicit zero integer selection is empty", function(fn) {
  out <- fn(cross_fixture(), integer())
  expect_equal(dim(out), c(0L, 0L))
})
cross_add(80, "zero-column data frame returns empty table", function(fn) {
  out <- fn(tibble::tibble(.rows = 3))
  expect_equal(dim(out), c(0L, 0L))
})
cross_add(81, "one selected variable errors", function(fn) {
  expect_error(fn(cross_fixture(), x), "rovide two variables")
})
cross_add(
  82,
  "three selected variables give every pairwise table",
  function(fn) {
    df <- cross_fixture()
    out <- fn(df)
    expect_named(out, c("x x y", "x x z", "y x z"))
    expect_identical(out[["x x y"]], fn(df, x, y))
    expect_identical(out[["y x z"]], fn(df, y, z))
  }
)
cross_add(83, "unknown variable selection errors", function(fn) {
  expect_error(fn(cross_fixture(), x, unknown_column))
})
cross_add(
  84,
  "numeric constant expression becomes second category",
  function(fn) {
    df <- cross_fixture()
    cross_assert(
      fn(df, x, constant = 100),
      df$x,
      rep(100, nrow(df)),
      "x \\ constant",
      identical(fn, tidystata::fre2)
    )
  }
)
cross_add(85, "NULL input errors", function(fn) expect_error(fn(NULL)))
cross_add(86, "atomic input errors", function(fn) expect_error(fn(c(1, 2, 3))))
cross_add(87, "matrix measured column errors", function(fn) {
  df <- tibble::tibble(x = c("a", "b"), y = matrix(1:4, 2))
  expect_error(fn(df))
})
cross_add(88, "missing flip flag errors", function(fn) {
  expect_error(fn(cross_fixture(), x, y, .flip = NA))
})
cross_add(89, "multi-element flip flag errors", function(fn) {
  expect_error(fn(cross_fixture(), x, y, .flip = c(TRUE, FALSE)))
})
cross_add(90, "computed category wrong size errors", function(fn) {
  expect_error(fn(cross_fixture(), x, invalid = c("a", "b")))
})

cross_add(91, "base data frame input is preserved", function(fn) {
  df <- data.frame(x = c("b", "a", "b"), y = c("X", "Y", "Y"))
  before <- unserialize(serialize(df, NULL))
  cross_assert(
    fn(df),
    df$x,
    df$y,
    "x \\ y",
    identical(fn, tidystata::fre2),
    expected_class = "data.frame"
  )
  expect_identical(df, before)
})
cross_add(
  92,
  "tibble attributes and variable labels are preserved",
  function(fn) {
    df <- cross_fixture()[1:2]
    attr(df$x, "label") <- "Row label"
    attr(df, "source") <- "acceptance fixture"
    before <- unserialize(serialize(df, NULL))
    cross_assert(fn(df), df$x, df$y, "x \\ y", identical(fn, tidystata::fre2))
    expect_identical(df, before)
  }
)
cross_add(93, "pre-grouped input is ungrouped without mutation", function(fn) {
  df <- dplyr::group_by(cross_fixture()[1:2], x)
  before <- unserialize(serialize(df, NULL))
  expect_message(out <- fn(df), "Ungrouping")
  cross_assert(out, df$x, df$y, "x \\ y", identical(fn, tidystata::fre2))
  expect_identical(df, before)
})
cross_add(94, "rowwise input produces global cross counts", function(fn) {
  df <- dplyr::rowwise(cross_fixture()[1:2])
  before <- unserialize(serialize(df, NULL))
  out <- fn(df)
  cross_assert(out, df$x, df$y, "x \\ y", identical(fn, tidystata::fre2))
  expect_identical(df, before)
})
cross_add(95, "data.table input is not changed by reference", function(fn) {
  skip_if_not_installed("data.table")
  df <- data.table::data.table(x = c("a", "b", "a"), y = c("X", "Y", "Y"))
  before <- data.table::copy(df)
  cross_assert(
    fn(df),
    df$x,
    df$y,
    "x \\ y",
    identical(fn, tidystata::fre2),
    expected_class = c("data.table", "data.frame")
  )
  expect_identical(df, before)
})
cross_add(
  96,
  "labelled numeric rows use labels only in frequency rows",
  function(fn) {
    x <- haven::labelled(c(1, 2, 1, NA), c(Yes = 1, No = 2))
    cross_run(fn, x, c("X", "Y", "Y", "X"))
  }
)
cross_add(
  97,
  "labelled numeric columns remain numeric category names",
  function(fn) {
    y <- haven::labelled(c(1, 2, 1, NA), c(Yes = 1, No = 2))
    cross_run(fn, c("a", "b", "a", "b"), y)
  }
)
cross_add(
  98,
  "units row values retain native class or displayed values",
  function(fn) {
    skip_if_not_installed("units")
    cross_run(fn, units::set_units(c(2, 1, 2), "cm"), c("X", "Y", "Y"))
  }
)
cross_add(
  99,
  "integer64 values are counted without floating conversion",
  function(fn) {
    skip_if_not_installed("bit64")
    cross_run(
      fn,
      bit64::as.integer64(c(
        "9007199254740992",
        "9007199254740993",
        "9007199254740992"
      )),
      c("X", "Y", "Y")
    )
  }
)
cross_add(
  100,
  "list row values are counted by complete identity",
  function(fn) {
    cross_run(
      fn,
      list(c(1L, 2L), c(2L, 1L), c(1L, 2L), NULL),
      c("X", "X", "Y", "Y")
    )
  }
)

stopifnot(identical(vapply(cross_cases, `[[`, integer(1), "id"), seq_len(100L)))
for (cross_export in c("tab2", "fre2")) {
  for (cross_case in cross_cases) {
    local({
      export <- cross_export
      item <- cross_case
      test_that(sprintf("%s coverage %03d: %s", export, item$id, item$title), {
        item$check(getExportedValue("tidystata", export))
      })
    })
  }
}
