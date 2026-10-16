# Numbered joint-tabulation acceptance cases, independently run for tab and fre.
# The oracle uses base R row identities and arithmetic, never statart internals.
joint_cases <- list()
joint_add <- function(title, run) {
  joint_cases[[length(joint_cases) + 1L]] <<- list(title = title, run = run)
}
joint_scalar <- function(x, i, render = FALSE) {
  if (render) {
    if (inherits(x, "haven_labelled")) {
      return(as.character(haven::as_factor(x))[i])
    }
    return(as.character(x)[i])
  }
  if (is.list(x)) {
    return(x[[i]])
  }
  x[i]
}
joint_equal <- function(x, y) {
  # SPSS is.na() classifies user-missing codes; identity still uses raw codes.
  if (inherits(x, "haven_labelled")) {
    x <- as.numeric(x)
  }
  if (inherits(y, "haven_labelled")) {
    y <- as.numeric(y)
  }
  if (is.numeric(x) && is.numeric(y) && length(x) == 1L && length(y) == 1L) {
    if (is.nan(x) || is.nan(y)) {
      return(is.nan(x) && is.nan(y))
    }
    if (is.na(x) || is.na(y)) {
      return(is.na(x) && is.na(y))
    }
    return(isTRUE(x == y))
  }
  identical(x, y)
}
joint_row_equal <- function(data, i, out, j, columns, render = character()) {
  all(vapply(
    columns,
    function(nm) {
      joint_equal(
        joint_scalar(data[[nm]], i, nm %in% render),
        joint_scalar(out[[nm]], j)
      )
    },
    logical(1)
  ))
}
joint_check <- function(
  out,
  data,
  measured,
  groups = character(),
  fre = FALSE,
  desc = FALSE
) {
  expect_s3_class(out, "tbl_df")
  expect_false(dplyr::is_grouped_df(out))
  expect_false(anyDuplicated(names(out)) > 0L)
  expect_true(all(
    c(groups, measured, "n", "percent", "cum", "valid", "valid_cum") %in%
      names(out)
  ))
  if (!length(measured) || !nrow(data)) {
    expect_equal(nrow(out), 0L)
    return(invisible(out))
  }
  # Real category rows have a cumulative percent. Synthetic subtotal/total rows
  # have NA there, so user values literally called Total remain distinguishable.
  synthetic <- if (fre) is.na(out$cum) else rep(FALSE, nrow(out))
  real <- out[!synthetic, , drop = FALSE]
  render <- if (fre && length(measured) <= 5L) {
    tail(measured, 1L)
  } else {
    character()
  }
  keys <- c(groups, measured)
  counts <- vapply(
    seq_len(nrow(real)),
    function(j) {
      sum(vapply(
        seq_len(nrow(data)),
        function(i) {
          joint_row_equal(data, i, real, j, keys, render)
        },
        logical(1)
      ))
    },
    integer(1)
  )
  expect_equal(real$n, counts)
  expect_true(all(counts > 0L))
  expect_equal(sum(real$n), nrow(data))
  # Every input row maps exactly once, not merely to a row with the right count.
  multiplicity <- vapply(
    seq_len(nrow(data)),
    function(i) {
      sum(vapply(
        seq_len(nrow(real)),
        function(j) {
          joint_row_equal(data, i, real, j, keys, render)
        },
        logical(1)
      ))
    },
    integer(1)
  )
  expect_equal(multiplicity, rep(1L, nrow(data)))
  group_ids <- if (length(groups)) {
    vapply(
      seq_len(nrow(real)),
      function(j) {
        which(vapply(
          seq_len(nrow(real)),
          function(k) {
            joint_row_equal(real, k, real, j, groups)
          },
          logical(1)
        ))[1L]
      },
      integer(1)
    )
  } else {
    rep(1L, nrow(real))
  }
  for (g in unique(group_ids)) {
    ix <- which(group_ids == g)
    # Determine missingness from original values, before fre renders its last key.
    missing <- vapply(
      ix,
      function(j) {
        i <- which(vapply(
          seq_len(nrow(data)),
          function(i) {
            joint_row_equal(data, i, real, j, keys, render)
          },
          logical(1)
        ))[1L]
        any(vapply(
          data[measured],
          function(x) {
            if (is.list(x)) {
              return(isTRUE(is.na(x)[i]))
            }
            is.na(x)[i]
          },
          logical(1)
        ))
      },
      logical(1)
    )
    n <- counts[ix]
    pct <- n / sum(n) * 100
    vpct <- rep(NA_real_, length(n))
    if (any(!missing)) {
      vpct[!missing] <- n[!missing] / sum(n[!missing]) * 100
    }
    expect_equal(real$percent[ix], pct)
    expect_equal(real$cum[ix], cumsum(pct))
    expect_equal(real$valid[ix], vpct)
    expect_equal(real$valid_cum[ix], cumsum(vpct))
    expect_equal(missing, sort(missing))
    if (desc) {
      expect_equal(n[!missing], sort(n[!missing], decreasing = TRUE))
      expect_equal(n[missing], sort(n[missing], decreasing = TRUE))
    }
    if (fre) {
      sub <- out[synthetic, , drop = FALSE]
      if (length(groups)) {
        sub <- sub[
          vapply(
            seq_len(nrow(sub)),
            function(j) {
              joint_row_equal(real, ix[1L], sub, j, groups)
            },
            logical(1)
          ),
          ,
          drop = FALSE
        ]
      }
      label_col <- if (length(measured) <= 5L) tail(measured, 1L) else "total"
      labels <- as.character(sub[[label_col]])
      expect_equal(sum(labels == "Total"), 1L)
      expect_equal(sub$n[labels == "Total"], sum(n))
      expect_equal(sub$percent[labels == "Total"], 100)
      need_valid <- sum(!missing) > 1L && any(missing)
      need_missing <- sum(missing) > 1L
      expect_equal(sum(labels == "Valid Total"), as.integer(need_valid))
      expect_equal(sum(labels == "Missing Total"), as.integer(need_missing))
      if (need_valid) {
        expect_equal(sub$n[labels == "Valid Total"], sum(n[!missing]))
        expect_equal(
          sub$percent[labels == "Valid Total"],
          sum(n[!missing]) / sum(n) * 100
        )
        expect_equal(sub$valid[labels == "Valid Total"], 100)
      }
      if (need_missing) {
        expect_equal(sub$n[labels == "Missing Total"], sum(n[missing]))
        expect_equal(
          sub$percent[labels == "Missing Total"],
          sum(n[missing]) / sum(n) * 100
        )
      }
    }
  }
  invisible(out)
}
joint_data_case <- function(
  title,
  data,
  measured = names(data),
  groups = character(),
  desc = FALSE,
  category_order = NULL
) {
  force(data)
  force(measured)
  force(groups)
  force(desc)
  force(category_order)
  joint_add(title, function(fun, is_fre) {
    before <- data
    out <- fun(
      data,
      tidyselect::all_of(measured),
      .by = tidyselect::all_of(groups),
      .desc = desc
    )
    joint_check(out, data, measured, groups, is_fre, desc)
    if (!is.null(category_order)) {
      real <- out[!is.na(out$cum), , drop = FALSE]
      expect_equal(
        as.character(real[[measured[1L]]]),
        as.character(category_order)
      )
    }
    expect_identical(data, before)
  })
}
# 001-020: atomic categories, exact row identities and frequency arithmetic.
joint_data_case(
  "repeated positive integers",
  tibble::tibble(x = c(2L, 1L, 2L, 3L, 2L)),
  category_order = 1:3
)
joint_data_case(
  "negative and positive numeric values",
  tibble::tibble(x = c(-2, 0, 2, -2, 0))
)
joint_data_case(
  "nonintegral categories",
  tibble::tibble(x = c(.25, .5, .25, .75))
)
joint_data_case("all categories equal", tibble::tibble(x = rep(7, 20)))
joint_data_case("singleton category", tibble::tibble(x = 42L))
joint_data_case("zero-row numeric input", tibble::tibble(x = numeric()))
joint_data_case("all unique categories", tibble::tibble(x = 1:25))
joint_data_case(
  "logical proportions",
  tibble::tibble(x = c(TRUE, FALSE, TRUE, TRUE))
)
joint_data_case(
  "logical categories with missing",
  tibble::tibble(x = c(TRUE, FALSE, NA, TRUE))
)
joint_data_case(
  "empty strings and whitespace",
  tibble::tibble(x = c("", " ", "  ", "a", "a"))
)
joint_data_case(
  "case-sensitive text identity",
  tibble::tibble(x = c("a", "A", "a", "AA"))
)
joint_data_case(
  "Unicode category identities",
  tibble::tibble(x = c("\u4e2d\u6587", "\u00e9", "\u4e2d\u6587", "\u03b1"))
)
joint_data_case(
  "control characters remain distinct",
  tibble::tibble(x = c("a\nb", "ab", "a\tb", "a\nb"))
)
joint_data_case(
  "literal NA versus missing text",
  tibble::tibble(x = c("NA", NA, "NA", "na"))
)
joint_data_case("signed infinities", tibble::tibble(x = c(Inf, -Inf, 0, Inf)))
joint_data_case(
  "NA and NaN retain separate categories",
  tibble::tibble(x = c(NA_real_, NaN, NaN, 1, 1))
)
joint_data_case("signed zero shares identity", tibble::tibble(x = c(0, -0, 1)))
joint_add("adjacent floating point categories", function(fun, is_fre) {
  data <- tibble::tibble(x = c(.1 + .2, .3, .3))
  out <- fun(data, x)
  if (!is_fre) {
    joint_check(out, data, "x")
    expect_identical(out$x, sort(unique(data$x)))
  } else {
    # fre deliberately renders its last measured column as text for totals.
    # Distinct doubles can share a display string; the two counts must survive.
    expect_s3_class(out, "tbl_df")
    expect_identical(out$x, c("0.3", "0.3", "Total"))
    expect_equal(out$n, c(2L, 1L, 3L))
    expect_equal(out$percent, c(2 / 3 * 100, 1 / 3 * 100, 100))
    expect_equal(out$cum, c(2 / 3 * 100, 100, NA_real_))
    expect_equal(out$valid, c(2 / 3 * 100, 1 / 3 * 100, NA_real_))
    expect_equal(out$valid_cum, c(2 / 3 * 100, 100, NA_real_))
  }
})
joint_data_case(
  "extremely small categories",
  tibble::tibble(x = c(1e-300, 2e-300, 1e-300))
)
joint_data_case(
  "large exact integer-valued doubles",
  tibble::tibble(x = c(2^40, 2^40 + 1, 2^40))
)
# 021-040: complete-case denominators and supported column classes.
joint_data_case(
  "all missing numeric categories",
  tibble::tibble(x = rep(NA_real_, 4))
)
joint_data_case(
  "all missing text categories",
  tibble::tibble(x = rep(NA_character_, 3))
)
joint_data_case(
  "one observed and missing category",
  tibble::tibble(x = c(1, NA, NA))
)
joint_data_case(
  "two observed categories and missing",
  tibble::tibble(x = c(1, 1, 2, NA))
)
joint_data_case(
  "multiple distinct missing patterns",
  tibble::tibble(x = c(1, 1, NA, NA), y = c("a", NA, "a", NA))
)
joint_data_case(
  "missingness in first measured variable",
  tibble::tibble(x = c(1, NA, 1, NA), y = c("b", "a", "a", "b"))
)
joint_data_case(
  "missingness in last measured variable",
  tibble::tibble(x = c(1, 2, 1, 2), y = c("a", NA, NA, "b"))
)
joint_data_case(
  "every row incomplete across columns",
  tibble::tibble(x = c(1, NA, NA), y = c(NA, "b", NA))
)
joint_data_case(
  "valid row denominator differs from category count",
  tibble::tibble(x = c(rep("a", 5), "b", NA, NA))
)
joint_data_case(
  "three-way complete-case denominator",
  tibble::tibble(
    x = c(1, 1, NA, 2),
    y = c("a", NA, "b", "b"),
    z = c(TRUE, TRUE, FALSE, FALSE)
  )
)
joint_data_case(
  "factor keeps observed levels only",
  tibble::tibble(x = factor(c("b", "a", "b"), levels = c("b", "a", "unused"))),
  category_order = c("b", "a")
)
joint_data_case(
  "ordered factor categories",
  tibble::tibble(
    x = ordered(c("high", "low", "low"), levels = c("low", "high"))
  ),
  category_order = c("low", "high")
)
joint_data_case(
  "factor missing value",
  tibble::tibble(x = factor(c("a", NA, "b", "a")))
)
joint_data_case(
  "Date categories span leap day",
  tibble::tibble(x = as.Date(c("2024-02-28", "2024-02-29", "2024-02-29")))
)
joint_data_case(
  "Date missingness",
  tibble::tibble(x = as.Date(c("2024-01-01", NA, "2024-01-01")))
)
joint_data_case(
  "UTC datetimes",
  tibble::tibble(x = as.POSIXct(c(0, 60, 0), origin = "1970-01-01", tz = "UTC"))
)
joint_data_case(
  "difftime categories in hours",
  tibble::tibble(x = as.difftime(c(1, 2, 1, NA), units = "hours"))
)
joint_data_case(
  "numeric labelled values render labels in fre",
  tibble::tibble(x = haven::labelled(c(1, 2, 1, NA), c(Yes = 1, No = 2)))
)
joint_data_case(
  "SPSS user-missing codes exclude valid denominator",
  tibble::tibble(
    x = haven::labelled_spss(
      c(1, 2, -99, 1),
      c(Yes = 1, No = 2, Missing = -99),
      na_values = -99
    )
  )
)
joint_data_case(
  "SPSS missing range excludes valid denominator",
  tibble::tibble(
    x = haven::labelled_spss(c(1, 2, 91, 95), na_range = c(90, 99))
  )
)
# 041-060: grouping and within-group missingness/totals.
joint_data_case(
  "two groups independent denominators",
  tibble::tibble(g = c("a", "a", "b", "b", "b"), x = c(1, 2, 1, 1, 2)),
  "x",
  "g"
)
joint_data_case(
  "missing group key remains a real group",
  tibble::tibble(g = c("a", NA, NA, "b"), x = c(1, 1, NA, 2)),
  "x",
  "g"
)
joint_data_case(
  "all missing group keys",
  tibble::tibble(g = rep(NA_character_, 4), x = c(1, 2, 1, NA)),
  "x",
  "g"
)
joint_data_case(
  "numeric grouping keys",
  tibble::tibble(g = c(10, 2, 10, 2), x = c("a", "b", "a", "a")),
  "x",
  "g"
)
joint_data_case(
  "logical grouping keys",
  tibble::tibble(g = c(TRUE, FALSE, NA, TRUE), x = c(1, 2, 1, 2)),
  "x",
  "g"
)
joint_data_case(
  "factor groups with unused levels",
  tibble::tibble(
    g = factor(c("b", "a", "b"), levels = c("c", "b", "a")),
    x = c(1, 1, 2)
  ),
  "x",
  "g"
)
joint_data_case(
  "Date grouping keys",
  tibble::tibble(
    g = as.Date(c("2020-01-01", "2020-01-02", "2020-01-01")),
    x = c(1, NA, 2)
  ),
  "x",
  "g"
)
joint_data_case(
  "multiple grouping keys",
  tibble::tibble(
    g = c("a", "a", "b", "b"),
    h = c(1, 2, 1, 1),
    x = c(1, 2, 1, NA)
  ),
  "x",
  c("g", "h")
)
joint_data_case(
  "multiple missing grouping-key patterns",
  tibble::tibble(
    g = c("a", NA, NA, "a"),
    h = c(NA, 1, NA, 1),
    x = c(1, 1, 2, 2)
  ),
  "x",
  c("g", "h")
)
joint_data_case(
  "all-missing measured values in one group",
  tibble::tibble(g = c("a", "a", "b", "b"), x = c(NA, NA, 1, 2)),
  "x",
  "g"
)
joint_data_case(
  "singleton groups",
  tibble::tibble(g = letters[1:5], x = c(1, 2, NA, 1, 2)),
  "x",
  "g"
)
joint_data_case(
  "grouped joint missingness",
  tibble::tibble(
    g = rep(c("a", "b"), each = 4),
    x = c(1, 2, NA, NA, 1, 1, 2, 2),
    y = c("a", "b", "a", NA, "a", NA, "b", NA)
  ),
  c("x", "y"),
  "g"
)
joint_data_case(
  "Unicode group keys",
  tibble::tibble(g = c("\u4e2d", "\u6587", "\u4e2d"), x = c(1, 2, NA)),
  "x",
  "g"
)
joint_data_case(
  "grouped zero-row input",
  tibble::tibble(g = character(), x = numeric()),
  "x",
  "g"
)
joint_data_case(
  "descending frequency inside each group",
  tibble::tibble(
    g = c(rep("a", 6), rep("b", 5)),
    x = c(1, 2, 2, 2, NA, NA, 1, 1, 1, 2, NA)
  ),
  "x",
  "g",
  TRUE
)
joint_add("existing grouping inherited when by omitted", function(fun, is_fre) {
  data <- tibble::tibble(g = c("a", "a", "b", "b"), x = c(1, NA, 2, 2))
  grouped <- dplyr::group_by(data, g)
  before <- grouped
  joint_check(fun(grouped, x), data, "x", "g", is_fre)
  expect_identical(grouped, before)
})
joint_add("explicit by overrides pre-existing grouping", function(fun, is_fre) {
  data <- tibble::tibble(
    old = c("a", "b", "a", "b"),
    new = c(1, 1, 2, 2),
    x = c("y", "y", "n", "n")
  )
  out <- fun(dplyr::group_by(data, old), x, .by = new)
  expect_false("old" %in% names(out))
  joint_check(out, data, "x", "new", is_fre)
})
joint_add(
  "group key selected also is counted only as key",
  function(fun, is_fre) {
    data <- tibble::tibble(g = c("a", "a", "b"), x = c(1, 1, 2))
    joint_check(fun(data, g, x, .by = g), data, "x", "g", is_fre)
  }
)
joint_data_case(
  "different group sizes and valid denominators",
  tibble::tibble(
    g = c(rep("a", 2), rep("b", 7)),
    x = c(1, NA, 1, 1, 1, 2, 2, NA, NA)
  ),
  "x",
  "g"
)
joint_data_case(
  "three grouping keys",
  tibble::tibble(
    g = c("a", "a", "b"),
    h = c(1, 2, 1),
    k = c(TRUE, FALSE, TRUE),
    x = c(NA, 2, 1)
  ),
  "x",
  c("g", "h", "k")
)
# 061-080: selection, expressions, output identities and protected names.
joint_add("starts_with selection", function(fun, is_fre) {
  data <- tibble::tibble(a_x = c(1, 1, 2), a_y = c("a", "b", "a"), z = 1:3)
  joint_check(
    fun(data, tidyselect::starts_with("a_")),
    data,
    c("a_x", "a_y"),
    fre = is_fre
  )
})
joint_add("negative selection", function(fun, is_fre) {
  data <- tibble::tibble(x = c(1, 1, 2), z = 1:3)
  joint_check(fun(data, -z), data, "x", fre = is_fre)
})
joint_add("numeric column positions", function(fun, is_fre) {
  data <- tibble::tibble(x = c(1, 1, 2), y = c("a", "b", "a"))
  joint_check(fun(data, 1:2), data, c("x", "y"), fre = is_fre)
})
joint_add("where numeric selection", function(fun, is_fre) {
  data <- tibble::tibble(x = c(1, 1, 2), y = c("a", "b", "a"))
  joint_check(fun(data, tidyselect::where(is.numeric)), data, "x", fre = is_fre)
})
joint_add("renamed selected column", function(fun, is_fre) {
  data <- tibble::tibble(x = c(1, 1, 2))
  expected <- tibble::tibble(answer = data$x)
  joint_check(fun(data, answer = x), expected, "answer", fre = is_fre)
})
joint_add("logical computed expression", function(fun, is_fre) {
  data <- tibble::tibble(x = c(1, 2, 2, NA))
  expected <- tibble::tibble(high = data$x > 1)
  joint_check(fun(data, high = x > 1), expected, "high", fre = is_fre)
})
joint_add("numeric computed expression", function(fun, is_fre) {
  data <- tibble::tibble(x = c(-2, 2, -1, 1))
  expected <- tibble::tibble(squared = data$x^2)
  joint_check(fun(data, squared = x^2), expected, "squared", fre = is_fre)
})
joint_add(
  "computed categories alongside original column",
  function(fun, is_fre) {
    data <- tibble::tibble(x = c(1, 2, 3, 4), y = c("a", "a", "b", "b"))
    expected <- tibble::tibble(y = data$y, even = data$x %% 2 == 0)
    joint_check(
      fun(data, y, even = x %% 2 == 0),
      expected,
      c("y", "even"),
      fre = is_fre
    )
  }
)
joint_data_case(
  "non-syntactic column names",
  setNames(tibble::tibble(c(1, 1, 2), c("a", "b", "a")), c("some value", "a-b"))
)
joint_add("Unicode variable name", function(fun, is_fre) {
  data <- setNames(tibble::tibble(c(1, 1, NA)), "\u6536\u5165")
  # Windows R's C locale cannot translate CJK mask names to native encoding.
  # Capture only that known environmental diagnostic; any other warning escapes.
  native_warnings <- character()
  out <- withCallingHandlers(fun(data), warning = function(w) {
    msg <- conditionMessage(w)
    if (
      .Platform$OS.type == "windows" &&
        Sys.getlocale("LC_CTYPE") == "C" &&
        grepl("unable to translate.*native encoding", msg)
    ) {
      native_warnings <<- c(native_warnings, msg)
      invokeRestart("muffleWarning")
    }
  })
  if (length(native_warnings)) {
    expect_true(all(grepl(
      "unable to translate.*native encoding",
      native_warnings
    )))
  }
  joint_check(out, data, names(data), fre = is_fre)
})
joint_add("count output name is safely renamed", function(fun, is_fre) {
  data <- tibble::tibble(n = c("a", "a", "b"))
  expect_message(out <- fun(data, n), "renamed")
  joint_check(out, tibble::tibble(.n = data$n), ".n", fre = is_fre)
})
joint_add("percentage output names are safely renamed", function(fun, is_fre) {
  data <- tibble::tibble(percent = c(1, 1, 2), valid = c("a", "b", "a"))
  expect_message(out <- fun(data), "renamed")
  joint_check(
    out,
    tibble::tibble(.percent = data$percent, .valid = data$valid),
    c(".percent", ".valid"),
    fre = is_fre
  )
})
joint_add(
  "reserved group key remains a key after rename",
  function(fun, is_fre) {
    data <- tibble::tibble(n = c("a", "a", "b"), x = c(1, 2, 1))
    expect_message(out <- fun(data, x, .by = n), "renamed")
    joint_check(out, tibble::tibble(.n = data$n, x = data$x), "x", ".n", is_fre)
  }
)
joint_add("reserved metadata names are safely renamed", function(fun, is_fre) {
  data <- tibble::tibble(...any_miss = c("a", "a", "b"), ...tmp = c(1, 2, 1))
  expect_message(out <- fun(data), "renamed")
  joint_check(
    out,
    tibble::tibble(....any_miss = data$...any_miss, ....tmp = data$...tmp),
    c("....any_miss", "....tmp"),
    fre = is_fre
  )
})
joint_add(
  "reserved-name collision rejects ambiguous rename",
  function(fun, is_fre) {
    data <- tibble::tibble(n = c(1, 2), .n = c(2, 1))
    expect_message(expect_error(fun(data), "new name|Rename fails"), "renamed")
  }
)
joint_add(
  "literal Total category remains distinguishable",
  function(fun, is_fre) {
    data <- tibble::tibble(x = c("Total", "Total", "other", NA))
    joint_check(fun(data, x), data, "x", fre = is_fre)
  }
)
joint_add("literal subtotal labels remain categories", function(fun, is_fre) {
  data <- tibble::tibble(x = c("Valid Total", "Missing Total", "a", NA))
  joint_check(fun(data, x), data, "x", fre = is_fre)
})
joint_data_case(
  "descending counts keep missing values last",
  tibble::tibble(x = c("a", "b", "b", NA, NA, NA)),
  desc = TRUE
)
joint_data_case(
  "descending frequency tie retains exact counts",
  tibble::tibble(x = c("c", "b", "a", "a", "b", "c")),
  desc = TRUE
)
joint_data_case(
  "descending joint missing categories",
  tibble::tibble(
    x = c(1, 2, 2, NA, NA, NA),
    y = c("a", "b", "b", "a", "a", NA)
  ),
  desc = TRUE
)
# 081-100: list identities, broad shapes, metamorphic and invalid-input cases.
joint_data_case(
  "list vectors are whole categories",
  tibble::tibble(x = list(1:2, 1:2, 2:3), marker = c("a", "a", "a"))
)
joint_data_case(
  "list order is part of identity",
  tibble::tibble(x = list(c(1, 2), c(2, 1), c(1, 2)), marker = rep("a", 3))
)
joint_data_case(
  "list NULL and empty vector differ",
  tibble::tibble(x = list(NULL, numeric(), NULL), marker = rep("a", 3))
)
joint_data_case(
  "nested list identities",
  tibble::tibble(
    x = list(list(a = 1), list(a = 1), list(a = 2)),
    marker = rep("a", 3)
  )
)
joint_data_case(
  "list scalar missing values",
  tibble::tibble(x = list(NA_real_, 1, NA_real_, 2), marker = rep("a", 4))
)
joint_data_case(
  "five measured variables retain joint counts",
  tibble::tibble(
    a = c(1, 1, 2),
    b = c("x", "x", "y"),
    c = c(TRUE, TRUE, FALSE),
    d = c(2, 2, 1),
    e = c("u", "v", "u")
  )
)
joint_data_case(
  "six measured variables use separate total label",
  tibble::tibble(
    a = c(1, 1, 2),
    b = c("x", "x", "y"),
    c = c(TRUE, TRUE, FALSE),
    d = c(2, 2, 1),
    e = c("u", "v", "u"),
    f = c(1, 1, NA)
  )
)
joint_data_case(
  "six measured variables with group key",
  tibble::tibble(
    g = c("a", "a", "b"),
    a = c(1, 1, 2),
    b = c("x", "x", "y"),
    c = c(TRUE, TRUE, FALSE),
    d = c(2, 2, 1),
    e = c("u", "v", "u"),
    f = c(1, 1, NA)
  ),
  letters[1:6],
  "g"
)
joint_add(
  "no selected columns returns typed empty table",
  function(fun, is_fre) {
    data <- tibble::tibble(x = 1:3)
    joint_check(
      fun(data, tidyselect::starts_with("absent")),
      data,
      character(),
      fre = is_fre
    )
  }
)
joint_add(
  "no selected columns preserves empty group schema",
  function(fun, is_fre) {
    data <- tibble::tibble(g = c("a", "a", "b"), x = 1:3)
    joint_check(
      fun(data, tidyselect::starts_with("absent"), .by = g),
      data,
      character(),
      "g",
      is_fre
    )
  }
)
joint_add("base data.frame input returns tibble", function(fun, is_fre) {
  data <- data.frame(x = c(1, 1, 2), y = c("a", "b", "a"))
  joint_check(fun(data), data, c("x", "y"), fre = is_fre)
})
joint_add(
  "column labels and input attributes preserved",
  function(fun, is_fre) {
    data <- tibble::tibble(x = c(1, 1, 2))
    attr(data$x, "label") <- "Example label"
    attr(data, "source") <- "QA fixture"
    before <- serialize(data, NULL)
    joint_check(fun(data, x), data, "x", fre = is_fre)
    expect_identical(serialize(data, NULL), before)
  }
)
joint_add("row permutation preserves joint frequencies", function(fun, is_fre) {
  data <- tibble::tibble(x = c(1, 2, 2, NA, 1), y = c("a", "b", "b", "a", "b"))
  permuted <- data[c(5, 3, 1, 4, 2), ]
  first <- fun(data)
  second <- fun(permuted)
  joint_check(second, permuted, c("x", "y"), fre = is_fre)
  expect_equal(second, first)
})
joint_add(
  "duplicating rows doubles counts with same percentages",
  function(fun, is_fre) {
    data <- tibble::tibble(x = c(1, 2, 2, NA))
    twice <- data[rep(seq_len(nrow(data)), 2), , drop = FALSE]
    first <- fun(data, x)
    second <- fun(twice, x)
    joint_check(second, twice, "x", fre = is_fre)
    expect_equal(second$n, 2 * first$n)
    expect_equal(second$percent, first$percent)
    expect_equal(second$valid, first$valid)
  }
)
joint_data_case(
  "deterministic 1000-row grouped survey",
  tibble::tibble(
    g = rep(letters[1:5], 200),
    x = rep(c(1, 1, 2, 3, NA), 200),
    y = rep(c("a", "b", "a", NA), 250)
  ),
  c("x", "y"),
  "g"
)
joint_add("matrix columns reject unsupported structure", function(fun, is_fre) {
  data <- tibble::tibble(x = matrix(1:6, nrow = 3))
  expect_error(fun(data, x), "[Mm]atrix")
})
joint_add("missing selected column errors", function(fun, is_fre) {
  expect_error(fun(tibble::tibble(x = 1:3), absent))
})
joint_add(
  "duplicate column names reject ambiguous inputs",
  function(fun, is_fre) {
    data <- tibble::tibble(x = 1:3, y = 3:1)
    names(data) <- c("x", "x")
    expect_error(fun(data, x))
  }
)
joint_add("NULL input is invalid", function(fun, is_fre) {
  expect_error(fun(NULL))
})
joint_add("missing grouping column errors", function(fun, is_fre) {
  expect_error(fun(tibble::tibble(x = 1:3), x, .by = absent))
})
stopifnot(length(joint_cases) == 100L)
for (joint_function_name in c("tab", "fre")) {
  for (joint_case_id in seq_along(joint_cases)) {
    local({
      fun_name <- joint_function_name
      case <- joint_cases[[joint_case_id]]
      id <- joint_case_id
      testthat::test_that(
        sprintf("%s coverage %03d: %s", fun_name, id, case$title),
        {
          case$run(
            getExportedValue("statart", fun_name),
            identical(fun_name, "fre")
          )
        }
      )
    })
  }
}
