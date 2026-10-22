"""Check the explicitly adopted R sources without modifying them."""

import argparse
import json
import os
from pathlib import Path
import shutil
import subprocess
import sys

from r_process import r_command, r_environment


def checked_files(root, manifest):
    paths = manifest["files"]
    if not paths or len(paths) != len(set(paths)):
        raise ValueError("Style scope must be nonempty and contain no duplicates")
    for name in paths:
        path = Path(name)
        if (path.is_absolute() or ".." in path.parts or path.suffix != ".R"
                or "\\" in name or name != path.as_posix()):
            raise ValueError("Invalid R source path: " + name)
        target = (root / path).resolve()
        if not target.is_relative_to(root.resolve()) or not target.is_file():
            raise ValueError("Missing or external R source: " + name)
        if name.casefold() == "r/cpp11.r" or name.casefold().startswith(
            ("extra_functions/", "docs/", ".opencode/results/",
             ".opencode/tools/", ".opencode/notes/")
        ):
            raise ValueError("Generated or archived source in style scope: " + name)
    return paths


def new_sources(root, base):
    result = subprocess.run(
        ["git", "diff", "--name-only", "-z", "--diff-filter=A", base, "--", "R", "tests"],
        cwd=root, check=True, text=True, encoding="utf-8", capture_output=True,
    )
    return {name for name in result.stdout.split("\0") if name.endswith(".R")}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--base", help="Reject newly added package/test R files outside scope")
    parser.add_argument("--air", help="Path to the pinned Air executable")
    args = parser.parse_args()
    root = Path(__file__).resolve().parents[2]
    manifest_path = root / ".opencode/style-scope.json"
    manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
    paths = checked_files(root, manifest)
    if args.base:
        missing = new_sources(root, args.base) - set(paths) - {"R/cpp11.R"}
        if missing:
            raise ValueError("New R sources absent from style scope: " + ", ".join(sorted(missing)))
    local_air = root / ".opencode/tools/style-tools/air.exe"
    air = args.air or os.environ.get("TIDYSTATA_AIR") or shutil.which("air")
    if not air and local_air.is_file():
        air = str(local_air)
    if not air:
        raise RuntimeError("Install Air " + manifest["air_version"] + " or set TIDYSTATA_AIR")
    version = subprocess.check_output([air, "--version"], text=True, encoding="utf-8").strip()
    if version != "air " + manifest["air_version"]:
        raise RuntimeError("Expected Air " + manifest["air_version"] + "; found " + version)
    result = subprocess.run([air, "format", "--check", *paths], cwd=root)
    if result.returncode:
        return result.returncode
    script = root / ".opencode/workflows/check_style.R"
    command = r_command(["Rscript", str(script), str(manifest_path)])
    return subprocess.run(command, cwd=root, env=r_environment()).returncode


if __name__ == "__main__":
    try:
        sys.exit(main())
    except (ValueError, RuntimeError, subprocess.CalledProcessError) as error:
        print(str(error), file=sys.stderr)
        sys.exit(1)
