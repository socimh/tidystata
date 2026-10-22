# Package verification workflows

Run from the repository root. [verify_package.py](verify_package.py) is the
maintained entry point for fresh native installation, tests, package checking,
required-dependency smoke checks and demos. It stages source in a temporary copy,
uses a private installation and returns failure for failed or incomplete checks.
Local tools, results and generated website output are excluded from staging.

```powershell
python .opencode/workflows/verify_package.py --prefix .opencode/results/current
python .opencode/workflows/verify_package.py --filter summ --prefix .opencode/results/current-focused
python .opencode/workflows/verify_package.py --shuffle-seed 20261019 --prefix .opencode/results/current-reordered
python .opencode/workflows/verify_package.py --minimal --prefix .opencode/results/current-minimal
python .opencode/workflows/verify_package.py --demos --prefix .opencode/results/current-demos
python .opencode/workflows/verify_package.py --release --prefix .opencode/results/current-release
```

`--release` includes vignettes, PDF manual and `--as-cran`; `--check` is a faster
development check that skips vignette and PDF-manual work, retaining tests and
examples. Both run the behavioral suite once inside native `R CMD
check`, then run only snapshot-bearing test blocks against a fresh installation
of that archive with `NOT_CRAN=true`. The CRAN check itself never inherits that
flag. Ordinary mode runs the full suite, including snapshots, against its fresh
installation. Snapshot selection preserves original test and fixture identities;
unsupported helper-defined snapshots and incomplete selections fail explicitly.
Check, release, minimal and demos are mutually exclusive.
Filters and shuffle seeds apply only to ordinary tests. The seeded run records
actual test file/block order and maps temporary names to original test identities;
compare outcomes by identity rather than timings.

Windows automation calls the protected launcher through `r_process.py`. Direct
R invocations, including the compatibility wrapper, require it too:

```powershell
python C:/Users/socimh/.codex/scripts/run_r_safe.py -- Rscript .opencode/workflows/run_tests.R summ
```

The default protected launcher is machine-specific; `TIDYSTATA_R_LAUNCHER` may
select another verified protected launcher. An absent launcher is an error.
Inspect native exit status and full logs. The release workflow parses the check
result, fails for errors/warnings/incomplete checks, installs the actual built
archive into an empty private library and records its checksum/install receipt.
Notes remain visible and require a publication decision. `<prefix>-paths.json`
is initialized before staging and finalized on every exit, including exceptions.
Its run ID, status, full staged-source SHA-256, stage timing/status and current
output list identify evidence from this invocation. The same identity is recorded
in suite metadata and the archive installation receipt. Old artifacts remain on
disk but are never evidence for a new invocation; inspect the receipt first.
All R helpers execute from the staged copy. Installed usage examples share one
warning policy and semantic-check implementation. Website checks install
their staged candidate separately; a dependency library never substitutes for
that candidate. Building a site does not authorize deployment.

## Maintained tools and outputs

- `run_suite.R` collects active `tests/testthat` outcomes. Specialized checks and
  benchmarks remain under `.opencode/tests/`; do not source the whole directory.
- `generate_demo_reports.R` executes `.opencode/demos/demo_<family>.R` against the
  explicit fresh library, generating current `report_<family>.md` files and
  `INDEX.md` in `.opencode/reports/`. Use `make demo-reports`. `--index-only`
  rebuilds the index from existing reports through the protected launcher.
  Malformed/missing demo status records fail clearly.
- `check_style.py` performs read-only Air 0.12.0, R parsing and lintr 3.4.0 checks
  for `.opencode/style-scope.json`; use `make style-check`. Local pinned tools
  live in `.opencode/tools/style-tools/`, and the development R library in
  `.opencode/tools/library/`. See CONTRIBUTING.md for environment overrides.
- `generate_migration.py` owns the website migration article;
  run it after editing root `MIGRATION.md`, then use `--check` for freshness.
- Python `test_*.py` files under `.opencode/tests/` exercise failure propagation,
  staging, launcher policy, dependency constraints and receipts. Run them with
  `python -m unittest discover -s .opencode/tests -p "test_*.py"`.

`.opencode/results/` and `.opencode/tools/` are ignored local directories. Reuse
consistent `current` prefixes for normal runs; execution logs may remain in the
protected launcher's temporary directory. Do not accumulate versioned histories.
Current verification and unresolved gates belong in
[DEVELOPMENT.md](../../DEVELOPMENT.md). Original issue notes are retained read-only
under `.opencode/notes/`; removed historical tooling and reports are recoverable
from the maintainer's verified external backup or tracked Git versions.

`make clean` is a non-destructive notice. Deleting artifacts requires explicit
authorization and a reviewed list; it is not an alternative verification mode.
