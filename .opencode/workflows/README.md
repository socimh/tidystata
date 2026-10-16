# Automated Testing Workflows

This directory contains automation scripts for the statart package testing system.

## Quick Start

### Run Tests for a Specific Function

```r
# Run tests for esttab
Rscript .opencode/tests/test_esttab_automated.R

# Run tests for summ
Rscript .opencode/tests/test_summ.R

# Run tests for tab/codebook
Rscript .opencode/tests/test_tab_codebook.R
```

### View Test Reports

All human-readable reports are in `.opencode/reports/`:

```bash
# View master index
open .opencode/reports/INDEX.md

# View specific report
open .opencode/reports/report_esttab_latest.md
open .opencode/reports/report_summ.md
```

## Directory Structure

```
.opencode/
├── reports/                    # Markdown reports (human-readable summaries)
│   ├── INDEX.md               # Master index of all reports
│   ├── report_esttab_latest.md
│   ├── report_summ.md
│   ├── report_tab.md
│   ├── report_cut_row.md
│   └── report_timer_fre.md
│
├── tests/                      # Test scripts (.R files)
│   ├── test_esttab_automated.R
│   ├── test_summ.R
│   ├── test_tab_codebook.R
│   ├── test_cut_row.R
│   └── test_timer_sselect_fre.R
│
└── workflows/                  # Automation scripts
    ├── esttab_automation.R    # Main orchestrator (legacy)
    ├── watch_esttab.R         # File watcher daemon
    └── lib/
        ├── test_runner.R      # Core test execution
        ├── error_handler.R    # Error capture & logging
        └── problem_updater.R  # Auto-update PROBLEMS.md
```

## Available Reports

| Report | Function | Scenarios | Status |
|--------|----------|-----------|--------|
| [report_esttab_latest.md](../reports/report_esttab_latest.md) | `esttab()` | 26 | ✅ Complete |
| [report_summ.md](../reports/report_summ.md) | `summ()`, `tabstat()` | 27 | ✅ Complete |
| [report_tab.md](../reports/report_tab.md) | `tab()`, `tab1()`, `fre()`, `codebook()` | 26 | ✅ Complete |
| [report_cut_row.md](../reports/report_cut_row.md) | `cut_quantile()`, `row_*` | 22 | ✅ Complete |
| [report_timer_fre.md](../reports/report_timer_fre.md) | `timer()`, `s_select()`, `fre()` | 22 | ✅ Complete |

## Manual Operations

### Run All Tests

```r
# Run all test scripts
for (f in list.files(".opencode/tests", pattern="test_.*\\.R", full.names=TRUE)) {
  message("\n=== Running: ", f, " ===")
  source(f)
}
```

### Check Watcher Status

```r
source(".opencode/workflows/watch_esttab.R")
watch_esttab_status()
```

### Generate New Report

After fixing a function and creating tests:

1. Create test script: `.opencode/tests/test_[function].R`
2. Run tests and verify all pass
3. Create markdown report: `.opencode/reports/report_[function].md`
4. Update `.opencode/reports/INDEX.md`
5. Commit both files

## Configuration

Edit `watch_esttab.R` to change:
- `watch_interval`: Check frequency (default: 2 seconds)
- `esttab_file`: Path to source file
- `verbose`: Console output level

## Troubleshooting

### "later package not found"
```r
install.packages("later")
```

### "Could not find esttab.R"
Check file paths and update if needed.

### Tests not running
Ensure all required packages are installed:
```r
install.packages(c("jsonlite", "digest", "dplyr", "lme4", "broom", "broom.mixed"))
```

### PROBLEMS.md not updating
Check file permissions or run manually:
```r
source(".opencode/workflows/lib/problem_updater.R")
update_problems_md()
```

## For Other Agents

If you're fixing an issue:

1. **Find the issue** in `.opencode/PROBLEMS.md`
2. **Read the report** in `.opencode/reports/report_[function].md` to understand what was tested
3. **Run the tests**:
   ```r
   source(".opencode/tests/test_[function].R")
   ```
4. **Fix the issue** in `R/[file].R`
5. **Re-run tests** to verify all pass
6. **Update the report** if behavior changed significantly
7. **Update PROBLEMS.md** to mark issue as resolved
