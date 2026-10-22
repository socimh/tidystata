"""Build and test a fresh temporary source copy without replacing local artifacts."""
import argparse
import csv
import hashlib
import json
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
import tarfile
import time
import uuid
from datetime import datetime, timezone

from r_process import r_command, r_environment


def source_copy_ignore(root):
    """Keep local tools and derived outputs out of fresh verification copies."""
    def ignore(directory, names):
        directory = Path(directory)
        return [name for name in names if
                name in {".git", ".Rproj.user", "__pycache__", ".Rhistory"} or
                (directory == root and (name in {"docs", "extra_functions"} or
                                        name.startswith(".Rd2pdf"))) or
                (directory == root / ".opencode" and
                 name in {"results", "tools", "notes"}) or
                (directory.name == "src" and
                 Path(name).suffix.lower() in {".o", ".dll", ".so", ".a"})]
    return ignore


def parse_options(argv=None):
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--filter", default="")
    parser.add_argument("--shuffle-seed", type=int)
    modes = parser.add_mutually_exclusive_group()
    modes.add_argument("--check", action="store_true")
    modes.add_argument("--release", action="store_true",
                        help="Build vignettes and run full --as-cran/manual checks")
    modes.add_argument("--demos", action="store_true")
    modes.add_argument("--minimal", action="store_true")
    parser.add_argument("--prefix", default=".opencode/results/current")
    options = parser.parse_args(argv)
    if any((options.check, options.release, options.demos, options.minimal)) and (
        options.filter or options.shuffle_seed is not None
    ):
        parser.error("--filter and --shuffle-seed require ordinary test mode")
    if options.shuffle_seed is not None and not 0 <= options.shuffle_seed <= 2147483647:
        parser.error("--shuffle-seed must be an integer from 0 to 2147483647")
    return options


def source_identity(source):
    """Hash every staged input, including fixtures, resources and workflow code."""
    files = {path.relative_to(source).as_posix():
             hashlib.sha256(path.read_bytes()).hexdigest()
             for path in sorted(source.rglob("*")) if path.is_file()}
    digest = hashlib.sha256(json.dumps(files, sort_keys=True).encode("utf-8")).hexdigest()
    return digest, files


def main():
    options = parse_options()
    root = Path(__file__).resolve().parents[2]
    prefix = (root / options.prefix).resolve()
    prefix.parent.mkdir(parents=True, exist_ok=True)
    receipt_path = Path(str(prefix) + "-paths.json")
    paths = dict(run_id=uuid.uuid4().hex, status="running", stages=[],
                 started_at=datetime.now(timezone.utc).isoformat(), current_outputs=[],
                 mode=next((name for name in ("check", "release", "demos", "minimal")
                            if getattr(options, name)), "tests"),
                 filter=options.filter, shuffle_seed=options.shuffle_seed)

    def persist():
        receipt_path.write_text(json.dumps(paths, indent=2), encoding="utf-8")

    persist()  # Invalidate old success before staging or installation can fail.
    status = 1
    try:
        status = execute(options, root, prefix, paths, persist)
        return status
    except BaseException as error:
        paths["exception"] = str(error)
        for stage in paths["stages"]:
            if stage["status"] == "running":
                stage.update(status="failed", exception=str(error),
                             finished_at=datetime.now(timezone.utc).isoformat())
        raise
    finally:
        paths["status"] = "passed" if status == 0 else "failed"
        paths["exit_status"] = status
        paths["finished_at"] = datetime.now(timezone.utc).isoformat()
        persist()


def execute(options, root, prefix, paths, persist):
    workspace = Path(tempfile.mkdtemp(prefix="tidystata-verify-"))
    source = workspace / "tidystata"
    library = workspace / "library"
    library.mkdir()
    logs = workspace / "logs"
    suite_prefix = workspace / "suite"
    paths.update(workspace=str(workspace), source=str(source), library=str(library))
    persist()
    started = time.monotonic()
    stage = dict(name="stage", status="running",
                 started_at=datetime.now(timezone.utc).isoformat())
    paths["stages"].append(stage)
    persist()
    shutil.copytree(root, source, ignore=source_copy_ignore(root))
    digest, files = source_identity(source)
    paths.update(source_sha256=digest, source_fingerprints=files)
    identity_path = workspace / "source-identity.json"
    identity_path.write_text(json.dumps(dict(source_sha256=digest,
                             source_fingerprints=files)), encoding="utf-8")
    stage.update(status="passed", elapsed_seconds=time.monotonic() - started,
                 finished_at=datetime.now(timezone.utc).isoformat())
    persist()
    print("Fresh source:", source, flush=True)

    def collect_suite():
        for suffix in (".csv", ".rds", "-order.csv", "-metadata.json", "-details.csv"):
            output = Path(str(suite_prefix) + suffix)
            if output.is_file():
                target = Path(str(prefix) + suffix)
                shutil.copyfile(output, target)
                paths["current_outputs"].append(str(target))
        summary = Path(str(suite_prefix) + ".csv")
        if summary.is_file():
            with summary.open(encoding="utf-8", newline="") as stream:
                rows = list(csv.DictReader(stream))
            def number(value):
                return 1 if value == "TRUE" else 0 if value == "FALSE" else int(value)
            paths["suite"] = dict(blocks=len(rows), totals={
                name: sum(number(row[name]) for row in rows)
                for name in ("passed", "failed", "error", "warning", "skipped")})
        persist()

    def run(name, command, cwd=root, extra_env=None):
        development_library = root / ".opencode/tools/library"
        library_paths = [str(library)]
        if development_library.is_dir():
            library_paths.append(str(development_library))
        env = r_environment(extra_env, libraries=library_paths)
        env["TIDYSTATA_SOURCE_IDENTITY"] = str(identity_path)
        if name == "check":
            env.pop("NOT_CRAN", None)
        log = prefix.parent / (prefix.name + "-" + name + ".log")
        stage = dict(name=name, status="running", log=str(log), log_current=False,
                     command=list(map(str, command)), started_at=datetime.now(timezone.utc).isoformat())
        paths["stages"].append(stage)
        persist()
        started = time.monotonic()
        full_command = r_command(command, log_directory=logs)
        with log.open("w", encoding="utf-8") as stream:
            stage["log_current"] = True
            paths["current_outputs"].append(str(log))
            persist()
            result = subprocess.run(full_command, cwd=cwd, env=env,
                                    stdout=stream, stderr=subprocess.STDOUT)
        stage.update(status="passed" if result.returncode == 0 else "failed",
                     exit_status=result.returncode, elapsed_seconds=time.monotonic() - started,
                     finished_at=datetime.now(timezone.utc).isoformat())
        persist()
        print(name + ": exit " + str(result.returncode) + "; " + str(log), flush=True)
        if result.returncode:
            print(log.read_text(encoding="utf-8", errors="replace")[-5000:], flush=True)
        return result.returncode

    workflow = source / ".opencode/workflows"
    helpers = source / ".opencode/tests"
    checked = options.check or options.release
    status = 0
    if not checked:
        status = run("install", ["R", "CMD", "INSTALL", "--preclean",
                     "--no-test-load", "--library=" + str(library), source])
        if status:
            return status
    if options.demos:
        return run("demos", ["Rscript", workflow / "generate_demo_reports.R"],
                   cwd=source, extra_env={"TIDYSTATA_DEMO_SOURCE": str(source),
                                         "TIDYSTATA_DEMO_LIBRARY": str(library),
                                         "TIDYSTATA_REPORT_DIR": str(root / ".opencode/reports")})
    if options.minimal:
        return run("minimal", ["Rscript", helpers / "minimal_dependencies.R",
                               library, workspace / "minimal-library"])
    if not checked:
        test_command = ["Rscript", workflow / "run_suite.R", source, suite_prefix,
                        options.filter, str(options.shuffle_seed) if
                        options.shuffle_seed is not None else "", "all"]
        status = run("tests", test_command, extra_env={"NOT_CRAN": "true",
                     "TIDYSTATA_TEST_LIBRARY": str(library),
                     "TIDYSTATA_SOURCE_SHA256": digest, "TIDYSTATA_RUN_ID": paths["run_id"]})
        collect_suite()
    if options.check or options.release:
        build_options = [] if options.release else ["--no-build-vignettes", "--no-manual"]
        build = run("build", ["R", "CMD", "build", *build_options, source], cwd=workspace)
        if build:
            return build
        tarballs = list(workspace.glob("tidystata_*.tar.gz"))
        if len(tarballs) != 1:
            raise RuntimeError("Expected exactly one built package archive")
        paths["tarball"] = str(tarballs[0])
        Path(str(prefix) + "-paths.json").write_text(
            json.dumps(paths, indent=2), encoding="utf-8")
        check_options = ["--as-cran"] if options.release else ["--no-manual", "--ignore-vignettes"]
        check_env = {
            "_R_CHECK_FORCE_SUGGESTS_": "true",
            "_R_CHECK_CRAN_INCOMING_REMOTE_": "true"
        } if options.release else {
            "_R_CHECK_FORCE_SUGGESTS_": "false",
            "_R_CHECK_CRAN_INCOMING_REMOTE_": "false"
        }
        paths["release_check"] = options.release
        paths["check_options"] = check_options
        Path(str(prefix) + "-paths.json").write_text(
            json.dumps(paths, indent=2), encoding="utf-8")
        check = run("check", ["R", "CMD", "check", *check_options, tarballs[0]],
                    cwd=workspace, extra_env=check_env)
        check_result = workspace / "check-result.json"
        parsed = run("check-result", [
            "Rscript", workflow / "parse_check_result.R",
            workspace / "tidystata.Rcheck/00check.log", str(check), check_result
        ])
        if parsed == 0 and not check_result.is_file():
            parsed = 1
        if check_result.is_file():
            target = Path(str(prefix) + "-check-result.json")
            shutil.copyfile(check_result, target)
            paths["current_outputs"].append(str(target))
        status = status or check or parsed
        paths["check_result"] = str(check_result)
        if parsed == 0 and check_result.is_file():
            summary = json.loads(check_result.read_text(encoding="utf-8"))
            summary.update(run_id=paths["run_id"], source_sha256=digest)
            check_result.write_text(json.dumps(summary, indent=2), encoding="utf-8")
            shutil.copyfile(check_result, Path(str(prefix) + "-check-result.json"))
            paths["check_summary"] = summary
            print("Check counts:", summary["counts"], flush=True)
            if summary["notes"]:
                print("Check notes require review before publication.", flush=True)
        if status == 0:
            archive = tarballs[0]
            before = archive.read_bytes()
            bundle_library = workspace / "bundle-library"
            bundle_library.mkdir()
            installed = run("bundle-install", [
                "R", "CMD", "INSTALL", "--library=" + str(bundle_library), archive
            ])
            if archive.read_bytes() != before:
                raise RuntimeError("Candidate archive changed during installation")
            status = status or installed
            if installed == 0:
                with tarfile.open(archive) as bundle:
                    description = bundle.extractfile("tidystata/DESCRIPTION").read().decode("utf-8")
                fields = dict(line.split(":", 1) for line in description.splitlines()
                              if line and not line[0].isspace() and ":" in line)
                receipt = dict(
                    run_id=paths["run_id"], source_sha256=digest,
                    tarball=str(archive),
                    tarball_sha256=hashlib.sha256(before).hexdigest(),
                    tarball_md5=hashlib.md5(before).hexdigest(),
                    bundle_library=str(bundle_library),
                    package=fields["Package"].strip(), version=fields["Version"].strip()
                )
                receipt_path = Path(str(prefix) + "-installation.json")
                receipt_path.write_text(json.dumps(receipt, indent=2), encoding="utf-8")
                snapshots = run("snapshots", [
                    "Rscript", workflow / "run_suite.R", source, suite_prefix, "", "", "snapshots"
                ], extra_env={"NOT_CRAN": "true", "TIDYSTATA_TEST_LIBRARY": str(bundle_library),
                              "TIDYSTATA_SOURCE_SHA256": digest, "TIDYSTATA_RUN_ID": paths["run_id"]})
                collect_suite()
                status = status or snapshots
                resources = run("resources", [
                    "Rscript", helpers / "verify_release_resources.R",
                    bundle_library, archive, receipt_path, "release" if options.release else "check"
                ])
                status = status or resources
                paths.update(receipt, installation_receipt=str(receipt_path))
                paths["current_outputs"].append(str(receipt_path))
        Path(str(prefix) + "-paths.json").write_text(
            json.dumps(paths, indent=2), encoding="utf-8")
    return status


if __name__ == "__main__":
    raise SystemExit(main())
