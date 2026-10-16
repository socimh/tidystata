# Developing statart

Current development version: **0.2.0.9000**. The package focuses on Stata-inspired
exploration and data preparation. This is the first stabilization milestone for
a future 0.3.0 release.

## Active package

The namespace exports 40 objects: 39 functions and the `%>%` operator.

| Area | Public functions |
| --- | --- |
| Tabulation | tab, tab1, tab2, fre, fre1, fre2 |
| Summaries | summ, tabstat |
| Variable inspection | codebook, browse, ds, ds_as_column, names_as_column, variables, variables_search |
| Row calculations | row_mean, row_sum, row_min, row_max, row_median, row_var, row_sd, row_unique, row_miss, row_non_miss |
| Conversion | as_character, as_numeric, na_if_value, value_if_na |
| Selection and types | s_select, s_match, s_type, s_unit |
| Binning | cut_quantile, cut_length, cut_breaks |
| Utilities | timer, set_seed, s_try |

Both bundled datasets, lifeexp and starwars, remain. Required Imports decreased
from 33 to 13; cpp11 and the existing native/Rfast backend remain. Flextable is
optional. The local installed dependency graph requires 37 non-base/recommended
packages, or 38 including statart, compared with 124 dependencies previously.
The counts describe dependency breadth, not download size.

Four wrappers are retired: read_data, write_data, esttab, and codebook_detail.
Their implementations, original help, dedicated tests, and demos are preserved
under extra_functions and excluded from builds and active discovery. See
[MIGRATION.md](MIGRATION.md) for direct alternatives and breaking changes.
Retained exploration/preparation helpers remain exported; MIGRATION.md also maps earlier upstream helper removals.

## Current verification

- [Milestone contract report](.opencode/reports/milestone_contracts_0.2.0.9000.md):
  622 passing scenarios and 4,098 passing expectations, with no failures,
  errors, warnings, or skips. Coverage includes the independent review fixes.
- A fresh native installation succeeds. A separate smoke check loads the core
  with required dependencies only and verifies the error for absent formatting.
- All ten active demos execute successfully and have versioned output reports.
- Package checking passes installation, namespace/dependency declarations,
  documentation, compiled code, and examples. Full-suite legacy failures still
  prevent a clean release check; use the milestone status report for totals.
- [Original baseline](.opencode/reports/project_status_2026-10-15.md) is historical:
  134 failed expectations and 38 error blocks before this milestone.

No coverage percentage or release-readiness claim is implied. Test blocks,
expectations, warnings, and error blocks are different counting units.

## Behavior established in this milestone

fre/fre2 return tibbles; fre1 returns a list. Rich formatting is explicit and
optional. Grouped tabulation retains missing keys and calculates totals within
each group. Reserved names are renamed consistently, including metadata names.
Character conversion preserves positions and parsing diagnostics. Variable
labels are read from attributes, and searches inspect those labels.

All row helpers return atomic vectors and preserve inputs. Missing values are
ignored in numeric summaries; all-missing rows yield NA except sums yield zero.
Variance/SD use sample statistics, and unique counts missing once. Explicit
pick(), dataframe arguments, and dataframe expressions work inside mutate().
Quantile binning keeps ties together, collapses duplicate cutpoints with a
warning, and does not claim exact equivalence to Stata xtile.

## Working commands

Run from the project root. The Python workflow calls the protected Windows R
launcher for every R command, builds native code in a temporary source copy,
collects real test results, and returns a failure status when tests fail.
Original compiled artifacts and datasets are preserved.

```powershell
# Entire retained suite (known legacy failures remain).
python .opencode/workflows/verify_package.py

# Focused milestone regressions, fresh native build, and scenario report.
python C:/Users/socimh/.codex/scripts/run_r_safe.py -- Rscript .opencode/tests/verify_milestone.R

# A single existing family.
python .opencode/workflows/verify_package.py --filter type_conversion

# Required-dependencies-only smoke check, including absent optional formatting.
python .opencode/workflows/verify_package.py --minimal

# Fresh source build, full suite, and R CMD check.
python .opencode/workflows/verify_package.py --check

# Versioned actual-output reports; retains historical reports.
make demo-reports
```

make test, make test-results, and make test-<family> use the same protected,
isolated workflow. Results are saved under .opencode/results. Paths/logs identify
temporary build copies and check output. The workflow scopes LC_ALL=C to child
processes because this Windows R rejects the inherited C.UTF-8 locale.

Edit logic and roxygen comments in R, native logic in src/*.cpp, tests under
tests/testthat, README.Rmd for README content, and _pkgdown.yml for website
organization. Regenerate help, namespace, README, and report indexes from their
sources. Do not hand-edit generated outputs. Source requires R >= 4.1 and a
matching build toolchain; the minimum version has not been exercised here.

## Next milestone

1. Resolve remaining invalid fixtures separately from implementation defects.
2. Stabilize summary/date output contracts and unsupported-statistic errors.
3. Reconcile cross-tabulation shape, category-name collisions, and totals tests.
4. Review selection evaluation and remaining name/type/utility discrepancies.
5. Reach a passing retained suite and clean package check before release.

Git history was restored on 2026-10-15 from https://github.com/socimh/statart.git.
Local master tracks origin/master. The 2026-10-16 development checkpoint preserves the newer local work with known test failures documented.
No push, publication, or release is included in this milestone.

## Stabilization preparation checkpoint

Prepared 2026-10-16: the local development checkpoint preserves source, tests,
archives, documentation and selected verification evidence. Other generated
results remain on disk and are ignored; see .opencode/results/README.md.
MIGRATION.md now covers all 15 removed upstream exports and the timer rename.

The [saved-failure triage](.opencode/reports/project_status_failure_triage_2026-10-16.md)
accounts for 104 identities: 11 invalid fixtures, 77 incorrect expectations,
seven likely defects, eight contract decisions, and one environmental flake.
These are classifications of earlier results, not a new passing suite.
Start with fixture/assertion repairs, then summaries, tabulation, and utilities.
No function behavior or test expectations were changed in this preparation pass.
A fresh isolated installation and required-dependency smoke check passed on
2026-10-16. Full-suite and release-check failures remain outstanding.

## GitHub maintenance

Verified 2026-10-15: origin uses authenticated HTTPS for socimh/statart, master
tracks origin/master, and GitHub CLI authenticates as socimh with admin access.
Commit identity, the repository-local credential helper, and the exact Git trust
entry are configured. No additional setup is needed. After a successful fetch,
local and remote master both point to 12709f6ab8398ddeedab40def10adfc3c7ebefd4;
there are no incoming commits to reconcile.

Use `git status --short --branch`, `git fetch origin`, and
`git diff origin/master` to inspect tracked work. Also inspect
`git ls-files --others --exclude-standard`, to catch new source, tests, archives, reports, and workflows before committing. Preserve that work before
switching branches or integrating changes. See the
[verified comparison](.opencode/reports/project_status_git_comparison_2026-10-15.md).

The upstream migration mapping and result-artifact versioning policy are now documented.
Before publishing, address the recorded whitespace findings and resolve the known
package test failures. The Git
connection is ready for maintenance; the package is not release-ready. Push,
merge, and release require an explicit maintainer request.

## Entry points

- [CONTRIBUTING.md](CONTRIBUTING.md) and [AGENTS.md](AGENTS.md).
- [Current issues](.opencode/PROBLEMS.md), [tasks](.opencode/TODO.md), and
  [progress](.opencode/PROGRESS.md).
- [Report index](.opencode/reports/INDEX.md), with current and historical output.
- [Approved scope and execution ledger](.opencode/plans/lean-core-milestone.md).
