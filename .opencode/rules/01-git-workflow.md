# 01-git-workflow.md

At the end of each completed coding task, review and commit relevant local
changes. Push, merge, publish or release only when explicitly requested.

## Required Git behavior

* Assume this repository is already a valid Git repository with a configured remote.
* After finishing the requested work, check whether there are actual file changes.
* If there are no changes, do not create an empty commit.
* If there are changes:

  1. review the changed files briefly
  2. stage the relevant changes
  3. create a concise, descriptive Git commit
  4. report the local checkpoint; push only after an explicit request
* If the push fails, do not keep retrying blindly. Stop and clearly report the Git error.

## Commit message rules

* Use a short, descriptive commit message.
* Prefer one of these formats:

  * `fix: <short description>`
  * `feat: <short description>`
  * `docs: <short description>`
  * `test: <short description>`
  * `refactor: <short description>`
  * `chore: <short description>`
* The commit message should match the actual change and should not be vague.

## Safety rules

* Do not commit or push if the task is incomplete, clearly broken, or blocked by an unresolved error.
* Do not commit unrelated file changes unless they are necessary for the requested task.
* Do not use destructive Git commands such as force-push, reset, rebase, amend, or deleting branches unless I explicitly request them.
* Do not create empty commits.
* If there are merge conflicts, authentication problems, or remote rejection, stop and report the issue.
