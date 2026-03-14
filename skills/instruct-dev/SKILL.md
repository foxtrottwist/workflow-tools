---
name: instruct-dev
description: "Write and review instruction files for Claude — prompt templates, CLAUDE.md, skills, and agent definitions. Use when asked to build a prompt, write a CLAUDE.md, create or review a skill, optimize agent files, audit instruction quality, or debug why instructions aren't working. Triggers on: 'create a prompt', 'build a template', 'write a CLAUDE.md', 'review my skill', 'optimize this agent file', 'fix this prompt', 'audit instructions'. Instruction authoring, agent file optimization, skill description tuning."
---

# Instruction Development

Iterative instruction authoring using the DISCOVER → DRAFT → TEST → REFINE → VALIDATE workflow. Covers four artifact types: prompt templates, CLAUDE.md files, skill definitions, and agent definitions. State persists in files for resumption.

## Resume Check

Every invocation, check for existing state in `.workflow.local/instruct-dev/`.

**If state exists**, read `state.json` and present status. Offer to resume, start fresh, or show current artifact.

**If no state**, proceed to Discover.

## Artifact Type Detection

Infer the artifact type from the request context — do not ask:

| Signal | Artifact Type |
|--------|--------------|
| "prompt", "template", structured input/output | **prompt-template** |
| "CLAUDE.md", "project instructions", "corrections" | **claude-md** |
| "skill", "SKILL.md", "slash command", "workflow" | **skill** |
| "agent", "agent definition", "subagent" | **agent** |

If genuinely ambiguous, ask once with these four options.

## Phase 1: Discover

Infer requirements from the request context:
- **Purpose**: What the artifact handles
- **Audience**: Who/what consumes it (model, user, CI)
- **Scope**: Boundaries — what's in, what's out
- **Existing state**: Is this new, or reviewing/improving something?

Use **AskUserQuestion** only for genuine gaps.

**Output:**
- Create `.workflow.local/instruct-dev/{artifact-slug}/`
- Write `brief.md` with requirements and detected artifact type
- Write `state.json`: `{ "phase": "draft", "type": "<artifact-type>" }`

## Phase 2: Draft

Route to artifact-specific guidance:

| Artifact Type | Reference | Action |
|--------------|-----------|--------|
| prompt-template | [conventions.md](references/conventions.md), [examples.md](references/examples.md) | Draft template following Claude 4 patterns |
| claude-md | [claude-md-guide.md](references/claude-md-guide.md) | Draft using Build/Test → Constraints → Corrections → Gotchas structure |
| skill | [skill-guide.md](references/skill-guide.md) | Hand off to `skill-creator` for scaffolding, then draft SKILL.md body |
| agent | [agent-guide.md](references/agent-guide.md) | Draft using Operating Principles → Output → Constraints structure |

All artifact types: load [principles.md](references/principles.md) for cross-cutting guidance.

**Output:**
- Write `draft.md` with the artifact
- Create empty `test-log.md` and `guardrails.md`
- Update `state.json`: `{ "phase": "test" }`
- Present draft for user review

## Phase 3: Test

Apply the artifact-specific review checklist from the relevant reference file:
- prompt-template: quality checklist in [conventions.md](references/conventions.md)
- claude-md: 8-item checklist in [claude-md-guide.md](references/claude-md-guide.md)
- skill: 10-item checklist in [skill-guide.md](references/skill-guide.md)
- agent: 4-item checklist in [agent-guide.md](references/agent-guide.md)

For prompt templates, also run `scripts/validate-template.sh <path>` if available.

Log each checklist item in `test-log.md` with PASS/FAIL/NOTE.

**Exit criteria:**
- All checklist items evaluated
- Any FAIL items have remediation notes

Update `state.json`: `{ "phase": "refine" }`

## Phase 4: Refine

For each FAIL item from testing:
1. Identify root cause
2. Apply fix to `draft.md`
3. Log in `guardrails.md`:
   - **Symptom:** what failed
   - **Fix:** what changed
   - **Principle:** which principle applies (P1–P8)
4. Re-run failed checklist items

**Token cost check** (all artifact types):
- <100 lines: likely fine
- 100–200: review for cuts
- 200–400: active compression needed
- >400: must split into modules

**Exit criteria:**
- All FAIL items resolved
- Token cost tier is acceptable

Update `state.json`: `{ "phase": "validate" }`

## Phase 5: Validate

Final review pass. Optionally dispatch the `editor` agent for adversarial review against writing standards.

Check cross-cutting principles from [principles.md](references/principles.md):
- [ ] No discoverable content restated (P1)
- [ ] No proactive/speculative rules (P2)
- [ ] No output format templates with `[placeholder]` syntax (P3)
- [ ] Verification mechanism present where applicable (P4)
- [ ] No generic knowledge the model already has (P5)
- [ ] Routing and execution properly separated (P8)

**If all pass:**
- Present final artifact
- Archive to `.workflow.local/instruct-dev/archive/{slug}/` if requested
- Update `state.json`: `{ "phase": "complete" }`

**If issues found:**
- Return to appropriate phase

## State Files

```
.workflow.local/instruct-dev/{artifact-slug}/
├── state.json      # Current phase + artifact type
├── brief.md        # Requirements from discovery
├── draft.md        # Current artifact version
├── test-log.md     # Checklist results
└── guardrails.md   # Patterns that didn't work
```
