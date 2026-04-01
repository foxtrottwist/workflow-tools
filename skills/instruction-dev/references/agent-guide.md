# Agent Definition Guide

## Template

```markdown
# {Agent Name}

{One sentence: what this agent does and its access level (read-only, write, etc.)}

## Operating Principles

{3–5 behavioral constraints. Phrased as imperatives.}

## Output

{What the agent returns. Format specification if structured.}

## Constraints

- {What this agent must NOT do.}
- {Scope boundary.}
```

Agents provide behavioral constraints (how to operate). Skills provide domain knowledge (what to do). Keep them separate.

## Review Checklist

| # | Question | If Yes | Principle |
|---|----------|--------|-----------|
| 1 | Is it >100 lines? | Compress — agents should be behavioral constraints, not methodology | P1 |
| 2 | Does it describe a methodology the model already knows? | Replace with behavioral constraints | P5 |
| 3 | Does it clearly state what the agent must NOT do? | If not, add scope boundaries | P1 |
| 4 | Does it duplicate content from a skill or another agent? | Keep one authoritative copy | Cost |

## Token Cost Tiers

| Tier | Size | Token Impact | Action |
|---|---|---|---|
| Compact | <100 lines | Low | Likely fine |
| Medium | 100–200 lines | Moderate | Review for cuts |
| Large | 200–400 lines | High | Active compression needed |
| Oversized | >400 lines | Very high | Must split into modules |

For plugins with multiple skills, oversized files (>400 lines) typically account for more token cost than all other skills combined. Splitting these is the single highest-impact improvement.
