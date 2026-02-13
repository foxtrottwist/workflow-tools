# PR Recipes — Azure DevOps CLI

Copy-paste-ready recipes. Replace `{PR_ID}`, `{REPO_ID}`, `{PROJECT}` with actual values.

> **Tip:** For read-only PR review workflows, prefer `scripts/az-pr.sh` — it bundles multiple calls into one command with built-in error handling. These recipes are for custom operations and write workflows.

> **Error handling:** Recipes use `2>/dev/null` before `jq` pipes for brevity. In practice, use the `az_safe` pattern from `references/error-handling.md` to avoid swallowing real errors.

## Setup

### Extract IDs from a PR

```bash
# Get repo ID and project from a known PR
REPO_ID=$(az repos pr show --id {PR_ID} --query 'repository.id' -o tsv)
PROJECT=$(az repos pr show --id {PR_ID} --query 'repository.project.name' -o tsv)
```

### Discovering the Project Name

Three methods, in order of preference:

```bash
# 1. From a PR (most reliable — works across repos and handles spaces)
PROJECT=$(az repos pr show --id {PR_ID} --query 'repository.project.name' -o tsv)

# 2. From a repo name
PROJECT=$(az repos show --repository my-repo --query 'project.name' -o tsv)

# 3. From configured defaults (unreliable if you work across multiple orgs/projects)
az devops configure --list
```

Method 1 is preferred because it derives the project directly from the PR's metadata. The `az devops configure --list` approach breaks when switching between repos in different projects.

### Configure Defaults (One-Time)

```bash
az devops configure --defaults organization=https://dev.azure.com/{ORG} project="{PROJECT}"
az devops configure --list  # Verify
```

---

## PR Details

### Full Overview

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

### Single Field Extraction

```bash
# Status
az repos pr show --id {PR_ID} --query 'status' -o tsv

# Merge status
az repos pr show --id {PR_ID} --query 'mergeStatus' -o tsv

# Repo ID (for use in az devops invoke)
az repos pr show --id {PR_ID} --query 'repository.id' -o tsv

# Branch names (cleaned)
az repos pr show --id {PR_ID} --query 'sourceRefName' -o tsv | sed 's|refs/heads/||'
az repos pr show --id {PR_ID} --query 'targetRefName' -o tsv | sed 's|refs/heads/||'
```

### PR List with Filters

```bash
# Active PRs
az repos pr list --status active -o table

# By creator, most recent
az repos pr list --creator "user@org.com" --status completed --top 10 -o table

# Filter with JMESPath
az repos pr list --query "[?isDraft==\`false\` && status=='active']" -o json
```

---

## PR Threads and Comments

All thread/comment operations require `az devops invoke` — no native CLI commands exist.

### List Threads (Human-Readable)

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

**Output:**
```
--- Thread 123456 [active] /src/components/Button.tsx ---
  Alice: Should we add a loading state here?
  Bob: Good idea, I'll add that.
--- Thread 789012 [resolved] (general) ---
  Carol: LGTM overall, just minor comments
```

### List Threads (Structured JSON)

```bash
az devops invoke \
  --area git \
  --resource pullRequestThreads \
  --route-parameters project="$PROJECT" repositoryId="$REPO_ID" pullRequestId={PR_ID} \
  --api-version 7.1 \
  -o json 2>/dev/null | jq '[
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
```

### Active Threads Only

```bash
az devops invoke \
  --area git \
  --resource pullRequestThreads \
  --route-parameters project="$PROJECT" repositoryId="$REPO_ID" pullRequestId={PR_ID} \
  --api-version 7.1 \
  -o json 2>/dev/null | jq -r '
  .value[]
  | select(.status == "active" and .comments[0].commentType != "system")
  | "[\(.threadContext.filePath // "general")] \(.comments[0].author.displayName): \(.comments[0].content // "" | split("\n")[0])"'
```

### Thread Count (Non-System)

```bash
az devops invoke \
  --area git \
  --resource pullRequestThreads \
  --route-parameters project="$PROJECT" repositoryId="$REPO_ID" pullRequestId={PR_ID} \
  --api-version 7.1 \
  -o json 2>/dev/null | jq '[.value[] | select(.comments[0].commentType != "system")] | length'
```

### Create New Thread (General Comment)

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
  "comments": [
    {
      "parentCommentId": 0,
      "content": "Comment text here",
      "commentType": "text"
    }
  ],
  "status": "active"
}
EOF
)

# Verify the thread was created
THREAD_ID=$(echo "$RESULT" | jq -r '.id')
if [ "$THREAD_ID" = "null" ] || [ -z "$THREAD_ID" ]; then
  echo "Error: Thread creation failed" >&2
  echo "$RESULT" | jq . >&2
fi
```

### Create Inline Comment (On a File/Line)

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
  "comments": [
    {
      "parentCommentId": 0,
      "content": "Inline comment text",
      "commentType": "text"
    }
  ],
  "threadContext": {
    "filePath": "/src/components/Button.tsx",
    "rightFileStart": { "line": 42, "offset": 1 },
    "rightFileEnd": { "line": 42, "offset": 1 }
  },
  "status": "active"
}
EOF
)

# Verify
THREAD_ID=$(echo "$RESULT" | jq -r '.id')
if [ "$THREAD_ID" = "null" ] || [ -z "$THREAD_ID" ]; then
  echo "Error: Inline comment creation failed" >&2
  echo "$RESULT" | jq . >&2
fi
```

### Reply to Existing Thread

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
  "content": "Reply text here",
  "parentCommentId": 0,
  "commentType": "text"
}
EOF
)

# Verify
COMMENT_ID=$(echo "$RESULT" | jq -r '.id')
if [ "$COMMENT_ID" = "null" ] || [ -z "$COMMENT_ID" ]; then
  echo "Error: Reply failed" >&2
  echo "$RESULT" | jq . >&2
fi
```

### Resolve a Thread

```bash
az devops invoke \
  --area git \
  --resource pullRequestThreads \
  --route-parameters project="$PROJECT" repositoryId="$REPO_ID" pullRequestId={PR_ID} threadId={THREAD_ID} \
  --api-version 7.1 \
  --http-method PATCH \
  --in-file /dev/stdin \
  -o json <<'EOF'
{
  "status": "fixed"
}
EOF
```

Thread status values: `active`, `fixed`, `closed`, `wontFix`, `byDesign`, `pending`

---

## PR Reviewers and Votes

### List Reviewers with Vote Status

```bash
az repos pr reviewer list --id {PR_ID} -o json 2>/dev/null | jq -r '
  .[] | "\(.displayName): \(
    if .vote == 10 then "approved"
    elif .vote == 5 then "approved with suggestions"
    elif .vote == 0 then "no vote"
    elif .vote == -5 then "waiting"
    elif .vote == -10 then "rejected"
    else "unknown (\(.vote))"
    end
  )"'
```

### Vote Code Reference

| Code | Meaning |
|------|---------|
| `10` | Approved |
| `5` | Approved with suggestions |
| `0` | No vote |
| `-5` | Waiting for author |
| `-10` | Rejected |

### Cast a Vote

```bash
az repos pr set-vote --id {PR_ID} --vote approve
az repos pr set-vote --id {PR_ID} --vote approve-with-suggestions
az repos pr set-vote --id {PR_ID} --vote wait-for-author
az repos pr set-vote --id {PR_ID} --vote reject
az repos pr set-vote --id {PR_ID} --vote reset
```

---

## PR File Changes

### File List via CLI

```bash
az repos pr diff --id {PR_ID} -o json 2>/dev/null | jq -r '.changes[] | "\(.changeType): \(.item.path)"'
```

### Full Diff via Git (Preferred for Content)

```bash
TARGET=$(az repos pr show --id {PR_ID} --query 'targetRefName' -o tsv | sed 's|refs/heads/||')
SOURCE=$(az repos pr show --id {PR_ID} --query 'sourceRefName' -o tsv | sed 's|refs/heads/||')
git fetch origin "$TARGET" "$SOURCE"
git diff "origin/$TARGET...origin/$SOURCE"
```

### Diff Stats Only

```bash
git diff --stat "origin/$TARGET...origin/$SOURCE"
```

---

## PR Management

### Create PR

```bash
az repos pr create \
  --title "feat: add new feature" \
  --description "Description here" \
  --source-branch feature/my-branch \
  --target-branch main \
  --draft
```

### Update PR

```bash
az repos pr update --id {PR_ID} --title "New title" --description "New description"
az repos pr update --id {PR_ID} --draft true   # Mark as draft
az repos pr update --id {PR_ID} --draft false  # Publish
```

### Complete (Merge) PR

```bash
az repos pr update --id {PR_ID} --status completed
```

### Abandon PR

```bash
az repos pr update --id {PR_ID} --status abandoned
```

---

## REST API Reference

### `az devops invoke` Parameter Mapping

The REST API URL:
```
GET https://dev.azure.com/{org}/{project}/_apis/{area}/repositories/{repoId}/pullRequests/{prId}/{resource}?api-version=7.1
```

Maps to:
```bash
az devops invoke \
  --area {area} \
  --resource {resource} \
  --route-parameters project="$PROJECT" repositoryId="$REPO_ID" pullRequestId={prId} \
  --api-version 7.1
```

### Common Resources

| Area | Resource | Route Params | Description |
|------|----------|-------------|-------------|
| `git` | `pullRequestThreads` | `project`, `repositoryId`, `pullRequestId` | List/create threads |
| `git` | `pullRequestThreadComments` | `project`, `repositoryId`, `pullRequestId`, `threadId` | Reply to threads |
| `git` | `pullRequests` | `project`, `repositoryId` | List/create PRs |
| `git` | `statuses` | `project`, `repositoryId`, `pullRequestId` | PR status checks |

### Response Structures

**PR Thread Response (`pullRequestThreads`):**
```json
{
  "count": 5,
  "value": [
    {
      "id": 123456,
      "status": "active",
      "threadContext": {
        "filePath": "/src/components/Button.tsx",
        "rightFileStart": { "line": 42, "offset": 0 }
      },
      "comments": [
        {
          "id": 1,
          "commentType": "text",
          "author": { "displayName": "Alice" },
          "content": "Comment text here (markdown)",
          "publishedDate": "2025-02-09T..."
        }
      ]
    }
  ]
}
```

**PR Show Response (key fields):**
```json
{
  "pullRequestId": 12345,
  "title": "feat: add feature",
  "status": "active",
  "mergeStatus": "succeeded",
  "isDraft": false,
  "sourceRefName": "refs/heads/feature/branch",
  "targetRefName": "refs/heads/main",
  "createdBy": { "displayName": "Alice" },
  "reviewers": [
    { "displayName": "Reviewer", "vote": 10 }
  ],
  "repository": {
    "id": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx",
    "name": "my-repo",
    "project": {
      "name": "My Project"
    }
  },
  "lastMergeSourceCommit": { "commitId": "abc123" },
  "lastMergeTargetCommit": { "commitId": "def456" }
}
```

---

## jq Patterns Quick Reference

```bash
# Filter out system threads
.value[] | select(.comments[0].commentType != "system")

# Handle null/missing fields with defaults
.status // "none"
.threadContext.filePath // "(general)"
.content // ""

# First line of multi-line content
.content // "" | split("\n")[0]

# Nested filter (remove system comments within a thread)
.comments[] | select(.commentType != "system")

# Count matching items
[.value[] | select(.status == "active")] | length

# Boolean negation (both work, != preferred)
select(.commentType != "system")
select(.commentType == "system" | not)
```

---

## Error Handling

See `references/error-handling.md` for the `az_safe` pattern and detailed error categories.

### Common Failures

| Error | Cause | Fix |
|-------|-------|-----|
| `'thread' is not in the 'az repos pr' command group` | No native thread command | Use `az devops invoke` |
| `jq: error ... null` | Stderr mixed into JSON | Add `2>/dev/null` before pipe (or use `az_safe`) |
| Route param parsed as separate args | Unquoted spaces in project name | Quote: `project="$PROJECT"` |
| Empty or malformed response | Old API version | Use `--api-version 7.1` |
| `Please run 'az login'` | Not authenticated | Run `az login` first |
