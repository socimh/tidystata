# Row calculations: type preservation and numerical acceptance

Verified 2026-10-16 (America/New_York), development version 0.2.0.9000.

## Outcome

Logical extrema now return TRUE/FALSE, integer extrema retain integer storage, and compatible classed inputs retain meaningful classes. Unsupported or incompatible combinations fail before numeric coercion. Public names/formals remain unchanged.

The existing C++ extrema and unique kernels remain. Classed extrema compare lossless vctrs ranks in C++, then slice the common original vector. Equality keys preserve integer64/list/complex identities for unique counts. Mean/sum use compiled base R. New C++ median and sample variance/SD kernels fix midpoint overflow, cancellation, and avoid overflowing variance before calculating a representable SD.

Rfast is no longer used and was removed from Imports, reducing required direct imports from 13 to 12. Optional units >= 1.0.0 supplies public measurement-scale validation. No new required dependencies or public exports.

## Verified results

- Full retained suite: **3,079 blocks / 16,674 passing expectations**, zero failures, errors, uncaptured warnings or skips.
- New type/numerical contracts: **26 blocks / 185 passing expectations**.
- Fresh native installation, source build and R CMD check --no-manual: **Status: OK**.
- Required-dependency-only smoke, all eleven demos and 92-file Air/parse/lintr checks pass.
- Standalone installed verification: `.opencode/tests/verify_row_types.R`.

Earlier failing probes are preserved locally. They reproduced logical type loss, unit stripping, SPSS metadata conflicts, integer64 precision loss, median overflow, negative/cancelled variance and ordered-factor order loss. Tests were observed failing before their fixes; raw evidence is retained.

## Type and operation contract

| Inputs | Extrema | Arithmetic | Counts |
| --- | --- | --- | --- |
| Plain logical/integer/double | Common logical/integer/double type | Double results | Integer |
| Date/POSIXct | Compatible common calendar type | Mean/median retain same calendar family; sum/dispersion require explicit conversion | Integer |
| difftime/hms | Compatible common duration type | Sum/mean/median/SD return difftime; variance requires an explicit numeric unit | Integer |
| Compatible measured vectors | Common normalized units | Linear scales retain units; variance has squared units | Integer |
| Affine/nonlinear measured scales | Compatible ordered extrema | Offset sum/SD/variance and all nonlinear arithmetic require explicit conversion | Integer |
| integer64 | Exact original values, no double conversion | Explicit conversion required | Exact equality and missingness, integer outputs |
| Labelled/SPSS | Underlying values; compatible metadata retained | Double after original missingness mask | Original missingness; incompatible metadata errors |
| Character/ordered factors | C lexical order / compatible factor level order | Rejected | Compatible common-type equality |
| Unordered factor/list/complex | Rejected | Rejected | Unique identity and original missingness |

All columns must be one-dimensional. Counts do not flatten list elements; scalar missing list elements are missing, NULL/empty elements are observed. Zero-column inputs error. Zero-row and all-missing extrema use the selected prototypes, not observed values. All-missing sums remain zero; other arithmetic/extrema are missing. Sample dispersion requires two observed values. Unknown numeric classes are rejected rather than silently stripped. Ordered factors cannot be mixed with character text for extrema. Common SPSS metadata cannot turn an originally observed value into missing.

## New executable cases

| Case | Passing expectations |
| --- | ---: |
| row extrema preserve logical values and typed missingness | 3 |
| row logical extrema preserve empty and single-column types | 4 |
| row logical extrema work with explicit and bare grouped selectors | 3 |
| logical arithmetic and counts retain operation-specific results | 8 |
| row extrema use the common logical integer double type | 6 |
| calendar extrema mean and median preserve their class | 8 |
| datetime extrema preserve timezone and missingness | 6 |
| duration calculations normalize units before aggregating | 7 |
| unit-aware calculations retain compatible physical dimensions | 12 |
| integer64 extrema and unique counts never round adjacent large integers | 10 |
| ordered extrema retain levels while unordered arithmetic is rejected | 7 |
| ordered factor extrema reject loss of their level ordering | 2 |
| character extrema use explicit lexical ordering without parsing | 6 |
| SPSS missing codes are excluded before any row calculation | 9 |
| list and complex columns support counts without numeric reinterpretation | 8 |
| row calculations reject structured columns instead of flattening cells | 10 |
| common SPSS metadata cannot turn an observed value into missing | 5 |
| numeric medians do not overflow when the true midpoint is finite | 1 |
| sample dispersion is stable for large offsets and magnitudes | 3 |
| affine units cannot disguise sums or dispersion as absolute scales | 6 |
| compiled row statistics agree with independent base references | 8 |
| row type follows selected prototypes rather than observed values | 36 |
| character ordering is locale-independent and preserves Unicode | 3 |
| unsupported numeric classes require explicit semantic conversion | 7 |
| classed extrema preserve input metadata and run accepted expressions once | 3 |
| large signed integer64 extrema retain exact order and identity | 4 |

## Selective real console output

```text
R launcher logs: C:\Users\socimh\AppData\Local\Temp\CodexRLogs\20261017T000640462897Z-b2b5b47a
row-types: .........................................................................................................................................................................................

== DONE ========================================================================

Verified type-contract blocks: 26
Passing expectations: 185

Logical row maximum preserves the original meaning:
# A tibble: 3 x 4
  a     b     any_flag true_count
  <lgl> <lgl> <lgl>         <dbl>
1 TRUE  FALSE TRUE              1
2 FALSE NA    FALSE             0
3 NA    NA    NA                0
Maximum type: logical

Dates remain dates in a subsequent research pipeline:
# A tibble: 2 x 3
  interview  follow_up  latest
  <date>     <date>     <date>
1 2024-01-01 2024-01-03 2024-01-03
2 NA         2024-01-05 2024-01-05

Compatible duration units are normalized before addition:
Time difference of 7200 secs

Large offsets no longer cause negative sample variance:
[1] 0.5
PASS: all type contracts and selective outputs verified.
R launcher exit: 0x00000000; status: C:\Users\socimh\AppData\Local\Temp\CodexRLogs\20261017T000640462897Z-b2b5b47a.status.json
```

## Reproduction

```powershell
python .opencode/workflows/verify_package.py --check --prefix .opencode/results/row-types-final
python .opencode/workflows/verify_package.py --minimal --prefix .opencode/results/row-types-minimal
python .opencode/workflows/verify_package.py --demos --prefix .opencode/results/row-types-demos
python .opencode/workflows/check_style.py
python C:/Users/socimh/.codex/scripts/run_r_safe.py -- Rscript .opencode/tests/verify_row_types.R <fresh-library>
python .opencode/workflows/summarize_row_types.py
```

## Boundaries before publication

This is verified Windows R 4.6.0 execution and static portability review. R 4.1, other platforms/compilers, oldest dependency combinations and actual GUI viewing remain separate validation. No universal input-class or performance claim is made. No push, merge, publication, release or artifact deletion was performed. Both previously generated PDFs are preserved unchanged.
