test_that("s_select forces its data promise once and preserves selected attributes", {
  calls <- 0L
  x <- structure(1:3, label = "Observed score")
  data <- tibble::tibble(x = x, y = 4:6)
  out <- s_select(
    {
      calls <- calls + 1L
      data
    },
    x
  )
  expect_identical(calls, 1L)
  expect_identical(out$x, x)
  expect_identical(data, tibble::tibble(x = x, y = 4:6))
})

test_that("s_select no-argument return preserves grouping and object identity", {
  data <- dplyr::group_by(tibble::tibble(g = c("a", "b"), x = 1:2), g)
  out <- withVisible(s_select(data))
  expect_identical(out$value, data)
  expect_true(out$visible)
  expect_identical(s_select(data, tidyselect::everything()), data)
})

test_that("s_select evaluates selection predicates once per column", {
  calls <- 0L
  predicate <- function(x) {
    calls <<- calls + 1L
    is.numeric(x)
  }
  data <- tibble::tibble(x = 1:2, y = c("a", "b"), z = c(TRUE, FALSE))
  expect_identical(s_select(data, tidyselect::where(predicate)), data["x"])
  expect_identical(calls, 3L)
})

test_that("s_select preserves successful warning conditions and their order", {
  first <- structure(
    list(message = "first selector warning", call = NULL),
    class = c("selector_warning", "warning", "condition")
  )
  second <- simpleWarning("second selector warning")
  choose <- function() {
    warning(first)
    warning(second)
    "x"
  }
  observed <- list()
  out <- withCallingHandlers(
    s_select(tibble::tibble(x = 1:2), tidyselect::all_of(choose())),
    warning = function(w) {
      observed[[length(observed) + 1L]] <<- w
      invokeRestart("muffleWarning")
    }
  )
  expect_identical(observed, list(first, second))
  expect_identical(out, tibble::tibble(x = 1:2))
})

test_that("s_select reports both failed branches without replaying their warnings", {
  compute <- function() {
    warning("discarded branch warning")
    stop("branch failure")
  }
  observed <- character()
  err <- withCallingHandlers(
    tryCatch(s_select(tibble::tibble(x = 1:2), compute()), error = identity),
    warning = function(w) {
      observed <<- c(observed, conditionMessage(w))
      invokeRestart("muffleWarning")
    }
  )
  expect_length(observed, 0L)
  expect_s3_class(err, "error")
  expect_match(conditionMessage(err), "select\\(\\) error:")
  expect_match(conditionMessage(err), "mutate\\(\\) error:")
  expect_match(conditionMessage(err), "branch failure", fixed = TRUE)
})

test_that("s_match returns positions with explicit variables and keeps matching boundaries", {
  vars <- c("x1", "x2", "x10", "prefix_x1", "X1", "xa", "xb")
  expect_identical(s_match("x[1-2]", vars = vars), c(1L, 2L, 5L))
  expect_identical(s_match("x1", ignore.case = FALSE, vars = vars), 1L)
  expect_identical(s_match("x[a-b]", vars = vars), c(6L, 7L))
  expect_identical(s_match("absent*", vars = vars), integer())
  expect_error(s_match("x[2-1]", vars = vars), "smaller number")
  expect_error(s_match("x[1-2][3-4]", vars = vars), "Only one range")
})

test_that("s_type and s_unit preserve labelled and duration metadata", {
  labelled <- haven::labelled(
    c(1, NA, 2),
    labels = c(Yes = 1, No = 2),
    label = "Answer"
  )
  duration <- as.difftime(c(1, NA, 2), units = "hours")
  before <- list(labelled, duration)
  expect_identical(s_type(labelled, .abbr = TRUE), "dbl+lbl")
  expect_identical(s_type(labelled), "double+label")
  expect_identical(s_unit(labelled), NA_character_)
  expect_identical(s_type(duration), "duration")
  expect_identical(s_unit(duration), "hours")
  expect_identical(list(labelled, duration), before)
})

test_that("s_type returns visible type names for empty and named vectors", {
  expect_identical(s_type(integer()), "integer")
  expect_identical(s_type(setNames(c(1, NA), c("a", "b"))), "double")
  expect_identical(s_unit(integer()), NA_character_)
  expect_identical(
    withVisible(s_type(integer())),
    list(value = "integer", visible = TRUE)
  )
})

test_that("timer evaluates its promise once and returns the exact object invisibly", {
  calls <- 0L
  value <- structure(list(x = 1:2), class = "timed_result", note = "preserved")
  expect_message(
    out <- withVisible(timer({
      calls <- calls + 1L
      value
    })),
    "^Time spent: "
  )
  expect_identical(calls, 1L)
  expect_identical(out, list(value = value, visible = FALSE))
})

test_that("timer propagates the original error and emits no completion message", {
  condition <- structure(
    list(message = "timed failure", call = NULL),
    class = c("timed_error", "error", "condition")
  )
  messages <- character()
  err <- withCallingHandlers(
    tryCatch(timer(stop(condition)), error = identity),
    message = function(m) {
      messages <<- c(messages, conditionMessage(m))
      invokeRestart("muffleMessage")
    }
  )
  expect_identical(err, condition)
  expect_length(messages, 0L)
})

test_that("set_seed seeds before evaluation and leaves the advanced global RNG state", {
  local({
    old <- get0(".Random.seed", envir = .GlobalEnv, inherits = FALSE)
    on.exit(
      if (is.null(old)) {
        rm(".Random.seed", envir = .GlobalEnv)
      } else {
        assign(".Random.seed", old, envir = .GlobalEnv)
      }
    )
    set.seed(419)
    expected <- stats::runif(3)
    expected_state <- .Random.seed
    expected_next <- stats::runif(1)
    calls <- 0L
    out <- set_seed(
      {
        calls <- calls + 1L
        stats::runif(3)
      },
      419
    )
    expect_identical(calls, 1L)
    expect_identical(out, expected)
    expect_identical(.Random.seed, expected_state)
    expect_identical(stats::runif(1), expected_next)
  })
})

test_that("set_seed keeps RNG effects when the expression fails", {
  local({
    old <- get0(".Random.seed", envir = .GlobalEnv, inherits = FALSE)
    on.exit(
      if (is.null(old)) {
        rm(".Random.seed", envir = .GlobalEnv)
      } else {
        assign(".Random.seed", old, envir = .GlobalEnv)
      }
    )
    set.seed(117)
    stats::runif(2)
    expected_state <- .Random.seed
    expect_error(
      set_seed(
        {
          stats::runif(2)
          stop("seeded failure")
        },
        117
      ),
      "seeded failure"
    )
    expect_identical(.Random.seed, expected_state)
  })
})

test_that("set_seed preserves result attributes and invisible expressions", {
  local({
    old <- get0(".Random.seed", envir = .GlobalEnv, inherits = FALSE)
    on.exit(
      if (is.null(old)) {
        rm(".Random.seed", envir = .GlobalEnv)
      } else {
        assign(".Random.seed", old, envir = .GlobalEnv)
      }
    )
    value <- structure(1:2, label = "Seeded result")
    expect_identical(
      withVisible(set_seed(invisible(value), 1)),
      list(value = value, visible = FALSE)
    )
  })
})

test_that("s_try evaluates once and preserves warnings and messages", {
  calls <- 0L
  warnings <- character()
  messages <- character()
  out <- withCallingHandlers(
    s_try({
      calls <- calls + 1L
      warning("kept warning")
      message("kept message")
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
  expect_identical(calls, 1L)
  expect_true(out)
  expect_identical(warnings, "kept warning")
  expect_identical(messages, "kept message\n")
})

test_that("s_try preserves the existing try-error classification and visible result", {
  value <- structure("already failed", class = "try-error")
  expect_false(s_try(value))
  expect_false(s_try(stop("new failure")))
  expect_identical(
    withVisible(s_try(invisible(NULL))),
    list(value = TRUE, visible = TRUE)
  )
})


test_that("s_select preserves RNG consumption across a failed selection and fallback", {
  local({
    old <- get0(".Random.seed", envir = .GlobalEnv, inherits = FALSE)
    on.exit(
      if (is.null(old)) {
        rm(".Random.seed", envir = .GlobalEnv)
      } else {
        assign(".Random.seed", old, envir = .GlobalEnv)
      }
    )
    set.seed(731)
    stats::runif(2)
    expected_state <- .Random.seed
    set.seed(731)
    calls <- 0L
    compute <- function(x) {
      calls <<- calls + 1L
      stats::runif(1)
      force(x)
      x * 2
    }
    out <- s_select(tibble::tibble(x = 1:3), z = compute(x))
    expect_identical(out, tibble::tibble(z = c(2, 4, 6)))
    expect_identical(calls, 2L)
    expect_identical(.Random.seed, expected_state)
  })
})

test_that("set_seed rejects an invalid seed before forcing the expression", {
  calls <- 0L
  expect_error(
    set_seed(
      {
        calls <- calls + 1L
        1
      },
      NA_integer_
    ),
    "not a valid integer"
  )
  expect_identical(calls, 0L)
})
