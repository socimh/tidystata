# Development baseline: 2026-10-15

This is a local source assessment for statart 0.2.0, not a release certification.
See [DEVELOPMENT.md](../../DEVELOPMENT.md) for the inventory and restart roadmap.

## Method and limits

- Parsed all 28 active R source files with R 4.6.0: launcher exit 0.
- Confirmed all declared dependencies are installed on this machine.
- Ran all 21 test files, containing 789 test blocks, first against the bundled
  DLL and then against freshly compiled native code in a temporary source copy.
- Fresh installation used GCC 14.3.0/Rtools45 and the protected R launcher:
  `R CMD INSTALL --preclean --no-test-load --library=<temporary-library> <temporary-source>`.
  Installation exited 0; a subsequent package load confirmed that the new DLL
  loaded. Original compiled artifacts were preserved.
- Ran `testthat::test_dir()` after loading the temporary source with
  `pkgload::load_all(compile = FALSE)`. Collection used
  `stop_on_failure = FALSE` and `stop_on_warning = FALSE` so every file could run.
- The collection harness exited 0, but the suite has failures. Exit status alone
  is insufficient when failure stopping is disabled.
- Startup locale warnings were present. `R CMD check`, clean tarball inspection,
  documentation regeneration, website build, and online release/CI status were
  not checked. No package behavior was changed.

## Fresh native-build results

| Measure | Count |
| --- | ---: |
| Test blocks | 789 |
| Passing expectations | 1,046 |
| Failed expectations | 134 |
| Blocks with errors | 38 |
| Warnings | 59 |
| Skipped blocks | 1 |

These measures have different counting units; they are not additive test cases.
No coverage percentage was measured.

| Test file | Passing expectations | Failed expectations | Error blocks | Warnings |
| --- | ---: | ---: | ---: | ---: |
| browse | 27 | 1 | 0 | 1 |
| complex_tb (codebook) | 27 | 0 | 8 | 1 |
| cut | 74 | 3 | 0 | 9 |
| esttab | 50 | 1 | 0 | 5 |
| fre | 43 | 8 | 2 | 7 |
| fre1 | 66 | 4 | 8 | 2 |
| fre2 | 38 | 24 | 2 | 3 |
| import-export | 33 | 0 | 0 | 0 |
| names | 52 | 3 | 1 | 2 |
| row_egen | 74 | 19 | 2 | 1 |
| s_match | 29 | 0 | 0 | 2 |
| s_select | 71 | 0 | 0 | 2 |
| s_try | 42 | 4 | 0 | 6 |
| s_type | 47 | 0 | 2 | 0 |
| set_seed | 30 | 0 | 0 | 0 |
| summ | 57 | 0 | 4 | 6 |
| tab | 62 | 19 | 1 | 1 |
| tab1 | 77 | 4 | 5 | 1 |
| tab2 | 49 | 27 | 3 | 9 |
| timer | 37 | 2 | 0 | 1 |
| type_conversion | 61 | 15 | 0 | 0 |

The initial stale-DLL run recorded 1,023 passing expectations, 128 failed
expectations, 54 error blocks, 59 warnings, and one skip; its launcher exited 1.
The fresh build removed 16 error blocks and exposed additional native-result
assertions. Use the fresh results for triage.

## Representative findings

- **Reproduced source defect:** `as_numeric(c("1", "2.5", "3.14"))` returns
  scalar `NA_real_`; empty character input also loses its length.
- **Invalid fixtures:** `haven::labelled(..., na_values = -99)` uses an
  unsupported argument, several codebook fixtures have incompatible column
  lengths, and some sample calls request too many values without replacement.
- **Incorrect expectations:** an ordered factor is expected to use a level
  order that was never specified. Other output and grouping discrepancies need
  contract review before changing either tests or implementation.
- **Remaining native-family discrepancies:** `row_egen` still has 19 failed
  expectations and two error blocks after the new DLL loads.
- **Static maintenance findings:** SAS output uses a format inconsistent with
  the requested extension; generated summary help omits current arguments;
  website references and test/report automation are stale.

Not every failed test is a package defect. Passing import/export tests also do
not establish correctness for formats or behaviors those tests never assert.

## Evidence and reproduction

The temporary source copy was
`%TEMP%/statart-rebuilt-6ikisjzx/statart`. Temporary evidence has prefix
`%TEMP%/statart-rebuilt-baseline` (`.json`, `.csv`, and `.txt`). Temporary files
may be cleared by the operating system; this report retains the measured
baseline and per-file totals.

Protected-launcher log prefixes under `%TEMP%/CodexRLogs/`:

- Build: `20261016T003052158332Z-8db97d64` (exit 0).
- Fresh suite collection: `20261016T003117181786Z-ea73fa64` (exit 0 with failures retained).
- Initial stale-DLL suite: `20261016T002818736349Z-f6878bbd` (exit 1).

UTC timestamps fall on October 16; the local review date in America/New_York is
October 15. For ordinary development, use the protected testing commands in
[DEVELOPMENT.md](../../DEVELOPMENT.md#working-commands-on-windows). Rebuild in an
isolated source copy if preserving old compiled files is necessary.
