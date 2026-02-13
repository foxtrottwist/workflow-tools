#!/usr/bin/env bash
# az-pr.sh — Read-only Azure DevOps PR operations bundled for fewer permission prompts.
# All subcommands are read-only. Write operations (vote, comment, resolve) stay in SKILL.md recipes.
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

Read-only PR operations for Azure DevOps.

Subcommands:
  context <pr-id>       Project, repo ID, branches, author
  threads <pr-id>       Non-system threads (human-readable)
  threads-json <pr-id>  Non-system threads (structured JSON)
  active <pr-id>        Active/unresolved threads only
  overview <pr-id>      Full PR overview: context + threads + reviewers
  files <pr-id>         List changed files
  diff <pr-id>          Full diff content via git
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

  az_safe az repos pr diff --id "$pr_id" -o json
  echo "$AZ_OUT" | jq -r '.changes[] | "\(.changeType): \(.item.path)"'
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

# --- Main ---

if [ $# -lt 1 ]; then
  usage
  exit 1
fi

subcmd=$1
shift

case "$subcmd" in
  context)      [ $# -ge 1 ] || { echo "Usage: az-pr.sh context <pr-id>" >&2; exit 1; }; cmd_context "$1" ;;
  threads)      [ $# -ge 1 ] || { echo "Usage: az-pr.sh threads <pr-id>" >&2; exit 1; }; cmd_threads "$1" ;;
  threads-json) [ $# -ge 1 ] || { echo "Usage: az-pr.sh threads-json <pr-id>" >&2; exit 1; }; cmd_threads_json "$1" ;;
  active)       [ $# -ge 1 ] || { echo "Usage: az-pr.sh active <pr-id>" >&2; exit 1; }; cmd_active "$1" ;;
  overview)     [ $# -ge 1 ] || { echo "Usage: az-pr.sh overview <pr-id>" >&2; exit 1; }; cmd_overview "$1" ;;
  files)        [ $# -ge 1 ] || { echo "Usage: az-pr.sh files <pr-id>" >&2; exit 1; }; cmd_files "$1" ;;
  diff)         [ $# -ge 1 ] || { echo "Usage: az-pr.sh diff <pr-id>" >&2; exit 1; }; cmd_diff "$1" ;;
  -h|--help|help) usage ;;
  *) echo "Unknown subcommand: $subcmd" >&2; usage; exit 1 ;;
esac
