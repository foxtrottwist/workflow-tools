# Hookify Rule: warn-untested-claim

- **Pattern:** `\b(tests should pass|build should succeed|I('m| am) confident (this|it) works)\b`
- **Scope:** file
- **Action:** warn
- **Enabled:** true
- **Message:** Claim made without verification evidence. Run the actual command (test suite, build, etc.) and include the output.
