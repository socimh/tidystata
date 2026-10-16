library(testthat)
library(statart)
library(tibble)

# These contracts apply to both public entry points. Calculated references use
# ordinary R arithmetic rather than statart's implementation helpers.
for (function_name in c("summ", "tabstat")) {
  local({
    api <- getExportedValue("statart", function_name)
    for (key in c("name", "value", "type", "n", "mean", "p50")) {
      local({
        group_key <- key
        test_that(paste(function_name, "preserves reserved grouping key", group_key), {
          df <- tibble(x = c(1, 3, 8), g = c("a", "a", "b"))
          names(df)[2] <- group_key
          before <- df
          expect_message(
            out <- api(df, x, .by = tidyselect::all_of(group_key),
                       .stat = c("n", "mean", "p50")),
            "renamed"
          )
          expect_equal(out[[paste0(".", group_key)]], c("a", "b"))
          expect_equal(out$n, c(2, 1))
          expect_equal(out$mean, c(2, 8))
          expect_equal(out$p50, c(2, 8))
          expect_equal(out$name, c("x", "x"))
          expect_identical(df, before)
        })
      })
    }

    test_that(paste(function_name, "reserved grouping repair avoids existing dotted names"), {
      df <- tibble(name = c("a", "a", "b"), .name = c("A", "A", "B"),
                   ..name = 1:3, x = c(1, 3, 8))
      out <- suppressMessages(api(df, x, .by = c(name, .name), .stat = "mean"))
      expect_equal(out$...name, c("a", "b"))
      expect_equal(out$.name, c("A", "B"))
      expect_equal(out$mean, c(2, 8))
      expect_equal(out$name, c("x", "x"))
    })

    test_that(paste(function_name, "explicit by overrides pre-existing groups"), {
      df <- dplyr::group_by(tibble(g = c("a", "b", "b"),
                                  h = c("z", "z", "y"), x = c(1, 3, 8)), g)
      out <- api(df, x, .by = h, .stat = "mean")
      expect_false("g" %in% names(out))
      expect_equal(out$h, c("z", "y"))
      expect_equal(out$mean, c(2, 8))
      expect_identical(dplyr::group_vars(df), "g")
    })

    test_that(paste(function_name, "uses pre-existing groups when by is omitted"), {
      df <- dplyr::group_by(tibble(g = c("a", "a", "b"), x = c(1, 3, 8)), g)
      out <- api(df, x, .stat = "mean")
      expect_equal(out$g, c("a", "b"))
      expect_equal(out$mean, c(2, 8))
    })

    test_that(paste(function_name, "drops name for one variable in empty grouped output"), {
      out <- api(tibble(g = character(), x = numeric()), x, .by = g,
                 .name = FALSE, .stat = "mean")
      expect_equal(nrow(out), 0L)
      expect_named(out, c("g", "type", "mean"))
    })

    test_that(paste(function_name, "retains name for multiple variables in empty grouped output"), {
      out <- api(tibble(g = character(), x = numeric(), y = integer()),
                 .by = g, .name = FALSE, .stat = "mean")
      expect_named(out, c("g", "name", "type", "mean"))
    })

    test_that(paste(function_name, "accepts fractional-second datetime spread in compact mode"), {
      df <- tibble(t = as.POSIXct("2024-01-01", tz = "UTC") + c(0, 1))
      out <- api(df, .stat = c("mean", "sd", "mad", "iqr", "se"),
                 .duration_format = "compact")
      expect_equal(out$mean, "2024-01-01 00:00")
      expect_equal(out$sd, "1s")
      expect_equal(out$mad, "1s")
      expect_equal(out$iqr, "0s")
      expect_equal(out$se, "0s")
    })

    test_that(paste(function_name, "single statistic datetime still works in compact mode"), {
      out <- api(tibble(t = as.POSIXct("2024-01-01", tz = "UTC") + 0:2),
                 .stat = "mean", .duration_format = "compact")
      expect_equal(out$mean, "2024-01-01 00:00")
    })

    test_that(paste(function_name, "preserves measured columns named data pronouns"), {
      df <- tibble(.data = c(1, 3, 8), .env = c(2, 4, 6))
      out <- api(df, .stat = c("n", "mean"))
      expect_equal(out$name, c(".data", ".env"))
      expect_equal(out$mean, c(4, 4))
      expect_equal(out$n, c(3, 3))
    })

    test_that(paste(function_name, "plain vector input has correct numeric statistics"), {
      x <- c(1, 3, NA_real_, 8)
      out <- api(x, .stat = c("n", "mean", "sum"))
      expect_equal(out$n, 3)
      expect_equal(out$mean, 4)
      expect_equal(out$sum, 12)
      expect_equal(out$name, "x")
    })

    test_that(paste(function_name, "logical control arguments reject missing and nonscalar values"), {
      for (argument in c(".keep_all", ".detail", ".na.rm", ".name")) {
        for (value in list(NA, logical(), c(TRUE, FALSE), "yes", 1)) {
          args <- c(list(tibble(x = 1:3)), stats::setNames(list(value), argument))
          expect_error(do.call(api, args), "single.*TRUE.*FALSE")
        }
      }
    })

    test_that(paste(function_name, "multi-key missing groups follow the explicit removal flag"), {
      df <- tibble(a = c("x", NA, "x", "x"), b = c(1, 1, NA, 1),
                   x = c(1, 2, 3, NA_real_))
      out <- api(df, x, .by = c(a, b), .na.rm = TRUE,
                 .stat = c("n", "missing", "mean"))
      expect_equal(nrow(out), 1L)
      expect_equal(out$n, 1)
      expect_equal(out$missing, 1)
      expect_equal(out$mean, 1)
    })

    test_that(paste(function_name, "mixed calendars have the documented list and table shapes"), {
      df <- tibble(x = c(1, 3), d = as.Date("2024-01-01") + 0:1,
                   t = as.POSIXct("2024-01-01", tz = "UTC") + c(0, 3600))
      out <- suppressMessages(api(df, .stat = c("n", "mean")))
      expect_named(out, c("numeric", "date", "datetime"))
      expect_type(out$numeric$mean, "double")
      expect_type(out$date$mean, "character")
      table <- api(df, .mode = "table", .stat = c("n", "mean"))
      expect_type(table$n, "integer")
      expect_type(table$mean, "character")
      expect_equal(table$name, c("x", "d", "t"))
    })
  })
}

for (function_name in c("summ", "tabstat")) {
  local({
    api <- getExportedValue("statart", function_name)
    test_that(paste(function_name, "keeps character counts without parsing numeric-looking text"), {
      df <- tibble(x = c("1", "3", "3", NA_character_))
      expect_warning(out <- api(df, .keep_all = TRUE,
                                .stat = c("n", "unique", "missing", "mean", "sum")),
                     "non-numeric")
      expect_equal(out$name, "***x")
      expect_equal(out$n, 3)
      expect_equal(out$unique, 2)
      expect_equal(out$missing, 1)
      expect_true(is.na(out$mean))
      expect_true(is.na(out$sum))
      expect_identical(df$x, c("1", "3", "3", NA_character_))
    })
    test_that(paste(function_name, "keeps list-column counts and identities"), {
      df <- tibble(x = list(c(1, 2), c(1, 2), c(3, 4), NA))
      expect_warning(out <- api(df, .keep_all = TRUE, .detail = TRUE,
                                .stat = c("n", "unique", "missing", "mean", "sum")),
                     "non-numeric")
      expect_equal(out$n, 3)
      expect_equal(out$unique, 2)
      expect_equal(out$missing, 1)
      expect_true(is.na(out$mean))
      expect_true(is.na(out$sum))
      expect_identical(df$x[[1]], c(1, 2))
    })
    test_that(paste(function_name, "mixed nonnumeric columns keep missing statistics"), {
      df <- tibble(x = c(1, 3, 5), text = c("10", "20", "30"))
      expect_warning(out <- api(df, .keep_all = TRUE, .stat = "mean"), "non-numeric")
      expect_equal(out$name, c("x", "***text"))
      expect_equal(out$mean, c(3, NA_real_))
    })
    test_that(paste(function_name, "matrix columns fail with an actionable message"), {
      df <- tibble(x = matrix(1:6, nrow = 3))
      expect_error(api(df), "Matrix.*columns.*not supported")
    })
  })
}

for (function_name in c("summ", "tabstat")) {
  local({
    api <- getExportedValue("statart", function_name)
    test_that(paste(function_name, "warns when integer64 conversion loses precision"), {
      skip_if_not_installed("bit64")
      df <- tibble(x = bit64::as.integer64(c("9007199254740992", "9007199254740993")))
      expect_warning(out <- api(df, .stat = c("n", "unique", "mean")),
                     "precision lost")
      expect_equal(out$n, 2)
      expect_equal(out$unique, 2)
      expect_type(out$mean, "double")
    })
  })
}

for (function_name in c("summ", "tabstat")) {
  local({
    api <- getExportedValue("statart", function_name)
    test_that(paste(function_name, "mixed-type notice has no spurious suffix"), {
      expect_message(
        api(tibble(x = c(1, 3), d = as.Date("2024-01-01") + 0:1), .stat = "mean"),
        "heterogeneous[.][[:space:]]*$"
      )
    })
  })
}
