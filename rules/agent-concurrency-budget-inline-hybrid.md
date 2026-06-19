---
paths:
  - ".claude/skills/**"
  - "documents/**"
---

# Agent Concurrency Budget + Inline-Hybrid — fewer agents, fill with inline, keep wall-clock low

**Priority:** 🟠 MANDATORY — agent orchestration efficiency governance
**Version:** 1.0.0
**Created:** 2026-06-11
**Last-Reviewed:** 2026-06-11
**Reviewer-Approver:** @nguyenvankiet (starter-kit upstream maintainer)
**Applies to:** Every wave/task execution with ≥3 disjoint buckets where the agent count must be reduced to avoid server/rate limits. Out-of-scope: single-bucket task, task with no limit concern (just use the normal parallel cap).

---

## 1. The Rule

> **When reducing the number of agent spawns to avoid server/rate limits, the coordinator MUST fill the idle time by self-executing disjoint buckets INLINE in parallel with the running agent(s).** "Fewer agents" comes paired with "coordinator works inline" — NOT "coordinator waits for the agent". The goal: wall-clock as low as a fan-out, with a concurrency budget that's safe against limits.

Spawning few agents (e.g. ≤1-2 capable-model agents) is correct to avoid rate-limits (each capable-model agent has high token throughput per `agent-model-opus-default`). BUT if the coordinator just waits → all the wall-clock benefit of parallelism is lost. Compensation: the coordinator self-executes disjoint buckets (assets/config/docs/single-file edits) WHILE the agent runs the heavy/cohesive bucket.

Force-multiplier: one hybrid standard → every limit-bound wave keeps wall-clock low without hitting the limit.

---

## 2. Decision model

### 2.1 Concurrency budget

| Limit situation | Concurrent agent budget | Remaining buckets |
|---|---|---|
| Severe limit (already/currently hitting rate-limit) | **≤1 capable-model agent** | coordinator inlines all remaining disjoint buckets |
| Moderate limit concern (precautionary) | **≤2 capable-model agents** | inline remaining disjoint buckets |
| No limit concern | normal parallel cap | (this rule does not fire) |

### 2.2 Bucket → agent vs inline (classification)

| Bucket characteristic | Assign to |
|---|---|
| Heavy + cohesive (one large file needing iterative compile/test, e.g. a seeder/service) | **Agent** (capable model, background) — agent loops compile-fix itself |
| Small + disjoint (asset fix, gitignore, config, single-file edit, docs, CSV row) | **Inline** (coordinator does it in parallel) |
| Cross-cutting needing many scattered file reads/edits | Agent if budget remains; inline if coordinator is free |

### 2.3 Idle-fill principle

After spawning agent(s) within budget → **BEFORE "waiting", the coordinator must ask: is there any disjoint bucket I can do inline right now?** If YES → do it inline (don't wait). Only "wait for notification" once all inline-able buckets are exhausted OR the remaining work depends on the running agent's output.

---

## 3. Required behavior when rule fires

```
1. Count disjoint buckets + assess limit concern → pick budget §2.1
2. Classify buckets §2.2: heavy-cohesive → agent; small-disjoint → inline
3. Spawn agent(s) within budget (background, capable model)
4. IMMEDIATELY after spawn: coordinator executes inline-able buckets in parallel (DON'T wait)
5. Only wait for notification once inline-able buckets are exhausted OR remaining work depends-on agent output
6. Agent finishes → integrate (review/compile) → proceed to dependent buckets
```

---

## 4. Banned shortcuts

| ❌ Don't | ✅ Do |
|---|---|
| Spawn ≤1 agent then have the coordinator wait while disjoint buckets remain | Do the disjoint bucket inline in parallel with the agent |
| Spawn 4-5 agents "for speed" while worried about limits | ≤1-2 within budget + compensate inline |
| Hand a small disjoint bucket (asset/config) to an agent then wait | Coordinator does it inline right away |
| "Do E/F after agent #1 finishes" when E/F are disjoint from #1 | Do E/F inline NOW while #1 runs |
| Inline a cohesive bucket the agent is working on (same file) | Only inline disjoint buckets — avoid conflict |

---

## 5. Override mechanism

Genuine exception (all remaining buckets depend-on agent output, nothing inline-able):

```
inline note: "AGENT_CONCURRENCY_INLINE_NA: <reason — e.g. all remaining buckets depend on the seeder agent output, nothing disjoint inline-able>"
```

Pattern frequency >20%/quarter → meta-review (bucket decomposition may not be optimally disjoint).

---

## 6. Worked self-test — limit-bound seed wave (originating incident)

**Scenario:** A wave had 6 buckets (A-D a cohesive single-file seeder / E content sections / F asset fix). The user directed "spawn few agents to avoid limits". I spawned **1 capable-model agent** (the A-D seeder, correct for budget ≤1) — good for the limit. BUT then I told the user "E/F will be done AFTER #1 finishes" → **coordinator idle while #1 ran** (wasting wall-clock = the full duration of agent #1).

**Apply rule retroactively:**
- §2.2: Bucket F (asset: gitignore + remove binaries + split logo) = **small-disjoint** → inline-able, does NOT touch the seeder agent #1's files.
- §2.3: immediately after spawning #1 → coordinator does **F inline in parallel** (+ writing this meta rule inline — the very pattern being applied).

| Metric | Without rule (idle) | With rule (inline-hybrid) |
|---|---|---|
| Concurrent agents | 1 (limit-safe) | 1 (limit-safe) |
| Coordinator while #1 runs | ❌ waits | ✅ does F + meta inline |
| Wall-clock | #1 + (F after) sequential | max(#1, F inline) — F is "free" |
| Limit risk | low | low (same) |

**Save:** ~the duration of Bucket F (+ meta) overlaps into agent #1's runtime → wall-clock drops while limit-risk stays flat. Self-test PASS ✅ — the rule fires correctly on the very session that spawned it (writing this rule = inline work parallel to agent #1).

---

## 7. Enforcement (per `rule-change-process.md` §6.5 Enforcement Parity Mandate)

### 7.1 Self-detection (in-turn, active now)
Immediately after spawning agent(s) within budget, BEFORE saying "wait" / ending the turn:
- Is there any disjoint inline-able bucket left? If YES → do it inline now, don't wait.
- If only buckets that depend-on the agent remain → waiting is valid.

### 7.2 Reviewer-checklist (active now)
When reviewing a wave execution / coordinator session:
- [ ] Concurrent agent count ≤ budget §2.1 when limit-concerned?
- [ ] Did the coordinator do disjoint buckets inline in parallel (not idle) while the agent ran?
- [ ] Inline bucket disjoint from the agent's files (no conflict)?

### 7.3 Memory auto-load (paired same-PR)
A paired memory entry reminds of the §7.1 checklist at session start (always-on, to compensate for the path-scope).

### 7.4 Detector (HONEST DEFER per `incident-to-rule-pipeline.md` §3.1)
- **Complexity:** detecting "coordinator idle while inline-able buckets remain" requires analyzing reasoning + a bucket dependency graph — NLP, not trivial.
- **Recurrence:** 1.
- **Decision:** self-detection §7.1 + reviewer-checklist + memory + worked self-test sufficient for v1.0.0; revisit when recurrence ≥2.

### 7.5 Override — per §5.

---

## 8. Atomic-unique-bar check (per `rule-change-process.md` §5.1)
- ✅ **Atomic:** single concept = concurrency budget + inline compensation
- ✅ **Unique:** `agent-model-opus-default` = model axis; `agent-background-spawn-default` = sync axis; this rule = intentionally LOWER concurrency + inline-fill (different axis)
- ✅ **Widely applicable:** every limit-bound wave
- ✅ **Body discipline:** §1 ≤2 conjunctions

---

## 9. Relationship to other rules
- **`agent-model-opus-default.md`** — capable model per agent (high throughput → budget needed); composes.
- **`agent-background-spawn-default.md`** — background spawn lets the coordinator work inline in parallel; composes directly.
- **`agent-action-bias.md`** §1 Part A — "do it yourself"; this rule = "do disjoint buckets yourself when reducing agents".
- **`incident-to-rule-pipeline.md`** — coverage-gap → rule conversion pipeline.
- **`rule-change-process.md`** §6.5 — rule + self-detection + reviewer-checklist + memory + worked self-test + rules-index row + output-review-mandate §3 row same PR.
- **`meta-gap-priority.md`** §3 — META P1 force-multiplier.

---

## 10. Log
- **2026-06-11 (v1.0.0):** Extracted into starter-kit from a real 200+ PR project. When agent count was reduced to dodge rate-limits, the coordinator sat idle waiting instead of doing disjoint buckets inline; this rule mandates filling idle time with inline work in parallel with the running agents.
