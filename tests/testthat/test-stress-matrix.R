# Every registered export meets the same contract on every adversarial column
# class, container and shape: it returns or fails with a package-level error,
# emits no leaked base-R/vctrs condition, leaves its input unchanged and, for
# mutate() helpers, returns one value per row. Correct values are covered by
# the family tests and test-stress-invariants.R.
#
# Cells per tier (stress_tier()): CRAN runs core classes on regular tibbles;
# ordinary runs add every class, zero-row/all-missing shapes and grouped or
# data.table containers; TIDYSTATA_STRESS=full adds the remaining
# containers and shapes.

registry <- stress_registry()
columns <- stress_columns()
containers <- stress_containers()
cells <- stress_cells(registry, columns, containers)

for (fn in names(registry)) {
  local({
    fn_cells <- cells[cells$fn == fn, , drop = FALSE]
    entry <- registry[[fn]]
    test_that(paste("stress matrix:", fn, "meets the cell contract"), {
      skip_if(nrow(fn_cells) == 0L, "no applicable cells in this tier")
      for (i in seq_len(nrow(fn_cells))) {
        cell <- fn_cells[i, ]
        label <- sprintf(
          "%s on %s / %s / %s",
          fn,
          cell$class,
          cell$container,
          cell$shape
        )
        d <- containers[[cell$container]](
          stress_frame(columns[[cell$class]], cell$shape)
        )
        before <- stress_copy(d)
        result <- stress_run(function() entry$call(d))
        outcome <- stress_outcome(result)
        expect(
          !outcome$kind %in% c("internal_error", "base_error"),
          sprintf("%s: unchecked error\n%s", label, outcome$message)
        )
        leaked <- outcome$warning_messages[
          !outcome$warning_kinds %in% "warning" &
            !stress_allowed_warning(outcome$warning_messages)
        ]
        expect(
          length(leaked) == 0L,
          sprintf(
            "%s: leaked warning\n%s",
            label,
            paste(leaked, collapse = "\n")
          )
        )
        expect(
          identical(d, before),
          sprintf("%s: input modified", label)
        )
        if (identical(entry$kind, "vector") && identical(outcome$kind, "ok")) {
          expect(
            length(result$value) == nrow(d),
            sprintf(
              "%s: %d values for %d rows",
              label,
              length(result$value),
              nrow(d)
            )
          )
        }
      }
    })
  })
}

test_that("stress matrix covers every exported function or records why not", {
  exports <- setdiff(getNamespaceExports("tidystata"), "%>%")
  covered <- unique(c(
    unlist(lapply(registry, function(entry) entry$export)),
    names(stress_unregistered_exports)
  ))
  expect_setequal(intersect(exports, covered), exports)
  expect_length(setdiff(covered, exports), 0L)
})

test_that("stress matrix aliases are their primary functions", {
  for (alias in names(stress_aliases)) {
    expect_identical(
      getExportedValue("tidystata", alias),
      getExportedValue("tidystata", stress_aliases[[alias]]),
      label = alias
    )
  }
})

# Regressions for defects the matrix found (S-001 to S-008; S-005 was a
# documented contract, see test-type-conversion-contracts.R). New confirmed
# defects go in stress_known_issues with a stress_skip_known() block here.

test_that("S-001 as_dummy() expands ordered factors", {
  x <- factor(
    c("lo", "hi", NA, "lo"),
    levels = c("lo", "mid", "hi"),
    ordered = TRUE
  )
  out <- as_dummy(tibble::tibble(x = x), x)
  expect_identical(out$x_lo, c(1L, 0L, NA, 1L), ignore_attr = TRUE)
  expect_identical(out$x_hi, c(0L, 1L, NA, 0L), ignore_attr = TRUE)
  expect_false("x_mid" %in% names(out))
  expect_identical(attr(out$x_hi, "label"), "x==hi")
})

test_that("S-002 cut_length() rejects non-finite or empty input clearly", {
  expect_error(
    cut_length(c(1, Inf, 3, 4), 3),
    "only finite values",
    class = "rlang_error"
  )
  expect_error(
    cut_length(c(1, NaN, -Inf, 4), 2),
    "only finite values",
    class = "rlang_error"
  )
  expect_no_warning(
    expect_error(
      cut_length(numeric(0), 3),
      "non-missing",
      class = "rlang_error"
    )
  )
  expect_identical(
    as.integer(cut_length(c(1, NaN, 3, 5), 2)),
    c(1L, NA, 2L, 2L)
  )
})

test_that("S-003 cut_breaks() handles empty input without base warnings", {
  expect_no_warning(out <- cut_breaks(numeric(0), breaks = c(0, 2)))
  expect_identical(levels(out), c("[-Inf,0)", "[0,2)", "[2, Inf]"))
  expect_length(out, 0L)
})

test_that("S-004 missing-value conversions report a value type mismatch", {
  cases <- list(
    list(quote(mvdecode(c("a", "b"), 1)), "mv"),
    list(quote(mvencode(c("a", NA), 0)), "mv"),
    list(quote(na_if_value(c("a", "b"), 1)), "value"),
    list(quote(value_if_na(c("a", NA), 0)), "value")
  )
  for (case in cases) {
    cnd <- tryCatch(eval(case[[1]]), error = identity)
    expect_s3_class(cnd, "rlang_error")
    expect_match(
      rlang::cnd_header(cnd),
      paste0("`", case[[2]], "` must have a type compatible with `x`"),
      fixed = TRUE
    )
    expect_identical(as.character(cnd$call[[1]]), as.character(case[[1]][[1]]))
    expect_false(grepl("`y`", conditionMessage(cnd), fixed = TRUE))
  }
  # Compatible values and inputs without missing values are unchanged.
  expect_identical(mvdecode(c(1, 2, 1), 1), c(NA, 2, NA))
  expect_identical(mvencode(c("a", "b"), 0), c("a", "b"))
  expect_identical(value_if_na(c("a", NA), "z"), c("a", "z"))
})

test_that("S-008 data-frame functions reject non-data-frame tables alike", {
  # A dependency-free stand-in for a dbplyr lazy table.
  lazy <- structure(
    list(src = list(), lazy_query = list()),
    class = c("tbl_lazy", "tbl")
  )
  calls <- list(
    quote(tab(lazy, x)),
    quote(tab2(lazy, x, y)),
    quote(fre2(lazy, x, y)),
    quote(summ(lazy, x)),
    quote(tabstat(lazy, x)),
    quote(codebook(lazy, x)),
    quote(browse(lazy, x)),
    quote(ds(lazy)),
    quote(variables(lazy)),
    quote(variables_search(lazy, "x")),
    quote(select_or_transmute(lazy, x)),
    quote(misstable(lazy, x)),
    quote(corr(lazy, x, y))
  )
  for (call in calls) {
    cnd <- tryCatch(eval(call), error = identity)
    expect_s3_class(cnd, "rlang_error")
    expect_match(
      conditionMessage(cnd),
      "`.data` must be a data frame.*not a <tbl_lazy> object",
      label = deparse(call)
    )
  }
})
