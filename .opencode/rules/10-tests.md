---
alwaysApply: true
---
# 10-tests.md

When working on code or tests in this repository, prioritize regression safety.

## Testing expectations

- If behavior changes, update or add tests in the same task.
- Prefer targeted tests over broad rewrites of the test suite.
- Preserve existing coverage unless a test is clearly obsolete and replaced.
- Prefer adding a failing or clearly motivated test before changing logic when practical.

## Function Verification Reports

For modified or new functions:
- Generate a standalone verification report demonstrating error-free execution on sample data.
- Follow the guidelines in [Function Reports](.opencode/rules/11-function-reports.md).
- Store scripts and results in `.opencode/reports/`.

## What to check

Focus especially on:

- input validation
- missing values
- zero-length inputs
- type/class handling
- vectorization behavior
- warnings and errors
- output structure, names, and return class
- backward-compatible behavior for exported functions

## Editing policy

- Do not remove tests casually.
- Do not rewrite unrelated tests.
- Keep test changes directly tied to observable behavior.
- Reuse the existing testing style and file organization already present in `tests/`.

## Completion

At the end of a task involving code changes, state:

- which tests were added or updated
- which behaviors were validated
- which tests or checks should still be run next
