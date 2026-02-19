# Development Mode

Task format, model selection, and programmatic gates for development work.

## Task Format

```markdown
# {Feature} - Tasks

**Total:** {N} tasks

## Dependencies

```
T1 ──► T3 ──► T5
T2 ────┘
T4 (independent)
```

## Tasks

- [ ] **T1**: {title}
  - Files: `path/to/file.ts`
  - Criteria: {measurable acceptance}
  - Depends: none
  - Model: sonnet
  - Max turns: 5

- [ ] **T2**: {title}
  - Files: `path/to/file.ts`, `path/to/other.ts`
  - Criteria: {acceptance}
  - Depends: T1
  - Model: sonnet
  - Max turns: 8
```

## Model Selection (Advisory)

Native model routing handles the common case. Use explicit overrides for cost optimization or when task complexity warrants it.

| Task Type | Model | Rationale |
|-----------|-------|-----------|
| File search, grep, glob | haiku | Pattern matching |
| Simple file edits (<50 lines) | haiku | Mechanical changes |
| Standard implementation | sonnet | Balanced capability |
| Code review | sonnet | Standards verification |
| Test generation | sonnet | Structured output |
| Complex debugging | opus | Root cause analysis |
| Architecture decisions | opus | Multi-factor reasoning |
| Refactors touching many files | opus | Coordination complexity |

**Default**: sonnet

## Programmatic Gates

Run the gate script after every completion attempt:

```bash
scripts/verify-gate.sh <task-dir> <language>
# language: typescript | swift | rust | python
# Writes gate-result.local.json to <task-dir>
# Exit 0 = all passed, exit 1 = failures (details in JSON)
```

If any check fails, back to implementation loop immediately. The JSON output in `gate-result.local.json` contains per-check results with command output for debugging.

### Individual checks by language

| Language | Build | Lint | Test |
|----------|-------|------|------|
| TypeScript | `tsc --noEmit` | `eslint .` | `vitest run` or `npm test` |
| Swift | `swift build` | `swiftlint lint` | `swift test` |
| Rust | `cargo check` | `cargo clippy -- -D warnings` | `cargo test` |
| Python | `mypy .` | `ruff check .` | `pytest` |

## JSON Output Convention

All scripts that produce structured results write to `*.local.json` files in the task's state directory. The schema is flat with a checks results array:

```json
{
  "script": "verify-gate",
  "timestamp": "2024-01-01T00:00:00Z",
  "language": "typescript",
  "checks": [
    {"name": "build", "command": "tsc --noEmit", "passed": true, "duration_ms": 1234},
    {"name": "lint", "command": "eslint .", "passed": false, "output": "...truncated to 2000 chars..."}
  ],
  "summary": {"total": 3, "passed": 2, "failed": 1}
}
```

Naming pattern: `<script-name>.local.json` (e.g., `gate-result.local.json`). The `*.local` gitignore pattern covers these files — they are ephemeral state, not tracked artifacts.

## Test Gate

```
Implementation DONE → Build passes? → Test agent
                                        ├── Generate tests (if needed)
                                        ├── Run all tests
                                        ├── TESTS_PASS → Confirmation
                                        └── TESTS_FAIL → Fix iteration → Re-test
```

**Test strategy by task type:**

| Task Type | Test Approach |
|-----------|---------------|
| New feature | Unit + integration tests |
| Bug fix | Regression test for the bug |
| Refactor | Existing tests must pass |
| API change | Contract tests |

## Good vs Bad Tasks

### Good Task

```markdown
- [ ] **T1**: Create User data model
  - Files: `src/models/User.swift`
  - Criteria:
    - Model with id (UUID), email (String), createdAt (Date)
    - SwiftData @Model annotation
    - @Attribute(.unique) on email
  - Depends: none
  - Model: sonnet
  - Max turns: 5
```

Why it's good:
- Clear, specific title
- Single file focus
- Measurable criteria (can verify each point)
- Appropriate model

### Bad Task

```markdown
- [ ] **T1**: Implement authentication
  - Files: multiple
  - Criteria: users can log in
  - Depends: none
  - Model: haiku
  - Max turns: 3
```

Problems:
- Too broad ("implement authentication")
- Vague files ("multiple")
- Unmeasurable criteria ("users can log in")
- Wrong model (haiku for complex work)
- Too few turns for complexity

## Dependency Notation

- `none` — Can start immediately
- `T1` — Wait for T1 to complete
- `T1, T2` — Wait for both (all must complete)

Independent tasks can be dispatched as parallel Task tool calls.
