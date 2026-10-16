# Agent Guidelines

## 1. Project Overview

This project (`statart`) aims to provide Stata-like functions in R for users familiar with Stata commands.
**Goal:** Bridge the gap between Stata's simplicity and R's flexibility, particularly where the Tidyverse framework might be less intuitive for Stata users.

### Development entry points

* Read [DEVELOPMENT.md](DEVELOPMENT.md) for the current inventory, verified baseline, and restart roadmap.
* Follow [CONTRIBUTING.md](CONTRIBUTING.md) for source locations and verification workflow.
* Current status lives in `.opencode/QUICK_STATUS.md`, `.opencode/PROBLEMS.md`, and `.opencode/TODO.md`; historical completion notes are not current verification.
* Git history is restored: `master` tracks `origin/master` at https://github.com/socimh/statart.git. Preserve uncommitted local changes and inspect status before Git operations.
* On Windows, every R/Rscript command must use `python C:/Users/socimh/.codex/scripts/run_r_safe.py -- ...`, including tests and documentation generation. Inspect exit status and stderr.

## 2. Core Principles

* **Stata-Like Naming**: Prioritize function names that match Stata commands (e.g., `tab`, `summarize`, `codebook`, `ds`, `timer`, `summ`).
* **Functionality Focus**: Implement functions that replicate key Stata behaviors (e.g., `timer` for timing code, `tab` for frequency tables).
* **Preservation**: Do not permanently delete code. If a function is deemed unnecessary for the core package, move it to the `extra_functions/` directory.

## 3. Mandatory Rules (Applied Automatically)

Agents must follow the rules in `.opencode/rules/` (the former `.trae/rules/` directory is absent). Explicit current user instructions override older rule files, including their automatic push requirement:

* [R Package Maintenance](.opencode/rules/00-core-r-package.md): Standards for editing R packages, preserving API, and safe edits.
* [Git Workflow](.opencode/rules/01-git-workflow.md): Commit conventions. Push, merge, publish, or release only when explicitly requested.
* [Autonomy &amp; Notifications](.opencode/rules/02-autonomy-and-notifications.md): Guidelines for autonomous action and status updates.
* [Generated Files](.opencode/rules/03-generated-and-results-files.md): Rules for handling generated code and artifacts.

## 4. Specific Guidelines

Refer to these rules when working on specific areas:

* [Testing](.opencode/rules/10-tests.md): Guidelines for adding and updating tests.
* [Function Reports](.opencode/rules/11-function-reports.md): Guidelines for generating verification reports for functions.
* [Documentation](.opencode/rules/20-docs.md): Standards for maintaining documentation alignment.

## 5. Default Operating Mode

* **Default to action**: Do not ask for permission for routine repository-local work (reading, editing, testing, docs, file operations, commit/push).
* **Ask only when**:
  1. Requirements are materially ambiguous.
  2. Secrets/authentication are needed.
  3. The action is unusually destructive.
  4. The action has consequences beyond this repo/branch.
  5. The task would cause a major public API or project-direction change.
* **If blocked**: Do the next safe step instead of stopping early.

## 6. Status Notifications

* **Before high-impact actions**: Send a brief console/chat note.
  * Deleting files/folders.
  * Moving or renaming files.
  * Overwriting generated outputs.
  * Major refactors.
  * Committing and pushing.
* **Keep notices short and factual**. Do not store these notices in a file unless explicitly asked.

## 7. Generated and Result Files

* **Source of Truth**: Treat generated files and result artifacts as derived outputs.
* **No Manual Edits**: Do not manually edit generated or result files unless explicitly asked. Edit the real source, then regenerate.
* **R Package Specifics**:
  * Do not hand-edit `man/*.Rd` or `NAMESPACE`. Update roxygen comments and regenerate.
  * Do not manually patch outputs in `results/`, `output/`, `tables/`, `figures/`, `cache/`.
  * Do not manually patch generated data files (`.csv`, `.rds`, etc.) derived from scripts.

## 8. Verification Before Completion

* **Verify**: Do not claim completion without at least one concrete verification step.
* **Methods**:
  * Relevant tests.
  * Focused package commands.
  * Regeneration checks.
  * Lint/check steps.
* **Scope**: Verify bug fixes address the root cause; verify doc changes match behavior.

## 9. Editing Boundaries

* **Focus**: Do not make unrelated cleanup edits or reformat unrelated files.
* **External Code**: Do not edit third-party or copied external code unless required.
* **Deprecation**: Preserve deprecated-but-useful code in `extra_functions/`.
* **Location**: Keep package logic in `R/`, tests in `tests/`, and generated docs from source.

## 10. Directory Structure

### `.opencode/` - Agent Workspace
* **`.opencode/demos/`**: Demo scripts (`.R` files) showing actual function output
* **`.opencode/reports/`**: **Markdown reports** showing real function output
  * [INDEX.md](.opencode/reports/INDEX.md) - Master index of all function reports
  * [report_*.md](.opencode/reports/) - One report per function with actual output examples
* **`.opencode/tests/`**: Test scripts (`.R` files) - executable verification scenarios
* **`.opencode/workflows/`**: Automation scripts
* **`.opencode/PROBLEMS.md`**: Current bugs and issues
* **`.opencode/TODO.md`**: Task list and completed work
* **`.opencode/PROGRESS.md`**: Action log (last 3 entries)

### Key Workflow
1. Check `.opencode/reports/INDEX.md` for function examples
2. Read `report_[function].md` to see actual output
3. Run `.opencode/demos/demo_[function].R` to regenerate
4. Fix issues in `R/` code
5. Regenerate reports: `make demo-reports`

## 12. Testing and Demo Reports

### Two-Part System

**1. Unit Tests (testthat)**
- Located in `tests/testthat/`
- Run with `make test` or `make test-<name>`
- Validates correctness with pass/fail assertions

**2. Demo Reports (Actual Output)**
- Located in `.opencode/demos/` and `.opencode/reports/`
- Run with `make demo-reports`
- Shows **real function output**, not just pass/fail
- Examples: "Time spent: 1.02s", data frames, tables

### Quick Commands (via Makefile)
```bash
make test              # Run all testthat tests
make demo-reports      # Generate reports with actual function output
make test-full         # Run both tests and demo reports
make test-<name>       # Run specific test file (e.g., make test-summ)
make clean             # Remove all generated files
```

### Demo Report Structure
- **Location**: `.opencode/reports/`
- **Files**:
  - `INDEX.md` - Overview of all functions with links
  - `report_[function].md` - Actual output examples
- **Features**:
  - Shows real console output (tables, messages, return values)
  - Multiple examples per function
  - Copy-paste ready code

### Workflow Script
- `.opencode/workflows/generate_demo_reports.R` - Runs demo scripts, captures output, creates markdown

### Adding New Function Reports
1. Create `.opencode/demos/demo_[function].R`
2. Add examples showing actual output
3. Run `make demo-reports`
4. View `.opencode/reports/report_[function].md`

## 11. Task Management

**Mandatory Update Rule**: These tracking files MUST be updated at the end of every task or session to ensure the project state is always current.

* **Known Issues**: Check and update [.opencode/PROBLEMS.md](.opencode/PROBLEMS.md). Add new bugs found; mark resolved bugs as done.
* **Task List**: Track progress in [.opencode/TODO.md](.opencode/TODO.md). Mark completed items; add new requirements.
* **Progress Log**: Log major actions in [.opencode/PROGRESS.md](.opencode/PROGRESS.md). Summarize what was done, what files changed, and what was verified.
* **Reports**: Add new markdown reports to `.opencode/reports/` and update INDEX.md.

## 11. Helper Agents

Delegate specialized tasks to these agents:

* **`r-release-auditor`**: Use before tagging a release, publishing a new version, or for final package validation .
* **`r-package-docs`**: Use when function behavior, arguments, or exports change. Updates roxygen comments and regenerates documentation.
* **`r-package-qa`**: Use for validating code changes, reproducing bugs, designing tests, and checking for regressions.
* **`r-package-reviewer`**: Use before refactors to analyze side effects, identify API risks, or plan safe changes.
