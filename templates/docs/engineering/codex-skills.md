# Codex PM Skill Guide

This document explains the shared generic PM skills installed from `codex-project-harness`.

## Source

- Central harness: `/Users/abyul/Desktop/project/codex-project-harness`
- Project-local skills: `.codex/skills/`
- Project harness config: `.codex-harness.yml`

Update shared skills from the central harness:

```bash
/Users/abyul/Desktop/project/codex-project-harness/installer/update.sh .
```

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

## Project-Specific Skills

Project-specific skills stay in the consuming project. Do not add domain-specific product rules to the central generic PM skills unless they apply broadly across projects.
