# Error Handling — Azure DevOps CLI

Patterns for handling `az` CLI errors without swallowing useful diagnostics.

## The Problem with `2>/dev/null`

Recipes use `2>/dev/null` before `jq` pipes for brevity — it prevents stderr warnings from corrupting JSON. But it also hides real errors (auth failures, 404s, permission issues). In practice, use the `az_safe` pattern or the wrapper script instead.

## `az_safe` Pattern

Captures stderr to a temp file, checks the exit code, and surfaces categorized errors. Used in `scripts/az-pr.sh` and available as a pattern for custom scripts.

```bash
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

# Usage
az_safe az repos pr show --id 12345 -o json
echo "$AZ_OUT" | jq '.title'
```

## Common Error Categories

| Pattern in stderr | Category | What to do |
|---|---|---|
| `Please run 'az login'` | Auth expired | Run `az login` |
| `could not be found`, `does not exist`, `404` | Resource missing | Verify the PR/repo/project ID |
| `TF200016`, `project.*not found` | Project mismatch | Derive project from PR, don't rely on defaults |
| `is not connected to a terminal` | Interactive prompt | Add `--only-show-errors` or check auth state first |
| `unrecognized arguments` | API version mismatch | Use `--api-version 7.1` |

## Verification After Writes

POST and PATCH operations return a response body. Always check that the operation succeeded — don't assume a 0 exit code means the content was created correctly.

```bash
# After creating a thread
RESULT=$(az devops invoke ... --http-method POST --in-file /dev/stdin -o json <<'EOF'
{ "comments": [{ "content": "text", "commentType": "text" }], "status": "active" }
EOF
)

THREAD_ID=$(echo "$RESULT" | jq -r '.id')
if [ "$THREAD_ID" = "null" ] || [ -z "$THREAD_ID" ]; then
  echo "Error: Thread creation failed — response had no ID" >&2
  echo "$RESULT" | jq . >&2
fi
```

```bash
# After replying to a thread
RESULT=$(az devops invoke ... --http-method POST --in-file /dev/stdin -o json <<'EOF'
{ "content": "reply text", "commentType": "text" }
EOF
)

COMMENT_ID=$(echo "$RESULT" | jq -r '.id')
if [ "$COMMENT_ID" = "null" ] || [ -z "$COMMENT_ID" ]; then
  echo "Error: Reply failed — response had no ID" >&2
  echo "$RESULT" | jq . >&2
fi
```

## When to Use Each Approach

| Situation | Approach |
|---|---|
| PR review workflow (reads) | Use `scripts/az-pr.sh` — error handling built in |
| One-off read in a recipe | `az_safe` pattern or `2>/dev/null` with awareness of the trade-off |
| Write operations (POST/PATCH) | Capture response, verify `.id` is non-null |
| Debugging a failing command | Run without any stderr redirection to see the full error |
