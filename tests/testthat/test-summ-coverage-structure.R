# Scenarios 051-100 complement the numeric/grouping scenarios 001-050.
# Shared core scenarios run once through summ(); tabstat wrapper contracts
# live in test-summ-contracts.R. Scenario numbers remain unchanged.
for (function_name in "summ") {
  local({
    api <- summary_legacy_layout(
      getExportedValue("tidystata", function_name)
    )

    test_that(
      paste(
        function_name,
        "coverage",
        sprintf("%03d", 51),
        "[classes]",
        "base data frames regain their class in table mode"
      ),
      {
        input <- data.frame(x = c(2, 4, 9), row.names = c("a", "b", "c"))
        before <- input
        out <- api(input, .type = "table", .stat = c("n", "mean"))
        expect_identical(class(out), "data.frame")
        expect_equal(out$n, 3)
        expect_equal(out$mean, 5)
        expect_identical(input, before)
      }
    )

    test_that(
      paste(
        function_name,
        "coverage",
        sprintf("%03d", 52),
        "[classes]",
        "tibble output retains ordered measured names"
      ),
      {
        input <- tibble::tibble(second = c(2, 4), first = c(6, 8))
        out <- api(input, .type = "table", .stat = "mean")
        expect_s3_class(out, "tbl_df")
        expect_equal(out$name, c("second", "first"))
        expect_equal(out$mean, c(3, 7))
      }
    )

    test_that(
      paste(
        function_name,
        "coverage",
        sprintf("%03d", 53),
        "[classes]",
        "data table output preserves input without reference mutation"
      ),
      {
        skip_if_not_installed("data.table")
        input <- data.table::data.table(x = c(2, 4, NA_real_))
        before <- data.table::copy(input)
        out <- api(input, .type = "table", .stat = c("n", "sum"))
        expect_s3_class(out, "data.table")
        expect_equal(out$n, 2)
        expect_equal(out$sum, 6)
        expect_identical(input, before)
      }
    )

    test_that(
      paste(
        function_name,
        "coverage",
        sprintf("%03d", 54),
        "[vectors]",
        "named vector elements do not become measured columns"
      ),
      {
        x <- c(first = 2, second = 4, last = 9)
        out <- api(x, .stat = c("n", "unique", "mean"))
        expect_equal(nrow(out), 1L)
        expect_equal(out$name, "x")
        expect_equal(out$n, 3)
        expect_equal(out$unique, 3)
        expect_equal(out$mean, 5)
      }
    )

    test_that(
      paste(
        function_name,
        "coverage",
        sprintf("%03d", 55),
        "[vectors]",
        "inline vector expressions retain a meaningful name"
      ),
      {
        out <- api(c(2, 4, 9), .stat = c("min", "max"))
        expect_match(out$name, "^c\\(")
        expect_equal(out$min, 2)
        expect_equal(out$max, 9)
      }
    )

    test_that(
      paste(
        function_name,
        "coverage",
        sprintf("%03d", 56),
        "[types]",
        "grouped logical proportions use observed group denominators"
      ),
      {
        input <- tibble::tibble(
          g = c("A", "A", "B", "B", "B"),
          x = c(FALSE, NA, TRUE, FALSE, TRUE)
        )
        out <- api(
          input,
          x,
          .by = g,
          .stat = c("n", "missing", "valid_pct", "mean", "sum", "sd")
        )
        expect_equal(out$n, c(1, 3))
        expect_equal(out$missing, c(1, 0))
        expect_equal(out$valid_pct, c(.5, 1))
        expect_equal(out$mean, c(0, 2 / 3))
        expect_equal(out$sum, c(0, 2))
        expect_equal(out$sd, c(NA_real_, sqrt(1 / 3)))
      }
    )

    test_that(
      paste(
        function_name,
        "coverage",
        sprintf("%03d", 57),
        "[types]",
        "factor statistics use declared level codes"
      ),
      {
        x <- factor(c("high", "low", "high", NA), levels = c("low", "high"))
        expect_message(
          out <- api(tibble::tibble(x = x), .stat = c("n", "mean", "sum")),
          "factor"
        )
        expect_equal(out$name, "**x")
        expect_equal(out$n, 3)
        expect_equal(out$mean, 5 / 3)
        expect_equal(out$sum, 5)
      }
    )

    test_that(
      paste(
        function_name,
        "coverage",
        sprintf("%03d", 58),
        "[types]",
        "ordered factors preserve unused level positions"
      ),
      {
        x <- ordered(c("low", "high", "high"), levels = c("low", "mid", "high"))
        expect_message(
          out <- api(
            tibble::tibble(x = x),
            .stat = c("unique", "median", "mean")
          ),
          "factor"
        )
        expect_equal(out$name, "**x")
        expect_equal(out$unique, 2)
        expect_equal(out$median, 3)
        expect_equal(out$mean, 7 / 3)
        expect_identical(levels(x), c("low", "mid", "high"))
      }
    )

    test_that(
      paste(
        function_name,
        "coverage",
        sprintf("%03d", 59),
        "[types]",
        "haven labels do not replace numerical values"
      ),
      {
        x <- haven::labelled(c(10, 20, 20, NA), labels = c(Low = 10, High = 20))
        before <- x
        expect_message(
          out <- api(tibble::tibble(x = x), .stat = c("n", "unique", "mean")),
          "labelled"
        )
        expect_equal(out$name, "*x")
        expect_equal(out$n, 3)
        expect_equal(out$unique, 2)
        expect_equal(out$mean, 50 / 3)
        expect_identical(x, before)
      }
    )

    test_that(
      paste(
        function_name,
        "coverage",
        sprintf("%03d", 60),
        "[types]",
        "tagged missing values are excluded from observed counts"
      ),
      {
        x <- c(2, haven::tagged_na("a"), 6, NA_real_)
        out <- api(
          tibble::tibble(x = x),
          .stat = c("n", "unique", "missing", "mean")
        )
        expect_equal(out$n, 2)
        expect_equal(out$unique, 2)
        expect_equal(out$missing, 2)
        expect_equal(out$mean, 4)
        expect_true(haven::is_tagged_na(x[[2]]))
      }
    )

    test_that(
      paste(
        function_name,
        "coverage",
        sprintf("%03d", 61),
        "[types]",
        "SPSS missing ranges and codes follow original missingness"
      ),
      {
        x <- haven::labelled_spss(
          c(1, 2, 90, 95, 99, NA_real_),
          na_range = c(90, 95),
          na_values = 99
        )
        expect_message(
          out <- api(
            tibble::tibble(x = x),
            .stat = c("n", "missing", "valid_pct", "sum", "mean")
          ),
          "labelled"
        )
        expect_equal(out$n, 2)
        expect_equal(out$missing, 4)
        expect_equal(out$valid_pct, 1 / 3)
        expect_equal(out$sum, 3)
        expect_equal(out$mean, 1.5)
      }
    )

    test_that(
      paste(
        function_name,
        "coverage",
        sprintf("%03d", 62),
        "[types]",
        "difftime statistics use the original hour unit"
      ),
      {
        x <- as.difftime(c(1, 2, 6, NA_real_), units = "hours")
        out <- api(tibble::tibble(x = x), .stat = c("n", "mean", "sum", "sd"))
        expect_equal(out$n, 3)
        expect_equal(out$mean, 3)
        expect_equal(out$sum, 9)
        expect_equal(out$sd, stats::sd(c(1, 2, 6)))
        expect_identical(attr(x, "units"), "hours")
      }
    )

    test_that(
      paste(
        function_name,
        "coverage",
        sprintf("%03d", 63),
        "[types]",
        "measured vectors retain their declared unit scale"
      ),
      {
        skip_if_not_installed("units")
        x <- units::set_units(c(100, 200, 300), "cm")
        out <- api(tibble::tibble(x = x), .stat = c("n", "mean", "sum"))
        expect_match(out$type, "cm", fixed = TRUE)
        expect_equal(out$n, 3)
        expect_equal(out$mean, 200)
        expect_equal(out$sum, 600)
        expect_equal(as.numeric(x), c(100, 200, 300))
      }
    )

    test_that(
      paste(
        function_name,
        "coverage",
        sprintf("%03d", 64),
        "[types]",
        "small integer64 values convert without precision loss"
      ),
      {
        skip_if_not_installed("bit64")
        x <- bit64::as.integer64(c(1, 3, 7))
        expect_no_warning(
          out <- api(
            tibble::tibble(x = x),
            .stat = c("n", "unique", "mean", "sum")
          )
        )
        expect_equal(out$n, 3)
        expect_equal(out$unique, 3)
        expect_equal(out$mean, 11 / 3)
        expect_equal(out$sum, 11)
      }
    )

    test_that(
      paste(
        function_name,
        "coverage",
        sprintf("%03d", 65),
        "[retained]",
        "text counts distinguish empty strings from missing values"
      ),
      {
        x <- c("", "", "42", NA_character_)
        expect_message(
          out <- api(
            tibble::tibble(x = x),
            .keep_all = TRUE,
            .stat = c("n", "unique", "missing", "valid_pct", "mean")
          ),
          "non-numeric"
        )
        expect_equal(out$n, 3)
        expect_equal(out$unique, 2)
        expect_equal(out$missing, 1)
        expect_equal(out$valid_pct, .75)
        expect_identical(out$mean, NA_real_)
      }
    )

    test_that(
      paste(
        function_name,
        "coverage",
        sprintf("%03d", 66),
        "[retained]",
        "list identities preserve element order and vector contents"
      ),
      {
        x <- list(c(1, 2), c(1, 2), c(2, 1), NA_real_)
        expect_message(
          out <- api(
            tibble::tibble(x = x),
            .keep_all = TRUE,
            .stat = c("n", "unique", "missing", "sum")
          ),
          "non-numeric"
        )
        expect_equal(out$n, 3)
        expect_equal(out$unique, 2)
        expect_equal(out$missing, 1)
        expect_identical(out$sum, NA_real_)
        expect_identical(x[[3]], c(2, 1))
      }
    )

    test_that(
      paste(
        function_name,
        "coverage",
        sprintf("%03d", 67),
        "[calendar]",
        "dates return readable locations and correct counts"
      ),
      {
        x <- as.Date("2024-02-28") + c(0, 1, 2, NA_real_)
        out <- api(
          tibble::tibble(x = x),
          .stat = c("n", "missing", "min", "mean", "max")
        )
        expect_equal(out$n, 3)
        expect_equal(out$missing, 1)
        expect_equal(out$min, "2024-02-28")
        expect_equal(out$mean, "2024-02-29")
        expect_equal(out$max, "2024-03-01")
      }
    )

    test_that(
      paste(
        function_name,
        "coverage",
        sprintf("%03d", 68),
        "[calendar]",
        "fractional date means omit fractional days from display"
      ),
      {
        x <- as.Date("1970-01-01") + c(0, 1)
        out <- api(
          tibble::tibble(x = x),
          .stat = c("min", "mean", "median", "max")
        )
        expect_equal(out$min, "1970-01-01")
        expect_equal(out$mean, "1970-01-01")
        expect_equal(out$median, "1970-01-01")
        expect_equal(out$max, "1970-01-02")
      }
    )

    test_that(
      paste(
        function_name,
        "coverage",
        sprintf("%03d", 69),
        "[calendar]",
        "date spreads are difftime columns in days"
      ),
      {
        out <- api(
          tibble::tibble(x = as.Date("2024-01-01") + c(0, 2, 4)),
          .stat = c("sd", "iqr", "mad")
        )
        expect_equal(out$sd, as.difftime(2, units = "days"))
        # Stata percentiles of 0, 2, 4: p25 = 0 and p75 = 4.
        expect_equal(out$iqr, as.difftime(4, units = "days"))
        expect_equal(
          out$mad,
          as.difftime(stats::mad(c(0, 2, 4)), units = "days")
        )
      }
    )

    test_that(
      paste(
        function_name,
        "coverage",
        sprintf("%03d", 70),
        "[calendar]",
        "date spreads include an unrounded standard error"
      ),
      {
        # `.duration_format` is retained for compatibility only.
        out <- api(
          tibble::tibble(x = as.Date("2024-01-01") + c(0, 2, 4)),
          .stat = c("sd", "iqr", "mad", "se"),
          .duration_format = "compact"
        )
        expect_equal(out$sd, as.difftime(2, units = "days"))
        # Stata percentiles of 0, 2, 4: p25 = 0 and p75 = 4.
        expect_equal(out$iqr, as.difftime(4, units = "days"))
        expect_equal(
          out$mad,
          as.difftime(stats::mad(c(0, 2, 4)), units = "days")
        )
        expect_equal(out$se, as.difftime(2 / sqrt(3), units = "days"))
      }
    )

    test_that(
      paste(
        function_name,
        "coverage",
        sprintf("%03d", 71),
        "[calendar]",
        "non UTC datetime inputs are displayed in their own time zone"
      ),
      {
        x <- as.POSIXct("2024-01-01 00:00:00", tz = "America/New_York") +
          c(0, 7200)
        before <- x
        out <- api(tibble::tibble(x = x), .stat = c("min", "mean", "max"))
        expect_equal(out$min, "2024-01-01 00:00")
        expect_equal(out$mean, "2024-01-01 01:00")
        expect_equal(out$max, "2024-01-01 02:00")
        expect_identical(x, before)
      }
    )

    test_that(
      paste(
        function_name,
        "coverage",
        sprintf("%03d", 72),
        "[calendar]",
        "datetime locations omit seconds across minute boundaries"
      ),
      {
        x <- as.POSIXct("2024-01-01", tz = "UTC") + c(59, 61)
        out <- api(tibble::tibble(x = x), .stat = c("min", "mean", "max"))
        expect_equal(out$min, "2024-01-01 00:00")
        expect_equal(out$mean, "2024-01-01 00:01")
        expect_equal(out$max, "2024-01-01 00:01")
      }
    )

    test_that(
      paste(
        function_name,
        "coverage",
        sprintf("%03d", 73),
        "[calendar]",
        "minute-scale datetime spreads use minutes"
      ),
      {
        x <- as.POSIXct("2024-01-01", tz = "UTC") + c(0, 120, 240)
        out <- api(tibble::tibble(x = x), .stat = c("sd", "iqr", "se"))
        expect_equal(out$sd, as.difftime(2, units = "mins"))
        expect_equal(out$iqr, as.difftime(4, units = "mins"))
        expect_equal(out$se, as.difftime(2 / sqrt(3), units = "mins"))
      }
    )

    test_that(
      paste(
        function_name,
        "coverage",
        sprintf("%03d", 74),
        "[calendar]",
        "hour-scale datetime spreads use hours"
      ),
      {
        x <- as.POSIXct("2024-01-01", tz = "UTC") + c(0, 3600, 7200)
        out <- api(tibble::tibble(x = x), .stat = c("mean", "sd", "iqr"))
        expect_equal(out$mean, "2024-01-01 01:00")
        expect_equal(out$sd, as.difftime(1, units = "hours"))
        expect_equal(out$iqr, as.difftime(2, units = "hours"))
      }
    )

    test_that(
      paste(
        function_name,
        "coverage",
        sprintf("%03d", 75),
        "[output]",
        "heterogeneous list mode preserves statistic types by family"
      ),
      {
        input <- tibble::tibble(
          x = c(2, 4),
          day = as.Date("2024-01-01") + c(0, 2),
          instant = as.POSIXct("2024-01-01", tz = "UTC") + c(0, 120)
        )
        expect_message(
          out <- api(input, .type = "list", .stat = c("n", "mean")),
          "heterogeneous"
        )
        expect_named(out, c("numeric", "date", "datetime"))
        expect_identical(out$numeric$mean, 3)
        expect_identical(out$date$mean, "2024-01-02")
        expect_identical(out$datetime$mean, "2024-01-01 00:01")
        expect_equal(
          vapply(out, nrow, integer(1)),
          c(numeric = 1L, date = 1L, datetime = 1L)
        )
      }
    )

    test_that(
      paste(
        function_name,
        "coverage",
        sprintf("%03d", 76),
        "[output]",
        "heterogeneous table mode formats shared locations but not counts"
      ),
      {
        input <- tibble::tibble(
          x = c(2, 4),
          day = as.Date("2024-01-01") + c(0, 2),
          instant = as.POSIXct("2024-01-01", tz = "UTC") + c(0, 120)
        )
        out <- api(input, .type = "table", .stat = c("n", "missing", "mean"))
        expect_equal(out$name, c("x", "day", "instant"))
        expect_equal(out$n, c(2, 2, 2))
        expect_equal(out$missing, c(0, 0, 0))
        expect_type(out$n, "integer")
        expect_equal(out$mean, c("3", "2024-01-02", "2024-01-01 00:01"))
      }
    )

    test_that(
      paste(
        function_name,
        "coverage",
        sprintf("%03d", 77),
        "[empty]",
        "zero row calendar columns retain missing formatted locations"
      ),
      {
        input <- tibble::tibble(
          day = as.Date(character()),
          instant = as.POSIXct(character(), tz = "UTC")
        )
        expect_message(
          out <- api(input, .stat = c("n", "unique", "valid_pct", "mean")),
          "heterogeneous"
        )
        for (family in c("date", "datetime")) {
          expect_equal(out[[family]]$n, 0)
          expect_equal(out[[family]]$unique, 0)
          expect_identical(out[[family]]$valid_pct, NA_real_)
          expect_identical(out[[family]]$mean, NA_character_)
        }
      }
    )

    test_that(
      paste(
        function_name,
        "coverage",
        sprintf("%03d", 78),
        "[empty]",
        "empty grouped mixed tables retain schema without invented groups"
      ),
      {
        input <- tibble::tibble(
          g = character(),
          x = numeric(),
          day = as.Date(character())
        )
        out <- api(input, .by = g, .type = "table", .stat = c("n", "mean"))
        expect_equal(nrow(out), 0L)
        expect_named(out, c("g", "name", "type", "n", "mean"))
        expect_type(out$g, "character")
        expect_type(out$mean, "character")
      }
    )

    test_that(
      paste(
        function_name,
        "coverage",
        sprintf("%03d", 79),
        "[selection]",
        "tidyselect helpers choose only matching names"
      ),
      {
        input <- tibble::tibble(
          score_a = c(1, 3),
          other = c(100, 200),
          score_b = c(6, 8)
        )
        out <- api(input, tidyselect::starts_with("score_"), .stat = "mean")
        expect_equal(out$name, c("score_a", "score_b"))
        expect_equal(out$mean, c(2, 7))
      }
    )

    test_that(
      paste(
        function_name,
        "coverage",
        sprintf("%03d", 80),
        "[selection]",
        "negative selection omits the excluded measured variable"
      ),
      {
        input <- tibble::tibble(
          x = c(1, 3),
          nuisance = c(100, 200),
          y = c(6, 8)
        )
        out <- api(input, -nuisance, .stat = "mean")
        expect_equal(out$name, c("x", "y"))
        expect_equal(out$mean, c(2, 7))
      }
    )

    test_that(
      paste(
        function_name,
        "coverage",
        sprintf("%03d", 81),
        "[selection]",
        "programmatic selection supports non syntactic and Unicode names"
      ),
      {
        input <- tibble::tibble(x = c(2, 4), y = c(10, 20))
        names(input) <- c("annual income", "\u5e74\u9f84")
        selected <- c("\u5e74\u9f84", "annual income")
        out <- api(input, tidyselect::all_of(selected), .stat = "mean")
        expect_equal(out$name, selected)
        expect_equal(out$mean, c(15, 3))
      }
    )

    test_that(
      paste(
        function_name,
        "coverage",
        sprintf("%03d", 82),
        "[selection]",
        "data masking computes expressions rather than filtering rows"
      ),
      {
        input <- tibble::tibble(x = c(1, 2, 4))
        out <- api(
          input,
          squared = x^2,
          positive = x > 1,
          .stat = c("n", "mean", "sum")
        )
        expect_equal(out$name, c("squared", "positive"))
        expect_equal(out$n, c(3, 3))
        expect_equal(out$mean, c(7, 2 / 3))
        expect_equal(out$sum, c(21, 2))
        expect_identical(input$x, c(1, 2, 4))
      }
    )

    test_that(
      paste(
        function_name,
        "coverage",
        sprintf("%03d", 83),
        "[selection]",
        "renamed selected variables use their requested output names"
      ),
      {
        input <- tibble::tibble(old = c(2, 4), other = c(6, 8))
        out <- api(input, renamed = old, .stat = "mean")
        expect_equal(out$name, "renamed")
        expect_equal(out$mean, 3)
        expect_named(input, c("old", "other"))
      }
    )

    test_that(
      paste(
        function_name,
        "coverage",
        sprintf("%03d", 84),
        "[statistics]",
        "duplicate requests deduplicate while aliases coexist in order"
      ),
      {
        out <- api(
          tibble::tibble(x = c(1, 3, 5, NA_real_)),
          .stat = c("p50", "mean", "p50", "median", "missing", "miss_n")
        )
        expect_named(
          out,
          c("name", "type", "p50", "mean", "median", "missing", "miss_n")
        )
        expect_equal(out$p50, 3)
        expect_equal(out$median, 3)
        expect_equal(out$mean, 3)
        expect_equal(out$missing, 1)
        expect_equal(out$miss_n, 1)
      }
    )

    test_that(
      paste(
        function_name,
        "coverage",
        sprintf("%03d", 85),
        "[output]",
        "name false retains variable identity when several variables are measured"
      ),
      {
        out <- api(
          tibble::tibble(x = c(1, 3), y = c(4, 8)),
          .name = FALSE,
          .stat = "mean"
        )
        expect_equal(out$name, c("x", "y"))
        expect_equal(out$mean, c(2, 6))
      }
    )

    test_that(
      paste(
        function_name,
        "coverage",
        sprintf("%03d", 86),
        "[validation]",
        "unknown statistics fail without returning a partial selection"
      ),
      {
        expect_error(
          api(tibble::tibble(x = 1:3), .stat = c("mean", "variance_typo")),
          "Unsupported statistic.*variance_typo"
        )
      }
    )

    test_that(
      paste(
        function_name,
        "coverage",
        sprintf("%03d", 87),
        "[validation]",
        "missing statistic names are rejected before calculation"
      ),
      {
        expect_error(
          api(tibble::tibble(x = numeric()), .stat = c("mean", NA_character_)),
          "stat.*character.*non-missing"
        )
      }
    )

    test_that(
      paste(
        function_name,
        "coverage",
        sprintf("%03d", 88),
        "[validation]",
        "selection of an absent variable provides a useful selection error"
      ),
      {
        expect_error(
          api(tibble::tibble(x = 1:3), absent, .stat = "mean"),
          "absent"
        )
      }
    )

    test_that(
      paste(
        function_name,
        "coverage",
        sprintf("%03d", 89),
        "[validation]",
        "invalid output modes are rejected"
      ),
      {
        expect_error(
          api(tibble::tibble(x = 1:3), .type = "wide"),
          "must be one of.*list.*table"
        )
      }
    )

    test_that(
      paste(
        function_name,
        "coverage",
        sprintf("%03d", 90),
        "[validation]",
        "invalid duration formats are rejected even for numeric input"
      ),
      {
        expect_error(
          api(tibble::tibble(x = 1:3), .duration_format = "seconds"),
          "must be one of.*long.*compact"
        )
      }
    )

    test_that(
      paste(
        function_name,
        "coverage",
        sprintf("%03d", 91),
        "[validation]",
        "logical controls reject numeric truth values"
      ),
      {
        expect_error(
          api(tibble::tibble(x = 1:3), .keep_all = 1),
          "keep_all.*must be `TRUE` or `FALSE`"
        )
        expect_error(
          api(tibble::tibble(x = 1:3), .name = c(TRUE, FALSE)),
          "name.*must be `TRUE` or `FALSE`"
        )
      }
    )

    test_that(
      paste(
        function_name,
        "coverage",
        sprintf("%03d", 92),
        "[validation]",
        "matrix columns fail rather than flattening observations"
      ),
      {
        input <- tibble::tibble(x = matrix(1:6, nrow = 3))
        expect_error(
          api(input, .keep_all = TRUE),
          "Matrix/data-frame columns are not supported"
        )
        expect_identical(dim(input$x), c(3L, 2L))
      }
    )

    test_that(
      paste(
        function_name,
        "coverage",
        sprintf("%03d", 93),
        "[validation]",
        "data frame columns fail rather than silently expanding variables"
      ),
      {
        input <- tibble::tibble(nested = tibble::tibble(x = 1:3, y = 4:6))
        expect_error(
          api(input, .keep_all = TRUE),
          "Matrix/data-frame columns are not supported"
        )
        expect_named(input$nested, c("x", "y"))
      }
    )

    test_that(
      paste(
        function_name,
        "coverage",
        sprintf("%03d", 94),
        "[validation]",
        "unsupported only selections warn and fail with keep all disabled"
      ),
      {
        expect_message(
          expect_error(api(tibble::tibble(x = c("a", "b"))), "None.*suitable"),
          "non-numeric.*removed"
        )
      }
    )

    test_that(
      paste(
        function_name,
        "coverage",
        sprintf("%03d", 95),
        "[validation]",
        "selecting no measured variables raises a clear error"
      ),
      {
        expect_error(
          api(tibble::tibble(x = 1:3), tidyselect::any_of("absent")),
          "None.*suitable"
        )
      }
    )

    test_that(
      paste(
        function_name,
        "coverage",
        sprintf("%03d", 96),
        "[validation]",
        "calendar sums are explicitly unsupported"
      ),
      {
        input <- tibble::tibble(x = as.Date("2024-01-01") + 0:2)
        expect_error(
          api(input, .stat = c("mean", "sum")),
          "sum.*not supported.*date"
        )
      }
    )

    test_that(
      paste(
        function_name,
        "coverage",
        sprintf("%03d", 97),
        "[validation]",
        "datetime skew is explicitly unsupported"
      ),
      {
        input <- tibble::tibble(x = as.POSIXct("2024-01-01", tz = "UTC") + 0:2)
        expect_error(api(input, .stat = "skew"), "Unsupported statistic.*skew")
      }
    )

    test_that(
      paste(
        function_name,
        "coverage",
        sprintf("%03d", 98),
        "[validation]",
        "date kurtosis is explicitly unsupported"
      ),
      {
        input <- tibble::tibble(x = as.Date("2024-01-01") + 0:2)
        expect_error(
          api(input, .stat = "kurtosis"),
          "Unsupported statistic.*kurtosis"
        )
      }
    )

    test_that(
      paste(
        function_name,
        "coverage",
        sprintf("%03d", 99),
        "[calendar]",
        "date percentile aliases share correctly formatted calendar values"
      ),
      {
        input <- tibble::tibble(x = as.Date("2024-12-29") + 0:4)
        out <- api(input, .stat = c("p25", "q1", "p50", "median", "p75", "q3"))
        expect_named(
          out,
          c("name", "type", "p25", "q1", "p50", "median", "p75", "q3")
        )
        expect_equal(out$p25, "2024-12-30")
        expect_equal(out$q1, out$p25)
        expect_equal(out$p50, "2024-12-31")
        expect_equal(out$median, out$p50)
        expect_equal(out$p75, "2025-01-01")
        expect_equal(out$q3, out$p75)
      }
    )

    test_that(
      paste(
        function_name,
        "coverage",
        sprintf("%03d", 100),
        "[retained]",
        "NULL and nested list values are counted without flattening"
      ),
      {
        x <- list(NULL, NULL, list(a = 1), list(a = 1), NA_real_)
        expect_message(
          out <- api(
            tibble::tibble(x = x),
            .keep_all = TRUE,
            .stat = c("n", "unique", "missing", "mean")
          ),
          "non-numeric"
        )
        expect_equal(out$n, 4)
        expect_equal(out$unique, 2)
        expect_equal(out$missing, 1)
        expect_identical(out$mean, NA_real_)
        expect_identical(x[[3]], list(a = 1))
      }
    )
  })
}
