# Comprehensive Test Suite for var_type() and var_unit() Functions
# Type detection and unit extraction

# CHALLENGE: Comprehensive testing for var_type, var_unit
# FUNCTIONS: var_type, var_unit
# KEY BEHAVIORS: type detection, unit extraction
# EDGE CASES: ambiguous types, compound units

# ============================================================================
# CHALLENGING TESTS - var_type() Basic Types
# ============================================================================

test_that("var_type: integer vector", {
  x <- 1:5
  result <- var_type(x)
  expect_type(result, "character")
  expect_equal(result, "integer")
})

test_that("var_type: double vector", {
  x <- c(1.5, 2.5, 3.5)
  result <- var_type(x)
  expect_equal(result, "double")
})

test_that("var_type: character vector", {
  x <- letters[1:5]
  result <- var_type(x)
  expect_equal(result, "character")
})

test_that("var_type: logical vector", {
  x <- c(TRUE, FALSE, TRUE)
  result <- var_type(x)
  expect_equal(result, "logical")
})

test_that("var_type: factor", {
  x <- factor(c("a", "b", "c"))
  result <- var_type(x)
  expect_equal(result, "factor")
})

test_that("var_type: ordered factor", {
  x <- ordered(c("low", "medium", "high"))
  result <- var_type(x)
  expect_equal(result, "ordered")
})

test_that("var_type: abbreviation mode", {
  x <- 1:5
  result_full <- var_type(x, abbr = FALSE)
  result_abbr <- var_type(x, abbr = TRUE)
  expect_equal(result_full, "integer")
  expect_equal(result_abbr, "int")
})

# ============================================================================
# CHALLENGING TESTS - var_type() Date/Time Types
# ============================================================================

test_that("var_type: Date", {
  x <- as.Date(c("2024-01-01", "2024-06-15"))
  result <- var_type(x)
  expect_equal(result, "date")
})

test_that("var_type: POSIXct (datetime)", {
  x <- as.POSIXct(c("2024-01-01 10:00:00", "2024-06-15 14:30:00"))
  result <- var_type(x)
  expect_equal(result, "datetime")
})

test_that("var_type: difftime (duration)", {
  x <- as.difftime(c(1, 2, 3), units = "hours")
  result <- var_type(x)
  expect_equal(result, "duration")
})

test_that("var_type: hms time", {
  skip_if_not_installed("hms")
  x <- hms::as_hms(c("08:00:00", "12:00:00"))
  result <- var_type(x)
  expect_type(result, "character")
})

# ============================================================================
# CHALLENGING TESTS - var_type() Complex Types
# ============================================================================

test_that("var_type: haven labelled", {
  x <- haven::labelled(c(1, 2, 1), labels = c(Yes = 1, No = 2))
  result <- var_type(x)
  expect_type(result, "character")
  expect_true(grepl("label|lbl", result))
})

test_that("var_type: list", {
  x <- list(1, 2, 3)
  result <- var_type(x)
  expect_type(result, "character")
})

test_that("var_type: data frame", {
  x <- tibble::tibble(a = 1:5, b = 6:10)
  result <- var_type(x)
  expect_type(result, "character")
})

test_that("var_type: complex numbers", {
  x <- c(1 + 2i, 3 + 4i)
  result <- var_type(x)
  expect_equal(result, "complex")
})

test_that("var_type: function", {
  x <- mean
  result <- var_type(x)
  expect_equal(result, "function")
})

# ============================================================================
# CHALLENGING TESTS - var_type() Edge Cases
# ============================================================================

test_that("var_type: NA vector", {
  x <- c(NA, NA, NA)
  result <- var_type(x)
  expect_type(result, "character")
})

test_that("var_type: empty vector", {
  x <- numeric(0)
  result <- var_type(x)
  expect_type(result, "character")
})

test_that("var_type: single element", {
  x <- 42
  result <- var_type(x)
  expect_equal(result, "double")
})

test_that("var_type: Inf values", {
  x <- c(1, Inf, -Inf)
  result <- var_type(x)
  expect_equal(result, "double")
})

test_that("var_type: NaN values", {
  x <- c(1, NaN, 3)
  result <- var_type(x)
  expect_equal(result, "double")
})

# ============================================================================
# CHALLENGING TESTS - var_type() Within Data Frames
# ============================================================================

test_that("var_type: applied to each column with summarise", {
  df <- tibble::tibble(
    int_col = 1:5,
    dbl_col = c(1.5, 2.5, 3.5, 4.5, 5.5),
    chr_col = letters[1:5],
    fct_col = factor(letters[1:5]),
    logi_col = c(TRUE, FALSE, TRUE, FALSE, TRUE)
  )

  result <- df |>
    dplyr::summarise(dplyr::across(dplyr::everything(), var_type))

  expect_s3_class(result, "tbl_df")
  expect_equal(result$int_col, "integer")
  expect_equal(result$dbl_col, "double")
  expect_equal(result$chr_col, "character")
  expect_equal(result$fct_col, "factor")
  expect_equal(result$logi_col, "logical")
})

test_that("var_type: within mutate for type checking", {
  df <- tibble::tibble(
    x = 1:5,
    y = letters[1:5]
  )

  result <- df |>
    dplyr::mutate(x_type = var_type(x), y_type = var_type(y))

  expect_equal(result$x_type[1], "integer")
  expect_equal(result$y_type[1], "character")
})

# ============================================================================
# CHALLENGING TESTS - var_unit()
# ============================================================================

test_that("var_unit: units object", {
  skip_if_not_installed("units")
  x <- units::set_units(c(1, 2, 3), "m")
  result <- var_unit(x)
  expect_type(result, "character")
  expect_false(is.na(result))
})

test_that("var_type and var_unit: measured length metadata", {
  skip_if_not_installed("units")
  x <- units::set_units(c(1, 2, 3), "m")
  original <- x

  expect_identical(var_type(x), "units")
  expect_identical(var_type(x, abbr = TRUE), "units")
  expect_identical(var_unit(x), "m")
  expect_identical(x, original)
})

test_that("var_type and var_unit: compound speed metadata", {
  skip_if_not_installed("units")
  x <- units::set_units(c(1, 2, 3), "m/s")

  expect_identical(var_type(x), "units")
  expect_identical(var_type(x, abbr = TRUE), "units")
  expect_identical(var_unit(x), "m/s")
})

test_that("var_type and var_unit: dimensionless metadata", {
  skip_if_not_installed("units")
  x <- units::set_units(c(1, 2, 3), "1")

  expect_identical(var_type(x), "units")
  expect_identical(var_type(x, abbr = TRUE), "units")
  expect_identical(var_unit(x), "1")
})

test_that("var_type and var_unit: empty measured vector metadata", {
  skip_if_not_installed("units")
  x <- units::set_units(numeric(0), "m")

  expect_identical(var_type(x), "units")
  expect_identical(var_type(x, abbr = TRUE), "units")
  expect_identical(var_unit(x), "m")
})

test_that("var_type and var_unit: all-missing measured vector metadata", {
  skip_if_not_installed("units")
  x <- units::set_units(c(NA_real_, NA_real_), "m")

  expect_identical(var_type(x), "units")
  expect_identical(var_type(x, abbr = TRUE), "units")
  expect_identical(var_unit(x), "m")
})

test_that("var_type and var_unit: codebook retains measurement metadata", {
  skip_if_not_installed("units")
  df <- tibble::tibble(distance = units::set_units(c(1, NA, 3), "m"))
  original <- df

  result <- codebook(df)

  expect_equal(result$variable, "distance")
  expect_equal(result$type, "units [m]")
  expect_equal(result$n, 2)
  expect_equal(result$unique, 2)
  expect_identical(df, original)
})

test_that("var_unit: difftime with units", {
  x <- as.difftime(c(1, 2, 3), units = "hours")
  result <- var_unit(x)
  expect_type(result, "character")
  expect_false(is.na(result))
})

test_that("var_unit: hms time", {
  skip_if_not_installed("hms")
  x <- hms::as_hms(c("08:00:00", "12:00:00"))
  result <- var_unit(x)
  expect_type(result, "character")
})

test_that("var_unit: regular numeric returns NA", {
  x <- 1:5
  result <- var_unit(x)
  expect_true(is.na(result))
})

test_that("var_unit: character returns NA", {
  x <- letters[1:5]
  result <- var_unit(x)
  expect_true(is.na(result))
})

test_that("var_unit: factor returns NA", {
  x <- factor(c("a", "b", "c"))
  result <- var_unit(x)
  expect_true(is.na(result))
})

# ============================================================================
# CHALLENGING TESTS - Integration with Codebook Workflow
# ============================================================================

test_that("var_type: used in codebook workflow", {
  withr::local_preserve_seed()
  df <- tibble::tibble(
    id = 1:100,
    income = rnorm(100, 50000, 10000),
    gender = sample(c("M", "F"), 100, replace = TRUE),
    score = sample(1:100, 100)
  )

  # Simulate codebook variable summary
  var_summary <- df |>
    dplyr::summarise(dplyr::across(
      dplyr::everything(),
      list(
        type = var_type,
        n = ~ sum(!is.na(.))
      )
    ))

  expect_s3_class(var_summary, "tbl_df")
})

test_that("var_type: type validation function", {
  is_numeric_type <- function(x) {
    type <- var_type(x, abbr = TRUE)
    type %in% c("int", "dbl")
  }

  expect_true(is_numeric_type(1:5))
  expect_true(is_numeric_type(c(1.5, 2.5)))
  expect_false(is_numeric_type(letters[1:5]))
  expect_false(is_numeric_type(factor(c("a", "b"))))
})

# ============================================================================
# CHALLENGING TESTS - Real-world Scenarios
# ============================================================================

test_that("var_type: data audit workflow", {
  withr::local_preserve_seed()
  audit_data <- tibble::tibble(
    transaction_id = 1:1000,
    amount = rnorm(1000, 100, 20),
    currency = sample(c("USD", "EUR", "GBP"), 1000, replace = TRUE),
    timestamp = Sys.time() + 1:1000,
    is_valid = sample(c(TRUE, FALSE), 1000, replace = TRUE)
  )

  # Get type summary for all columns
  type_summary <- audit_data |>
    dplyr::summarise(dplyr::across(dplyr::everything(), var_type))

  expect_equal(type_summary$transaction_id, "integer")
  expect_equal(type_summary$amount, "double")
  expect_equal(type_summary$currency, "character")
  expect_equal(type_summary$is_valid, "logical")
})

test_that("var_type: ETL pipeline type checking", {
  raw_data <- tibble::tibble(
    id = as.character(1:100), # IDs stored as character
    value = rep(c("100.5", "200.3", "150.0"), length.out = 100), # Values as character
    date = rep(c("2024-01-01", "2024-01-02", "2024-01-03"), length.out = 100) # Dates as character
  )

  # Check types before conversion
  original_types <- raw_data |>
    dplyr::summarise(dplyr::across(dplyr::everything(), var_type))

  expect_equal(unique(unlist(original_types)), "character")

  # After conversion
  clean_data <- raw_data |>
    dplyr::mutate(
      id = as.integer(id),
      value = as.numeric(value),
      date = as.Date(date)
    )

  clean_types <- clean_data |>
    dplyr::summarise(dplyr::across(dplyr::everything(), var_type))

  expect_equal(clean_types$id, "integer")
  expect_equal(clean_types$value, "double")
  expect_equal(clean_types$date, "date")
})


test_that("type expansion preserves custom names and structured descriptions", {
  x <- structure(1:3, class = "tidystata_type_probe")
  for (label in c(
    "interval",
    "price-usd",
    "integerish",
    "list<int>",
    "ymd<day>"
  )) {
    testthat::local_mocked_bindings(
      type_sum = function(x) label,
      .package = "pillar"
    )
    expect_identical(var_type(x, abbr = TRUE), label)
    expect_identical(var_type(x), label)
  }
})

test_that("missing custom type summaries fall back to the class", {
  x <- structure(1:3, class = "tidystata_type_probe")
  for (label in list(NA_character_, "", character(), c("a", "b"), 1L)) {
    testthat::local_mocked_bindings(
      type_sum = function(x) label,
      .package = "pillar"
    )
    expect_identical(var_type(x), "tidystata_type_probe")
    expect_identical(var_type(x, abbr = TRUE), "tidystata_type_probe")
  }
})

test_that("numeric-looking custom class names do not imply summability", {
  labels <- c("interval", "integerish", "dbl_extra", "timestamp", "date_custom")
  expect_false(any(tidystata:::is_summable_chr(labels)))
  expect_true(all(tidystata:::is_summable_chr(c(
    "int",
    "dbl+lbl",
    "int64",
    "units [m]"
  ))))
})

test_that("structured extension type labels retain their element information", {
  expect_identical(var_type(I(1:3), abbr = TRUE), "I<int>")
  expect_identical(var_type(vctrs::list_of(1:2), abbr = TRUE), "list<int>")
})


# Exact contracts cover storage types and class metadata independently of values.
type_contract_cases <- list(
  logical = list(c(TRUE, FALSE, NA), "lgl", "logical"),
  integer = list(c(1L, 2L, NA_integer_), "int", "integer"),
  double = list(c(1, Inf, NaN, NA_real_), "dbl", "double"),
  complex = list(c(1 + 2i, NA_complex_), "cpl", "complex"),
  character = list(c("1", "2024-01-01", NA_character_), "chr", "character"),
  raw = list(as.raw(1:3), "raw", "raw"),
  list = list(list(1L, NULL, NA, list(a = 1)), "list", "list"),
  factor = list(factor(c("a", NA), levels = c("a", "unused")), "fct", "factor"),
  ordered = list(ordered(c("a", NA), levels = c("a", "b")), "ord", "ordered"),
  date = list(as.Date(c("2024-01-01", NA)), "date", "date"),
  datetime = list(
    as.POSIXct(c("2024-01-01", NA), tz = "UTC"),
    "dttm",
    "datetime"
  ),
  datetime_list = list(
    as.POSIXlt(c("2024-01-01", NA), tz = "UTC"),
    "dttm",
    "datetime"
  ),
  duration = list(
    as.difftime(c(1, NA), units = "hours"),
    "drtn",
    "duration",
    "hours"
  ),
  labelled_integer = list(
    haven::labelled(c(1L, NA_integer_), c(yes = 1L)),
    "int+lbl",
    "integer+label"
  ),
  labelled_double = list(
    haven::labelled(c(1, haven::tagged_na("a")), c(yes = 1)),
    "dbl+lbl",
    "double+label"
  ),
  labelled_character = list(
    haven::labelled(c("a", NA), c(yes = "a")),
    "chr+lbl",
    "character+label"
  ),
  spss = list(
    haven::labelled_spss(c(1, 99, NA), na_values = 99),
    "dbl+lbl",
    "double+label"
  )
)
for (case_name in names(type_contract_cases)) {
  local({
    case <- type_contract_cases[[case_name]]
    states <- list(observed = case[[1]], empty = case[[1]][0L])
    if (case_name != "raw") {
      states$missing <- case[[1]][NA_integer_]
    }
    for (state in names(states)) {
      test_that(paste("type contract", case_name, state), {
        x <- states[[state]]
        before <- serialize(x, NULL)
        expect_identical(var_type(x, abbr = TRUE), case[[2]])
        expect_identical(var_type(x), case[[3]])
        expect_identical(
          var_unit(x),
          if (length(case) == 4L) case[[4]] else NA_character_
        )
        expect_identical(serialize(x, NULL), before)
      })
    }
  })
}

test_that("nonvector type contracts are exact and have no units", {
  cases <- list(
    list(NULL, "NULL", "NULL"),
    list(as.name("x"), "sym", "symbol"),
    list(quote(x + 1), "language", "language"),
    list(expression(x, y), "expression", "expression"),
    list(pairlist(x = 1), "pairlist", "pairlist"),
    list(new.env(parent = emptyenv()), "env", "environment"),
    list(sum, "fn", "function"),
    list(quote, "fn", "function"),
    list(function(x) x, "fn", "function")
  )
  for (case in cases) {
    expect_identical(var_type(case[[1]], abbr = TRUE), case[[2]])
    expect_identical(var_type(case[[1]]), case[[3]])
    expect_identical(var_unit(case[[1]]), NA_character_)
  }
})

test_that("structured base types preserve established element and container names", {
  for (x in list(
    matrix(1:4, 2),
    matrix(integer(), 0, 2),
    array(1:8, c(2, 2, 2))
  )) {
    expect_identical(var_type(x, abbr = TRUE), "int")
    expect_identical(var_type(x), "integer")
    expect_identical(as_numeric(x), as.numeric(x))
  }
  expect_identical(var_type(data.frame(x = integer())), "dataframe")
  expect_identical(var_type(tibble::tibble(x = integer())), "tibble")
  expect_identical(var_type(I(integer())), "I<int>")
  expect_identical(var_type(vctrs::list_of(.ptype = integer())), "list<int>")
})

test_that("type detection propagates extension method errors", {
  testthat::local_mocked_bindings(
    type_sum = function(x) stop("extension failed"),
    .package = "pillar"
  )
  expect_error(
    var_type(structure(1, class = "tidystata_probe")),
    "extension failed"
  )
})

test_that("custom numeric-looking labels remain unsupported in summaries", {
  x <- structure(1:3, class = "interval")
  testthat::local_mocked_bindings(
    type_sum = function(x) "interval",
    .package = "pillar"
  )
  expect_identical(var_type(x), "interval")
  expect_identical(as_numeric(x), rep(NA_real_, 3))
  expect_warning(expect_error(summ(tibble::tibble(x = x)), "None"), "numeric")
  expect_warning(
    out <- summ(
      tibble::tibble(x = x),
      .keep_all = TRUE,
      .stat = c("n", "unique", "mean")
    ),
    "non-numeric"
  )
  expect_identical(out$n, 3L)
  expect_identical(out$unique, 3L)
  expect_true(is.na(out$mean))
})

test_that("integer64 metadata survives empty and missing values", {
  skip_if_not_installed("bit64")
  for (x in list(
    bit64::as.integer64(c("9007199254740993", NA)),
    bit64::integer64(),
    bit64::as.integer64(NA)
  )) {
    expect_identical(var_type(x, abbr = TRUE), "int64")
    expect_identical(var_type(x), "integer64")
    expect_identical(var_unit(x), NA_character_)
  }
})

test_that("hms metadata survives empty and missing values", {
  skip_if_not_installed("hms")
  for (x in list(
    hms::hms(seconds = c(1, NA_real_)),
    hms::hms(numeric()),
    hms::hms(NA_real_)
  )) {
    expect_identical(var_type(x, abbr = TRUE), "time")
    expect_identical(var_type(x), "time")
    expect_identical(var_unit(x), "secs")
  }
})

test_that("unit metadata covers compound and dimensionless vectors in every state", {
  skip_if_not_installed("units")
  for (unit in c("m", "m/s", "1")) {
    for (values in list(c(1, NA_real_), numeric(), NA_real_)) {
      x <- units::set_units(values, unit, mode = "standard")
      expect_identical(var_type(x), "units")
      expect_identical(var_type(x, abbr = TRUE), "units")
      expect_identical(var_unit(x), unit)
    }
  }
})

test_that("geometry labels and table extension names remain class-specific", {
  skip_if_not_installed("sf")
  x <- sf::st_sfc(sf::st_point(c(1, 2)))
  expect_identical(var_type(x), "POINT")
  expect_identical(var_type(x[0]), "POINT")
  expect_identical(var_unit(x), NA_character_)
})


test_that("classed matrices retain their scalar type and numeric conversion", {
  vectors <- list(
    factor(c("a", "b", "a", NA)),
    as.Date("2024-01-01") + c(0, 1, 2, NA),
    as.difftime(c(1, 2, 3, NA), units = "mins")
  )
  for (x in vectors) {
    matrix_x <- x
    dim(matrix_x) <- c(2L, 2L)
    expect_identical(var_type(matrix_x), var_type(x))
    expect_identical(var_type(matrix_x, abbr = TRUE), var_type(x, abbr = TRUE))
    expect_identical(as_numeric(matrix_x), as.numeric(x))
  }
})

test_that("vctrs record types and complete element identities remain intact", {
  x <- vctrs::new_rcrd(
    list(a = c(1, 1, NA), b = c("x", "x", NA)),
    class = "tidystata_record"
  )
  label <- pillar::type_sum(x)
  expect_identical(var_type(x), label)
  expect_identical(var_type(x[0]), label)
  expect_identical(var_unit(x), NA_character_)
  out <- codebook(tibble::tibble(x = x))
  expect_identical(out$type, label)
  expect_identical(out$n, 2L)
  expect_identical(out$unique, 1L)
})

test_that("S4 metadata uses pillar descriptions without interpreting class substrings", {
  x <- methods::getClass("numeric")
  expect_identical(var_type(x), pillar::type_sum(x))
  expect_identical(var_type(x, abbr = TRUE), pillar::type_sum(x))
  expect_identical(var_unit(x), NA_character_)
})

test_that("data.table metadata retains its container name", {
  skip_if_not_installed("data.table")
  x <- data.table::data.table(x = integer())
  expect_identical(var_type(x), "dt")
  expect_identical(var_type(x, abbr = TRUE), "dt")
})


test_that("missing extension abbreviations do not defeat the class fallback", {
  x <- structure(1:3, class = "tidystata_type_probe")
  testthat::local_mocked_bindings(
    type_sum = function(x) NA_character_,
    .package = "pillar"
  )
  testthat::local_mocked_bindings(
    vec_ptype_abbr = function(x) NA_character_,
    .package = "vctrs"
  )
  expect_identical(var_type(x), "tidystata_type_probe")
})


test_that("custom unit-bearing classes retain their units method", {
  registry <- get(".__S3MethodsTable__.", envir = asNamespace("base"))
  registerS3method(
    "units",
    "tidystata_clock_probe",
    function(x) attr(x, "clock_units"),
    envir = asNamespace("base")
  )
  withr::defer(rm("units.tidystata_clock_probe", envir = registry))
  testthat::local_mocked_bindings(
    type_sum = function(x) "time",
    .package = "pillar"
  )
  x <- structure(
    c(1, NA),
    class = "tidystata_clock_probe",
    clock_units = "hours"
  )
  expect_identical(var_type(x), "time")
  expect_identical(var_unit(x), "hours")
})

test_that("var_type and var_unit preserve labelled and duration metadata", {
  labelled <- haven::labelled(
    c(1, NA, 2),
    labels = c(Yes = 1, No = 2),
    label = "Answer"
  )
  duration <- as.difftime(c(1, NA, 2), units = "hours")
  before <- list(labelled, duration)
  expect_identical(var_type(labelled, abbr = TRUE), "dbl+lbl")
  expect_identical(var_type(labelled), "double+label")
  expect_identical(var_unit(labelled), NA_character_)
  expect_identical(var_type(duration), "duration")
  expect_identical(var_unit(duration), "hours")
  expect_identical(list(labelled, duration), before)
})

test_that("var_type returns visible type names for empty and named vectors", {
  expect_identical(var_type(integer()), "integer")
  expect_identical(var_type(setNames(c(1, NA), c("a", "b"))), "double")
  expect_identical(var_unit(integer()), NA_character_)
  expect_identical(
    withVisible(var_type(integer())),
    list(value = "integer", visible = TRUE)
  )
})

test_that("abbr must be TRUE or FALSE", {
  expect_error(var_type(1, abbr = NA), "`abbr` must be `TRUE` or `FALSE`")
})
