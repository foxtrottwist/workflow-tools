# Output Formats

Templates for the three delivery modes. Select based on user preference at the DELIVER phase.

## Statement of Intent

Dense, actionable summary. Use when the output feeds directly into a prompt or skill invocation.

```markdown
## Intent

{1-2 sentence core objective — what and why}

## Scope

- **Primary:** {main deliverable or outcome}
- **Secondary:** {supporting concerns, if any}
- **Out of scope:** {explicit exclusions, if identified}

## Key Concerns

1. {Concern with brief rationale}
2. {Concern with brief rationale}
3. {Concern with brief rationale}

## Constraints

{Technical, timeline, quality, or other boundaries — omit section if none}

## Success Criteria

- {Measurable or observable outcome}
- {Measurable or observable outcome}
```

## Lightweight Spec

Extended format for complex or multi-phase work. Use when the output will be saved to disk for future reference or handed to iter/plan mode.

```markdown
# {Project/Task Title}

## Problem Statement

{What problem exists and why it matters — 2-3 sentences}

## Proposed Approach

{High-level strategy — what will be built/done and how}

## Requirements

### Must Have
- {Requirement}

### Should Have
- {Requirement}

### Won't Include
- {Explicit exclusion}

## Key Concerns

| # | Concern | Impact | Notes |
|---|---------|--------|-------|
| 1 | {Concern} | {high/medium/low} | {Context} |

## Constraints

- {Constraint with rationale}

## Success Criteria

- [ ] {Measurable outcome}
- [ ] {Measurable outcome}

## Open Questions

- {Unresolved item, if any}
```

## Workflow Invocation

Format for handing off to a specific skill. Match the target skill's expected input patterns.

### iter handoff
```
/iter {refined statement of intent — 1-2 sentences covering what to build/research and the key constraints}
```

### writing handoff
```
/writing {content type}: {purpose and audience} — {key points to cover}
```

### prompt-dev handoff
```
/prompt-dev {what the prompt should do} — {target audience/use case, constraints, success criteria}
```

### General prompt
```
{Refined request — clear objective, key constraints, expected output format}
```
