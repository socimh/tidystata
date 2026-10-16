# Run Control Configuration
# statart Package Improvement Workflow

MODE: RUN
BATCH_SIZE: 3
MAX_REVIEW_PASSES: 2
CURRENT_BATCH: 1
BATCH_TARGET: summ, tab1, codebook

## Execution Rules

### Breaking Changes
- Policy: PRAGMATIC
- Avoid breaking changes where possible
- Minor API additions allowed without permission (must be backward-compatible)
- Document any API changes in commit messages

### Documentation
- Run devtools::document() after each function
- Fix documentation errors immediately
- Update roxygen comments for any new parameters

### Verification
- Minimum 20 test scenarios per function
- Store tests in .opencode/reports/test_[function].R
- Generate report in .opencode/reports/report_[function].md
- All tests must pass before commit

### Commit Strategy
- Commit after each verified function
- Use conventional commit format: fix:, feat:, docs:, test:
- Push to current branch after each commit
- Include test results in commit description

### Pause Points
- After each function verification
- Before starting next function in queue
- On MODE change or BATCH completion
- When MAX_REVIEW_PASSES exceeded

## Current Session
Started: 2026-03-02
Target: Process summ function completely
Status: summ done. Running full queue automatically.
Next: tab1 → codebook → tab → cut_quantile → fre → row_min → timer → s_select
