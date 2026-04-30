## Gemini-Specific

- Base instructions are managed by NixOS in `~/.gemini/instructions.md`.
- `GEMINI.md` imports this file and is mutable for auto-memories.

### Delegation Mandate

- For Cypress-to-Playwright porting, or mass syntax translation across multiple files: **NEVER** do it directly in main chat.
- **ALWAYS** use `invoke_agent` to spawn the `generalist` subagent to do the heavy lifting in the background.
- Tell `generalist` to use existing Page Objects from `e2e/po/` and **NOT** run/verify tests.
- Monko handles verification and fixing only after `generalist` finishes the port.
