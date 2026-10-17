"""Generate the row-type acceptance report from saved execution evidence."""

import csv
from pathlib import Path


def main():
    root = Path(__file__).resolve().parents[2]
    results = root / ".opencode/results"
    with (results / "row-types-final.csv").open(encoding="utf-8", newline="") as stream:
        rows = list(csv.DictReader(stream))
    totals = {
        name: sum(int(row[name]) if row[name].isdigit() else int(row[name] == "TRUE") for row in rows)
        for name in ("passed", "failed", "error", "warning", "skipped")
    }
    if any(totals[name] for name in ("failed", "error", "warning", "skipped")):
        raise RuntimeError(f"Acceptance is not clean: {totals}")
    cases = [row for row in rows if row["file"] == "test-row-types.R"]
    check = (results / "row-types-final-check.log").read_text(encoding="utf-8")
    examples = (results / "row-types-examples.log").read_text(encoding="utf-8")
    minimal = (results / "row-types-minimal-minimal.log").read_text(encoding="utf-8")
    demos = (results / "row-types-demos-demos.log").read_text(encoding="utf-8")
    style = (results / "row-types-style.log").read_text(encoding="utf-8")
    if "Status: OK" not in check:
        raise RuntimeError("R CMD check did not pass")
    for name, text in (("examples", examples), ("minimal", minimal), ("demos", demos), ("style", style)):
        if "R launcher exit: 0x00000000" not in text:
            raise RuntimeError(f"Missing successful protected exit: {name}")
    for stage in ("install", "tests", "build", "check"):
        if "R launcher exit: 0x00000000" not in (results / f"row-types-final-{stage}.log").read_text(encoding="utf-8"):
            raise RuntimeError(f"Final {stage} failed")
    lines = [
        "# Row calculations: type preservation and numerical acceptance", "",
        "Verified 2026-10-16 (America/New_York), development version 0.2.0.9000.", "",
        "## Outcome", "",
        "Logical extrema now return TRUE/FALSE, integer extrema retain integer storage, "
        "and compatible classed inputs retain meaningful classes. Unsupported or incompatible "
        "combinations fail before numeric coercion. Public names/formals remain unchanged.", "",
        "The existing C++ extrema and unique kernels remain. Classed extrema compare lossless "
        "vctrs ranks in C++, then slice the common original vector. Equality keys preserve "
        "integer64/list/complex identities for unique counts. Mean/sum use compiled base R. "
        "New C++ median and sample variance/SD kernels fix midpoint overflow, cancellation, "
        "and avoid overflowing variance before calculating a representable SD.", "",
        "Rfast is no longer used and was removed from Imports, reducing required direct "
        "imports from 13 to 12. Optional units >= 1.0.0 supplies public measurement-scale "
        "validation. No new required dependencies or public exports.", "",
        "## Verified results", "",
        f"- Full retained suite: **{len(rows):,} blocks / {totals['passed']:,} passing expectations**, "
        "zero failures, errors, uncaptured warnings or skips.",
        f"- New type/numerical contracts: **{len(cases)} blocks / {sum(int(row['passed']) for row in cases)} passing expectations**.",
        "- Fresh native installation, source build and R CMD check --no-manual: **Status: OK**.",
        "- Required-dependency-only smoke, all eleven demos and 92-file Air/parse/lintr checks pass.",
        "- Standalone installed verification: `.opencode/tests/verify_row_types.R`.", "",
        "Earlier failing probes are preserved locally. They reproduced logical type loss, "
        "unit stripping, SPSS metadata conflicts, integer64 precision loss, median overflow, "
        "negative/cancelled variance and ordered-factor order loss. Tests were observed "
        "failing before their fixes; raw evidence is retained.", "",
        "## Type and operation contract", "",
        "| Inputs | Extrema | Arithmetic | Counts |",
        "| --- | --- | --- | --- |",
        "| Plain logical/integer/double | Common logical/integer/double type | Double results | Integer |",
        "| Date/POSIXct | Compatible common calendar type | Mean/median retain same calendar family; sum/dispersion require explicit conversion | Integer |",
        "| difftime/hms | Compatible common duration type | Sum/mean/median/SD return difftime; variance requires an explicit numeric unit | Integer |",
        "| Compatible measured vectors | Common normalized units | Linear scales retain units; variance has squared units | Integer |",
        "| Affine/nonlinear measured scales | Compatible ordered extrema | Offset sum/SD/variance and all nonlinear arithmetic require explicit conversion | Integer |",
        "| integer64 | Exact original values, no double conversion | Explicit conversion required | Exact equality and missingness, integer outputs |",
        "| Labelled/SPSS | Underlying values; compatible metadata retained | Double after original missingness mask | Original missingness; incompatible metadata errors |",
        "| Character/ordered factors | C lexical order / compatible factor level order | Rejected | Compatible common-type equality |",
        "| Unordered factor/list/complex | Rejected | Rejected | Unique identity and original missingness |", "",
        "All columns must be one-dimensional. Counts do not flatten list elements; scalar "
        "missing list elements are missing, NULL/empty elements are observed. Zero-column "
        "inputs error. Zero-row and all-missing extrema use the selected prototypes, not "
        "observed values. All-missing sums remain zero; other arithmetic/extrema are missing. "
        "Sample dispersion requires two observed values. Unknown numeric classes are rejected "
        "rather than silently stripped. Ordered factors cannot be mixed with character text "
        "for extrema. Common SPSS metadata cannot turn an originally observed value into missing.", "",
        "## New executable cases", "",
        "| Case | Passing expectations |", "| --- | ---: |",
    ]
    lines.extend(f"| {row['test']} | {row['passed']} |" for row in cases)
    lines += [
        "", "## Selective real console output", "",
        "```text", *[line.rstrip() for line in examples.splitlines()], "```", "",
        "## Reproduction", "", "```powershell",
        "python .opencode/workflows/verify_package.py --check --prefix .opencode/results/row-types-final",
        "python .opencode/workflows/verify_package.py --minimal --prefix .opencode/results/row-types-minimal",
        "python .opencode/workflows/verify_package.py --demos --prefix .opencode/results/row-types-demos",
        "python .opencode/workflows/check_style.py",
        "python C:/Users/socimh/.codex/scripts/run_r_safe.py -- Rscript .opencode/tests/verify_row_types.R <fresh-library>",
        "python .opencode/workflows/summarize_row_types.py", "```", "",
        "## Boundaries before publication", "",
        "This is verified Windows R 4.6.0 execution and static portability review. R 4.1, "
        "other platforms/compilers, oldest dependency combinations and actual GUI viewing "
        "remain separate validation. No universal input-class or performance claim is made. "
        "No push, merge, publication, release or artifact deletion was performed. Both "
        "previously generated PDFs are preserved unchanged.", "",
    ]
    path = root / ".opencode/reports/project_status_row_types_2026-10-16.md"
    path.write_text("\n".join(lines), encoding="utf-8", newline="\n")
    print(path)
    print(totals)


if __name__ == "__main__":
    main()
