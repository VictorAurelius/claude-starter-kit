---
paths:
  - "CLAUDE.md"
---

# CLAUDE.md Content Discipline — base context budget guard

**Priority:** 🟠 MANDATORY — base-context-budget governance
**Version:** 1.0.0
**Created:** 2026-05-15
**Last-Reviewed:** 2026-05-15
**Reviewer-Approver:** @nguyenvankiet (starter-kit upstream maintainer)
**Applies to:** Every PR touching `CLAUDE.md` (project root) — this file auto-loads 100% of every session, every turn → each extra line is a tax on every future turn

---

## 1. The Rule

> **CLAUDE.md must stay <= 250 lines (target ~200).** Any detailed content (specific mechanism, examples, checklist) MUST live in its own path-scoped rule file, and CLAUDE.md holds only a 1-line pointer.

CLAUDE.md auto-loads 100% of every session, every turn (per `context-budget-mandate.md` §2). One extra line × N sessions × N turns = a fast-accumulating cost. CLAUDE.md is one of the three big base-context sources (CLAUDE.md + always-load rules + memory).

---

## 2. Content ceiling + structure

| Section | Purpose | Max lines |
|---|---|---|
| Communication language | 4 lines max | 4 |
| Current Phase | Active phase + locked decision context | 20 |
| Operational shortcuts (start/stop, override pointer) | Each shortcut 1-2 lines + link to rule | 15 |
| Project Overview | Product line definitions | 10 |
| Methodology summary | Steps + link to core skills | 15 |
| Build / Git workflow / Branch strategy | Each major workflow ~5 lines + link | 30 |
| Business Logic / domain doc pattern | Pattern + file template + link | 15 |
| Living Documents | Table + 1-line rule | 10 |
| Skills Reference | Index pointer only + main category list | 30 |
| Folder Structure + Naming | Reference tables | 20 |
| **Total target** | | **<200** |

Sections not in this table = candidate for deletion or move to a rule.

---

## 3. Banned content (move to a rule file)

| ❌ Banned in CLAUDE.md | ✅ Where it goes |
|---|---|
| Detailed step-by-step procedure (5+ bullet steps) | Path-scoped rule `.claude/rules/*.md` |
| Concrete code examples (>10 lines) | Skill `.claude/skills/**/SKILL.md` |
| Self-test / worked examples | Rule `_examples/` folder |
| Detector regex / hook logic | `.claude/hooks/*.py` |
| Override mechanism table (when X allowed, when Y banned, etc.) | Dedicated rule file |
| Specific gap numbers / PR refs in narrative | Memory entries or ROADMAP |
| Anti-pattern table >5 rows | Rule file |
| Multi-section deep-dive (>15 lines for one concept) | Split into a rule file + 1-line pointer in CLAUDE.md |

---

## 4. Required pattern for new CLAUDE.md additions

When adding a new concept to CLAUDE.md, each addition MUST follow the pattern:

```markdown
**<Concept name>:** <one-sentence summary>. Process / detail: `.claude/rules/<rule-name>.md` (path-scoped).
```

Correct example:
```markdown
**Authorized override:** when the dev says "I authorize" → the agent may trigger the gated workflow (overrides the default BANNED). Detailed process: `.claude/rules/<override-rule>.md`.
```

Wrong example (bloat):
```markdown
**Authorized override:** when the dev says the following phrases...
1. Mandatory pre-flight...
2. Pre-mutation audit...
3. Default dry-run first...
[20+ more lines]
```

---

## 5. Banned shortcuts

| ❌ Don't | ✅ Do |
|---|---|
| "CLAUDE.md is the master doc, the fuller the better" | CLAUDE.md is an INDEX; detail lives in rule files |
| Copy-paste rule content into CLAUDE.md "to make it visible" | 1-line link; rule loads on-demand via `paths:` |
| Add a new section because it's "important" | Quantify: section >10 lines → split into a rule |
| Inline a workflow diagram, ASCII art | External file + link |
| List 10 file paths inline | Link the folder + main 3-5 paths |
| Forward-date "next milestone will need..." | CLAUDE.md = current-state truth, no placeholders |

---

## 6. Worked self-test — override addition

**Scenario:** User asks to add an authorized-override note to CLAUDE.md.

**Attempt 1 (bloated — violates rule):**
- Added a 30-line section directly to CLAUDE.md with a phrase list + 5-gate procedure + out-of-scope table
- User flagged: "CLAUDE.md edit too long, keep it short, it affects start-session context"
- → Confirmed rule violation; net +30 lines permanent base context

**Attempt 2 (correct per §4 pattern):**
- CLAUDE.md gets 1 paragraph: "Authorized override: ... Detailed process: `.claude/rules/<override-rule>.md`"
- Detailed mechanism → its own path-scoped rule (NOT base load)
- Net CLAUDE.md cost: ~3 lines vs ~30 lines

→ Rule fires correctly on the originating incident. Self-test PASS ✅

Counterfactual cost if rule existed at attempt time:
- Attempt 1 caught immediately by §3 banned-content check (multi-bullet procedure → BANNED)
- §4 pattern auto-applied
- User round-trip saved
- Base context: 3 lines (vs 30) — savings ~95% for this addition

---

## 7. Enforcement (per `rule-change-process.md` §6.5)

### 7.1 Reviewer-checklist (active now)

Each PR touching `CLAUDE.md`:
- [ ] Total CLAUDE.md lines after PR ≤250?
- [ ] Each section belongs to table §2? If NO → split into a rule
- [ ] No §3 banned content appears?
- [ ] New addition follows §4 pattern (1-liner + link)?
- [ ] Linked rule file already exists (path-scoped)?

### 7.2 Memory auto-load (optional)

A paired memory reminder — auto-load each session so Claude pre-checks before adding a section.

### 7.3 CI grep detector (deferred per `incident-to-rule-pipeline.md` premature-rule guard)

Future: `scripts/check-claude-md-size.sh` counts lines + greps banned-content patterns. CI fails if >250 lines or matches banned patterns. Deferred; reviewer-checklist + worked self-test sufficient for v1.0.0.

### 7.4 Override mechanism (rare)

Genuine exception (CLAUDE.md needs a detailed section because no corresponding rule scope exists):

```
git commit -m "...
CLAUDE_MD_BLOAT_OVERRIDE: <reason — e.g. 'no path-scope rule applicable, content cross-cuts'>"
```

Trailer logged. Pattern frequency >2/quarter → meta-review.

---

## 8. Anti-patterns

| ❌ Don't | ✅ Do |
|---|---|
| Add detailed rule content into CLAUDE.md "so devs see it easily" | Path-scoped rule — Claude auto-loads when context matches |
| Skip path-scope because "this rule is important" | Path-scope does NOT reduce importance — only defers load |
| Treat a CLAUDE.md edit like a rule edit (full version bump + log) | CLAUDE.md is an index, not governed by `rule-change-process.md`; this rule is the governance layer |
| Restructure CLAUDE.md every milestone | Stability matters — restructure ≤1×/quarter |

---

## 9. Relationship to other rules

- **`context-budget-mandate.md`** §2 — sister rule for rules + memory; this rule is specific to CLAUDE.md scope
- **`rule-change-process.md`** §6.5 Enforcement Parity Mandate — rule + reviewer-checklist + worked self-test all ship same PR
- **`docs-folder-structure.md`** — generic folder rule; this rule = specialized for root CLAUDE.md
- **`readme-content-discipline.md`** — sister rule for root README.md (volatile content denylist + stable allowlist); same pattern, different file
- **`incident-to-rule-pipeline.md`** — coverage-gap → rule conversion pipeline
- **`output-review-mandate.md`** §3 — adds row "CLAUDE.md content" tracking review standard

---

## 10. Log

- **2026-05-15 (v1.0.0):** Extracted into starter-kit from a real 200+ PR project. CLAUDE.md auto-loads on every turn, so unchecked growth taxes every future session; this rule caps it at ~200 lines and forces detail into path-scoped rule files with 1-line pointers.
