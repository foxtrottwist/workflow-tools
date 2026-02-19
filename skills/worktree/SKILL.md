---
name: worktree
description: "Create isolated git worktrees for parallel sessions. Use when starting new branches, needing parallel sessions, isolating work, or working on multiple features simultaneously."
---

# Worktree

Create isolated git worktrees for parallel Claude Code sessions. Each worktree gets its own working directory, enabling concurrent work without conflicts.

## Commands

### Create

Set up a new worktree with branch isolation.

**1. Directory selection**

Check for an existing worktree directory in this order:
1. `.worktrees/` in the repo root
2. `worktrees/` in the repo root
3. CLAUDE.md preference (if specified)
4. Ask the user

**2. Safety check**

Verify the worktree directory is gitignored:
```
git check-ignore -q <directory>
```
If not ignored, warn the user and offer to add it to `.gitignore`. Project-local worktrees should never be tracked.

**3. Create the worktree**

```
git worktree add <directory>/<branch-name> -b <branch-name>
```

Branch naming: use the user's preferred name. If not specified, suggest a descriptive name based on the task (e.g., `feature/add-auth`, `fix/login-redirect`).

**4. Project setup**

Auto-detect project type and install dependencies:

| Marker | Action |
|--------|--------|
| `package.json` | `npm install` (or `yarn`/`pnpm` if lockfile present) |
| `Cargo.toml` | `cargo build` |
| `go.mod` | `go mod download` |
| `requirements.txt` | `pip install -r requirements.txt` |
| `Gemfile` | `bundle install` |
| `Package.swift` | `swift build` |

Skip if the user requests it.

**5. Baseline verification**

Run the project's test suite in the new worktree to confirm a clean starting point:
```
cd <worktree-path> && <test command>
```

Report results. If tests fail on a clean branch, the problem is in main — flag it before starting work.

### List

Show all active worktrees:
```
git worktree list
```

Include branch name and status (clean/dirty) for each.

### Finish

Complete work in a worktree. See `references/branch-finish.md` for the full merge/PR/keep/discard workflow.

**Quick summary:**
1. Ensure all changes are committed
2. Choose resolution: merge, PR, keep branch, or discard
3. Clean up: `git worktree remove <path>`
4. Optionally delete the branch: `git branch -d <branch-name>`

## Notes

- Worktrees share the same git history and objects — they're lightweight
- Each worktree has its own working directory, index, and HEAD
- You cannot have the same branch checked out in two worktrees simultaneously
- Worktrees are local only — they don't affect the remote

## iter Integration

iter can map `worktree` to tasks that need branch isolation, but it's not mandatory. The skill works standalone for ad-hoc branching.
