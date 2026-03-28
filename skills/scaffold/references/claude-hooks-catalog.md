# Claude Hooks Catalog

Reusable hook patterns for `.claude/hooks/hooks.json`. Each hook is a shell script triggered by a Claude Code lifecycle event.

All hooks should:
- Skip subagents: check `agent_id` field from stdin and exit 0 if present
- Fail open: end with `|| exit 0` so a broken hook doesn't block work
- Read stdin as JSON: pipe through `jq` for field extraction

## Canonical hooks.json

Always use this exact structure. All hook commands point to `.claude/hooks/`:

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

## Verification Nudge

**Event:** Stop
**Purpose:** Prompt the agent to run tests/build before declaring work complete.
**When to use:** Any project with a test suite or build step.

```bash
#!/usr/bin/env bash
set -euo pipefail

INPUT=$(cat)
echo "$INPUT" | jq -e '.agent_id' > /dev/null 2>&1 && exit 0

# Check if tests/build were run in this session
# If not, remind the agent
echo "Commit reminder: have you run the test suite and confirmed a clean build before stopping?" || exit 0
```

## CLAUDE.md Bloat Guard

**Event:** PreToolUse (Edit|Write) — script filters to CLAUDE.md/AGENTS.md internally
**Purpose:** Warn when agent files exceed ~50 lines.
**When to use:** Any project with a CLAUDE.md.

The matcher is broad (`Edit|Write`) but the script exits silently for files that aren't CLAUDE.md or AGENTS.md. This avoids complex matcher syntax while keeping the guard precise.

```bash
#!/usr/bin/env bash
set -euo pipefail

INPUT=$(cat)
echo "$INPUT" | jq -e '.agent_id' > /dev/null 2>&1 && exit 0

FILE=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty') || exit 0

# Only guard CLAUDE.md and AGENTS.md
case "$FILE" in
  */CLAUDE.md|*/AGENTS.md|CLAUDE.md|AGENTS.md) ;;
  *) exit 0 ;;
esac

LINE_COUNT=$(wc -l < "$FILE" 2>/dev/null || echo 0)
THRESHOLD=50

if [ "$LINE_COUNT" -gt "$THRESHOLD" ]; then
  echo "CLAUDE.md bloat warning: file is $LINE_COUNT lines (threshold ~$THRESHOLD). Before adding content, verify each line is a hard requirement Claude cannot discover from the code. Remove anything descriptive, architectural, or already covered by skills."
fi

exit 0
```

## Commit Reminder

**Event:** PostToolUse (Bash or Edit)
**Purpose:** Nudge the agent to commit completed work periodically.
**When to use:** Projects where the agent tends to accumulate large uncommitted changesets.

Counts uncommitted files via `git status --porcelain`. If count exceeds a threshold (e.g., 10 files), outputs a reminder. Useful for long-running sessions.

## Test on Save

**Event:** PostToolUse (Edit or Write targeting source files)
**Purpose:** Run fast tests after each file edit.
**When to use:** Projects with a fast test suite (<5 seconds). Not suitable for slow test suites.

Detects which file was edited, runs the relevant test subset if the project supports targeted test running (e.g., `jest --findRelatedTests`, `swift test --filter`). Provides immediate feedback.

## Dependency Audit

**Event:** PreToolUse (Edit or Write targeting package manifests)
**Purpose:** Warn before adding new dependencies.
**When to use:** Projects with strict dependency policies.

When the agent edits `package.json`, `Package.swift`, `Cargo.toml`, `requirements.txt`, etc., the hook outputs a reminder to verify the dependency is necessary and approved.

## Writing Hook Scripts

Hooks are shell scripts that receive a JSON object on stdin. Key fields:

- `tool_name` — the tool being called (Edit, Write, Bash, etc.)
- `tool_input` — the tool's parameters (file_path, command, etc.)
- `agent_id` — present only for subagents (skip when set)
- `session_id` — the current session

Example skeleton:

```bash
#!/usr/bin/env bash
set -euo pipefail

INPUT=$(cat)

# Skip subagents
echo "$INPUT" | jq -e '.agent_id' > /dev/null 2>&1 && exit 0

# Your logic here
FILE=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty') || exit 0

# Output feedback (agent sees this)
echo "Reminder: run tests before stopping."
```

Make scripts executable: `chmod +x hooks/*.sh`
