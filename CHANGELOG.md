# Changelog

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
