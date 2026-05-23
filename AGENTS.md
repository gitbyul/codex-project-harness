# Codex Project Harness Agent Rules

This directory is the central source for shared Codex harness engineering and generic PM skills.

## Modification Guard

- Do not edit this directory while working from another product project.
- Edit this directory only when the user explicitly asks to modify `codex-project-harness`.
- The agent working directory must be `/Users/abyul/Desktop/project/codex-project-harness` before changing files here.
- Project-specific requirements, domain skills, product planning, and operational policies belong in the consuming project, not here.
- Installer scripts must copy from this repository to projects; they must not write project changes back into this repository.

## Validation

Run:

```bash
./installer/validate.sh
```

If a consuming project is updated, also run that project's `./scripts/verify.sh`.
