# Contributing to statart

Start with [DEVELOPMENT.md](DEVELOPMENT.md) for the current package map, known
limitations, and restart priorities. Read [AGENTS.md](AGENTS.md) and
[.opencode/rules/](.opencode/rules/) before changing files.

## Scope and compatibility

statart provides Stata-inspired R functions with tidyverse-compatible inputs and
outputs. Preserve exported names and established behavior unless an API change
has been agreed. New commands should serve a concrete Stata-style workflow.
Prefer small direct changes and reuse the existing dependencies.

## R coding standard

This section is the authoritative coding standard for active handwritten R
sources, tests and maintained examples. Adopt it one function family at a time;
the reviewed file list is `.opencode/style-scope.json`.

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
lintr 3.4.0 in a development library. `STATART_AIR` may name the Air executable;
`STATART_STYLE_LIBRARY` may name the R library containing the pinned lintr.
The checker permits explicit `stats::`/`utils::` qualification of already
imported functions; it still rejects missing namespaces and exports.

Run `make style-check` (or `python .opencode/workflows/check_style.py`) for a
read-only formatting, parsing and lint check. To format, explicitly pass only
the family being adopted to `air format`; inspect the diff afterward. Add new
handwritten package/test files to the reviewed scope immediately. CI checks new
PR sources against this list. Do not run whole-repository automatic formatting.
Generated registration/help, archives and preserved results are excluded.

Keep formatting, refactoring and behavioral fixes distinguishable in commits.
Each completed family requires focused tests, fresh native installation, the
full suite and package check. Regenerate docs from source and record exact
results and limitations. Any departure from an accepted public contract is a
separate decision, not incidental style cleanup.

Git history is restored from https://github.com/socimh/statart.git; local master
tracks origin/master. Local development checkpoints preserve the
newer work; consult DEVELOPMENT.md for the latest verified results. Inspect status and preserve any
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
