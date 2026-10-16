---
alwaysApply: true
---
# 20-docs.md

When working on user-facing code or documentation in this repository, keep documentation aligned with actual behavior.

## Documentation expectations

- If function behavior changes, update the relevant documentation in the same task.
- If arguments, defaults, return values, warnings, errors, or examples change, check whether roxygen comments, `man/`, `README.md`, `NEWS.md`, and vignettes need updates.
- If behavior does not change, avoid unnecessary documentation churn.

## What to update

Consider the relevant documentation layers:

- inline roxygen comments
- generated docs in `man/`
- `README.md`
- `NEWS.md`
- vignettes
- examples

## Editing policy

- Do not describe behavior the code does not implement.
- Do not leave examples inconsistent with current function signatures.
- Preserve the existing documentation style and tone.
- Prefer small, precise doc edits over large rewrites.

## Completion

At the end of a task involving user-facing changes, state:

- which documentation files were updated
- whether examples changed
- whether additional documentation regeneration or checks should be run
