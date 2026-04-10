---
name: sharpen
description: Refine raw, unstructured thoughts into focused statements of intent. Takes stream-of-consciousness input and produces sharp, dense, actionable prompts or lightweight specs through guided questioning. Use when asked to "sharpen", "refine my thinking", "focus this idea", "help me clarify", "what am I trying to say", or when a user provides rambling/unstructured input that needs to be distilled before starting work. Also triggers on "shape this prompt", "clarify my intent", "tighten this up", or requests to prepare input for other workflows.
---

# Sharpen

Refine unstructured thinking into a focused, executable spec. This session's only job is to produce a clear statement of intent, save it to disk, and end. The spec on disk is an executable contract — the next session is expected to read it end-to-end, consult every reference it cites, investigate the relevant code, and implement every success criterion. Sharpen's job is to make sure the spec carries everything the downstream reader needs to do that without falling back on built-in assumptions.

## Workflow

```
INTAKE  →  ANALYZE  →  CLARIFY  →  SYNTHESIZE  →  APPROVE  →  DELIVER
(accept)   (silent)    (ask)       (draft)        (gate)      (save + handoff)
```

## 1. Intake

Accept raw input without judgment. The user's initial dump may be rambling, contradictory, or incomplete — that's the point. Acknowledge receipt and signal that refinement is starting.

Capture any documents, guides, file paths, or URLs the user mentions verbatim — these are candidate references for the spec's **References** section and must not be paraphrased or summarized away during Analyze.

Do not ask questions yet. First, analyze.

## 2. Analyze

Silently extract from the raw input:

- **Core intent** — What is the user actually trying to accomplish?
- **Stated concerns** — What did they explicitly mention as important?
- **Implied concerns** — What's between the lines (dependencies, risks, prerequisites)?
- **Reference sources** — What documents, guides, file paths, or URLs did the user cite or allude to? List candidates verbatim. If the user gestured at "the style guide" or "our existing auth" without naming a specific artifact, flag it as a Clarify question — the spec needs specific paths, not vague gestures.
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

### Round 2: Fill Gaps and Surface References

Address the most important gaps identified in analysis. Tailor questions to the domain, and always surface references when the user mentioned or implied external material.

**Reference surfacing (all domains):** When intake mentioned a guide, doc, file, or URL — even vaguely — ask explicitly which specific paths should travel with the spec. A spec with an empty References section fails the handoff. Good question form: "You mentioned the security guide — is that `docs/security.md`, or somewhere else?" not "Are there docs I should know about?"

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
- **References over assumptions** — Cite specific paths, URLs, and file names. The downstream reader must read them rather than default to built-in knowledge. Never write "follow existing patterns" without naming the file to read; never write "per the style guide" without the guide's path.
- **Structured over flat** — Use the section requirements in [references/output-formats.md](references/output-formats.md) to ensure completeness. Both spec formats require **References** and **Execution Directives** sections — these are non-negotiable.
- **Preserve the user's priorities** — The ordering from clarification should be reflected in the output. Primary concerns first.

Select the output format based on complexity:
- **Statement of intent** — Default for most inputs. Dense, single-page.
- **Lightweight spec** — For complex, multi-phase work or when the user wants to save for later.

## 5. Approve

Present the synthesized spec for approval. This is the gate between thinking and delivery.

Use AskUserQuestion:

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

**If "Start over":** Return to Clarify (step 3) with new context from this attempt.

## 6. Deliver

After approval, save to disk — the file is the executable contract the next session will follow.

1. **Save** the approved spec to `.workflow.local/sharpen/{slug}.md`. Descriptive slug from the intent (e.g., `auth-refactor-spec.md`, `api-research-brief.md`).
2. **Present the handoff.** Show the file path and a literal, copy-pasteable next command (e.g., `/iter .workflow.local/sharpen/auth-refactor-spec.md`) — not just a skill name. Select the skill from the spec's domain: `/iter` for implementation or research, `/prompt-dev` for prompt templates, `/write` for written content. See [references/output-formats.md](references/output-formats.md) for the exact form.

The session's job is done. The spec on disk crosses the context boundary — the next session reads it cold and is expected to follow it end-to-end, consult every reference, and implement every success criterion. The handoff is deliberate: the user runs the next command themselves, so every downstream invocation is a conscious choice.

### Handoff Chain

This skill is the first stage of a three-phase pipeline:

```
SHARPEN (this session)     →  ITER plan (next session)      →  ITER execute (next session)
Clarify intent → spec file    Read spec → decompose → plan    Read plan → dispatch → verify
```

Each phase gets full context budget for its specific job. The file on disk is the only thing that crosses each boundary.

## Worked Example

**User intake:** "I need to refactor the auth middleware because legal flagged it for how it stores session tokens. The compliance rules are in `legal/session-tokens.md` and we have a security guide at `docs/security.md` that covers the existing patterns. I want this done per those documents — not guessed at."

**Intake capture:** `legal/session-tokens.md` and `docs/security.md` recorded verbatim as candidate references.

**Analyze (silent):** Core intent is compliance-driven middleware refactor. Reference sources are both named explicitly — no vague gestures to flag. Gaps: scope boundary (middleware only vs. downstream handlers), definition of done, which sections of each reference are load-bearing.

**Clarify — Round 1:** Confirm scope ("middleware only, or downstream handlers too?") and definition of done ("compliance review, existing tests, both?"). Skip reference-path questions because the user already named specific files.

**Clarify — Round 2:** Because references are specific, ask what to take from each: "From `legal/session-tokens.md`, which sections are load-bearing — storage rules only, or also expiry/rotation?" and "From `docs/security.md`, is there a specific middleware pattern the refactor should conform to?"

**Synthesize (Statement of Intent):**
- Intent names the two reference files inline
- Key Concerns ranked with compliance first
- Success Criteria includes "storage mechanism matches `legal/session-tokens.md` §{specific sections}" — paths not paraphrases
- **References** section lists both files with a note on what to take from each
- **Execution Directives** block carries the standard imperatives: read references first, investigate existing middleware, plan from what you find, implement every success criterion, stop on gaps

**Approve:** User selects "Approve — this captures it."

**Deliver:**
```
Spec saved: .workflow.local/sharpen/auth-middleware-refactor-spec.md
Next: /iter .workflow.local/sharpen/auth-middleware-refactor-spec.md
```

Literal copy-pasteable command. The next session reads the spec cold and is directed by the Execution Directives block to consult both reference files before planning — no built-in auth/session assumptions.

## References

| File | When to Read |
|------|-------------|
| [output-formats.md](references/output-formats.md) | During Synthesize and Deliver — spec formats and handoff template |
