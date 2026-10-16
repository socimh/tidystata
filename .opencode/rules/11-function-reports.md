# Function Verification Reports

## Requirement

For every modified or new function, you must generate a verification report demonstrating that it works error-free on sample data.

**Rigorous Testing Rule**:
*   Test at least **20 different scenarios** with diverse settings to ensure the function is robust.
*   Cover edge cases, different input types, argument combinations, error conditions, and boundary values.

## Directory Structure

```
.opencode/
├── reports/           # Markdown reports ONLY (human-readable summaries)
│   ├── INDEX.md                 # Master index of all reports
│   ├── report_[function].md     # One report per function/group
│   └── ...
├── tests/             # Test scripts (.R files)
│   ├── test_[function].R        # Executable test scripts
│   └── ...
└── workflows/         # Automation scripts
    └── lib/
```

## Process

### 1. Create Test Script
*   Create a standalone R script in `.opencode/tests/` (e.g., `.opencode/tests/test_esttab.R`).
*   Load the package (or source relevant files) and necessary libraries.
*   Use **pkgdown examples** or standard datasets (`mtcars`, `iris`, `sleepstudy`, `starwars`, etc.).
*   Implement **20+ distinct test cases** (numbered or labeled) to verify behavior under various conditions.
*   Script should output PASS/FAIL for each scenario.

### 2. Execute the Script
*   Run the script using `Rscript` or an interactive R session.
*   Capture the output (both stdout and stderr).
*   Verify all scenarios pass before proceeding.

### 3. Generate Markdown Report
*   Create a Markdown file in `.opencode/reports/` (e.g., `.opencode/reports/report_esttab.md`).
*   Include:
    *   **Function Name**: The function being tested.
    *   **Date**: When the test was run.
    *   **Issues Fixed**: Brief description of what was fixed.
    *   **Summary**: PASS/FAIL counts, execution time, success rate.
    *   **Detailed Results**: Table of test scenarios by category.
    *   **Changes Made**: Files modified and backward compatibility notes.

### 4. Update INDEX.md
*   Add the new report to `.opencode/reports/INDEX.md` with status and link.

## Storage Rules

*   **`.opencode/reports/`**: Markdown files ONLY. No .R scripts, no .txt files.
*   **`.opencode/tests/`**: Test scripts (.R files) and output files (.txt).
*   Do not delete reports; they serve as a permanent record of verification.
*   If a function is modified again, append to or update the existing report.

## Report Template

```markdown
# Verification Report: [function_name]()

**Date**: YYYY-MM-DD  
**Function**: `function_name()` - Brief description  
**Test Script**: `.opencode/tests/test_[function].R`  
**Total Scenarios**: XX  
**Execution Time**: ~X.X seconds  

## Summary

| Metric | Count |
|--------|-------|
| **PASS** | XX |
| **FAIL** | 0 |
| **Success Rate** | 100% |

## Issues Fixed

### Issue ID: Brief Title (Severity)
**Problem**: Description of the issue  
**Solution**: How it was fixed  
**Status**: ✅ Fixed

## Test Results by Category

### Category Name (N tests)
| ID | Description | Status |
|----|-------------|--------|
| 1.1 | Test description | ✓ PASS |
| ... | ... | ... |

## Changes Made

**Files Modified**:
- `R/file.R`: Description of changes
- Backward compatibility notes
```

## Quick Reference

### View All Reports
Open `.opencode/reports/INDEX.md` for a master list.

### View Specific Report
Open `.opencode/reports/report_[function].md`

### Run Tests
```r
Rscript .opencode/tests/test_[function].R
```

### For Other Agents
If you're fixing an issue:
1. Read `.opencode/reports/report_[function].md` to understand what was tested
2. Run `.opencode/tests/test_[function].R` to verify current state
3. Make your fix
4. Re-run tests to confirm PASS
5. Update the report with your changes
