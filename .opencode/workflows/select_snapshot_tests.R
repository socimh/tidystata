# Select snapshot-bearing test calls without changing fixture or file identities.
select_snapshot_tests <- function(expressions, auxiliary = FALSE) {
  count <- 0L
  call_name <- function(x) {
    if (is.symbol(x)) {
      return(as.character(x))
    }
    if (is.call(x) && identical(x[[1L]], as.name("::"))) {
      return(as.character(x[[3L]]))
    }
    ""
  }
  has_snapshot <- function(x) {
    if (missing(x) || !is.call(x)) {
      return(FALSE)
    }
    if (grepl("^expect_snapshot", call_name(x[[1L]]))) {
      return(TRUE)
    }
    any(vapply(as.list(x)[-1L], has_snapshot, logical(1)))
  }
  if (auxiliary && any(vapply(expressions, has_snapshot, logical(1)))) {
    stop(
      "Snapshot expectations in auxiliary test files cannot be selected safely."
    )
  }
  visit <- function(x) {
    if (!is.call(x)) {
      return(x)
    }
    name <- call_name(x[[1L]])
    if (name == "test_that") {
      if (!has_snapshot(x)) {
        return(quote(NULL))
      }
      count <<- count + 1L
      return(x)
    }
    if (name == "function" && has_snapshot(x)) {
      stop("Snapshot calls in helper functions cannot be selected safely.")
    }
    if (grepl("^expect_snapshot", name)) {
      stop("Snapshot expectation outside test_that cannot be selected safely.")
    }
    for (i in seq_along(x)[-1L]) {
      if (!identical(x[[i]], quote(expr = ))) x[i] <- list(visit(x[[i]]))
    }
    x
  }
  list(expressions = lapply(expressions, visit), count = count)
}
