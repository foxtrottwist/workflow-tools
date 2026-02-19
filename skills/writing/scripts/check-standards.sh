#!/usr/bin/env bash
# check-standards.sh — Mechanical writing standards check
# Usage: check-standards.sh <content-path>
# Exit 0 = all passed, 1 = any failed, 2 = invalid args

set -euo pipefail

if [ $# -lt 1 ]; then
  echo "Usage: check-standards.sh <content-path>" >&2
  exit 2
fi

CONTENT_PATH="$1"

if [ ! -f "$CONTENT_PATH" ]; then
  echo "Error: file not found: $CONTENT_PATH" >&2
  exit 2
fi

TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

# --- helpers ---

# json_escape: minimal escaping for embedding strings in JSON
json_escape() {
  local s="$1"
  # Replace backslash first, then quotes, then control chars
  s="${s//\\/\\\\}"
  s="${s//\"/\\\"}"
  printf '%s' "$s"
}

# search_terms: grep file for terms, return JSON detail array
# Args: file, term1 term2 ...
search_terms() {
  local file="$1"
  shift
  local terms=("$@")
  local details=""
  local first=1

  for term in "${terms[@]}"; do
    # grep -n returns "linenum:content"; -i case-insensitive
    while IFS=: read -r linenum context; do
      local escaped_term
      escaped_term=$(json_escape "$term")
      local escaped_context
      escaped_context=$(json_escape "$context")
      if [ $first -eq 0 ]; then
        details="${details},"
      fi
      details="${details}{\"term\":\"${escaped_term}\",\"line\":${linenum},\"context\":\"${escaped_context}\"}"
      first=0
    done < <(grep -in "$term" "$file" 2>/dev/null || true)
  done

  printf '%s' "$details"
}

# search_patterns: grep file for regex patterns, return JSON detail array
search_patterns() {
  local file="$1"
  shift
  local patterns=("$@")
  local details=""
  local first=1

  for pattern in "${patterns[@]}"; do
    while IFS=: read -r linenum context; do
      local escaped_pattern
      escaped_pattern=$(json_escape "$pattern")
      local escaped_context
      escaped_context=$(json_escape "$context")
      if [ $first -eq 0 ]; then
        details="${details},"
      fi
      details="${details}{\"term\":\"${escaped_pattern}\",\"line\":${linenum},\"context\":\"${escaped_context}\"}"
      first=0
    done < <(grep -inE "$pattern" "$file" 2>/dev/null || true)
  done

  printf '%s' "$details"
}

# build_check: produce a JSON check object
# Args: name, details_string
build_check() {
  local name="$1"
  local details="$2"

  if [ -z "$details" ]; then
    printf '{"name":"%s","passed":true}' "$name"
  else
    printf '{"name":"%s","passed":false,"details":[%s]}' "$name" "$details"
  fi
}

# --- checks ---

PROHIBITED_TERMS=(
  "crafting"
  "drove"
  "championed"
  "elegant"
  "performant"
  "passionate"
  "innovative"
  "leverage"
  "seamless"
  "robust"
)

MARKETING_TERMS=(
  "unlock"
  "empower"
  "transform"
  "revolutionize"
  "game-changer"
  "cutting-edge"
  "world-class"
  "best-in-class"
  "industry-leading"
)

VAGUE_PATTERNS=(
  "proven track record"
  "deep expertise"
  "[0-9]* years of experience"
)
# "years of experience" without a leading number — match lines that have the phrase but NOT a digit before it
VAGUE_PATTERNS_NO_NUM=(
  "years of experience"
)

# Check 1: prohibited_terms
prohibited_details=$(search_terms "$CONTENT_PATH" "${PROHIBITED_TERMS[@]}")
check_prohibited=$(build_check "prohibited_terms" "$prohibited_details")

# Check 2: marketing_tone
marketing_details=$(search_terms "$CONTENT_PATH" "${MARKETING_TERMS[@]}")
check_marketing=$(build_check "marketing_tone" "$marketing_details")

# Check 3: vague_claims
# "proven track record" and "deep expertise" are always vague
# "years of experience" is vague only when NOT preceded by a digit
vague_details_fixed=$(search_patterns "$CONTENT_PATH" "proven track record" "deep expertise")

# For "years of experience": match lines that contain the phrase but have no digit directly before it
vague_yoe_details=""
vague_yoe_first=1
while IFS=: read -r linenum context; do
  # If the context does NOT have a digit before "years", flag it
  if ! echo "$context" | grep -qiE '[0-9]+ years of experience'; then
    escaped_context=$(json_escape "$context")
    if [ $vague_yoe_first -eq 0 ]; then
      vague_yoe_details="${vague_yoe_details},"
    fi
    vague_yoe_details="${vague_yoe_details}{\"term\":\"years of experience\",\"line\":${linenum},\"context\":\"${escaped_context}\"}"
    vague_yoe_first=0
  fi
done < <(grep -inE "years of experience" "$CONTENT_PATH" 2>/dev/null || true)

# Combine vague details
if [ -n "$vague_details_fixed" ] && [ -n "$vague_yoe_details" ]; then
  vague_details="${vague_details_fixed},${vague_yoe_details}"
elif [ -n "$vague_details_fixed" ]; then
  vague_details="$vague_details_fixed"
else
  vague_details="$vague_yoe_details"
fi

check_vague=$(build_check "vague_claims" "$vague_details")

# --- tally ---
total=3
passed=0
failed=0

for check in "$check_prohibited" "$check_marketing" "$check_vague"; do
  if echo "$check" | grep -q '"passed":true'; then
    passed=$((passed + 1))
  else
    failed=$((failed + 1))
  fi
done

# --- output ---
escaped_path=$(json_escape "$CONTENT_PATH")

cat <<EOF
{
  "script": "check-standards",
  "timestamp": "${TIMESTAMP}",
  "content": "${escaped_path}",
  "checks": [
    ${check_prohibited},
    ${check_marketing},
    ${check_vague}
  ],
  "summary": {"total": ${total}, "passed": ${passed}, "failed": ${failed}}
}
EOF

[ $failed -gt 0 ] && exit 1 || exit 0
