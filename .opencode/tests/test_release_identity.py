"""Reject stale installations and archives before checking release resources."""

import hashlib
import importlib.util
import io
import json
from pathlib import Path
import subprocess
import sys
import tarfile
import tempfile
import unittest
from unittest import mock

ROOT = Path(__file__).resolve().parents[2]
WORKFLOWS = ROOT / ".opencode/workflows"
sys.path.insert(0, str(WORKFLOWS))
from r_process import r_command, r_environment

SPEC = importlib.util.spec_from_file_location("build_site", WORKFLOWS / "build_site.py")
SITE = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(SITE)


class ReleaseIdentityTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.workspace = Path(tempfile.mkdtemp(prefix="tidystata-identity-tests-"))
        cls.fallback = cls.workspace / "fallback-library"
        cls.fallback.mkdir()
        source = cls.workspace / "fallback-source"
        (source / "R").mkdir(parents=True)
        cls.description = (
            "Package: tidystata\nVersion: 0.0.1\nTitle: Identity Test Fixture\n"
            "Description: A temporary fixture for package identity tests.\n"
            "Author: Test Author\nMaintainer: Test Author <test@example.invalid>\n"
            "License: MIT\n"
        )
        (source / "DESCRIPTION").write_text(cls.description, encoding="utf-8")
        (source / "NAMESPACE").write_text("export(identity_fixture)\n", encoding="utf-8")
        (source / "R/fixture.R").write_text(
            'identity_fixture <- function() "fallback"\n', encoding="utf-8")
        result = subprocess.run(
            r_command(["R", "CMD", "INSTALL", "--library=" + str(cls.fallback), source]),
            env=r_environment(), capture_output=True, text=True,
            encoding="utf-8", errors="replace",
        )
        if result.returncode:
            raise RuntimeError(result.stdout + result.stderr)

    def setUp(self):
        self.case = Path(tempfile.mkdtemp(prefix="case-", dir=self.workspace))
        self.library = self.case / "candidate-library"
        (self.library / "tidystata").mkdir(parents=True)
        (self.library / "tidystata/DESCRIPTION").write_text(
            self.description, encoding="utf-8")
        self.archive = self.case / "tidystata_0.0.1.tar.gz"
        with tarfile.open(self.archive, "w:gz") as tar:
            content = self.description.encode("utf-8")
            entry = tarfile.TarInfo("tidystata/DESCRIPTION")
            entry.size = len(content)
            tar.addfile(entry, io.BytesIO(content))
        payload = self.archive.read_bytes()
        self.receipt = self.case / "receipt.json"
        self.record = {
            "tarball": str(self.archive),
            "tarball_sha256": hashlib.sha256(payload).hexdigest(),
            "tarball_md5": hashlib.md5(payload).hexdigest(),
            "bundle_library": str(self.library),
            "package": "tidystata", "version": "0.0.1",
        }
        self.write_receipt()

    def write_receipt(self):
        self.receipt.write_text(json.dumps(self.record), encoding="utf-8")

    def verify(self, library=None, receipt=None):
        return subprocess.run(
            r_command(["Rscript", ROOT / ".opencode/tests/verify_release_resources.R",
                       library or self.library, self.archive, receipt or self.receipt]),
            env=r_environment(libraries=[self.fallback]),
            capture_output=True, text=True, encoding="utf-8", errors="replace",
        )

    def assert_rejected(self, result, message):
        self.assertNotEqual(result.returncode, 0)
        self.assertIn(message, (result.stdout + result.stderr).lower())

    def test_missing_candidate_cannot_load_fallback_installation(self):
        self.assert_rejected(self.verify(library=self.case / "missing"),
                             "candidate installation")

    def test_missing_receipt_is_rejected(self):
        self.assert_rejected(self.verify(receipt=self.case / "missing.json"),
                             "installation receipt")

    def test_unknown_resource_mode_cannot_omit_vignette_checks(self):
        result = subprocess.run(
            r_command(["Rscript", ROOT / ".opencode/tests/verify_release_resources.R",
                       self.library, self.archive, self.receipt, "releas"]),
            env=r_environment(libraries=[self.fallback]), capture_output=True,
            text=True, encoding="utf-8", errors="replace",
        )
        self.assert_rejected(result, "mode must be check or release")

    def test_changed_archive_is_rejected(self):
        self.record["tarball_md5"] = "0" * 32
        self.write_receipt()
        self.assert_rejected(self.verify(), "archive checksum")

    def test_receipt_cannot_identify_another_library(self):
        self.record["bundle_library"] = str(self.fallback)
        self.write_receipt()
        self.assert_rejected(self.verify(), "receipt library")

    def test_loaded_fallback_namespace_is_rejected(self):
        wrapper = self.case / "preload.R"
        wrapper.write_text(
            'loadNamespace("tidystata", lib.loc = Sys.getenv("TIDYSTATA_IDENTITY_FALLBACK"))\n'
            'source(Sys.getenv("TIDYSTATA_IDENTITY_VERIFIER"))\n', encoding="utf-8")
        result = subprocess.run(
            r_command(["Rscript", wrapper, self.library, self.archive, self.receipt]),
            env=r_environment({
                "TIDYSTATA_IDENTITY_FALLBACK": str(self.fallback),
                "TIDYSTATA_IDENTITY_VERIFIER": str(ROOT / ".opencode/tests/verify_release_resources.R"),
            }, libraries=[self.fallback]),
            capture_output=True, text=True, encoding="utf-8", errors="replace",
        )
        self.assert_rejected(result, "loaded namespace")

    def test_site_install_failure_does_not_fall_back_to_installed_package(self):
        root = self.case / "site-source"
        (root / "R").mkdir(parents=True)
        (root / "DESCRIPTION").write_text(self.description, encoding="utf-8")
        target = self.case / "site-output"
        with mock.patch.object(SITE, "__file__", str(root / ".opencode/workflows/build_site.py")), \
             mock.patch.object(sys, "argv", ["build_site.py", "--destination", str(target),
                                             "--library", str(self.fallback)]), \
             mock.patch.object(SITE.subprocess, "run", return_value=subprocess.CompletedProcess([], 17)) as run:
            self.assertEqual(SITE.main(), 17)
        self.assertEqual(run.call_count, 1)
        self.assertIn("INSTALL", list(map(str, run.call_args.args[0])))
        self.assertFalse(target.exists())


if __name__ == "__main__":
    unittest.main()
