---
name: scaffold
description: "Set up a project for agent-assisted development with feedback loops, scoped knowledge, and guardrails. Use when starting a new project and want to set up git hooks, tests, Claude hooks, and local skills. Use when entering an existing project that lacks agent tooling. Use when asked to make a repo 'agent-safe', 'agent-ready', set up developer tooling, add Claude hooks, create local skills, or audit project infrastructure. Triggers on: 'scaffold', 'set up this project', 'make this agent-ready', 'audit this project', 'add hooks', 'set up testing', 'bootstrap', 'project setup'."
---

# Scaffold

Set up a project so any coding agent entering the repo gets feedback loops, scoped knowledge, and guardrails. The goal: eval-driven development where the agent receives feedback from tests, git hooks, Claude hooks, and has scoped skills for the repository's domain.

## Choose a mode

**Mode 1 — New project:** No existing infrastructure. Guide the user through full setup.
**Mode 2 — Existing project:** Infrastructure exists but may have gaps. Audit and fill them.

Ask which mode if unclear from context. If the repo has a `package.json`, `Package.swift`, `Cargo.toml`, or similar, default to Mode 2.

## Mode 1: New Project Setup

Walk through each layer in order. Present recommendations, get approval, then implement.

### Step 1: Detect the stack

Read the project root. Identify:
- Language and package manager (Swift/SPM, Node/npm, Python/uv, Rust/cargo, etc.)
- Existing test files or test directories
- Existing git configuration
- Whether `.claude/` exists

### Step 2: Testing infrastructure

If no tests exist, ask: "What test framework does this project use, or should I set one up?"

Ensure there is a way to run tests from the command line. The agent needs a single command that returns pass/fail. Document it in CLAUDE.md under `## Build and Test`.

### Step 3: Git hooks

Check for existing git hook tooling (lefthook, husky, pre-commit framework, raw `.git/hooks/`).

If nothing is present, offer two paths:
1. **Ad hoc scripts** — shell scripts in `.githooks/` with `git config core.hooksPath .githooks`
2. **Hook manager** — suggest the appropriate tool for the stack (lefthook for polyglot, husky for Node, pre-commit for Python)

Ask the user which they prefer. Then set up:
- **pre-commit**: lint, format check, build check as appropriate for the stack
- **pre-push**: test suite gate

### Step 4: Claude hooks

Create `.claude/hooks/hooks.json` with hooks selected from the catalog. Read `references/claude-hooks-catalog.md` for available patterns.

Default recommendations for any project:
- **Verification nudge** (Stop event) — prompts the agent to run tests before declaring done
- **CLAUDE.md bloat guard** (PreToolUse on Edit|Write, scoped to CLAUDE.md only) — warns when CLAUDE.md exceeds ~50 lines

Use this exact hooks.json structure:

```json
{
  "hooks": [
    {
      "type": "Stop",
      "command": ".claude/hooks/verification-nudge.sh"
    },
    {
      "type": "PreToolUse",
      "matcher": "Edit|Write",
      "command": ".claude/hooks/claude-md-bloat-guard.sh"
    }
  ]
}
```

The bloat guard script must filter by file path internally — only warn when the target file is `CLAUDE.md` (or `AGENTS.md`). Exit 0 silently for all other files. This keeps the matcher broad (catches both Edit and Write) while the script handles specificity.

Present the full list of applicable hooks and let the user select which to include.

### Step 5: CLAUDE.md

Create a minimal CLAUDE.md following the reactive principle — only include what the agent cannot discover from the code. Target ≤25 lines. Combine multiple commands on one line with `&&` when they form a single workflow step.

```
## Build and Test
{exact commands — one line per distinct step}

## Constraints
{only if conventions differ from defaults}

## Corrections
_(None yet — add when an observed failure warrants it.)_
```

Do not add architecture overviews, file descriptions, or general language guidance. If the file exceeds 25 lines, cut — every line costs reasoning tokens across every agent session.

### Step 6: Local skills

Ask: "Are there any domain-specific workflows in this project that an agent would need guidance on? Things like: deployment procedures, API conventions, data pipeline steps, or unusual build processes."

If the user identifies workflows, offer to create skill stubs using the `instruct-dev` skill. If not, skip — don't create skills speculatively.

### Step 7: Source control

Ensure `.claude/` is committed. Check `.gitignore` for patterns that would exclude it.

Default: commit everything in `.claude/` except `settings.json` (contains personal preferences). Add to `.gitignore`:
```
.claude/settings.json
```

Ask the user if they want to include settings. Default is exclude.

If `.claude/` was previously gitignored entirely, remove that pattern and add the selective ignore above.

## Mode 2: Existing Project Audit

### Step 1: Scan

Check for the presence of each layer:

| Layer | What to check |
|-------|--------------|
| Tests | Test directory exists, test command works, documented in CLAUDE.md |
| Git hooks | `.githooks/`, `.husky/`, `.lefthook.yml`, `.pre-commit-config.yaml`, `.git/hooks/` |
| Claude hooks | `.claude/hooks/hooks.json` |
| CLAUDE.md | Exists, follows reactive principles, not bloated |
| Local skills | `.claude/skills/` with SKILL.md files |
| Source control | `.claude/` committed, settings excluded |

### Step 2: Report gaps

Present findings as a checklist:
```
[x] Tests — jest configured, `npm test` works, documented in CLAUDE.md
[ ] Git hooks — no pre-commit or pre-push hooks found
[x] CLAUDE.md — exists but 87 lines, needs trimming
[ ] Claude hooks — no hooks.json
[ ] Local skills — none found
[x] Source control — .claude/ committed
```

### Step 3: Implement fixes

For each gap, follow the same procedure as Mode 1 for that layer. Ask for approval before implementing each one.

For CLAUDE.md trimming: apply the review checklist — remove lines the agent can discover from code, remove architecture descriptions, remove general language guidance. Keep build commands, constraints, corrections, and gotchas.

## Worked Example

User enters a Node.js project with Jest tests but no hooks or Claude configuration.

```
Scan results:
[x] Tests — jest in devDependencies, `npm test` runs 47 tests
[ ] Git hooks — nothing found
[ ] CLAUDE.md — missing
[ ] Claude hooks — missing
[ ] Local skills — none
[ ] Source control — no .claude/ directory

Recommendations:
1. Git hooks via husky (already using npm):
   - pre-commit: npx eslint --fix && npx prettier --check .
   - pre-push: npm test
2. CLAUDE.md with build/test commands
3. Claude hooks: verification nudge + bloat guard
4. .claude/ committed with settings.json excluded

Proceed with all? Or select specific items?
```

User approves. Agent installs husky, creates hooks, writes CLAUDE.md, creates hooks.json, updates .gitignore.

## Constraints

- Never generate CLAUDE.md content with an LLM — write it by hand based on what the project actually needs.
- Never create skills speculatively. Only create them when the user identifies a concrete, recurring workflow.
- Always ask before installing dependencies (husky, lefthook, etc.).
- Always present the full plan before implementing. Get explicit approval.
- Default to excluding `.claude/settings.json` from source control.
