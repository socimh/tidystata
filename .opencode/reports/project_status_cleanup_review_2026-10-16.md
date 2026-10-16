# Repository cleanup review

Reviewed 2026-10-16 on test/stabilize-fixtures at 3f1d4b2. The worktree was clean before this review. This is an inventory and recommendation, not an executed cleanup. No source, data, generated evidence or artifacts were moved or deleted; no Git integration or publication occurred.

## Verified inventory

Excluding .git, the folder contains 670 files: 250 tracked and 420 ignored, with no untracked files at review start. Counts describe the pre-review folder, not the Git repository size. The largest directory groups are .opencode (352 files, 23.03 MiB), docs (132 files, 5.42 MiB), and src (9 files, 5.16 MiB).

| Group | Recommendation | Reason |
| --- | --- | --- |
| R/, tests/, DESCRIPTION, NAMESPACE, man/, data/, native C++ sources | Keep | Active package implementation, checks, help, datasets and native build inputs. Generated help and registration are still required distribution files. |
| README.Rmd and README.md, LICENSE files, NEWS, MIGRATION, DEVELOPMENT, CONTRIBUTING, .github, Makefile, build/ignore rules | Keep | Sources plus required generated documentation, maintenance and automation. README source and output serve different purposes. |
| extra_functions/ | Keep as an archive | 20 preserved files of retired or exploratory functionality; already excluded by .Rbuildignore. No dependency cost to the active package merely from storing them. |
| inst/Build_Package.R | Archive outside inst/ and exclude archive from builds | Historical scratchpad with package installation, submit_cran, interactive help, hardcoded paths and obsolete API examples. Confirmed present in the previous clean-check source tarball. It is not executed by this review. |
| test.R | Archive | Exploratory script loads tidyverse/devtools and uses summ as though it were an atomic-vector summary. Current supported verification lives elsewhere. |
| install_statart_deps.R | Archive or replace later with DESCRIPTION-driven setup | Still installs the former broad dependency collection, including retired import/export and modeling dependencies. Already excluded from package builds. |
| TEST_SUMMARY.md | Archive | Old 357-test inventory and obsolete rlang installation blockage conflict with current verified status. Already excluded from builds. |
| CRAN-SUBMISSION and cran-comments.md | Archive as historical release metadata | Describe 0.2.0 in 2024 and 33 Imports, not current 0.2.0.9000 with 13 Imports. Excluded from builds. |
| run_tests.R | Keep or relocate with references updated | Current protected-workflow wrapper, not obsolete just because it is at the root. |
| .opencode/ workflows, demos, current tests/status, selected evidence | Keep | Active validation and provenance; the directory is excluded from package builds. Review historical esttab automation, duplicate issue notes and superseded scripts separately before archiving. |
| docs/, .Rproj.user/, .Rhistory, ignored .opencode/results outputs, src/*.o and src/*.dll | Candidates for an explicitly approved local artifact cleanup | Already ignored by Git. Preserve current evidence and any wanted local session state. Keep C++ sources and registration wrappers. Rebuilding is required after removing native binaries. |
| data-raw/complex_tb.R | Keep pending a separate provenance review | Development fixture source is excluded from builds; being outside active R/ does not alone establish that it is disposable. |

## Proposed order

1. Preserve and relocate misleading historical root files and the inst scratchpad into a clearly labeled archive excluded from builds. Update any actual references and show a move manifest.
2. Keep one current status entry point; distinguish historical reports from current findings. Review duplicate historical notes and esttab-only tooling before moving them.
3. Retain the existing selected-evidence allowlist. Consider local generated-artifact removal separately, with an exact list and explicit maintainer approval.
4. Verify links and exclusions, inspect a fresh source tarball to ensure the scratchpad is absent, then run the protected fresh-build/check workflow after actual layout changes.

Do not run the existing make clean target for this cleanup: it removes .opencode/reports/report_*.md, including preserved historical/versioned reports. Review that target before relying on it.

## Verification and limits

Read-only Git status/log/list-files, a filesystem count/size inventory, ignore rules, candidate script contents, repository references and the previous checked tarball were inspected. No references to the named root cleanup candidates or Build_Package were found by the targeted content search. This does not prove an external user has no dependency on their locations. No package logic changed, and package tests were not rerun. The preceding passing package checks remain historical evidence, not a new check from this review.
