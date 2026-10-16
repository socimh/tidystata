# Modern R development adoption

Verified 2026-10-16; statart 0.2.0.9000.

## Verified results

- Full suite: 3,053 blocks, 16,492 passing expectations; zero failures, errors, uncaptured warnings or skips.
- Protected fresh native install, source build and R CMD check --no-manual exit 0; Status: OK.
- 90 adopted handwritten R files pass pinned Air 0.12.0, parsing and lintr 3.4.0 checks.
- Three Python scope tests pass, including Unicode Git paths and generated/archive path exclusions.
- All 40 exported interfaces and 24 output/visibility/diagnostic records match the pre-adoption installation.
- Eleven demos execute successfully; required-dependency-only smoke checks pass.
- Checked package sources/tests/help match the working sources byte-for-byte; both earlier PDFs are unchanged.

## Changes and compatibility

CONTRIBUTING.md owns the coding standard. Shared read-only tooling checks an explicit scope; formatting remains deliberate and uses a single authority. New PR R sources must enter scope.

Conversions cache their existing classification and use direct calls; type dispatch remains compatible with the previous implementation. Missing-value wrappers remain delegated. Documentation now states casting, metadata, SPSS/tagged missingness and precision behavior precisely.

Row/binning, selection/type and utility implementations received surgical readability changes. Tests pin interval boundaries, missing rows, types, warnings, promise evaluation, visibility and RNG effects. Accepted summary/tabulation/inspection catalogues remain intact. Fifteen previously uncaptured warnings are now asserted; the old empty interval-width test now checks exact assignments.

Six help topics were regenerated from roxygen sources. Maintained demos and verification R scripts are formatted and demos load the fresh installed package, replacing repeated development loads. The timer demo explicitly qualifies its private formatting helper. The report generator supports --index-only, replacing temporary index-extraction workarounds without rerunning demos. Historical scripts and result artifacts are preserved.

No exported names, signatures/defaults, runtime Imports count (13), R minimum (4.1), or established statistical/output contracts changed.

## Dependency constraints

These floors cover APIs and documented casting behavior, not tested oldest-version combinations.

| Dependency | Floor | Reason/source |
| --- | --- | --- |
| purrr | 1.0.0 | [list_rbind](https://purrr.tidyverse.org/news/index.html#purrr-100) |
| stringr | 1.5.0 | [str_split_1](https://stringr.tidyverse.org/news/index.html#stringr-150) |
| tibble | 3.0.0 | [as_tibble_col](https://tibble.tidyverse.org/news/index.html#tibble-300) |
| tidyr | 1.2.0 | [strict replacement casting](https://tidyr.tidyverse.org/news/index.html#tidyr-120) |
| vctrs | 0.6.0 | [obj_is_vector](https://vctrs.r-lib.org/news/index.html#vctrs-060) |
| Rfast | 1.9.6 | [released rowMedians na.rm API](https://raw.githubusercontent.com/cran/Rfast/1.9.6/R/median.R) |

## New focused contract cases

57 new blocks with 266 passing expectations. These complement retained suites and exact-value improvements; no fixed scenario quota was used.

| File | Contract | Expectations |
| --- | --- | ---: |
| test-conversion-contracts.R | conversion drops vector metadata without modifying inputs | 3 |
| test-conversion-contracts.R | conversion flattens matrices in column order | 4 |
| test-conversion-contracts.R | conversion returns typed empty vectors | 14 |
| test-conversion-contracts.R | conversion distinguishes numeric missing values from their text | 3 |
| test-conversion-contracts.R | number parsing retains exact diagnostic rows and positions | 6 |
| test-conversion-contracts.R | factor conversion uses level text and level codes | 2 |
| test-conversion-contracts.R | labelled conversion preserves raw values and partial labels | 3 |
| test-conversion-contracts.R | tagged missing labels are displayed while numeric tags survive | 4 |
| test-conversion-contracts.R | tagged missing values without labels use ordinary character coercion | 2 |
| test-conversion-contracts.R | SPSS user missing codes remain values during conversion | 4 |
| test-conversion-contracts.R | labelled character numeric values use ordinary numeric coercion | 4 |
| test-conversion-contracts.R | lists and unsupported numeric inputs retain element count | 4 |
| test-conversion-contracts.R | calendar conversion uses days and UTC seconds | 4 |
| test-conversion-contracts.R | duration conversion retains its stated units | 3 |
| test-conversion-contracts.R | measured conversion drops units without changing values | 3 |
| test-conversion-contracts.R | integer64 conversion retains character precision and warns on numeric loss | 4 |
| test-conversion-contracts.R | missing replacement preserves vector type and names | 3 |
| test-conversion-contracts.R | missing replacement supports vector comparisons and NaN | 3 |
| test-conversion-contracts.R | missing replacement preserves categorical and date classes | 3 |
| test-conversion-contracts.R | missing replacement returns typed empty inputs | 4 |
| test-conversion-contracts.R | missing replacement reports incompatible sizes and lossy casts | 4 |
| test-conversion-contracts.R | conversion composes in research preparation without mutating source | 4 |
| test-row-binning-contracts.R | row contracts: numeric backends agree with independent row references | 31 |
| test-row-binning-contracts.R | row contracts: typed zero-row inputs return plain empty vectors | 30 |
| test-row-binning-contracts.R | row contracts: a single observed column has undefined sample variance | 4 |
| test-row-binning-contracts.R | row contracts: logical and integer inputs remain unmodified | 3 |
| test-row-binning-contracts.R | row contracts: explicit pick and bare selectors agree in mutate | 20 |
| test-row-binning-contracts.R | row contracts: grouped mutate preserves grouping and row order | 4 |
| test-row-binning-contracts.R | row contracts: an accepted data-frame expression runs once | 2 |
| test-row-binning-contracts.R | row contracts: accepted data-frame warnings are replayed once | 4 |
| test-row-binning-contracts.R | row contracts: counts accept nonnumeric columns and return integers | 2 |
| test-row-binning-contracts.R | row contracts: numeric helpers reject character columns clearly | 8 |
| test-row-binning-contracts.R | binning contracts: quantile codes use type-7 boundaries | 2 |
| test-row-binning-contracts.R | binning contracts: collapsed quantile boundaries preserve all ties | 4 |
| test-row-binning-contracts.R | binning contracts: quantile permutation preserves value assignments | 1 |
| test-row-binning-contracts.R | binning contracts: equal-width edges use right-closed intervals | 2 |
| test-row-binning-contracts.R | binning contracts: explicit boundaries respect either closure | 2 |
| test-row-binning-contracts.R | binning contracts: supplied breaks sort and deduplicate with endpoints | 1 |
| test-row-binning-contracts.R | binning contracts: defaults and custom labels preserve ordering | 2 |
| test-row-binning-contracts.R | binning contracts: binning does not mutate source values or labels | 1 |
| test-selector-utility-contracts.R | s_select forces its data promise once and preserves selected attributes | 3 |
| test-selector-utility-contracts.R | s_select no-argument return preserves grouping and object identity | 3 |
| test-selector-utility-contracts.R | s_select evaluates selection predicates once per column | 2 |
| test-selector-utility-contracts.R | s_select preserves successful warning conditions and their order | 2 |
| test-selector-utility-contracts.R | s_select reports both failed branches without replaying their warnings | 5 |
| test-selector-utility-contracts.R | s_match returns positions with explicit variables and keeps matching boundaries | 6 |
| test-selector-utility-contracts.R | s_type and s_unit preserve labelled and duration metadata | 6 |
| test-selector-utility-contracts.R | s_type returns visible type names for empty and named vectors | 4 |
| test-selector-utility-contracts.R | timer evaluates its promise once and returns the exact object invisibly | 3 |
| test-selector-utility-contracts.R | timer propagates the original error and emits no completion message | 2 |
| test-selector-utility-contracts.R | set_seed seeds before evaluation and leaves the advanced global RNG state | 4 |
| test-selector-utility-contracts.R | set_seed keeps RNG effects when the expression fails | 2 |
| test-selector-utility-contracts.R | set_seed preserves result attributes and invisible expressions | 1 |
| test-selector-utility-contracts.R | s_try evaluates once and preserves warnings and messages | 4 |
| test-selector-utility-contracts.R | s_try preserves the existing try-error classification and visible result | 3 |
| test-selector-utility-contracts.R | s_select preserves RNG consumption across a failed selection and fallback | 3 |
| test-selector-utility-contracts.R | set_seed rejects an invalid seed before forcing the expression | 2 |

## Review and limits

Cross-review covered changes outside each specialist's authored scope. Review fixes include NUL-delimited Unicode Git paths, canonical generated/archive path exclusions, and the tidyr casting floor. The path defects were reproduced by failing tests before fixes; the final scope tests pass. Installed-package demos first exposed the timer helper lookup, then all eleven passed after qualification.

Current execution is Windows R 4.6.0. CI now explicitly includes R 4.1, alongside existing Windows/macOS/Linux and development-R checks, but remote CI has not run. Old dependency combinations and actual interactive viewer rendering remain unverified. Known locale/display and legacy binning boundaries documented in prior acceptance reports remain applicable.

The /style workflow is check-only. Website deployment requires an explicit manual deploy input. No push, merge, website deployment, package publication or release was performed.

## Reproduction

```powershell
python .opencode/workflows/check_style.py --base ac7cea3
python -m unittest discover -s .opencode/tests -p test_style_workflow.py
python .opencode/workflows/verify_package.py --check --prefix .opencode/results/style-adoption-final
python .opencode/workflows/verify_package.py --minimal --prefix .opencode/results/style-adoption-minimal
python .opencode/workflows/verify_package.py --demos --prefix .opencode/results/style-adoption-demos
python .opencode/workflows/summarize_style_adoption.py
```

The differential verifier takes an installed library, baseline/compare mode and a record path. The preserved pre-adoption record is style-adoption-baseline.rds; regenerate it from ac7cea3 when intentionally changing the baseline. Windows R invocations must use the protected launcher.

Detailed execution logs, CSVs and tooling evidence are under .opencode/results/style-adoption-*.
