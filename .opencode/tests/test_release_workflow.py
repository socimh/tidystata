"""Guard release mode selection before any builds or filesystem effects."""
import contextlib
import io
import itertools
from pathlib import Path
import sys
import subprocess
import tempfile
import unittest

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "workflows"))
import verify_package


class ModeTests(unittest.TestCase):
    def test_cli_rejects_conflicts_without_creating_output(self):
        with tempfile.TemporaryDirectory(prefix="statart-invalid-mode-") as temporary:
            prefix = Path(temporary) / "untouched" / "result"
            result = subprocess.run(
                [sys.executable, verify_package.__file__, "--release", "--minimal",
                 "--prefix", str(prefix)], capture_output=True, text=True,
                encoding="utf-8", errors="replace",
            )
            self.assertEqual(result.returncode, 2, result.stdout + result.stderr)
            self.assertFalse(prefix.parent.exists())

    def test_modes_are_mutually_exclusive(self):
        for first, second in itertools.combinations(
            ["--check", "--release", "--minimal", "--demos"], 2
        ):
            with self.subTest(first=first, second=second):
                with contextlib.redirect_stderr(io.StringIO()):
                    with self.assertRaises(SystemExit) as error:
                        verify_package.parse_options([first, second])
                self.assertEqual(error.exception.code, 2)

    def test_full_modes_reject_filters_and_partial_order_runs(self):
        for mode in ["--check", "--release", "--minimal", "--demos"]:
            for selection in [["--filter", "summ"], ["--shuffle-seed", "20261017"]]:
                with self.subTest(mode=mode, selection=selection):
                    with contextlib.redirect_stderr(io.StringIO()):
                        with self.assertRaises(SystemExit) as error:
                            verify_package.parse_options([mode, *selection])
                    self.assertEqual(error.exception.code, 2)

    def test_ordinary_test_mode_accepts_filter_and_seed(self):
        options = verify_package.parse_options(
            ["--filter", "summ", "--shuffle-seed", "20261017"]
        )
        self.assertEqual(options.filter, "summ")
        self.assertEqual(options.shuffle_seed, 20261017)

    def test_seed_is_a_nonnegative_r_integer(self):
        for value in ["-1", "2147483648", "1.5"]:
            with self.subTest(value=value):
                with contextlib.redirect_stderr(io.StringIO()):
                    with self.assertRaises(SystemExit):
                        verify_package.parse_options(["--shuffle-seed", value])


if __name__ == "__main__":
    unittest.main()
