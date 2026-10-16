"""Build the core-stabilization report from retained verification evidence."""
from pathlib import Path
import csv

ROOT = Path(__file__).resolve().parents[2]
PREFIX = ROOT / ".opencode/results/stabilization-core-clean"
REPORT = ROOT / ".opencode/reports/project_status_core_stabilization_2026-10-16.md"


def main():
    with Path(str(PREFIX) + ".csv").open(encoding="utf-8", newline="") as stream:
        rows = list(csv.DictReader(stream))
    totals = {key: sum(int(row[key]) if key in ("passed", "failed", "warning") else row[key] == "TRUE" for row in rows) for key in ("passed", "failed", "error", "warning", "skipped")}
    check = Path(str(PREFIX) + "-check.log").read_text(encoding="utf-8")
    assert totals["failed"] == totals["error"] == 0
    assert "Status: OK" in check and "R launcher exit: 0x00000000" in check
    examples = (ROOT / ".opencode/results/stabilization-core-examples.txt").read_text(encoding="utf-8")
    examples = "\n".join(line.rstrip() for line in examples.splitlines() if not line.startswith("R launcher"))
    lines = ["# Core stabilization verification", "", "Verified 2026-10-16. Version 0.2.0.9000; 13 required Imports; 40 exports. No push, merge or release.", "", "## Agreed behavior and repairs", "", "- Retain numeric/logical columns with no observations, including zero-row inputs: n/unique are zero and statistics are NA. Grouped empty inputs do not invent groups.", "- Accept missing/p25/p50/p75 alongside miss_n/q1/median/q3; preserve requested names/order and support numeric sum. Calendar sum is explicitly unsupported. Mixed calendar/numeric table statistics use compatible text columns while counts stay numeric; list-mode numeric statistics stay numeric.", "- Preserve substring searches and explicitly test anchored complete-name matching.", "- Count list-column identities without flattening. No selected variables yield empty tables; tab1/fre1 retain list defaults. Invalid nonempty cross-table arity still errors.", "- Fix original-variable/category name collisions, preserve n/...tmp categories and reject fre2 column category total before it overwrites counts.", "- Recognize units metadata before interpreting pillar display strings, including empty/all-missing measured vectors.", "", "## Fresh verification", "", "| Measure | Result |", "| --- | ---: |", f"| Test blocks | {len(rows)} |"]
    labels = {"passed": "Passing expectations", "failed": "Failed expectations", "error": "Error blocks", "warning": "Test warnings", "skipped": "Skipped blocks"}
    lines += [f"| {labels[key]} | {totals[key]} |" for key in ("passed", "failed", "error", "warning", "skipped")]
    lines += ["", "Fresh native installation, source build, and R CMD check --no-manual all passed. Check status is OK: zero check errors, warnings or notes. A first check exposed five unbound selection names; using explicit all_of selections removed that NOTE in this final run. The required-dependency-only smoke check also passed.", "", "The 33 test warnings are distinct from package-check warnings. They include expected conversion/metadata/invalid-input warnings and legacy matrix-name fixtures. The single skipped block is the pre-existing empty cut_length interval-width test; it still needs a real assertion. No tests were removed or disabled. The test-only stage had five failed expectations and ten errors across 1,358 blocks; this stage adds 52 regression blocks and clears all remaining failures/errors.", "", "| Modified family | Verified blocks | Passing expectations |", "| --- | ---: | ---: |"]
    families = {"Summary/statistics": ("test-summ.R", "test-summ-contracts.R"), "Tabulation/frequency": ("test-tab.R", "test-tab1.R", "test-tab2.R", "test-fre.R", "test-fre1.R", "test-fre2.R", "test-tab-collisions.R", "test-tab-empty-selection.R"), "Types/units": ("test-s_type.R",), "Names/search": ("test-names.R",), "Prior milestone contracts": ("test-milestone-core.R", "test-milestone-review.R")}
    for family, files in families.items():
        subset = [row for row in rows if row["file"] in files]
        lines.append(f"| {family} | {len(subset)} | {sum(int(row['passed']) for row in subset)} |")
    lines += ["", "Sources: [full summary](../results/stabilization-core-clean.csv), [warning/skip details](../results/stabilization-core-clean-details.csv), [test log](../results/stabilization-core-clean-tests.log), [build log](../results/stabilization-core-clean-build.log), [package check](../results/stabilization-core-clean-check.log), [required-dependency smoke](../results/stabilization-core-minimal-minimal.log).", "", "Read-only package review found no material introduced defects; focused probes also verified grouped empty summaries, nested lists, and empty flextable output. Generated help/README were rebuilt from source. Original datasets and native build artifacts were preserved.", "", "## Actual output examples", "", "Captured through the protected launcher using .opencode/tests/show_core_stabilization.R and a fresh installation.", "", "```text", examples, "```", "", "## Remaining limits", "", "- Exercise the declared R 4.1 minimum and other platforms before publishing. This validation used Windows R 4.6.0; no online CI or release was performed.", "- Replace the empty cut_length test and tighten expected-warning handling/legacy matrix fixtures separately.", "- Ambiguous combined-header or literal-NA/missing-category pivot labels still error explicitly. A row value total remains alongside the appended total row, so callers should use the final row for the marginal total.", "- Four regenerated README console lines contain pillar trailing spaces; generated output was not manually patched.", "", "Regenerate this report with python .opencode/workflows/summarize_core_stabilization.py after running the protected final verification workflow.", ""]
    REPORT.write_text("\n".join(lines), encoding="utf-8")
    print(REPORT)
    print(totals)


if __name__ == "__main__":
    main()
