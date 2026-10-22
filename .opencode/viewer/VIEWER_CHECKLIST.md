# Manual viewer check: RStudio and VS Code

Status: GUI observation is pending. Native editor automation was unavailable
during preparation. Run the following checklist independently in each editor;
passing return-value assertions alone does not verify rendering.

## Select the candidate

Use the candidate archive's installation receipt from the final verification,
not whichever statart happens to be in the default library. The receipt records
the archive SHA256 and the private `bundle_library` containing that archive's
fresh installation. Opening this repository does not select that installation.

The normal Windows preparation command, run from the repository root, is:

```powershell
python .opencode/workflows/verify_package.py --release --prefix .opencode/results/current-release
```

This workflow uses the protected R launcher. Inspect its exit status and full
check log before using the receipt. It leaves the default library unchanged.
If that candidate has already been verified, reuse its receipt instead of
rebuilding solely for this manual check. Do not substitute an earlier candidate.

If the receipt's temporary library has disappeared, reinstall the exact archive
recorded in the receipt into a new empty private library. On this Windows machine:

```powershell
$receipt = Get-Content -Raw -Encoding UTF8 .opencode/results/current-release-installation.json | ConvertFrom-Json
$candidateHash = (Get-FileHash -Algorithm SHA256 -LiteralPath $receipt.tarball).Hash.ToLowerInvariant()
if ($candidateHash -ne $receipt.tarball_sha256) { throw 'Candidate archive checksum mismatch' }
$viewerLibrary = Join-Path $env:TEMP ('statart-viewer-' + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $viewerLibrary | Out-Null
python C:/Users/socimh/.codex/scripts/run_r_safe.py -- R CMD INSTALL "--library=$viewerLibrary" $receipt.tarball
if ($LASTEXITCODE -ne 0) { throw 'Candidate installation failed; inspect the protected launcher logs' }
$viewerLibrary
```

Use the printed library path below if reinstalling. Retain the receipt and the
new installation log together. An absent archive requires a new verified
candidate, not an installation from another source.

## Open an interactive session

On this Windows machine, first verify that the editor's interactive R launch
configuration preserves the architecture environment and native crash-dialog
suppression required by the protected-launcher policy. The batch launcher above
closes standard input and cannot itself serve as an interactive R terminal. If
no compatible protected configuration is available, record this prerequisite as
pending; do not substitute an unprotected R shell to complete the checklist.

In **RStudio**, restart R, open this project, and record the full RStudio version
from Help > About RStudio. Use the R console for the calls below. A headless
Rscript process cannot establish that RStudio's data viewer works.

In **VS Code**, record the VS Code version (Help > About), the R extension
version, and relevant viewer settings. Once the protected interactive launch
configuration is verified, start a fresh R terminal through the R extension.
Check that the terminal is interactive and that the extension has attached to
that R session.
Record whether the session watcher is connected and whether the extension's
`View` override is enabled; those can affect how `tibble::view()` is routed.
If the watcher reports a stale lock, record that as an environment failure;
verify the lock owner's exit before any separate lock repair.

In either editor, set the working directory to the repository root and run:

```r
stopifnot(interactive())
receipt <- jsonlite::read_json(
  ".opencode/results/current-release-installation.json",
  simplifyVector = TRUE
)
candidate_library <- receipt$bundle_library
# If reinstalled above, replace candidate_library with that printed path.
candidate_id <- receipt$tarball_sha256
editor_version <- "REPLACE: editor version; VS Code also R extension version"
stopifnot(!grepl("REPLACE", editor_version))
source(".opencode/viewer/viewer_check.R")
```

The helper selects the private library, prints the loaded package path and R
version, and rejects an already-loaded statart from a different library. Restart
R if it reports a mismatch. Sourcing the file only defines the helper; it opens
no viewer and installs no packages.

## Run one case at a time

```r
selected_record <- run_viewer_check(
  candidate_library, candidate_id, editor_version, case = "selected"
)
```

Observe a viewer with three rows, only `id` and `score`, ids 1/2/3, and scores
4/missing/8 in that order. The missing cell must not appear as zero or vanish.
Record the viewer surface or tab that opened and any error or stale display.

```r
all_record <- run_viewer_check(
  candidate_library, candidate_id, editor_version, case = "all"
)
```

Observe three rows with `id`, `score`, and `group`; the group values are A/A/B.
Confirm this is the new result rather than the previous selected-column view.

```r
grouped_record <- run_viewer_check(
  candidate_library, candidate_id, editor_version, case = "grouped"
)
```

Observe three rows with `group` and `score`, A/A/B and 4/missing/8. The console
message about adding the missing grouping variable is expected. The helper
checks that the returned object retains grouping by `group`.

For every case, the helper independently checks exact returned data, invisible
return, the score label `Assessment score`, and unchanged input. Variable labels
need not appear in viewer headers; their preservation is checked on the return
value. A stopped assertion means that case failed even if a window opened.
The helper always leaves `gui_observation` pending: only a person can complete
the visual check. Calling it from Rscript stops clearly before opening a viewer.

## Record actual observations

Copy the printed record and complete one row per editor and case. Retain the
archive SHA256, package path, R/platform version, and full editor/extension
versions with the table. Record screenshots where useful; do not overwrite a
previous observation from another candidate.

| Editor and case | Viewer opened and location | Rows/columns/values correct | Missing cell correct | Return contracts | Result, error, or pending reason |
| --- | --- | --- | --- | --- | --- |
| RStudio: selected | pending | pending | pending | pending | pending |
| RStudio: all | pending | pending | pending | pending | pending |
| RStudio: grouped | pending | pending | pending | pending | pending |
| VS Code: selected | pending | pending | pending | pending | pending |
| VS Code: all | pending | pending | pending | pending | pending |
| VS Code: grouped | pending | pending | pending | pending | pending |

Close the GUI gate only when both editors have actual observations against the
recorded candidate. An unavailable editor or disconnected watcher remains a
specific pending environment check.
