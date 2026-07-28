---
name: code-audit
description: "Use when documentation may be out of sync with code. Triggers on \"audit the codebase\", \"verify documentation\", \"check docs match code\", \"review codebase\", \"documentation health\", \"doc drift\", \"stale documentation\", or requests to validate code/doc alignment."
---

# Code Audit

Verify documentation accuracy against code using parallel subagents with state persistence and verification gates.

## Workflow

```
RESUME?  →  SCOPE  →  PARTITION  →  REVIEW  →  VERIFY  →  PROPOSE
(check      (what to   (spawn       (parallel  (confirm   (present
 state)     audit)     subagents)   review)    findings)  actions)
```

## Phase 0: Resume Check

Every invocation, check for existing state in `.workflow.local/code-audit/`.

**If state exists**, read `state.json` and present:
```
Found audit of "{project}" at {phase}:
- Reviewed: src/, lib/
- Pending: tests/, docs/
- Findings: 3 critical, 5 warnings

Resume, start fresh, or view findings?
```

**If no state**, proceed to Scope.

## Phase 1: Scope

Infer audit type and focus from the request context:
- "audit the codebase" → Full review, all focus areas
- "check docs in src/auth" → Module audit, documentation accuracy
- "quick sync" → Quick sync (smoke test)
- "explore the payment feature" → Feature exploration

Use **AskUserQuestion** only when scope or focus is genuinely ambiguous.

**Output:**
- Create `.workflow.local/code-audit/{project-slug}/`
- Write `brief.md` with scope
- Write `state.json`: `{ "phase": "partition" }`

## Phase 2: Partition

Divide codebase into reviewable units.

**Default: Directory-based**
1. List top-level directories (exclude build artifacts, dependencies)
2. Group small related directories
3. Target 3-6 partitions

**Feature-based** (for targeted audits):
1. Identify feature entry point
2. Trace primary dependencies
3. Create partitions: core, dependencies, consumers

**Output:**
- Write `partitions.md` listing units
- Update `state.json`: `{ "phase": "review", "pending": [...], "complete": [] }`

## Phase 3: Review (Parallel Subagents)

Spawn parallel Task agents for each partition using prompts from [references/subagent-prompts.md](references/subagent-prompts.md). Use haiku for quick sync agents, sonnet for deep review (advisory — native routing handles the common case).

Each subagent:
1. Reviews assigned partition only
2. Returns structured findings (see [references/report-format.md](references/report-format.md))
3. Notes cross-cutting concerns

**Limits:**
- 3-6 concurrent subagents
- 2-3 directory levels per agent
- Split partitions >20 files

**After completion:**
- Execute `scripts/aggregate-findings.py .workflow.local/code-audit/{project}/` to produce `findings.md` from partition outputs. Review the aggregated output for cross-cutting concerns before proceeding to verification.
- Update `state.json` with completed partitions
- Append session to `progress.md`

## Phase 4: Verify (Gates)

Before presenting findings, run verification gates.

### Gate 1: Confirmation Pass
Fresh agent reviews aggregated findings:
- Are findings consistent across partitions?
- Any contradictions or duplicates?
- Do severity levels seem accurate?

### Gate 2: Verification Agent
Adversarial review:
- Spot-check 2-3 findings against actual code
- Look for false positives
- Verify proposed fixes are correct

**If issues found:** Adjust findings, re-run affected checks.

**If gates pass:** Proceed to Propose.

## Phase 5: Propose

Present verified findings with action options:

```
## Audit Summary: {project}

**Reviewed:** {N} partitions
**Findings:** {critical} critical, {warning} warnings, {info} info

### Critical Issues
[List with locations and recommended fixes]

### Warnings
[Grouped by type]

### Recommendations
[Prioritized action list]

---

Options:
1. Address all critical issues
2. Address specific items
3. Generate remediation plan
4. Export findings and close
```

**Important:** Always get approval before modifying files.

## State Files

```
.workflow.local/code-audit/{project-slug}/
├── state.json       # Current phase, partition status
├── brief.md         # Audit scope and requirements
├── partitions.md    # Review units
├── findings.md      # Aggregated, verified findings
└── progress.md      # Session log
```

Codebase-specific lessons ("this project uses `// MARK:` for section headers, not stale comments") belong in Claude Code's auto memory, not a hand-maintained guardrails file — they're exactly the kind of per-project learning it captures automatically across sessions.

## Progress Tracking

Append after each session:

```markdown
## Session - {timestamp}
**Partitions reviewed:** src/auth/, src/api/
**Findings:** 2 critical, 3 warnings
**Notes:** {observations}
```

Enables resume and provides audit history.

## Worked Example

**Request:** "Audit the docs in src/auth for drift."

**Phase 0 (Resume):** No existing state for this project — proceed to Scope.

**Phase 1 (Scope):** "docs in src/auth" → module audit, documentation accuracy focus. Write `brief.md`.

**Phase 2 (Partition):** Feature-based — entry point `src/auth/index.ts`, trace dependencies. Partitions: core (`src/auth/`), consumers (`src/api/middleware/`, `src/routes/`).

**Phase 3 (Review):** Two subagents dispatched in parallel, one per partition, using `references/subagent-prompts.md`. Core-partition agent finds: `src/auth/session.ts`'s docstring says "tokens expire after 1 hour" but the code sets a 24-hour expiry. Consumer-partition agent finds no discrepancies. `scripts/aggregate-findings.py` merges both into `findings.md`.

**Phase 4 (Verify):** Gate 1 confirms the finding isn't a duplicate and severity (warning, not critical — stale comment, not a functional bug) is reasonable. Gate 2 spot-checks `session.ts` directly and confirms the docstring is indeed wrong.

**Phase 5 (Propose):**
```
## Audit Summary: src/auth

**Reviewed:** 2 partitions
**Findings:** 0 critical, 1 warning, 0 info

### Warnings
- src/auth/session.ts:14 — docstring claims 1-hour expiry, code sets 24 hours

Options:
1. Address all warnings
2. Export findings and close
```

User selects option 1 — agent gets explicit approval, then fixes the docstring.

## Documentation Philosophy

See [references/doc-philosophy.md](references/doc-philosophy.md) — code is source of truth, documentation should direct rather than describe, and stale docs are worse than no docs.
