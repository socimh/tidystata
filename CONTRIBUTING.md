# Contributing to statart

Start with [DEVELOPMENT.md](DEVELOPMENT.md) for the current package map, known
limitations, and restart priorities. Read [AGENTS.md](AGENTS.md) and
[.opencode/rules/](.opencode/rules/) before changing files.

## Scope and compatibility

statart provides Stata-inspired R functions with tidyverse-compatible inputs and
outputs. Preserve exported names and established behavior unless an API change
has been agreed. New commands should serve a concrete Stata-style workflow.
Prefer small direct changes and reuse the existing dependencies.

Git history is restored from https://github.com/socimh/statart.git; local master
tracks origin/master. A 2026-10-16 local development checkpoint preserves the
newer work with known failures documented. Inspect status and preserve any
uncommitted changes before switching branches or integrating updates.

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
`docs/`. Keep data, historical reports, compiled files, and unrelated changes
intact. Preserve useful retired functions in `extra_functions/`.

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
6. Update `.opencode/PROBLEMS.md`, `.opencode/TODO.md`, and
   `.opencode/PROGRESS.md`. Follow the local function-report rules for new or
   modified functions, retaining actual output and linking reports in the index.

On this Windows machine, launch every R/Rscript command through:

```powershell
python C:/Users/socimh/.codex/scripts/run_r_safe.py -- Rscript path/to/script.R
```

See [DEVELOPMENT.md](DEVELOPMENT.md#working-commands) for testing,
documentation, and checking commands. Use UTF-8 text files; older Windows
PowerShell can introduce quoting problems or a BOM when writing scripts.
Inspect the launcher exit status and stderr before reporting success.

Native code needs a matching R toolchain. Avoid interpreting failures from an
old DLL as source-code regressions. A temporary source copy with freshly built
native code is useful when the original artifacts need to be preserved.

## Before integration or release

- Inspect the diff and staged paths for unrelated work, secrets, debug files,
  and unintended large artifacts.
- State which checks ran, their results, and anything still unverified. A test
  suite with known failures is not a passing release check.
- Use conventional commit prefixes such as `fix:`, `feat:`, `docs:`, or `test:`.
- Push, merge, publish, and release only when the maintainer requests the action.
- Before release, verify a clean source build, package contents, full tests,
  documentation consistency, and `R CMD check`.
