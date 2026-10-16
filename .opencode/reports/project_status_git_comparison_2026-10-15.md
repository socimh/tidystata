# Local development compared with origin/master

Reverified 2026-10-15 (2026-10-16 03:53 UTC). Comparison baseline: `12709f6ab8398ddeedab40def10adfc3c7ebefd4`.

## Connection and scope

Authenticated GitHub CLI account: socimh. HTTPS fetch succeeded. Origin is https://github.com/socimh/statart.git. Local master tracks origin/master; both point to the baseline above, with zero commits ahead or behind. The index is unchanged from HEAD. All development differences are unstaged or untracked, not local commits. No merge, commit, push, or release was performed.

At final verification: 48 tracked paths differ (33 modified, 15 deleted), with 1,330 inserted and 2,314 deleted lines. There are 274 untracked files, including 135 result artifacts, 28 reports, 20 archived files, and 20 new test files. These counts include this report. Git's tracked diff statistics exclude all untracked content and therefore overstate net code removal if read without the archives.

## Final connection verification

Fetch completed successfully on 2026-10-15 (2026-10-16 03:53 UTC). The remote revision did not advance: local HEAD, fetched origin/master, and live GitHub master all match the baseline above. No incoming commits or remote changes require reconciliation. The 538 existing working files retained identical SHA-256 hashes during fetch, and the Git index retained identical bytes.

The existing HTTPS credential helper, exact repository trust entry, and configured commit identity are sufficient for maintenance from this folder. No further repository setup or SSH changes are needed. The earlier setup refresh error concerned tool startup; authenticated Git operations succeeded through approved outside-sandbox execution. Credential values and private keys were not displayed.

Only the development guide, this report, and status trackers are refreshed in this completion pass. No R execution or package verification was repeated; milestone test results below refer to prior evidence. Before publication, reconcile migration notes, review result-artifact staging scope, address whitespace through appropriate sources, and resolve the recorded test failures. No staging, commit, push, merge, or release is part of this task.

## Development changes

| Area | Difference from GitHub |
| --- | --- |
| Package scope | Version 0.2.0 to 0.2.0.9000; required Imports 33 to 13; R minimum 2.10 to 4.1.0; optional formatting dependencies move to Suggests. |
| Public API | 54 exported objects become 40: 15 removals, one addition (`timer`). Six printing S3 registrations are removed. |
| Frequencies | fre/fre2 default to tibbles; fre1 defaults to a list. Group keys, missing keys, reserved names, within-group totals, and output selection change. |
| Rows/native code | Atomic results, explicit row-input handling, sample variance/SD, consistent missing-value rules; native extrema/totals allocate independent result vectors. |
| Binning | Quantile input validation and duplicate-cutpoint collapse; ties remain together. |
| Metadata/conversion | Direct label attributes replace Hmisc; label searches corrected; character parsing and missing-value preservation change. |
| Summaries | Vector/data.table handling and .na.rm, .name, .mode, .duration_format arguments added; date/duration formatting and nonfinite summary behavior change. These contracts still have known failing tests. |
| Utilities | s_time becomes timer with compact duration output; s_select includes underlying selection/expression errors. |
| Tests and workflow | 20 new active test files and expanded complex-table tests; protected isolated build/test workflow, demos, archived tests, development docs, migration guide, and status records are untracked. |

## Findings requiring follow-up

1. **Migration notes use a newer local baseline than GitHub.** The four-wrapper retirement statement is not a complete migration description from origin/master. Removed upstream exports are `codebook_detail`, `print_headtail`, `print_interval`, `read_data`, `regress`, `regress_coef`, `regress_data`, `regress_stat`, `s_ggsave`, `s_plot`, `s_time`, `slice_headtail`, `slice_interval`, `tidy_coef`, and `write_data`. `timer` is added. `esttab` was not exported by this upstream revision: the local tidy_coef-to-esttab transition preceded its retirement. Reconcile NEWS/MIGRATION against this upstream baseline before publishing.
2. **Deleted paths largely represent archives or replacements.** Nine of the 15 deleted R/help files have same-name archives with identical text after newline normalization. The two regress archives differ in their reference from tidy_coef to etable. The other four paths correspond to s_time-to-timer and tidy_coef-to-esttab source/help transitions. These replacements are not exact preservation of the original files; original versions remain recoverable from Git history.
3. **Do not stage the entire directory blindly.** The 135 untracked result files include logs, machine-specific path records, CSV and RDS outputs. The largest is about 2.39 MB. Decide which reproducibility evidence belongs in version control. No artifacts were deleted or ignored by this comparison.
4. **Whitespace check fails.** `git diff --check origin/master` reports 26 trailing-whitespace locations in R/summ-helpers.R, R/summ.R, README.md, and tests/testthat/test-complex_tb.R. README.md is generated; address its source/generation if cleanup is requested.
5. **Package release remains blocked by recorded test failures.** Existing milestone evidence reports 94 failed expectations and 22 error blocks; this comparison did not rerun tests or R CMD check. Connection verification and a source comparison do not establish package correctness.

## Earlier comparison verification (before this completion pass)

The earlier comparison ran gh auth status, git fetch origin, revision equality, upstream and ahead/behind checks; tracked and untracked inventory; NAMESPACE export set comparison; removed-file/archive text comparisons; source diff review; git diff --check. All 26 active R source files also parsed successfully through the protected launcher (exit 0); startup emitted four locale warnings for inherited C.UTF-8 settings. No functions were executed. Package source, datasets and existing result artifacts were not modified. That earlier comparison updated this report, the generated report index, and status trackers. The final completion pass is documented separately above and did not rerun R or regenerate the index.

## Tracked inventory

```text
M	.Rbuildignore
M	DESCRIPTION
M	NAMESPACE
M	NEWS.md
M	R/codebook.R
M	R/cut.R
D	R/geom_violinbox.R
D	R/import-export.R
D	R/regress.R
M	R/row_egen.R
D	R/s_ggsave.R
D	R/s_plot.R
M	R/s_select.R
D	R/s_time.R
D	R/sepecial-print.R
M	R/statart-package.R
M	R/statart.R
M	R/summ-helpers.R
M	R/summ.R
M	R/tab-helpers.R
M	R/tab.R
D	R/tidy_coef.R
M	R/type_conversion.R
M	R/variables.R
M	README.Rmd
M	README.md
M	_pkgdown.yml
M	man/browse.Rd
M	man/codebook.Rd
M	man/cut.Rd
D	man/import-export.Rd
M	man/names.Rd
D	man/regress.Rd
M	man/row_egen.Rd
D	man/s_ggsave.Rd
M	man/s_match.Rd
D	man/s_plot.Rd
M	man/s_select.Rd
D	man/s_time.Rd
D	man/special-print.Rd
M	man/statart-package.Rd
M	man/summ.Rd
M	man/tab.Rd
D	man/tidy_coef.Rd
M	man/type_conversion.Rd
M	man/variables.Rd
M	src/row_stat.cpp
M	tests/testthat/test-complex_tb.R
```

## Untracked inventory at final verification

```text
.opencode/COLUMN_ORDERING_FIX.md
.opencode/COMPLETION_SUMMARY.md
.opencode/FUNCTION_QUEUE.md
.opencode/PROBLEMS.R
.opencode/PROBLEMS.md
.opencode/PROGRESS.md
.opencode/PROGRESS_ARCHIVE.md
.opencode/QUICK_STATUS.md
.opencode/RUN_CONTROL.md
.opencode/TODO.md
.opencode/demos/demo_browse.R
.opencode/demos/demo_codebook.R
.opencode/demos/demo_cut.R
.opencode/demos/demo_fre.R
.opencode/demos/demo_row_egen.R
.opencode/demos/demo_s_select.R
.opencode/demos/demo_summ.R
.opencode/demos/demo_tab.R
.opencode/demos/demo_tab1.R
.opencode/demos/demo_timer.R
.opencode/plans/lean-core-milestone.md
.opencode/reports/INDEX.md
.opencode/reports/NEW PROBLEMS.md
.opencode/reports/PROBLEMS.md
.opencode/reports/milestone_contracts_0.2.0.9000.md
.opencode/reports/milestone_status_0.2.0.9000.md
.opencode/reports/project_status_2026-10-15.md
.opencode/reports/project_status_git_comparison_2026-10-15.md
.opencode/reports/report_browse.md
.opencode/reports/report_browse_0.2.0.9000.md
.opencode/reports/report_codebook.md
.opencode/reports/report_codebook_0.2.0.9000.md
.opencode/reports/report_cut.md
.opencode/reports/report_cut_0.2.0.9000.md
.opencode/reports/report_esttab.md
.opencode/reports/report_fre.md
.opencode/reports/report_fre_0.2.0.9000.md
.opencode/reports/report_row_egen.md
.opencode/reports/report_row_egen_0.2.0.9000.md
.opencode/reports/report_s_select.md
.opencode/reports/report_s_select_0.2.0.9000.md
.opencode/reports/report_summ.md
.opencode/reports/report_summ_0.2.0.9000.md
.opencode/reports/report_tab.md
.opencode/reports/report_tab1.md
.opencode/reports/report_tab1_0.2.0.9000.md
.opencode/reports/report_tab_0.2.0.9000.md
.opencode/reports/report_timer.md
.opencode/reports/report_timer_0.2.0.9000.md
.opencode/reproduce_issues.R
.opencode/results/baseline-0.2.0.json
.opencode/results/baseline-source-manifest.json
.opencode/results/milestone-contracts-details.csv
.opencode/results/milestone-contracts-install.log
.opencode/results/milestone-contracts-paths.json
.opencode/results/milestone-contracts-tests.log
.opencode/results/milestone-contracts.csv
.opencode/results/milestone-contracts.rds
.opencode/results/milestone-demos-demos.log
.opencode/results/milestone-demos-final-demos.log
.opencode/results/milestone-demos-final-install.log
.opencode/results/milestone-demos-final-paths.json
.opencode/results/milestone-demos-install.log
.opencode/results/milestone-demos-paths.json
.opencode/results/milestone-final-build.log
.opencode/results/milestone-final-check.log
.opencode/results/milestone-final-details.csv
.opencode/results/milestone-final-install.log
.opencode/results/milestone-final-paths.json
.opencode/results/milestone-final-tests.log
.opencode/results/milestone-final.csv
.opencode/results/milestone-final.rds
.opencode/results/milestone-focused-details.csv
.opencode/results/milestone-focused-final-details.csv
.opencode/results/milestone-focused-final-install.log
.opencode/results/milestone-focused-final-paths.json
.opencode/results/milestone-focused-final-tests.log
.opencode/results/milestone-focused-final.csv
.opencode/results/milestone-focused-final.rds
.opencode/results/milestone-focused-install.log
.opencode/results/milestone-focused-paths.json
.opencode/results/milestone-focused-tests.log
.opencode/results/milestone-focused-v2-details.csv
.opencode/results/milestone-focused-v2-install.log
.opencode/results/milestone-focused-v2-paths.json
.opencode/results/milestone-focused-v2-tests.log
.opencode/results/milestone-focused-v2.csv
.opencode/results/milestone-focused-v2.rds
.opencode/results/milestone-focused.csv
.opencode/results/milestone-focused.rds
.opencode/results/milestone-full-build.log
.opencode/results/milestone-full-check.log
.opencode/results/milestone-full-details.csv
.opencode/results/milestone-full-install.log
.opencode/results/milestone-full-paths.json
.opencode/results/milestone-full-tests.log
.opencode/results/milestone-full.csv
.opencode/results/milestone-full.rds
.opencode/results/milestone-minimal-final-install.log
.opencode/results/milestone-minimal-final-minimal.log
.opencode/results/milestone-minimal-final-paths.json
.opencode/results/milestone-minimal-install.log
.opencode/results/milestone-minimal-minimal.log
.opencode/results/milestone-minimal-paths.json
.opencode/results/milestone-retained-final-details.csv
.opencode/results/milestone-retained-final-install.log
.opencode/results/milestone-retained-final-paths.json
.opencode/results/milestone-retained-final-tests.log
.opencode/results/milestone-retained-final.csv
.opencode/results/milestone-retained-final.rds
.opencode/results/milestone-timer-recheck-details.csv
.opencode/results/milestone-timer-recheck.csv
.opencode/results/milestone-timer-recheck.rds
.opencode/results/milestone-timing-probe.txt
.opencode/results/milestone-verification-build.log
.opencode/results/milestone-verification-check.log
.opencode/results/milestone-verification-details.csv
.opencode/results/milestone-verification-install.log
.opencode/results/milestone-verification-paths.json
.opencode/results/milestone-verification-tests.log
.opencode/results/milestone-verification.csv
.opencode/results/milestone-verification.rds
.opencode/results/test-browse_output.txt
.opencode/results/test-browse_previous.Rds
.opencode/results/test-browse_results.Rds
.opencode/results/test-complex_tb_output.txt
.opencode/results/test-complex_tb_previous.Rds
.opencode/results/test-complex_tb_results.Rds
.opencode/results/test-cut_output.txt
.opencode/results/test-cut_previous.Rds
.opencode/results/test-cut_results.Rds
.opencode/results/test-esttab_output.txt
.opencode/results/test-esttab_previous.Rds
.opencode/results/test-esttab_results.Rds
.opencode/results/test-fre1_output.txt
.opencode/results/test-fre1_previous.Rds
.opencode/results/test-fre1_results.Rds
.opencode/results/test-fre2_output.txt
.opencode/results/test-fre2_previous.Rds
.opencode/results/test-fre2_results.Rds
.opencode/results/test-fre_output.txt
.opencode/results/test-fre_previous.Rds
.opencode/results/test-fre_results.Rds
.opencode/results/test-import-export_output.txt
.opencode/results/test-import-export_previous.Rds
.opencode/results/test-import-export_results.Rds
.opencode/results/test-names_output.txt
.opencode/results/test-names_previous.Rds
.opencode/results/test-names_results.Rds
.opencode/results/test-row_egen_output.txt
.opencode/results/test-row_egen_previous.Rds
.opencode/results/test-row_egen_results.Rds
.opencode/results/test-s_match_output.txt
.opencode/results/test-s_match_previous.Rds
.opencode/results/test-s_match_results.Rds
.opencode/results/test-s_select_output.txt
.opencode/results/test-s_select_previous.Rds
.opencode/results/test-s_select_results.Rds
.opencode/results/test-s_try_output.txt
.opencode/results/test-s_try_previous.Rds
.opencode/results/test-s_try_results.Rds
.opencode/results/test-s_type_output.txt
.opencode/results/test-s_type_previous.Rds
.opencode/results/test-s_type_results.Rds
.opencode/results/test-set_seed_output.txt
.opencode/results/test-set_seed_previous.Rds
.opencode/results/test-set_seed_results.Rds
.opencode/results/test-summ_output.txt
.opencode/results/test-summ_previous.Rds
.opencode/results/test-summ_results.Rds
.opencode/results/test-tab1_output.txt
.opencode/results/test-tab1_previous.Rds
.opencode/results/test-tab1_results.Rds
.opencode/results/test-tab2_output.txt
.opencode/results/test-tab2_previous.Rds
.opencode/results/test-tab2_results.Rds
.opencode/results/test-tab_output.txt
.opencode/results/test-tab_previous.Rds
.opencode/results/test-tab_results.Rds
.opencode/results/test-timer_output.txt
.opencode/results/test-timer_previous.Rds
.opencode/results/test-timer_results.Rds
.opencode/results/test-type_conversion_output.txt
.opencode/results/test-type_conversion_previous.Rds
.opencode/results/test-type_conversion_results.Rds
.opencode/rules/00-core-r-package.md
.opencode/rules/01-git-workflow.md
.opencode/rules/02-autonomy-and-notifications.md
.opencode/rules/03-generated-and-results-files.md
.opencode/rules/10-tests.md
.opencode/rules/11-function-reports.md
.opencode/rules/20-docs.md
.opencode/tests/debug_issue_a1.R
.opencode/tests/debug_issue_a1_step.R
.opencode/tests/minimal_dependencies.R
.opencode/tests/test_cut_row.R
.opencode/tests/test_esttab.R
.opencode/tests/test_esttab_automated.R
.opencode/tests/test_esttab_comprehensive.R
.opencode/tests/test_esttab_comprehensive_output.txt
.opencode/tests/test_esttab_output.txt
.opencode/tests/test_issue_a1.R
.opencode/tests/test_summ.R
.opencode/tests/test_tab_codebook.R
.opencode/tests/test_timer_sselect_fre.R
.opencode/tests/verification_milestone.txt
.opencode/tests/verification_new_features.txt
.opencode/tests/verification_output.txt
.opencode/tests/verify_all_functions.R
.opencode/tests/verify_milestone.R
.opencode/tests/verify_new_features.R
.opencode/verify_esttab.R
.opencode/workflows/README.md
.opencode/workflows/add_challenge_headers.R
.opencode/workflows/esttab_automation.R
.opencode/workflows/generate_demo_reports.R
.opencode/workflows/lib/error_handler.R
.opencode/workflows/lib/problem_updater.R
.opencode/workflows/lib/test_runner.R
.opencode/workflows/run_suite.R
.opencode/workflows/summarize_milestone.py
.opencode/workflows/verify_package.py
.opencode/workflows/watch_esttab.R
AGENTS.md
CONTRIBUTING.md
DEVELOPMENT.md
MIGRATION.md
Makefile
R/timer.R
TEST_SUMMARY.md
extra_functions/R/esttab.R
extra_functions/R/geom_violinbox.R
extra_functions/R/import-export.R
extra_functions/R/regress.R
extra_functions/R/s_ggsave.R
extra_functions/R/s_plot.R
extra_functions/R/sepecial-print.R
extra_functions/demos/demo_esttab.R
extra_functions/legacy-codebook.R
extra_functions/legacy-row_egen.R
extra_functions/legacy-tab-helpers.R
extra_functions/man/codebook-legacy.Rd
extra_functions/man/esttab.Rd
extra_functions/man/import-export.Rd
extra_functions/man/regress.Rd
extra_functions/man/s_ggsave.Rd
extra_functions/man/s_plot.Rd
extra_functions/man/special-print.Rd
extra_functions/tests/test-esttab.R
extra_functions/tests/test-import-export.R
install_statart_deps.R
man/timer.Rd
run_tests.R
test.R
tests/testthat/test-browse.R
tests/testthat/test-cut.R
tests/testthat/test-fre.R
tests/testthat/test-fre1.R
tests/testthat/test-fre2.R
tests/testthat/test-milestone-core.R
tests/testthat/test-milestone-review.R
tests/testthat/test-names.R
tests/testthat/test-row_egen.R
tests/testthat/test-s_match.R
tests/testthat/test-s_select.R
tests/testthat/test-s_try.R
tests/testthat/test-s_type.R
tests/testthat/test-set_seed.R
tests/testthat/test-summ.R
tests/testthat/test-tab.R
tests/testthat/test-tab1.R
tests/testthat/test-tab2.R
tests/testthat/test-timer.R
tests/testthat/test-type_conversion.R
```
