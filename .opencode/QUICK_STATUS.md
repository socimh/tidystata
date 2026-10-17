# Quick status - statart

Updated 2026-10-16. Development version **0.2.0.9000**.

- Core scope retained: 12 required Imports, 46 exports, cpp11 row kernels and compiled base aggregates; four retired wrappers preserved in extra_functions.
- Full suite: **16,992 passing expectations across 3,106 blocks**, zero failures/errors/uncaptured warnings/skips.
- Fresh native installation, source build, required-dependency smoke and all twelve demos passed.
- Fresh source build and R CMD check --no-manual pass with Status: OK (zero errors, warnings or notes).
- Fixed invalid test fixtures/assertions, summary missing-data/statistic contracts, tabulation collisions/empty selections, and units recognition. Substring search is retained with explicit anchors for complete matches.
- Numeric/logical summaries retain zero-observation rows; aliases and numeric sum are supported. Mixed table statistics format consistently; counts stay numeric.
- List-column tabulation preserves identities; no measured variables yields empty outputs using the established list/tibble container.
- Original datasets and native artifacts preserved. No new required dependencies; six public functions added/restored.
- Work is on local branch test/stabilize-fixtures; master retains origin/master tracking. No push, merge, publication or release.

- Row types/numerics: 26 new blocks/185 expectations; logical/integer/classed extrema preserve meaning, stable C++ median/dispersion replace Rfast, SPSS masks and unit-scale compatibility are explicit. Required-only graph is 33 packages including statart.

- Persistent previews: 27 blocks/318 expectations pass; complete data survives supported pipelines, with opt-in head/tail or interval printing. All 96 adopted R files pass style checks. tibble >= 3.1.0 and pillar >= 1.8.0 declare printing API requirements.

## Evidence and next steps

- [Ten-page preview PDF](results/preview-showcase/statart_preview_console.pdf): executed inputs and console output for the new preview helpers and research pipelines; visually reviewed.

- [Persistent previews](reports/project_status_previews_2026-10-16.md): latest full-suite acceptance and supported-operation boundaries. [Scripts and console output](reports/report_special_print_0.2.0.9000.md).
- [Row type and numerical acceptance](reports/project_status_row_types_2026-10-16.md): earlier full/native/build/check results, type rules and console examples.
- [Modern R adoption: standards, tooling, family contracts and final verification](reports/project_status_r_style_adoption_2026-10-16.md): 90 files pass style/parse/lint; all 40 public interfaces and 24 output records match baseline.

- [Ten-page codebook/browse console PDF](reports/project_status_codebook_browse_pdf_2026-10-16.md): input scripts, real printed outputs and research pipelines for maintainer review.
- [Codebook/browse: 100 scenarios each](reports/project_status_codebook_browse_acceptance_2026-10-16.md)
- [Five inspection helpers: 100 scenarios each](reports/project_status_inspection_acceptance_2026-10-16.md)
- [Selective console PDF and input-script showcase](reports/project_status_console_showcase_2026-10-16.md): four pages approved by the maintainer; package behavior unchanged.
- [Tabulation acceptance: 100 scenarios per function](reports/project_status_tabulation_acceptance_2026-10-16.md)
- [100-scenario catalogue for each summary function](reports/project_status_summ_tabstat_100_scenarios_2026-10-16.md)
- [Earlier summ/tabstat acceptance](reports/project_status_summ_tabstat_acceptance_2026-10-16.md)
- [Earlier core verification](reports/project_status_core_stabilization_2026-10-16.md)
- [Test-only stage](reports/project_status_test_stabilization_2026-10-16.md)
- [Development guide](../DEVELOPMENT.md), [migration](../MIGRATION.md), [issues](PROBLEMS.md), [tasks](TODO.md).

Function-family style adoption, conversion/row/binning/selector/utility reviews, warning assertions and the empty cut_length test are complete locally. Next: execute R 4.1 and other-platform CI before publication. Known ambiguous
cross-table labels remain explicit errors; see the core report for boundaries.

Repository cleanup completed: six historical files archived byte-for-byte, build scratchpad excluded, and make clean preserves artifacts. Fresh full suite/build/check pass unchanged; see [cleanup verification](reports/project_status_cleanup_2026-10-16.md). Generated artifacts remain on disk.

Function review: summ() and tabstat() are locally accepted release candidates. Their 342 test blocks/1,224 expectations have zero failures, errors, warnings or skips; standalone acceptance has 286 scenarios/1,158 expectations, including 100 numbered scenarios for each function. Tabulation is also locally accepted within documented naming/display/locale limits: 897 blocks/8258 expectations pass, including 100 numbered scenarios for each of six exports (600 executions/7547 expectations), with zero failures/errors/uncaptured warnings/skips. Name and variable metadata helpers are also locally accepted: ds/ds_as_column/names_as_column/variables/variables_search pass 548 blocks/1169 expectations without failures/errors/uncaptured warnings/skips, including 100 numbered scenarios per export. codebook/browse are now locally accepted in headless use: 297 blocks/985 expectations, including 100 numbered cases each, with zero failures/errors/uncaptured warnings/skips. Interactive viewer rendering remains unverified. Conversion/row/binning/selector/utility contracts are now reviewed; publication still requires minimum-R/multi-platform validation.
