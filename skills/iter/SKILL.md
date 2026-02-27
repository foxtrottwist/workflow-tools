---
name: iter
description: "Use when building features, implementing tasks, researching topics, writing documents, or analyzing problems. Triggers on /iter, \"help me build\", \"implement\", \"research\", \"write a document\", \"analyze\", or any multi-step task that benefits from structured orchestration."
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
- **Development**: Tasks (T1, T2, ...) with files, criteria, weight, dispatch, model selection. All implementation tasks map to the `tdd` skill by default — tests before production code. See [references/development.md](references/development.md).
- **Knowledge**: Phases using domain templates (R1-R4, D1-D4, A1-A4, P1-P4). See [references/knowledge.md](references/knowledge.md).

**Skill mapping**: Cross-reference decomposed units against available skills (listed in the conversation's system reminders). If a unit aligns with a skill's triggers, annotate it with the skill name in the plan. Mapped tasks should invoke the skill — it provides specialized workflows and domain knowledge that general-purpose prompts lack.

### 2. Task Dispatch

After plan approval, dispatch each unit according to its `dispatch` field. Tasks marked `subagent` use the Task tool. Tasks marked `inline` execute in the primary context — the orchestrator does the work directly, keeping intermediate results visible for downstream decisions.

This distinction matters most after a context clear between planning and execution. The fresh session reads the plan file and acts on the dispatch annotation without re-deriving the delegation decision.

**Development tasks (dispatch: subagent):**
```
Task tool call:
- subagent_type: "general-purpose"
- model: {from task spec — haiku|sonnet|opus}
- max_turns: {from task spec}
- prompt: |
    Task: T{N} "{title}"
    Files: {paths}
    Criteria: {acceptance criteria}
    Skill: tdd{, additional skill if mapped}

    Before writing any code, review the codebase you're working in — read existing files, understand patterns and conventions already in use.

    Review the available skills listed in your system reminders. If any skill is relevant to this task (by name alone you can tell — e.g., swift-dev for Swift work, swiftui-expert-skill for SwiftUI, systematic-debugging for bugs), invoke it. Skills provide domain-specific workflows and constraints you won't have otherwise.

    Read .claude/guardrails.md for accumulated lessons before starting.
    Invoke the tdd skill — write failing tests before production code (RED-GREEN-REFACTOR).

    Work toward the criteria. Commit in logical units — at minimum one commit per task, more if the task has natural boundaries.
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
    Before starting, review the codebase or existing material relevant to this phase.

    Review the available skills listed in your system reminders. If any skill is relevant to this phase (by name alone you can tell — e.g., writing for composition, prompt-dev for templates), invoke it. Skills provide domain-specific workflows and constraints you won't have otherwise.

    Read .claude/guardrails.md for accumulated lessons before starting.

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

Load references selectively based on detected mode and workflow phase. Not every file is needed on every invocation — skip irrelevant references to keep context focused.

| File | When to Read | Skip When |
|------|-------------|-----------|
| [interview.md](references/interview.md) | Plan mode / discovery phase | Task dispatch and verification phases |
| [development.md](references/development.md) | Development mode — task format, gates, model selection | Knowledge mode |
| [knowledge.md](references/knowledge.md) | Knowledge mode — phase templates (R/D/A/P) | Development mode |
| [verification.md](references/verification.md) | After DONE — verification hierarchy, stub detection, recovery patterns | Never skip |
| [scripts/verify-gate.sh](scripts/verify-gate.sh) | Programmatic gate runner — build/lint/test, outputs gate-result.local.json | Knowledge mode |

**Loading by phase:**
- **Discovery/planning**: interview.md + the mode-specific reference (development.md or knowledge.md)
- **Task dispatch**: mode-specific reference only (development.md or knowledge.md)
- **Verification**: verification.md only

## Commands

| Command | Action |
|---------|--------|
| `/iter {description}` | Start new task (auto-detect mode) |

## Attribution

- [Ralph Wiggum Technique](https://ghuntley.com/specs/ralph-wiggum/) (Geoffrey Huntley): fresh-context iteration pattern. Now native to Claude Code's Task system.
- [Get Shit Done](https://github.com/glittercowboy/get-shit-done) (glittercowboy): checkpoint types, four-level stub detection, automation-first verification.
