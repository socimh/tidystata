"""Build and test a fresh temporary source copy without replacing local artifacts."""
import argparse
import json
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--filter", default="")
    parser.add_argument("--check", action="store_true")
    parser.add_argument("--demos", action="store_true")
    parser.add_argument("--minimal", action="store_true")
    parser.add_argument("--prefix", default=".opencode/results/current")
    options = parser.parse_args()
    root = Path(__file__).resolve().parents[2]
    prefix = (root / options.prefix).resolve()
    prefix.parent.mkdir(parents=True, exist_ok=True)
    workspace = Path(tempfile.mkdtemp(prefix="statart-verify-"))
    source = workspace / "statart"
    library = workspace / "library"
    library.mkdir()
    launcher = Path("C:/Users/socimh/.codex/scripts/run_r_safe.py")
    logs = workspace / "logs"

    def ignore(directory, names):
        return [name for name in names if name in
                (".git", ".Rproj.user", "__pycache__", ".Rhistory") or
                (Path(directory).name == "src" and
                 Path(name).suffix.lower() in (".o", ".dll", ".so", ".a"))]

    shutil.copytree(root, source, ignore=ignore)
    paths = dict(workspace=str(workspace), source=str(source), library=str(library))
    Path(str(prefix) + "-paths.json").write_text(
        json.dumps(paths, indent=2), encoding="utf-8")
    print("Fresh source:", source, flush=True)

    def run(name, command, cwd=root, extra_env=None):
        env = os.environ.copy()
        # The inherited C.UTF-8 locale is unsupported by Windows R. Scope the
        # correction to child processes; never change machine/R startup files.
        env.update({"LC_ALL": "C", "LANG": "C"})
        env.update(extra_env or {})
        log = prefix.parent / (prefix.name + "-" + name + ".log")
        full_command = [sys.executable, str(launcher), "--log-directory",
                        str(logs), "--timeout", "900", "--", *map(str, command)]
        with log.open("w", encoding="utf-8") as stream:
            result = subprocess.run(full_command, cwd=cwd, env=env,
                                    stdout=stream, stderr=subprocess.STDOUT)
        print(name + ": exit " + str(result.returncode) + "; " + str(log), flush=True)
        if result.returncode:
            print(log.read_text(encoding="utf-8", errors="replace")[-5000:], flush=True)
        return result.returncode

    status = run("install", ["R", "CMD", "INSTALL", "--preclean",
                             "--no-test-load", "--library=" + str(library), source])
    if status:
        return status
    if options.demos:
        return run("demos", ["Rscript", root / ".opencode/workflows/generate_demo_reports.R"],
                   cwd=source, extra_env={"STATART_DEMO_SOURCE": str(source),
                                         "STATART_DEMO_LIBRARY": str(library),
                                         "R_LIBS_USER": str(library),
                                         "STATART_REPORT_DIR": str(root / ".opencode/reports")})
    if options.minimal:
        return run("minimal", ["Rscript", root / ".opencode/tests/minimal_dependencies.R",
                               library, workspace / "minimal-library"])
    status = run("tests", ["Rscript", root / ".opencode/workflows/run_suite.R",
                           source, prefix, options.filter])
    if options.check:
        build = run("build", ["R", "CMD", "build", "--no-build-vignettes",
                               "--no-manual", source], cwd=workspace)
        if build:
            return build
        tarballs = list(workspace.glob("statart_*.tar.gz"))
        if len(tarballs) != 1:
            raise RuntimeError("Expected exactly one built package archive")
        paths["tarball"] = str(tarballs[0])
        Path(str(prefix) + "-paths.json").write_text(
            json.dumps(paths, indent=2), encoding="utf-8")
        check = run("check", ["R", "CMD", "check", "--no-manual",
                               tarballs[0]], cwd=workspace, extra_env={
                                   "_R_CHECK_FORCE_SUGGESTS_": "false",
                                   "_R_CHECK_CRAN_INCOMING_REMOTE_": "false"
                               })
        status = status or check
    return status


if __name__ == "__main__":
    raise SystemExit(main())
