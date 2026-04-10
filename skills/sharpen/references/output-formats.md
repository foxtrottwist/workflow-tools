# Output Formats

Section requirements for the two spec formats and the handoff. Compose the document structure yourself — these are completeness checks, not fill-in-the-blank scaffolding.

A sharpen spec is an **executable contract**, not a summary. The downstream reader (a fresh session or subagent) is expected to read it end-to-end and follow it literally: read every cited reference, investigate the relevant code, plan from what is found, and implement every success criterion. The spec formats below enforce that contract.

## Statement of Intent

Dense, single-page contract. Default for most inputs.

**Required sections:** Intent (1-2 sentences: what and why), Scope (primary deliverable, secondary concerns if any, explicit exclusions if identified), Key Concerns (ranked, each with brief rationale), Success Criteria (measurable or observable outcomes), References, Execution Directives.

**Optional section:** Constraints (technical, timeline, quality boundaries) — omit if none were identified during clarification.

Every sentence carries information. If a section would be empty or speculative, cut it — except References and Execution Directives, which are required even when short.

## Lightweight Spec

Extended contract for complex or multi-phase work.

**Required sections:** Problem Statement (what problem exists, why it matters — 2-3 sentences), Proposed Approach (high-level strategy), Requirements (MoSCoW: must-have, should-have, won't-include), Key Concerns (tabular: concern, impact level, notes), Success Criteria (checkboxes, measurable), References, Execution Directives.

**Optional sections:** Constraints (each with rationale), Open Questions (unresolved items from clarification — only include if genuinely unresolved, not as a hedge).

The spec must be self-contained. A reader with no context from this conversation must understand the full picture *and* must not fall back on built-in assumptions where the spec cites a specific reference.

## References (required)

Enumerate every document, guide, file, URL, or code path the reader must consult before acting. Each entry is specific — a path, a URL, or a file name with a section anchor — never a vague gesture like "existing auth code" or "the style guide."

Requirements:
- At least one entry when the user mentioned, linked, or implied any external source during intake or clarification. An empty References section is a signal that sharpen failed to surface the right material — go back to Clarify.
- Each entry names what the reader should take from it (e.g., "read §3 Principles 1, 4, 8" or "preserve the existing error-handling pattern").
- Order by importance. The most load-bearing reference first.

## Execution Directives (required)

A short imperative block the spec carries to the downstream reader. State these directives literally — they are not suggestions:

- Read every entry in **References** before planning or acting. Do not substitute built-in knowledge where a cited source exists.
- Investigate the relevant code or material before drafting a plan. Read existing files, understand patterns in use, note constraints that are not in the spec.
- Plan from what you find. If the spec and the code disagree, surface the conflict — do not silently pick a side.
- Implement every entry in **Success Criteria**. Partial completion is not completion.
- If a reference is missing, ambiguous, or unreachable, stop and report it. Do not improvise around a gap in the spec.

Keep this section short and imperative. The directives are the same every time; the value is that they travel with the spec across the context boundary.

## Handoff

After saving the spec to disk, present the file path and a literal, copy-pasteable next command. Not just a skill name — the actual invocation the user can paste into the terminal.

Required form:

```
Spec saved: {absolute or workspace-relative path}
Next: {literal slash command with the spec path as argument}
```

Select the next skill from the spec's domain:
- Implementation or research → `/iter {path}`
- Prompt templates → `/prompt-dev {path}`
- Written content → `/write {path}`
- Other → name the skill explicitly

The handoff is deliberate, not automatic. The user runs the command themselves — no auto-dispatch, no pipeline glue — so that every downstream invocation is a conscious choice.
