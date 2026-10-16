# To-do list

## Repository organization

- [x] Review tracked, ignored, historical and package-distributed files without deleting anything; see [cleanup review](reports/project_status_cleanup_review_2026-10-16.md).
- [x] Archive six obsolete scripts/release notes with byte preservation and build exclusions verified; see [cleanup results](reports/project_status_cleanup_2026-10-16.md).
- [x] Make clean non-destructive and verify it preserves all reports and artifacts.
- [ ] Review an exact generated-artifact list before requesting any deletion.

## Function-by-function acceptance

- [x] Build and visually verify a selective four-page PDF showing input scripts, actual console output and a downstream research pipeline.
- [x] Review maintainer feedback: the selective console PDF is approved; preserve its current presentation.

- [x] Provide a numbered 100-scenario catalogue and run every case independently for summ and tabstat; preserve all prior checks. See [cases and results](reports/project_status_summ_tabstat_100_scenarios_2026-10-16.md).

- [x] Review summ/tabstat, repair reproduced defects, implement counts-only nonnumeric retention, regenerate help and verify real output; see [acceptance report](reports/project_status_summ_tabstat_acceptance_2026-10-16.md).
- [x] Verify summary tests have no uncaptured warnings/skips and fresh full package checks remain green.
- [x] Review tab/tab1/tab2 and fre/fre1/fre2, fix reproduced grouping/conversion defects and verify 100 numbered scenarios per export; see [acceptance](reports/project_status_tabulation_acceptance_2026-10-16.md).
- [x] Regenerate shared help, verify actual output and pass fresh full-suite/build/check after tabulation changes.
- [x] Review ds, ds_as_column, names_as_column, variables and variables_search with 100 numbered scenarios each; fix query validation/letter-range warnings, regenerate help and pass full checks. See [acceptance](reports/project_status_inspection_acceptance_2026-10-16.md).
- [ ] Review codebook and browse next, including remaining fixture warnings.
- [ ] Continue through conversions, row helpers, binning and utilities after codebook/browse.
- [ ] Complete minimum-R/multi-platform validation before any publication request.

## Next stabilization milestone

- [x] Repair invalid labelled, incompatible-length, and sampling fixtures.
- [x] Settle summary missing-input/statistic and mixed numeric/date output contracts.
- [x] Reconcile cross-table dimensions/counts, original-name collisions and explicit ambiguous-name errors.
- [x] Resolve retained selection/name/type/utility test discrepancies; preserve explicit substring semantics.
- [x] Reach a passing retained suite and clean local R CMD check.
- [ ] Exercise the supported R-version range; current verification used R 4.6.0 only.
- [x] Restore original Git history from socimh/statart, establish master tracking origin/master, and verify all existing file hashes are unchanged.

- [x] Verify restored GitHub access and compare tracked changes, untracked files, exports, and archives with origin/master.
- [x] Complete maintenance setup verification: fresh fetch, configured identity/helper/trust, no incoming commits, and unchanged working-file hashes/index during fetch.
- [x] Reconcile upstream-to-local migration notes and review result-artifact staging scope before integration.
- [x] Prepare a reviewed local development checkpoint with selected evidence and a complete saved-failure classification.
- [x] Repair the 11 invalid fixtures and 77 incorrect-expectation identities in focused batches, verifying each against its contract.
- [x] Resolve the eight behavior contracts and fix the reproduced units, summary and naming defects.

- [ ] Replace the skipped empty cut_length test and capture remaining expected warnings outside the accepted summary/tabulation/names families.
- [ ] Review selector side effects and additional naming boundaries beyond the retained scenarios before release.

## Completed first milestone

- [x] Retire only read_data, write_data, esttab, and codebook_detail; preserve archive.
- [x] Reduce required Imports from 33 to 13 and keep all other helper exports.
- [x] Default frequency output to data and make rich formatting optional.
- [x] Replace Hmisc label extraction and fix attribute-label searches.
- [x] Repair character conversion, grouped keys/percentages/totals, row results, and quantile ties.
- [x] Fix independent-review regressions for reserved variable keys and general dataframe expressions.
- [x] Regenerate namespace, help, README, migration notes, and active website references.
- [x] Provide protected isolated test/demo commands with reliable failure exit status.
- [x] Verify 622 focused scenarios; fresh build, minimal dependencies, ten demos and archive contents.
- [x] Compare full retained failures with baseline: 94 failed expectations, 22 error blocks,
  no unexplained new failure identities (one unchanged timing fixture is flaky); record test-stage package-check ERROR.

## Historical completion notes

The following pre-milestone notes are preserved as history. Some behavior,
especially rank-based quantile splitting and required formatted output, has
been superseded by the approved smaller-core contracts.

### Batch 1 (summ, tab1/tab, codebook)
- [x] summ: Fix 5 issues (Inf, datetime, performance, .na.rm, .name)
- [x] tab1: Expression support (positional keyword arg bug)
- [x] tab: Missing values per group, .desc sorting, fre1 expressions
- [x] codebook: Suppress Hmisc::contents warning

### Batch 2 (cut_quantile, row_min/max, row_mean/sum)
- [x] cut_quantile: Rank-based fallback for heavy ties (Stata xtile equivalent)
- [x] row_min/max: Return plain numeric vectors (removed as_tibble() wrapper)
- [x] row_mean/sum/miss/non_miss: Same fix (plain vectors)

### Batch 3 (timer, s_select, fre performance)
- [x] timer(): Compact format (1m5s, 0.05s, 1h3m)
- [x] s_select(): Informative errors showing which column + both error messages
- [x] fre(): ~10x performance improvement (add_total rewritten)

### Infrastructure
- [x] Run roxygen2 (NAMESPACE, Rd files updated)
- [x] Create .trae/rules/ structure
- [x] Fix esttab issues (lmer, formatting, stats, error handling)
- [x] Create automated testing workflow (26 scenarios, 100% pass)
- [x] Initialize agent documentation
- [x] Create extra_functions/ structure
- [x] Rename functions (s_time→timer, tidy_coef→esttab)
- [x] Reorganize documentation files for conciseness


## Deferred scope

PCA, spatial extensions, additional import/export, and regression-table wrappers
are not part of the chosen core roadmap. Reconsider only with a concrete use case.
Git metadata was restored on 2026-10-15. Historical completion notes do not imply that current local changes have been committed or pushed.
