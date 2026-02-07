---
name: prompt-dev
description: Create and refine prompt templates following Claude 4 conventions. Use when asked to build a new prompt template, improve an existing prompt, debug why a prompt isn't working, or develop reusable prompts for specific tasks. Triggers on "create a prompt", "build a template", "fix this prompt", "prompt isn't working", or requests to make prompts for specific use cases.
---

# Prompt Development

Iterative prompt template creation using the DISCOVER → DRAFT → TEST → REFINE → VALIDATE workflow. State persists in files for resumption.

## Resume Check

Every invocation, check for existing state in `.prompt-dev.local/`.

**If state exists**, read `state.json` and present status. Offer to resume, start fresh, or show current template.

**If no state**, proceed to Discover.

## Phase 1: Discover

Infer requirements from the request context:
- **Task type**: What the prompt handles (generation, extraction, analysis, review)
- **Input format**: What users will provide (structured data, freeform text, files)
- **Output format**: Expected deliverable (structured, freeform, artifact)
- **Constraints**: Style guides, tone requirements, system integrations

Use **AskUserQuestion** only for genuine gaps the request doesn't clarify.

**Output:**
- Create `.prompt-dev.local/{template-slug}/`
- Write `brief.md` with requirements
- Write `state.json`: `{ "phase": "draft" }`

## Phase 2: Draft

Create minimal viable template following [references/conventions.md](references/conventions.md) for structure and [references/examples.md](references/examples.md) for patterns.

**Output:**
- Write `template.md` with draft
- Create empty `test-log.md`
- Create empty `guardrails.md`
- Update `state.json`: `{ "phase": "test" }`
- Present template for user review

## Phase 3: Test

This phase requires user collaboration. The template must be tested with real or representative cases.

**Per test case:**
1. User provides test input
2. Run template against input
3. Evaluate output against success criteria
4. Log result in `test-log.md`:

```markdown
## Test {N} - {timestamp}
**Input:** {description}
**Expected:** {what should happen}
**Actual:** {what happened}
**Status:** PASS | FAIL | PARTIAL
**Notes:** {observations}
```

**Exit criteria:**
- Minimum 2-3 test cases run
- At least one edge case tested
- Failure patterns identified (if any)

Update `state.json`: `{ "phase": "refine" }`

## Phase 4: Refine

Analyze test-log.md for failure patterns. For each failure:

1. Identify root cause (unclear constraint, missing context, wrong output format)
2. Add to `guardrails.md`:
```markdown
## {Pattern Name}
- **Symptom:** {what went wrong}
- **Cause:** {why it happened}
- **Fix:** {constraint or change added}
- **Learned:** Test {N}
```
3. Update template.md with fixes
4. Return to Test phase if significant changes made

**Exit criteria:**
- All identified issues addressed
- No new failures in re-tests
- Guardrails documented

Update `state.json`: `{ "phase": "validate" }`

## Phase 5: Validate

Final check against quality checklist:

- [ ] Task context clearly defined
- [ ] Constraints specific and actionable
- [ ] Input structure uses XML when appropriate
- [ ] Output format appropriate for usage context
- [ ] No unnecessary process instructions
- [ ] Success criteria measurable
- [ ] No prohibited terms (see conventions.md)
- [ ] Tested with real cases

**If all pass:**
- Present final template
- Archive to `.prompt-dev.local/archive/{slug}/` if requested
- Update `state.json`: `{ "phase": "complete" }`

**If issues found:**
- Return to appropriate phase

## State Files

```
.prompt-dev.local/{template-slug}/
├── state.json      # Current phase
├── brief.md        # Requirements from discovery
├── template.md     # Current template version
├── test-log.md     # Test cases and results
└── guardrails.md   # Patterns that didn't work
```

## Quick Reference

| Command | Action |
|---------|--------|
| `/prompt-dev {description}` | Start new template |
| `/prompt-dev resume` | Continue from last phase |
| `/prompt-dev status` | Show current state |
