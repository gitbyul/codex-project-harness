---
name: release-readiness-review
description: Review whether a feature, MVP, milestone, or release is ready to ship by checking scope completion, acceptance criteria, quality gates, operational readiness, risks, launch dependencies, rollback, support, and go/no-go evidence.
---

# Release Readiness Review

Use this skill to produce a PM-facing go/no-go review before shipping a feature, milestone, beta, or MVP.

## Workflow

1. Read the PRD, release scope, user stories, acceptance criteria, test results, operational notes, known issues, and launch dependencies.
2. Check readiness across:
   - scope complete vs. deferred
   - acceptance criteria status
   - test and QA evidence
   - analytics or success measurement
   - support and communication needs
   - operational runbooks and rollback
   - privacy, security, compliance, or policy gates
3. Classify each issue:
   - launch blocker
   - launch risk with mitigation
   - follow-up after release
   - accepted non-goal
4. Provide a go/no-go recommendation with evidence and open decisions.

## Output Rules

- Write in the language of the target document.
- Do not mark ready without concrete evidence.
- Keep the recommendation concise and traceable to requirements or test results.
- For this RVC project, missing consent, ownership, model status, audit, traceability, or quality gates are blockers for launch readiness.
