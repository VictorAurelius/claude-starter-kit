# Session-End Context Check — verify % budget before proposing end

**Priority:** 🟠 MANDATORY — session lifecycle discipline
**Version:** 1.1.0
**Created:** 2026-05-19
**Last-Reviewed:** 2026-05-19
**Reviewer-Approver:** @nguyenvankiet (starter-kit upstream maintainer)
**Applies to:** Every turn where Claude intends to propose end-session / suggest `/clear` / hint "out of session" / "next session" / "wrap up" / "context degraded" — proactive proposal OR reactive proposal after user nudge. Out-of-scope: user explicitly asks `/clear` (do it now, no check).

---

## 1. The Rule

> **Before Claude proposes end-session OR suggests `/clear` OR hints "next session" / "out of context", it MUST run `bash .claude/statusline.sh` to check the actual context %, then decide per the §3 threshold table.**

Proposing end-session while context is still spacious (e.g. <50%) wastes user time + forces a cache miss + loses conversation continuity. Proposing end when context is genuinely high (>70%) honors the cache TTL + preps the user for a fresh session.

Force-multiplier: NOT checking = guessing; checking = evidence-based decision. Cost ~50 tokens (1 Bash invocation) saves vs the cost of N×1000 tokens of cache miss when the user clears prematurely on the agent's advice.

---

## 2. When this rule fires

Rule fires when Claude's turn is about to output text matching a phrasing pattern:

| Pattern | Example |
|---|---|
| Direct end propose | "End session", "Wrap up", "Session done" |
| Clear suggestion | "Recommend `/clear`", "Suggest clearing context" |
| Future-session deferral | "Next session", "Pick up next time" |
| Context-degraded hint | "Context degraded", "Context full", "Token budget low", "Context heavy" |
| Compact suggestion | "Recommend `/compact`" |
| Cache-miss warning | "Context approaching limit", "Approaching context max" |

Rule does **NOT** fire when:
- User explicitly asks: "Clear", "Wrap up" → execute directly (user authorization override)
- Mid-task pause unrelated to context: "Pausing for you to review", "Waiting for confirm" — not end-session
- Reporting CI/agent status: "Agent done", "Build done" — not session lifecycle

---

## 3. Threshold decision table

After running `bash .claude/statusline.sh`, output format: `[icon] [progress-bar] X% N/total $cost`. Extract the `X%` value.

| Context % | Action |
|---|---|
| **< 50%** | ❌ **DON'T propose end** — context is spacious, keep working. Answer any user context question with current % + "still fine, can continue". |
| **50-69%** | 🟡 **Soft mention OK** — may note "context ~X%, still has room" but DON'T propose end. Reserve for near-threshold heads-up only. |
| **70-84%** | 🟠 **Heads-up + ask** — flag user "context ~X% nearing limit, want to `/clear` after the current task?" — wait for the user to decide, DON'T self-execute. |
| **≥ 85%** | 🔴 **Strong recommend** — propose `/clear` after the current task finishes + a handoff note. User confirms before clear. |
| **≥ 95%** | ⚠️ **Force handoff** — the current task MUST close now (no new work), write a handoff note, recommend `/clear` immediately. |

Thresholds are based on prompt-cache TTL + the `context-budget-mandate.md` baseline to preserve the cache window. 70% = a cache-warm threshold breach signal.

---

## 4. Required action sequence

When rule fires (Claude detects it's about to output text in the §2 pattern):

0. **Docs-sync verification (MANDATORY)** — Verify the 5 sync targets per §4.5 before proposing end. If ANY target is stale → fix BEFORE proposing end (bundle into a docs-only sync PR). Skipping this = next session pickup misses state.
1. **STOP text output composition.**
2. **Run the statusline with proper stdin** (the script reads JSON stdin from the harness, NOT standalone). Find the most recent transcript path, construct the JSON envelope, and pipe it into `bash .claude/statusline.sh`. The script auto-detects the context window total (200k vs 1M) from the model ID. Threshold % (§3) is valid for any total (% means the same thing).
3. **Read X%** from output format `[model] [bar] X% used/total $cost` (extract `\d+%`).
4. **Apply §3 threshold table** → decide action class.
5. **Output text per the action class** — INCLUDE the current % value for transparency. E.g. "Context is at 44% — still has room, no need to end session" OR "Context 78% — nearing limit, suggest `/clear` after this task".

If the script fails (exit non-0 / no output / transcript path missing): fall back to asking the user to read the status-line % from the UI.

## 4.5 Docs-sync verification 5-target checklist

Extends the per-PR sync framework (`post-merge-sync-completeness.md`) with a 5th target (session-handoff) — applied at the session-end decision moment specifically, not just per-PR.

| # | Target | How to verify |
|---|---|---|
| 1 | Gap-status CSV (`documents/**/gap-status.csv`) | Every gap status flip this session is reflected — diff the CSV against actual gap file states |
| 2 | ROADMAP `§Current Status Snapshot` | Wave / PR / gap shipped this session has a ROADMAP entry |
| 3 | Wave-history log | Wave completions / wave-plan ships appended an entry |
| 4 | Memory index | New memory entries created this session have a pointer in the index file |
| 5 | Session-handoff note (`documents/**/session-handoffs/YYYY-MM-DD-*.md`) | A handoff note exists for the session date with scope shipped + pickup state for the next session |

**Decision flow:**

```
1. Run 5-target check (MANDATORY)
2. If ANY stale → fix BEFORE proposing end:
   - Bundle sync into a docs-only PR
   - Apply 1 PR for all 5 targets (atomic sync)
3. After sync clean → run §4 Step 1-5 context check sequence
4. Then propose end with both: clean docs sync + verified context %
```

**Banned shortcuts:**
- ❌ Propose `/clear` when any sync target is stale "I'll fix next session" — context flush = lose track
- ❌ Sync partial (3/5 targets) — atomic 5/5 required for a clean handoff
- ❌ Skip the session-handoff note "because conversation context is enough" — Claude session context doesn't persist; the handoff doc is the canonical pickup source

---

## 5. Anti-patterns

| ❌ Don't | ✅ Do |
|---|---|
| Propose end-session by feel ("context is probably high") | Run the statusline script, get evidence % |
| Suggest `/clear` just because the conversation has many turns | Turn count ≠ context %. Check actual % via script |
| Auto-execute `/clear` without asking the user | User confirms first, even at 95%+ |
| Skip the check "because the task is small" | Rule applies to EVERY end-session proposal regardless of task size |
| Include % from a previous turn ("earlier it was X%") | Re-check fresh — context grows each turn |
| Round 95% down to 85% "to be safe" | Report exact %; be transparent with the user |
| Propose end when the user just started a new task | Finish the current task first, then re-evaluate |

---

## 6. Worked self-test

**Scenario:** A long session — multiple agents spawned + gap triage + decisions + rule additions. Suppose at the final turn the agent intends to propose "let's end this session".

**Apply §4 sequence:**

1. STOP text output composition ✅
2. Run `bash .claude/statusline.sh` (with proper stdin) — output: `[icon] [bar] X% N/total $cost`
3. Read X%
4. Apply table:
   - If X < 50% → DON'T propose end; respond "context still ok, can continue"
   - If X 70-84% → heads-up + ask user
   - If X ≥ 85% → strong recommend `/clear` post-task
5. Output text including exact % value

**Counterfactual without rule:** Claude proposes end based on subjective "feel" (turn count, work volume) — possibly wrong direction (propose end at 30% = waste; OR fail to propose at 90% = next-turn overflow + cache miss).

**Verdict:** rule fires correctly on session-end proposal moments. Evidence-based vs subjective decision. ✅

---

## 7. Auto-load justification (per `context-budget-mandate.md` §3.2)

This rule does NOT use `paths:` frontmatter — it always auto-loads each session. Rationale:

- **Cross-cuts every end-session proposal moment** — it fires at text-output composition time, not file-read time. There is no natural file-scope trigger.
- **Path-scope would miss the important case** — if scoped to `.claude/**` only, the rule would be absent when a session works on code or `documents/**` files (most sessions) — exactly the case where it needs to fire.
- **Hook-coverage not feasible v1** — detecting "Claude is about to output text proposing end-session" requires NLP on the response candidate, beyond a deterministic hook (PreToolUse/PostToolUse fire at the tool-call boundary, not at text composition).
- **Token cost acceptable** — ~1k tokens × every session; force-multiplier each session saving one false-end-propose round-trip + cache preservation.
- **Priority 🟠 MANDATORY kept** — not raised to CRITICAL because the §3 "user explicit ask" exception relaxes it; always-load applies per `context-budget-mandate.md` §3.2.

Re-evaluate if: (a) a pre-text-output NLP hook becomes available, (b) >5 false-positives per session/quarter, (c) the rule grows >300 lines.

---

## 8. Enforcement (per `rule-change-process.md` §6.5)

### 8.1 Memory auto-load (per-session)

A paired memory entry loads at session start, reminding of the checklist before every end-session text composition.

### 8.2 Self-detection (in-turn)

Before sending a response containing a §2 pattern (end / clear / next session / context-degraded / compact), Claude mentally runs the §4 sequence. If §4 wasn't run → high probability of a wrong threshold.

### 8.3 Reviewer / user manual

User can flag with "Why propose end without checking %?" after the rule lands. Repeated pattern → file a follow-up gap referencing this rule.

### 8.4 Override mechanism

Genuine exception (e.g. user explicitly says "wrap up" — Claude executes without checking; OR end-of-context-window forced):

```
git commit -m "...
SESSION_END_CHECK_OVERRIDE: <reason — e.g. 'user explicitly asked clear', 'context-window hard-limit forced end'>"
```

Trailer logged. Pattern frequency >5% triggers meta-review.

### 8.5 Detector (deferred per `incident-to-rule-pipeline.md` premature-rule guard)

Future enhancement: scan recent session transcripts for end-session text WITHOUT a corresponding `bash .claude/statusline.sh` invocation. Deferred; memory auto-load + self-detection + worked self-test sufficient for v1.0.0.

---

## 9. Relationship to other rules

- **`context-budget-mandate.md`** §1 — auto-load baseline; this rule operationalizes "when to act on budget" at the end-session decision point
- **`agent-action-bias.md`** §1 Part A — do-it-yourself; this rule extends: do-state-check-yourself (run script vs guess)
- **`mcp-first-with-fallback.md`** — tool selection hierarchy; the statusline script = Tier 3 (project script), correct usage
- **`post-merge-sync-completeness.md`** — per-PR sync framework; §4.5 extends it with the 5th session-handoff target at the session-end moment
- **`incident-to-rule-pipeline.md`** — coverage-gap → rule conversion pipeline
- **`rule-change-process.md`** §6.5 Enforcement Parity Mandate — rule + memory + self-test all paired same PR
- **`output-review-mandate.md`** §3 — adds row "Session-end context check" tracking review standard

---

## 10. Log

- **2026-05-19 (v1.1.0):** Extracted into starter-kit from a real 200+ PR project. Proposing end-session by feel (rather than checking the actual context %) wastes the cache window and can miss a near-full window; this rule mandates a statusline check + a 5-target docs-sync verification before any end-session proposal.
