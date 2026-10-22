# OpenCode Global Rules (local-only, not managed by nixos-config)

## Agent cost policy: savings-first

- Always delegate mechanical tasks to the cheapest capable subagent:
  - `explore` (deepseek-v4.1-flash-free): codebase search, file finding, "where is X" questions
  - `general` (deepseek-v4.1-flash-free): bulk multi-step edits from clear patterns
  - `free-assistant` (openrouter/free): quick Q&A, summaries, rewording, formatting
  - `evidence-vision` (openrouter/qwen/qwen3-vl-235b-a22b-instruct, cheap paid): reads images and
    screenshots; converts visible content into written claim cards. The vision seat of the pair
    below
  - `reviewer` (deepseek-v4-pro, paid via OpenRouter credits): first-pass check of another
    subagent's result, run before the parent reviews it. Text-only: it cannot see images, so never
    hand it PNGs expecting visual verdicts
- Keep on the primary model: root-cause analysis, fix design, architecture decisions, anything where
  a wrong-but-confident answer is expensive.
- Launch subagents in background/parallel where possible; keep main context lean.
- Execution goes to subagents by default: test runs, bulk file ops, evidence harvesting, repetitive
  verification loops. The parent's job is to frame the task, review the subagent's output, arbitrate
  disputes, and own the final call before anything gets implemented or committed.
- Model pins live in `~/.config/opencode/opencode.jsonc`. This directory is local-only: never commit
  it anywhere.

## Subagent review

- After any subagent (`explore`, `general`, `free-assistant`, or custom) returns, invoke `reviewer`
  once with the original task and that subagent's output, before using the result.
- Do not invoke `reviewer` on its own output, and skip it for trivial results (a single file lookup,
  a one-line answer).
- The reviewer is only a first pass. The invoking agent still does the final review of the result
  and of the reviewer's findings, and decides what to accept or send back.
- Watch-each-other pair for evidence review: when judging screenshots or image evidence, run the
  vision seat (`evidence-vision`, free) for claim cards, then hand the cards to `reviewer` for
  source/consistency objections, then send only the contested cards back to `evidence-vision` for a
  rebuttal round. Parent arbitrates and owns the final verdict; human eyes stay the tiebreaker for
  anything still contested.

## Git policy

- Never push to a remote unless the user explicitly asks you to in the current turn. "Commit",
  "amend", and "force-push" all require an explicit instruction; do not infer permission from past
  turns.
- Commits and amends to local branches are fine when asked, but the push step is gated on a direct
  request each time.
