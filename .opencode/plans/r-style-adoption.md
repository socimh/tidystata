# Modern R development adoption

Approved 2026-10-16. Start: ac7cea3, clean test/stabilize-fixtures.

## Contract

Adopt family by family with risk-based tests. Preserve R >= 4.1, 13 Imports,
40 exports, existing arguments/returns/statistical policies and `%>%` support.
No push, merge, publication, release or artifact deletion. All Windows R uses
the protected launcher. Generated files are regenerated from their sources.

## Execution

- [x] Standards, pinned Air/lintr tooling, progressive scope and read-only checks.
- [x] Check-only PR style workflow, explicit website deployment and R 4.1 CI.
- [x] Conversions: characterize, simplify, strengthen values and correct help.
- [x] Row calculations and binning: contracts, missingness, boundaries and empty test.
- [x] Selectors/types/utilities: evaluation, diagnostics, RNG and visibility.
- [x] Accepted families: compatibility-preserving consistency pass.
- [x] Maintained demos/verification/report sources: formatting and proven duplication.
- [x] Dependency floor audit, focused/fresh full/native/build/check verification.
- [x] Generated help/examples/reports, tracking and independent final review.

## Review focus

Preserve attributes and typed missing values; avoid changing promise forcing
or callback counts; preserve successful warnings and documented failed probes;
check matrix/list/empty boundaries; retain R 4.1 syntax and realistic dependency
constraints. Historical PDF artifacts remain byte-for-byte unchanged.

## Ledger

- Preflight: existing isolated development branch is clean; approved plan is the
  specification. Existing protected native build workflow is reused.
- Ruling: retain the project plan location and artifacts rather than the skill's
  generic docs location/deletion step, as required by repository preservation rules.
- Ruling: specialist tasks may run independently on disjoint files; integration
  and evidence checks follow family order. No simultaneous writes to shared files.

- Refactor checkpoint726c81e: new57 risk-based blocks, retained-suite warning
  assertions and six regenerated help topics; full3053/16492 green.
- Formatting checkpointbf7181d: explicit adopted package/test scope; same full
  counts green. Final source build/check and required-dependency smoke pass.
- Final cross-review fixes: NUL-delimited Git paths and canonical path guards
  reproduced RED then GREEN; tidyr floor raised to1.2.0 for casting semantics.
- Ruling: keep existing display-based conversion dispatch after78 equivalence
  comparisons; changing class dispatch is unnecessary API risk in style adoption.
- Ruling: permit narrowly identified redundant stats/utils qualification in lint
  to retain explicit calls; missing packages/exports remain errors.
- Final verification:90 sources style/parse/lint clean, three Python tests pass,
  full3053blocks16492expectations and R CMD check OK, eleven demos and minimal
  smoke pass,40 interfaces/24 output records unchanged,100 package files match
  the checked copy and both prior PDFs are byte-identical.
- Remaining external gates: R4.1 and other-platform CI execution require a later
  authorized remote update. Actual GUI viewing and oldest dependency combinations
  remain unverified; these limits do not block the completed local adoption.

- Maintained-demo fix: remove ten repeated pkgload development loads; pass the
  freshly installed library explicitly. Timer private-helper lookup reproduced
  in the installed demo run, qualified explicitly, then eleven demos passed.
- Raw console logs preserve R's trailing display spaces. Source/documentation
  whitespace checks exclude raw result evidence; no saved output was hand-patched.
