# Codex Project Harness Agent Rules

This directory is the central source for shared Codex harness engineering and generic PM skills.

## Modification Guard

- Do not edit this directory while working from another product project.
- Edit this directory only when the user explicitly asks to modify `codex-project-harness`.
- The agent working directory must be this repository root before changing files here.
- Project-specific requirements, domain skills, product planning, and operational policies belong in the consuming project, not here.
- Installer scripts must copy from this repository to projects; they must not write project changes back into this repository.

## Change Management

- Update `manifest.json` version whenever central harness behavior, installed wrappers, validation rules, or generic PM skills change in a way consuming projects need to track.
- Add a matching `CHANGELOG.md` entry describing what changed and what consuming projects may need to update.
- `installer/update.sh` must write the current `manifest.json` version into each consuming project's `.codex-harness.yml`.
- `installer/status.sh <project>` must remain the supported way to compare a consuming project's configured harness version and managed files against this central source.
- When wrapper coverage changes, update `README.md`, `templates/docs/engineering/codex-skills.md`, and installer smoke tests together.

## Workflow

- Prefer `harness/scripts/start_task.sh` or an installed `./scripts/start_task.sh` before making non-trivial harness changes.
- Finish work through high-level commands such as `finish_codex_worktree_task.sh`, `finish_codex_pr_task.sh`, or `harness_publish.sh` so execution plans, run artifacts, validation, push/PR or merge, branch cleanup, and worktree cleanup stay connected.
- Treat `harness_commit.sh` as a low-level internal command. Direct use requires `HARNESS_ALLOW_DIRECT_COMMIT=1` and `HARNESS_BYPASS_REASON`.
- For remote delivery from a consuming project, prefer installed CLI wrappers such as `harness_publish.sh`, `harness_push.sh`, `finish_codex_pr_task.sh`, `open_pr.sh`, and `squash_merge_pr.sh` over plugin-only or skill-only flows.
- Install/update/bootstrap must preserve the convention that new or initial repositories use `main` as the local primary branch. Existing non-initial project branch policies must not be renamed destructively.
- Keep GitHub CLI setup available as an installed wrapper (`install_github_cli.sh`) with a dry-run mode; do not make network/package-manager installation mandatory during ordinary harness install.
- If manual Git commands are used because the workflow itself is being repaired, record the reason in the execution plan or final response.

## Validation

Run:

```bash
./installer/validate.sh
```

If a consuming project is updated, also run that project's `./scripts/verify.sh`.
