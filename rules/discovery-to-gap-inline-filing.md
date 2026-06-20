# Discovery-to-Gap Inline Filing Mandate — file ngay khi phát hiện, không stash

**Priority:** 🟠 MANDATORY — discovery hygiene governance
**Version:** 1.0.0
**Created:** 2026-06-03
**Last-Reviewed:** 2026-06-03
**Reviewer-Approver:** @nguyenvankiet (starter-kit upstream maintainer)
**Applies to:** Mọi work session sinh discovery (gap-worthy finding) từ scope KHÔNG phải audit — docs writing / refactor / debug / cleanup / migration / code-read / design review. Out-of-scope: audit runs (covered by `audit-to-gap-pipeline.md`), bug-fix sweep (covered by `cross-flow-bug-class-sweep.md`), user-flagged miss (covered by `incident-to-rule-pipeline.md`).

---

## 1. The Rule

> **Khi đang làm ANY task (docs writing / refactor / debug / cleanup / migration / code-read) mà tình cờ discover gap-worthy finding (drift / bug / anti-pattern / TODO / security risk / contract mismatch / schema anomaly / dead code / etc.), PHẢI file gap inline trong cùng session — không stash sang "follow-up sau".**

Discovery stuck trong narrative section (vd "Ghi chú schema anomalies" trong docs PR) → KHÔNG vào `gap-status.csv` → KHÔNG trigger fix pipeline → silent decay risk "quên".

Sister rules cover adjacent boundaries:
- `audit-to-gap-pipeline.md` §3 — formal audit run → gap files (audit boundary)
- `cross-flow-bug-class-sweep.md` §1 — bug fix lands → sweep sister code sites (fix-then-sweep direction)
- `incident-to-rule-pipeline.md` — user-flagged miss → permanent rule guard (coverage-gap meta)
- **This rule** — non-audit work → tình cờ discovery → gap file inline (work-then-file direction)

Force-multiplier: 1 chuẩn file-inline → mọi discovery subsequent enters CSV-canonical fix pipeline → eliminate silent-decay class.

---

## 2. Trigger pattern — đang làm gì × discover gì

Rule fires khi current task scope ≠ audit AND discovery matches gap-worthy class:

| Đang làm | Discover gì | Fire rule? |
|---|---|---|
| **Docs writing** (schema docs, ADR draft, runbook) | Schema anomaly / inconsistent naming / orphan FK / column type mismatch | ✅ YES |
| **Docs writing** | TODO comment trong code mentioning unresolved decision | ✅ YES |
| **Refactor** (rename class, extract helper) | Dead code / unused import / commented-out block / orphan test | ✅ YES |
| **Refactor** | Anti-pattern repeated trong sister flows | ✅ YES (also triggers `cross-flow-bug-class-sweep.md`) |
| **Debug** (chasing an incident) | Sister bug surfaced trong same area | ✅ YES |
| **Debug** | Missing log / observability gap / monitoring hole | ✅ YES |
| **Cleanup** (delete temp files, archive old docs) | Active artifact mis-located / stale state / drift | ✅ YES |
| **Migration** (DB migration V→V+1) | Schema constraint missing (NOT NULL / index / access-control policy) | ✅ YES |
| **Code-read** (understanding flow) | Security risk (raw SQL / unescaped output / missing auth check) | ✅ YES |
| **Code-read** | API contract mismatch (BE route ≠ FE call site) | ✅ YES |
| **Design review** (UI mockup → impl walk) | Affordance missing / state unhandled / accessibility gap | ✅ YES |
| **Routine task** (dependency install, PR merge) | Unrelated CI fail surface | ❌ NO — already in CI flow, fix per CI cycle |
| **Pure typo fix** trong narrative | Tangential typo trong adjacent paragraph | ❌ NO — fix inline, không gap-worthy |
| **Audit run** | Audit finding | ❌ NO — `audit-to-gap-pipeline.md` covers |

Rule **KHÔNG** fires khi:
- Discovery scope khớp 1 task-scope hiện tại + fix nhỏ inline (single-line typo / variable rename) → fix trực tiếp, không cần gap
- Discovery đã có gap mở khớp scope → comment vào gap hiện tại, không tạo duplicate
- Discovery thuộc audit scope → `audit-to-gap-pipeline.md` §3 đường nhánh chính

---

## 3. Required artifacts mỗi discovery

Khi rule fires, PHẢI tạo gap file minimal format (per `audit-to-gap-pipeline.md` §3 template, simplified):

### 3.1 Gap file minimum content

```markdown
# GAP-NNN: [Title — 1 line describing finding]

**Status:** 🔵 OPEN
**Priority:** 🔴 P0 / 🟠 P1 / 🟡 P2 / 🟢 P3
**Domain:** [Frontend / Backend / DB / DevOps / Docs]
**Found:** YYYY-MM-DD ([scope context — vd "DB cluster docs writing"])
**Affects:** [scope — table/file/service]

## Problem

[1-2 paragraph describing finding. Cite source: "Discovered while writing X" + concrete evidence (file:line, schema dump, log snippet).]

## Proposed Fix

[1-2 sentence: high-level approach. Detail deferred to fix PR — gap is filing, not designing.]

## Acceptance Criteria

- [ ] [1-3 measurable criteria]

## Related

- Discovered in: [PR # OR commit SHA OR session ID]
- [Sister GAP-XXX if known]
```

### 3.2 File location

Per `gap-folder-organization.md`: file vào `documents/04-quality/gaps/<phase>/` matching gap phase scope. Default = the active phase folder. Run `bash scripts/check-gap-folder-location.sh` để verify.

### 3.3 CSV row mandatory

Per `meta-csv-index-pattern.md` §4 + `gap-architecture-v2.md`: PHẢI add row vào `documents/04-quality/gaps/gap-status.csv` cùng commit với gap file.

### 3.4 Cross-reference từ originating work

Trong PR body của work session (docs PR / refactor PR / debug PR), thêm section:

```markdown
## Discoveries filed (per discovery-to-gap-inline-filing.md §3)

- GAP-NNN: <1-line finding> (P-level, domain)
- GAP-NNN+1: <1-line finding>
- ...
```

Để reviewers + future readers thấy work session đã spawn N gaps.

---

## 4. Banned shortcuts

| ❌ Don't | ✅ Do |
|---|---|
| Stash discovery vào narrative ("Note: schema anomaly detected — fix later") | File gap inline cùng session |
| Defer "will file gap next session" | Next session = lose context = silent decay; file NOW |
| Bulk-list 10 anomalies trong 1 gap | 1 gap = 1 finding (per `audit-to-gap-pipeline.md` §3 anti-pattern) |
| Skip CSV row "vì gap small" | CSV row mandatory per `meta-csv-index-pattern.md` 100% coverage |
| File gap nhưng không reference từ originating PR body | PR body MUST cite §3.4 section cho reviewer trail |
| Comment vào docs narrative thay vì gap file | Narrative = read-only context; gap = actionable fix tracker |
| File gap mà không check duplicate (per `audit-to-gap-pipeline.md` §2) | Run `bash scripts/query-gaps.sh --grep <keyword>` trước khi tạo |
| Treat docs PR + N discovery gaps là "out of scope" | Discovery gaps ship same wave hoặc next wave; KHÔNG dump vào backlog mà không file |

---

## 5. Override mechanism

Genuine exception (discovery scope vượt quá ngắn-hạn session capacity, vd ≥10 anomalies cùng class cần dedicated triage wave):

```
git commit -m "...
DISCOVERY_GAP_DEFER: <topic> — <reason — e.g. 'multiple schema anomalies surfaced in a cluster docs pass, need dedicated triage wave'>
DISCOVERY_GAP_FOLLOWUP: <gap link OR wave plan link tracking batch filing within Ndays>"
```

Trailer logged. Pattern frequency >10%/quarter triggers meta-review (likely scope mis-defined OR work-then-file discipline failing).

**Exception rate target:** <5% session-wide. Higher rate = sign rule scope mis-tuned OR session hygiene drift.

---

## 6. Worked self-test — documentation pass discovery cluster

**Scenario:** A milestone ships a set of cluster DB docs (several PRs in parallel). Each cluster doc contains a "Ghi chú schema anomalies" section listing ~10 anomalies = ~50 anomalies surfaced across the set. At rule-creation moment: PRs merged, 0 gap files filed, 0 CSV rows added — anomalies stuck trong narrative.

**Apply rule retroactively (counterfactual):** Cluster 1 author writing RBAC schema discovers `user_roles.role_id` orphan FK → per §1 file gap inline THIS session → §3.1 GAP-NNN file + §3.3 CSV row + §3.4 cite trong PR body `## Discoveries filed`. Pattern × N discoveries × N clusters.

| Metric | Without rule | With rule |
|---|---|---|
| Gap files filed | 0 | ~50 |
| CSV rows | 0 | ~50 |
| Per-discovery file overhead | n/a | ~2-3 min |
| Batch retroactive cost | ~2-3h | 0 |
| Silent-decay risk | HIGH | LOW |
| Discovery-to-fix pipeline | Broken | Functional |

**Save:** ~2-3h batch-filing eliminated + silent-decay risk eliminated. Per-discovery ~2-3 min × 50 ÷ N PRs ≈ ~25 min/PR overhead (acceptable). **Verdict:** Rule fires correctly on originating incident. Self-test PASS ✅.

---

## 7. Auto-load justification (per `context-budget-mandate.md` §3.2)

Rule này KHÔNG dùng `paths:` frontmatter — luôn auto-load mỗi session. Lý do:

- **Fire tại discovery decision-time, không file-read-time** — rule kích hoạt khi vừa phát hiện gap-worthy finding trong ANY work scope (docs / code / config / migration). Không có natural file-scope glob: discovery có thể surface trong `documents/**` (docs writing), `**/*.java`/`**/*.ts` (code-read), `**/*.sql` (migration review), infra config (cleanup). Path-scope tới mọi source = quá rộng, gần như always-load anyway.
- **Path-scope sẽ miss case quan trọng** — nếu scope `.claude/rules/**` only, rule vắng mặt khi làm task non-rule work (đa số session). Đúng case rule cần fire nhất.
- **Hook-cover không khả thi v1** — phát hiện "vừa surface gap-worthy finding trong narrative" cần NLP trên response candidate, vượt khả năng deterministic hook (PreToolUse/PostToolUse fire ở tool-call boundary, không ở reasoning-discovery moment).
- **Token cost chấp nhận được** — force-multiplier mỗi session file 1+ inline gap thay vì stash vào narrative → eliminate silent-decay class.
- **Priority 🟠 MANDATORY giữ nguyên** — không nâng CRITICAL vì §5 exception cho phép defer P-level scope vượt session capacity; auto-load áp dụng theo `context-budget-mandate.md` §3.2 row 2.

Re-evaluate nếu: (a) pre-text-output NLP hook detect "discovery in narrative" pattern khả dụng, (b) > 5 false-positive trên session/quarter, (c) rule grows > 300 lines.

---

## 8. Enforcement (per `rule-change-process.md` §6.5 Enforcement Parity Mandate)

### 8.1 Reviewer-checklist (active now)

Pre-merge review cho non-audit work PR (docs / refactor / debug / cleanup / migration / design):

- [ ] PR body có section `## Discoveries filed` (per §3.4)?
- [ ] Nếu CÓ — số gap files referenced khớp count actual filed cùng commit?
- [ ] Nếu KHÔNG — PR thực sự không surface discovery nào? Hoặc stashed trong narrative (vi phạm rule)?
- [ ] Mỗi gap filed có CSV row (per `meta-csv-index-pattern.md` 100% coverage)?
- [ ] Mỗi gap follow folder structure (per `gap-folder-organization.md`)?

### 8.2 Self-detection (in-turn)

Trước khi write text chứa pattern "Note: <anomaly>" / "TODO: <missing>" / "Schema anomaly:" / "Drift:" / "<inconsistency> here" trong narrative của docs/code/PR-body, mentally run check:
- Đây có phải gap-worthy finding (§2 trigger match)?
- Nếu CÓ → STOP narrative write → file gap inline first → cite gap reference trong narrative thay vì stash anomaly
- Nếu KHÔNG → narrative note OK

### 8.3 Memory auto-load (paired same-PR)

Paired memory entry loads at session start, reminds checklist trước khi stash discovery vào narrative.

### 8.4 Detector (HONEST DEFER per `incident-to-rule-pipeline.md` §3.1 tightened conditions)

- **Detector complexity:** Scan PR body / commit body cho discovery keywords ("anomaly", "drift", "TODO", "missing", "inconsistent") trong narrative WITHOUT corresponding gap file diff — requires NLP discovery classification + diff inspection, NOT trivial bash
- **Recurrence count:** 1
- **FP risk:** High — legitimate narrative often mentions "missing X (to be designed)" trong scope context, not gap-worthy
- **Decision:** Reviewer-checklist §8.1 + memory auto-load §8.3 + worked self-test §6 sufficient cho v1.0.0; revisit detector when recurrence-count ≥2 post-rule

### 8.5 Override mechanism

Per §5 trailer `DISCOVERY_GAP_DEFER:` — logged quarterly retro. Pattern frequency > 10%/quarter → meta-review.

---

## 9. Anti-patterns

| ❌ Don't | ✅ Do |
|---|---|
| Treat docs PR as "docs-only" exempt from discovery filing | Docs PRs spawn most discoveries (re-reading code surfaces hidden issues) |
| Bulk-file all discoveries trong 1 mega-gap | 1 gap = 1 finding; bulk-filing erases triage signal |
| Skip gap "vì discovery trivial" | Trivial-looking discovery often masks systemic issue |
| Wait until session end để batch-file | Mid-session context preserves discovery detail; end-session context fades |
| Stash anomaly trong commit message "for posterity" | Commit message ≠ CSV-canonical; will be lost in git log noise |
| File gap nhưng quên CSV row | CI fails per `meta-csv-index-pattern.md` 100% coverage gate |
| Hide discovery trong PR body comment thay vì gap file | Comment != actionable; gap file = trackable |
| Use override trailer cho normal scope discoveries | Override trailer reserved cho genuine batch overflow (≥10 same-class anomalies) |

---

## 10. Relationship to other rules

- **`audit-to-gap-pipeline.md`** §3 — sister covering AUDIT direction; this rule covers NON-AUDIT work direction. Same gap-file format, different trigger boundary.
- **`cross-flow-bug-class-sweep.md`** §1 — sister covering bug-fix→sweep direction; this rule covers work→discovery direction. Both can co-apply.
- **`incident-to-rule-pipeline.md`** — covers user-flagged-miss→rule direction. This rule = direct output applied to "non-audit discovery" coverage gap.
- **`gap-architecture-v2.md`** + **`gap-folder-organization.md`** — gap file format + folder. §3.1/3.2 honor.
- **`meta-csv-index-pattern.md`** §4 — 100% CSV coverage. §3.3 honors.
- **`gap-done-discipline.md`** — DONE flip at closure (downstream).
- **`rule-change-process.md`** §6.5 Enforcement Parity — rule + checklist + memory + self-test paired same PR.
- **`meta-gap-priority.md`** §3 — META P1 force-multiplier.
- **`output-review-mandate.md`** §3 — paired matrix row "Discovery during non-audit work".
- **`context-budget-mandate.md`** §3.2 — auto-load justified §7.
- (paired memory entry, same-PR).

---

## 11. Log

- **2026-06-03 (v1.0.0):** Extracted into starter-kit from a real 200+ PR project. Codifies the work-then-file-inline discipline after a documentation pass surfaced ~50 schema anomalies stuck in narrative sections with zero gap files filed — closing the silent-decay class where non-audit discoveries never enter the canonical fix pipeline.
