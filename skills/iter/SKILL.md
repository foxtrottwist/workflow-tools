---
name: iter
description: Task orchestration with verification gates and domain-specific decomposition. Auto-detects development (code) or knowledge (research/writing/analysis/planning) mode. Adds confirmation passes, verification agents, and guardrails on top of native Task system. Triggers - /iter, "help me build", "implement", "research", "write a document", "analyze".
---

# Iterative

Task orchestration layered on Claude Code's native Task system. This skill adds verification gates, domain-specific decomposition templates, and guardrails accumulation. The native Task tool handles fresh-context subagents, state persistence, and session resumption.

## Mode Detection

Infer mode from request context. Only ask via AskUserQuestion when genuinely ambiguous after examining available signals.

| Signal | Mode |
|--------|------|
| "implement", "build", "fix bug", "add feature", "refactor", code file references | development |
| "research", "write", "analyze", "plan", "document", "synthesize" | knowledge |

## Workflow

```
PLAN MODE  →  DECOMPOSE  →  TASK DISPATCH  →  VERIFY  →  DELIVER
(discover,    (templates)   (native Task)    (gates)   (summary)
 plan)
```

### 1. Plan Mode (Required)

Plan mode is required. Enter plan mode immediately when this skill is invoked — discovery interviews and task decomposition must occur within plan mode before any work is dispatched.

**Discovery**: Use AskUserQuestion with mode-specific templates from [references/interview.md](references/interview.md).

**Decompose**: Break into atomic units using mode-specific templates:
- **Development**: Tasks (T1, T2, ...) with files, criteria, model selection. See [references/development.md](references/development.md).
- **Knowledge**: Phases using domain templates (R1-R4, D1-D4, A1-A4, P1-P4). See [references/knowledge.md](references/knowledge.md).

**Skill mapping**: Cross-reference decomposed units against available skills (listed in the conversation's system reminders). If a unit aligns with a skill's triggers, annotate it with the skill name in the plan. Mapped tasks should invoke the skill — it provides specialized workflows and domain knowledge that general-purpose prompts lack.

### 2. Task Dispatch

After plan approval, dispatch each unit via the native Task tool.

**Development tasks:**
```
Task tool call:
- subagent_type: "general-purpose"
- model: {from task spec — haiku|sonnet|opus}
- max_turns: {from task spec}
- prompt: |
    Task: T{N} "{title}"
    Files: {paths}
    Criteria: {acceptance criteria}
    Skill: {name, if mapped — omit if none}

    Read .claude/guardrails.md for accumulated lessons before starting.
    If a skill is listed, invoke it before starting — it provides specialized workflows for this type of work.

    Work toward the criteria. Commit after completing each criterion — progress must be recoverable if interrupted. Do not batch all changes into a single commit at the end.
    If ALL criteria met, state "DONE" with summary.
    If blocked, state "BLOCKED" with reason.
```

**Knowledge phases:**
```
Task tool call:
- subagent_type: "general-purpose"
- model: sonnet
- max_turns: {from phase spec}
- prompt: |
    Phase: {ID} "{title}"
    Criteria: {acceptance criteria}
    Output: {output_path}
    Skill: {name, if mapped — omit if none}

    Read .claude/guardrails.md for accumulated lessons before starting.
    If a skill is listed, invoke it before starting — it provides specialized workflows for this type of work.

    Work toward the criteria. Save output to the specified path.
    If ALL criteria met, state "DONE" with summary.
    If blocked, state "BLOCKED" with reason.
```

**Model selection** (advisory — native routing handles the common case; use explicit overrides for cost optimization):

| Task Type | Model | Rationale |
|-----------|-------|-----------|
| File operations, simple edits | haiku | Mechanical work |
| Standard implementation, code review | sonnet | Balanced capability |
| Complex debugging, architecture | opus | Deep reasoning |

**Default**: sonnet

### 3. Verification Gates

After a unit declares DONE, run verification layers. See [references/verification.md](references/verification.md) for the full hierarchy.

**Programmatic checks** (development only):
```bash
# Build, lint, test — must all pass before proceeding
```

**Confirmation pass (N+1)** — dispatch a fresh Task with the same prompt as the original work pass. The agent doesn't know it's a confirmation. If work is truly complete, it finds nothing to do. If gaps exist, it fills them.

```
Task tool call:
- subagent_type: "general-purpose"
- model: {same as work pass}
- max_turns: 3
- prompt: {same prompt as original dispatch}
```

**Verification agent** — dispatch a review-focused Task with adversarial mindset:

```
Task tool call:
- subagent_type: "general-purpose"
- model: sonnet
- prompt: |
    Review T{N} "{title}" with adversarial mindset.
    Files: {paths}
    Criteria: {acceptance criteria}

    Check for:
    - Incomplete work, stubs, TODOs
    - Edge cases and error handling
    - Quality gaps
    - (Dev) Build/test integrity
    - (Knowledge) Depth, accuracy, completeness

    Output: VERIFIED or GAPS_FOUND with specific issues.
```

Only after all gates pass is the unit marked complete.

### 4. Deliver

After all units complete and pass verification:
1. Run task review (cross-unit integration check)
2. Present summary with outputs/files list
3. Clean up any temporary state

## Guardrails

Project-level lessons accumulate in `.claude/guardrails.md`. Every subagent reads this file before starting and appends when problems are discovered.

```markdown
## {Pattern Name}
- **When**: {context when this applies}
- **Do**: {what to do instead}
- **Learned**: {task/phase} - {brief reason}
```

Guardrails persist across sessions. Past lessons prevent repeated mistakes.

## Before Stopping

Before ending a session, check if `.claude/guardrails.md` exists. If it does, review accumulated lessons to ensure no patterns were missed.

## Anti-Patterns

- **Skipping verification**: Always run confirmation pass + verification agent
- **Giant units**: Scope tasks/phases to be completable in a few turns
- **Ignoring guardrails**: Read `.claude/guardrails.md` before every dispatch
- **Wrong model**: Use the model selection table, don't default everything to opus

## Reference Files

| File | When to Read |
|------|-------------|
| [interview.md](references/interview.md) | During discovery — question templates |
| [development.md](references/development.md) | Dev mode — task format, gates, model selection |
| [knowledge.md](references/knowledge.md) | Knowledge mode — phase templates (R/D/A/P) |
| [verification.md](references/verification.md) | After DONE — verification hierarchy, stub detection |
| [scripts/verify-gate.sh](scripts/verify-gate.sh) | Programmatic gate runner — build/lint/test, outputs gate-result.local.json |

## Commands

| Command | Action |
|---------|--------|
| `/iter {description}` | Start new task (auto-detect mode) |

## Attribution

- [Ralph Wiggum Technique](https://ghuntley.com/specs/ralph-wiggum/) (Geoffrey Huntley): fresh-context iteration pattern. Now native to Claude Code's Task system.
- [Get Shit Done](https://github.com/glittercowboy/get-shit-done) (glittercowboy): checkpoint types, four-level stub detection, automation-first verification.
