# Expand summary coverage to 100 scenarios per function

User request: provide the current tests and expand to at least 100 diverse
checks for summ/tabstat. Implementation target: a numbered 001-100 catalogue,
each scenario exercised independently against both exported functions.

- [x] Inspect current tests/evidence and preserve the existing 142 summary blocks.
- [x] Add cases 001-050: numerical references, missing/infinite/boundary values,
  arithmetic invariants, grouping, names, preservation and realistic sizes.
- [x] Add cases 051-100: types/classes, calendar output, selection, options and
  invalid inputs. Delegate this independent test file to package QA.
- [x] Run all new cases; investigate failures rather than weakening contracts.
- [x] Integrate the numbered suite with the standalone runner and generate a
  readable catalogue with per-function statuses and links to test source.
- [x] Run protected fresh full suite/build/check; obtain test-quality review.
- [x] Update status/evidence and create a local commit; no push, merge or release.

Use independent arithmetic/base-R or documented-contract expectations. No
claim that finite tests prove correctness for every possible input. Minimum-R
and other-platform validation remain publication requirements. Preserve source,
datasets, native artifacts and prior results unless a reproduced defect needs
an authorized surgical repair. All R commands use the protected launcher.
