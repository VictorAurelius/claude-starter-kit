# Agent Model Default — spawn the most capable model for non-trivial agents

**Priority:** 🟠 MANDATORY — agent reliability governance
**Version:** 1.0.0
**Created:** 2026-05-25
**Last-Reviewed:** 2026-05-25
**Reviewer-Approver:** @nguyenvankiet (starter-kit upstream maintainer)
**Applies to:** Every `Agent` tool invocation (subagent spawn) in the project — `general-purpose`, `Explore`, `Plan`, or any subagent type. Out-of-scope: `statusline-setup`, `init` (single-shot config skills, below the thrash threshold).

---

## 1. The Rule

> **Every Agent tool invocation MUST set `model: "opus"`** (the most capable model, 1M context) unless a §3 exception applies. A weaker default model MUST NOT be used for agent spawns because it has a failure mode — "autocompact thrash" on non-trivial prompts.

This rule sharpens `agent-background-spawn-default.md` (same family — agent invocation discipline) on a different axis: model selection (most-capable mandatory) rather than sync mode (background mandatory). Both apply each spawn.

---

## 2. Why — recurring failure pattern

| Setting | Failure mode | Recovery |
|---|---|---|
| **Audit-suite agents on the weaker model** | ALL agents thrashed on first attempt (autocompact 3x in 3 turns) | Most-capable-model retry SUCCESS — shipped all reports |
| **Background bucket agents on the weaker model** | Multiple of N agents thrashed (autocompact 3x); some additionally leaked work via path violations | Most-capable-model retry succeeded |

**Observed recurring across multiple milestones** = a systemic failure mode of the weaker model, not noise.

### Failure mode mechanism

The weaker model thrashes when:
- Agent prompt context + rule auto-load (path-scoped) + tool output > its effective working window
- Autocompact compresses recent turns → context refills immediately the next turn (rule auto-loads still apply) → compresses again → 3x in 3 turns = "thrashing" signal
- The agent stops returning useful work after the 3rd compact

The most capable model (1M-context) handles the same prompt + auto-load + tool output comfortably — no compact triggered for realistic agent prompts.

### Cost reasoning

The capable model's token cost is several times higher. But:
- 1 thrash = full agent spawn cost (0 output) + retry cycle wall-clock cost
- 2 weak-model retries > 1 capable-model first-try success
- Coordinator round-trip cost (user round-trip + diagnose + decide retry) >> token delta

Cost-benefit: capable-model default ROI is positive when the failure recurs.

---

## 3. Allowed exceptions (rare)

A weaker model (or omitting the field, since the harness default may be weaker) is ACCEPTABLE ONLY when:

| Case | Why exempt | Example |
|---|---|---|
| **Single keyword/file lookup** (Explore < 2 min wall) | Single grep, no reasoning depth needed | "Find which file imports X" → 1 grep return |
| **Statusline / init / one-config-edit agents** | Out-of-scope per `Applies to`; single tool call | `statusline-setup`, `init` skills |
| **Cost-bound experiment, user explicit override** | User testing the weaker model on a simple scope | "Try the cheaper model to compare speed" — user-directed |

When invoking an exception, state it inline in the agent prompt OR commit body: "Per `agent-model-opus-default.md` §3 row <X>".

---

## 4. Override mechanism

Genuine weaker-model case outside the §3 list:

```
AGENT_MODEL_WEAKER_OVERRIDE: <reason — e.g. 'cost experiment on docs-only scope', 'parallel-of-N + capable-model budget constraint'>
```

Trailer logged in quarterly retro. Pattern frequency > 5% in a quarter → meta-review of the §3 exception list.

---

## 5. Anti-patterns

| ❌ Don't | ✅ Do |
|---|---|
| Spawn 4-5 background agents on the weaker model "because it's cheaper" | Capable model default — 1 success > 2 retries |
| Trust the weaker model after 1 success "because it worked yesterday" | Recurrence has proven thrash; default to the capable model |
| Skip the rule "because the agent prompt is small" | Even small prompts + path-scoped rule auto-load + tool output → thrash threshold |
| Omit the `model:` field "to use the harness default" | Explicit `model: "opus"` on every spawn — don't trust the default |
| Weaker model for audit agents | Audit agents = reasoning-heavy = capable model mandatory |
| Weaker model for code-write bucket agents | Bucket agents = full implementation = capable model mandatory |
| Foreground weaker model "because foreground avoids thrash" | Background + capable model = both rules apply, no conflict |

---

## 6. Self-test — background bucket spawn incident

**Scenario:** A coordinator spawned 3 background agents on the weaker model with `run_in_background: true` for a batch:
- Bucket A: a controller IDOR fix
- Bucket D: a model default value
- Bucket E: a javadoc edit

**Actual outcome (weaker model, this rule's counterfactual):**
- A: **thrashed** (autocompact 3x in 3 turns) — 0 output
- D: leaked work via an absolute-path violation; agent worktree empty
- E: **thrashed** (autocompact 3x) — 0 output
- Failure rate: **2/3 = 67%** + 1 partial leak

**Counterfactual with rule (capable model from start):**
- 3 capable-model agents from start
- Prior milestone lesson: all capable-model retries SUCCEEDED → expected same pattern
- Failure rate projected: **~0/3**

**Cost-save quantification:**
- 2 wasted background-agent spawns (A + E thrash) ≈ ~30 min wall-clock + token waste
- 1 manual salvage operation (Bucket D leak recovery) ≈ ~15 min coordinator cost
- 1 user round-trip (Q "spawn 3 capable-model retries?" decision) ≈ ~5 min
- Total preventable cost: ~50 min wall-clock + cognitive overhead per batch

**Verdict:** Rule fires correctly on the originating incident — the retry pattern (3 capable-model agents in parallel) is exactly what the rule mandates. Self-test PASS ✅

---

## 7. Auto-load justification (per `context-budget-mandate.md` §3.2)

This rule does NOT use `paths:` frontmatter — it always auto-loads each session. Rationale:

- **Cross-cuts every agent spawn moment** — the decision happens at Agent tool invocation runtime, not file-read time. There is no natural file-scope trigger.
- **Path-scope would miss the critical case** — if scoped to `.claude/skills/**`, the rule would be absent when a coordinator spawns agents outside a skill context (every batch execution). Exactly the case where it needs to fire.
- **Hook-coverage not feasible v1** — pre-tool-call inspection of Agent tool args to verify model=opus is possible but cost-benefit hasn't cleared the `incident-to-rule-pipeline.md` premature-rule guard.
- **Token cost acceptable** — ~1.1k tokens × every session; force-multiplier each spawn saving one thrash retry cycle.
- **Priority 🟠 MANDATORY kept** — not raised to CRITICAL because the §3 exception list permits deferral; always-load applies per `context-budget-mandate.md` §3.2.

Re-evaluate if: (a) a weaker model release fixes thrash mode, (b) a cheaper model proves fit for bucket-scale agents, (c) a pre-tool-call NLP hook becomes available, (d) > 5 false-positive overrides in a quarter.

---

## 8. Enforcement (per `rule-change-process.md` §6.5 Enforcement Parity Mandate)

### 8.1 Memory auto-load (per-session)

A paired memory entry loads at session start. 4-bullet checklist:
1. Every Agent tool spawn → `model: "opus"`
2. Weaker model OK ONLY for a §3 exception (single-lookup Explore / statusline / user-explicit)
3. Thrash recurrence is systemic
4. Cost ROI positive when the failure recurs

### 8.2 Self-detection each turn

Before calling the Agent tool, the coordinator mentally runs the check:
- Set `model: "opus"`?
- If NOT → does a §3 exception match? Justify inline?
- If NOT matched → upgrade to the capable model before invoking

### 8.3 Reviewer-checklist (manual)

When reviewing a skill file / agent prompt template touching agent spawn examples:
- [ ] Agent invocation examples set `model: "opus"`?
- [ ] §3 exception cited inline if a weaker model?

### 8.4 Detector (deferred per `incident-to-rule-pipeline.md` §3.1)

- **Detector complexity:** Pre-tool-call hook inspecting Agent tool args to verify the `model` field — moderate complexity (PreToolUse hook + JSON parse args)
- **Recurrence count:** 0 post-merge
- **FP risk:** Low — exception list narrow, clear binary check
- **Decision:** Reviewer-checklist §8.3 + memory auto-load §8.1 + worked self-test §6 sufficient for v1.0.0; revisit when a weaker-model spawn slips through.

### 8.5 Override mechanism

Per §4 trailer `AGENT_MODEL_WEAKER_OVERRIDE:` — logged quarterly retro. Pattern frequency > 5% → meta-review.

---

## 9. Relationship to other rules

- **`agent-background-spawn-default.md`** — sister rule (same family: agent invocation discipline). That rule covers the `run_in_background: true` axis; this rule covers the `model: "opus"` axis. Both apply each spawn — compose cleanly.
- **`agent-action-bias.md`** — "do it yourself" governance. Orthogonal axis: WHEN to spawn an agent. Once the decision is to spawn, this rule + agent-background-spawn-default both apply.
- **`agent-concurrency-budget-inline-hybrid.md`** — when reducing concurrency to avoid limits, this rule still mandates the capable model for the agents that are spawned.
- **`incident-to-rule-pipeline.md`** — coverage-gap → rule conversion pipeline.
- **`rule-change-process.md`** §6.5 Enforcement Parity Mandate — rule + memory auto-load + worked self-test all ship same PR.
- **`context-budget-mandate.md`** §3.2 — this rule's always-load is justified in §7.
- **`meta-gap-priority.md`** §3 — META P1 force-multiplier.
- **`output-review-mandate.md`** §3 — paired matrix row "Agent model selection" tracking standard.

---

## 10. Log

- **2026-05-25 (v1.0.0):** Extracted into starter-kit from a real 200+ PR project. The default/weaker model thrashed (autocompact 3x in 3 turns) on non-trivial background agents across multiple milestones, while the most capable model succeeded on retry; this rule mandates spawning the most capable model for every non-trivial agent.
