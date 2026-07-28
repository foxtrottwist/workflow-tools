# `.claude/rules/` Authoring Guide

## When to Use a Rule Instead of CLAUDE.md or a Skill

- **Belongs in CLAUDE.md** if every session needs it regardless of what's touched (build commands, hard project-wide constraints).
- **Belongs in a rule** if it only matters when Claude is working with specific files or a specific subdirectory — a convention for `hooks/**`, a security requirement for `src/api/**`, a packaging step tied to `.claude-plugin/*.json`.
- **Belongs in a skill** if it's a multi-step procedure the user or Claude invokes on demand, not a standing constraint that should silently apply whenever matching files are opened.

A rule without `paths` frontmatter loads unconditionally, same priority as CLAUDE.md — that's just a way to split a large CLAUDE.md by topic, not a different mechanism. The path-scoping is what makes rules distinct: it's how you keep a constraint out of context until it's relevant.

## Template

```markdown
---
paths:
  - "src/api/**/*.ts"
---

# {Topic}

- {Imperative constraint that only applies to matching files.}
- {Another, if genuinely related to the same topic.}
```

Omit the `paths` block entirely for a rule that should always load — but prefer scoping whenever the content has a natural file boundary; that's the whole point of the mechanism.

## Good Example

```markdown
---
paths:
  - "hooks/**"
---

# Hook Scripts

- Skip subagents via an `agent_id` guard at the top of the script.
- Fail open: end every script with `|| exit 0` so a hook bug never blocks the user's action.
```

This never enters context while Claude is editing skills or docs — only when a hook script is actually open.

## Review Checklist

| # | Question | If Yes | Principle |
|---|----------|--------|-----------|
| 1 | Does this apply to every session regardless of file touched? | Move to CLAUDE.md instead | — |
| 2 | Is this a multi-step procedure invoked on demand rather than a standing constraint? | Move to a skill instead | — |
| 3 | Could `paths` be added but was omitted? | Add it — unscoped rules cost context every session | Cost |
| 4 | Does the file mix unrelated concerns (e.g. security + code style)? | Split into separate rule files, one topic each | P3 |
| 5 | Is this discoverable from the code the pattern already matches? | Remove it | P1 |
| 6 | Is it phrased as an absolute rule where a judgement call would transfer better? | Rephrase per P9 | P9 |

## Splitting an Oversized CLAUDE.md

1. Read every line. For each, ask: does this apply no matter what file is open?
2. If yes, it stays in CLAUDE.md.
3. If no, identify the path pattern that scopes it and move it to `.claude/rules/{topic}.md` with that pattern in `paths`.
4. Leave a one-line pointer in CLAUDE.md so the rule is discoverable by a human reading the file (e.g. "See `.claude/rules/hooks.md` for hook conventions").
