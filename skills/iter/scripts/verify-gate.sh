#!/usr/bin/env bash
# verify-gate.sh — Run build/lint/test sequence and output JSON results
#
# Usage: verify-gate.sh <task-dir> <language>
# Language: typescript | swift | rust | python
#
# Exit 0 = all checks passed
# Exit 1 = one or more checks failed (see gate-result.local.json for details)

set -euo pipefail

# Bash 3.2 compatible — no associative arrays, no [[ =~ ]] with groups

TASK_DIR="${1:-}"
LANGUAGE="${2:-}"

if [ -z "$TASK_DIR" ] || [ -z "$LANGUAGE" ]; then
  echo "Usage: $0 <task-dir> <language>" >&2
  echo "Language: typescript | swift | rust | python" >&2
  exit 1
fi

if [ ! -d "$TASK_DIR" ]; then
  echo "Error: task-dir '$TASK_DIR' does not exist" >&2
  exit 1
fi

OUTPUT_FILE="$TASK_DIR/gate-result.local.json"
TIMESTAMP="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"

# Accumulate JSON check entries in a plain string
CHECKS_JSON=""
TOTAL=0
PASSED=0
FAILED=0

# run_check <name> <command...>
# Appends a JSON entry to CHECKS_JSON
run_check() {
  local name="$1"
  shift
  local cmd="$*"

  TOTAL=$((TOTAL + 1))
  local start_ms
  start_ms=$(date +%s)

  local output=""
  local exit_code=0
  output=$(eval "$cmd" 2>&1) || exit_code=$?

  local end_ms
  end_ms=$(date +%s)
  local duration_ms=$(( (end_ms - start_ms) * 1000 ))

  local passed_val="false"
  if [ "$exit_code" -eq 0 ]; then
    passed_val="true"
    PASSED=$((PASSED + 1))
  else
    FAILED=$((FAILED + 1))
  fi

  # Truncate output to 2000 chars, escape for JSON
  local truncated_output="${output:0:2000}"
  # Escape backslashes, double quotes, newlines, tabs for JSON
  truncated_output="${truncated_output//\\/\\\\}"
  truncated_output="${truncated_output//\"/\\\"}"
  truncated_output="${truncated_output//$'\n'/\\n}"
  truncated_output="${truncated_output//$'\t'/\\t}"
  truncated_output="${truncated_output//$'\r'/}"

  # Escape cmd for JSON
  local escaped_cmd="${cmd//\\/\\\\}"
  escaped_cmd="${escaped_cmd//\"/\\\"}"

  local entry="{\"name\": \"${name}\", \"command\": \"${escaped_cmd}\", \"passed\": ${passed_val}, \"duration_ms\": ${duration_ms}"
  if [ "$passed_val" = "false" ]; then
    entry="${entry}, \"output\": \"${truncated_output}\""
  fi
  entry="${entry}}"

  if [ -n "$CHECKS_JSON" ]; then
    CHECKS_JSON="${CHECKS_JSON}, ${entry}"
  else
    CHECKS_JSON="${entry}"
  fi
}

# Language-specific check sequences
case "$LANGUAGE" in
  typescript)
    run_check "build" "tsc --noEmit"
    run_check "lint" "eslint ."
    if command -v vitest >/dev/null 2>&1; then
      run_check "test" "vitest run"
    else
      run_check "test" "npm test"
    fi
    ;;
  swift)
    run_check "build" "swift build"
    if command -v swiftlint >/dev/null 2>&1; then
      run_check "lint" "swiftlint lint"
    fi
    run_check "test" "swift test"
    ;;
  rust)
    run_check "build" "cargo check"
    run_check "lint" "cargo clippy -- -D warnings"
    run_check "test" "cargo test"
    ;;
  python)
    if command -v mypy >/dev/null 2>&1; then
      run_check "build" "mypy ."
    fi
    if command -v ruff >/dev/null 2>&1; then
      run_check "lint" "ruff check ."
    fi
    run_check "test" "pytest"
    ;;
  *)
    echo "Error: unsupported language '$LANGUAGE'. Use: typescript | swift | rust | python" >&2
    exit 1
    ;;
esac

# Write JSON output
cat > "$OUTPUT_FILE" <<EOF
{
  "script": "verify-gate",
  "timestamp": "${TIMESTAMP}",
  "language": "${LANGUAGE}",
  "checks": [${CHECKS_JSON}],
  "summary": {"total": ${TOTAL}, "passed": ${PASSED}, "failed": ${FAILED}}
}
EOF

echo "verify-gate: ${PASSED}/${TOTAL} checks passed → ${OUTPUT_FILE}"

if [ "$FAILED" -gt 0 ]; then
  exit 1
fi
exit 0
