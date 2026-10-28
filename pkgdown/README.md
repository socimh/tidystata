# Website reference chapters

The English and Chinese Stata-to-R guides are native pkgdown articles. Their
authoritative examples, notes and sources come from the installed package's
catalogue; the two tracked landing articles own the orientation prose.

After installing the current package source, build from the repository root:

```r
source("pkgdown/build-stata-reference.R")
build_stata_reference(".")
pkgdown::build_site(install = FALSE)
finalize_stata_reference(".", "docs")
check_stata_reference(".", "docs")
```

On Windows, invoke R through the protected launcher documented in `AGENTS.md`.
The local `.opencode/workflows/build_site.py --destination <fresh-path>` helper
and the GitHub pkgdown workflow run generation and audit automatically.

Generated chapter sources, contents, lookup maps and audits are ignored by Git.
They are excluded from the R archive together with other website-only articles.
Obsolete generated chapters stop the build without deleting anything; choose a
fresh source/output directory after chapter renames or changes to pagination.
Do not edit them: rerun the generator after catalogue changes. It never executes
the catalogue's analysis snippets or changes the separately hosted book.

The audit checks exact code and IDs in both languages, descriptions, sources,
links, anchors, language targets and search inclusion. Every reference page must
stay below 512 KiB of raw HTML and 10,000 elements, including closed disclosures.
Both editions together, including native Markdown companions, custom CSS/JS,
the old-link map and the entire site search index, must stay below 20 MiB.
Other chapters are never prefetched;
pkgdown's existing search index loads when its search box receives focus.

Tooling regressions run separately from the R package tests:

```r
source("pkgdown/build-stata-reference.R")
testthat::test_file("pkgdown/tests/test-stata-reference.R", stop_on_failure = TRUE)
```
