# Hookify Rule: warn-unverified-completion

- **Pattern:** `\b(should work|probably (works?|fixed)|seems (correct|fine|to work)|likely (works?|fixed))\b`
- **Scope:** file
- **Action:** warn
- **Enabled:** true
- **Message:** Unverified completion claim detected. Run the verification command and confirm the output before claiming work is done. See iter verification gates.
