# Quick status - statart

Updated 2026-10-16. Development version **0.2.0.9000**.

- Core scope retained: 13 required Imports, 40 exports, cpp11/Rfast backend; four retired wrappers preserved in extra_functions.
- Full suite: **5,617 passing expectations, zero failures/errors**, 33 warnings and one skipped empty test across **1,410 blocks**.
- Fresh native installation, source build and required-dependency smoke passed.
- **R CMD check --no-manual: Status: OK** (zero check errors/warnings/notes).
- Fixed invalid test fixtures/assertions, summary missing-data/statistic contracts, tabulation collisions/empty selections, and units recognition. Substring search is retained with explicit anchors for complete matches.
- Numeric/logical summaries retain zero-observation rows; aliases and numeric sum are supported. Mixed table statistics format consistently; counts stay numeric.
- List-column tabulation preserves identities; no measured variables yields empty outputs using the established list/tibble container.
- Original datasets and native artifacts preserved. No new dependencies or exports.
- Work is on local branch test/stabilize-fixtures; master retains origin/master tracking. No push, merge, publication or release.

## Evidence and next steps

- [Current core verification](reports/project_status_core_stabilization_2026-10-16.md)
- [Test-only stage](reports/project_status_test_stabilization_2026-10-16.md)
- [Development guide](../DEVELOPMENT.md), [migration](../MIGRATION.md), [issues](PROBLEMS.md), [tasks](TODO.md).

Next: replace the empty cut_length test, clarify expected-warning assertions,
and validate R 4.1 and other platforms before publication. Known ambiguous
cross-table labels remain explicit errors; see the core report for boundaries.

Repository cleanup completed: six historical files archived byte-for-byte, build scratchpad excluded, and make clean preserves artifacts. Fresh full suite/build/check pass unchanged; see [cleanup verification](reports/project_status_cleanup_2026-10-16.md). Generated artifacts remain on disk.
