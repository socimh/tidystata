# Developing statart

statart **0.2.0.9000** provides Stata-inspired data exploration and preparation
and is stabilizing toward a future 0.3.0 release. This is the single current
package map, verification status and backlog. See [CONTRIBUTING.md](CONTRIBUTING.md)
for the coding standard and [MIGRATION.md](MIGRATION.md) for public contracts.

## Current verification

**Long-function splits, 2026-10-20 (same branch):** `xtile()` 140 to 41
lines (`xtile_rank()`, `xtile_quantile()`), `s_merge()` 131 to 78
(`merge_renamed()`, `merge_check_relationship()`, `merge_drop_shared()`,
`merge_join()`, `merge_check_assert()`), `summ()` 196 to 143
(`summ_check_flags()`, `summ_rename_reserved_groups()`, `summ_finalize()`),
`summ_variable()` 210 to 166 (pure statistic steps extracted). Full suite
19,518 passing, zero failures/warnings/skips; style 144 sources, 0 findings.
`benchmark_core.R --filter=xtile|s_merge|summ`, two interleaved rounds per
build: result hashes identical; timing changes -6% to +5% (largest
`xtile_grouped` +60 ms on 1,965 ms, 10,000 groups), inside the 10%/5 ms
tolerance. `s_type()`/`s_unit()` now soft-deprecated.

**Policy consistency pass, 2026-10-20 (same branch):** `var_type()` and
`var_unit()` made primary; naming policy clarified (dot rule, `.type` values,
alias vs deprecation, `.missing` defaults, re-raised conditions). `--release`
suite **19,518 passing expectations**, zero failures, errors, warnings or
skips; `R CMD check --as-cran` 0 errors, 0 warnings, the same CRAN-incoming
NOTE; style check 144 sources, 0 findings; vignette `tab2(.by)` chunk renders.

**API naming pass, 2026-10-20 (same branch):** `--release` suite **19,518
passing expectations**, zero failures, errors, warnings or skips; `R CMD check
--as-cran` 0 errors, 0 warnings, the same CRAN-incoming NOTE; seeded shuffle
identical; style check 144 sources, 0 findings; all 24 demos pass (reports
changed only for the renamed arguments). README re-rendered with ASCII output.

**Tidyverse conventions pass, 2026-10-20 (branch
`refactor/tidyverse-conventions`):** `--release` suite **19,469 passing
expectations**, zero failures, errors, warnings or skips (snapshot tests now
run with `NOT_CRAN=true`); `R CMD check --as-cran` gives 0 errors, 0 warnings
and the existing CRAN-incoming NOTE (new submission, six unpublished URLs). The
seeded shuffle (`--shuffle-seed 20261020`) passes identically. Style check:
144 sources, 0 findings; `pkgdown::check_pkgdown()` finds no problems.
Changes: R files named after their functions or families; tests regrouped to
mirror `R/` (1,319 blocks retained); conditions via cli with shared
`R/utils-check.R` checkers and per-family error snapshots; `@returns`,
`@family` and `statart_args`; family-prefixed helpers; demos refreshed for the
new wording. The baseline before this pass found two unasserted warnings in
`test-aggregation-core.R`, now asserted. An in-place `load_all()` debug build
once returned `NA` for a `NaN` group sum in `group_sum_dbl`; fresh installed
builds match, but the payload rule may deserve a targeted check.

**Speed audit, 2026-10-20 (live checkout):** `--release` suite **19,416
passing expectations across 3,364 blocks**, zero failures, errors, warnings or
skips; `R CMD check --as-cran` gives 0 errors, 0 warnings and 1 NOTE (CRAN
incoming feasibility). The style check (157 sources) and demos pass; the
regenerated reports differed only in timestamps, `timer()` durations and the
unseeded `rnorm()` example in `report_cut.md`, so they were restored.

The new `.opencode/tests/benchmark_core.R` times 57 workloads across every
core family (`--references` adds Rfast, matrixStats, collapse and data.table
as diagnostic ceilings, `--profile` profiles). Three alternating rounds of the
committed and candidate builds produced identical output hashes for all 57;
`benchmark_problems2.R` records (30) and all 80 export interfaces are
bit-identical too. An edge battery of 163 cases (NA/NaN payloads, signed
zeros, overflow, empty and single-value groups, errors and warnings) is
byte-identical. Paired medians:

| Workload | Before | After |
| --- | ---: | ---: |
| `row_unique`, 1,000,000 x 5 | 300 ms | 55 ms |
| `row_max`, 100,000 x 50 | 240 ms | 70 ms |
| `row_sd`, 1,000,000 x 5 | 320 ms | 115 ms |
| `summ(.detail = TRUE)`, 10,000 groups | 1,060 ms | 240 ms |
| weighted `tab`, 10,000 groups | 200 ms | 80 ms |
| `s_merge` m:1, 1,000,000 rows | 170 ms | 70 ms |
| `destring`, 1,000,000 strings | 250 ms | 85 ms |
| `pwcorr`, 20 variables | 330 ms | 200 ms |
| grouped `xtile`, 10,000 groups | 980 ms | 640 ms |

Causes and fixes: row kernels built a protected cpp11 vector per cell (now
column pointers read once; sums and means are native with long double, like
`rowSums()`); row helpers and `xtile()` probed `dplyr::cur_group_id()` outside
verbs, costing about 5 ms per call in rlang/cli message formatting (now
skipped unless a dplyr frame is on the stack); `tab` and weighted counts used
per-group R loops (now `src/group_stat.cpp`, reproducing `sum()`, `cumsum()`
and `mean()` bit for bit, including `cumsum()`'s NA/NaN rules); `summ()` with
many small groups (average size at most 1,000) sorts once for quantiles,
medians and MADs; `destring()` trimmed every string; `pwcorr()` copied both
columns per pair; `s_merge()` built character statuses. No dependencies,
exports or outputs changed. No other workload slowed by more than both 10%
and 5 ms; two first-pass flags (`duplicates_report`, `s_lag_single`, code
unchanged) were noise in five further alternations. Receipts are under
ignored `.opencode/results/perf-core/`.

**Round 8 Stata names and aliases, 2026-10-20 (live checkout):**
`--release` suite **19,379 passing expectations across 3,357 blocks**, zero
failures, errors, warnings or skips; `R CMD check --as-cran` gives 0 errors,
0 warnings and 1 NOTE (CRAN incoming feasibility), and the installed-resource
check passes with the export guards in `.opencode/tests/` raised from 68 to 80.
The minimal-dependency and style checks (157 sources) pass, demos pass
(24 families; only the `findit`, `keys` and `tab` reports changed), and a fresh
site build renders both `findit()` articles and the alias help pages. A first
release attempt failed on two literal information glyphs (now `ℹ`
escapes) and on a `test-problems2-tab.R` message pattern that still named
`xtab()`.

**Round 7 `assert()`, `is_first()`, `print_all()`, 2026-10-19 (live
checkout):** `--release` suite **19,298 passing expectations across 3,347
blocks** (includes the concurrent agent's updated `findit()` tests), zero
failures, errors, warnings or skips; `R CMD check --as-cran` gives 0 errors,
0 warnings and 1 NOTE. The full and seed-20261027 reordered suites passed
19,271 / 3,344 just before. Demos pass (24 families, including `checks`),
and the minimal-dependency and style checks (156 sources) pass. Ordered-factor
`time` support passed its own full run earlier (19,227 / 3,335). An earlier
Round 7 release attempt failed only in `test-findit.R` while the other agent
was mid-edit; demo scripts must not assign `failure`, which the report
generator uses.

**Round 6 follow-up (more `time` types for `s_lag()` and friends),
2026-10-19 (live checkout):** full, seed-20261025 reordered and `--release`
suites each **19,222 passing expectations across 3,334 blocks**, with zero
failures, errors, warnings or skips. Demos (23), the minimal-dependency check
and the style check (151 sources) pass; `R CMD check --as-cran` gives
0 errors, 0 warnings and 1 NOTE. tsibble period cases were checked once with
tsibble 1.2.0 in a scratch library (tsibble is not a dependency).

**Round 6 `s_lag()`, `s_lead()`, `s_diff()`, 2026-10-19 (live checkout):**
full and `--release` suites **19,200 passing expectations across 3,331
blocks**, with zero failures, errors, warnings or skips, after updating the
`findit(L.x)` expectation to the new `s_lag()` entry; the seed-20261024
reordered run before that fix differed only by that expectation. Demos pass
(23 families, including `panel`), the minimal-dependency check passes, the
style check is clean (151 sources), and `R CMD check --as-cran` gives
0 errors, 0 warnings and 1 NOTE (CRAN incoming feasibility). Panel operators
match StataNow 19 `L.`/`F.`/`D.` output on annual (gaps, unsorted, missing),
`delta(5)`, `%tm` and `%tq` panels.

**Round 5 `std()`, `pct()`, `as_dummy()`, 2026-10-19 (live checkout):** full,
seed-20261023 reordered and `--release` suites each **19,151 passing
expectations across 3,325 blocks**, with zero failures, errors, warnings or
skips. Demos pass (22 families, including `dummy`), the minimal-dependency
check passes, the style check is clean (148 sources), and
`R CMD check --as-cran` gives 0 errors, 0 warnings and 1 NOTE (CRAN incoming
feasibility).

**Vector aggregation core, 2026-10-19 (integrated Windows / R 4.6.0):**
full suite **19,102 passing expectations across 3,317 blocks**, with zero
failures, errors, warnings or skips. The new aggregation regressions contribute
49 expectations across 12 blocks. All **143** pinned style/parsing/lint sources,
**21** demo families and migration-copy checks pass. Fresh source build,
actual-archive installation and installed-resource/example verification pass.
Complete `R CMD check --as-cran`, including archive tests, vignettes and PDF/HTML
manuals, finishes with **0 errors, 0 warnings and 1 NOTE** for development
metadata and six unpublished URLs. Initial sandbox attempts failed on CRAN and
TeX access; normal-system verification of the identical archive completed.

The core computes counts, percentages and rectangular cross-tables from vectors
and native vctrs identities. Group locations are reused for totals and across
summary families; row IDs are allocated only when needed. Summaries classify
vectors once, assemble columns per family, and skip unrequested weighted
quantiles and spreads. Class conversion and presentation stay at the boundaries.
No new C++ or dependencies were added. Concurrent `pwcorr()`, `misstable()` and
`xtab(.chi2 =)` additions were preserved and included in final validation.

| Paired complete-call workload | Frozen baseline | Refactor | Reduction |
| --- | ---: | ---: | ---: |
| `tab`, 100,000 rows / 10,000 groups | 210 ms | 60 ms | 71% |
| `xtab` with totals, 2,000 row categories / five columns | 50 ms | 6 ms | 88% |
| Weighted `summ` mean, 1,000,000 rows / two variables | 225 ms | 95 ms | 58% |

Repeated standalone runs showed machine drift in unchanged controls, so the
acceptance comparison alternated compiled frozen-baseline and installed-candidate
calls on identical inputs within each workload, after warm-up, using adaptive
batches and seven repetitions. All 31 workloads stayed within the regression
limit (both 10% and 5 ms); ordinary and mixed summaries also improved by 43% and
27%. Weighted-mean allocations fell from 315.6 to 139.3 MB; these are allocated
bytes, not peak memory. The 30 saved value/visibility/diagnostic records and all
57 then-existing export signatures matched before concurrent API additions.
Rfast 2.1.5.2 matched the limited dense-integer-count and finite-group-sum
references; no broader class or weighted equivalence is claimed.

The maintained `.opencode/tests/benchmark_problems2.R` now includes weighted,
wide and mixed workloads plus output/interface/session receipts. Frozen sources,
paired driver, hashes, comparisons and check/install receipts are retained under
ignored `.opencode/results/aggregation-core/`. Other platforms and dependency
floors remain the existing remote release gates below; no publication occurred.

**`findit()` R-function descriptions widened, 2026-10-19 (live checkout):**
`inst/extdata/r-functions.csv` now describes 607 R functions (316 used in the
entries plus 291 common ones), each with a related Stata command; all 599
in installed namespaces were confirmed as exports, and the other 8 against
CRAN NAMESPACE files. Functions without entries print their description and
related Stata command. Full suite **19,305 passing expectations across 3,348
blocks**, zero failures, errors, warnings or skips (`test-findit.R`: 103 /
14). Style check clean (156 sources); demos pass; both articles render all
607 descriptions. Not rerun: `--release`.

**`findit()` R-function lookup, 2026-10-19 (live checkout):** `findit()` also
accepts R function names (`left_join`, `lm()`, `dplyr::left_join`), shows both
meanings for words such as `log`, and adds a `match` column. New
`inst/extdata/r-functions.csv` describes all 316 R functions in English and
Chinese; a test keeps it in sync with the entries. Full suite **19,298 passing
expectations across 3,347 blocks**, zero failures, errors, warnings or skips
(`test-findit.R`: 96 / 13). Style check clean (156 sources); the findit demo
passes; both articles, now ending with a function index, render fully. The
concurrent `checks` demo reports FAIL in its own report (not part of this
work). Not rerun: `--release`.

**`findit()` coverage round 2, 2026-10-19 (live checkout):** 207 entries added
(414 in total, 250 commands and functions) after checking against the Stata
Training cheat sheets and Stata 17-18 table commands. Full suite **19,159
passing expectations across 3,326 blocks**, zero failures, errors, warnings or
skips (`test-findit.R`: 69 / 10; every entry parses and is single-line ASCII).
All 82 qualified `pkg::fun` calls exist (74 checked in installed namespaces, 8
in CRAN NAMESPACE files). Style check clean (148 sources); demos pass. A fresh
site build exposed and fixed a round-1 bug: pkgdown renders articles in a
non-UTF-8 locale, so Chinese headings and notes printed as `<U+xxxx>`; table
text is now entity-encoded and both articles render fully. Not rerun:
`--release`.

**Round 4 `pwcorr()`, `misstable()`, `xtab(.chi2 =)`, 2026-10-19 (live
checkout):** full suite **19,053 passing expectations across 3,305 blocks**;
the seed-20261022 reordered suite and the `--release` suite **19,101 across
3,316** (a concurrent agent added aggregation tests mid-run). All had zero
failures, errors, warnings or skips. Demos pass (21 families, including
`pwcorr` and `misstable`), the minimal-dependency check passes, the style
check is clean (141 sources), and `R CMD check --as-cran` gives 0 errors,
0 warnings and 1 NOTE (CRAN incoming feasibility).

**Round 3 weights, 2026-10-19 (live checkout, includes `findit()`):** full
suite and seed-20261021 reordered suite each **18,959 passing expectations
across 3,295 blocks**, zero failures, errors, warnings or skips. Demos pass
(19 families, including `weights` and `findit`), the minimal-dependency check
passes, and `--release` (fresh build, resources, `R CMD check --as-cran`)
gives 0 errors, 0 warnings and 1 NOTE (CRAN incoming feasibility, offline URL
checks).

**`findit()` addition, 2026-10-19 (live checkout, fresh source copy):** full
suite **18,918 passing expectations across 3,287 blocks**, with zero failures,
errors, warnings or skips (`test-findit.R`: 61 / 9). Pinned style checks pass
(132 sources). Demos pass, and the findit report and index are generated.
Migration copies are current, README.md re-renders with only the new paragraph,
and a fresh website build includes both "Coming from Stata" articles and the
reference entry. `help.search("stata")` lists `findit`. Not rerun: `--release`
and `R CMD check --as-cran`. This run covers the concurrent xtab/s_merge edits
in the same checkout, but certifies only the test outcome.

Verified **2026-10-19** on Windows / R 4.6.0 in the isolated snapshot after two
aggregation/metadata performance passes. Concurrent naming/API changes appeared
in the live checkout afterward; the results below do not certify those edits or
their integration. The results below describe that earlier snapshot; the current
aggregation sources have since changed:

- Fresh full suite: **18,761 passing expectations across 3,260 blocks**, with
  zero failures, errors, unexpected warnings or skips.
- Dedicated type/unit coverage grew from **74 expectations / 39 blocks** to
  **418 / 107**. It covers storage types, empty/missing values, factors, labelled
  and SPSS vectors, calendars/durations, classed matrices, list-of/records, S4,
  integer64, units, hms, sf, custom labels and custom unit methods.
- All **121-source** pinned style/parsing/lint checks and **16 demos** pass.
  The codebook demo/report now shows structured and custom type descriptions.
  Help is regenerated from roxygen source.
- All **46 public interfaces** and **24 maintained compatibility records** remain
  unchanged. All **22 core benchmark return/visibility/diagnostic records** match
  the preceding implementation exactly. New type regressions independently verify
  the intentional fixes for previously corrupted or misleading custom labels.
- Fresh source build, actual-archive installation and installed-resource/six-script
  verification pass. Complete `R CMD check --as-cran` finishes with **0 errors,
  1 WARNING, 1 NOTE**, including archive tests, vignettes and PDF/HTML manuals.
  The pre-existing non-ASCII information symbol in `R/summ-helpers.R` and the
  development-metadata/unpublished-URL NOTE remain. No new check issue remains;
  the strict release gate is still not passing.

The implementation reuses existing native routines. Tabulation uses native vctrs
row grouping; summaries select statistics once per variable and reuse group
slices. Single-group distinct counts avoid a redundant identity pass. Codebooks
assemble one output table, and cross-table totals use vectorized sums with integer
storage/promotion preserved. Plain type/unit metadata avoids repeated formatting;
custom descriptions remain intact and numeric-looking prefixes no longer imply
summary support. Haven conversion requires an actual haven-labelled class.
No public arguments, dependencies, datasets or custom native kernels were added.

### Performance evidence

The maintained benchmark covers 23 calls with fixed inputs, warm-up and seven
batches. Batches target about 100 ms and are capped at 100 calls, allowing fast
metadata calls to be measured above clock resolution. The second-pass repeated
medians below compare fresh installations before and after the metadata changes;
all timings include preparation and result construction.

| Workload | Before | After | Reduction |
| --- | ---: | ---: | ---: |
| `codebook`, 1,000 rows / 1,000 integer columns | 2,560 ms | 15.5 ms | 99% |
| `summ` unique only, 1,000,000 rows / two numeric columns | 110 ms | 55 ms | 50% |
| `fre2`, 2,000 row categories / five column categories | 430 ms | 50 ms | 88% |
| `summ`, 10,000 rows / 40 numeric columns / 100 groups | 350 ms | 80 ms | 77% |
| `codebook`, 1,000,000 rows / four columns | 85 ms | 55 ms | 35% |

The first pass separately improved many-group `tab` from 750 to 220 ms and default
`summ` from 670 to 270 ms. These measurements are workload-specific, not cumulative
speedup promises. Unchanged controls showed machine-load variation between runs;
no slowdown exceeding both 10% and 5 ms recurred in the repeat. Each retained
optimization exceeds the 20% targeted-workload threshold. Single-group distinct
summary allocations fell from 132.8 to 100.0 MB; cross-table allocations fell from
9.21 to 2.59 MB. Allocated bytes are not peak resident memory.

Reproduce with `.opencode/tests/benchmark_problems2.R`, supplying an explicit fresh
installation library and output prefix through the protected R launcher. Keep
measurements out of unit-test assertions. Receipts, comparisons and logs remain
in ignored `.opencode/results/performance/` and `performance2/`.

The preceding repository cleanup is backed up externally, including ignored files
and Git metadata. Its historical workflow/site checks passed; they are not newly
rerun performance gates. Original notes under `.opencode/notes/` are preserved.

## Package map

The namespace contains **80 exports**: 79 functions and `%>%`. Fourteen
are quiet aliases (`xtab`, `na_if_value`, `value_if_na`, `as_numeric`,
`as_character`, `pct`, `s_tag`, `tab_gen`, `var_type`, `var_unit`,
`cut_quantile`, `s_try`, `ds_as_column`, `names_as_column`) documented on their
primary's help page, and one is deprecated (`s_match`). The package has
14 required Imports (cli and lifecycle joined on 2026-10-20), two bundled datasets (`lifeexp`, `starwars`), and cpp11
native row kernels. R >= 4.1 is required.

| Area | Public functions |
| --- | --- |
| Stata lookup | findit |
| Tabulation | tab, tab1, tab2, fre, fre1, fre2 |
| Summaries | summ, tabstat, pwcorr, misstable |
| Inspection | codebook, browse, ds, variables, variables_search |
| Keys, duplicates and merging | isid, duplicates_report, duplicates_tag, duplicates_list, duplicates_drop, is_first, assert, s_merge |
| Row calculations | row_mean, row_sum, row_min, row_max, row_median, row_var, row_sd, row_unique, row_nvals, row_miss, row_non_miss |
| Conversion | destring, decode, tostring, mvdecode, mvencode |
| Selection and types | s_select, varlist, s_type, s_unit |
| Binning | xtile, cut_length, cut_breaks |
| Variable transforms | std, pc, as_dummy |
| Panel operators | s_lag, s_lead, s_diff |
| Utilities | timer, set_seed, capture |
| Aliases | xtab, na_if_value, value_if_na, as_numeric, as_character, pct, s_tag, tab_gen, var_type, var_unit, cut_quantile, s_try, ds_as_column, names_as_column |
| Deprecated | s_match |
| Table previews | preview_table, unpreview_table, s_print, print_headtail, print_interval, print_all, slice_headtail, slice_interval |

| Location | Maintained content |
| --- | --- |
| `R/`, `src/`, `tests/testthat/` | Package source, native code and active regression coverage |
| `man/`, `NAMESPACE` | Generated help and namespace; edit roxygen sources |
| `data/`, `data-raw/`, `inst/DATA-PROVENANCE.md` | Preserved datasets, exact reconstruction and provenance |
| `inst/examples/`, `vignettes/` | Plain manual examples, viewer checklist and tutorials |
| `inst/extdata/stata-to-r.csv` | Hand-curated `findit()` entries (English and Chinese); the source for the "Coming from Stata" articles |
| `.opencode/demos/`, `.opencode/reports/` | Current actual-output demos and generated reports/index |
| `.opencode/workflows/`, `.opencode/tests/` | Current verification tools and specialized checks/benchmarks |
| `.opencode/notes/` | Unchanged original issue notes, screenshots and follow-up handover |
| `.opencode/tools/`, `.opencode/results/` | Ignored local tool installations and disposable verification results |

README content lives in `README.Rmd`; website organization lives in
`_pkgdown.yml`. `MIGRATION.md` generates the installed guide and website article.
Website output is derived and is built independently from deployment. Retired
wrappers and historical development archives are no longer shipped in the
checkout; consult migration alternatives, Git history for tracked versions or
the maintainer's external backup. The root `run_tests.R` remains a compatibility
entry point. `make clean` removes nothing.

## Established choices

The user-approved follow-up decisions remain binding:

- Summaries sort groups by default (`.sort = TRUE`) and hide the single-variable
  `name` column (`.name = FALSE`); `.drop_empty` remains opt-in.
- `timer()` reports on failure (`on_error = TRUE`) and rethrows the untouched
  error. Nested timers measure their entire enclosed expressions cumulatively.
- Row numeric constants are values, as in `pmin()`; they never fill an all-missing
  row. Named tabulation/summary constants are computed; unnamed numbers select
  column positions. Column expressions are computed once and selection typos
  must not silently evaluate unrelated globals.
- Quantile cuts use the documented xtile rule with type-7 cutpoints, occupied
  groups renumbered consecutively and warnings for collapsed groups. Rank mode
  remains explicit. Grouped default cuts return group-relative integer codes.
- The latest low-severity follow-up supports vectors in `fre()`/`tab1()`/`fre1()`,
  names piped summary vectors `value`, rounds mixed-table numeric text to seven
  significant digits, returns calendar spreads as `difftime` columns in list
  mode and numeric unit-labelled spreads in table mode, and handles `hms` clocks.
  It also adds actionable `.by` errors, grouping-column row inputs and supported
  sf previews/slices. Their regressions, formerly `test-problems2-low.R`, now
  live in `test-summ.R`, `test-tab.R`, `test-cut.R`, `test-row-stats.R` and
  `test-preview.R`;
  older readiness triage dispositions deferring them are superseded.

Mixed calendar/numeric location columns in table mode remain character; choose
list mode to retain separate numeric tables. `starwars` attachment masking is
normal namespace lookup; use qualified dataset names. Existing container,
missingness, grouping, class and locale boundaries are documented in migration
and help. The old long-duration summary formatter was replaced by duration
columns; its historical wording checks are not current formatter coverage.

## Working commands

Run from the project root. Repository automation uses a fresh temporary source
copy and installation; Windows R commands pass through the protected launcher.
Inspect exit status and complete logs before claiming success.

```powershell
python .opencode/workflows/check_style.py
python .opencode/workflows/verify_package.py --prefix .opencode/results/current
python .opencode/workflows/verify_package.py --filter type_conversion --prefix .opencode/results/current-focused
python .opencode/workflows/verify_package.py --shuffle-seed 20261019 --prefix .opencode/results/current-reordered
python .opencode/workflows/verify_package.py --minimal --prefix .opencode/results/current-minimal
python .opencode/workflows/verify_package.py --demos --prefix .opencode/results/current-demos
python .opencode/workflows/verify_package.py --release --prefix .opencode/results/current-release
python .opencode/workflows/generate_migration.py --check
```

`make test`, `make test-<family>`, `make demo-reports` and `make style-check`
provide shortcuts. `--release` includes vignettes, PDF manual and `--as-cran`;
`--check` is a faster development check. Check, release, minimal and demos are
mutually exclusive modes. Compare reordered tests by source/test identity and
outcome, excluding timings. The [workflow guide](.opencode/workflows/README.md)
describes the maintained tools. [Plain examples](inst/examples/README.md) cover
installation and direct calls; [current reports](.opencode/reports/INDEX.md)
show generated console output.

## Open backlog and release gates

- **API naming (decided 2026-10-20):** the maintainer's decisions are written
  as the naming policy in CONTRIBUTING ("Package conventions"): `x` as the
  first argument of vector and expression functions; dots only on options
  after a `...` taking columns or expressions (`na.rm` excepted);
  `var_type()`/`var_unit()` primary over `s_type()`/`s_unit()`; `by` for
  merge keys and `.by` for groups;
  `.missing` for missing-as-group controls (replacing `summ(.na.rm)`);
  `.type` for output containers (replacing `summ(.mode)`); `arg_match()`;
  lifecycle deprecations; and `tab2(.by)` returning a list. Old argument names
  keep working with soft deprecation warnings; remove them in a later release.
- **Long-function refactors:** done 2026-10-20 (see Current verification).
  `summ_variable()` keeps its lazily cached per-group closures; splitting
  those further would need an explicit state object and new timings.
- **Argument checks:** `R/utils-check.R` mirrors the checkers rlang 1.2.0
  exports. Requiring `rlang (>= 1.2.0)` would allow using rlang's own versions
  once the dependency floor is reviewed.

- **Naming and additions (in progress, one batch per round):** follow the
  [naming and gaps review](.opencode/notes/naming-and-gaps-review.md); its
  status table records what is done. Round 1 (2026-10-19) renamed `xtile`,
  `varlist`, `capture` and `ds_as_column`, and added `isid()`/`duplicates_*()`.
  Round 2 added `xtab()` (replacing `tab2`/`fre2`), `.total` for `tab`/`tab1`,
  `s_merge()` and the "Coming from Stata" guide in MIGRATION. Round 3 added
  `.wt`/`.wt_type` to the tab family, `summ()`/`tabstat()` and `xtile(wt =)`.
  Round 4 added `pwcorr()`, `misstable()` and `xtab(.chi2 = TRUE)`.
  Round 5 added `std()`, `pct()` and `as_dummy()`.
  Round 6 added gap-aware `s_lag()`, `s_lead()` and `s_diff()`, checked
  against StataNow 19. Round 7 added `assert()`, `is_first()` (Stata's
  `egen tag()`; renamed by the maintainer because `tag` clashes with
  htmltools/shiny) and `print_all()`. The ranked gap list is complete.
- **Dataset distribution:** keep both datasets and notices unchanged and hold
  public distribution pending dataset-specific evidence. For `lifeexp`, establish
  terms for the historical World Bank Learning Modules selection and Stata-derived
  file. For `starwars`, establish the compiled-data permission/notice chain across
  pinned dplyr 1.1.3, SWAPI and additional research; dplyr's MIT software notice
  alone does not resolve it. Supply evidence or separately authorize clarification
  requests; replacement or relicensing requires another decision.
- **Remote compatibility:** six OS/R jobs and eleven exact dependency-floor cases
  are configured but actual hosted execution remains pending. Run only after
  distribution evidence and separate upload/dispatch authorization, recording
  candidate identity, exact versions, logs, skips and native exits. Local Windows
  R 4.6 checks do not establish R 4.1, dependency floors or other platforms.
- **Interactive viewers:** obtain actual selected/all/grouped observations in
  both RStudio and VS Code using the candidate-bound
  [viewer checklist](inst/examples/VIEWER_CHECKLIST.md). Verify a protected
  interactive launch first; the batch launcher cannot drive an interactive
  terminal. Record editor/extension versions and any watcher failure.
- **Publication:** review release version/metadata and six unpublished URLs.
  Existing incoming-check notes require a recorded publication decision. Local
  verification does not authorize push, deployment, release or submission.
- **Remaining follow-up:** duration display rounding at unit boundaries still
  needs review: compact timer formatting can round a value just below one minute
  to `60.00s`. Preserve the agreed cumulative timing contract while addressing
  display separately. No formatter behavior is changed by repository cleanup.
- **Remaining speed gaps (2026-10-20 audit):** weighted `summ(.detail = TRUE)`
  still computes weighted quantiles per group (about 710 ms for 10,000
  groups); `std()`, `pc()`, `s_lag()` and `s_diff()` inside grouped `mutate()`
  are dominated by dplyr's per-group evaluation (3-12 times slower than
  collapse's vectorized equivalents); `tostring()` cost is base
  `as.character()` formatting. Each needs a separate design that keeps
  outputs identical.
- **Optional work:** consider suite-runtime optimization without removing coverage;
  obtain the original labelled-factor failing call and actual `fre()` dataset for
  exact historical reproduction if desired. Existing representative tests do not
  prove those unavailable originals. Review preview styling only on maintainer
  feedback. New weighted cuts, PCA, regression wrappers, plotting, profiling and
  output presets require separate feature design.
