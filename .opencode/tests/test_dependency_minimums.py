"""Offline regression checks for complete, feasible dependency-floor coverage."""
from copy import deepcopy
import importlib.util
import json
from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[2]
SPEC = importlib.util.spec_from_file_location(
    "dependency_minimums", ROOT / ".opencode/workflows/dependency_minimums.py")
MODULE = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(MODULE)


class FloorMatrixTests(unittest.TestCase):
    def setUp(self):
        self.description = (ROOT / "DESCRIPTION").read_text(encoding="utf-8")
        self.config = json.loads((ROOT / ".opencode/dependency-minimums.json").read_text(encoding="utf-8"))

    def test_every_declared_bound_has_an_exact_feasible_case(self):
        rows = MODULE.matrix(self.description, self.config)["include"]
        bounds = [entry for entry in MODULE.requirements(MODULE.dcf(self.description)) if entry[2]]
        self.assertEqual(len(rows), len(bounds))
        self.assertEqual({row["package"] for row in rows}, {entry[1] for entry in bounds})
        for row in rows:
            self.assertTrue(MODULE.satisfies(row["version"], "==", row["declared"]))
            self.assertEqual(set(row["install_order"]), set(row["pins"]))

    def test_new_bound_cannot_be_omitted(self):
        description = self.description.replace("    rlang,", "    rlang (>= 1.1.0),")
        with self.assertRaisesRegex(ValueError, "coverage differs"):
            MODULE.matrix(description, self.config)

    def test_changed_bound_requires_review(self):
        description = self.description.replace("testthat (>= 3.2.0)", "testthat (>= 3.2.1)")
        with self.assertRaisesRegex(ValueError, "Changed declared floor"):
            MODULE.matrix(description, self.config)

    def test_infeasible_companions_fail_instead_of_upgrading_candidate(self):
        config = deepcopy(self.config)
        config["cases"]["dplyr"]["companions"] = {"pillar": "1.8.1"}
        config["upstream"]["pillar@1.8.1"] = dict(
            config["upstream"]["pillar@1.9.0"], Version="1.8.1")
        with self.assertRaisesRegex(ValueError, "Infeasible companion.*pillar"):
            MODULE.matrix(self.description, config)

    def test_unreviewed_effective_boundary_is_rejected(self):
        config = deepcopy(self.config)
        config["cases"]["tibble"].update(classification="redundant", version="3.2.1")
        with self.assertRaisesRegex(ValueError, "Unreviewed effective boundary"):
            MODULE.matrix(self.description, config)

    def test_alternate_version_spelling_is_equivalent(self):
        self.assertTrue(MODULE.satisfies("1.0-0", "==", "1.0.0"))

    def test_upstream_evidence_matches_pins(self):
        config = deepcopy(self.config)
        config["upstream"]["dplyr@1.1.4"]["Version"] = "1.1.5"
        with self.assertRaisesRegex(ValueError, "Upstream version mismatch"):
            MODULE.matrix(self.description, config)


if __name__ == "__main__":
    unittest.main()
