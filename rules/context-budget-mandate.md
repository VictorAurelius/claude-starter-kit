---
paths:
  - ".claude/rules/**"
  - "CLAUDE.md"
  - ".claude/skills/**/SKILL.md"
---

# Context Budget Mandate — base auto-load < 120k tokens

**Priority:** 🟠 MANDATORY — meta-governance for base context size
**Version:** 1.1.0
**Created:** 2026-05-14
**Last-Reviewed:** 2026-05-31
**Reviewer-Approver:** @nguyenvankiet (starter-kit upstream maintainer)
**Applies to:** Every change touching `.claude/rules/**/*.md`, `.claude/skills/**/SKILL.md`, or `CLAUDE.md` (artifacts that auto-load into base context every session)

---

## 1. The Rule

> **Base auto-load context per session MUST stay <120k tokens (target ~100k).** Any rule that auto-loads ≥1k tokens into base context MUST use `paths:` frontmatter (path-scoped deferred-load) OR include a `## Auto-load justification` section explaining the rationale.

When a project accumulates dozens of always-loaded `.claude/rules/*.md` files, the base context per fresh session can balloon to hundreds of thousands of tokens — a large fraction of the window consumed before any work starts. Per `meta-gap-priority.md` §3 Meta-P0 force-multiplier — every future session benefits permanently from path-scoping.

---

## 2. What counts as base context

| Source | Loaded when | Token measurement |
|---|---|---|
| `CLAUDE.md` (project root) | Every session, every turn | `wc -w CLAUDE.md` × 1.3 ≈ tokens |
| `.claude/rules/*.md` WITHOUT `paths:` frontmatter | Every session | `wc -l .claude/rules/*.md` × ~7 ≈ tokens |
| `.claude/rules/*.md` WITH `paths:` frontmatter | Only when Claude reads a file matching glob | Deferred — does NOT count toward base |
| Auto-loaded memory entries | Every session (auto-load) | `wc -w` × 1.3 |
| Memory index file | Every session | (always loaded) |
| `.claude/skills/**/SKILL.md` frontmatter (description) | Every session (~100 tokens each) | description string only |
| `.claude/skills/**/SKILL.md` body | When skill activated (NOT base) | Deferred |

Base context = sum of "Every session" rows above.

---

## 3. Per-rule check

Each new rule or rule edit MUST satisfy ONE of:

### 3.1 Path-scoped (preferred)

YAML frontmatter at top:

```yaml
---
paths:
  - "<glob-1>"
  - "<glob-2>"
---
```

Path-scoped rules do NOT count toward base context — they load only when Claude reads a file matching the glob.

### 3.2 Auto-load justification (rare)

Rules that auto-load every session must:
- Have Priority `🔴 CRITICAL` (governance/meta level)
- OR have a section `## Auto-load justification` explaining why it must always-load (e.g. `meta-gap-priority.md`, `incident-to-rule-pipeline.md`, `rule-change-process.md`, `output-review-mandate.md`)
- Total number of CRITICAL auto-load rules kept <15 (per `.claude/rules/README.md` Tier convention)

### 3.3 Hook-covered (alternative for non-file-scope rules)

Rules that trigger via tool patterns (Bash command, edit pattern) rather than file read:
- Implement enforcement in `.claude/hooks/*.py` (PreToolUse / PostToolUse / Stop)
- Rule body documents the hook reference
- Rule frontmatter SHOULD have `paths:` empty (hook handles trigger)

---

## 4. Banned patterns

| ❌ Banned | ✅ Required |
|---|---|
| Add new MANDATORY rule >1k tokens with no `paths:` and no justification | Add `paths:` glob OR `## Auto-load justification` section |
| Multiple narrative `Last-Reviewed` updates → bloat base context | Path-scope rule first; subsequent edits don't grow base |
| Migrate hook → auto-load rule "for visibility" | Hooks are deterministic enforcement; rules are human-readable narrative — don't mix |
| CRITICAL count >15 ("everything is critical") | Reserve CRITICAL for cross-cutting governance only; downgrade to MANDATORY + path-scope when scope narrow |
| Add `paths:` glob too broad (`**/*.md`) — every doc edit triggers load | Narrow scope to actual trigger files (e.g. `documents/**`) |

---

## 5. Worked self-test (context-optimization baseline)

**Pre-optimization state (illustrative):**
- Dozens of rules auto-loaded
- ~237k tokens in base context (rules alone)
- + CLAUDE.md ~25k + memory ~85k = ~347k total base load
- A fresh session consumed a large fraction of the context window before any work

**Post-optimization target:**
- ~14 CRITICAL auto-load (~50k tokens)
- ~30 MANDATORY path-scoped (deferred — load only when a relevant file is in context)
- ~10 MANDATORY hook-covered (no auto-load)
- Base context drop: ~237k → ~50k rules + ~25k CLAUDE.md + ~85k memory = **~160k** (vs ~347k pre)
- Net savings: large fraction of context window per session

→ Rule fires correctly: target met if a baseline measurement records <120k base context. ✅

---

## 6. Enforcement (per `rule-change-process.md` §6.5)

### 6.1 Reviewer-checklist (active now)

Pre-merge review for PR touching `.claude/rules/**/*.md`:
- [ ] New rule: `paths:` frontmatter present? OR `## Auto-load justification` section? OR explicit hook-covered note?
- [ ] Existing rule edit growing >500 lines: re-evaluate whether path-scope still correct?
- [ ] CRITICAL priority justified (cross-cutting governance, NOT domain-specific)?
- [ ] `rules-index.csv` `path_trigger` column matches `paths:` value?

### 6.2 Memory auto-load

A paired memory reminder per session — Claude reviews the context-budget mandate before adding new rules.

### 6.3 Detector

`scripts/check-context-budget.sh` (CI job `context-budget`) — enforces two gates on always-load rules (rules WITHOUT `paths:` frontmatter), byte-based (deterministic, ~4 bytes ≈ 1 token proxy):

| Gate | Threshold | CI behavior |
|---|---|---|
| **TOTAL ceiling** — sum of always-load rule bytes | WARN ≥ 250000 B (~62k tok) / FAIL ≥ 300000 B (~75k tok) | FAIL blocks PR (exit 1) |
| **PER-RULE §3.2** — always-load rule ≥4000 B (~1k tok), NOT Priority CRITICAL, no `## Auto-load justification` | any violation | FAIL blocks (must `paths:`-scope / justify / hook) |

Thresholds tunable via env (`WARN_TOTAL` / `FAIL_TOTAL` / `MIN_BYTES` / `CI_FAIL_PER_RULE`). This is the durable guard against per-session start-context creep — any new always-load rule pushing total over ceiling FAILs CI, forcing path-scope (the §3.1 default).

### 6.4 Override mechanism

Genuine exception (rule must auto-load every session despite size):

```
git commit -m "...
CONTEXT_BUDGET_OVERRIDE: <reason — explain why path-scope/justification both N/A>"
```

Trailer logged in quarterly retro. Pattern frequency >5%/quarter triggers meta-review.

---

## 7. Anti-patterns

| ❌ Don't | ✅ Do |
|---|---|
| "Make it CRITICAL just to be safe" | Default MANDATORY + path-scope; CRITICAL requires explicit justification |
| Add big §Self-test + §Worked example to MANDATORY rule auto-loaded | Move §Self-test to a `tests/` fixture; rule body keeps essence |
| Skip `paths:` "because rule is small (~500 lines)" | Even a small rule × dozens of rules = tens of thousands of tokens |
| Path-scope `paths: ["**/*.md"]` (too broad — every doc edit triggers) | Narrow scope: `documents/**` |
| Allow the memory index to grow unbounded | Per memory governance — keep the index file short |

---

## 8. Relationship to other rules

- **`rule-change-process.md`** §6.5 Enforcement Parity Mandate — this rule + reviewer-checklist + worked self-test all ship same PR
- **`meta-gap-priority.md`** §3 Force-multiplier — context optimization is Meta-P0 (touches every session)
- **`meta-csv-index-pattern.md`** §3 — `rules-index.csv` `path_trigger` column tracks `paths:` per rule
- **`incident-to-rule-pipeline.md`** — coverage-gap → rule conversion pipeline
- **`output-review-mandate.md`** §3 — adds row "Context budget" tracking review standard
- **`.claude/rules/README.md`** — Tier convention (CRITICAL auto / MANDATORY path-scoped / hook-covered)

---

## 9. Log

- **2026-05-14 (v1.1.0):** Extracted into starter-kit from a real 200+ PR project. A growing set of always-loaded rules consumed a large fraction of the context window every session; this rule caps base auto-load and mandates path-scoping or justification for every new always-load rule.
