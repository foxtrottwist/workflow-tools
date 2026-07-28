---
paths:
  - "hooks/**"
---

# Hook Scripts

- Skip subagents via an `agent_id` guard at the top of the script.
- Fail open: end every script with `|| exit 0` so a hook bug never blocks the user's action.
