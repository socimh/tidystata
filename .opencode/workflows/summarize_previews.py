"""Generate preview acceptance notes from protected execution evidence."""

import csv
import json
from pathlib import Path


def main():
    root = Path(__file__).resolve().parents[2]
    results = root / ".opencode/results"
    with (results / "preview-final.csv").open(encoding="utf-8", newline="") as stream:
        rows = list(csv.DictReader(stream))
    totals = {
        name: sum(int(row[name]) if row[name].isdigit() else int(row[name] == "TRUE") for row in rows)
        for name in ("passed", "failed", "error", "warning", "skipped")
    }
    if any(totals[name] for name in ("failed", "error", "warning", "skipped")):
        raise RuntimeError(f"Acceptance is not clean: {totals}")
    for stage in ("install", "tests", "build", "check"):
        log = (results / f"preview-final-{stage}.log").read_text(encoding="utf-8")
        if "R launcher exit: 0x00000000" not in log:
            raise RuntimeError(f"Final {stage} did not exit successfully")
        if stage == "check" and "Status: OK" not in log:
            raise RuntimeError("R CMD check is not clean")
    logs = {}
    for name in ("examples", "minimal-minimal", "demos-demos", "style"):
        logs[name] = (results / f"preview-{name}.log").read_text(encoding="utf-8")
        if "R launcher exit: 0x00000000" not in logs[name]:
            raise RuntimeError(f"Missing protected successful exit: {name}")
    cases = [row for row in rows if row["file"] == "test-special-print.R"]
    style = json.loads((root / ".opencode/style-scope.json").read_text(encoding="utf-8"))
    lines = [
        "# Persistent table previews: acceptance", "",
        "Development version 0.2.0.9000. Verified 2026-10-16 (America/New_York).", "",
        "## Outcome", "",
        "The opt-in preview_table() wrapper retains every row and column while printing "
        "head/tail or evenly spaced positions. Its statart_preview class extends a tibble "
        "and preserves the resulting grouping through supported transformations. "
        "unpreview_table() removes only the display policy. Existing tabulation and "
        "summary defaults are unchanged.", "",
        "The four archived print/slice helpers are restored as maintained functions. "
        "One-time printers invisibly return the original data; slicing really selects rows. "
        "The original archived implementation remains preserved.", "",
        "## Verified results", "",
        f"- Full retained suite: **{len(rows):,} blocks / {totals['passed']:,} passing expectations**.",
        f"- Preview contracts: **{len(cases)} blocks / {sum(int(row['passed']) for row in cases)} passing expectations**.",
        "- Zero failures, errors, uncaptured warnings or skips in both scopes.",
        "- Fresh native installation, source build and R CMD check --no-manual: Status: OK.",
        "- Installed standalone verification and required-dependency-only smoke pass.",
        "- All twelve actual-output demos pass, including the eight-example preview demo.",
        f"- Pinned Air, parsing and lintr checks pass for {len(style['files'])} maintained R files.", "",
        "## Behavior and compatibility", "",
        "- Default: first five and last five rows. n is a total positive whole number or Inf; "
        "odd budgets favor the head. Both styles use the first row for n = 1. Short inputs never repeat rows.",
        "- Preview positions are recalculated after edits. Complete data is used in calculations.",
        "- Common dplyr edits, grouping, summaries/reframing, standard joins and tidyr pivots "
        "retain settings. Joins use the left table's policy; bind_rows uses the first table's policy.",
        "- Explicit as_tibble/as.data.frame conversions remove the preview; vector extraction "
        "returns ordinary columns. Table column classes and labels remain intact.",
        "- Support covers ordinary data frames and ordinary/grouped/rowwise tibbles. "
        "Other container subclasses and lazy tables require explicit conversion/collection. "
        "Lists of tables require mapping the wrapper. Direct vec_rbind and arbitrary third-party "
        "transformations are outside the persistence guarantee.",
        "- Six public functions are added/restored: 46 exports in total. "
        "Required Imports remain 12; tibble >= 3.1.0 and pillar >= 1.8.0 declare the public printing API floors.", "",
        "## Regressions caught before acceptance", "",
        "Initial RED confirmed absent APIs. Focused failures then reproduced grouped rename "
        "class loss, pivot selector scope loss, narrow-footer overflow, ignored footer limits, "
        "misleading n=1 omission wording, and duplicate/empty column-name printing errors. "
        "Each was corrected and covered by assertions. Pivot selector callback counts match "
        "the corresponding upstream tidyr operation rather than assuming upstream evaluates once. "
        "Report regeneration also exposed and fixed a whitespace-trimming expression that "
        "removed literal trailing t characters from headings; regenerated headings and fences were verified.", "",
        "## Contract catalogue", "",
        "| Scenario | Passing expectations |", "| --- | ---: |",
    ]
    lines.extend(f"| {row['test']} | {row['passed']} |" for row in cases)
    lines.extend([
        "", "## Actual installed console output", "", "```text", "\n".join(line.rstrip() for line in logs["examples"].strip().splitlines()), "```", "",
        "## Reproduction and limits", "", "```powershell",
        "python .opencode/workflows/verify_package.py --check --prefix .opencode/results/preview-final",
        "python .opencode/workflows/verify_package.py --minimal --prefix .opencode/results/preview-minimal",
        "python .opencode/workflows/verify_package.py --demos --prefix .opencode/results/preview-demos",
        "python .opencode/workflows/check_style.py", "```", "",
        "Run .opencode/tests/verify_special_print.R with the fresh installed library path through "
        "the protected R launcher. Inspect both exit status and captured stderr. "
        "The report generator refuses incomplete or failing acceptance evidence.", "",
        "Executed locally on Windows R 4.6.0 with installed dependencies. R 4.1, "
        "minimum dependency versions, and macOS/Linux execution remain pending. "
        "This feature controls console printing, not HTML widgets or GUI viewers. "
        "No push, merge, publication or release is included.", "",
    ])
    target = root / ".opencode/reports/project_status_previews_2026-10-16.md"
    target.write_text("\n".join(lines), encoding="utf-8")
    print(target)


if __name__ == "__main__":
    main()
