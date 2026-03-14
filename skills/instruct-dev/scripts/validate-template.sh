#!/usr/bin/env bash
# validate-template.sh — Mechanical checks for prompt templates
# Usage: validate-template.sh <template-path>
# Exit 0: all passed, Exit 1: any failed, Exit 2: invalid args

set -euo pipefail

if [ $# -ne 1 ]; then
  echo '{"error":"Usage: validate-template.sh <template-path>"}' >&2
  exit 2
fi

TEMPLATE_PATH="$1"

if [ ! -f "$TEMPLATE_PATH" ]; then
  echo "{\"error\":\"File not found: $TEMPLATE_PATH\"}" >&2
  exit 2
fi

TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
TEMPLATE_CONTENT=$(cat "$TEMPLATE_PATH")

# ---- helpers ----

# json_bool: convert 0/1 to true/false
json_bool() {
  [ "$1" -eq 0 ] && echo "true" || echo "false"
}

# escape_json: minimal JSON string escaping (no external deps)
escape_json() {
  local s="$1"
  s="${s//\\/\\\\}"
  s="${s//\"/\\\"}"
  s="${s//$'\n'/\\n}"
  s="${s//$'\t'/\\t}"
  echo "$s"
}

# ---- check: prohibited_terms ----
# Grep for prohibited writing terms; collect matches with line/context
check_prohibited_terms() {
  local terms=("crafting" "drove" "championed" "elegant" "performant" "passionate" "innovative" "leverage" "seamless" "robust")
  local details=""
  local first=1
  local any_found=0

  for term in "${terms[@]}"; do
    local line_num=0
    while IFS= read -r raw_line; do
      line_num=$((line_num + 1))
      # case-insensitive match
      if echo "$raw_line" | grep -qi "$term"; then
        any_found=1
        local ctx
        ctx=$(escape_json "${raw_line:0:80}")
        if [ $first -eq 1 ]; then
          first=0
        else
          details="$details,"
        fi
        details="$details{\"term\":\"$term\",\"line\":$line_num,\"context\":\"$ctx\"}"
      fi
    done < "$TEMPLATE_PATH"
  done

  local passed
  passed=$(json_bool $any_found)
  if [ -n "$details" ]; then
    echo "{\"name\":\"prohibited_terms\",\"passed\":$passed,\"details\":[$details]}"
  else
    echo "{\"name\":\"prohibited_terms\",\"passed\":$passed,\"details\":[]}"
  fi
  return $any_found
}

# ---- check: xml_structure ----
# Verify presence of required XML tags
check_xml_structure() {
  local required_tags=("context" "constraints" "input_structure" "output_format")
  local found_tags=""
  local missing_tags=""
  local first_found=1
  local first_missing=1
  local any_missing=0

  for tag in "${required_tags[@]}"; do
    if echo "$TEMPLATE_CONTENT" | grep -q "<$tag"; then
      if [ $first_found -eq 1 ]; then first_found=0; else found_tags="$found_tags,"; fi
      found_tags="$found_tags\"$tag\""
    else
      any_missing=1
      if [ $first_missing -eq 1 ]; then first_missing=0; else missing_tags="$missing_tags,"; fi
      missing_tags="$missing_tags\"$tag (missing)\""
    fi
  done

  local all_details=""
  [ -n "$found_tags" ] && all_details="$found_tags"
  if [ -n "$missing_tags" ]; then
    [ -n "$all_details" ] && all_details="$all_details,"
    all_details="$all_details$missing_tags"
  fi

  local passed
  passed=$(json_bool $any_missing)
  echo "{\"name\":\"xml_structure\",\"passed\":$passed,\"details\":[$all_details]}"
  return $any_missing
}

# ---- check: no_personas ----
# Grep for persona-style instructions
check_no_personas() {
  local persona_patterns=("You are a" "Act as a" "Imagine you")
  local found=0
  local details=""
  local first=1

  for pattern in "${persona_patterns[@]}"; do
    if echo "$TEMPLATE_CONTENT" | grep -q "$pattern"; then
      found=1
      if [ $first -eq 1 ]; then first=0; else details="$details,"; fi
      details="$details\"$pattern\""
    fi
  done

  local passed
  passed=$(json_bool $found)
  if [ -n "$details" ]; then
    echo "{\"name\":\"no_personas\",\"passed\":$passed,\"details\":[$details]}"
  else
    echo "{\"name\":\"no_personas\",\"passed\":$passed}"
  fi
  return $found
}

# ---- check: no_step_by_step ----
# Grep for explicit step-by-step patterns
check_no_step_by_step() {
  local found=0
  local details=""
  local first=1

  if echo "$TEMPLATE_CONTENT" | grep -qE "Step [0-9]+:"; then
    found=1
    if [ $first -eq 1 ]; then first=0; else details="$details,"; fi
    details="$details\"Step N: pattern found\""
  fi

  # Detect "First, ... Second, ... Third," across the full content
  if echo "$TEMPLATE_CONTENT" | grep -q "First," && \
     echo "$TEMPLATE_CONTENT" | grep -q "Second," && \
     echo "$TEMPLATE_CONTENT" | grep -q "Third,"; then
    found=1
    if [ $first -eq 1 ]; then first=0; else details="$details,"; fi
    details="$details\"First\/Second\/Third sequence found\""
  fi

  local passed
  passed=$(json_bool $found)
  if [ -n "$details" ]; then
    echo "{\"name\":\"no_step_by_step\",\"passed\":$passed,\"details\":[$details]}"
  else
    echo "{\"name\":\"no_step_by_step\",\"passed\":$passed}"
  fi
  return $found
}

# ---- check: context_tag ----
# Verify <context> tag is present
check_context_tag() {
  local found=0
  if echo "$TEMPLATE_CONTENT" | grep -q "<context"; then
    found=1
  fi

  local inverse
  inverse=$(json_bool $((1 - found)))
  echo "{\"name\":\"context_tag\",\"passed\":$inverse}"
  # exit 0 if found (passed), exit 1 if not found (failed)
  [ $found -eq 1 ]
}

# ---- run all checks ----
checks_json=""
total=0
passed_count=0
failed_count=0

run_check() {
  local check_name="$1"
  local check_fn="$2"
  local result exit_code

  result=$($check_fn 2>/dev/null) || true
  # Re-run to get exit code (subshell above loses it with set -e)
  if $check_fn > /dev/null 2>&1; then
    exit_code=0
  else
    exit_code=1
  fi

  total=$((total + 1))
  if [ $exit_code -eq 0 ]; then
    passed_count=$((passed_count + 1))
  else
    failed_count=$((failed_count + 1))
  fi

  if [ -n "$checks_json" ]; then
    checks_json="$checks_json,"
  fi
  checks_json="$checks_json$result"
}

# Collect results — suppress set -e for individual check failures
set +e
run_check "prohibited_terms" check_prohibited_terms
run_check "xml_structure" check_xml_structure
run_check "no_personas" check_no_personas
run_check "no_step_by_step" check_no_step_by_step
run_check "context_tag" check_context_tag
set -e

TEMPLATE_PATH_ESC=$(escape_json "$TEMPLATE_PATH")

cat <<EOF
{
  "script": "validate-template",
  "timestamp": "$TIMESTAMP",
  "template": "$TEMPLATE_PATH_ESC",
  "checks": [$checks_json],
  "summary": {"total": $total, "passed": $passed_count, "failed": $failed_count}
}
EOF

[ $failed_count -eq 0 ]
