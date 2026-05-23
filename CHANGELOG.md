# Changelog

## 0.8.0

- Add goal workflow wrappers that split a larger Codex goal into one-unit
  worktree tasks: `start_goal.sh`, `start_goal_unit.sh`,
  `finish_goal_unit.sh`, and `finish_goal.sh`.
- Track active/completed goal documents under `docs/goals/` and require each
  goal unit to complete through commit, main merge, branch cleanup, and worktree
  cleanup before the next unit starts.
- Add split backend/frontend mocking rule files for minimal Mock/Stub/Fake usage
  and contract-aligned fixture practices.
- Add development/QA rule templates, QA sections in execution plans/run
  artifacts, and configurable `quality.commands` gates that run through
  `verify.sh`.

- Stop installing the standalone commit wrapper in consuming projects and remove
  stale installed copies during update.
- Require commits to flow through finish/publish wrappers so verification,
  publication, merge, branch cleanup, and worktree cleanup stay connected.

## 0.6.0

- Make `harness_status.sh --check` validate local Git hook installation, including
  `core.hooksPath=githooks` when hook management is enabled.
- Document runtime/tool dependencies and GitHub branch protection requirements for
  consuming projects.

## 0.5.0

- Ensure initial Git repositories use `main` as the local primary branch during
  harness install/update/bootstrap.
- Add `install_github_cli.sh` wrapper to install or dry-run GitHub CLI setup across
  macOS, Linux package managers, and Windows package managers.

## 0.4.0

- Route commit work through the finish/publish flow so agents do not stop after
  commit while leaving push, PR, merge, branch cleanup, or worktree cleanup undone.
- Let higher-level finish/publish commands call the internal commit step through
  `HARNESS_INTERNAL_COMMIT=1`.

## 0.3.0

- Add CLI-first publish flow wrappers for consuming projects:
  `harness_push.sh`, `harness_publish.sh`, and `finish_codex_pr_task.sh`.
- Support dry-run checks for publish/PR commands so projects can verify the flow
  without writing to remotes.
- Route PR creation through the shared push gate so verify, completed execution
  plan, and test handoff checks run before remote publication.

## 0.2.0

- Expose the full harness workflow through consuming project wrappers:
  `start_task.sh`, `finish_task.sh`, `harness_merge.sh`,
  `finish_codex_worktree_task.sh`, worktree helpers, PR helpers, and status checks.
- Make harness workflow scripts run against `HARNESS_PROJECT_ROOT` so central scripts
  can be called from generated wrappers.
- Track the installed harness version in `.codex-harness.yml` from `manifest.json`.
- Add `installer/status.sh` and `scripts/harness_status.sh` wrappers to compare a
  consuming project against the current central harness version and managed files.
- Extend installer smoke tests to exercise start/finish workflow wrappers.

## 0.1.0

- Initial shared Codex harness scripts, Git hooks, GitHub workflow template, installer,
  and generic PM skills.
