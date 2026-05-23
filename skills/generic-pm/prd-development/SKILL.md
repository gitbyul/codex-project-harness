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
5. For this repository, preserve RVC-specific constraints:
   - consent, rights, ownership, model state, policy, and audit gates are product requirements
   - audio quality and QC criteria must be represented when training, separation, conversion, preview, download, or feedback is in scope

## Output Rules

- Write in the language of the target document.
- Use `template.md` when creating a new PRD from scratch.
- Do not invent metrics, thresholds, legal terms, or technical commitments that are not supported by source documents. Mark uncertain items as TBD or open questions.
- If the PRD touches user stories or ticket breakdown, use or follow `deliver-user-stories`.
- If the PRD is for this RVC project and touches scope, rights, or quality, use or follow `rvc-product-scope`, `rvc-rights-policy-gates`, and `rvc-quality-qc` as relevant.
