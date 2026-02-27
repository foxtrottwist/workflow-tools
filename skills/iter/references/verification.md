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
│         VERIFICATION AGENT — Stage 1: Spec Compliance       │
│  Requirements met? Nothing missing? Nothing extra?          │
├─────────────────────────────────────────────────────────────┤
│         VERIFICATION AGENT — Stage 2: Code Quality          │
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

### Layer 4: Verification Agent (Two-Stage Review)

**What it is:** Dedicated agent with adversarial mindset, split into two sequential stages. Stage 1 must pass before Stage 2 runs.

#### Stage 1: Spec Compliance (always first)

Verify implementation matches requirements — nothing more, nothing less.

**Task tool dispatch:**
```
Task tool call:
- subagent_type: "general-purpose"
- model: sonnet
- prompt: |
    Review {task/phase} "{title}" for spec compliance.
    Files/Output: {paths}
    Criteria: {acceptance criteria}

    Check ONLY:
    - Are all acceptance criteria met?
    - Any requirements missing?
    - Any unrequested additions?

    Output: SPEC_PASS or SPEC_GAPS with specific issues.
```

If `SPEC_GAPS`: fix gaps → re-check spec compliance (loop until `SPEC_PASS`, max 3 cycles).

#### Stage 2: Code Quality (only after SPEC_PASS)

Review implementation quality, edge cases, and design.

**Task tool dispatch:**
```
Task tool call:
- subagent_type: "general-purpose"
- model: sonnet
- prompt: |
    Review {task/phase} "{title}" for code quality.
    Files/Output: {paths}

    Check:
    - Edge cases and error handling (dev)
    - Design and architecture
    - Test coverage and quality
    - Performance concerns
    - Shallow analysis or missing perspectives (knowledge)

    Output: VERIFIED or GAPS_FOUND with specific issues.
```

**Output:** `VERIFIED` or `GAPS_FOUND` with specific issues.

**Why two stages:** Spec compliance is objective — did you build what was asked? Code quality is subjective — is it well-built? Mixing them causes reviewers to flag style issues while missing missing requirements. Spec first ensures completeness before quality polish.

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
├── Verification Agent — Stage 1: Spec Compliance
│   ├── SPEC_PASS → Proceed to Stage 2
│   └── SPEC_GAPS → Fix → Re-check spec (max 3 cycles)
│
├── Verification Agent — Stage 2: Code Quality
│   ├── VERIFIED → Unit complete
│   └── GAPS_FOUND → Fix → Re-verify (max 3 cycles)
│
└── Unit Complete

After all units:
├── Task Review (cross-unit integration)
└── Human Review (final approval)
```

## Weight-Based Verification

Check the task's `weight` field before dispatching verification layers. Weight is assigned during decomposition (see development.md).

| Weight | Verification Path |
|--------|-------------------|
| **light** | Work pass → programmatic gates → unit complete. Skip confirmation pass and verification agent. |
| **standard** | Full hierarchy: work pass → programmatic gates → confirmation → post-confirmation gate → verification agent (both stages). |
| **heavy** | Full hierarchy with 2x max_turns on work pass and verification agent. Same layers as standard, more room to iterate. |

Light tasks are mechanical — file renames, config changes, dependency bumps. The programmatic gates (build, lint, test) catch regressions. Confirmation and verification add cost without catching meaningful issues on mechanical work.

Standard and heavy tasks involve logic changes where agent overconfidence and subtle gaps matter. The full hierarchy earns its keep.

## When to Skip Layers

| Layer | Skippable? | Rationale |
|-------|------------|-----------|
| Programmatic (dev) | No | Fast, objective, no reason to skip |
| Confirmation (N+1) | Light tasks only | Core mechanism, but mechanical changes don't benefit |
| Verification Stage 1 (Spec) | Light tasks only | Spec compliance matters less for renames and config |
| Verification Stage 2 (Quality) | Light tasks only | Skip for mechanical work |
| Task Review | No | Catches cross-unit issues |
| Human Review | No | Final authority |

## Recovery Patterns

Every automated recovery path has a retry cap and a human escalation fallback. The orchestrator never loops indefinitely.

### Programmatic Gate Failure

Re-dispatch the work pass with the `gate-result.local.json` contents appended to the original prompt as a `<gate_failure>` block. The subagent receives the original task spec plus the specific build/lint/test failures.

- **Max retries**: 2
- **Escalation**: If the gate fails after 2 retries, escalate to a human-verify checkpoint with the failure details. Include the `gate-result.local.json` output so the user sees exactly what's breaking.

### Confirmation Pass Disagreement

When the confirmation agent's assessment contradicts the work pass output — it finds gaps and makes changes that alter the work pass result — dispatch a tiebreaker pass.

The tiebreaker agent receives:
1. The original task spec
2. The work pass output summary
3. The confirmation agent's objections or changes

The tiebreaker decides which is correct and either approves or returns the task to the work pass with consolidated feedback.

- **Max tiebreakers**: 1
- **Escalation**: If unresolved after the tiebreaker, escalate to a human-verify checkpoint with all three perspectives (work pass, confirmation, tiebreaker).

### Verification Agent Rejection

Return the task to the work pass with the verification findings formatted as additional requirements in a `<verification_findings>` block. The work pass agent treats these as mandatory fixes.

After the rework, the task re-enters the verification hierarchy from the programmatic gates step — not from the verification agent. It must pass all layers again.

- **Max rejection cycles**: 1
- **Escalation**: If the verification agent rejects a second time, escalate to a human-verify checkpoint with the verification findings and the rework attempt.

### Recovery Summary

| Failure Type | Action | Max Retries | Escalation |
|-------------|--------|-------------|------------|
| Gate failure | Re-dispatch work pass with `<gate_failure>` block | 2 | human-verify with gate output |
| Confirmation disagreement | Tiebreaker pass with all context | 1 | human-verify with three perspectives |
| Verification rejection | Rework with `<verification_findings>` block, re-enter from gates | 1 | human-verify with findings + rework |

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
| Verification Stage 1 | Spec compliance | Missing requirements, unrequested additions |
| Verification Stage 2 | Quality/code review | Shallow work, edge cases, quality issues |
| Task Review | Integration check | Cross-unit issues, coherence |
| Human Review | Final authority | Judgment calls, quality assessment |

**Key distinction:**
- **Confirmation** = "Do this task" (agent tries to complete, finds nothing to do)
- **Verification** = "Review this work" (agent explicitly critiques completed work)

Both are necessary. Confirmation catches work that isn't done. Verification catches work that's done but flawed.
