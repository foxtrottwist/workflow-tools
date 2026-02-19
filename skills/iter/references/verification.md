# Verification Hierarchy

Defense-in-depth strategy for validating work. Each layer catches different failure modes.

## The Problem

Agents are fallible. Even well-scoped tasks/phases can fail in subtle ways:
- Confirmation bias (agent thinks their work is correct)
- Shallow completion (meets letter of criteria, not intent)
- Missing edge cases/nuances
- Quality gaps (works but lacks depth or rigor)

## Verification Layers

```
┌─────────────────────────────────────────────────────────────┐
│                     HUMAN REVIEW                            │
│  Final authority. Judgment calls. Quality assessment.       │
├─────────────────────────────────────────────────────────────┤
│                   TASK REVIEW                               │
│  Cross-unit integration. Coherence. Completeness.           │
├─────────────────────────────────────────────────────────────┤
│              VERIFICATION AGENT (Quality/Code Review)       │
│  Adversarial scrutiny. Depth check. Gap analysis.           │
├─────────────────────────────────────────────────────────────┤
│            MANDATORY CONFIRMATION PASS (N+1)                │
│  Fresh agent attempts the SAME task. Independent agreement. │
├─────────────────────────────────────────────────────────────┤
│               PROGRAMMATIC CHECKS (Dev Only)                │
│  Tests. Linting. Type checking. Build verification.         │
├─────────────────────────────────────────────────────────────┤
│              WORK PASS (1...N)                              │
│  Initial work. Agent iterates until it believes done.       │
└─────────────────────────────────────────────────────────────┘
```

## The Key Insight: Work Consensus

The mandatory N+1 pass is **NOT** a verification step. It is another **work attempt**.

- Same prompt as the original dispatch
- Fresh agent with no memory of doing the work
- Reads criteria, examines outputs/code, decides what needs doing
- If work is truly complete, agent finds nothing to do and declares DONE
- If gaps exist, agent naturally finds and fills them

This creates **work consensus**: two independent agents, both given the same mandate, both concluding the work is complete.

## Layer Details

### Layer 1: Work Pass

**What it is:** Agent works on the task/phase until it believes criteria are met.

**Implementation:** Dispatch via Task tool with `max_turns` set from the task spec.

**Failure mode:** Agent is overconfident, stops too early, or misunderstands criteria.

---

### Layer 2: Programmatic Checks (Development Only)

**What it is:** Automated, objective verification.

Run via `scripts/verify-gate.sh <task-dir> <language>`. Writes `gate-result.local.json` to the task directory with per-check pass/fail results. Exit 0 = all passed; exit 1 = failures.

| Check | Purpose | Example |
|-------|---------|---------|
| Build | Code compiles | `swift build`, `tsc`, `cargo check` |
| Types | Type safety | `tsc --noEmit`, `mypy` |
| Lint | Style/patterns | `swiftlint`, `eslint`, `ruff` |
| Tests | Behavior | `swift test`, `npm test`, `cargo test` |

**Output:** Pass/fail for each check. All must pass to proceed.

---

### Layer 3: Mandatory Confirmation Pass (N+1)

**What it is:** Another work attempt with the **exact same prompt** as the original dispatch.

The confirmation agent doesn't know it's a "confirmation pass." It receives the same instruction the original agent received.

**Task tool dispatch:**
```
Task tool call:
- subagent_type: "general-purpose"
- model: {same as work pass}
- max_turns: 3
- prompt: {same prompt as original dispatch}
```

**What it catches:**
- Incomplete work
- Gaps the first agent missed
- Criteria misunderstandings

**When to require:** Always. Every task/phase gets N+1 regardless of complexity.

**Why this works:** Two independent agents, same mandate, both concluding done = consensus.

---

### Post-Confirmation Programmatic Gate (Development Only)

After the confirmation pass declares DONE, run `scripts/verify-gate.sh` again before proceeding to the Verification Agent. The confirmation agent may have modified code to fill gaps — this gate ensures those changes haven't broken what previously passed.

```bash
scripts/verify-gate.sh <task-dir> <language>
```

If this gate fails, treat it as a failed confirmation: the confirmation agent's changes introduced regressions. Send the failing check output back to an implementation agent and re-run confirmation.

---

### Layer 4: Verification Agent

**What it is:** Dedicated agent with adversarial mindset.

**Task tool dispatch:**
```
Task tool call:
- subagent_type: "general-purpose"
- model: sonnet
- prompt: |
    Review {task/phase} "{title}" with adversarial mindset.
    Files/Output: {paths}
    Criteria: {acceptance criteria}

    Check for:
    - Incomplete work, stubs, TODOs
    - Edge cases and error handling (dev)
    - Shallow analysis or missing perspectives (knowledge)
    - Quality gaps

    Output: VERIFIED or GAPS_FOUND with specific issues.
```

**Output:** `VERIFIED` or `GAPS_FOUND` with specific issues.

### Stub Detection

Verification must check work is **substantive**, not placeholder. Four verification levels:

| Level | Check | Catches |
|-------|-------|---------|
| Exists | File present at expected path | Missing files |
| Substantive | Real implementation, not placeholder | Stubs, TODOs |
| Wired | Connected to rest of system | Orphaned code |
| Functional | Actually works when invoked | Integration bugs |

**Universal stub patterns (grep for these):**
- Comment stubs: `TODO`, `FIXME`, `PLACEHOLDER`, `implement later`
- Empty returns: `return null`, `return {}`, `return []`
- Log-only functions: `console.log(...); return`
- Placeholder text: `lorem ipsum`, `coming soon`, `example data`

**Wiring verification (where 80% of stubs hide):**
- Does component actually call API and use response?
- Does API route actually query database and return result?
- Does form handler actually submit data?
- Is state actually rendered, not hardcoded?

---

### Layer 5: Task Review

**What it is:** Cross-unit verification after all tasks/phases complete.

**Purpose:** Ensure units work together coherently.

**What it catches:**
- Inconsistencies between units
- Missing connections
- Gaps that span units

---

### Layer 6: Human Review

**What it is:** Final human approval.

**Purpose:** Ultimate authority on quality and correctness.

## Task/Phase Lifecycle with All Layers

```
Task/Phase Start
│
├── Work Pass (Task tool dispatch, max_turns from spec)
│   └── Agent declares DONE
│
├── Programmatic Gate (dev only: build, lint, tests)
│
├── Mandatory Confirmation Pass (Task tool, same prompt, max_turns: 3)
│   ├── Finds work? → Does it → Another confirmation
│   └── Finds nothing? → Work consensus achieved
│
├── Programmatic Gate (dev, again — ensure confirmation didn't break anything)
│
├── Verification Agent (Task tool, adversarial review)
│   ├── VERIFIED → Unit complete
│   └── GAPS_FOUND → Fix → Re-verify (max 3 cycles)
│
└── Unit Complete

After all units:
├── Task Review (cross-unit integration)
└── Human Review (final approval)
```

## When to Skip Layers

| Layer | Skippable? | Rationale |
|-------|------------|-----------|
| Programmatic (dev) | No | Fast, objective, no reason to skip |
| Confirmation (N+1) | No | Core mechanism for catching overconfidence |
| Verification | Rarely | Skip only for trivial tasks |
| Task Review | No | Catches cross-unit issues |
| Human Review | No | Final authority |

## Gap Severity Guide

| Severity | Definition | Action |
|----------|------------|--------|
| Critical | Broken functionality, missing major requirement, factual errors | Must fix before proceeding |
| Major | Missing requirement, shallow analysis, unhandled error path | Must fix before proceeding |
| Minor | Style issue, optimization opportunity, minor clarification | Fix in review phase or skip |

## Max Verification Cycles

Prevent infinite verify-fix loops:
- Default: 3 verification attempts per task/phase
- If still failing after 3, escalate to user
- User can: simplify criteria, intervene manually, or accept with known gaps

## Checkpoint Types

When human interaction is needed, categorize by type to minimize unnecessary pauses:

| Type | Frequency | Use |
|------|-----------|-----|
| human-verify | ~90% | Claude automated, human confirms result |
| decision | ~9% | User chooses between approaches |
| human-action | ~1% | Truly unavoidable manual step |

**Principle:** If Claude can run it, Claude runs it. Always automate first.

### human-verify checkpoint

Most common. Claude completes the work, human confirms visual/functional correctness.

```
**Completed:** {what Claude built/automated}
**To verify:**
1. {specific step with URL/command}
2. {expected outcome}

Reply "approved" or describe issues.
```

### decision checkpoint

User makes architectural or design choices. Present options with context.

```
**Decision needed:** {what's being decided}
**Context:** {why this matters}

Options:
A. {option} - {pros} / {cons}
B. {option} - {pros} / {cons}

Reply with your choice.
```

### human-action checkpoint

Rare. Only for actions Claude cannot perform (external account auth, physical access, etc.).

```
**Manual step needed:** {what action}
**Why Claude can't:** {explanation of limitation}
**After completing:** {how to signal ready to continue}
```

## Summary

| Layer | Purpose | Catches |
|-------|---------|---------|
| Work Pass | Do the work | -- |
| Programmatic (dev) | Objective checks | Syntax, types, regressions |
| **Confirmation (N+1)** | **Independent agreement** | **Incomplete work, misunderstood criteria** |
| Verification | Quality/code review | Shallow work, gaps, quality issues |
| Task Review | Integration check | Cross-unit issues, coherence |
| Human Review | Final authority | Judgment calls, quality assessment |

**Key distinction:**
- **Confirmation** = "Do this task" (agent tries to complete, finds nothing to do)
- **Verification** = "Review this work" (agent explicitly critiques completed work)

Both are necessary. Confirmation catches work that isn't done. Verification catches work that's done but flawed.
