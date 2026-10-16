# Repository cleanup completed

Completed 2026-10-16 on test/stabilize-fixtures. Implements the approved
[cleanup review](project_status_cleanup_review_2026-10-16.md).

## Changes and preservation

Six historical files were relocated into extra_functions/development-history,
which is excluded from package builds by the existing extra_functions rule.
Their contents were preserved byte-for-byte. The archive README maps their old
locations and directs maintainers to supported entry points. run_tests.R stays
at the root. Obsolete root-file exclusions were removed from .Rbuildignore.

| Original path | Preserved path | SHA-256 |
| --- | --- | --- |
| inst/Build_Package.R | extra_functions/development-history/Build_Package.R | `b7d635b3e198375abf9300dc785aee3cb61c87f370a87551bd764a0477c5d4d1` |
| test.R | extra_functions/development-history/test.R | `8287c070ea81bd47ad3699183156c2652134288f89de906ef0d928b1159b0174` |
| install_statart_deps.R | extra_functions/development-history/install_statart_deps.R | `9330d73655a69d9bcee83b923342923ef0d0f9aa89013a48a65bd948692990aa` |
| TEST_SUMMARY.md | extra_functions/development-history/TEST_SUMMARY.md | `0fed20ae78c7f48d039a659e491ae9cbb5369b4302f04edd6334357c4fa494b0` |
| CRAN-SUBMISSION | extra_functions/development-history/CRAN-SUBMISSION | `62035398654972768b04358c8b8997f3c70180dcfbdff3a8c2f459e1765ce8ac` |
| cran-comments.md | extra_functions/development-history/cran-comments.md | `667cbf99b9c4d86e7bc4840c52728861b537bf2695a029941fa70a4e52d350cc` |

The Make clean target now prints preservation guidance and removes no files.
Its help and AGENTS quick command were updated. The workflow README now points
to the protected fresh-build verification workflow and labels esttab tooling
historical. DEVELOPMENT explains current versus archived files.

All 671 pre-task non-Git files remain at their original or mapped archive
locations. Allowed edits are limited to maintenance configuration and notes;
active R/C++ source, tests, help/namespace, datasets, native binaries, README
source/output, existing reports and ignored outputs are unchanged. Original
cleanup-review notes were retained. No artifacts were deleted.

## Verification

- Six destination SHA-256 hashes match the pre-move snapshot.
- make clean exited 0; all baseline artifacts still matched afterward.
- Read-only package validation review found no material issues with the moves,
  build exclusions, preservation, clean target or edited documentation links.
- The protected fresh workflow exited 0 for installation, all tests, source
  build and R CMD check. The suite retained 1,410 blocks and 5,617 passing
  expectations, with zero failures/errors, 33 existing warnings and one empty
  test skipped. R CMD check --no-manual reports Status: OK.
- Fresh tarball inspection confirms no extra_functions archive, .opencode or
  Build_Package.R. Compared with the preceding checked tarball, the only removed
  regular file is statart/inst/Build_Package.R; no regular files were added.
  All 92 retained regular files match, allowing only the DESCRIPTION Packaged
  timestamp to vary.
- Protected R execution used the existing launcher; its exit statuses were
  checked. No historical maintenance scripts were sourced.

Command:

```powershell
python .opencode/workflows/verify_package.py --check --prefix .opencode/results/cleanup-final
```

Selected raw evidence: [suite summary](../results/cleanup-final.csv),
[build log](../results/cleanup-final-build.log), and
[package-check log](../results/cleanup-final-check.log). Other run outputs remain
local and ignored. The previous core report retains detailed behavioral evidence.

## Remaining scope

Generated docs, IDE state, compiled artifacts and duplicate intermediate results
remain preserved. Deletion requires an exact reviewed list and explicit
maintainer approval. Older esttab-specific scripts and duplicate issue notes
remain historical; they were not reorganized in this pass. Empty-test coverage,
intentional-warning assertions and minimum-R/multi-platform validation remain
release follow-ups. No push, merge, publication or release was performed.
