"""Build a fresh website from staged package sources, preserving repository artifacts."""

import argparse
import hashlib
import json
from pathlib import Path
import shutil
import subprocess
import tempfile

from r_process import r_command, r_environment


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--destination", required=True,
                        help="New output directory; existing paths are never overwritten")
    parser.add_argument("--library", help="Dependency library; the staged package is always freshly installed")
    args = parser.parse_args()
    root = Path(__file__).resolve().parents[2]
    destination = Path(args.destination).resolve()
    if destination.exists():
        parser.error("Destination already exists; choose a fresh directory.")
    libraries = []
    if args.library:
        library = Path(args.library).resolve()
        if not library.is_dir():
            parser.error("--library must be an existing dependency library directory.")
        libraries.append(library)
    development_library = root / ".opencode/tools/library"
    if development_library.is_dir():
        libraries.append(development_library)
    workspace = Path(tempfile.mkdtemp(prefix="statart-site-"))
    source = workspace / "statart"
    candidate_library = workspace / "library"
    candidate_library.mkdir()
    libraries.insert(0, candidate_library)
    excluded = {"AGENTS.md", "DEVELOPMENT.md", "CONTRIBUTING.md",
                ".opencode", "extra_functions", "docs"}

    def ignore(directory, names):
        return [name for name in names if
                (Path(directory) == root and (name in excluded or
                                             name.startswith(".Rd2pdf"))) or
                name in {".git", ".Rproj.user", ".Rhistory", "__pycache__"} or
                (Path(directory).name == "src" and
                 Path(name).suffix.lower() in {".o", ".dll", ".so", ".a"})]

    shutil.copytree(root, source, ignore=ignore)
    source_files = {
        path.relative_to(source).as_posix(): hashlib.sha256(path.read_bytes()).hexdigest()
        for path in sorted(source.rglob("*")) if path.is_file()
    }
    source_sha256 = hashlib.sha256(
        json.dumps(source_files, sort_keys=True).encode("utf-8")
    ).hexdigest()
    script = workspace / "build-site.R"
    script.write_text(
        'args <- commandArgs(trailingOnly = TRUE)\n'
        'candidate_library <- normalizePath(args[[3L]], winslash = "/", mustWork = TRUE)\n'
        'expected <- normalizePath(file.path(candidate_library, "statart"),\n'
        '  winslash = "/", mustWork = TRUE)\n'
        '.libPaths(c(candidate_library, .libPaths()))\n'
        'ns <- loadNamespace("statart", lib.loc = candidate_library)\n'
        'actual <- normalizePath(getNamespaceInfo(ns, "path"), winslash = "/", mustWork = TRUE)\n'
        'stopifnot(identical(actual, expected),\n'
        '  identical(normalizePath(find.package("statart"), winslash = "/"), expected))\n'
        'source_desc <- read.dcf(file.path(args[[1L]], "DESCRIPTION"))\n'
        'installed_desc <- read.dcf(file.path(expected, "DESCRIPTION"))\n'
        'stopifnot(identical(source_desc[1L, c("Package", "Version")],\n'
        '  installed_desc[1L, c("Package", "Version")]),\n'
        '  identical(as.character(getNamespaceVersion(ns)), unname(source_desc[1L, "Version"])))\n'
        'cat("Verified fresh installation:", actual, "\\n")\n'
        'pkgdown::build_site(args[[1L]], install = FALSE, new_process = FALSE,\n'
        '  preview = FALSE, quiet = FALSE,\n'
        '  override = list(destination = args[[2L]]))\n',
        encoding="utf-8",
    )
    destination.parent.mkdir(parents=True, exist_ok=True)
    log = destination.with_name(destination.name + "-build.log")
    paths = destination.with_name(destination.name + "-paths.json")
    record = {
        "workspace": str(workspace), "source": str(source),
        "destination": str(destination), "libraries": list(map(str, libraries)),
        "candidate_library": str(candidate_library), "log": str(log),
        "source_sha256": source_sha256, "source_files_sha256": source_files,
    }
    paths.write_text(json.dumps(record, indent=2), encoding="utf-8")
    print("Staged source:", source, flush=True)
    print("Source SHA-256:", source_sha256, flush=True)
    install_log = destination.with_name(destination.name + "-install.log")
    install_command = r_command(
        ["R", "CMD", "INSTALL", "--preclean", "--library=" + str(candidate_library), source],
        log_directory=workspace / "logs",
    )
    with install_log.open("w", encoding="utf-8") as stream:
        installed = subprocess.run(install_command, cwd=source,
                                   env=r_environment(libraries=libraries),
                                   stdout=stream, stderr=subprocess.STDOUT)
    record.update(install_log=str(install_log), install_exit=installed.returncode)
    paths.write_text(json.dumps(record, indent=2), encoding="utf-8")
    print("Fresh install exit:", installed.returncode, "; log:", install_log, flush=True)
    if installed.returncode:
        print(install_log.read_text(encoding="utf-8", errors="replace")[-5000:])
        return installed.returncode
    command = r_command(["Rscript", script, source, destination, candidate_library],
                        log_directory=workspace / "logs")
    print("Destination:", destination, flush=True)
    with log.open("w", encoding="utf-8") as stream:
        result = subprocess.run(command, cwd=source,
                                env=r_environment(libraries=libraries),
                                stdout=stream, stderr=subprocess.STDOUT)
    print("Site build exit:", result.returncode, "; log:", log, flush=True)
    record["build_exit"] = result.returncode
    paths.write_text(json.dumps(record, indent=2), encoding="utf-8")
    if result.returncode:
        print(log.read_text(encoding="utf-8", errors="replace")[-5000:])
    else:
        # Preserve the GitHub Pages marker supplied by the previous workflow.
        (destination / ".nojekyll").write_text("", encoding="utf-8")
    return result.returncode


if __name__ == "__main__":
    raise SystemExit(main())
