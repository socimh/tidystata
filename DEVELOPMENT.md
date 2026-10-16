# Developing statart

Current development version: **0.2.0.9000**. The package focuses on Stata-inspired
exploration and data preparation. This is the first stabilization milestone for
a future 0.3.0 release.

The [coding standard](CONTRIBUTING.md#r-coding-standard) defines modern R style,
compatibility boundaries and risk-based verification. Run `make style-check`
for the adopted source list; formatting is explicit and local. See the
[adoption ledger](.opencode/plans/r-style-adoption.md) for execution status.

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

## Repository layout and historical files

Current entry points are this guide, CONTRIBUTING.md, and
.opencode/QUICK_STATUS.md. Retired implementations remain in extra_functions;
[historical development files](extra_functions/development-history/README.md)
now hold the old build scratchpad, exploratory test/dependency scripts and
0.2.0 release notes. The archive is excluded from package builds.

Keep run_tests.R, README source/output, generated help, bundled datasets and
native sources. Local docs, IDE state, compiled objects and intermediate
results remain preserved and ignored by Git. make clean removes no files;
artifact deletion requires a separately reviewed, explicitly approved list.

## Current verification

Modern R adoption is verified locally: **16,492 passing expectations across
3,053 blocks, zero failures, errors, uncaptured warnings or skips**. Fresh native
installation, source build and `R CMD check --no-manual` pass with **Status: OK**.
All 90 adopted R files pass pinned Air/lintr/parsing checks. Required-dependency
smoke checks and all eleven demos pass; 40 public interfaces and 24 representative
outputs/visibility/diagnostic records match the pre-adoption installation.
See [adoption evidence](.opencode/reports/project_status_r_style_adoption_2026-10-16.md).

The four conversion helpers, row calculations, binning, selectors/types and
utilities now have risk-based contract review alongside retained suites.
Existing numbered catalogues remain intact. Fifteen formerly uncaptured warnings
are explicitly asserted; the empty interval-width test has real assertions.
Six API/behavior dependency floors are now declared, retaining 13 Imports,
40 exports, the R 4.1 minimum and existing public behavior. CI includes an
explicit R 4.1 job; remote platform/minimum-version execution remains pending.

## Earlier family milestones

The following figures retain earlier acceptance evidence; the full-suite totals
above are current.

Latest codebook/browse acceptance: **16,213 passing expectations across 2,996
blocks, zero failed expectations or error blocks**, with 15 test warnings and
one pre-existing empty test skipped. Fresh native installation, source build
and `R CMD check --no-manual` pass with **Status: OK**, no check errors,
warnings or notes. Earlier required-dependency smoke evidence remains valid;
dependencies and exports did not change. See [codebook/browse acceptance and all numbered cases](.opencode/reports/project_status_codebook_browse_acceptance_2026-10-16.md).

codebook() and browse() are locally accepted in the documented/headless scope:
297 blocks/985 expectations pass with zero failures/errors/uncaptured warnings
or skips, including 100 numbered scenarios each (200 cases/817 expectations).
Fixed global grouped inventories, SPSS/list missingness, structured-row counts,
Unicode names and repeated successful selector execution. Failed selection can
still execute callbacks before data-masking fallback; precompute random or
side-effecting expressions with mutate. Actual GUI viewing remains unverified.

ds, ds_as_column, names_as_column, variables and variables_search are locally
accepted: 548 blocks/1,169 expectations pass without failures/errors/uncaptured
warnings/skips, including 100 numbered scenarios each (500 executions/1,084
expectations). Malformed search queries error clearly; valid letter ranges no
longer warn. Existing-column selection, grouping-key retention, label metadata
and substring/anchored search are preserved and documented. The maintainer
approved the selective console PDF; its presentation remains unchanged.

tab/tab1/tab2 and fre/fre1/fre2 are locally accepted release candidates within
documented display, naming and locale limits: 897 blocks/8,258 expectations
pass with zero failures/errors/uncaptured warnings/skips, including 100 numbered
cases per export (600 executions/7,547 expectations). Explicit grouping overrides
and label-free tagged-missing conversion are fixed. Frequency display labels can
coincide without merging counts; some non-ASCII column names emit native-encoding
warnings under Windows LC_CTYPE=C. See the acceptance report for precise limits.

summ() and tabstat() remain locally accepted: all 342 summary blocks and 1,224
expectations pass. Their [100-case catalogue](.opencode/reports/project_status_summ_tabstat_100_scenarios_2026-10-16.md)
remains valid. Conversion helpers are next; minimum-R/multi-platform
publication checks and remaining warning/empty-test coverage still remain.
The first-milestone evidence below is historical.

- [Milestone contract report](.opencode/reports/milestone_contracts_0.2.0.9000.md):
  622 passing scenarios and 4,098 passing expectations, with no failures,
  errors, warnings, or skips. Coverage includes the independent review fixes.
- A fresh native installation succeeds. A separate smoke check loads the core
  with required dependencies only and verifies the error for absent formatting.
- All ten active demos execute successfully and have versioned output reports.
- Historically, first-milestone package checking passed non-test stages but
  failed at tests. The current passing full-suite check above supersedes that
  result; the milestone status report retains its original totals.
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
# Entire retained suite.
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

## Next validation milestone

1. Execute the declared R 4.1 minimum and Windows/macOS/Linux CI matrix after an
   authorized remote update; current local execution is Windows R 4.6.0 only.
2. Validate actual interactive viewer rendering manually.
3. Review release metadata, migration guidance and preserved locale/display/binning
   limitations before requesting publication.

Function-family adoption is complete in the tested local scope; use
`make style-check` and the documented protected verification workflows for future
changes. Website building is separate from explicitly requested deployment.

The approved summary policies, search matching, empty selections and list counts
are implemented. Original-variable/category collisions and units recognition
are fixed. No push, merge, publication or release has been performed.

Git history was restored on 2026-10-15 from https://github.com/socimh/statart.git.
Local master tracks origin/master. The 2026-10-16 development checkpoint preserves the newer local work with known test failures documented.
No push, publication, or release is included in this milestone.

## Stabilization preparation checkpoint (historical)

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
Before publishing, address the remaining test-warning/empty-test coverage,
exercise supported R versions/platforms, and review generated whitespace. The Git
connection is ready for maintenance; passing local checks do not replace
cross-platform and minimum-version release validation. Push,
merge, and release require an explicit maintainer request.

## Entry points

- [CONTRIBUTING.md](CONTRIBUTING.md) and [AGENTS.md](AGENTS.md).
- [Current issues](.opencode/PROBLEMS.md), [tasks](.opencode/TODO.md), and
  [progress](.opencode/PROGRESS.md).
- [Report index](.opencode/reports/INDEX.md), with current and historical output.
- [Approved scope and execution ledger](.opencode/plans/lean-core-milestone.md).
