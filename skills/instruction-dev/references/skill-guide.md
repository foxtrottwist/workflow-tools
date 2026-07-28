# Skill Authoring Guide

## Examples Belong in the Skill, Not the Interface

Anthropic's "examples to interface design" guidance is about tool and API interfaces — an MCP tool or CLI whose shape makes correct use obvious doesn't need a prompt full of usage examples to compensate. That's a different layer than skill authoring. Inside a skill body, a worked example is still required (P3, checklist #7) — the shift doesn't license cutting it. If a skill wraps a tool, spend the effort on the tool's interface first; keep the skill's worked example either way.

## The Shortcut Anti-Pattern

Rich output templates give Claude enough scaffolding to respond without following the full workflow. Templates become shortcuts that bypass the procedure (P3).

**Before (shortcut-enabling):**
```
**Output format:**
## [Brief Title]
**TL;DR:** [One sentence — what you did and the outcome]
### Situation
[Context — what was happening...]
### Action
[What YOU did — be specific...]
### Result
[Outcome — quantify if possible...]
```

**After (procedure-enforcing):**
> STAR format — Situation/Task/Action/Result. TL;DR one sentence. Resume bullet ≤30 words, action verb + quantified result.

Constraint lines tell Claude what must be true without giving it fill-in-the-blank scaffolding.

## Description (Frontmatter) Template

```yaml
---
name: {skill-name}
description: "{One sentence: what + domain}. Use when {3–5 use cases}.
  Triggers on: '{exact phrase 1}', '{exact phrase 2}', '{exact phrase 3}'.
  {Technical keywords for secondary matching}."
---
```

**Good (76 words, high activation):**
```yaml
description: "Speak text aloud or check TTS status via SpokenBite's local REST API.
  Use when the user asks to read something aloud, say something, speak text,
  announce results, give a verbal status update, check if SpokenBite is running.
  Triggers on: 'read this aloud', 'say this', 'speak', 'tell me', 'announce',
  'voice status', 'is SpokenBite running'."
```

**Bad (too sparse, undertriggers):**
```yaml
description: "TTS via SpokenBite REST API. Triggers: speak, say, read aloud."
```

**Bad (behavioral content in description — wastes tokens in every conversation):**
```yaml
description: "...Always check /v1/status before speaking. Never override the voice
  parameter unless the user asks..."
```

Behavioral content belongs in the body, not the description (P8).

## Body Template

```markdown
# {Skill Name}

{One sentence scope — what this skill does.}

## {Core Procedure Section}

{Numbered steps or clear subsections. Each step is an action with specific
tool/command/API call. No background theory.}

## Worked Example

{Complete input → action → output sequence showing the procedure applied
to a realistic case.}

## Constraints

- Never {X}.
- Always {Y} before {Z}.
- {Boundary condition or safety rule.}
```

## Review Checklist

| # | Question | If Yes | Principle |
|---|----------|--------|-----------|
| 1 | Is the main skill body >200 lines? | Split into focused modules with reference files | P3 |
| 2 | Does the body contain output format templates with `[placeholder]` syntax? | Replace with 1–2 constraint lines | P3 |
| 3 | Does the body contain a "When to Use" section? | Remove — the description field handles routing | P8 |
| 4 | Does the description contain behavioral instructions? | Move them to the body | P8 |
| 5 | Does the description include quoted trigger phrases? | If not, add them — activation improves from 50% to 90% | P8 |
| 6 | Does the skill teach generic knowledge the model already has? | Cut or compress to behavioral constraints only | P5 |
| 7 | Does the skill include a worked example? | If not, add one — most commonly missing element | P3 |
| 8 | Does the skill include a verification mechanism? | If not, consider adding one — tests, lint, build check | P4 |
| 9 | Are there sections that restate other skills? | Deduplicate — keep one authoritative copy | Cost |
| 10 | Is there a "Notes", "Resources", or "Quick Reference" tail section? | Likely low-value — cut unless unique content | Cost |

## Splitting an Oversized Skill

1. **Identify natural boundaries.** Sections serving different audiences or use cases: core API vs. advanced, essential vs. extended, implementation vs. migration.
2. **Create the main skill.** Keep decision trees, routing logic, most-used procedures. Target <200 lines.
3. **Move detailed content to reference files.** Create `references/` directory. Each file covers one focused topic.
4. **Update the main skill to load references.** Reference files by name when the relevant branch is taken — don't load all unconditionally.
5. **Remove "When to Use" sections** from the body. The description handles routing (P8).
6. **Verify description still routes correctly.** Test activation with 3–5 representative prompts.

## Writing a New Skill from Scratch

1. **Check if it's needed.** Generic software engineering gains only +4.5pp (SkillsBench). Domain-specific or post-cutoff knowledge is where skills add real value (P5).
2. **Write the description first.** One sentence + "Use when" + quoted triggers + keywords.
3. **Write the body.** Scope → procedure → worked example → constraints.
4. **Verify the worked example is complete.** Realistic request, exact actions, expected output.
5. **Check for templates.** Any `[placeholder]` output templates → replace with constraint lines (P3).
6. **Check line count.** >200 lines → split into main + references.
7. **Test activation.** 3–5 natural-language prompts. <80% activation → add more trigger phrases to description.

**For plugin-bundled skills:** hand off to the `skill-creator` skill for scaffolding, file creation, and plugin registration (build.sh SKILLS array, version bump).
