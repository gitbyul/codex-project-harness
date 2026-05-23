# Codex PM Skill Guide

This document explains the shared generic PM skills installed from `codex-project-harness`.

## Source

- Central harness: `/Users/abyul/Desktop/project/codex-project-harness`
- Project-local skills: `.codex/skills/`
- Project harness config: `.codex-harness.yml`

Update shared skill wrappers from the central harness:

```bash
/Users/abyul/Desktop/project/codex-project-harness/installer/update.sh .
```

The shared PM skill source remains in the central harness. Project-local generic PM skill files under `.codex/skills/` are wrappers that point agents back to the central source.

## Generic PM Skills

- `product-discovery-synthesis`: synthesize discovery notes, interviews, feedback, and research into problems, users, JTBD, assumptions, and opportunities.
- `prd-development`: create or improve PRDs with problem, users, scope, requirements, success criteria, risks, and engineering handoff.
- `deliver-user-stories`: break requirements into user stories and Given/When/Then acceptance criteria.
- `roadmap-prioritization`: prioritize roadmap items, MVP scope, feature candidates, and backlog tradeoffs.
- `release-readiness-review`: review launch readiness, blockers, risks, QA evidence, operational readiness, and go/no-go decisions.
- `stakeholder-status-update`: turn progress, blockers, decisions, and validation results into concise stakeholder updates.

## Recommended Flow

1. Use `product-discovery-synthesis` to clarify the problem and assumptions.
2. Use `prd-development` to turn decisions into a PRD.
3. Use `deliver-user-stories` to make implementation-ready stories.
4. Use `roadmap-prioritization` to sequence MVP, near-term, and later work.
5. Use `release-readiness-review` before launch or milestone completion.
6. Use `stakeholder-status-update` for status, decision summaries, handoffs, and escalations.

## Harness Workflow

Use the installed project wrappers for implementation work:

```bash
./scripts/start_task.sh "작업 이름" task/example
# make changes
./scripts/finish_codex_worktree_task.sh "feat(scope): 작업 설명"
```

The workflow creates an execution plan, records a run artifact, verifies the project, commits through the harness checks, merges into the main branch, and removes the merged branch/source worktree when possible.

Do not use `harness_commit.sh` as the normal completion command. It is a low-level internal command and is blocked by default because commit-only work leaves push, PR, merge, branch cleanup, or worktree cleanup unfinished. Use `finish_codex_worktree_task.sh`, `finish_codex_pr_task.sh`, or `harness_publish.sh`.

For remote publication and PR-based delivery, use the CLI wrappers instead of relying on agent-only skills:

```bash
./scripts/finish_codex_pr_task.sh "feat(scope): 작업 설명"
./scripts/harness_publish.sh "feat(scope): 작업 설명" --pr
./scripts/harness_publish.sh "feat(scope): 작업 설명" --push-only
```

Use `--dry-run` to verify command wiring without writing to the remote:

```bash
./scripts/harness_publish.sh "feat(scope): 작업 설명" --pr --dry-run
```

Check the installed shared harness version and managed file coverage:

```bash
./scripts/harness_status.sh
./scripts/harness_status.sh --check
```

## Project-Specific Skills

Project-specific skills stay in the consuming project. Do not add domain-specific product rules to the central generic PM skills unless they apply broadly across projects.
