# Contributing to statart

Start with [DEVELOPMENT.md](DEVELOPMENT.md) for the current package map, known
limitations and open backlog. Read [AGENTS.md](AGENTS.md) before changing files.

## Scope and compatibility

statart provides Stata-inspired R functions with tidyverse-compatible inputs and
outputs. Preserve exported names and established behavior unless an API change
has been agreed. New commands should serve a concrete Stata-style workflow.
Prefer small direct changes and reuse the existing dependencies.

## R coding standard

This section is the authoritative coding standard for active handwritten R
sources, tests and maintained examples. The reviewed file list is
`.opencode/style-scope.json`.

- Use two-space indentation, an 80-character target and descriptive snake_case
  internal names. Preserve exported names and argument names for compatibility.
- Keep functions focused. Extract helpers for meaningful shared operations,
  rather than creating a framework around small wrappers. Base R calls and
  loops are appropriate when they make the operation clear.
- Prefer direct calls for single operations and `|>` for readable sequences in
  new or deliberately revised code. Preserve `%>%` support. Do not mechanically
  replace pipes: review promise forcing, warnings, side effects and visibility.
  Use only native-pipe syntax supported by R 4.1 (no newer placeholders or
  extraction syntax). Use `function()` for named and multiline functions.
- Prefer an implicit final return and explicit early returns. Keep intentional
  invisible returns for side-effect functions. Comments explain reasons and
  non-obvious contracts, rather than narrating each line.
- Validate public inputs before computation; avoid repeating validation after
  normalization. State output type/shape, missingness, grouping and warning
  contracts explicitly. Preserve input data and relevant attributes.
- Distinguish tidy selection, data masking and ordinary arguments. Forward
  expressions through established tidy-evaluation tools; do not hide failed
  computations behind general suppression or undocumented fallback behavior.
- Qualify dependency calls in package code. Do not attach packages/data, change
  the working directory or install dependencies from package functions. Existing
  imports and documented stateful utilities are retained.
- Test observable behavior using small fixtures and independently stated values.
  Check types/classes/attributes when they are part of the contract. Retain
  numbered acceptance catalogues; new coverage is risk-based, without a numeric
  quota. Assert intentional warnings explicitly. Snapshots are selective tools
  for diagnostics/presentation, not substitutes for numerical assertions.

Air **0.12.0** is the sole formatter; lintr **3.4.0** checks namespace use and
prohibited package-code calls. These are development tools, not runtime Imports.
Install Air from its official release or `air-formatter==0.12.0`, and install
lintr 3.4.0 in a development library. The local Air fallback lives in ignored
`.opencode/tools/style-tools/`; the pinned lintr library defaults to
`.opencode/tools/style-tools/library/`. Other verification dependencies may use
`.opencode/tools/library/`.
`STATART_AIR` may name the Air executable;
`STATART_STYLE_LIBRARY` may name the R library containing the pinned lintr.
The checker permits explicit `stats::`/`utils::` qualification of already
imported functions; it still rejects missing namespaces and exports.

Run `make style-check` (or `python .opencode/workflows/check_style.py`) for a
read-only formatting, parsing and lint check. To format, explicitly pass only
the family being adopted to `air format`; inspect the diff afterward. Add new
handwritten package/test files to the reviewed scope immediately. CI checks new
PR sources against this list. Do not run whole-repository automatic formatting.
Generated registration/help, local tools and results are excluded.

Keep formatting, refactoring and behavioral fixes distinguishable in commits.
Each completed family requires focused tests, fresh native installation, the
full suite and package check. Regenerate docs from source and record exact
results and limitations. Any departure from an accepted public contract is a
separate decision, not incidental style cleanup.

Inspect Git status and preserve uncommitted changes before switching branches
or integrating updates. Current verification belongs in DEVELOPMENT.md; Git
history and the maintainer's external backup retain historical material.

## Aggregation boundary

Tabulation and summary computation uses prepared vectors, native vctrs category
identities, and per-call group locations in `R/aggregation-core.R`. Keep class
conversion, selection, diagnostics, calendar formatting and table restoration at
the boundaries. Numerical helpers return vectors or lists of columns and use
base R, stats and vctrs; do not add grouped data-masking operations inside them.
Reuse metadata and group locations across variables. Calculate only requested
statistics and their prerequisites, including for weighted summaries. Keep
cumulative sums local to each group, and distinguish raw category identity from
cross-table display names. Ambiguous headers retain the existing pivot behavior.

Measure complete public calls, including preparation and output construction,
with warm-up, adaptive batches, at least seven repetitions and allocations. Run
repeated before/after measurements without concurrent validation jobs. Retain an
algorithmic optimization only with a targeted improvement of at least 20% and no
repeatable regression exceeding both 10% and 5 ms; architectural extraction must
stay performance-neutral. Timing assertions do not belong in unit tests.

## Source files

| Change | Edit |
| --- | --- |
| Function behavior and help | `R/*.R`, including roxygen comments |
| Native row operations | `src/row_stat.cpp` |
| Regression tests | `tests/testthat/test-<family>.R` |
| README content | `README.Rmd` |
| Package metadata and release notes | `DESCRIPTION`, `NEWS.md` |
| Website organization | `_pkgdown.yml` |
| Demo examples | `.opencode/demos/demo_<family>.R` |

Regenerate derived files through their tools: roxygen for `man/` and `NAMESPACE`,
cpp11 for registration wrappers, R Markdown for `README.md`, and pkgdown for
`docs/`. Preserve data and unrelated changes. Do not delete artifacts without
explicit authorization. Retired source removed by the approved cleanup remains
in the maintainer's verified external backup and, for tracked versions, Git
history; see MIGRATION.md for supported alternatives.

## Local workflow

1. Reproduce the issue and define the expected behavior. Distinguish a package
   defect from an invalid fixture or an intentional difference in the API.
2. Add a focused regression test when behavior changes. Include relevant empty,
   missing, labelled, grouped, and class-sensitive inputs.
3. Make the smallest coherent source change and update its roxygen comments.
4. Run focused tests, then the broader suite as justified by the change. Check
   return values and actual printed output when formatting is involved.
5. Regenerate relevant documentation and inspect the resulting changes. Record
   user-visible behavior changes in `NEWS.md`.
6. Update the dated current verification and open backlog in DEVELOPMENT.md.
   For observable output changes, update the relevant maintained demo and
   regenerate current reports/index. Do not create duplicate historical reports.

On this Windows machine, launch every R/Rscript command through:

```powershell
python C:/Users/socimh/.codex/scripts/run_r_safe.py -- Rscript path/to/script.R
```

See [DEVELOPMENT.md](DEVELOPMENT.md#working-commands) for testing,
documentation, and checking commands. Use UTF-8 text files; older Windows
PowerShell can introduce quoting problems or a BOM when writing scripts.
Inspect the launcher exit status and stderr before reporting success.

Native code needs a matching R toolchain. Avoid interpreting failures from an
old DLL as source-code regressions. Repository automation uses a temporary source
copy with freshly built native code.

## Before integration or release

- Inspect the diff and staged paths for unrelated work, secrets, debug files,
  and unintended large artifacts.
- State which checks ran, their results, and anything still unverified. A test
  suite with known failures is not a passing release check.
- Use conventional commit prefixes such as `fix:`, `feat:`, `docs:`, or `test:`.
- Push, merge, publish, and release only when the maintainer requests the action.
- Before release, verify a clean source build, package contents, full tests,
  documentation consistency, and `R CMD check`.

## Portable contributor workflow

From the package project in a fresh R session, use `devtools::load_all()` for
interactive development, `devtools::test()` for focused feedback, and
`devtools::check()` for a complete package check. These commands do not require
the maintainer's Python tooling. Install the current folder with
`devtools::install(".", upgrade = "never")`, restart R, then inspect
`packageVersion("statart")` and `find.package("statart")` before manual examples.
Opening the repository does not change which installation `library()` loads.

Repository automation uses `.opencode/workflows/r_process.py`. On Windows,
`STATART_R_LAUNCHER` can name a verified protected `run_r_safe.py`; this machine's
existing launcher is the default. An unavailable protected launcher is an error,
not a reason to run an unprotected probe. On other platforms R is invoked directly.

For the final local candidate, run:

```powershell
python .opencode/workflows/verify_package.py --release --prefix .opencode/results/current-release
```

It builds vignettes and checks with `--as-cran`, including the PDF manual.
Ordinary `--check` remains a faster development check. Both use a fresh source
copy and installation and retain command options and logs.

After editing MIGRATION.md, run
`python .opencode/workflows/generate_migration.py`. The installed Markdown and
website-only article are generated copies. Run its `--check` mode in CI.
Render roxygen and README against current source in an isolated build; review
README output differences when R or formatting dependencies change. Website
building and deployment are distinct actions.

## Verification safeguards

Repository automation needs pkgload, rcmdcheck and jsonlite in a development
library, conventionally ignored `.opencode/tools/library/`. On Windows every R
subprocess uses the protected launcher described above. These tooling dependencies are not runtime Imports of statart.

The check, release, minimal and demos modes are mutually exclusive. Filters and
`--shuffle-seed` apply only to ordinary test runs. For reproducible order checks:

```powershell
python .opencode/workflows/verify_package.py --prefix .opencode/results/current
python .opencode/workflows/verify_package.py --shuffle-seed 20261019 --prefix .opencode/results/current-reordered
```

The seeded run records its actual file/block ordering and maps temporary names
back to original test identities. Compare results by file/test identity; do not
compare timing or printed elapsed-time values.

Ordinary tests assert results, types and conditions rather than elapsed-time
thresholds, which vary with machine load. Keep performance measurements in
separate reproducible benchmarks and record timing variability. Do not skip
accepted behavioral coverage solely to reach a suite-runtime target.

`--release` parses the complete check log and fails for errors, warnings, failed
processes, or incomplete output. Notes remain visible and need a recorded
publication decision. It installs the actual built archive into an empty private
library, writes its checksum/install receipt, and validates installed resources.
A successful local command does not itself authorize publication.

Website builds always install their staged source into a fresh private library.
The website helper's optional `--library` supplies dependencies only. Missing or
wrong candidate installations are rejected by resource checks rather than falling
back to another installed statart version.
