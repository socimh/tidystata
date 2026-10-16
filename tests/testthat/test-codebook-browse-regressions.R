test_that("codebook inventories grouped data globally without modifying grouping", {
  d <- dplyr::group_by(tibble::tibble(g = c("a", "a", "b"), x = c(1, NA, 2)), g)
  before <- d
  out <- codebook(d)
  expect_identical(out$variable, c("g", "x"))
  expect_identical(out$n, c(3L, 2L))
  expect_identical(out$unique, c(2L, 2L))
  expect_identical(codebook(d, x)$variable, "x")
  expect_identical(d, before)
})
test_that("codebook excludes SPSS user missing values from unique counts", {
  d <- tibble::tibble(x = haven::labelled_spss(c(1, 1, 99, NA), na_values = 99))
  before <- d
  out <- codebook(d)
  expect_identical(out$n, 2L)
  expect_identical(out$unique, 1L)
  expect_identical(d, before)
})
test_that("codebook structured columns count complete rows rather than cells", {
  m <- matrix(c(1, 1, 2, 2, NA, 2, 2, 2), ncol = 2, byrow = TRUE)
  # Three complete rows: (1,1), (2,2), (2,2); one incomplete row.
  d <- tibble::tibble(m = m, nested = as.data.frame(m))
  before <- d
  out <- codebook(d)
  expect_identical(out$n, c(3L, 3L))
  expect_identical(out$unique, c(2L, 2L))
  expect_identical(d, before)
})
for (.name in c("codebook", "browse", "s_select")) {
  local({
    fn_name <- .name
    test_that(paste(fn_name, "does not evaluate an unused transmute branch"), {
      calls <- new.env(parent = emptyenv())
      calls$n <- 0L
      choose <- function() {
        calls$n <- calls$n + 1L
        "x"
      }
      d <- tibble::tibble(x = 1:3, y = 4:6)
      fn <- getExportedValue("statart", fn_name)
      out <- fn(d, tidyselect::all_of(choose()))
      expect_identical(calls$n, 1L)
      expect_true(
        if (fn_name == "codebook") {
          identical(out$variable, "x")
        } else {
          identical(names(out), "x")
        }
      )
    })
  })
}

for (.bad_names in list(c("same", "same"), c("a", ""), c("a", NA_character_))) {
  local({
    bad_names <- .bad_names
    test_that(
      paste(
        "codebook rejects ambiguous names",
        paste(bad_names, collapse = "/")
      ),
      {
        d <- data.frame(a = 1:2, b = 3:4)
        names(d) <- bad_names
        before <- serialize(d, NULL)
        expect_error(codebook(d), "unique|duplicat|empty|missing|NA")
        expect_identical(serialize(d, NULL), before)
      }
    )
  })
}
test_that("s_select emits successful selector warnings exactly once", {
  d <- tibble::tibble(x = 1:3, y = 4:6)
  choose <- function() {
    warning("successful-selector-warning")
    "x"
  }
  warnings <- character()
  out <- withCallingHandlers(
    s_select(d, tidyselect::all_of(choose())),
    warning = function(w) {
      warnings <<- c(warnings, conditionMessage(w))
      invokeRestart("muffleWarning")
    }
  )
  expect_identical(warnings, "successful-selector-warning")
  expect_identical(out, d["x"])
})
test_that("s_select discards failed-probe warnings and retains successful fallback warning", {
  d <- tibble::tibble(x = 1:3)
  compute <- function(x) {
    warning("branch-warning")
    force(x)
    x * 2
  }
  warnings <- character()
  out <- withCallingHandlers(
    s_select(d, z = compute(x)),
    warning = function(w) {
      warnings <<- c(warnings, conditionMessage(w))
      invokeRestart("muffleWarning")
    }
  )
  expect_length(warnings, 1L)
  expect_match(warnings, "branch-warning", fixed = TRUE)
  expect_identical(out, tibble::tibble(z = c(2, 4, 6)))
})
test_that("s_select retains documented select-first side-effect boundary", {
  d <- tibble::tibble(x = 1:3)
  state <- new.env()
  state$n <- 0L
  compute <- function(x) {
    state$n <- state$n + 1L
    force(x)
    x * 2
  }
  out <- s_select(d, z = compute(x))
  # The failing selection attempt can run code; the fallback runs only once.
  expect_identical(state$n, 2L)
  expect_identical(out, tibble::tibble(z = c(2, 4, 6)))
})
