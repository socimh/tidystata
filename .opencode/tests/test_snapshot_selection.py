"""Exercise parsed snapshot selection, including unsafe and incomplete layouts."""
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / ".opencode/workflows"))
from r_process import r_command, r_environment


class SnapshotSelectionTests(unittest.TestCase):
    def test_parser_keeps_fixtures_and_selects_only_snapshot_blocks(self):
        script = r'''
source(commandArgs(trailingOnly = TRUE)[[1L]])
x <- parse(text = c(
  'fixture <- "expect_snapshot is only text"',
  '# expect_snapshot is only a comment',
  'test_that("behavior", { stop("must not run") })',
  'testthat::test_that("snapshot", { expect_snapshot(cat("hello")) })',
  'if (TRUE) test_that("nested", { testthat::expect_snapshot(error = TRUE, stop("x")) })'
))
selected <- select_snapshot_tests(as.list(x))
stopifnot(selected$count == 2L, identical(selected$expressions[[1L]], x[[1L]]),
          identical(selected$expressions[[2L]], quote(NULL)),
          identical(selected$expressions[[3L]], x[[3L]]))
for (text in c('expect_snapshot(cat("outside"))',
               'helper <- function() expect_snapshot(cat("hidden"))')) {
  result <- try(select_snapshot_tests(as.list(parse(text = text))), silent = TRUE)
  stopifnot(inherits(result, "try-error"))
}
# Auxiliary files are inspected as syntax without evaluating setup side effects.
for (name in c("helper.R", "setup.R", "teardown.R")) {
  path <- file.path(tempdir(), name)
  writeLines(c('stop("must not evaluate")',
               'helper <- function() testthat::expect_snapshot(cat("hidden"))'), path)
  result <- try(select_snapshot_tests(as.list(parse(path)), auxiliary = TRUE), silent = TRUE)
  stopifnot(inherits(result, "try-error"),
            grepl("auxiliary test files", as.character(result), fixed = TRUE))
}
safe_auxiliary <- parse(text = c('stop("must not evaluate")',
  'helper <- function() "expect_snapshot is only text"'))
stopifnot(select_snapshot_tests(as.list(safe_auxiliary), auxiliary = TRUE)$count == 0L)
null_fixture <- parse(text = 'fixture <- list(NULL, value = NULL, 3)')
stopifnot(identical(select_snapshot_tests(as.list(null_fixture))$expressions[[1L]],
                    null_fixture[[1L]]))
stopifnot(select_snapshot_tests(as.list(parse(text = 'test_that("plain", expect_true(TRUE))')))$count == 0L)
'''
        with tempfile.TemporaryDirectory() as temporary:
            path = Path(temporary) / "fixture.R"
            path.write_text(script, encoding="utf-8")
            result = subprocess.run(r_command(["Rscript", path,
                                    ROOT / ".opencode/workflows/select_snapshot_tests.R"]),
                                    env=r_environment(), capture_output=True, text=True,
                                    encoding="utf-8", errors="replace")
            self.assertEqual(result.returncode, 0, result.stdout + result.stderr)


if __name__ == "__main__":
    unittest.main()
