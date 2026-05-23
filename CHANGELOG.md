# Changelog

## 0.4.0

- Block direct `harness_commit.sh` use by default so agents do not stop after
  commit while leaving push, PR, merge, branch cleanup, or worktree cleanup undone.
- Require `HARNESS_ALLOW_DIRECT_COMMIT=1` with `HARNESS_BYPASS_REASON` for explicit
  commit-only exceptions.
- Let higher-level finish/publish commands call the low-level commit command through
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
