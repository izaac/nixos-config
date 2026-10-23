# OpenCode Global Rules (local-only, not managed by nixos-config)

## Agent cost policy: savings-first

- Always delegate mechanical tasks to the cheapest capable subagent:
  - `explore` (deepseek-v4.1-flash via OpenCode Go): codebase search, file finding, "where is X"
    questions
  - `general` (deepseek-v4.1-flash via OpenCode Go): bulk multi-step edits from clear patterns
  - `free-assistant` (beam-free via OpenCode Go, zero cost): quick Q&A, summaries, rewording,
    formatting; stable pin since beam-free replaced the random openrouter/free router for this seat
  - `evidence-vision` (gemini-3.8-flash-low via google/antigravity, Google AI Pro subscription
    quota, refill ~weekly): reads images and screenshots; when the Antigravity weekly bucket is
    drained, the parent respawns this seat on the OpenRouter vision model.
  - `reviewer` (deepseek-v4.1-flash via OpenCode Go): first-pass check of another subagent's result,
    run before the parent reviews it. Text-only: it cannot see images, so never hand it PNGs
    expecting visual verdicts
  - `reader` (beam-free via OpenCode Go, zero cost): bulk distillation only. Send it volume (test
    output, logs, inventories, long docs) and collect capped terse cards for the parent context.
    Never give it a skeptical task; it passed a head-to-head on facts but missed a verified
    docs-vs-code contradiction
  - `arbiter` (claude-haiku-5-5 via OpenCode Go, third family beside the DeepSeek workers and the
    gemini primary): called only when a reviewer verdict is disputed, evidence conflicts, or a wrong
    verdict is expensive. Independent error pattern is the point, not more effort
  - `arbiter-sonnet` (claude-sonnet-4-6 via google/antigravity): last-resort arbiter for complex
    reasoning, same read-only rules, called when stronger reasoning depth is needed or a dispute
    stays contested.
- Keep on the primary model: root-cause analysis, fix design, architecture decisions, anything where
  a wrong-but-confident answer is expensive.
- Launch subagents in background/parallel where possible; keep main context lean.
- Execution goes to subagents by default: test runs, bulk file ops, evidence harvesting, repetitive
  verification loops. The parent's job is to frame the task, review the subagent's output, arbitrate
  disputes, and own the final call before anything gets implemented or committed.
- Tiered execution: Simple Path (surface/visibility/config) bundles verification into ONE
  single-pass subagent and audits the final plan once. Complex Path (operators/CRDs/multi-step
  lifecycles) decomposes into phased fixture, execution, and paired-vision stages.
- Reviewer gating: Invoke `reviewer` on authored artifacts (plans, code diffs, fixtures) or disputed
  claims. Skip `reviewer` on read-only discovery queries (git checks, issue queries, simple status
  curls).
- Model pins live in `~/.config/opencode/opencode.jsonc`. This directory is local-only: never commit
  it anywhere.

## Subagent review

- After any subagent (`explore`, `general`, `free-assistant`, or custom) returns, invoke `reviewer`
  once with the original task and that subagent's output, before using the result.
- Do not invoke `reviewer` on its own output, and skip it for trivial results (a single file lookup,
  a one-line answer).
- The reviewer is only a first pass. The invoking agent still does the final review of the result
  and of the reviewer's findings, and decides what to accept or send back.
- Disputed or high-stakes claims: escalate the specific contested claims to `arbiter` (cross-family
  Claude Haiku), one escalation per dispute. It re-checks against files and returns per-claim
  verdicts. Parent arbitrates and owns the final call.
- Watch-each-other pair for evidence review: when judging screenshots or image evidence, run the
  vision seat (`evidence-vision`, google/antigravity) for claim cards, then hand the cards to
  `reviewer` for source/consistency objections, then send only the contested cards back to
  `evidence-vision` for a rebuttal round. Parent arbitrates and owns the final verdict; human eyes
  stay the tiebreaker for anything still contested.
- Text-only agents never interpret screenshots directly: they either receive pre-split visual work,
  or they record a VISUAL REQUEST card (file paths and exact questions) in their report and defer;
  the parent routes it to the vision seat and resumes that session on the cards.

## Search discipline

- Web search loops (two or more queries, or one query plus page fetches) are delegated to a subagent
  (`explore` or `general`) with a done-condition; the parent gets one distilled card, not link
  piles.
- Inline search in the main thread is allowed only for one-off single queries with no page reading.
- Fallback chain when the `websearch` tool is weak, rate-limited, or unavailable:
  1. `websearch` (default)
  2. DuckDuckGo via `webfetch`: `https://html.duckduckgo.com/html/?q=<query>` or
     `https://lite.duckduckgo.com/lite/?q=<query>`
  3. Brave Search API via `webfetch` with a free-tier key (2000 queries/month):
     `https://api.search.brave.com/res/v1/web/search?q=<query>` with header `X-Subscription-Token`;
     get the key at the Brave API dashboard. Skip this rung when no key is configured.
  4. Startpage via `webfetch`: `https://www.startpage.com/sp/search?query=<query>`; Google-grade
     results, HTML only, occasional captcha, last mile before self-hosting.
  5. Self-hosted SearXNG (`services.searxng` in NixOS) is the permanent upgrade path when search
     volume grows; do not wire it speculatively.
- Never send raw search result dumps back into the parent context; distill to a card first.

## Git policy

- Never push to a remote unless the user explicitly asks you to in the current turn. "Commit",
  "amend", and "force-push" all require an explicit instruction; do not infer permission from past
  turns.
- Commits and amends to local branches are fine when asked, but the push step is gated on a direct
  request each time.
