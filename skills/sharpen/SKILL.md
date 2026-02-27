---
name: sharpen
description: Refine raw, unstructured thoughts into focused statements of intent. Takes stream-of-consciousness input and produces sharp, dense, actionable prompts or lightweight specs through guided questioning. Use when asked to "sharpen", "refine my thinking", "focus this idea", "help me clarify", "what am I trying to say", or when a user provides rambling/unstructured input that needs to be distilled before starting work. Also triggers on "shape this prompt", "clarify my intent", "tighten this up", or requests to prepare input for other workflows.
---

# Sharpen

Refine unstructured thinking into focused intent. This session's only job is to produce a clear statement of intent, save it to disk, and end. The spec on disk is the handoff artifact for the next session.

## Workflow

```
PLAN MODE  →  INTAKE  →  ANALYZE  →  CLARIFY  →  SYNTHESIZE  →  APPROVE  →  DELIVER
(if avail.)   (accept)   (silent)    (ask)       (draft)        (gate)      (save + handoff)
```

## 1. Enter Plan Mode

If plan mode is available (Claude Code, Cowork), enter it immediately. Plan mode prevents premature execution — this session is for thinking, not building.

**Claude Code specifics:** After plan approval, Claude Code defaults to clearing context and executing. The plan file survives this clear. To make the handoff work, the plan must include a `## Post-Approval` section at the end with the save path and iter invocation — this is what Claude reads after the context clear to know its only remaining job is to save the file and present the handoff.

If plan mode is not available (chat, API), proceed directly to Intake. The AskUserQuestion approval in step 6 serves the same gating role. The session still ends after delivery.

## 2. Intake

Accept raw input without judgment. The user's initial dump may be rambling, contradictory, or incomplete — that's the point. Acknowledge receipt and signal that refinement is starting.

Do not ask questions yet. First, analyze.

## 3. Analyze

Silently extract from the raw input:

- **Core intent** — What is the user actually trying to accomplish?
- **Stated concerns** — What did they explicitly mention as important?
- **Implied concerns** — What's between the lines (dependencies, risks, prerequisites)?
- **Contradictions** — Where does the input conflict with itself?
- **Gaps** — What critical information is missing?
- **Domain** — Is this technical work, knowledge work, or mixed?

This analysis drives the questions in the next phase. Do not present the analysis to the user — it informs question selection.

## 4. Clarify

Use **AskUserQuestion** to run 2-3 targeted rounds. Each round should build on previous answers. Questions should feel like a conversation, not a form.

### Question Design Principles

- **Infer first, confirm second** — Pre-populate options with what you've already deduced. The user confirming a good inference is faster than answering from scratch.
- **Surface the non-obvious** — The most valuable questions reveal things the user hadn't considered. "You mentioned X — does that also mean Y?" is more useful than "What do you want?"
- **Prioritize** — Ask about gaps and contradictions before preferences. Missing information matters more than nice-to-haves.
- **Combine related questions** — Use multiSelect when concerns are non-exclusive. Batch related facets into a single AskUserQuestion call (up to 4 questions per call).

### Round 1: Confirm and Prioritize

Focus on validating the core intent and ranking concerns.

```yaml
# Question 1: Confirm inferred intent
question: "Is this what you're going for?"
options:
  - "{inferred intent statement} (Recommended)"
  - "{alternative interpretation}"
  - "{narrower scope variation}"

# Question 2: Priority of concerns (if multiple identified)
question: "Which of these matter most?"
multiSelect: true
options:
  - "{concern A}"
  - "{concern B}"
  - "{concern C}"
  - "{concern D}"
```

### Round 2: Fill Gaps

Address the most important gaps identified in analysis. Tailor questions to the domain.

**Technical work:**
- Scope boundaries (what's in, what's out)
- Constraints (compatibility, performance, existing patterns)
- Definition of done

**Knowledge work:**
- Audience and purpose
- Depth vs breadth
- Deliverable format

**Mixed/unclear:**
- Which aspect to tackle first
- How the pieces relate

### Round 3 (if needed): Resolve Tensions

Only ask a third round if contradictions remain or the user's round 2 answers introduced new ambiguity. Skip if the picture is clear.

### Adaptive Questioning

Not every input needs all three rounds. Match question depth to input complexity.

- **Simple input** (clear intent, few concerns): 1 round — confirm intent, ask about output preference
- **Moderate input** (clear intent, multiple concerns): 2 rounds — confirm + prioritize, then fill gaps
- **Complex input** (unclear intent, contradictions, many threads): 3 rounds — confirm, gap-fill, resolve tensions

## 5. Synthesize

Draft the refined output. Apply these principles:

- **Dense over verbose** — Every sentence should carry information. Cut filler.
- **Specific over abstract** — Name the things. "Refactor the auth middleware" beats "improve the authentication system."
- **Structured over flat** — Use the section requirements in [references/output-formats.md](references/output-formats.md) to ensure completeness.
- **Preserve the user's priorities** — The ordering from clarification should be reflected in the output. Primary concerns first.

Select the output format based on complexity:
- **Statement of intent** — Default for most inputs. Dense, single-page.
- **Lightweight spec** — For complex, multi-phase work or when the user wants to save for later.

## 6. Approve

Present the synthesized spec for approval. This is the gate between thinking and delivery.

**In plan mode (Claude Code):** Write the spec to the plan file with a `## Post-Approval` section appended:

```
## Post-Approval

Save the spec above (everything before this section) to `.workflow.local/sharpen/{slug}.md`.
Then present the handoff: suggest clearing context and invoking `/iter` with the spec file path.
```

Then use ExitPlanMode. After the user approves (default: clear context + auto-accept), Claude reads the plan file, sees the Post-Approval section, and executes the save + handoff. The Post-Approval section is excluded from the saved spec file.

**Without plan mode (chat, Cowork, API):** Use AskUserQuestion:

```yaml
question: "How does this look?"
options:
  - label: "Approve — this captures it"
    description: "Move to delivery"
  - label: "Needs editing"
    description: "Specific parts need adjustment — tell me what"
  - label: "Something's missing"
    description: "A key concern or requirement isn't represented"
  - label: "Start over"
    description: "The framing is off — loop back through clarification"
```

**If revision requested:** Apply changes, re-present. A failed synthesis is still useful — it shows what the user *doesn't* want.

**If "Start over":** Return to Clarify (step 4) with new context from this attempt.

## 7. Deliver

After plan approval, Write tools are available. Always save to disk — the file is the handoff artifact.

1. **Save** the approved spec to `.workflow.local/sharpen/{slug}.md`. Descriptive slug from the intent (e.g., `auth-refactor-spec.md`, `api-research-brief.md`).
2. **Present the handoff.** Show the file path and the suggested next step. See [references/output-formats.md](references/output-formats.md) for the handoff format.

The session's job is done. The spec on disk crosses the context boundary — the next session reads it cold.

### Handoff Chain

This skill is the first stage of a three-phase pipeline:

```
SHARPEN (this session)     →  ITER plan (next session)      →  ITER execute (next session)
Clarify intent → spec file    Read spec → decompose → plan    Read plan → dispatch → verify
```

Each phase gets full context budget for its specific job. The file on disk is the only thing that crosses each boundary.

## References

| File | When to Read |
|------|-------------|
| [output-formats.md](references/output-formats.md) | During Synthesize and Deliver — spec formats and handoff template |
