# OpenCode Global Rules (local-only, not managed by nixos-config)

## Agent cost policy: savings-first

- Always delegate mechanical tasks to the cheapest capable subagent:
  - `explore` (deepseek-v4.1-flash off-peak / qwen3.8-flash peak via OpenCode Go): codebase search,
    file finding, "where is X" questions
  - `general` (deepseek-v4.1-flash off-peak / qwen3.8-flash peak via OpenCode Go): bulk multi-step
    edits from clear patterns
  - `free-assistant` (beam-free via OpenCode Go, zero cost): quick Q&A, summaries, rewording,
    formatting; stable pin since beam-free replaced the random openrouter/free router for this seat
  - `evidence-vision` (gemini-3.8-flash-low via google/antigravity, Google AI Pro subscription
    quota, refill ~weekly): reads images and screenshots; when the Antigravity weekly bucket is
    drained, the parent respawns this seat on the OpenRouter vision model.
  - `reviewer` (gpt-6-luna via OpenCode Go, `xhigh` reasoning variant): first-pass check strictly
    gated on authored artifacts (plans, code diffs, fixtures) or disputed claims before parent
    reviews them. Text-only: it cannot see images and its shell access is restricted to read-only
    git inspection (`git status`, `git diff`, `git log`, `git show`) alongside `read`/`glob`/`grep`.
  - `reader` (beam-free via OpenCode Go, zero cost): bulk distillation only. Send it volume (test
    output, logs, inventories, long docs) and collect capped terse cards for the parent context.
    Never give it a skeptical task; it passed a head-to-head on facts but missed a verified
    docs-vs-code contradiction
  - `arbiter` (opencode-go/minimax-m3, MiniMax-M3 via OpenCode Go, independent family beside the
    DeepSeek workers, GPT reviewer, and gemini primary): the single arbiter seat, two triggers. (a)
    Disputed or high-stakes claims: a reviewer verdict is contested, evidence conflicts, or a wrong
    verdict is expensive. (b) Large code change foul-check: one bounded referee pass that runs ONLY
    after the first-pass `reviewer` has reviewed the diff and the principal has formed its own final
    reasoning (see the foul-check ordering under Subagent review). Independent error pattern is the
    point, not more effort. Pin form: `"model": "opencode-go/minimax-m3"` as one plain string.
  - `architect` (claude-sonnet-5-5-high via google/antigravity, fallback to deepseek-v4-pro via
    OpenCode Go): principal architect for deep reasoning, root-cause diagnosis, and obscure bug
    hunting. Escalated strictly by the primary agent when workers and primary are stuck. Has full
    permissions to debug freely (shell, webfetch, edit).
- Saiyan models ban: NEVER invoke `saiyan` agents/models (`saiyan`, `saiyan-haiku`, `saiyan-opus`)
  unless explicitly requested by the user in the session prompt. Default strictly to standard
  savings-first subagents.
- Keep on the primary model: root-cause analysis, fix design, architecture decisions, anything where
  a wrong-but-confident answer is expensive. If the primary is also stuck, escalate to `architect`.
- Launch subagents in background/parallel where possible; keep main context lean.
- Execution goes to subagents by default: test runs, bulk file ops, evidence harvesting, repetitive
  verification loops. The parent's job is to frame the task, review the subagent's output, arbitrate
  disputes, and own the final call before anything gets implemented or committed.
- Tiered execution (strictly enforced):
  - Simple Path (surface/visibility/config, routine operations, host hygiene, cleanup, command
    runs): bundles execution and verification into ONE single-pass subagent. Reviewer is FORBIDDEN
    on Simple Path. The parent reviews the subagent card directly and delivers the verdict.
  - Audit Path (codebase reviews, architectural sweeps, hygiene/best-practice audits, repo
    summaries): decomposes into 3 parallel background domain probes (`explore` / `reader`): (1)
    Architecture & Topology (boundaries, data flow, coupling), (2) Quality & Anti-patterns (error
    handling, types, dead paths, test structure), (3) Tooling & DX (builds, CI, manifests, configs).
    Each worker returns a FINDING CARD (<=25 lines). Reviewer is FORBIDDEN. Parent synthesizes the
    cards into a prioritized roadmap.
  - Complex Path (operators/CRDs/multi-step lifecycles): decomposes into phased fixture, execution,
    and paired-vision stages.
- Reviewer gating (hard rule): Invoke `reviewer` ONLY on authored artifacts (plans, code diffs,
  fixtures) or disputed claims. NEVER invoke `reviewer` on Simple Path executions, Audit Path
  sweeps, operational commands, or read-only discovery queries.
- Model pins live in `~/.config/opencode/opencode.jsonc`. This directory is local-only: never commit
  it anywhere.

## Subagent review

- Reviewer gating is strictly enforced: invoke `reviewer` ONLY on authored artifacts (plans, code
  diffs, fixtures) or disputed claims.
- Never invoke `reviewer` on Simple Path executions or Audit Path sweeps: routine operations
  (cleanup, single commands, builds, host hygiene) or discovery/audit queries (code reviews, git
  checks, issue queries, status curls) are verified directly by the executing subagent or
  synthesized by the parent.
- Do not invoke `reviewer` on its own output, and skip it for trivial results (a single file lookup,
  a one-line answer).
- The reviewer is only a first pass for authored artifacts. The invoking agent still does the final
  review of the result and of the reviewer's findings, and decides what to accept or send back. On a
  large code change, that completed principal reasoning is exactly what the foul-check `arbiter`
  pass receives, together with the diff and the reviewer findings.
- Disputed or high-stakes claims: escalate the specific contested claims to `arbiter` (cross-family
  MiniMax-M3), one escalation per dispute. It re-checks against files and returns per-claim
  verdicts. Parent arbitrates and owns the final call.
- Large code change foul-check (referee check): a large change means 3+ files modified, roughly 100+
  lines changed, or an architectural touchpoint. The order is fixed and strictly enforced:
  1. The worker executes the change.
  2. First-pass `reviewer` (`opencode-go/gpt-6-luna#xhigh`) reviews the authored diff.
  3. The principal receives the `reviewer` review and forms its own final reasoning: what to accept,
     reject, or adjust.
  4. ONLY AT THAT POINT, with the `reviewer` findings and the principal's final reasoning both in
     hand, call `arbiter` (`opencode-go/minimax-m3`) for ONE quick bounded referee pass, capped at
     <=5 tool calls, over the diff, the `reviewer` findings, and the principal's final reasoning, to
     see if a foul needs to be called out before finalizing. Never call `arbiter` before `reviewer`,
     and never call it twice.

  What it looks for: broken invariants, security or stealth regressions, cross-file contract
  mismatches, or missed edge cases the fast first-pass reviewer would not catch. Same read-only
  rules: it never edits and never redoes the task. Foul-check output is lines of
  `FOUL severity high|medium, file:line, what breaks, smallest fix`, or `CLEAN` plus the riskiest
  spots checked.

- Watch-each-other pair for evidence review: when judging screenshots or image evidence, run the
  vision seat (`evidence-vision`, google/antigravity) for claim cards, then hand the cards to
  `reviewer` for source/consistency objections, then send only the contested cards back to
  `evidence-vision` for a rebuttal round. Parent arbitrates and owns the final verdict; human eyes
  stay the tiebreaker for anything still contested.
- Text-only agents never interpret screenshots directly: they either receive pre-split visual work,
  or they record a VISUAL REQUEST card (file paths and exact questions) in their report and defer;
  the parent routes it to the vision seat and resumes that session on the cards.
- Subagent anti-freeze rules (strictly enforced):
  - No recursive CLI spawning: Subagents must NEVER invoke `opencode` CLI commands
    (`opencode debug`, `opencode run`, etc.) inside shell tools: inspect files, configs, and system
    state directly with standard tools.
  - Bounded reviewer budget: Reviewer subagents are strictly first-pass spot-checks, capped at <=5
    tool calls total. Never run deep diagnostic loops, full rebuilds, or recursive audits in the
    reviewer seat.

## Stuck circuit-breaker & 3-tier escalation ladder

- Rule of Two: If a command, tool, or fix attempt fails with the same error twice, or two
  consecutive searches return 0 results, blind iteration is PROHIBITED. The worker subagent must
  immediately halt and return a STUCK CARD (<=15 lines: Target, Attempt, Error snippet, Blocker,
  Files) to the parent.
- Two-stage triage:
  1. The parent reviews the STUCK CARD. If the issue is a simple boundary or path error, the parent
     redirects the worker directly without spending frontier tokens.
  2. If the primary's hypothesis also fails, or the root cause is obscure, the primary escalates to
     the `architect` seat (Claude Sonnet 5.5 on Antigravity, fallback to DeepSeek V4 Pro on OpenCode
     Go).
- `architect` produces a dense ARCHITECTURAL SOLUTION CARD (<=25 lines) diagnosing root causes and
  providing concrete actions for the worker to execute.
- Role clarity:
  - `arbiter` is strictly for tie-breaking disputed claims between reviewer and worker, plus the
    single bounded large-change foul-check. That foul-check runs only after `reviewer` has reported
    and the principal has formed its final reasoning, and it is never run twice on the same change.
    It NEVER diagnoses bugs or solves problems.
  - Problem escalation when stuck goes strictly to `architect`.
- Terminal Stop Invariant: The `architect` is the ceiling of automated reasoning. If the architect
  determines an external environment/credential/spec blocker, it returns an ARCHITECTURAL IMPASSE
  CARD (<=20 lines). If the architect's solution fails upon worker execution, the primary receives
  the failure card. In either case, further automated guessing is STRICTLY FORBIDDEN: the primary
  immediately HALTS execution and invokes the `question` tool to present the blocker, evidence, and
  2-3 concrete human options. Terminal stop means at most one architect round per problem: no loops,
  no retries after the impasse verdict.

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
