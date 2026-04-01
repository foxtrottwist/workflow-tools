---
name: release
description: "Cut and publish a versioned release of the workflow-tools plugin. Use when bumping the plugin version, tagging a release, publishing to GitHub, or packaging skills for distribution. Triggers on: 'release', 'cut a release', 'publish version', 'bump version', 'tag and release'."
---

# Release

Build, version, tag, and publish a new release of the workflow-tools plugin to GitHub.

## Procedure

1. **Confirm bump type and changelog.** Ask for patch, minor, or major if not stated. Run `git log $(git describe --tags --abbrev=0)..HEAD --oneline` to summarize what changed since the last tag. Present the summary and the new version string for confirmation before proceeding.

2. **Validate.** Run `bash build.sh` from the repo root. Stop if it exits non-zero — do not proceed past a failed build.

3. **Package.** Run `bash package.sh` from the repo root. Stop if it exits non-zero.

4. **Bump version.** Update the `"version"` field to the new version string in both:
   - `.claude-plugin/plugin.json`
   - `.claude-plugin/marketplace.json`
   Both files must have the same version string.

5. **Commit.** Stage both version files and commit: `git add .claude-plugin/plugin.json .claude-plugin/marketplace.json && git commit -m "chore: release vX.Y.Z"`

6. **Tag.** `git tag vX.Y.Z`

7. **Push.** `git push && git push --tags`

8. **Create GitHub release.** `gh release create vX.Y.Z dist/*.skill --generate-notes --title "vX.Y.Z"`

## Worked Example

User: "cut a patch release"

Current version: 0.24.0. New version: 0.25.0.

```
# Step 1 — confirm bump and summarize changes
$ git log $(git describe --tags --abbrev=0)..HEAD --oneline
ba20fb6 chore: trim CLAUDE.md from 87 to 26 lines
7738b98 feat: add scaffold skill, remove swift-dev hub

Bump type: patch → 0.24.0 → 0.25.0
Proceed? [y]

# Step 2 — validate
$ bash build.sh
==> Validating workflow-tools plugin
  OK: .claude-plugin/plugin.json
  ...
==> Validation passed

# Step 3 — package
$ bash package.sh
==> Packaging workflow-tools skills
  ...
==> Packaged 21 skills to dist/

# Step 4 — bump version in both files
# .claude-plugin/plugin.json: "version": "0.24.0" → "0.25.0"
# .claude-plugin/marketplace.json: "version": "0.24.0" → "0.25.0"

# Step 5 — commit
$ git add .claude-plugin/plugin.json .claude-plugin/marketplace.json
$ git commit -m "chore: release v0.25.0"
[main abc1234] chore: release v0.25.0

# Step 6 — tag
$ git tag v0.25.0

# Step 7 — push
$ git push && git push --tags
...
* [new tag] v0.25.0 -> v0.25.0

# Step 8 — GitHub release
$ gh release create v0.25.0 dist/*.skill --generate-notes --title "v0.25.0"
https://github.com/Foxtrottwist/workflow-tools/releases/tag/v0.25.0
```

## Constraints

- Always run `build.sh` before `package.sh` — packaging a broken plugin silently produces bad artifacts.
- Never skip the version bump confirmation — both files must be updated to the same version string before committing.
- Never tag before the commit is on the branch — tag the commit, not the working tree.
- Do not push without tagging first — `git push` and `git push --tags` are a single atomic step in this workflow.
- Use `dist/*.skill` glob in the `gh release create` command — do not enumerate files manually.
