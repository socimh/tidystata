# Package verification workflows

Run from the repository root. The current supported workflow is
[verify_package.py](verify_package.py). It builds native code in a temporary
source copy, preserves local artifacts, and returns a failure status when
installation, tests, build or package checks fail.

```powershell
# Full retained test suite.
python .opencode/workflows/verify_package.py

# One test family.
python .opencode/workflows/verify_package.py --filter summ

# Fresh native install, suite, source build and R CMD check.
python .opencode/workflows/verify_package.py --check

# Required-dependency smoke check.
python .opencode/workflows/verify_package.py --minimal

# Current versioned demo reports; preserves historical reports.
make demo-reports
```

The Python workflow invokes the protected Windows R launcher for every R
command. Any direct Rscript invocation, including the root run_tests.R wrapper,
must also use that launcher:

```powershell
python C:/Users/socimh/.codex/scripts/run_r_safe.py -- Rscript run_tests.R summ
```

Results are written to .opencode/results. Use --prefix to retain a distinct
run. Only selected reviewed evidence is versioned; other outputs remain local.
See [the evidence policy](../results/README.md). The
[report index](../reports/INDEX.md) distinguishes versioned examples and
historical reports; [.opencode/QUICK_STATUS.md](../QUICK_STATUS.md) is the
current status entry point.

make clean is a non-destructive notice. It does not delete reports, results,
data, compiled files or session state. Review an exact list and obtain
maintainer approval before any artifact deletion.

## Historical tooling

esttab_automation.R, watch_esttab.R and related older tests remain for historical
reference. They target retired functionality and are not the active package
verification workflow. Do not source all scripts in .opencode/tests as a test
runner: that folder also contains historical and specialized scripts.

Old root setup/test/release files and the interactive build scratchpad are
preserved in [development-history](../../extra_functions/development-history/README.md),
excluded from package builds. See [DEVELOPMENT.md](../../DEVELOPMENT.md) for
source locations and the protected execution requirements.
