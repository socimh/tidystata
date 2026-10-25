"""Build, audit and optionally integrate the bilingual reference book locally."""
import argparse
import json
import os
from pathlib import Path
import shutil
import subprocess
import sys

import reference
import highlight
import validate

ROOT = Path(__file__).resolve().parents[1]


def protected(command, log_directory):
    if os.name == "nt":
        launcher = Path.home() / ".codex/scripts/run_r_safe.py"
        # Codex's sandbox account can have a different HOME from the maintainer.
        if not launcher.is_file():
            launcher = Path("C:/Users/socimh/.codex/scripts/run_r_safe.py")
        if not launcher.is_file():
            raise RuntimeError("The Windows protected R/Quarto launcher is required.")
        return [sys.executable, str(launcher), "--log-directory", str(log_directory), "--", *map(str, command)]
    return list(map(str, command))


def run(command, cwd, log, environment=None):
    print("Running:", " ".join(map(str, command)), flush=True)
    with log.open("w", encoding="utf-8") as stream:
        result = subprocess.run(command, cwd=cwd, stdout=stream, stderr=subprocess.STDOUT,
                                env=environment)
    if result.returncode:
        raise RuntimeError(f"Exit {result.returncode}; {log}\n" + log.read_text(encoding="utf-8", errors="replace")[-4500:])
    print("Passed:", log.name, flush=True)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output", required=True, type=Path, help="Fresh build directory, retained for review")
    parser.add_argument("--personal-site", type=Path, help="Prepare, verify and apply local personal-site integration")
    parser.add_argument("--generate-only", action="store_true")
    args = parser.parse_args()
    output = args.output.resolve()
    if output.exists():
        parser.error("Choose a fresh --output directory; existing artifacts are never removed.")
    output.mkdir(parents=True)
    environment = os.environ.copy()
    environment.update(LC_ALL="C", LANGUAGE="en")
    metadata_path = output / "metadata.csv"
    run(protected(["Rscript", ROOT / "book/export-metadata.R", ROOT, metadata_path], output / "logs"),
        ROOT, output / "metadata.log", environment)
    metadata = {row["id"]: {"priority": int(row["priority"]), "meaning": row["meaning"],
                            "preferred": row["preferred"] == "TRUE"} for row in reference.read_csv(metadata_path)}
    source = output / "source"
    manifest = reference.generate(ROOT, source, metadata)
    print(f"Generated {manifest['example_count']} examples in both editions.", flush=True)
    if args.generate_only:
        return 0
    # Quarto's Windows Sass cache lives below LOCALAPPDATA. Keep build caches
    # writable and isolated without changing machine or user configuration.
    if os.name == "nt":
        environment["LOCALAPPDATA"] = str(output / "local-cache")
    for lang in ("en", "zh"):
        run(protected(["quarto", "render"], output / "logs"), source / lang, output / (lang + "-render.log"), environment)
    site = output / "site"
    shutil.copytree(source / "en/_book", site)
    shutil.copytree(source / "zh/_book", site / "zh")
    highlight.rehighlight_site(site)
    report = validate.audit(site, manifest)
    (output / "audit.json").write_text(json.dumps(report, indent=2), encoding="utf-8")
    print(json.dumps(report), flush=True)
    if args.personal_site:
        import integrate
        integrate.integrate(args.personal_site, site, output / "personal-site", run, protected, environment)
    print("Book ready:", site / "index.html", flush=True)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
