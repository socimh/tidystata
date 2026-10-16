# To-do list

## Next stabilization milestone

- [x] Repair invalid labelled, incompatible-length, and sampling fixtures.
- [ ] Settle summary/date output contracts and invalid-statistic handling.
- [ ] Reconcile cross-tabulation dimensions/count-column expectations and category collisions.
- [ ] Review selector evaluation, names/types, and remaining utility discrepancies.
- [ ] Reach a passing retained suite and clean R CMD check before release.
- [ ] Exercise the supported R-version range; current verification used R 4.6.0 only.
- [x] Restore original Git history from socimh/statart, establish master tracking origin/master, and verify all existing file hashes are unchanged.

- [x] Verify restored GitHub access and compare tracked changes, untracked files, exports, and archives with origin/master.
- [x] Complete maintenance setup verification: fresh fetch, configured identity/helper/trust, no incoming commits, and unchanged working-file hashes/index during fetch.
- [x] Reconcile upstream-to-local migration notes and review result-artifact staging scope before integration.
- [x] Prepare a reviewed local development checkpoint with selected evidence and a complete saved-failure classification.
- [x] Repair the 11 invalid fixtures and 77 incorrect-expectation identities in focused batches, verifying each against its contract.
- [ ] Resolve eight open behavior contracts and reproduce seven likely source defects before fixes.

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
