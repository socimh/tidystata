# Quick status - statart

Updated 2026-10-16. Development version **0.2.0.9000**.

- First scope-reduction and priority-repair milestone implemented.
- Four wrappers retired and archived: read_data, write_data, esttab, codebook_detail.
- 13 required Imports; 40 exported objects; current C++/Rfast backend retained.
- fre/fre2 return tibbles; fre1 returns a list; flextable formatting is optional.
- Focused verification: 622 passing scenarios and 4,098 passing expectations;
  zero failures, errors, warnings, or skips.
- Fresh build, required-dependencies-only smoke, and ten demos pass.
- Latest full suite after test-only repairs: 5,357 passing expectations, five failed expectations, ten error blocks, 33 warnings and one skip across the same 1,358 blocks.
- All 11 invalid fixtures and the incorrect assertions were repaired; no package source changed. Existing source defects and open contracts remain exposed. [Evidence](reports/project_status_test_stabilization_2026-10-16.md).
- Git history restored; master tracks origin/master over authenticated HTTPS.
- Local development checkpoint prepared on 2026-10-16; no push, publication, or release.
- Upstream migration mapping completed; selected evidence is versioned and remaining generated results are preserved locally and ignored.
- [Failure triage](reports/project_status_failure_triage_2026-10-16.md): 104 identities = 11 invalid fixtures, 77 incorrect expectations, seven likely defects, eight contract decisions, one environmental flake.
- Fresh isolated installation and minimal-dependency smoke check passed on 2026-10-16. No function fixes or full-suite rerun in this preparation pass.

## Resume here

- [Development guide](../DEVELOPMENT.md)
- [Migration guide](../MIGRATION.md)
- [Milestone status](reports/milestone_status_0.2.0.9000.md)
- [Focused report](reports/milestone_contracts_0.2.0.9000.md)
- [Remaining issues](PROBLEMS.md) and [tasks](TODO.md)

Next: repair reproduced naming/units defects and settle summary/date/cross-tabulation contracts, then
resolve the remaining name/type/utility discrepancies before a release check.
Use the protected isolated build/test commands documented in DEVELOPMENT.md.
