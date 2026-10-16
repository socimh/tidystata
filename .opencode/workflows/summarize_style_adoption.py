"""Generate the adoption report from saved verification evidence."""

import csv
import json
from pathlib import Path


def number(value):
    return int(value == "TRUE") if value in ("TRUE", "FALSE") else int(float(value))


def main():
    root = Path(__file__).resolve().parents[2]
    results = root / ".opencode/results"
    prefix = "style-adoption-final"
    with (results / (prefix + ".csv")).open(encoding="utf-8") as stream:
        rows = list(csv.DictReader(stream))
    totals = {key: sum(number(row[key]) for row in rows)
              for key in ("passed", "failed", "error", "warning", "skipped")}
    assert totals["passed"] > 0 and not any(totals[key] for key in totals if key != "passed")
    for stage in ("install", "tests", "build", "check"):
        log = (results / (prefix + "-" + stage + ".log")).read_text(encoding="utf-8")
        assert "R launcher exit: 0x00000000" in log, stage
        if stage == "check":
            assert "Status: OK" in log
    compatibility = (results / "style-adoption-compatibility.log").read_text(encoding="utf-8")
    assert "Verified unchanged: 40 public interfaces and 24" in compatibility
    assert "R launcher exit: 0x00000000" in compatibility
    tools = json.loads((results / "style-adoption-tooling.json").read_text(encoding="utf-8"))
    assert tools["style_exit"] == tools["python_tests_exit"] == 0
    assert tools["source_unchanged_after_style_check"]
    assert tools["pdfs_unchanged"] and tools["source_matches_checked_copy"]
    demos = (results / "style-adoption-demos-demos.log").read_text(encoding="utf-8")
    assert demos.count(" PASS") == 11 and "R launcher exit: 0x00000000" in demos
    minimal = (results / "style-adoption-minimal-minimal.log").read_text(encoding="utf-8")
    assert "R launcher exit: 0x00000000" in minimal
    scope = json.loads((root / ".opencode/style-scope.json").read_text(encoding="utf-8"))
    contracts = [row for row in rows if row["file"] in (
        "test-conversion-contracts.R", "test-row-binning-contracts.R",
        "test-selector-utility-contracts.R")]
    lines = [
        "# Modern R development adoption", "", "Verified 2026-10-16; statart 0.2.0.9000.", "",
        "## Verified results", "",
        f"- Full suite: {len(rows):,} blocks, {totals['passed']:,} passing expectations; "
        "zero failures, errors, uncaptured warnings or skips.",
        "- Protected fresh native install, source build and R CMD check --no-manual exit 0; Status: OK.",
        f"- {len(scope['files'])} adopted handwritten R files pass pinned Air 0.12.0, parsing and lintr 3.4.0 checks.",
        "- Three Python scope tests pass, including Unicode Git paths and generated/archive path exclusions.",
        "- All 40 exported interfaces and 24 output/visibility/diagnostic records match the pre-adoption installation.",
        "- Eleven demos execute successfully; required-dependency-only smoke checks pass.",
        "- Checked package sources/tests/help match the working sources byte-for-byte; both earlier PDFs are unchanged.", "",
        "## Changes and compatibility", "",
        "CONTRIBUTING.md owns the coding standard. Shared read-only tooling checks an explicit scope; "
        "formatting remains deliberate and uses a single authority. New PR R sources must enter scope.", "",
        "Conversions cache their existing classification and use direct calls; type dispatch remains "
        "compatible with the previous implementation. Missing-value wrappers remain delegated. "
        "Documentation now states casting, metadata, SPSS/tagged missingness and precision behavior precisely.", "",
        "Row/binning, selection/type and utility implementations received surgical readability changes. "
        "Tests pin interval boundaries, missing rows, types, warnings, promise evaluation, visibility and RNG effects. "
        "Accepted summary/tabulation/inspection catalogues remain intact. Fifteen previously uncaptured warnings "
        "are now asserted; the old empty interval-width test now checks exact assignments.", "",
        "Six help topics were regenerated from roxygen sources. Maintained demos and verification R scripts "
        "are formatted and demos load the fresh installed package, replacing repeated development loads. "
        "The timer demo explicitly qualifies its private formatting helper. The report generator "
        "supports --index-only, replacing temporary index-extraction "
        "workarounds without rerunning demos. Historical scripts and result artifacts are preserved.", "",
        "No exported names, signatures/defaults, runtime Imports count (13), R minimum (4.1), "
        "or established statistical/output contracts changed.", "",
        "## Dependency constraints", "",
        "These floors cover APIs and documented casting behavior, not tested oldest-version combinations.", "",
        "| Dependency | Floor | Reason/source |", "| --- | --- | --- |",
        "| purrr | 1.0.0 | [list_rbind](https://purrr.tidyverse.org/news/index.html#purrr-100) |",
        "| stringr | 1.5.0 | [str_split_1](https://stringr.tidyverse.org/news/index.html#stringr-150) |",
        "| tibble | 3.0.0 | [as_tibble_col](https://tibble.tidyverse.org/news/index.html#tibble-300) |",
        "| tidyr | 1.2.0 | [strict replacement casting](https://tidyr.tidyverse.org/news/index.html#tidyr-120) |",
        "| vctrs | 0.6.0 | [obj_is_vector](https://vctrs.r-lib.org/news/index.html#vctrs-060) |",
        "| Rfast | 1.9.6 | [released rowMedians na.rm API](https://raw.githubusercontent.com/cran/Rfast/1.9.6/R/median.R) |", "",
        "## New focused contract cases", "",
        f"{len(contracts)} new blocks with {sum(number(row['passed']) for row in contracts)} passing expectations. "
        "These complement retained suites and exact-value improvements; no fixed scenario quota was used.", "",
        "| File | Contract | Expectations |", "| --- | --- | ---: |",
    ]
    for row in contracts:
        lines.append(f"| {row['file']} | {row['test'].replace('|', '/')} | {row['passed']} |")
    lines.extend([
        "", "## Review and limits", "",
        "Cross-review covered changes outside each specialist's authored scope. Review fixes include "
        "NUL-delimited Unicode Git paths, canonical generated/archive path exclusions, and the tidyr casting floor. "
        "The path defects were reproduced by failing tests before fixes; the final scope tests pass. "
        "Installed-package demos first exposed the timer helper lookup, then all eleven passed after qualification.", "",
        "Current execution is Windows R 4.6.0. CI now explicitly includes R 4.1, alongside existing "
        "Windows/macOS/Linux and development-R checks, but remote CI has not run. Old dependency combinations "
        "and actual interactive viewer rendering remain unverified. Known locale/display and legacy binning "
        "boundaries documented in prior acceptance reports remain applicable.", "",
        "The /style workflow is check-only. Website deployment requires an explicit manual deploy input. "
        "No push, merge, website deployment, package publication or release was performed.", "",
        "## Reproduction", "", "```powershell",
        "python .opencode/workflows/check_style.py --base ac7cea3",
        "python -m unittest discover -s .opencode/tests -p test_style_workflow.py",
        "python .opencode/workflows/verify_package.py --check --prefix .opencode/results/style-adoption-final",
        "python .opencode/workflows/verify_package.py --minimal --prefix .opencode/results/style-adoption-minimal",
        "python .opencode/workflows/verify_package.py --demos --prefix .opencode/results/style-adoption-demos",
        "python .opencode/workflows/summarize_style_adoption.py", "```", "",
        "The differential verifier takes an installed library, baseline/compare mode and a record path. "
        "The preserved pre-adoption record is style-adoption-baseline.rds; regenerate it from ac7cea3 "
        "when intentionally changing the baseline. Windows R invocations must use the protected launcher.", "",
        "Detailed execution logs, CSVs and tooling evidence are under .opencode/results/style-adoption-*.",
    ])
    report = root / ".opencode/reports/project_status_r_style_adoption_2026-10-16.md"
    report.write_text("\n".join(lines) + "\n", encoding="utf-8")
    print(report, "blocks", len(rows), "expectations", totals["passed"])


if __name__ == "__main__":
    main()
