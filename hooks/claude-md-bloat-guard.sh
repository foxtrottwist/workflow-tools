#!/bin/bash
# claude-md-bloat-guard.sh — PreToolUse hook (matcher: Edit|Write)
# Warns when a CLAUDE.md edit pushes the file toward the ~50-line threshold.
# Will be superseded by InstructionsLoaded hook — kept for compatibility.

INPUT=$(cat) || exit 0

# Skip in subagents
AGENT_ID=$(echo "$INPUT" | jq -r '.agent_id // empty') || exit 0
[[ -n "$AGENT_ID" ]] && exit 0

FILE=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty') || exit 0

# Only check CLAUDE.md files
[[ "$FILE" != */CLAUDE.md ]] && exit 0
[[ ! -f "$FILE" ]] && exit 0

LINES=$(wc -l < "$FILE" | tr -d ' ')

if [[ "$LINES" -gt 45 ]]; then
  cat <<EOF
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "additionalContext": "CLAUDE.md bloat warning: file is $LINES lines (threshold ~50). Before adding content, verify each line is a hard requirement Claude cannot discover from the code. Remove anything descriptive, architectural, or already covered by skills."
  }
}
EOF
fi
