# Agent guidelines

tidystata is an R package providing Stata-inspired exploration and preparation
functions. Read [DEVELOPMENT.md](DEVELOPMENT.md) for the package map, latest
verification and open backlog, and [CONTRIBUTING.md](CONTRIBUTING.md) for the
authoritative R coding standard and contributor workflow.

## Changes and compatibility

- Inspect relevant source, tests and help before editing. Confirm the authoritative
  input and preserve unrelated work in a dirty worktree.
- Preserve public names, arguments, defaults, return types, dependencies and
  datasets unless the user authorizes the change. Prefer simple, surgical edits
  and existing package patterns. New functions should serve a concrete Stata-style
  workflow.
- Keep logic in `R/`, native sources in `src/`, and regression tests in
  `tests/testthat/`. Retain existing behavioral and numbered acceptance coverage;
  remove obsolete duplicates only after confirming unique coverage is retained.
- Follow the pinned, read-only `make style-check` workflow for adopted sources.
  Do not format unrelated files or edit third-party code unnecessarily.
- Update behavior, tests, roxygen and user-facing documentation together. Consider
  README, migration guidance, NEWS and vignettes when a public contract changes.

## Generated files and artifacts

- Edit sources, then regenerate help, registration, README, migration copies and
  demo reports. Do not hand-edit `man/*.Rd`, `NAMESPACE`, derived data or results.
- Keep current demo output in `.opencode/reports/report_<family>.md`; its index is
  generated. Update a relevant demo for observable output changes. Tests establish
  correctness; do not create duplicate per-function verification reports.
- Store disposable verification output under ignored `.opencode/results/` and
  local pinned tools under ignored `.opencode/tools/`. Do not create permanent
  histories of logs, reports, plans or status files.
- Do not delete datasets, generated results, session state or other artifacts
  without explicit authorization. `make clean` is a non-destructive notice.
  The approved repository cleanup is a specific exception, backed up externally.
- Retired implementations removed by that cleanup are available in the
  maintainer's verified external backup and, for tracked versions, Git history.
  New API retirement requires a separate explicit decision.

## Windows R execution

Every R/Rscript invocation on this machine, including parsing, tests, help and
rendering, must use the protected launcher:

```powershell
python C:/Users/socimh/.codex/scripts/run_r_safe.py -- Rscript path/to/script.R
```

Repository Python workflows use `.opencode/workflows/r_process.py` to enforce
this protection. Inspect exit status and stderr; output files alone do not prove
successful shutdown. Do not run unprotected crash probes or change global R
installations to hide failures. Read and write text explicitly as UTF-8 and use
`python`, not `python3`, on Windows.

## Verification and status

- Define observable success criteria. Reproduce defects and add focused,
  risk-based regressions for changed behavior; avoid arbitrary scenario quotas.
- Check empty/missing/labelled/grouped inputs, types, attributes, warnings, errors
  and invisible returns where relevant. Compare actual printed output for
  presentation changes. Keep machine-speed thresholds out of ordinary tests.
- Parse non-trivial R edits through the protected launcher. Source function-only
  files only when side-effect free; inspect pipelines before executing them.
- Run relevant checks, inspect their full results and review the diff for
  accidental changes. Report failures and unavailable checks without implying
  success. Final package validation includes a fresh build and installation,
  full tests, documentation/resources and the complete release check.
- Update the current dated verification and open backlog in `DEVELOPMENT.md` at
  task completion. Keep it concise and distinguish historical evidence, current
  observations and unexecuted release gates. Original issue notes in
  `.opencode/notes/` are read-only source material.

## Autonomy and Git

Do not credit AI tools as authors, contributors or co-authors in package metadata,
documentation or Git commit trailers.

Continue safe in-scope work without repeated confirmation. Ask only for material
ambiguity, required credentials, unusually destructive operations or unapproved
API/project-direction changes. Give a brief factual notice before deletion,
move/rename, overwriting generated output, major refactors or Git integration.

Inspect status before Git operations and preserve unrelated changes. Use
conventional commit prefixes (`feat:`, `fix:`, `docs:`, `refactor:`, `test:`,
`chore:`, `analysis:`, `data:`). Before a requested commit, review staged paths for
secrets, debug artifacts and unintended large files and confirm required checks.
Commit only when requested; do not push, merge, publish, release or rewrite
history without explicit authorization. Local passing checks do not authorize
remote distribution or publication.
