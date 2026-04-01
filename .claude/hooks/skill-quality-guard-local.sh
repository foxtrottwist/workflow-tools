#!/bin/bash
# skill-quality-guard-local.sh — PostToolUse hook for local repo use.
# Mirrors the plugin-level skill-quality-guard.sh for contributors
# who don't have the workflow-tools plugin installed.
# Register in .claude/settings.local.json to activate.

INPUT=$(cat) || exit 0

# Skip in subagents
AGENT_ID=$(echo "$INPUT" | jq -r '.agent_id // empty') || exit 0
[[ -n "$AGENT_ID" ]] && exit 0

FILE=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty') || exit 0

[[ -z "$FILE" ]] && exit 0

# Only fire for skill SKILL.md files or agent definition files
if [[ "$FILE" != */skills/*/SKILL.md && "$FILE" != */agents/*.md ]]; then
  exit 0
fi

cat <<'EOF'
{
  "hookSpecificOutput": {
    "hookEventName": "PostToolUse",
    "additionalContext": "Skill or agent file modified. Quality checklist:\n- Invoke skill-creator (if installed) to review and optimize this file\n- Consult references/optimization/agent-optimization-guide.md for authoring principles\nKey checks: description has quoted trigger phrases, body has a worked example, no [placeholder] output templates, body under 200 lines."
  }
}
EOF
