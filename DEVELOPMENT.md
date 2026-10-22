# Developing tidystata

tidystata **0.3.0** provides Stata-inspired data exploration and preparation
and is stabilizing toward a future 1.0.0 release. This is the single current
package map, verification status and backlog. See [CONTRIBUTING.md](CONTRIBUTING.md)
for the coding standard and [MIGRATION.md](MIGRATION.md) for public contracts.

## Current verification

**Minimums finalized and pushed, 2026-10-22:** `master` and
`refactor/tidyverse-conventions` are on GitHub; before the push, the unpushed
history dropped `.opencode/notes/` (now ignored, local only) and old
`.opencode/results/` output, and commit emails moved to the GitHub noreply
address. The first hosted CI runs found and fixed: `.desc` reaching `if()`
unchecked (R 4.1 aborts), `row_var()` squaring a rounded square root (off by
one ulp without extended long double, as on Apple Silicon), two tests that
assumed an extended long double or R's NA-over-NaN `cumsum()` order, unbraced
`test_that()` helpers (testthat 3.2.1 warns), and CI setup gaps (libcurl,
decor, remotes, the package for the linter). Windows now uses the standard
`check-r-package` action; R crashed at startup (0xC0000005) under the
protected launcher on the hosted runner, so `ci_check.py` is removed and the
launcher stays for local runs. The R 4.1 floor jobs raised two declared
minimums: `readr (>= 1.4.0)` (1.0.0 cannot parse scientific notation and
reports empty problem values) and `testthat (>= 3.2.0)` (the recorded snapshot
display, #1856).

Hosted verification at `563e7c0` (tree identical to the checked `4e9fc27`):
R-CMD-check passes on macOS release, Windows release, Ubuntu devel, release,
oldrel-1 and R 4.1; all eleven exact dependency-floor cases pass on R 4.1
(dplyr 1.1.4, haven 2.5.3, pillar 1.9.0, purrr 1.0.0, readr 1.4.0,
stringr 1.5.0, testthat 3.2.0, tibble 3.2.0, tidyr 1.2.0, units 1.0-0,
vctrs 0.6.4); style, documentation freshness, test coverage and pkgdown pass.
The site is deployed and every URL from the incoming NOTE resolves. Local:
full suite **18,503 passing, 0 failures/warnings**.

**Attribution cleanup, 2026-10-21:** the maintainer-approved history rewrite
removes AI co-author trailers from all local refs and both GitHub code branches.
All 210 mapped commit trees, author/committer identities and dates are unchanged;
104 commits per GitHub code branch are verified, and GitHub lists only `socimh`
as a contributor. Release tags and `gh-pages` are unchanged; a verified rollback
bundle is retained outside the repository. Package checks were not rerun because
package source is unchanged. The release backlog below remains unchanged.

**Dataset distribution resolved, 2026-10-22 (branch
`refactor/tidyverse-conventions`):** `lifeexp` is rebuilt from World Bank WDI
(CC BY 4.0) by `data-raw/lifeexp.R` from the dated snapshot
`data-raw/lifeexp-wdi.csv`, keeping its columns, labels, region coding and
missing values. The bundled `starwars` and `inst/THIRD-PARTY-NOTICES.md` are
removed; examples, tests, vignettes and demos use `dplyr::starwars`, and
Imports require `dplyr (>= 1.1.4)`. NEWS, MIGRATION and
`inst/DATA-PROVENANCE.md` record both changes. The package rename to tidystata
is in Git history; the GitHub repository is renamed and `origin` points to
`socimh/tidystata`. A separate session re-audited the 2024 CRAN review items;
its open items, the unquoted 'tidyverse' in Description and the shipped
`devtools::install()` call in `examples/00_install.R`, are fixed, and
`cran-comments.md` is drafted. Older dated entries are in Git history.

**Package contents trimmed, 2026-10-22:** following R Packages, the plain
scripts move from `inst/examples/` to the repository-only `examples/`
(`.Rbuildignore`), and `inst/MIGRATION.md` is no longer shipped;
`generate_migration.py` writes only the website article. README, the
getting-started vignette, package help and NEWS point to the website or
repository. Because dplyr 1.1.4 itself requires `pillar (>= 1.9.0)`,
`tibble (>= 3.2.0)` and `vctrs (>= 0.6.4)`, DESCRIPTION now declares those
floors, and `.opencode/dependency-minimums.json` pins exact cases with
upstream DESCRIPTION evidence for them. The built tarball's `inst/` holds only
`DATA-PROVENANCE.md` (CC BY attribution), `extdata/` (read by `findit()`) and
the built vignettes.

Verification: pinned style/parse/lint **143 sources, 0 findings**; help and
README regenerated; migration article current; `pkgdown::check_pkgdown()`
clean; 45 workflow Python tests pass. Full suite before the trim
**18,501 passing, 0 failures/warnings**. `--release` after the trim: fresh
build, `R CMD check --as-cran` **0 errors, 0 warnings, 1 NOTE** (new
submission; five pkgdown article URLs and the GitHub `examples/` link return
404 until push and site deployment), tests inside check **18,477 passing,
0 failures/warnings** (21 snapshot blocks skipped there), `snapshots` stage
21 blocks with 0 failures, installed resources and the repository usage
scripts pass. All 24 demos pass.

## Package map

The namespace contains **80 exports**: 79 functions and the re-exported `%>%`.
Twelve are quiet aliases (`xtab`, `na_if_value`, `value_if_na`, `as_numeric`,
`as_character`, `pct`, `s_tag`, `tab_gen`, `cut_quantile`, `s_try`,
`ds_as_column`, `names_as_column`) documented on their primary's help page, and
three are deprecated (`s_match`, `s_type`, `s_unit`). The package has 16
required Imports, one bundled dataset (`lifeexp`; examples also use
`dplyr::starwars`), and cpp11
native row kernels. R >= 4.1 is required; sources, tests and examples use `|>`.

| Area | Public functions |
| --- | --- |
| Stata lookup | findit |
| Tabulation | tab, tab1, tab2, fre, fre1, fre2 |
| Summaries | summ, tabstat, pwcorr, misstable |
| Inspection | codebook, browse, ds, variables, variables_search |
| Keys, duplicates and merging | isid, duplicates_report, duplicates_tag, duplicates_list, duplicates_drop, is_first, assert, s_merge |
| Row calculations | row_mean, row_sum, row_min, row_max, row_median, row_var, row_sd, row_unique, row_nvals, row_miss, row_non_miss |
| Conversion | destring, decode, tostring, mvdecode, mvencode |
| Selection and types | s_select, varlist, var_type, var_unit |
| Binning | xtile, cut_length, cut_breaks |
| Variable transforms | std, pc, as_dummy |
| Panel operators | s_lag, s_lead, s_diff |
| Utilities | timer, set_seed, capture |
| Aliases | xtab, na_if_value, value_if_na, as_numeric, as_character, pct, s_tag, tab_gen, cut_quantile, s_try, ds_as_column, names_as_column |
| Deprecated | s_match, s_type, s_unit |
| Table previews | preview_table, unpreview_table, s_print, print_headtail, print_interval, print_all, slice_headtail, slice_interval |

| Location | Maintained content |
| --- | --- |
| `R/`, `src/`, `tests/testthat/` | Package source, native code and active regression coverage |
| `man/`, `NAMESPACE` | Generated help and namespace; edit roxygen sources |
| `data/`, `data-raw/`, `inst/DATA-PROVENANCE.md` | Preserved datasets, exact reconstruction and provenance |
| `vignettes/` | Tutorials shipped with the package |
| `examples/` | Plain manual scripts (repository only, not shipped) |
| `.opencode/viewer/` | Manual RStudio/VS Code viewer checklist and helper (not shipped) |
| `inst/extdata/stata-to-r.csv` | Hand-curated `findit()` entries (English and Chinese); the source for the "Coming from Stata" articles |
| `.opencode/demos/`, `.opencode/reports/` | Current actual-output demos and generated reports/index |
| `.opencode/workflows/`, `.opencode/tests/` | Current verification tools and specialized checks/benchmarks |
| `.opencode/notes/` | Unchanged original issue notes, screenshots and follow-up handover (local only, ignored by Git) |
| `.opencode/tools/`, `.opencode/results/` | Ignored local tool installations and disposable verification results |

README content lives in `README.Rmd`; website organization lives in
`_pkgdown.yml`. `MIGRATION.md` generates the website migration article (not shipped).
Website output is derived and is built independently from deployment. Retired
wrappers and historical development archives are no longer shipped in the
checkout; consult migration alternatives, Git history for tracked versions or
the maintainer's external backup. `.opencode/workflows/run_tests.R` remains a
compatibility entry point. `make clean` removes nothing.

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
  names magrittr-piped summary vectors `value`, rounds mixed-table numeric text to seven
  significant digits, returns calendar spreads as `difftime` columns in list
  mode and numeric unit-labelled spreads in table mode, and handles `hms` clocks.
  It also adds actionable `.by` errors, grouping-column row inputs and supported
  sf previews/slices. Their regressions, formerly `test-problems2-low.R`, now
  live in `test-summ.R`, `test-tab.R`, `test-cut.R`, `test-row-stats.R` and
  `test-preview.R`;
  older readiness triage dispositions deferring them are superseded.

Mixed calendar/numeric location columns in table mode remain character; choose
list mode to retain separate numeric tables. Existing container,
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
describes the maintained tools. [Plain examples](examples/README.md) cover
installation and direct calls; [current reports](.opencode/reports/INDEX.md)
show generated console output.

## Open backlog and release gates

- **Snapshot step harness:** the earlier `could not find function` failure of
  the `--release` `snapshots` stage did not recur on 2026-10-22, in the
  workflow or in direct runs against a separate bundle library. No harness
  change was made; if it returns, record the failing log before changing
  `run_suite.R`.
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
- **Dataset distribution (decided 2026-10-22):** the maintainer chose to
  rebuild `lifeexp` from World Bank WDI (CC BY 4.0; `data-raw/lifeexp.R` and
  its dated snapshot) and to drop the bundled `starwars` for `dplyr::starwars`
  with `dplyr (>= 1.1.4)`, whose `starwars.rda` is byte-identical from 1.1.4
  to the current main branch. `inst/DATA-PROVENANCE.md` records the source,
  indicators and changes; the distribution gate is closed.
- **Remote compatibility:** done 2026-10-22 (see Current verification). The
  floor matrix runs on pull requests and manual dispatch; rerun it after any
  change to DESCRIPTION bounds.
- **Interactive viewers:** obtain actual selected/all/grouped observations in
  both RStudio and VS Code using the candidate-bound
  [viewer checklist](.opencode/viewer/VIEWER_CHECKLIST.md). Verify a protected
  interactive launch first; the batch launcher cannot drive an interactive
  terminal. Record editor/extension versions and any watcher failure.
- **Toward 1.0.0:** the version is named 0.3.0 (2026-10-21) and every lifecycle
  deprecation says `"0.3.0"`. Before 1.0.0: no public renames for a release
  cycle, the 0.3.0 deprecations removed or moved to `deprecate_stop()`, and
  README no longer calls
  the package experimental.
- **Publication:** pushed and the site deployed 2026-10-22; review release
  version/metadata and `cran-comments.md` before submitting.
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
- **Optional work:** obtain the original labelled-factor failing call and actual
  `fre()` dataset for exact historical reproduction if desired. Existing representative tests do not
  prove those unavailable originals. Review preview styling only on maintainer
  feedback. New weighted cuts, PCA, regression wrappers, plotting, profiling and
  output presets require separate feature design.
