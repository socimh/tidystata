# Developing statart

statart **0.2.0.9000** provides Stata-inspired data exploration and preparation
and is stabilizing toward a future 0.3.0 release. This is the single current
package map, verification status and backlog. See [CONTRIBUTING.md](CONTRIBUTING.md)
for the coding standard and [MIGRATION.md](MIGRATION.md) for public contracts.

## Current verification

Verified **2026-10-19** on Windows / R 4.6.0 after repository cleanup:

- Fresh baseline, post-cleanup and reordered suites each pass **18,382
  expectations across 3,184 blocks**, with identical source fingerprints and
  outcomes, different reordered execution, and no failures, errors, unexpected
  warnings or skips.
- All **39 Python workflow tests**, **121-source** pinned style/parsing/lint,
  **16 demos**, six plain manual scripts, required-only smoke and generated
  migration freshness pass. Fresh installations preserve all **46 public
  interfaces** and **24** captured value/visibility/diagnostic records.
- Fresh source build and complete `--as-cran` archive checking finish, including
  tests, examples, vignettes and PDF/HTML manuals. The strict verification gate
  remains **not passing**: **0 errors, 1 WARNING, 1 NOTE**. The warning is an
  existing Unicode information symbol in `R/summ-helpers.R:31`, unchanged from
  the pre-cleanup source; use an equivalent Unicode escape in a separate
  portability fix. The incoming NOTE covers development/new-submission metadata
  and four unpublished URLs. Separate archive installation and installed-resource
  checks pass. No condition was suppressed.
- Fresh website build passes: **72 pages, 1,143 local references, zero broken
  targets**. Maintained Markdown links also resolve. Network-dependent checks
  were rerun with network access after sandboxed attempts were blocked.

The complete pre-cleanup checkout, including ignored/untracked files and Git
metadata, is preserved in a hash-verified external backup. The cleanup removes
superseded artifacts, scripts and documentation while preserving package sources,
active tests, datasets and generated help byte-for-byte. Current demo reports
are regenerated from maintained sources. Disposable logs/receipts are retained
outside the checkout; normal future runs use ignored `.opencode/results/`.
Local Git checkpoint requested 2026-10-19. No push, publication or remote
compatibility run was performed.

## Package map

The namespace contains **46 exports**: 45 functions and `%>%`. The package has
12 required Imports, two bundled datasets (`lifeexp`, `starwars`), and cpp11
native row kernels. R >= 4.1 is required.

| Area | Public functions |
| --- | --- |
| Tabulation | tab, tab1, tab2, fre, fre1, fre2 |
| Summaries | summ, tabstat |
| Inspection | codebook, browse, ds, ds_as_column, names_as_column, variables, variables_search |
| Row calculations | row_mean, row_sum, row_min, row_max, row_median, row_var, row_sd, row_unique, row_miss, row_non_miss |
| Conversion | as_character, as_numeric, na_if_value, value_if_na |
| Selection and types | s_select, s_match, s_type, s_unit |
| Binning | cut_quantile, cut_length, cut_breaks |
| Utilities | timer, set_seed, s_try |
| Table previews | preview_table, unpreview_table, print_headtail, print_interval, slice_headtail, slice_interval |

| Location | Maintained content |
| --- | --- |
| `R/`, `src/`, `tests/testthat/` | Package source, native code and active regression coverage |
| `man/`, `NAMESPACE` | Generated help and namespace; edit roxygen sources |
| `data/`, `data-raw/`, `inst/DATA-PROVENANCE.md` | Preserved datasets, exact reconstruction and provenance |
| `inst/examples/`, `vignettes/` | Plain manual examples, viewer checklist and tutorials |
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
- `timer()` reports on failure (`.on_error = TRUE`) and rethrows the untouched
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
  sf previews/slices. These have active regressions in `test-problems2-low.R`;
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
- **Publication:** review release version/metadata and four unpublished URLs.
  Existing incoming-check notes require a recorded publication decision. Local
  verification does not authorize push, deployment, release or submission.
- **Remaining follow-up:** duration display rounding at unit boundaries still
  needs review: compact timer formatting can round a value just below one minute
  to `60.00s`. Preserve the agreed cumulative timing contract while addressing
  display separately. No formatter behavior is changed by repository cleanup.
- **Optional work:** consider suite-runtime optimization without removing coverage;
  obtain the original labelled-factor failing call and actual `fre()` dataset for
  exact historical reproduction if desired. Existing representative tests do not
  prove those unavailable originals. Review preview styling only on maintainer
  feedback. New weighted cuts, PCA, regression wrappers, plotting, profiling and
  output presets require separate feature design.
