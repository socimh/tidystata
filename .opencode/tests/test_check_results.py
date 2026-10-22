"""Verify check-result semantics and the installed package test entry point."""
import csv
import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / ".opencode/workflows"))
from r_process import r_command, r_environment


def run_r(arguments, cwd=None):
    return subprocess.run(
        r_command(["Rscript", *map(str, arguments)]), cwd=cwd or ROOT,
        env=r_environment(libraries=[ROOT / ".opencode/tools/library"]),
        capture_output=True, text=True, encoding="utf-8", errors="replace",
    )


HEADER = (
    "* using log directory 'fixture.Rcheck'\n"
    "* using R version 4.6.0\n"
    "* using platform: x86_64-w64-mingw32\n"
    "* checking for file 'fixture/DESCRIPTION' ... OK\n"
    "* this is package 'fixture' version '0.0.1'\n"
)


class CheckResultTests(unittest.TestCase):
    def test_clean_note_warning_error_and_incomplete_results(self):
        cases = {
            "clean": (HEADER + "* DONE\nStatus: OK\n", 0, True, True, (0, 0, 0)),
            "note": (HEADER + "* checking incoming ... NOTE\nNew submission\n"
                     "* DONE\nStatus: 1 NOTE\n", 0, True, False, (0, 0, 1)),
            "warning": (HEADER + "* checking help ... WARNING\nUndocumented foo\n"
                        "* DONE\nStatus: 1 WARNING\n", 0, False, False, (0, 1, 0)),
            "error": (HEADER + "* checking install ... ERROR\nInstall failed\n"
                      "* DONE\nStatus: 1 ERROR\n", 1, False, False, (1, 0, 0)),
            "process": (HEADER + "* DONE\nStatus: OK\n", 1, False, False, (0, 0, 0)),
            "process_large": (HEADER + "* DONE\nStatus: OK\n", 3221225477,
                              False, False, (0, 0, 0)),
            "truncated": (HEADER, 0, False, False, (0, 0, 0)),
            "no_status": (HEADER + "* DONE\n", 0, False, False, (0, 0, 0)),
            "mismatch": (HEADER + "* DONE\nStatus: 1 WARNING\n",
                         0, False, False, (0, 0, 0)),
            "missing": (None, 0, False, False, (0, 0, 0)),
        }
        with tempfile.TemporaryDirectory(prefix="tidystata-check-parser-") as temporary:
            base = Path(temporary)
            for name, (text, native, passed, ready, counts) in cases.items():
                with self.subTest(name=name):
                    check = base / (name + ".log")
                    output = base / (name + ".json")
                    if text is not None:
                        check.write_text(text, encoding="utf-8")
                    result = run_r([
                        ROOT / ".opencode/workflows/parse_check_result.R",
                        check, native, output,
                    ])
                    self.assertEqual(result.returncode, 0 if passed else 1,
                                     result.stdout + result.stderr)
                    parsed = json.loads(output.read_text(encoding="utf-8"))
                    self.assertEqual(parsed["native_exit"], native)
                    self.assertEqual(parsed["verification_passed"], passed)
                    self.assertEqual(parsed["check_conditions_clear"], ready)
                    for key in ("errors", "warnings", "notes", "diagnostics"):
                        self.assertIsInstance(parsed[key], list)
                    self.assertEqual(tuple(parsed["counts"][key] for key in
                                           ("errors", "warnings", "notes")), counts)

    def test_real_native_check_warning_is_rejected_despite_exit_zero(self):
        with tempfile.TemporaryDirectory(prefix="tidystata-check-native-") as temporary:
            base = Path(temporary)
            package = base / "warningprobe"
            (package / "R").mkdir(parents=True)
            (package / "DESCRIPTION").write_text(
                "Package: warningprobe\nVersion: 0.0.1\n"
                "Title: Probe Check Warning Exit Status\n"
                "Description: A disposable probe of native check exit status.\n"
                "Author: Test Author\nMaintainer: Test Author <test@example.org>\n"
                "License: GPL-3\nEncoding: UTF-8\n", encoding="utf-8",
            )
            (package / "NAMESPACE").write_text("export(foo)\n", encoding="utf-8")
            (package / "R/foo.R").write_text("foo <- function() 1\n", encoding="utf-8")
            result = subprocess.run(
                r_command(["R", "CMD", "check", "--no-manual", "--no-tests",
                           "--no-examples", package]), cwd=base,
                env=r_environment(), capture_output=True, text=True,
                encoding="utf-8", errors="replace",
            )
            self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
            check = base / "warningprobe.Rcheck/00check.log"
            self.assertIn("WARNING", check.read_text(encoding="utf-8"))
            output = base / "result.json"
            parsed = run_r([ROOT / ".opencode/workflows/parse_check_result.R",
                            check, result.returncode, output])
            self.assertEqual(parsed.returncode, 1, parsed.stdout + parsed.stderr)
            data = json.loads(output.read_text(encoding="utf-8"))
            self.assertGreater(data["counts"]["warnings"], 0)
            self.assertFalse(data["verification_passed"])


class EntryPointTests(unittest.TestCase):
    def test_package_entry_accepts_expected_and_rejects_unexpected_warnings(self):
        with tempfile.TemporaryDirectory(prefix="tidystata-entry-warning-") as temporary:
            base = Path(temporary)
            (base / "testthat").mkdir()
            entry = ROOT / "tests/testthat.R"
            cases = {
                "expected": ('testthat::expect_warning(warning("fixture"), "fixture")', 0),
                "unexpected": ('warning("fixture"); testthat::expect_true(TRUE)', 1),
            }
            for name, (body, expected) in cases.items():
                with self.subTest(name=name):
                    (base / "testthat/test-fixture.R").write_text(
                        'testthat::test_that("fixture", {' + body + '})\n',
                        encoding="utf-8",
                    )
                    result = run_r([entry], cwd=base)
                    self.assertEqual(result.returncode, expected,
                                     result.stdout + result.stderr)


class ShuffleEvidenceTests(unittest.TestCase):
    def test_utf8_literals_and_names_match_normal_execution(self):
        with tempfile.TemporaryDirectory(prefix="tidystata-order-utf8-") as temporary:
            base = Path(temporary)
            package = base / "fixture"
            (package / "R").mkdir(parents=True)
            tests = package / "tests/testthat"
            (tests / "fixtures").mkdir(parents=True)
            (package / "DESCRIPTION").write_text(
                "Package: utf8fixture\nTitle: Unicode Fixture\nVersion: 0.0.1\n"
                "Description: A temporary Unicode transport fixture.\nLicense: GPL-3\n"
                "Authors@R: person('Test', 'Author', email='test@example.org', "
                "role=c('aut', 'cre'))\nEncoding: UTF-8\nConfig/testthat/edition: 3\n",
                encoding="utf-8",
            )
            (package / "NAMESPACE").write_text("", encoding="utf-8")
            values = ["\u20ac", "\u00a3", "\u00e9", "\u0627\u0644\u0639\u0631\u0628\u064a\u0629", "\u05e2\u05d1\u05e8\u05d9\u05ea"]
            (tests / "fixtures/utf8.txt").write_text("\n".join(values) + "\n", encoding="utf-8")
            literals = ", ".join(json.dumps(value, ensure_ascii=False) for value in values)
            (tests / "test-unicode.R").write_text(
                f'literals <- c({literals})\n'
                'expected <- readLines(testthat::test_path("fixtures", "utf8.txt"), '
                'encoding="UTF-8")\n'
                'testthat::test_that("UTF8 strings retain values, names and encodings", {\n'
                'testthat::expect_identical(literals, expected)\n'
                'testthat::expect_identical(Encoding(literals), Encoding(expected))\n'
                'testthat::expect_identical(names(stats::setNames(seq_along(literals), literals)), expected)\n'
                'testthat::expect_identical(readr::parse_number(c("\u20ac1,200.50", "\u20aa9.50", "\u00a33")), '
                'c(1200.5, 9.5, 3))\n})\n', encoding="utf-8",
            )
            fingerprints = []
            for mode, seed in (("normal", []), ("shuffled", ["20261017"])):
                prefix = base / mode
                result = run_r([ROOT / ".opencode/workflows/run_suite.R",
                                package, prefix, "", *seed])
                self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
                with Path(str(prefix) + ".csv").open(encoding="utf-8") as stream:
                    records = list(csv.DictReader(stream))
                self.assertEqual(len(records), 1)
                self.assertEqual(int(records[0]["passed"]), 4)
                metadata = json.loads(Path(str(prefix) + "-metadata.json").read_text(encoding="utf-8"))
                fingerprints.append(metadata["source_fingerprints"])
            self.assertEqual(fingerprints[0], fingerprints[1])

    def test_shuffled_order_and_seed_are_retained_and_reproducible(self):
        with tempfile.TemporaryDirectory(prefix="tidystata-order-evidence-") as temporary:
            base = Path(temporary)
            package = base / "fixture"
            (package / "R").mkdir(parents=True)
            tests = package / "tests/testthat"
            tests.mkdir(parents=True)
            (package / "DESCRIPTION").write_text(
                "Package: orderfixture\nTitle: Order Evidence Fixture\nVersion: 0.0.1\n"
                "Description: A temporary test execution order fixture.\nLicense: GPL-3\n"
                "Authors@R: person('Test', 'Author', email='test@example.org', "
                "role=c('aut', 'cre'))\nConfig/testthat/edition: 3\n",
                encoding="utf-8",
            )
            (package / "NAMESPACE").write_text("", encoding="utf-8")
            (tests / "helper-marker.R").write_text(
                'fixture_marker <- "helper loaded"\n', encoding="utf-8")
            (tests / "fixtures").mkdir()
            (tests / "fixtures/value.txt").write_text("fixture value\n", encoding="utf-8")
            for letter in "abcdefgh":
                (tests / ("test-" + letter + ".R")).write_text(
                    'setup_counter <- 1L\n'
                    f'testthat::test_that("{letter}-first", {{\n'
                    f'testthat::expect_identical(late_helper_{letter}(), "helper loaded")\n'
                    'testthat::expect_identical(readLines(testthat::test_path("fixtures", '
                    '"value.txt")), "fixture value")\n})\n'
                    'setup_counter <- setup_counter + 1L\n'
                    f'late_helper_{letter} <- function() fixture_marker\n'
                    'unused_factory <- function() {\n'
                    'testthat::test_that("must not register", stop("not invoked"))\n}\n'
                    'for (index in 1:2) local({\n'
                    f'testthat::test_that(paste("{letter}-loop", index), '
                    'testthat::expect_true(index %in% 1:2))\n})\n'
                    'local({\n'
                    f'testthat::test_that("{letter}-local", '
                    'testthat::expect_identical(setup_counter, 2L))\n})\n'
                    f'testthat::test_that("{letter}-last", '
                    'testthat::expect_identical(setup_counter, 2L))\n',
                    encoding="utf-8",
                )
            orders = []
            for run in ("first", "second"):
                prefix = base / run
                result = run_r([ROOT / ".opencode/workflows/run_suite.R",
                                package, prefix, "", "20261017"])
                self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
                metadata = json.loads(Path(str(prefix) + "-metadata.json").read_text(
                    encoding="utf-8"))
                self.assertTrue(metadata["shuffle"])
                self.assertEqual(metadata["seed"], 20261017)
                self.assertEqual(metadata["shuffle_scope"], ["files", "test_groups"])
                for filename, groups in metadata["test_group_order"].items():
                    self.assertEqual(groups["original_group_indices"], [2, 6, 7, 8])
                    self.assertEqual(groups["setup_indices"], [1, 3, 4, 5])
                    self.assertEqual(sorted(groups["permuted_group_indices"]), [2, 6, 7, 8])
                    self.assertEqual(groups["observed_test_blocks"], 5)
                self.assertIn("testthat", metadata["tool_versions"])
                self.assertIn("tests/testthat/test-a.R", metadata["source_fingerprints"])
                with Path(str(prefix) + "-order.csv").open(encoding="utf-8") as stream:
                    records = list(csv.DictReader(stream))
                self.assertEqual([int(x["execution_index"]) for x in records],
                                 list(range(1, 41)))
                with Path(str(prefix) + ".csv").open(encoding="utf-8") as stream:
                    results = list(csv.DictReader(stream))
                self.assertEqual(sum(int(row["passed"]) for row in results), 48)
                orders.append([x["file"] for x in records])
            self.assertEqual(orders[0], orders[1])
            self.assertNotEqual(orders[0], sorted(orders[0]))


if __name__ == "__main__":
    unittest.main()
