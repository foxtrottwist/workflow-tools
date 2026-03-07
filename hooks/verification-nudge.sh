#!/bin/bash
# verification-nudge.sh — Stop hook
# If Swift files were modified BY THIS SESSION, prompt Claude to confirm
# verification (build + tests) before stopping.

INPUT=$(cat) || exit 0

# Skip in subagents
AGENT_ID=$(echo "$INPUT" | jq -r '.agent_id // empty') || exit 0
[[ -n "$AGENT_ID" ]] && exit 0

# Never fire twice — prevents infinite loop
ACTIVE=$(echo "$INPUT" | jq -r '.stop_hook_active // false') || exit 0
[[ "$ACTIVE" == "true" ]] && exit 0

# Check transcript for Edit/Write calls targeting .swift files
TRANSCRIPT=$(echo "$INPUT" | jq -r '.transcript_path // empty') || exit 0
[[ -z "$TRANSCRIPT" || ! -f "$TRANSCRIPT" ]] && exit 0

# Only nudge if this session actually wrote/edited Swift files
if ! grep -q '"Edit"\|"Write"' "$TRANSCRIPT" 2>/dev/null; then
  exit 0
fi
if ! grep -q '\.swift' "$TRANSCRIPT" 2>/dev/null; then
  exit 0
fi

CWD=$(echo "$INPUT" | jq -r '.cwd') || exit 0
cd "$CWD" || exit 0
git rev-parse --git-dir > /dev/null 2>&1 || exit 0

SWIFT_CHANGES=$(git status --porcelain | grep '\.swift$' | wc -l | tr -d ' ')
[[ "$SWIFT_CHANGES" -eq 0 ]] && exit 0

cat <<EOF
{
  "decision": "block",
  "reason": "Swift files were modified ($SWIFT_CHANGES file(s)). Before stopping: confirm build passes and tests were run. If verification is already complete or not applicable, state why and proceed."
}
EOF
