# Codex Project Harness Agent Rules

This directory is the central source for shared Codex harness engineering and generic PM skills.

## Modification Guard

- Do not edit this directory while working from another product project.
- Edit this directory only when the user explicitly asks to modify `codex-project-harness`.
- The agent working directory must be `/Users/abyul/Desktop/project/codex-project-harness` before changing files here.
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
- Finish work through `finish_task.sh`, `harness_commit.sh`, and `harness_merge.sh` where possible so execution plans, run artifacts, validation, branch cleanup, and worktree cleanup stay connected.
- If manual Git commands are used because the workflow itself is being repaired, record the reason in the execution plan or final response.

## Validation

Run:

```bash
./installer/validate.sh
```

If a consuming project is updated, also run that project's `./scripts/verify.sh`.
