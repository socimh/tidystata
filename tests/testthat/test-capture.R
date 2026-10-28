test_that("capture preserves successful values and attributes", {
  values <- list(
    NULL,
    NA,
    Inf,
    NaN,
    TRUE,
    FALSE,
    "hello",
    "",
    1:3,
    tibble::tibble(x = 1:2, y = 3:4),
    list(a = 1, b = 2),
    structure("already failed", class = "try-error")
  )
  for (value in values) {
    expect_identical(capture(value), value)
    expect_identical(capture(value, quiet = TRUE), value)
  }
  expect_identical(capture(mean(1:10)), 5.5)
  expect_null(capture({}))
  expect_null(capture(NULL$nonexistent))
  expect_false(capture(exists("fake_function_xyz", mode = "function")))
  expect_identical(capture(loadNamespace("dplyr")), asNamespace("dplyr"))
})

test_that("capture preserves visibility and returns invisible NULL on error", {
  for (quiet in c(FALSE, TRUE)) {
    expect_identical(
      withVisible(capture(42, quiet = quiet)),
      list(value = 42, visible = TRUE)
    )
    expect_identical(
      withVisible(capture(NULL, quiet = quiet)),
      list(value = NULL, visible = TRUE)
    )
    expect_identical(
      withVisible(capture(invisible(42), quiet = quiet)),
      list(value = 42, visible = FALSE)
    )
    expect_identical(
      withVisible(capture(invisible(NULL), quiet = quiet)),
      list(value = NULL, visible = FALSE)
    )
    expect_identical(
      withVisible(capture(stop("failure"), quiet = quiet)),
      list(value = NULL, visible = FALSE)
    )
  }
})

test_that("capture evaluates once in the caller and preserves earlier effects", {
  calls <- 0L
  result <- capture({
    calls <- calls + 1L
    x <- 1:10
    mean(x^2)
  })
  expect_identical(calls, 1L)
  expect_identical(x, 1:10)
  expect_identical(result, 38.5)
  expect_null(capture({
    calls <- calls + 1L
    stop("failure")
    calls <- calls + 100L
  }))
  expect_identical(calls, 2L)
  expect_identical(
    withVisible(capture(assigned <- 3L)),
    list(value = 3L, visible = FALSE)
  )
  expect_identical(assigned, 3L)
  expect_identical(capture(capture(mean(x))), 5.5)
  expect_identical(
    capture({
      capture(stop("inner failure"))
      7L
    }),
    7L
  )
})

test_that("capture returns pipeline, model and file-reading results", {
  data <- tibble::tibble(x = 1:5, y = 6:10)
  expect_identical(
    capture(data |> dplyr::summarise(total = sum(x))),
    tibble::tibble(total = 15L)
  )
  model <- lm(mpg ~ wt, data = mtcars)
  expect_equal(capture(lm(mpg ~ wt, data = mtcars)), model)
  expect_identical(
    capture(summary(lm(mpg ~ wt, data = mtcars))$r.squared),
    summary(model)$r.squared
  )
  expect_null(capture(lm(nonexistent ~ wt, data = mtcars)))
  expect_equal(
    capture(utils::read.csv(text = "a,b\n1,2\n3,4")),
    data.frame(a = c(1L, 3L), b = c(2L, 4L))
  )
  expect_warning(
    expect_null(capture(utils::read.csv(tempfile("missing-capture-")))),
    "cannot open file"
  )
})

test_that("capture returns ggplot objects unchanged", {
  skip_if_not_installed("ggplot2")
  plot <- ggplot2::ggplot(mtcars, ggplot2::aes(x = wt, y = mpg)) +
    ggplot2::geom_point()
  expect_identical(capture(plot), plot)
})

test_that("capture reports caught errors as messages rather than warnings", {
  expect_null(capture(nonexistent_function(1:10)))
  expect_null(capture(eval(quote(stop("delayed failure")))))
  expect_null(capture(parse(text = "1 +")))
  expect_output(capture(stop("do not print")), NA)
  expect_message(
    capture(stop("failed calculation")),
    "Captured expression did not complete"
  )
  expect_warning(capture(stop("do not print")), NA)
  missing_package <- function() {
    stop(errorCondition("unavailable", class = "packageNotFoundError"))
  }
  expect_null(capture(missing_package()))
})

test_that("capture preserves warnings and messages by default", {
  warnings <- messages <- character()
  result <- withCallingHandlers(
    capture({
      warning("first warning")
      message("kept message")
      warning("second warning")
      FALSE
    }),
    warning = function(w) {
      warnings <<- c(warnings, conditionMessage(w))
      invokeRestart("muffleWarning")
    },
    message = function(m) {
      messages <<- c(messages, conditionMessage(m))
      invokeRestart("muffleMessage")
    }
  )
  expect_false(result)
  expect_identical(warnings, c("first warning", "second warning"))
  expect_identical(messages, "kept message\n")
  expect_warning(
    expect_true(is.na(capture(mean("not numeric")))),
    "not numeric"
  )
  data <- tibble::tibble(x = 1:2)
  expect_warning(
    expect_null(capture(data$y)),
    "Unknown or uninitialised column"
  )
})

test_that("quiet muffles diagnostics without aborting evaluation", {
  expect_no_warning(expect_no_message(
    result <- capture(
      {
        warning("hidden warning")
        message("hidden message")
        42L
      },
      quiet = TRUE
    )
  ))
  expect_identical(result, 42L)
  for (quiet in c(FALSE, TRUE)) {
    warnings <- messages <- character()
    result <- withCallingHandlers(
      capture(
        {
          warning("before failure")
          message("before failure")
          stop("failure")
        },
        quiet = quiet
      ),
      warning = function(w) {
        warnings <<- c(warnings, conditionMessage(w))
        invokeRestart("muffleWarning")
      },
      message = function(m) {
        messages <<- c(messages, conditionMessage(m))
        invokeRestart("muffleMessage")
      }
    )
    expect_null(result)
    expect_identical(warnings, if (quiet) character() else "before failure")
    if (quiet) {
      expect_identical(messages, character())
    } else {
      expect_length(messages, 2L)
      expect_identical(messages[[1L]], "before failure\n")
      expect_match(messages[[2L]], "Captured expression did not complete")
    }
  }
})

test_that("capture gives one failure notice with the cause and partial-effect caveat", {
  messages <- character()
  result <- withCallingHandlers(
    withVisible(capture(stop("missing {score}"))),
    message = function(m) {
      messages <<- c(messages, conditionMessage(m))
      invokeRestart("muffleMessage")
    }
  )
  expect_identical(result, list(value = NULL, visible = FALSE))
  expect_length(messages, 1L)
  expect_match(messages, "Captured expression did not complete.", fixed = TRUE)
  expect_match(messages, "missing {score}", fixed = TRUE)
  expect_match(
    messages,
    "Earlier changes, if any, were not undone.",
    fixed = TRUE
  )
  expect_no_message(capture(stop("hidden failure"), quiet = TRUE))
  expect_no_message(capture(FALSE))
  expect_no_message(capture(NULL))
})

test_that("capture keeps the call and bullets of the original error", {
  fail_with_bullets <- function() {
    cli::cli_abort(c("Can't compute.", x = "Column not found."))
  }
  message <- testthat::capture_messages(capture(fail_with_bullets()))
  expect_length(message, 1L)
  expect_match(message, "fail_with_bullets()", fixed = TRUE)
  expect_match(message, "Can't compute.\n", fixed = TRUE)
  expect_match(message, "Column not found.", fixed = TRUE)
  message <- testthat::capture_messages(capture(stop("plain failure")))
  expect_no_match(message, "doTryCatch", fixed = TRUE)
  expect_match(message, "plain failure", fixed = TRUE)
})

test_that("nested captures report a failure once and respect quiet", {
  messages <- testthat::capture_messages(capture(capture(stop(
    "inner failure"
  ))))
  expect_length(messages, 1L)
  expect_match(messages, "inner failure", fixed = TRUE)
  expect_no_message(capture(capture(stop("inner failure"), quiet = TRUE)))
  expect_no_message(capture(capture(stop("inner failure")), quiet = TRUE))
})

test_that("captured assignments preserve existing data on failure", {
  original <- tibble::tibble(x = 1:3)
  data <- original
  expect_message(capture(data <- stop("failed update")), "failed update")
  expect_identical(data, original)
  expect_no_message(capture(data <- dplyr::mutate(data, y = x * 2L)))
  expect_identical(data, tibble::tibble(x = 1:3, y = c(2L, 4L, 6L)))
  expect_message(
    result <- capture(stop("new result failed")),
    "new result failed"
  )
  expect_null(result)
  expect_message(
    data <- capture(stop("replacement failed")),
    "replacement failed"
  )
  expect_null(data)
  data <- original
  expect_no_message(capture(data <- NULL))
  expect_null(data)
})

test_that("captured blocks keep completed updates and skip later steps", {
  original <- tibble::tibble(x = 1:3)
  data <- original
  calls <- 0L
  expect_message(
    capture({
      data <- dplyr::mutate(data, y = x * 2L)
      data <- stop("second step failed")
      calls <- calls + 1L
      data <- dplyr::mutate(data, z = x + 1L)
    }),
    "second step failed"
  )
  expect_identical(data, tibble::tibble(x = 1:3, y = c(2L, 4L, 6L)))
  expect_identical(calls, 0L)
  data <- original
  fail <- function(x) stop("pipeline failed")
  expect_message(
    capture(data <- data |> dplyr::mutate(y = x * 2L) |> fail()),
    "pipeline failed"
  )
  expect_identical(data, original)
})

test_that("capture failure notices do not become errors under warn = 2", {
  withr::local_options(warn = 2)
  expect_message(
    result <- withVisible(capture(stop("failed calculation"))),
    "failed calculation"
  )
  expect_identical(result, list(value = NULL, visible = FALSE))
  expect_no_message(capture(stop("hidden failure"), quiet = TRUE))
})

test_that("capture preserves explicit output even before failure", {
  for (quiet in c(FALSE, TRUE)) {
    expect_output(
      expect_identical(
        capture(
          {
            cat("kept")
            42L
          },
          quiet = quiet
        ),
        42L
      ),
      "kept"
    )
    expect_output(
      expect_null(capture(
        {
          print("kept")
          stop("failure")
        },
        quiet = quiet
      )),
      "kept"
    )
  }
})

test_that("capture validates quiet before evaluating the expression", {
  calls <- 0L
  for (bad in list(NULL, NA, 1, "TRUE", logical(), c(TRUE, FALSE))) {
    expect_error(
      capture(
        {
          calls <- calls + 1L
        },
        quiet = bad
      ),
      "quiet"
    )
  }
  expect_identical(calls, 0L)
})

test_that("capture respects warning escalation and does not catch interrupts", {
  withr::local_options(warn = 2)
  expect_null(capture({
    warning("escalated")
    42L
  }))
  expect_identical(
    capture(
      {
        warning("muffled")
        42L
      },
      quiet = TRUE
    ),
    42L
  )
  interrupt <- structure(
    list(message = "interrupted", call = NULL),
    class = c("interrupt", "condition")
  )
  for (quiet in c(FALSE, TRUE)) {
    caught <- tryCatch(
      capture(signalCondition(interrupt), quiet = quiet),
      interrupt = identity
    )
    expect_identical(caught, interrupt)
  }
})
