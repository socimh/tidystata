# 00-core-r-package.md

Always treat this repository as an **R package**.

## Required behavior

* Preserve the current public API unless the user explicitly asks for a breaking change.
* Prefer minimal diffs over broad rewrites.
* Before editing, inspect the most relevant package files, especially:

  * `DESCRIPTION`
  * `NAMESPACE`
  * `R/`
  * `tests/`
  * `man/`
  * `README.md`
  * `NEWS.md`
* If behavior changes, update tests and documentation in the same task.
* If arguments, defaults, outputs, warnings, errors, or examples change, check whether roxygen comments, `man/`, `README.md`, `NEWS.md`, and vignettes need updates.
* Reuse existing package patterns and naming conventions.
* Do not add dependencies unless necessary.

## Editing policy

* Make the smallest coherent change that solves the task.
* Avoid unnecessary refactors.
* Do not rename exported objects unless explicitly requested.
* Do not remove tests unless they are obsolete and replaced.
* Do not modify `README.md` for package-marketing purposes unless the task actually requires documentation updates.

## Completion policy

At the end, summarize:

* files changed
* whether behavior changed
* what should be tested or checked next
* any unresolved risks
