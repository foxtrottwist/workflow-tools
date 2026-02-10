---
name: azure-devops
description: "This skill should be used when working with Azure DevOps pull requests, reviewing PRs, listing PR comments or threads, checking PR status, creating PR comments, or using the az repos CLI. Triggers on 'review PR', 'PR comments', 'PR threads', 'check PR status', 'az repos', 'az devops', or any Azure DevOps CLI operation."
---

# Azure DevOps CLI

Recipes and patterns for Azure DevOps CLI (`az repos`, `az devops invoke`). Use `jq` for JSON processing — no Python fallbacks.

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

Always pipe through `2>/dev/null` before `jq` to prevent stderr warnings from corrupting the JSON pipeline.

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
  --route-parameters project={PROJECT} repositoryId={REPO_ID} pullRequestId={PR_ID} \
  --api-version 7.1 \
  -o json 2>/dev/null | jq -r '
  .value[]
  | select(.comments[0].commentType != "system")
  | "--- Thread \(.id) [\(.status // "none")] \(.threadContext.filePath // "(general)") ---",
    (.comments[]
      | select(.commentType != "system")
      | "  \(.author.displayName): \(.content // "" | split("\n")[0])")'
```

### PR Threads (Structured JSON)

```bash
az devops invoke \
  --area git \
  --resource pullRequestThreads \
  --route-parameters project={PROJECT} repositoryId={REPO_ID} pullRequestId={PR_ID} \
  --api-version 7.1 \
  -o json 2>/dev/null | jq '[
    .value[]
    | select(.comments[0].commentType == "system" | not)
    | {
        id,
        status,
        file: .threadContext.filePath,
        comments: [
          .comments[]
          | select(.commentType == "system" | not)
          | {
              author: .author.displayName,
              content: (.content // "" | split("\n")[0])
            }
        ]
      }
  ]'
```

### PR File Changes

```bash
# File list via REST
az repos pr diff --id {PR_ID} -o json 2>/dev/null | jq -r '.changes[].item.path'

# Full diff content — use git locally
TARGET=$(az repos pr show --id {PR_ID} --query 'targetRefName' -o tsv | sed 's|refs/heads/||')
SOURCE=$(az repos pr show --id {PR_ID} --query 'sourceRefName' -o tsv | sed 's|refs/heads/||')
git fetch origin "$TARGET" "$SOURCE"
git diff "origin/$TARGET...origin/$SOURCE"
```

### PR Reviewer Votes

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

### Create PR Comment

```bash
az devops invoke \
  --area git \
  --resource pullRequestThreads \
  --route-parameters project={PROJECT} repositoryId={REPO_ID} pullRequestId={PR_ID} \
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
```

### Reply to Existing Thread

```bash
az devops invoke \
  --area git \
  --resource pullRequestThreadComments \
  --route-parameters project={PROJECT} repositoryId={REPO_ID} pullRequestId={PR_ID} threadId={THREAD_ID} \
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
```

## Extracting IDs

Most recipes need `{PROJECT}`, `{REPO_ID}`, and `{PR_ID}`. Extract them:

```bash
# From a known PR ID
REPO_ID=$(az repos pr show --id {PR_ID} --query 'repository.id' -o tsv)
PROJECT=$(az devops configure --list 2>/dev/null | grep 'project' | awk '{print $NF}')
```

If project has spaces, quote it in `--route-parameters`: `project="My Project Name"`.

## Gotchas

1. **No native thread/comment commands** — `az repos pr thread` and `az repos pr comment` do not exist. Always use `az devops invoke` with `--area git --resource pullRequestThreads`.

2. **Stderr corrupts JSON pipelines** — Always add `2>/dev/null` before piping `az` output to `jq`. Azure CLI emits warnings to stderr that break JSON parsing.

3. **Quote project names with spaces** — `--route-parameters project="My Project"` not `project=My Project`. Unquoted spaces split into separate arguments.

4. **Use `!=` for jq negation** — `select(.x != "y")` is more reliable than `select(.x == "y" | not)`. Both work, but `!=` is clearer and avoids edge cases with null.

5. **Vote codes are integers** — Map: `10=approved`, `5=approved with suggestions`, `0=no vote`, `-5=waiting`, `-10=rejected`.

6. **API version matters** — Use `--api-version 7.1` or later. Older versions may return different response shapes.

7. **Configure defaults once** — Run `az devops configure --defaults organization=URL project=NAME` to skip `--org` and `--project` on every command.

## Reference

See `references/pr-recipes.md` for detailed recipes with response structures, REST API endpoint mappings, and `az devops invoke` route parameter reference.
