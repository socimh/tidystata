# Stata to R Reference

This directory owns the bilingual Quarto reference book hosted at
<https://www.socimh.com/stata-to-r/> (English) and
<https://www.socimh.com/stata-to-r/zh/> (Chinese). The pkgdown navbar links to it.
It is a reference companion, separate from the introductory textbook.

## Authoritative inputs

- `data-raw/findit/` owns the catalogue, descriptions and provenance; regenerate
  those resources through its documented workflow before rebuilding the book.
- `content/en/` and `content/zh/` own short orientation and qualification prose.
- `assets/` owns the responsive layout and language/deep-link behavior.
- `export-metadata.R` reads selection annotations from the current package source,
  using `pkgload`, rather than the user's installed package.

Subject chapters, indexes and both Quarto configurations are generated into a
fresh build directory. They are not manually maintained or shipped in the R
package. Every example keeps its catalogue ID and code. Book builds display
snippets without executing them; use the independent execution corpus described
in `data-raw/findit/README.md` to verify analyses.

## Build and inspect

Requires Python 3.10+, Quarto, and the package's existing R development tools
(including `pkgload`). The generator and audits use the Python standard library.
On Windows every R/Quarto child process uses the protected R launcher; no global
R installation or cache setting is changed.

From the package repository, choose a new output directory for each run:

```powershell
python -m unittest discover -s book/tests -v
python book/build.py --output .opencode/results/reference-book/local-build
```

The resulting `site/index.html` and `site/zh/index.html` are the two editions.
For browser previews, serve the `site` directory over localhost; search requires
HTTP rather than opening HTML with a `file:` URL. The generated manifest and
`audit.json` record content and local-link checks. Build logs remain alongside
the output. A failure stops before website integration.

## Update the personal website locally

With writable access to the personal-site checkout, one command builds, audits,
stages and renders that site twice before applying the verified local updates:

```powershell
python book/build.py --output .opencode/results/reference-book/site-update --personal-site D:/Agent/Personal-Website
```

For separate review or filesystem approval, prepare without writing to that
checkout, then apply the checked receipt:

```powershell
python book/integrate.py --personal-site D:/Agent/Personal-Website --book .opencode/results/reference-book/local-build/site --staging .opencode/results/reference-book/site-preview
python book/integrate.py --apply-prepared .opencode/results/reference-book/site-preview/integration.json
```

Integration adds the Books/Software links and a portable Python preservation hook.
The hook preserves `docs/CNAME`, `docs/cc-guide`, `docs/slides`, `docs/zh` and
`docs/stata-to-r`. Its local
`.embedded-cache/` is ignored and must remain outside the output directory.
The older shell hook remains on disk but is replaced in Quarto's hook configuration.
Quarto cleans output **before** pre-render hooks, so the existing `render-site.sh`
wrapper is updated to save embedded output before invoking Quarto and use
`--no-clean` for both personal-site editions. Use that wrapper for routine site
renders. On a fresh checkout without a cache, the post-render hook recovers missing
tracked embedded files by reading Git's index, without checking out or overwriting
existing files. Independently revised embedded output should always be saved through
the wrapper before rendering. The integration command also seeds the local cache.

Preparation snapshots source/output fingerprints before rendering and rejects any
edits made while rendering. Application verifies those fingerprints again before writing.
Copies are additive: it never deletes old files or artifacts. A failed render
leaves the real checkout untouched, and unrelated working-tree changes are
preserved. No command commits, pushes or publishes either site. Inspect the local
diff and request publication separately when ready.
