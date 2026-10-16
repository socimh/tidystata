# Repository Cleanup Implementation Plan

> **For agentic workers:** Execute the approved archival proposal inline, verifying each step before completion.

**Goal:** Reduce misleading maintenance files while preserving all local development work and evidence.
**Architecture:** Reuse extra_functions/development-history, already excluded from builds. Keep package logic and validation entry points unchanged.
**Tech Stack:** Python file operations, Make, protected Windows R package workflow.
**Spec:** ../reports/project_status_cleanup_review_2026-10-16.md, approved by the maintainer's proceed instruction.

## Constraints and decisions

- No artifact deletion, API changes, dependency changes, push, merge, or release.
- R commands use the protected launcher; UTF-8 text operations are explicit.
- Preserve the existing uncommitted cleanup-review notes.
- Ruling: Work in the requested D:/R/statart on the existing development branch, because this task reorganizes that folder and preserves its ignored local artifacts.
- Ruling: Reuse extra_functions/development-history rather than introduce another top-level archive; the existing build exclusion covers it.
- Ruling: Make clean will be a non-destructive notice. Deletion requires an exact separately approved list.
- Pre-flight: Archival paths determine README links and build-content checks; verify the move table before execution.

## Task 1: Archive obsolete maintenance files

- [x] Snapshot hashes of existing files; check six sources and nonexisting destinations.
- [x] Move inst/Build_Package.R and five root files into the excluded archive, unchanged.
- [x] Document the move table and historical-only status; remove obsolete root build-ignore patterns.
- [x] Replace stale workflow instructions and add a short archive/current-entry explanation in DEVELOPMENT.
- [x] Verify destination hashes and unchanged active source, tests, datasets, native binaries, reports and ignored artifacts.

## Task 2: Preserve evidence during maintenance

- [x] Replace destructive make clean recipe with a notice and update its descriptions.
- [x] Run clean with available Make and verify all evidence hashes remain unchanged.

## Task 3: Validate and record

- [x] Run a protected fresh full suite/build/check; tarball matches prior contents except removed scratchpad and packaging timestamp.
- [x] Obtain read-only package validation review; no material findings.
- [x] Update required tracking/report index and verify links/diffs; include the result in the local cleanup checkpoint.
- [x] Record verification and remaining optional artifact-cleanup scope in the completion report.
