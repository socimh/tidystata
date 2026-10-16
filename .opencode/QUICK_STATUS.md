# Quick status - statart

Updated 2026-10-16. Development version **0.2.0.9000**.

- Core scope retained: 13 required Imports, 40 exports, cpp11/Rfast backend; four retired wrappers preserved in extra_functions.
- Full suite: **14,255 passing expectations, zero failures/errors**, 22 warnings and one skipped empty test across **2,274 blocks**.
- Fresh native installation and source build passed; earlier required-dependency smoke remains valid.
- **R CMD check --no-manual: Status: OK** (zero check errors/warnings/notes).
- Fixed invalid test fixtures/assertions, summary missing-data/statistic contracts, tabulation collisions/empty selections, and units recognition. Substring search is retained with explicit anchors for complete matches.
- Numeric/logical summaries retain zero-observation rows; aliases and numeric sum are supported. Mixed table statistics format consistently; counts stay numeric.
- List-column tabulation preserves identities; no measured variables yields empty outputs using the established list/tibble container.
- Original datasets and native artifacts preserved. No new dependencies or exports.
- Work is on local branch test/stabilize-fixtures; master retains origin/master tracking. No push, merge, publication or release.

## Evidence and next steps

- [Selective console PDF and input-script showcase](reports/project_status_console_showcase_2026-10-16.md): four pages for maintainer review; package behavior unchanged.
- [Tabulation acceptance: 100 scenarios per function](reports/project_status_tabulation_acceptance_2026-10-16.md)
- [100-scenario catalogue for each summary function](reports/project_status_summ_tabstat_100_scenarios_2026-10-16.md)
- [Earlier summ/tabstat acceptance](reports/project_status_summ_tabstat_acceptance_2026-10-16.md)
- [Earlier core verification](reports/project_status_core_stabilization_2026-10-16.md)
- [Test-only stage](reports/project_status_test_stabilization_2026-10-16.md)
- [Development guide](../DEVELOPMENT.md), [migration](../MIGRATION.md), [issues](PROBLEMS.md), [tasks](TODO.md).

Next: review variable inspection functions, then replace the empty cut_length test and clarify remaining expected-warning assertions,
and validate R 4.1 and other platforms before publication. Known ambiguous
cross-table labels remain explicit errors; see the core report for boundaries.

Repository cleanup completed: six historical files archived byte-for-byte, build scratchpad excluded, and make clean preserves artifacts. Fresh full suite/build/check pass unchanged; see [cleanup verification](reports/project_status_cleanup_2026-10-16.md). Generated artifacts remain on disk.

Function review: summ() and tabstat() are locally accepted release candidates. Their 342 test blocks/1,224 expectations have zero failures, errors, warnings or skips; standalone acceptance has 286 scenarios/1,158 expectations, including 100 numbered scenarios for each function. Tabulation is also locally accepted within documented naming/display/locale limits: 897 blocks/8258 expectations pass, including 100 numbered scenarios for each of six exports (600 executions/7547 expectations), with zero failures/errors/uncaptured warnings/skips. Next function family: variable inspection. Publication still requires minimum-R/multi-platform validation.
