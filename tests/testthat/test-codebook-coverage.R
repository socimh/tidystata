# Public codebook acceptance: 100 numbered scenarios.
# Expected counts are hand-calculated or derived with base R, never statart
# internals. Structured columns count complete observed rows; lists retain the
# established element identity semantics (NULL and empty vectors are elements).

cb_expect <- function(
  data,
  n,
  unique,
  type = NULL,
  variables = names(data),
  labels = NULL
) {
  out <- codebook(data)
  expect_s3_class(out, "tbl_df")
  expect_false(inherits(out, "grouped_df"))
  expect_false(inherits(out, "rowwise_df"))
  expect_identical(out$variable, variables)
  expect_equal(out$n, n)
  expect_equal(out$unique, unique)
  expect_identical(
    names(out),
    if (is.null(labels)) {
      c("variable", "type", "n", "unique")
    } else {
      c("variable", "label", "type", "n", "unique")
    }
  )
  if (!is.null(type)) {
    expect_identical(out$type, type)
  }
  if (!is.null(labels)) {
    expect_identical(out$label, labels)
  }
  invisible(out)
}

test_that("codebook coverage 001: integer storage and repeated values", {
  cb_expect(tibble::tibble(x = c(1L, 1L, 2L, NA_integer_)), 3, 2, "integer")
})
test_that("codebook coverage 002: doubles exclude ordinary missing values", {
  cb_expect(tibble::tibble(x = c(1.5, NA, 2.5, 1.5)), 3, 2, "double")
})
test_that("codebook coverage 003: logical values count both observed states", {
  cb_expect(tibble::tibble(x = c(TRUE, FALSE, TRUE, NA)), 3, 2, "logical")
})
test_that("codebook coverage 004: character blanks are observed distinct values", {
  cb_expect(tibble::tibble(x = c("", " ", "a", "", NA)), 4, 3, "character")
})
test_that("codebook coverage 005: Unicode character values retain identity", {
  cb_expect(
    tibble::tibble(x = c("\u4e2d", "\u6587", "\u4e2d", NA)),
    3,
    2,
    "character"
  )
})
test_that("codebook coverage 006: factor counts omit unused levels", {
  cb_expect(
    tibble::tibble(x = factor(c("a", "a", NA), levels = c("a", "b"))),
    2,
    1,
    "factor"
  )
})
test_that("codebook coverage 007: ordered factors preserve their type", {
  cb_expect(
    tibble::tibble(
      x = ordered(c("low", "high", NA), levels = c("low", "middle", "high"))
    ),
    2,
    2,
    "ordered"
  )
})
test_that("codebook coverage 008: complex missing values are excluded", {
  cb_expect(
    tibble::tibble(x = c(1 + 2i, 1 + 2i, 2 + 1i, NA_complex_)),
    3,
    2,
    "complex"
  )
})
test_that("codebook coverage 009: raw zero is observed", {
  cb_expect(tibble::tibble(x = as.raw(c(0, 0, 255))), 3, 2, "raw")
})
test_that("codebook coverage 010: all missing numeric columns retain a row", {
  cb_expect(tibble::tibble(x = c(NA_real_, NA_real_)), 0, 0, "double")
})
test_that("codebook coverage 011: NaN is missing", {
  cb_expect(tibble::tibble(x = c(NaN, NaN, 1)), 1, 1, "double")
})
test_that("codebook coverage 012: infinities are observed distinct values", {
  cb_expect(tibble::tibble(x = c(Inf, -Inf, Inf, NA)), 3, 2, "double")
})
test_that("codebook coverage 013: signed zeros have one identity", {
  cb_expect(tibble::tibble(x = c(0, -0, 0)), 3, 1, "double")
})
test_that("codebook coverage 014: singleton observation", {
  cb_expect(tibble::tibble(x = 42), 1, 1, "double")
})
test_that("codebook coverage 015: typed zero-row columns retain type and zero counts", {
  cb_expect(
    tibble::tibble(i = integer(), c = character(), l = logical()),
    c(0, 0, 0),
    c(0, 0, 0),
    c("integer", "character", "logical")
  )
})
test_that("codebook coverage 016: no columns return the fixed empty schema", {
  cb_expect(tibble::tibble(), integer(), integer(), character())
})
test_that("codebook coverage 017: zero-column data frame with rows remains empty", {
  cb_expect(
    data.frame(row.names = seq_len(4)),
    integer(),
    integer(),
    character()
  )
})
test_that("codebook coverage 018: all unique values have unique count equal to n", {
  cb_expect(tibble::tibble(x = seq_len(1000)), 1000, 1000, "integer")
})
test_that("codebook coverage 019: repetition changes n but not unique count", {
  x <- rep(c(3, 7, 11), c(20, 30, 50))
  cb_expect(tibble::tibble(x = x), 100, 3, "double")
})
test_that("codebook coverage 020: mixed storage reports in input column order", {
  cb_expect(
    tibble::tibble(z = c("a", NA), a = c(1L, 2L), m = c(TRUE, NA)),
    c(1, 2, 1),
    c(1, 2, 1),
    c("character", "integer", "logical")
  )
})
test_that("codebook coverage 021: leap dates use observed date identity", {
  cb_expect(
    tibble::tibble(
      x = as.Date(c("2024-02-29", "2024-02-29", "2024-03-01", NA))
    ),
    3,
    2,
    "date"
  )
})
test_that("codebook coverage 022: datetime fractions count separate instants", {
  x <- as.POSIXct(c(0, 0.1, 0.1, NA), origin = "1970-01-01", tz = "UTC")
  cb_expect(tibble::tibble(x = x), 3, 2, "datetime")
})
test_that("codebook coverage 023: timezone does not change instant counts", {
  x <- as.POSIXct(
    c(0, 0, 3600, NA),
    origin = "1970-01-01",
    tz = "America/New_York"
  )
  cb_expect(tibble::tibble(x = x), 3, 2, "datetime")
})
test_that("codebook coverage 024: duration includes its declared unit", {
  cb_expect(
    tibble::tibble(x = as.difftime(c(1, 1, 2, NA), units = "hours")),
    3,
    2,
    "duration [hours]"
  )
})
test_that("codebook coverage 025: all missing duration retains unit metadata", {
  cb_expect(
    tibble::tibble(x = as.difftime(c(NA_real_, NA_real_), units = "mins")),
    0,
    0,
    "duration [mins]"
  )
})
test_that("codebook coverage 026: hms reports seconds and missingness", {
  skip_if_not_installed("hms")
  cb_expect(
    tibble::tibble(x = hms::as_hms(c(0, 3600, 3600, NA))),
    3,
    2,
    "time [secs]"
  )
})
test_that("codebook coverage 027: measured units are displayed without conversion", {
  skip_if_not_installed("units")
  cb_expect(
    tibble::tibble(x = units::set_units(c(1, 1, 2, NA), "cm")),
    3,
    2,
    "units [cm]"
  )
})
test_that("codebook coverage 028: empty measured vector retains unit", {
  skip_if_not_installed("units")
  cb_expect(
    tibble::tibble(x = units::set_units(numeric(), "m")),
    0,
    0,
    "units [m]"
  )
})
test_that("codebook coverage 029: integer64 identity survives values above double precision", {
  skip_if_not_installed("bit64")
  x <- bit64::as.integer64(c(
    "9007199254740992",
    "9007199254740993",
    "9007199254740993",
    NA
  ))
  cb_expect(tibble::tibble(x = x), 3, 2, "integer64")
})
test_that("codebook coverage 030: deterministic wider data agree with base counts", {
  x <- tibble::as_tibble(stats::setNames(
    lapply(seq_len(30), function(i) {
      replace((seq_len(100) * i) %% 17, seq(i, 100, by = 31), NA)
    }),
    paste0("v", seq_len(30))
  ))
  cb_expect(
    x,
    unname(vapply(x, function(z) sum(!is.na(z)), integer(1))),
    unname(vapply(x, function(z) length(unique(z[!is.na(z)])), integer(1)))
  )
})
test_that("codebook coverage 031: numeric haven labels do not merge value codes", {
  x <- haven::labelled(c(1, 2, 2, NA), labels = c(Same = 1, Same = 2))
  cb_expect(tibble::tibble(x = x), 3, 2, "double+label")
})
test_that("codebook coverage 032: character haven labels preserve raw identities", {
  x <- haven::labelled(
    c("a", "b", "a", NA),
    labels = c(Alpha = "a", Beta = "b")
  )
  cb_expect(tibble::tibble(x = x), 3, 2, "character+label")
})
test_that("codebook coverage 033: tagged missing codes are all excluded", {
  x <- haven::labelled(c(
    1,
    haven::tagged_na("a"),
    haven::tagged_na("z"),
    NA,
    1
  ))
  cb_expect(tibble::tibble(x = x), 2, 1, "double+label")
})
test_that("codebook coverage 034: SPSS discrete user missing codes are excluded from unique", {
  x <- haven::labelled_spss(c(1, 1, 99, NA), na_values = 99)
  cb_expect(tibble::tibble(x = x), 2, 1, "double+label")
})
test_that("codebook coverage 035: SPSS multiple missing codes are excluded", {
  x <- haven::labelled_spss(c(1, 2, 97, 98, 99, NA), na_values = c(97, 98, 99))
  cb_expect(tibble::tibble(x = x), 2, 2, "double+label")
})
test_that("codebook coverage 036: SPSS missing range includes its endpoints", {
  x <- haven::labelled_spss(c(1, 96, 97, 98, 99, 100, NA), na_range = c(97, 99))
  cb_expect(tibble::tibble(x = x), 3, 3, "double+label")
})
test_that("codebook coverage 037: SPSS range and discrete exclusions compose", {
  x <- haven::labelled_spss(
    c(1, 1, 9, 97, 98, 99, NA),
    na_values = 9,
    na_range = c(97, 99)
  )
  cb_expect(tibble::tibble(x = x), 2, 1, "double+label")
})
test_that("codebook coverage 038: SPSS all user missing has no observed identities", {
  x <- haven::labelled_spss(c(97, 98, 99, NA), na_range = c(97, 99))
  cb_expect(tibble::tibble(x = x), 0, 0, "double+label")
})
test_that("codebook coverage 039: SPSS character missing code is omitted", {
  x <- haven::labelled_spss(
    c("yes", "yes", "missing", NA),
    na_values = "missing"
  )
  cb_expect(tibble::tibble(x = x), 2, 1, "character+label")
})
test_that("codebook coverage 040: one variable label adds the ordered label column", {
  cb_expect(
    tibble::tibble(x = structure(c(1, NA), label = "Age in years")),
    1,
    1,
    "double",
    labels = "Age in years"
  )
})
test_that("codebook coverage 041: mixed labels use NA for unlabelled variables", {
  cb_expect(
    tibble::tibble(a = structure(1:2, label = "Identifier"), b = c("a", "b")),
    c(2, 2),
    c(2, 2),
    c("integer", "character"),
    labels = c("Identifier", NA_character_)
  )
})
test_that("codebook coverage 042: empty string label is treated as absent metadata", {
  cb_expect(tibble::tibble(x = structure(1:2, label = "")), 2, 2, "integer")
})
test_that("codebook coverage 043: Unicode and multiline labels are unchanged", {
  label <- "\u5e74\u9f84\nAge"
  cb_expect(
    tibble::tibble(x = structure(1:2, label = label)),
    2,
    2,
    "integer",
    labels = label
  )
})
test_that("codebook coverage 044: unselected labels do not add a label column", {
  x <- tibble::tibble(a = structure(1:2, label = "Hidden"), b = 1:2)
  out <- codebook(x, b)
  expect_identical(names(out), c("variable", "type", "n", "unique"))
  expect_identical(out$variable, "b")
})
test_that("codebook coverage 045: labelled empty column retains its label", {
  cb_expect(
    tibble::tibble(x = structure(integer(), label = "Empty measurement")),
    0,
    0,
    "integer",
    labels = "Empty measurement"
  )
})
test_that("codebook coverage 046: value labels and variable labels remain distinct", {
  x <- haven::labelled(
    c(1, 2, NA),
    labels = c(No = 1, Yes = 2),
    label = "Response"
  )
  cb_expect(tibble::tibble(x = x), 2, 2, "double+label", labels = "Response")
})
test_that("codebook coverage 047: labelled source is not mutated", {
  x <- tibble::tibble(
    x = haven::labelled_spss(
      c(1, 99, NA),
      labels = c(Yes = 1),
      na_values = 99,
      label = "Response"
    )
  )
  before <- serialize(x, NULL)
  out <- codebook(x)
  expect_identical(serialize(x, NULL), before)
  expect_equal(out$n, 1)
  expect_equal(out$unique, 1)
})
test_that("codebook coverage 048: measured source is not mutated", {
  skip_if_not_installed("units")
  x <- tibble::tibble(x = units::set_units(c(1, NA, 1), "kg"))
  before <- serialize(x, NULL)
  cb_expect(x, 2, 1, "units [kg]")
  expect_identical(serialize(x, NULL), before)
})
test_that("codebook coverage 049: all missing labelled source retains type and metadata", {
  x <- haven::labelled(
    c(NA_real_, haven::tagged_na("a")),
    labels = c(Yes = 1),
    label = "Unobserved"
  )
  cb_expect(tibble::tibble(x = x), 0, 0, "double+label", labels = "Unobserved")
})
test_that("codebook coverage 050: list column label describes the whole variable", {
  x <- structure(list(1:2, 1:2, NA), label = "Nested responses")
  cb_expect(tibble::tibble(x = x), 2, 1, "list", labels = "Nested responses")
})
test_that("codebook coverage 051: bare selection returns only requested variable", {
  out <- codebook(tibble::tibble(a = 1:2, b = c(3, NA)), b)
  expect_identical(out$variable, "b")
  expect_equal(out$n, 1)
})
test_that("codebook coverage 052: positive positions preserve requested order", {
  out <- codebook(tibble::tibble(a = 1:2, b = 1:2, c = 1:2), 3, 1)
  expect_identical(out$variable, c("c", "a"))
})
test_that("codebook coverage 053: negative selection omits specified columns", {
  out <- codebook(tibble::tibble(a = 1:2, b = 1:2, c = 1:2), -b)
  expect_identical(out$variable, c("a", "c"))
})
test_that("codebook coverage 054: starts_with selects matching names", {
  out <- codebook(
    tibble::tibble(pre_a = 1:2, z = 1:2, pre_b = 1:2),
    tidyselect::starts_with("pre_")
  )
  expect_identical(out$variable, c("pre_a", "pre_b"))
})
test_that("codebook coverage 055: ends_with selects matching names", {
  out <- codebook(
    tibble::tibble(a_id = 1:2, id_b = 1:2, c_id = 1:2),
    tidyselect::ends_with("_id")
  )
  expect_identical(out$variable, c("a_id", "c_id"))
})
test_that("codebook coverage 056: where selects numeric storage types", {
  out <- codebook(
    tibble::tibble(i = 1:2, c = c("a", "b"), d = c(1, 2)),
    tidyselect::where(is.numeric)
  )
  expect_identical(out$variable, c("i", "d"))
})
test_that("codebook coverage 057: all_of supports programmatic selection order", {
  wanted <- c("b", "a")
  out <- codebook(
    tibble::tibble(a = 1:2, b = 1:2, c = 1:2),
    tidyselect::all_of(wanted)
  )
  expect_identical(out$variable, wanted)
})
test_that("codebook coverage 058: absent any_of selection has fixed empty schema", {
  out <- codebook(tibble::tibble(a = 1:2), tidyselect::any_of("absent"))
  expect_equal(nrow(out), 0)
  expect_identical(names(out), c("variable", "type", "n", "unique"))
})
test_that("codebook coverage 059: renamed selection retains original label", {
  out <- codebook(
    tibble::tibble(a = structure(1:2, label = "Original")),
    renamed = a
  )
  expect_identical(out$variable, "renamed")
  expect_identical(out$label, "Original")
})
test_that("codebook coverage 060: computed column counts transformed values", {
  out <- codebook(tibble::tibble(x = c(1, 1, 2, NA)), squared = x^2)
  expect_identical(out$variable, "squared")
  expect_equal(out$n, 3)
  expect_equal(out$unique, 2)
})
test_that("codebook coverage 061: logical computed columns retain logical type", {
  out <- codebook(tibble::tibble(x = c(1, 2, 3, NA)), positive = x > 1)
  expect_identical(out$type, "logical")
  expect_equal(out$n, 3)
  expect_equal(out$unique, 2)
})
test_that("codebook coverage 062: multiple computed columns follow expression order", {
  out <- codebook(
    tibble::tibble(x = c(1, 2, NA)),
    square = x^2,
    present = !is.na(x)
  )
  expect_identical(out$variable, c("square", "present"))
  expect_equal(out$n, c(2, 3))
  expect_equal(out$unique, c(2, 2))
})
test_that("codebook coverage 063: programmatic unquoting selects a column", {
  var <- rlang::sym("b")
  out <- codebook(tibble::tibble(a = 1:2, b = c(1, NA)), !!var)
  expect_identical(out$variable, "b")
  expect_equal(out$n, 1)
})
test_that("codebook coverage 064: data pronoun computes without column ambiguity", {
  out <- codebook(tibble::tibble(x = c(1, 2, NA)), shifted = .data$x + 1)
  expect_identical(out$variable, "shifted")
  expect_equal(out$n, 2)
  expect_equal(out$unique, 2)
})
test_that("codebook coverage 065: environment pronoun is available in computation", {
  offset <- 5
  out <- codebook(
    tibble::tibble(x = c(1, 1, NA), offset = c(10, 20, 30)),
    shifted = x + .env$offset
  )
  expect_identical(out$variable, "shifted")
  expect_equal(out$n, 2)
  expect_equal(out$unique, 1)
})
test_that("codebook coverage 066: no-match prefix returns an empty result", {
  out <- codebook(tibble::tibble(a = 1:2), tidyselect::starts_with("none"))
  expect_equal(nrow(out), 0)
  expect_identical(out$variable, character())
})
test_that("codebook coverage 067: explicit everything matches omitted selection", {
  x <- tibble::tibble(a = c(1, NA), b = c("a", "b"))
  expect_identical(codebook(x, tidyselect::everything()), codebook(x))
})
test_that("codebook coverage 068: repeated selection does not duplicate variables", {
  out <- codebook(tibble::tibble(a = 1:2, b = 1:2), a, a)
  expect_identical(out$variable, "a")
  expect_equal(nrow(out), 1)
})
test_that("codebook coverage 069: accepted computation is not rerun", {
  counter <- new.env(parent = emptyenv())
  counter$n <- 0L
  transform <- function(a) {
    force(a)
    counter$n <- counter$n + 1L
    a * 2
  }
  x <- tibble::tibble(a = 1:3)
  out <- codebook(x, doubled = transform(a))
  expect_identical(counter$n, 1L)
  expect_identical(out$variable, "doubled")
  expect_equal(out$unique, 3)
})
test_that("codebook coverage 070: filtering and selection compose in a pipeline", {
  x <- tibble::tibble(id = 1:5, score = c(10, 10, NA, 20, 30))
  out <- x |> dplyr::filter(id <= 4) |> codebook(score)
  expect_identical(out$variable, "score")
  expect_equal(out$n, 3)
  expect_equal(out$unique, 2)
})
test_that("codebook coverage 071: existing groups do not partition the codebook", {
  x <- dplyr::group_by(tibble::tibble(g = c("a", "b", "a"), x = c(1, 1, NA)), g)
  cb_expect(x, c(3, 2), c(2, 1), c("character", "double"))
})
test_that("codebook coverage 072: multiple groups still yield one row per variable", {
  x <- dplyr::group_by(
    tibble::tibble(g = c("a", "a", "b"), h = c(1L, 2L, 1L), x = c(1, NA, 3)),
    g,
    h
  )
  cb_expect(x, c(3, 3, 2), c(2, 2, 2), c("character", "integer", "double"))
})
test_that("codebook coverage 073: grouped factor includes only observed levels", {
  x <- dplyr::group_by(
    tibble::tibble(g = factor(c("a", "a"), levels = c("a", "b")), x = c(1, NA)),
    g,
    .drop = FALSE
  )
  cb_expect(x, c(2, 1), c(1, 1), c("factor", "double"))
})
test_that("codebook coverage 074: zero-row grouped data retain all variables", {
  x <- dplyr::group_by(tibble::tibble(g = character(), x = double()), g)
  cb_expect(x, c(0, 0), c(0, 0), c("character", "double"))
})
test_that("codebook coverage 075: missing grouping keys are counted as missing data", {
  x <- dplyr::group_by(tibble::tibble(g = c("a", NA, "b"), x = c(1, 2, NA)), g)
  cb_expect(x, c(2, 2), c(2, 2), c("character", "double"))
})
test_that("codebook coverage 076: rowwise data are summarized as whole columns", {
  x <- dplyr::rowwise(tibble::tibble(a = c(1, 1, NA), b = c("x", "y", "x")))
  cb_expect(x, c(2, 3), c(1, 2), c("double", "character"))
})
test_that("codebook coverage 077: rowwise identifier remains an ordinary variable", {
  x <- dplyr::rowwise(tibble::tibble(id = c("a", "b"), x = c(1, NA)), id)
  cb_expect(x, c(2, 1), c(2, 1), c("character", "double"))
})
test_that("codebook coverage 078: grouped selection omits keys and preserves input", {
  x <- dplyr::group_by(tibble::tibble(g = c("b", "a", "b"), x = c(1, NA, 2)), g)
  before <- serialize(x, NULL)
  out <- codebook(x, x)
  expect_identical(serialize(x, NULL), before)
  expect_identical(out$variable, "x")
  expect_equal(out$n, 2)
})
test_that("codebook coverage 079: row permutation leaves codebook counts invariant", {
  x <- tibble::tibble(a = c(1, 2, 1, NA), b = c("a", "b", "a", NA))
  expect_identical(codebook(x[c(4, 1, 3, 2), ]), codebook(x))
})
test_that("codebook coverage 080: duplicating rows doubles n and preserves unique", {
  x <- tibble::tibble(a = c(1, NA, 1), b = c("a", "b", "b"))
  out <- codebook(dplyr::bind_rows(x, x))
  expect_equal(out$n, c(4, 6))
  expect_equal(out$unique, c(1, 2))
})
test_that("codebook coverage 081: list duplicate vectors count one identity", {
  cb_expect(tibble::tibble(x = list(1:2, 1:2, 3:4, NA)), 3, 2, "list")
})
test_that("codebook coverage 082: NULL and empty vectors remain list elements", {
  cb_expect(tibble::tibble(x = list(NULL, integer(), NULL, NA)), 3, 2, "list")
})
test_that("codebook coverage 083: nested list structure is compared by identity", {
  cb_expect(
    tibble::tibble(x = list(list(a = 1), list(a = 1), list(a = 2))),
    3,
    2,
    "list"
  )
})
test_that("codebook coverage 084: empty list column keeps one metadata row", {
  cb_expect(tibble::tibble(x = list()), 0, 0, "list")
})
test_that("codebook coverage 085: matrix columns count complete row observations", {
  x <- matrix(c(1, 1, NA, 2, 2, NA), nrow = 3)
  cb_expect(tibble::tibble(x = x), 2, 1, "double")
})
test_that("codebook coverage 086: partial-missing matrix rows are incomplete observations", {
  x <- matrix(c(1, 1, 2, NA, 3, 3), nrow = 3)
  cb_expect(tibble::tibble(x = x), 2, 2, "double")
})
test_that("codebook coverage 087: nested data frame uses complete-row identity", {
  x <- data.frame(a = c(1, 1, NA), b = c("x", "x", NA))
  cb_expect(tibble::tibble(x = x), 2, 1, "dataframe")
})
test_that("codebook coverage 088: all incomplete nested rows have zero counts", {
  x <- data.frame(a = c(1, NA_real_), b = c(NA_real_, 2))
  cb_expect(tibble::tibble(x = x), 0, 0, "dataframe")
})
test_that("codebook coverage 089: base data frame returns tibble and preserves row names", {
  x <- data.frame(a = c(1, 1, NA), row.names = c("one", "two", "three"))
  before <- serialize(x, NULL)
  cb_expect(x, 2, 1, "double")
  expect_identical(serialize(x, NULL), before)
})
test_that("codebook coverage 090: data.table input returns tibble without mutation", {
  skip_if_not_installed("data.table")
  x <- data.table::data.table(a = c(1, 1, NA), b = c("x", "y", "x"))
  before <- data.table::copy(x)
  cb_expect(x, c(2, 3), c(1, 2), c("double", "character"))
  expect_identical(x, before)
})
test_that("codebook coverage 091: metadata-like input names do not collide", {
  nms <- c("value", "variable", "label", "unit", "type", "n", "unique")
  x <- tibble::as_tibble(stats::setNames(
    rep(list(c(1, 1, NA)), length(nms)),
    nms
  ))
  cb_expect(x, rep(2, 7), rep(1, 7), rep("double", 7))
})
test_that("codebook coverage 092: Unicode non-syntactic names remain exact", {
  nms <- c("\u5e74\u9f84", "with spaces", "x-y", ".data")
  x <- tibble::as_tibble(stats::setNames(rep(list(c(1, NA)), length(nms)), nms))
  cb_expect(x, rep(1, 4), rep(1, 4), rep("double", 4))
})
test_that("codebook coverage 093: reserved value name carries a variable label", {
  cb_expect(
    tibble::tibble(value = structure(c(1, NA), label = "Response")),
    1,
    1,
    "double",
    labels = "Response"
  )
})
test_that("codebook coverage 094: NULL is rejected as non-data-frame input", {
  expect_error(codebook(NULL))
})
test_that("codebook coverage 095: atomic vector input is rejected", {
  expect_error(codebook(1:3))
})
test_that("codebook coverage 096: list input is rejected despite named columns", {
  expect_error(codebook(list(a = 1:3)))
})
test_that("codebook coverage 097: absent bare selection errors", {
  expect_error(codebook(tibble::tibble(a = 1:3), absent))
})
test_that("codebook coverage 098: out-of-range positional selection errors", {
  expect_error(codebook(tibble::tibble(a = 1:3), 1:10))
})
test_that("codebook coverage 099: invalid computed output size errors", {
  expect_error(codebook(tibble::tibble(a = 1:3), bad = a[1:2]))
})
test_that("codebook coverage 100: codebook integrates labelled survey preparation", {
  raw <- tibble::tibble(
    id = 1:6,
    age = c(20, 30, NA, 40, 50, 60),
    response = haven::labelled_spss(
      c(1, 2, 99, 1, 2, 99),
      labels = c(Yes = 1, No = 2),
      na_values = 99,
      label = "Response"
    )
  )
  prepared <- raw |>
    dplyr::filter(!is.na(age)) |>
    dplyr::mutate(adult = age >= 30)
  before <- serialize(prepared, NULL)
  out <- codebook(prepared, response, adult)
  expect_identical(out$variable, c("response", "adult"))
  expect_identical(out$label, c("Response", NA_character_))
  expect_equal(out$n, c(4, 5))
  expect_equal(out$unique, c(2, 2))
  expect_identical(serialize(prepared, NULL), before)
})
