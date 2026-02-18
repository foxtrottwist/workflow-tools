---
name: sharpen
description: Refine raw, unstructured thoughts into focused statements of intent. Takes stream-of-consciousness input and produces sharp, dense, actionable prompts or lightweight specs through guided questioning. Use when asked to "sharpen", "refine my thinking", "focus this idea", "help me clarify", "what am I trying to say", or when a user provides rambling/unstructured input that needs to be distilled before starting work. Also triggers on "shape this prompt", "clarify my intent", "tighten this up", or requests to prepare input for other workflows.
---

# Sharpen

Refine unstructured thinking into focused intent through conversational questioning. Produces output ready for direct use, workflow invocation, or disk for later.

## Workflow

```
INTAKE  →  ANALYZE  →  CLARIFY  →  SYNTHESIZE  →  REVIEW  →  DELIVER
```

## 1. Intake

Accept raw input without judgment. The user's initial dump may be rambling, contradictory, or incomplete — that's the point. Acknowledge receipt and signal that refinement is starting.

Do not ask questions yet. First, analyze.

## 2. Analyze

Silently extract from the raw input:

- **Core intent** — What is the user actually trying to accomplish?
- **Stated concerns** — What did they explicitly mention as important?
- **Implied concerns** — What's between the lines (dependencies, risks, prerequisites)?
- **Contradictions** — Where does the input conflict with itself?
- **Gaps** — What critical information is missing?
- **Domain** — Is this technical work, knowledge work, or mixed?

This analysis drives the questions in the next phase. Do not present the analysis to the user — it informs question selection.

## 3. Clarify

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

## 4. Synthesize

Draft the refined output. Apply these principles:

- **Dense over verbose** — Every sentence should carry information. Cut filler.
- **Specific over abstract** — Name the things. "Refactor the auth middleware" beats "improve the authentication system."
- **Structured over flat** — Use the templates in [references/output-formats.md](references/output-formats.md) as starting points.
- **Preserve the user's priorities** — The ordering from clarification should be reflected in the output. Primary concerns first.

Select the output format based on complexity:
- **Statement of intent** — Default for most inputs. Dense, single-page.
- **Lightweight spec** — For complex, multi-phase work or when the user wants to save for later.

## 5. Review

Present the synthesized output and ask for approval using **AskUserQuestion**:

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

**If "Needs editing":** Apply the user's specific changes, re-present. No need to re-run full clarification.

**If "Something's missing":** Ask what's missing, integrate it, re-present.

**If "Start over":** Return to Clarify (step 3) with the new context from this attempt. The failed synthesis is still useful — it shows what the user *doesn't* want.

## 6. Deliver

After approval, ask for output mode:

```yaml
question: "How should I deliver this?"
options:
  - label: "Show inline"
    description: "Display as copyable text right here"
  - label: "Invoke a workflow"
    description: "Hand off to iter, writing, prompt-dev, or another skill"
  - label: "Save to disk"
    description: "Write as a *.local.md file for future use"
  - label: "Show inline + save"
    description: "Display now and also write to disk"
```

**Show inline:** Present the final output in a clean, copyable format.

**Invoke a workflow:** Suggest the best-fit skill based on the refined intent. Present the suggested invocation for approval before triggering.

**Save to disk:** Write to `{slug}.local.md` in the current working directory. Use a descriptive slug derived from the intent (e.g., `auth-refactor-spec.local.md`, `api-research-brief.local.md`).

**Show inline + save:** Both — display first, then write to disk.

See [references/output-formats.md](references/output-formats.md) for delivery templates.

## References

| File | When to Read |
|------|-------------|
| [output-formats.md](references/output-formats.md) | During Synthesize and Deliver — templates for statements of intent, specs, and workflow invocations |
