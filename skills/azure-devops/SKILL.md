---
name: azure-devops
description: "Azure DevOps PR workflows via az CLI and wrapper script. Use for reviewing PRs, listing threads/comments, checking status, posting comments, voting, or any az repos/az devops operation. Triggers on 'review PR', 'PR comments', 'PR threads', 'check PR', 'az repos', 'az devops'."
---

# Azure DevOps CLI

Patterns for Azure DevOps CLI (`az repos`, `az devops invoke`, `scripts/az-pr.sh`). Use `jq` for JSON processing — no Python fallbacks.

## First-Run Setup

Before first use, verify `az` CLI is authenticated:

```bash
az account show
```

If not authenticated, run `az login`.

Then offer to add auto-approve rules for read-only operations. Use AskUserQuestion to ask where to add them:
- **Global** — `~/.claude/settings.json` (applies to all projects)
- **Project-level** — `.claude/settings.local.json` (this repo only)

Permission rules to add under `"permissions.allow"`:

```json
[
  "Bash(az repos pr show *)",
  "Bash(az repos pr list *)",
  "Bash(az repos pr diff *)",
  "Bash(az repos pr reviewer list *)",
  "Bash(az repos show *)",
  "Bash(az devops configure *)",
  "Bash(az devops invoke *)",
  "Bash(*/az-pr.sh *)"
]
```

Write safety comes from AskUserQuestion — the skill always shows write details and asks for confirmation before executing POST/PATCH operations. The Bash permission prompt alone doesn't give users enough context to make informed decisions, so the skill gates writes at a higher level.

## Permission Model

**Read operations — execute directly, no confirmation needed:**
- `az repos pr show`, `list`, `diff`
- `az repos pr reviewer list`
- `az devops invoke` with GET
- `scripts/az-pr.sh` (all subcommands)

**Write operations — use AskUserQuestion to confirm first:**
- `az repos pr set-vote` — show the vote value, ask to confirm
- `az devops invoke --http-method POST` — show comment content, ask to confirm
- `az devops invoke --http-method PATCH` — show what's being resolved/changed, ask to confirm
- `az repos pr update`, `create` — show the changes, ask to confirm

Use AskUserQuestion (not just the Bash permission prompt) to give the user clear context about what the write will do before executing it.

## Wrapper Script

For PR review workflows, prefer `scripts/az-pr.sh` — one Bash call instead of 6+ separate `az` commands.

| Subcommand | Output |
|---|---|
| `context <pr-id>` | Project, repo ID, branches, author (JSON) |
| `threads <pr-id>` | Non-system threads (human-readable) |
| `threads-json <pr-id>` | Non-system threads (structured JSON) |
| `active <pr-id>` | Active/unresolved threads only |
| `overview <pr-id>` | Full overview: context + reviewers + threads |
| `files <pr-id>` | Changed files list |
| `diff <pr-id>` | Full diff via git |

```bash
# Typical review start — one call gets everything
scripts/az-pr.sh overview 12345
```

The script derives the project name from the PR itself (via `repository.project.name`), so it works correctly across repos without relying on `az devops configure` defaults.

## Project Discovery

Derive the project name from the PR — never rely on `az devops configure --list`.

```bash
# Preferred: from a PR (handles spaces, works across repos)
PROJECT=$(az repos pr show --id {PR_ID} --query 'repository.project.name' -o tsv)

# Alternative: from a repo name
PROJECT=$(az repos show --repository my-repo --query 'project.name' -o tsv)
```

The `az devops configure --list | grep project` pattern is unreliable when working across multiple projects or orgs.

## Available Commands

| Operation | Command | Notes |
|---|---|---|
| PR details | `az repos pr show` | Native CLI |
| List PRs | `az repos pr list` | Native CLI |
| Create PR | `az repos pr create` | Native CLI |
| Update PR | `az repos pr update` | Native CLI |
| Set vote | `az repos pr set-vote` | Native CLI |
| List reviewers | `az repos pr reviewer list` | Native CLI |
| PR diff (files) | `az repos pr diff` | Native CLI, limited output |
| PR diff (content) | `git diff` | Use three-dot diff locally |
| PR threads | `az devops invoke` | **No native command** |
| PR comments | `az devops invoke` | **No native command** |
| Create comment | `az devops invoke --http-method POST` | **No native command** |

**Key gap:** `az repos pr thread` and `az repos pr comment` do not exist. Use `az devops invoke` with the REST API for all thread/comment operations.

## Core Recipes

### PR Overview

```bash
az repos pr show --id {PR_ID} --query "{
  id: pullRequestId,
  title: title,
  status: status,
  merge: mergeStatus,
  isDraft: isDraft,
  source: sourceRefName,
  target: targetRefName,
  author: createdBy.displayName,
  reviewers: reviewers[].{name: displayName, vote: vote}
}" -o json
```

### PR Threads (Human-Readable)

```bash
az devops invoke \
  --area git \
  --resource pullRequestThreads \
  --route-parameters project="$PROJECT" repositoryId="$REPO_ID" pullRequestId={PR_ID} \
  --api-version 7.1 \
  -o json 2>/dev/null | jq -r '
  .value[]
  | select(.comments[0].commentType != "system")
  | "--- Thread \(.id) [\(.status // "none")] \(.threadContext.filePath // "(general)") ---",
    (.comments[]
      | select(.commentType != "system")
      | "  \(.author.displayName): \(.content // "" | split("\n")[0])")'
```

### PR File Changes

```bash
az repos pr diff --id {PR_ID} -o json 2>/dev/null | jq -r '.changes[] | "\(.changeType): \(.item.path)"'
```

### Create Comment

```bash
RESULT=$(az devops invoke \
  --area git \
  --resource pullRequestThreads \
  --route-parameters project="$PROJECT" repositoryId="$REPO_ID" pullRequestId={PR_ID} \
  --api-version 7.1 \
  --http-method POST \
  --in-file /dev/stdin \
  -o json <<'EOF'
{
  "comments": [{ "parentCommentId": 0, "content": "Comment text", "commentType": "text" }],
  "status": "active"
}
EOF
)

# Verify
THREAD_ID=$(echo "$RESULT" | jq -r '.id')
if [ "$THREAD_ID" = "null" ] || [ -z "$THREAD_ID" ]; then
  echo "Error: Thread creation failed" >&2
fi
```

### Reply to Thread

```bash
RESULT=$(az devops invoke \
  --area git \
  --resource pullRequestThreadComments \
  --route-parameters project="$PROJECT" repositoryId="$REPO_ID" pullRequestId={PR_ID} threadId={THREAD_ID} \
  --api-version 7.1 \
  --http-method POST \
  --in-file /dev/stdin \
  -o json <<'EOF'
{
  "content": "Reply text",
  "parentCommentId": 0,
  "commentType": "text"
}
EOF
)

# Verify
COMMENT_ID=$(echo "$RESULT" | jq -r '.id')
if [ "$COMMENT_ID" = "null" ] || [ -z "$COMMENT_ID" ]; then
  echo "Error: Reply failed" >&2
fi
```

## Extracting IDs

Most recipes need `{PROJECT}`, `{REPO_ID}`, and `{PR_ID}`. Extract them from the PR:

```bash
REPO_ID=$(az repos pr show --id {PR_ID} --query 'repository.id' -o tsv)
PROJECT=$(az repos pr show --id {PR_ID} --query 'repository.project.name' -o tsv)
```

Or use the wrapper script — `scripts/az-pr.sh context {PR_ID}` returns both along with branch info.

## JSON Output

Use `jq` as the primary JSON tool. Two approaches depending on the need:

**jq** — formatting, filtering, transforming:
```bash
az repos pr show --id {PR_ID} -o json 2>/dev/null | jq '.title'
```

**JMESPath `--query` + `-o tsv`** — extracting single values into shell variables:
```bash
REPO_ID=$(az repos pr show --id {PR_ID} --query 'repository.id' -o tsv)
```

Recipes use `2>/dev/null` before `jq` for brevity. See `references/error-handling.md` for the `az_safe` pattern that surfaces errors instead of swallowing them.

## Gotchas

1. **No native thread/comment commands** — `az repos pr thread` and `az repos pr comment` do not exist. Always use `az devops invoke` with `--area git --resource pullRequestThreads`.

2. **Stderr corrupts JSON pipelines** — `az` emits warnings to stderr that break `jq` parsing. Use the `az_safe` pattern from `references/error-handling.md` or `2>/dev/null` when you're confident the command will succeed.

3. **Quote project names** — Always use `project="$PROJECT"` in `--route-parameters`. Unquoted names with spaces split into separate arguments.

4. **Don't rely on `az devops configure` for project name** — Derive from the PR via `--query 'repository.project.name'`. Configure defaults are unreliable across repos.

5. **Verify writes** — POST/PATCH responses include the created resource. Check `.id` is non-null to confirm the operation succeeded. See `references/error-handling.md`.

6. **Vote codes are integers** — Map: `10=approved`, `5=approved with suggestions`, `0=no vote`, `-5=waiting`, `-10=rejected`.

7. **API version matters** — Use `--api-version 7.1` or later. Older versions may return different response shapes.

8. **`az devops invoke` covers reads and writes** — The permission rule allows both GET and POST/PATCH calls without a Bash prompt. This is intentional — AskUserQuestion gates all writes with full context (comment text, resolution status, etc.) before execution. The Bash prompt would just show a raw command string, which isn't useful for informed approval.

## Reference

- `references/pr-recipes.md` — Full recipe collection with response structures, REST API mappings, inline comments, thread resolution
- `references/error-handling.md` — `az_safe` pattern, error categories, verification after writes
