# Output Formats

Section requirements for the two spec formats and the handoff. Compose the document structure yourself — these are completeness checks, not fill-in-the-blank scaffolding.

## Statement of Intent

Dense, single-page summary. Default for most inputs.

**Required sections:** Intent (1-2 sentences: what and why), Scope (primary deliverable, secondary concerns if any, explicit exclusions if identified), Key Concerns (ranked, each with brief rationale), Success Criteria (measurable or observable outcomes).

**Optional section:** Constraints (technical, timeline, quality boundaries) — omit if none were identified during clarification.

Every sentence carries information. If a section would be empty or speculative, cut it.

## Lightweight Spec

Extended format for complex or multi-phase work.

**Required sections:** Problem Statement (what problem exists, why it matters — 2-3 sentences), Proposed Approach (high-level strategy), Requirements (MoSCoW: must-have, should-have, won't-include), Key Concerns (tabular: concern, impact level, notes), Success Criteria (checkboxes, measurable).

**Optional sections:** Constraints (each with rationale), Open Questions (unresolved items from clarification — only include if genuinely unresolved, not as a hedge).

The spec must be self-contained. A reader with no context from this conversation should understand the full picture.

## Handoff

After saving the spec to disk, present the file path and the suggested next step. Adapt the suggested skill to the spec's domain: `/iter` for implementation or research, `/prompt-dev` for prompt templates, `/write` for written content. The handoff should name the specific file path and the specific skill invocation.

In Claude Code with plan mode, the handoff instructions go in the `## Post-Approval` section of the plan file (see step 6 in SKILL.md). After context clear, this section tells Claude what to do.

Without plan mode, present the handoff directly after saving the file.
