"""Summarize collected evidence without changing or suppressing test outcomes."""
import csv
import hashlib
import json
from pathlib import Path


root = Path(__file__).resolve().parents[2]
results = root / ".opencode/results"
prefix = "milestone-retained-final"
with (results / (prefix + ".csv")).open(encoding="utf-8") as stream:
    rows = list(csv.DictReader(stream))
with (results / (prefix + "-details.csv")).open(encoding="utf-8") as stream:
    details = list(csv.DictReader(stream))
baseline = json.loads((results / "baseline-0.2.0.json").read_text(encoding="utf-8"))
with (results / "milestone-contracts.csv").open(encoding="utf-8") as stream:
    focused = list(csv.DictReader(stream))
focused_passes = sum(int(x["passed"]) for x in focused)
if any(int(x["failed"]) or x["error"] == "TRUE" or
       int(x["warning"]) or x["skipped"] == "TRUE" for x in focused):
    raise SystemExit("Focused acceptance is not completely passing; inspect its scenario report")
failure_types = {"expectation_failure", "expectation_error"}
original_failures = {(x["file"], x["test"]) for x in baseline["details"]
                     if x["type"] in failure_types}
new_failures = {(x["file"], x["test"]) for x in details
                if x["type"] in failure_types} - original_failures
manifest = json.loads((results / "baseline-source-manifest.json").read_text(encoding="utf-8"))
manifest = {path.replace("\\", "/"): value for path, value in manifest.items()}
timer_unchanged = all(hashlib.sha256((root / path).read_bytes()).hexdigest() == manifest[path]
                      for path in ("R/timer.R", "tests/testthat/test-timer.R"))
clock_identity = ("test-timer.R", "timer: timing is reasonable compared to system.time")
clock_flakes = {clock_identity} if timer_unchanged and any(
    (x["file"], x["test"]) == clock_identity and
    'st["elapsed"] >= 0.04' in x["message"] for x in details) else set()
unexplained = new_failures - clock_flakes
totals = {
    "Test blocks": len(rows),
    "Passing expectations": sum(int(x["passed"]) for x in rows),
    "Failed expectations": sum(int(x["failed"]) for x in rows),
    "Error blocks": sum(x["error"] == "TRUE" for x in rows),
    "Warnings": sum(int(x["warning"]) for x in rows),
    "Skipped blocks": sum(x["skipped"] == "TRUE" for x in rows),
}
report = [
    "# First milestone: implementation and remaining baseline", "",
    "Version: **0.2.0.9000**. Local implementation of the approved exploration",
    "and preparation scope; no release or publication was performed.", "",
    "## Implemented", "",
    "- Retired read_data, write_data, esttab, and codebook_detail; preserved",
    "  implementations, original help, dedicated tests and demo in extra_functions.",
    "- Reduced Imports from 33 to 13; retained cpp11/Rfast and all other exports.",
    "- Made formatting optional; fre/fre2 default to tibbles and fre1 to a list.",
    "- Fixed character conversion, attribute labels/search, grouped keys and totals,",
    "  atomic row results/missingness/input preservation, and stable quantile ties.",
    "- Added reliable isolated build/test/report commands with failure exit status.",
    "- Regenerated namespace/help/README; refreshed website reference configuration.",
    "", "## Focused acceptance", "",
    f"[{len(focused)} milestone scenarios](milestone_contracts_0.2.0.9000.md) passed, with",
    f"{focused_passes:,} passing expectations and zero failed expectations, errors, warnings,",
    "or skips. The standalone scenario runner returns a nonzero status on failure.",
    "A separate required-dependencies-only library smoke test passed, including",
    "the actionable error for explicitly requested, unavailable flextable output.",
    "All ten active demos passed and their versioned reports preserve actual output.",
    "", "## Full retained suite", "",
    "The full suite is **not passing**. These categories have different counting",
    "units and must not be added together as a number of test cases.", "",
    "| Measure | Count |", "| --- | ---: |",
    *[f"| {name} | {value:,} |" for name, value in totals.items()],
    "", f"New failing test identities relative to the original baseline: **{len(new_failures)}**;",
    f"unexplained after environmental triage: **{len(unexplained)}**.",
    "The original baseline had 134 failed expectations and 38 error blocks across",
    "789 blocks. Functions were retired and regression scenarios added, so total",
    "test counts are not directly comparable as a completion percentage.",
    "", "| File | Failed expectations | Error blocks | Warnings |",
    "| --- | ---: | ---: | ---: |",
]
for filename in sorted({x["file"] for x in rows}):
    group = [x for x in rows if x["file"] == filename]
    failed = sum(int(x["failed"]) for x in group)
    errors = sum(x["error"] == "TRUE" for x in group)
    warnings = sum(int(x["warning"]) for x in group)
    if failed or errors or warnings:
        report.append(f"| {filename} | {failed} | {errors} | {warnings} |")
report += [
    "", "Remaining discrepancies include invalid labelled/tibble/sample fixtures,",
    "cross-tabulation expectations for an extra count column, category-name",
    "collisions, summary/date contracts, and name/type/utility expectations.",
    "Not every failed test is a source defect. Triage these in milestone two.",
    "The additional timer identity checks system.time(Sys.sleep(0.05)) against",
    "a strict 0.04 lower bound before examining statart output. Both timer source",
    "and its test file are byte-identical to the baseline. A 30-iteration base-R",
    "probe reproduced a below-threshold result, and a focused timer rerun returned",
    "only its two original failures. This is an environmental/floating-point timing",
    "fixture flake, not an unexplained package regression; it remains recorded.",
    "", "## Package checking and independent review", "",
    "Fresh source installation and tarball build succeeded. R CMD check --no-manual",
    "passed all non-test stages, including dependency declarations, namespace/load",
    "checks, help, code/documentation consistency, compiled code and examples. It",
    "finished with **one ERROR at tests**, reflecting the retained-suite failures.",
    "Repository-index access warnings occurred in the restricted-network environment.",
    "The inherited invalid Windows locale was corrected only in child processes.",
    "", "The independent reviewer reproduced two important regressions: reserved",
    "variable group keys were overwritten in combined output, and row dispatch",
    "rejected general dataframe expressions inside mutate. Both now have RED-to-GREEN",
    "regression coverage, including exactly-once evaluation of dataframe producers.",
    "The reviewer also verified archive byte identity, exclusion of development/",
    "archive files from the tarball, both datasets, 13 Imports and 40 exports.",
    "Original datasets, DLL and object files were preserved.",
    "", "## Evidence and limits", "",
    f"- [Final suite results](../results/{prefix}.csv).",
    f"- [Failure/warning details](../results/{prefix}-details.csv).",
    "- [Package check log](../results/milestone-verification-check.log).",
    "- [Required-dependency smoke](../results/milestone-minimal-final-minimal.log).",
    "- [Base-R timing probe](../results/milestone-timing-probe.txt) and",
    "  [timer-only recheck](../results/milestone-timer-recheck.csv).",
    "- [Historical baseline](project_status_2026-10-15.md) and its preserved",
    "  [raw evidence](../results/baseline-0.2.0.json).",
    "", "No R-version matrix, manual PDF, full built website, online CI, or release",
    "validation was performed. The declared R 4.1 minimum was not exercised here.",
    "Git metadata is absent, so no commit was possible. See",
    "[DEVELOPMENT.md](../../DEVELOPMENT.md) and [MIGRATION.md](../../MIGRATION.md).",
]
if unexplained:
    report += ["", "## New failure identities requiring triage", "",
               *[f"- {file}: {test}" for file, test in sorted(unexplained)]]
path = root / ".opencode/reports/milestone_status_0.2.0.9000.md"
path.write_text("\n".join(report) + "\n", encoding="utf-8")
print(totals)
print("New failing identities:", len(new_failures), "; unexplained:", len(unexplained))
print(path)
if unexplained:
    raise SystemExit(1)
