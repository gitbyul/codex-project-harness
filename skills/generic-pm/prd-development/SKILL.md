---
name: prd-development
description: Build or improve a structured PRD that connects problem, users, scope, requirements, success criteria, risks, and engineering handoff. Use when turning discovery notes, roadmap items, or product requirements into a concise PRD.
---

# PRD Development

Use this skill to turn product notes into an engineering-ready PRD. Keep the document concise, decision-oriented, and traceable to source planning documents.

## Workflow

1. Read the source notes, roadmap, existing requirements, and any linked design or research material.
2. Identify the product decision to make:
   - new PRD
   - PRD gap review
   - scope clarification
   - engineering handoff cleanup
3. Draft or revise the PRD around:
   - problem statement
   - target users and jobs-to-be-done
   - goals and non-goals
   - user workflows
   - functional requirements
   - acceptance criteria
   - success metrics
   - dependencies, risks, and open questions
4. Keep requirements testable and separate product intent from implementation details.
5. Preserve project-specific constraints only when they are present in the consuming project's source documents or local skills.

## Output Rules

- Write in the language of the target document.
- Use `template.md` when creating a new PRD from scratch.
- Do not invent metrics, thresholds, legal terms, or technical commitments that are not supported by source documents. Mark uncertain items as TBD or open questions.
- If the PRD touches user stories or ticket breakdown, use or follow `deliver-user-stories`.
- If local project-specific skills are relevant, use them as constraints instead of adding domain assumptions to this generic PRD.
