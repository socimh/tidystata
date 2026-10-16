"""Summarize saved failures without rerunning tests or changing package behavior."""
from pathlib import Path
from collections import Counter, defaultdict
import csv

ROOT = Path(__file__).resolve().parents[2]
SOURCE = ROOT / ".opencode/results/milestone-retained-final-details.csv"
SUMMARY = ROOT / ".opencode/results/milestone-retained-final.csv"
REPORT = ROOT / ".opencode/reports/project_status_failure_triage_2026-10-16.md"


def classify(file, test, messages):
    if any(text in messages for text in (
        "unused argument (na_values", "Tibble columns must have compatible sizes",
        "cannot take a sample larger than the population")):
        return "Invalid fixture", "Repair construction before calling statart; preserve the intended scenario."
    if file == "test-s_try.R":
        return "Incorrect expectation", "These expressions succeed or warn; s_try detects errors, not false results or warnings."
    if test in ("browse: works in dplyr pipeline", "timer: works with multiple pipes"):
        return "Incorrect expectation", "Input is mtcars/data.frame; do not require tibble class from a class-preserving pipeline."
    if test in ("tab1: .desc=TRUE applied to all variables", "fre1: .desc applied to all variables in list", "tab1: frequency ties handling in sorting"):
        return "Incorrect expectation", "Check actual frequency counts; .desc sorts frequency, not category value."
    if test in ("tab: factor with NA level explicitly set", "tab1: factor with NA vs character with NA"):
        return "Incorrect expectation", "An explicit NA factor level differs from a missing factor code."
    if test == "timer: timing is reasonable compared to system.time":
        return "Environmental flake", "Saved base-R probe reproduced the strict elapsed-time threshold failure."
    if "Names must be unique" in messages and "pivot_wider" in messages:
        return "Likely implementation defect", "Resolve pivot category/row-name collisions without silently losing categories."
    if test in ("summ: empty data frame with columns", "s_unit: units object"):
        return "Likely implementation defect", "Valid edge input reaches an NA conditional/predicate; reproduce narrowly before fixing."
    if file == "test-tab.R" and test in (
        "tab: group with empty groups after filtering", "tab: boolean with OR and AND combined",
        "tab: boolean expression creating all FALSE", "tab: boolean with is.na() function",
        "tab: boolean with %in% operator"):
        return "Incorrect expectation", "The API tabulates computed variables; filtering requires a separate filter step."
    if test == "fre: Total with missing values included":
        return "Incorrect expectation", "Match the grand Total label exactly; broad Total matching also selects Valid Total."
    unresolved = {
        "variables_search: single character with ?", "variables_search: numeric range",
        "summ: all available statistics", "tabstat: custom statistics",
        "summ: all NA variable handling", "tab: deeply nested list columns should fail gracefully",
        "tab: starts_with with no matches", "tab: gracefully handle data.frame with no columns",
    }
    if test in unresolved:
        return "Contract review", "Decide supported statistics/all-missing, search matching, list input or empty selection semantics before editing."
    return "Incorrect expectation", "Source/test review identifies a mismatch in dimensions/metadata, totals, classes, selection, NA handling or local warning capture; reproduce before repairing assertions."



def main():
    with SOURCE.open(encoding="utf-8", newline="") as stream:
        rows = list(csv.DictReader(stream))
    with SUMMARY.open(encoding="utf-8", newline="") as stream:
        summary = list(csv.DictReader(stream))
    groups = defaultdict(list)
    for row in rows:
        if row["type"] in ("expectation_failure", "expectation_error"):
            groups[row["file"], row["test"]].append(row)
    assert sum(int(r["failed"]) for r in summary) == 94
    assert sum(r["error"] == "TRUE" for r in summary) == 22
    assert len(groups) == 104 and sum(map(len, groups.values())) == 116
    items = []
    for (file, test), evidence in sorted(groups.items()):
        messages = "\n".join(row["message"] for row in evidence)
        category, action = classify(file, test, messages)
        items.append((file, test, category, action, len(evidence)))
    counts = Counter(item[2] for item in items)
    lines = ["# Saved failure triage and repair queue", "", "Prepared 2026-10-16 from the 2026-10-15 retained-suite evidence. No full-suite rerun or function fixes are implied.", "", "## Evidence and counting", "", "The saved suite contains 94 failed expectations and 22 error blocks across 104 distinct file/test identities. The 116 failure/error detail rows reconcile with those two measures; identities can contain multiple failed expectations. Warnings (54) and skips (one) remain separate and are not classified as failures here.", "", "Sources: [summary](../results/milestone-retained-final.csv), [details](../results/milestone-retained-final-details.csv), and [milestone report](milestone_status_0.2.0.9000.md).", "", "Classifications use saved messages plus source/test inspection. Likely defects require focused reproduction; Contract review is an explicit unresolved decision, not a confirmed source bug. No tests are disabled or changed by this report.", "", "| Classification | Distinct test identities |", "| --- | ---: |"]
    lines += [f"| {category} | {count} |" for category, count in sorted(counts.items())]
    assert counts == {"Invalid fixture": 11, "Incorrect expectation": 77, "Likely implementation defect": 7, "Contract review": 8, "Environmental flake": 1}
    lines += ["", "## Source review findings", "", "A read-only package QA review traced all identities to current tests and sources. Invalid fixtures fail before statart is called. The 77 incorrect expectations account for 88 failed expectations and one test-side error; 11 fixture identities account for 11 errors; seven likely defects account for seven errors; eight contract decisions account for five failures and three errors; the flake accounts for one failure.", "", "- Five tab2/fre2 pivot collisions occur in R/tab-helpers.R:329-350 when category names duplicate the row variable name.", "- Empty summary input reaches a NaN predicate in R/summ-helpers.R:67-72 and :124-129. Units handling reaches an NA conditional in R/s_type.R:17-29.", "- Summary decisions: all-missing input, aliases missing/p25/p50/p75 versus miss_n/q1/median/q3, and support for sum. Search decisions: whole-name versus substring regex matching. Tabulation decisions: list columns and empty selections/dataframes.", "- Stale expectations include an extra n column in cross-tables, missing percentage/cumulative metadata in dimension counts, Date classes after textual Total rows, invalid Total-row matching, nonexistent result$x access, and a warning test assigning result with <<-.", "- Four s_try expressions succeed or warn rather than error; mtcars pipelines preserve data.frame class. Boolean tab arguments create measured values rather than filtering observations.", "", "## Repair order", "", "1. Repair definite fixture construction and incorrect expectations in small reviewed batches. Preserve scenarios and distinguish assertions from intended behavior. Run only affected test files initially.", "2. Summaries: settle empty/all-missing data, supported statistics, and date/duration output contracts; reproduce the empty predicate failure.", "3. Tabulation/frequencies: settle cross-table dimensions and count-column policy, totals and types, then fix pivot name collisions. Many saved expectations assume an extra n column; do not add one solely to satisfy those tests.", "4. Names/types/utilities: resolve regex expectations, units handling, warning capture, and timing fixtures. Treat warning behavior separately from error behavior.", "5. Run broader regression/check validation once affected families pass; retain the 622 focused scenarios as regression coverage.", "", "## Complete identity inventory", "", "| File | Test | Detail rows | Classification | Next action |", "| --- | --- | ---: | --- | --- |"]
    escape = lambda text: text.replace("|", r"\|").replace("\n", " ")
    lines += [f"| {file} | {escape(test)} | {number} | {category} | {action} |" for file, test, category, action, number in items]
    lines += ["", "## Reproduction", "", "Regenerate this report with `python .opencode/workflows/triage_saved_failures.py`. It reads saved CSV files only. For subsequent targeted R checks, use the protected workflows in DEVELOPMENT.md and retain fresh results under a new prefix.", ""]
    REPORT.write_text("\n".join(lines), encoding="utf-8")
    print(f"104 identities / 116 detail rows accounted for; classifications: {dict(counts)}")
    print(REPORT)


if __name__ == "__main__":
    main()
