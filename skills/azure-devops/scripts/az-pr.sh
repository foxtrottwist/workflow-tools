#!/usr/bin/env bash
# az-pr.sh — Azure DevOps PR operations bundled for fewer permission prompts.
# Read subcommands run directly. Write operations (review-actions) require a JSON action plan.
set -euo pipefail

# --- Helpers ---

# Captures stderr, checks exit code, surfaces categorized errors.
# Result stored in AZ_OUT. Compatible with bash 3.2 (macOS default).
# Usage: az_safe az repos pr show --id 123; echo "$AZ_OUT"
AZ_OUT=""
az_safe() {
  local errfile
  errfile=$(mktemp)

  local rc=0
  AZ_OUT=$("$@" 2>"$errfile") || rc=$?

  if [ "$rc" -ne 0 ]; then
    local err
    err=$(cat "$errfile")
    rm -f "$errfile"

    if echo "$err" | grep -qi "az login"; then
      echo "Error: Not authenticated. Run 'az login' first." >&2
    elif echo "$err" | grep -qi "could not be found\|does not exist\|404"; then
      echo "Error: Resource not found. Check that the PR ID is correct." >&2
    elif echo "$err" | grep -qi "project.*not found\|TF200016"; then
      echo "Error: Project not found. The configured default may not match this repo." >&2
    else
      echo "Error: az CLI failed (exit $rc):" >&2
      echo "$err" >&2
    fi
    return 1
  fi

  rm -f "$errfile"
}

usage() {
  cat <<'USAGE'
Usage: az-pr.sh <subcommand> <pr-id>

PR operations for Azure DevOps.

Subcommands:
  context <pr-id>                    Project, repo ID, branches, author
  threads <pr-id>                    Non-system threads (human-readable)
  threads-json <pr-id>               Non-system threads (structured JSON)
  active <pr-id>                     Active/unresolved threads only
  overview <pr-id>                   Full PR overview: context + threads + reviewers
  files <pr-id>                      List changed files
  diff <pr-id>                       Full diff content via git
  review-actions <pr-id> <actions>   Execute batch write operations from JSON file
USAGE
}

# Extract project and repo ID from a PR — never relies on az devops configure.
get_pr_meta() {
  local pr_id=$1
  az_safe az repos pr show --id "$pr_id" -o json

  PROJECT=$(echo "$AZ_OUT" | jq -r '.repository.project.name')
  REPO_ID=$(echo "$AZ_OUT" | jq -r '.repository.id')
  PR_RAW="$AZ_OUT"
}

# --- Subcommands ---

cmd_context() {
  local pr_id=$1
  get_pr_meta "$pr_id"

  echo "$PR_RAW" | jq '{
    project: .repository.project.name,
    repoId: .repository.id,
    repoName: .repository.name,
    prId: .pullRequestId,
    title: .title,
    status: .status,
    mergeStatus: .mergeStatus,
    isDraft: .isDraft,
    source: (.sourceRefName | sub("refs/heads/"; "")),
    target: (.targetRefName | sub("refs/heads/"; "")),
    author: .createdBy.displayName
  }'
}

cmd_threads() {
  local pr_id=$1
  get_pr_meta "$pr_id"

  az_safe az devops invoke \
    --area git \
    --resource pullRequestThreads \
    --route-parameters project="$PROJECT" repositoryId="$REPO_ID" pullRequestId="$pr_id" \
    --api-version 7.1 \
    -o json

  echo "$AZ_OUT" | jq -r '
    .value[]
    | select(.comments[0].commentType != "system")
    | "--- Thread \(.id) [\(.status // "none")] \(.threadContext.filePath // "(general)") ---",
      (.comments[]
        | select(.commentType != "system")
        | "  \(.author.displayName): \(.content // "" | split("\n")[0])")'
}

cmd_threads_json() {
  local pr_id=$1
  get_pr_meta "$pr_id"

  az_safe az devops invoke \
    --area git \
    --resource pullRequestThreads \
    --route-parameters project="$PROJECT" repositoryId="$REPO_ID" pullRequestId="$pr_id" \
    --api-version 7.1 \
    -o json

  echo "$AZ_OUT" | jq '[
    .value[]
    | select(.comments[0].commentType != "system")
    | {
        id,
        status,
        file: .threadContext.filePath,
        line: .threadContext.rightFileStart.line,
        comments: [
          .comments[]
          | select(.commentType != "system")
          | {
              author: .author.displayName,
              content: (.content // "" | split("\n")[0]),
              date: .publishedDate
            }
        ]
      }
  ]'
}

cmd_active() {
  local pr_id=$1
  get_pr_meta "$pr_id"

  az_safe az devops invoke \
    --area git \
    --resource pullRequestThreads \
    --route-parameters project="$PROJECT" repositoryId="$REPO_ID" pullRequestId="$pr_id" \
    --api-version 7.1 \
    -o json

  echo "$AZ_OUT" | jq -r '
    .value[]
    | select(.status == "active" and .comments[0].commentType != "system")
    | "[\(.threadContext.filePath // "general")] \(.comments[0].author.displayName): \(.comments[0].content // "" | split("\n")[0])"'
}

cmd_overview() {
  local pr_id=$1
  get_pr_meta "$pr_id"

  echo "=== PR #${pr_id} ==="
  echo "$PR_RAW" | jq -r '"Title: \(.title)\nStatus: \(.status) (merge: \(.mergeStatus))\nDraft: \(.isDraft)\nAuthor: \(.createdBy.displayName)\nSource: \(.sourceRefName | sub("refs/heads/"; ""))\nTarget: \(.targetRefName | sub("refs/heads/"; ""))\nProject: \(.repository.project.name)\nRepo: \(.repository.name)"'

  echo ""
  echo "=== Reviewers ==="
  az_safe az repos pr reviewer list --id "$pr_id" -o json
  echo "$AZ_OUT" | jq -r '
    .[] | "\(.displayName): \(
      if .vote == 10 then "approved"
      elif .vote == 5 then "approved with suggestions"
      elif .vote == 0 then "no vote"
      elif .vote == -5 then "waiting"
      elif .vote == -10 then "rejected"
      else "unknown (\(.vote))"
      end
    )"'

  echo ""
  echo "=== Threads ==="
  az_safe az devops invoke \
    --area git \
    --resource pullRequestThreads \
    --route-parameters project="$PROJECT" repositoryId="$REPO_ID" pullRequestId="$pr_id" \
    --api-version 7.1 \
    -o json
  local threads="$AZ_OUT"

  local total active
  total=$(echo "$threads" | jq '[.value[] | select(.comments[0].commentType != "system")] | length')
  active=$(echo "$threads" | jq '[.value[] | select(.status == "active" and .comments[0].commentType != "system")] | length')
  echo "Total: $total ($active active)"
  echo ""

  echo "$threads" | jq -r '
    .value[]
    | select(.comments[0].commentType != "system")
    | "--- Thread \(.id) [\(.status // "none")] \(.threadContext.filePath // "(general)") ---",
      (.comments[]
        | select(.commentType != "system")
        | "  \(.author.displayName): \(.content // "" | split("\n")[0])")'
}

cmd_files() {
  local pr_id=$1

  local target source
  target=$(az repos pr show --id "$pr_id" --query 'targetRefName' -o tsv 2>/dev/null | sed 's|refs/heads/||')
  source=$(az repos pr show --id "$pr_id" --query 'sourceRefName' -o tsv 2>/dev/null | sed 's|refs/heads/||')

  if [ -z "$target" ] || [ -z "$source" ]; then
    echo "Error: Could not determine source/target branches for PR $pr_id" >&2
    return 1
  fi

  git fetch origin "$target" "$source" 2>/dev/null
  git diff "origin/$target...origin/$source" --name-status
}

cmd_diff() {
  local pr_id=$1

  local target source
  target=$(az repos pr show --id "$pr_id" --query 'targetRefName' -o tsv 2>/dev/null | sed 's|refs/heads/||')
  source=$(az repos pr show --id "$pr_id" --query 'sourceRefName' -o tsv 2>/dev/null | sed 's|refs/heads/||')

  if [ -z "$target" ] || [ -z "$source" ]; then
    echo "Error: Could not determine source/target branches for PR $pr_id" >&2
    return 1
  fi

  git fetch origin "$target" "$source" 2>/dev/null
  git diff "origin/$target...origin/$source"
}

cmd_review_actions() {
  local pr_id=$1
  local actions_file=$2

  if [ ! -f "$actions_file" ]; then
    echo "Error: Actions file not found: $actions_file" >&2
    return 1
  fi

  local actions
  actions=$(cat "$actions_file")

  get_pr_meta "$pr_id"

  local timestamp
  timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

  local checks_json="[]"
  local total=0
  local passed=0
  local failed=0

  # Helper: append a check result to checks_json
  append_check() {
    local name=$1
    local check_passed=$2
    local details=${3:-""}
    checks_json=$(echo "$checks_json" | jq \
      --arg n "$name" \
      --argjson p "$check_passed" \
      --arg d "$details" \
      '. + [{"name": $n, "passed": $p} + (if $d != "" then {"details": $d} else {} end)]')
    total=$((total + 1))
    if [ "$check_passed" = "true" ]; then
      passed=$((passed + 1))
    else
      failed=$((failed + 1))
    fi
  }

  # --- Post comments ---
  local comment_count
  comment_count=$(echo "$actions" | jq '.comments | length // 0')
  local i=0
  while [ "$i" -lt "$comment_count" ]; do
    local comment_file_path comment_line comment_content
    comment_file_path=$(echo "$actions" | jq -r ".comments[$i].file // \"\"")
    comment_line=$(echo "$actions" | jq -r ".comments[$i].line // \"\"")
    comment_content=$(echo "$actions" | jq -r ".comments[$i].content")

    local check_name="comment_$((i + 1))"
    local body

    if [ -n "$comment_file_path" ]; then
      # File-level comment — create thread with file context
      local line_num=${comment_line:-1}
      body=$(jq -n \
        --arg content "$comment_content" \
        --arg filepath "$comment_file_path" \
        --argjson line "$line_num" \
        '{
          "comments": [{"parentCommentId": 0, "content": $content, "commentType": "text"}],
          "status": "active",
          "threadContext": {
            "filePath": $filepath,
            "rightFileStart": {"line": $line, "offset": 1},
            "rightFileEnd": {"line": $line, "offset": 1}
          }
        }')

      local tmp_body
      tmp_body=$(mktemp /tmp/az-pr-body-XXXXXX.json)
      echo "$body" > "$tmp_body"

      local rc=0
      AZ_OUT=$(az devops invoke \
        --area git \
        --resource pullRequestThreads \
        --route-parameters project="$PROJECT" repositoryId="$REPO_ID" pullRequestId="$pr_id" \
        --api-version 7.1 \
        --http-method POST \
        --in-file "$tmp_body" \
        -o json 2>/dev/null) || rc=$?
      rm -f "$tmp_body"

      if [ "$rc" -eq 0 ]; then
        local thread_id
        thread_id=$(echo "$AZ_OUT" | jq -r '.id // ""')
        if [ -n "$thread_id" ] && [ "$thread_id" != "null" ]; then
          append_check "$check_name" true "File comment on ${comment_file_path}:${line_num}"
        else
          append_check "$check_name" false "File comment on ${comment_file_path}:${line_num} — no thread ID returned"
        fi
      else
        append_check "$check_name" false "File comment on ${comment_file_path}:${line_num} — az CLI error"
      fi
    else
      # General PR-level comment
      body=$(jq -n \
        --arg content "$comment_content" \
        '{
          "comments": [{"parentCommentId": 0, "content": $content, "commentType": "text"}],
          "status": "active"
        }')

      local tmp_body
      tmp_body=$(mktemp /tmp/az-pr-body-XXXXXX.json)
      echo "$body" > "$tmp_body"

      local rc=0
      AZ_OUT=$(az devops invoke \
        --area git \
        --resource pullRequestThreads \
        --route-parameters project="$PROJECT" repositoryId="$REPO_ID" pullRequestId="$pr_id" \
        --api-version 7.1 \
        --http-method POST \
        --in-file "$tmp_body" \
        -o json 2>/dev/null) || rc=$?
      rm -f "$tmp_body"

      if [ "$rc" -eq 0 ]; then
        local thread_id
        thread_id=$(echo "$AZ_OUT" | jq -r '.id // ""')
        if [ -n "$thread_id" ] && [ "$thread_id" != "null" ]; then
          append_check "$check_name" true "General comment"
        else
          append_check "$check_name" false "General comment — no thread ID returned"
        fi
      else
        append_check "$check_name" false "General comment — az CLI error"
      fi
    fi

    i=$((i + 1))
  done

  # --- Resolve threads ---
  local resolution_count
  resolution_count=$(echo "$actions" | jq '.resolutions | length // 0')
  local j=0
  while [ "$j" -lt "$resolution_count" ]; do
    local thread_id
    thread_id=$(echo "$actions" | jq -r ".resolutions[$j]")
    local check_name="resolve_${thread_id}"

    local tmp_resolve
    tmp_resolve=$(mktemp /tmp/az-pr-resolve-XXXXXX.json)
    printf '{"status":"fixed"}' > "$tmp_resolve"

    local rc=0
    AZ_OUT=$(az devops invoke \
      --area git \
      --resource pullRequestThreads \
      --route-parameters project="$PROJECT" repositoryId="$REPO_ID" pullRequestId="$pr_id" threadId="$thread_id" \
      --api-version 7.1 \
      --http-method PATCH \
      --in-file "$tmp_resolve" \
      -o json 2>/dev/null) || rc=$?
    rm -f "$tmp_resolve"

    if [ "$rc" -eq 0 ]; then
      local status
      status=$(echo "$AZ_OUT" | jq -r '.status // ""')
      if [ "$status" = "fixed" ]; then
        append_check "$check_name" true
      else
        append_check "$check_name" false "Expected status=fixed, got: $status"
      fi
    else
      append_check "$check_name" false "az CLI error"
    fi

    j=$((j + 1))
  done

  # --- Set vote ---
  local vote_value
  vote_value=$(echo "$actions" | jq -r '.vote // ""')
  if [ -n "$vote_value" ] && [ "$vote_value" != "null" ]; then
    local vote_str
    case "$vote_value" in
      10)   vote_str="approve" ;;
      5)    vote_str="approve-with-suggestions" ;;
      0)    vote_str="reset" ;;
      -5)   vote_str="wait-for-author" ;;
      -10)  vote_str="reject" ;;
      *)
        append_check "vote" false "Unknown vote code: $vote_value"
        vote_str=""
        ;;
    esac

    if [ -n "$vote_str" ]; then
      local rc=0
      AZ_OUT=$(az repos pr set-vote --id "$pr_id" --vote "$vote_str" -o json 2>/dev/null) || rc=$?

      if [ "$rc" -eq 0 ]; then
        append_check "vote" true "Vote set to $vote_value ($vote_str)"
      else
        append_check "vote" false "az repos pr set-vote failed (vote=$vote_str)"
      fi
    fi
  fi

  # --- Output summary ---
  jq -n \
    --arg script "review-actions" \
    --arg ts "$timestamp" \
    --argjson checks "$checks_json" \
    --argjson total "$total" \
    --argjson passed "$passed" \
    --argjson failed "$failed" \
    '{
      "script": $script,
      "timestamp": $ts,
      "checks": $checks,
      "summary": {"total": $total, "passed": $passed, "failed": $failed}
    }'
}

# --- Main ---

if [ $# -lt 1 ]; then
  usage
  exit 1
fi

subcmd=$1
shift

case "$subcmd" in
  context)        [ $# -ge 1 ] || { echo "Usage: az-pr.sh context <pr-id>" >&2; exit 1; }; cmd_context "$1" ;;
  threads)        [ $# -ge 1 ] || { echo "Usage: az-pr.sh threads <pr-id>" >&2; exit 1; }; cmd_threads "$1" ;;
  threads-json)   [ $# -ge 1 ] || { echo "Usage: az-pr.sh threads-json <pr-id>" >&2; exit 1; }; cmd_threads_json "$1" ;;
  active)         [ $# -ge 1 ] || { echo "Usage: az-pr.sh active <pr-id>" >&2; exit 1; }; cmd_active "$1" ;;
  overview)       [ $# -ge 1 ] || { echo "Usage: az-pr.sh overview <pr-id>" >&2; exit 1; }; cmd_overview "$1" ;;
  files)          [ $# -ge 1 ] || { echo "Usage: az-pr.sh files <pr-id>" >&2; exit 1; }; cmd_files "$1" ;;
  diff)           [ $# -ge 1 ] || { echo "Usage: az-pr.sh diff <pr-id>" >&2; exit 1; }; cmd_diff "$1" ;;
  review-actions) [ $# -ge 2 ] || { echo "Usage: az-pr.sh review-actions <pr-id> <actions.json>" >&2; exit 1; }; cmd_review_actions "$1" "$2" ;;
  -h|--help|help) usage ;;
  *) echo "Unknown subcommand: $subcmd" >&2; usage; exit 1 ;;
esac
