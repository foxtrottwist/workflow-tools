# Branch Finish Workflow

Complete and clean up a worktree branch.

## Pre-Flight

Before finishing, verify:
1. All changes are committed (no uncommitted work)
2. Tests pass in the worktree
3. You know the intended resolution

## Resolution Options

### Merge to main

Fast-forward or merge the branch into the base branch.

```bash
# From the main worktree
git checkout main
git merge <branch-name>

# Clean up
git worktree remove <worktree-path>
git branch -d <branch-name>
```

Use when: Work is complete, reviewed, and ready to integrate.

### Create PR

Push the branch and create a pull request for review.

```bash
# From the worktree
git push -u origin <branch-name>
gh pr create --title "..." --body "..."

# Clean up worktree (branch stays for PR)
git worktree remove <worktree-path>
```

Use when: Work needs review before merging.

### Keep branch

Remove the worktree but keep the branch for later.

```bash
git worktree remove <worktree-path>
# Branch remains available: git worktree add <path> <branch-name>
```

Use when: Work is paused, not abandoned.

### Discard

Delete everything — worktree and branch.

```bash
git worktree remove --force <worktree-path>
git branch -D <branch-name>
```

Use when: Work was exploratory and isn't needed. **Confirm with user before discarding.**

## Handling Uncommitted Changes

If the worktree has uncommitted changes when finishing:

1. **Ask the user.** Don't silently commit or discard.
2. Options:
   - Commit with a message ("WIP: [description]")
   - Stash (`git stash` in the worktree)
   - Discard (only if user confirms)

## Cleanup Verification

After removing a worktree, verify:
```bash
git worktree list  # Should not show the removed worktree
ls <worktree-directory>  # Should not exist (or be empty)
```

If the worktree directory persists after `git worktree remove`, it may need manual cleanup. Check for untracked files that weren't managed by git.
