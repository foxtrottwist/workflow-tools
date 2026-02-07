#!/bin/bash
# Verify iterative workflow considerations before stopping
# Used by Stop hook
#
# With native Task system handling state, this hook provides
# a lightweight reminder to check for incomplete work.

# Check for guardrails file (indicates iterative work has been done)
if [ -f ".claude/guardrails.md" ]; then
  echo "Note: .claude/guardrails.md exists — review accumulated lessons before stopping."
fi

exit 0
