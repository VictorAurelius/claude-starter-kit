---
paths: ["documents/**", ".claude/rules/**", ".claude/skills/**"]
---

# Docs Filename Prefix Convention — 5-tier taxonomy + audience frontmatter

**Priority:** 🟠 MANDATORY — docs scaling governance (Rule 4/4 docs scaling pack)
**Version:** 1.0.0
**Created:** 2026-05-18
**Last-Reviewed:** 2026-05-18
**Reviewer-Approver:** @nguyenvankiet (starter-kit upstream maintainer)
**Applies to:** Mọi file `.md` mới (hoặc rename) dưới `documents/**`, `.claude/rules/**`, `.claude/skills/**`. Out-of-scope: code files (`.java`/`.ts`/etc.), config files (`.yml`/`.json`), source repo `README.md` ở root level (governed by `readme-content-discipline.md`).

---

## 1. The Rule

> **Mọi filename `.md` mới PHẢI khớp đúng một trong 5 tier prefix taxonomy §2. Multi-tier hybrid (vd `wave-plan-2026-...`) BANNED — chỉ pick MỘT tier canonical.**

Filename prefix = first compass cho reader (Claude + dev) khi scan ls output. Inconsistent prefix → reader phải open file để biết nature → friction cao. 5-tier taxonomy này codify patterns đã emerge tự nhiên (GAP-NNN, ADR-NNN, AUDIT-NNN, YYYY-MM-DD-, wave-, plan-, README, SKILL) thành rule rõ ràng để future files auto-comply.

Force-multiplier: 1 chuẩn chung → mọi file subsequent auto-classifies bằng prefix → ls output đọc được mà không cần open → grep filter dễ → reader velocity tăng.

---

## 2. The 5-tier taxonomy

### Tier 1 — Enumerated ID (🔴 MANDATORY)

Files có canonical sequential ID trong meta CSV indexes (per `meta-csv-index-pattern.md`):

| Prefix | Use case | Example |
|---|---|---|
| `GAP-NNN-` | Gap files trong `documents/04-quality/gaps/**` | `GAP-042-post-wave-audit-suite.md` |
| `ADR-NNN-` | Architecture Decision Records trong `documents/02-architecture/adr/**` | `ADR-007-fe-self-host.md` |
| `AUDIT-NNN-` HOẶC composite ID `AUDIT-YYYY-MM-DD-` | Indexed audits trong `audits-index.csv` | `AUDIT-2026-05-18-ops-readiness.md` |

**Rules:**
- ID PHẢI canonical (sequential, không skip number)
- ID PHẢI khớp CSV row trong matching meta index (`gaps-index.csv` HOẶC `adrs-index.csv` HOẶC `audits-index.csv`)
- Slug sau ID PHẢI lowercase-kebab-case (vd `post-wave-audit-suite`)
- Total filename length ≤80 ký tự khuyến nghị (Linux pathmax không phải vấn đề; reader-friendly là vấn đề)

### Tier 2 — Time-bound (🔴 MANDATORY)

Files là snapshot tại một thời điểm cụ thể (audit report ad-hoc, session handoff, retro, persona review):

| Prefix | Use case | Example |
|---|---|---|
| `YYYY-MM-DD-` | Snapshot artifacts | `2026-05-18-persona-simulation.md` |

**Rules:**
- Date = creation date (default) HOẶC scope-date (per artifact convention — vd audit report dated to scope window not file-creation moment)
- Date PHẢI ISO 8601 strict `YYYY-MM-DD` (4-digit year + zero-padded month/day)
- Date PHẢI lead — không cho phép `audit-2026-05-18-...` (date middle BANNED)
- Slug sau date PHẢI lowercase-kebab-case
- Nếu file là indexed audit có ID → upgrade lên Tier 1 (`AUDIT-NNN-...`); nếu chưa indexed → Tier 2 acceptable

### Tier 3 — Typed (🟧 STRONG_RECOMMEND)

Files thuộc category nghiệp vụ rõ ràng:

| Prefix | Use case | Example |
|---|---|---|
| `wave-{YYYY-MM-DD}-{N}-` | Wave plans (date = wave launch date, N = wave number) | `wave-2026-05-18-42-pre-launch-cluster.md` |
| `plan-` | Generic plans (chiến lược, multi-wave roadmaps không thuộc wave hay release scope) | `plan-ui-ux-design-system-integration.md` |
| `runbook-` HOẶC suffix `-runbook` | Operations runbooks | `secrets-seeding-runbook.md` |
| `release-N-` | Release plans (N = release number) | `release-1-plan.md` |
| `phase-N-` | Phase scope docs (N = phase number) | `phase-1-beta-readiness-runbook.md` |

**Rules:**
- Chỉ ONE prefix tier — `wave-2026-05-18-42-plan-...` (multi-prefix wave+plan) BANNED
- `runbook-` suffix dùng cho doc đứng độc lập (`secrets-seeding-runbook.md`); `runbook-` prefix dùng khi cần group nhiều runbook trong folder (vd `runbook-restore-drill.md`, `runbook-rollback.md` trong cùng folder) — pick một style consistent trong folder
- `phase-N-` + `release-N-` không xung đột với Tier 1 ID schemes (N = scope number, không phải canonical CSV ID)

### Tier 4 — Entry-point UPPERCASE (🔴 MANDATORY)

Files đặc biệt làm "entry point" cho folder hoặc skill — convention UPPERCASE để stand-out trong ls output:

| Filename | Purpose |
|---|---|
| `README.md` | Folder index (per `docs-folder-structure.md` §2) |
| `SKILL.md` | Skill entry-point (per `skill-conventions.md`) |
| `MEMORY.md` | Memory index (per auto-memory convention) |
| `CHANGELOG.md` | Version log (per Keep a Changelog convention) |
| `_TEMPLATE.md` | Template files (underscore prefix denoting "infrastructure", UPPERCASE denoting "template") |

**Rules:**
- Case-sensitive EXACT — `Readme.md`, `readme.md`, `Skill.md` BANNED (filesystem case-sensitive trên Linux production)
- Mỗi folder có TỐI ĐA 1 `README.md` (per folder structure rule)
- `_TEMPLATE.md` placed ngang folder containing actual templated artifacts (vd `documents/03-planning/waves/_TEMPLATE.md` ngang với `wave-*.md`)

### Tier 5 — Plain slug (🟢 ADVISORY default)

Files general-purpose không thuộc Tier 1-4 — rules, general docs, reference materials:

| Filename pattern | Example |
|---|---|
| `{kebab-case-topic}.md` | `.claude/rules/gap-done-discipline.md`, `documents/05-guides/operations/incident-response-runbook.md` |

**Rules:**
- Lowercase-kebab-case (no spaces, no underscores except `_TEMPLATE.md` Tier 4 exception, no CamelCase)
- Slug descriptive (≥2 words preferred — `auth.md` quá vague, `auth-jwt-token-flow.md` clearer)
- Không suffix branding — `gap-done-discipline-RULE.md` BANNED (rule-ness from folder, not suffix)
- Không skip prefix khi file thuộc Tier 1-4 — vd ad-hoc audit không có ID NHƯNG có date → upgrade Tier 2 với date prefix, không stay Tier 5 plain slug

---

## 3. Anti-patterns

| ❌ Don't | ✅ Do |
|---|---|
| `GAP-042-Wave-Audit-Suite.md` (mixed case + spaces) | `GAP-042-post-wave-audit-suite.md` lowercase-kebab |
| `audit-2026-05-18-ops-readiness.md` (date middle) | `2026-05-18-audit-ops-readiness.md` HOẶC `AUDIT-2026-05-18-...md` per Tier 1/2 |
| `wave-42-plan.md` (skip date prefix per Tier 3) | `wave-2026-05-18-42-pre-launch-cluster.md` |
| `Readme.md` HOẶC `readme.md` (case mismatch) | `README.md` UPPERCASE exact |
| `gap-done-discipline-RULE.md` (suffix branding) | `gap-done-discipline.md` plain slug |
| Multi-prefix `wave-plan-2026-05-18-42-...` | Single tier (wave-{date}-N- canonical, KHÔNG add `plan-`) |
| `2026-5-18-...` (single-digit month/day) | `2026-05-18-...` zero-padded ISO 8601 |
| `auth.md` (vague single-word) | `auth-jwt-token-flow.md` descriptive ≥2 words |
| `wave_42_plan.md` (snake_case) | `wave-2026-05-18-42-...md` kebab-case |
| `Wave-2026-05-18-42-...md` (CamelCase first letter) | `wave-2026-05-18-42-...md` all lowercase |
| `runbook.md` HOẶC `RUNBOOK.md` (Tier 3 prefix collision) | `secrets-seeding-runbook.md` descriptive + suffix |
| File ad-hoc audit không có date prefix | Date prefix mandatory cho snapshot artifacts (Tier 2) |

---

## 4. Audience frontmatter (recommended)

Câu hỏi "Claude vs dev readable file naming": **KHÔNG split bằng prefix** (sẽ doubling taxonomy). Thay vào đó dùng frontmatter `audience:` field:

```yaml
---
audience: dev | claude | mixed
---
```

| Value | Use case | Example |
|---|---|---|
| `dev` (default cho user-facing docs) | Tài liệu dev đọc chính (rules, runbooks, plans, gaps, ADRs) | `.claude/rules/*.md`, `documents/03-planning/**`, `documents/05-guides/**` |
| `claude` | Files Claude-only consumes (hooks scripts đi kèm doc, MEMORY.md, agent-internal references) | `.claude/skills/*/reference/*.md` khi reference là Claude prompt context, `MEMORY.md` |
| `mixed` | Default cho most docs — cả Claude + dev đều đọc | Business docs, architecture docs, README files |

**Rules:**
- Optional v1.0.0 — recommend cho new files; existing files grandfathered (no mass backfill)
- Override default per folder qua folder-level README.md note (vd "Files trong folder này default `audience: claude`")
- Phục vụ `context-budget-mandate.md` §3.2 awareness: agent có thể skip-load `audience: dev` files trong path-scope nếu budget tight (future hook enhancement)

---

## 5. Migration path (existing files grandfathered)

Existing files (pre-rule) **KHÔNG** required mass rename. Rule applies prospectively từ next file created/renamed.

**Exception — quarterly retro rename batch:** nếu file vi phạm rule cản trở reader velocity (vd `Readme.md` case mismatch trong production folder), file batch rename PR có thể được proposed during quarterly retro. Pattern frequency violations >10% trong any folder → trigger rename batch.

**Audit trail:** existing files đã được cataloged trong meta CSV indexes per `meta-csv-index-pattern.md`. Indexed files (Tier 1) đã canonical. Non-indexed files (Tier 2-5) bám tự nhiên patterns đã observe được trong §6 self-test.

---

## 6. Worked self-test — retroactive sample

Apply 5-tier taxonomy trên một sample files thực tế. Categorize từng file + flag violations.

### Tier 1 — Enumerated ID

| File | Tier | Verdict |
|---|:---:|:---:|
| `documents/04-quality/gaps/GAP-040-beta-request-abort-cleanup.md` | T1 (GAP-) | ✅ |
| `documents/04-quality/gaps/GAP-041-ops-readiness-audit-deferred.md` | T1 (GAP-) | ✅ |
| `documents/02-architecture/adr/ADR-001-data-model.md` | T1 (ADR-) | ✅ |
| `documents/02-architecture/adr/ADR-002-role-hierarchy.md` | T1 (ADR-) | ✅ |

### Tier 2 — Time-bound

| File | Tier | Verdict |
|---|:---:|:---:|
| `documents/04-quality/audits/quality/2026-05-14-quality-baseline.md` | T2 | ✅ |
| `documents/04-quality/audits/persona-review/2026-05-14-persona-walkthrough.md` | T2 | ✅ |
| `documents/04-quality/audits/security/2026-05-15-owasp-rest-audit.md` | T2 | ✅ |

### Tier 3 — Typed

| File | Tier | Verdict |
|---|:---:|:---:|
| `documents/03-planning/waves/wave-01-foundation.md` | T3 (`wave-`) | ⚠️ legacy — pre-rule `wave-NN-*.md` thiếu date prefix; grandfathered |
| `documents/03-planning/waves/wave-02-data-model.md` | T3 (`wave-`) | ⚠️ legacy — grandfathered |
| `documents/03-planning/roadmap/phase-1-beta-readiness-runbook.md` | T3 (`phase-N-`) | ✅ |
| `documents/03-planning/roadmap/phase-2-migration.md` | T3 (`phase-N-`) | ✅ |
| `documents/05-guides/operations/2026-05-15-secret-rotation-commands.md` | T2 (date prefix) | ✅ — snapshot artifact correctly uses Tier 2 |
| `documents/05-guides/operations/audit-log-retention-runbook.md` | T3 (`-runbook` suffix) | ✅ |

### Tier 4 — Entry-point UPPERCASE

| File | Tier | Verdict |
|---|:---:|:---:|
| `documents/README.md` | T4 | ✅ |
| `.claude/skills/quality-audit/SKILL.md` | T4 | ✅ |
| `documents/03-planning/waves/_TEMPLATE.md` | T4 (`_TEMPLATE`) | ✅ |

### Tier 5 — Plain slug

| File | Tier | Verdict |
|---|:---:|:---:|
| `.claude/rules/admin-merge-discipline.md` | T5 | ✅ |
| `.claude/rules/agent-action-bias.md` | T5 | ✅ |

### Verdict

**Rule fires correctly:** Tier 1-2 + Tier 4 enforcement spot-on. Tier 3 wave plans legacy grandfathered (violations identified for awareness, not for rename). No Tier 5 violations.

**Recommendation cho new wave plans:** dùng `wave-{YYYY-MM-DD}-{N}-{slug}.md` format thay vì `wave-{NN}-{slug}.md` để khớp Tier 3 mandate. Existing legacy waves grandfathered per §5.

---

## 7. Enforcement

### 7.1 Reviewer-checklist (active now)

Pre-merge PR review cho PR touching `documents/**`, `.claude/rules/**`, `.claude/skills/**`:

- [ ] New file matches MỘT Tier (Tier 1-5)?
- [ ] Tier 1 (GAP/ADR/AUDIT): ID canonical (matches CSV row)?
- [ ] Tier 2 (date prefix): `YYYY-MM-DD` ISO 8601 lead?
- [ ] Tier 3 (typed): single prefix, không multi-prefix hybrid?
- [ ] Tier 4 (UPPERCASE): exact case `README.md`/`SKILL.md`/`MEMORY.md`/`CHANGELOG.md`/`_TEMPLATE.md`?
- [ ] Tier 5 (plain slug): lowercase-kebab-case, ≥2 word descriptive?
- [ ] Audience frontmatter set (recommended cho new files)?

### 7.2 CI grep detector (HONEST DEFER — heuristic complexity high, FP risk >5%)

Detector HONEST-deferred per `incident-to-rule-pipeline.md` §3 tightened legitimate-deferral conditions, not boilerplate copy-paste:
- **Detector complexity:** 5-tier classification logic (Tier 1 ID format + Tier 2 ISO 8601 strict + Tier 3 multi-prefix detection + Tier 4 exact-case + Tier 5 kebab-case) — NOT trivial <50 LOC bash
- **FP risk:** Legitimate cases trigger false positives — `_TEMPLATE.md` UPPERCASE valid + composite ID `AUDIT-2026-05-18-*` mixed Tier 1+2 valid
- **Decision:** Reviewer-checklist §7.1 + retroactive self-test §6 sufficient cho v1.0.0; revisit detector when recurrence-count ≥2 OR proven AST classifier available

Future detector heuristic regex (when implemented):

```bash
# Detect mixed-case prefixes
find documents/ .claude/ -name "*.md" -type f 2>/dev/null \
  | grep -E '/(GAP|ADR|AUDIT)-[0-9]+-[A-Z]' \
  && { echo "WARN: Tier 1 ID prefix với UPPERCASE slug — use lowercase-kebab"; exit 0; }

# Detect snake_case + CamelCase in filenames
find documents/ .claude/ -name "*[A-Z]*_*.md" -type f 2>/dev/null \
  | head -5 \
  && { echo "WARN: mixed-case/underscore filename — use lowercase-kebab-case per Tier 5"; exit 0; }

# Detect non-ISO-8601 date prefixes
find documents/ -name "[0-9][0-9][0-9][0-9]-[0-9]-*" 2>/dev/null \
  && { echo "WARN: single-digit month in date prefix — use zero-padded YYYY-MM-DD"; exit 0; }
```

WARN-only (false positives expected — `_TEMPLATE.md` UPPERCASE valid). Track follow-up gap khi stabilize.

### 7.3 Memory auto-load (optional, deferred)

Memory entry reminding tại session start trước file creation. Defer per `incident-to-rule-pipeline.md` premature-rule guard ≥7 ngày; reviewer-checklist + worked self-test sufficient cho v1.0.0.

### 7.4 Cross-reference với `meta-csv-index-pattern.md`

Tier 1 enforcement parallels `meta-csv-index-pattern.md` 100% coverage parity: mọi GAP-NNN/ADR-NNN/AUDIT-NNN file PHẢI có matching CSV row. Filename prefix rule (this file) + CSV coverage rule (meta-csv-index-pattern) cùng wear một guard:
- This rule: ID format compliance trong filename
- That rule: ID presence trong CSV index

Both ship same wave (docs scaling pack Rule 4 + meta-csv-index-pattern).

---

## 8. Override mechanism

Genuine exception (vd vendor template requires specific filename casing, external tool generates files với non-standard names):

```
git commit -m "...
DOCS_FILENAME_PREFIX_OVERRIDE: <file-path> — <reason — e.g., vendor template, external tool output>"
```

Trailer logged. Pattern frequency >5%/quarter triggers meta-review của taxonomy (có thể thiếu tier).

---

## 9. Relationship to other rules

- **`docs-folder-structure.md`** §2 — folder README mandate; Tier 4 `README.md` UPPERCASE enforcement parallel here
- **`skill-conventions.md`** — Tier 4 `SKILL.md` UPPERCASE entry-point mandate
- **`meta-csv-index-pattern.md`** — Tier 1 enumerated ID parity với CSV indexes (paired enforcement)
- **`docs-folder-volume-budget.md`** (Rule 3/4 docs scaling pack) — per-folder caps; this rule governs filename within those folders
- **`docs-subfolder-maturity.md`** (Rule 2/4 docs scaling pack) — subdir creation discipline
- **`docs-archival-cadence.md`** (Rule 1/4 docs scaling pack) — date-prefix Tier 2 artifacts drive cadence detection
- **`output-review-mandate.md`** §3 — review standards matrix; row "Docs filename prefix" tracking this rule
- **`readme-content-discipline.md`** — root `README.md` content rules separate scope; this rule's Tier 4 mandate filename casing only
- **`rule-change-process.md`** §6.5 Enforcement Parity Mandate — rule + reviewer-checklist + worked self-test all paired same PR
- **`incident-to-rule-pipeline.md`** — applied 5-stage pipeline
- **`context-budget-mandate.md`** §3.2 — path-scope frontmatter trong this rule (auto-load only khi documents/.claude/rules/.claude/skills touched, không global session); audience frontmatter §4 future hook integration

---

## 10. Log

- **2026-05-18 (v1.0.0):** Extracted into starter-kit from a real 200+ PR project. Rule 4/4 of the docs scaling pack — codifies a 5-tier filename prefix taxonomy (enumerated ID / time-bound / typed / entry-point UPPERCASE / plain slug) plus an `audience:` frontmatter so ls output is self-describing as docs scale.
