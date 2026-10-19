# Historical summary suites pin the layout used before the PROBLEMS2 defaults
# changed: an explicit `name` column and first-appearance group order. They
# call the API through this wrapper so their statistical checks are unchanged;
# the current defaults (`.name = FALSE`, `.sort = TRUE`) have their own tests.
summary_legacy_layout <- function(fn) {
  force(fn)
  function(...) {
    call <- sys.call()
    call[[1L]] <- fn
    if (!".name" %in% names(call)) {
      call$.name <- TRUE
    }
    if (!".sort" %in% names(call)) {
      call$.sort <- FALSE
    }
    eval(call, parent.frame())
  }
}
