---
paths:
  - "documents/04-quality/audits/**/*.md"
  - "documents/03-planning/session-handoffs/**/*.md"
  - "documents/03-planning/waves/**/*.md"
  - "documents/03-planning/pr-logs/**/*.json"
---

# Docs Archival Cadence — auto-archive time-bound artifacts to prevent docs accumulation

**Priority:** 🟠 MANDATORY — docs lifecycle + volume governance
**Version:** 1.0.0
**Created:** 2026-05-18
**Last-Reviewed:** 2026-05-18
**Reviewer-Approver:** @nguyenvankiet (starter-kit upstream maintainer)
**Applies to:** Time-bound artifacts trong `documents/04-quality/audits/**` + `documents/03-planning/session-handoffs/**` + `documents/03-planning/waves/**` + `documents/03-planning/pr-logs/**`. KHÔNG áp dụng cho: `ROADMAP.md`, gap files (`documents/04-quality/gaps/**` — đã có separate flow per `audit-to-gap-pipeline.md`), READMEs, canonical living docs (CLAUDE.md, business rules docs).

---

## 1. The Rule

> **Time-bound artifacts có ngày sản xuất xác định (audit, session-handoff, wave plan, PR-log) PHẢI được archive khi vượt ngưỡng tuổi theo §2 Cadence table. Archive destination tuân theo §3 convention. Reviewer enforce per-merge; CI detector script defer ≥7 ngày per `incident-to-rule-pipeline.md` premature-rule guard.**

Rationale: time-bound artifacts (audit reports + PR-logs + session-handoffs) có giá trị cao trong ngắn hạn (≤90 ngày) cho debug + retro, value giảm exponentially sau đó. Khi không archive, cognitive load tăng + grep noise + git diff bloat + parent context burn (Claude session đọc nhầm stale audit thay vì latest).

Force-multiplier: 1 cadence chuẩn → mọi artifact subsequent auto-comply → eliminate retroactive cleanup cost mỗi quý.

---

## 2. Cadence table (mandatory)

| Artifact type | Folder pattern | Cadence (≥ N ngày tuổi) | Tuổi tính từ | Archive destination |
|---|---|---|---|---|
| **Audit reports** | `documents/04-quality/audits/**/*.md` có date-prefix `YYYY-MM-DD-*.md` HOẶC date trong filename | **90 ngày** | Date prefix trong filename | `documents/04-quality/audits/{category}/closed/{year}-Q{N}/` |
| **Session handoffs** | `documents/03-planning/session-handoffs/*.md` | **30 ngày** | Date prefix trong filename | `documents/07-archived/planning-{year}/session-handoffs/` |
| **Wave plans (closure status:complete)** | `documents/03-planning/waves/*.md` có frontmatter `status: complete` HOẶC `status: closed` | **60 ngày POST closure date** | `closed_at` field trong frontmatter HOẶC last git commit date sau status flip | `documents/07-archived/planning-{year}/waves/` |
| **PR-logs** | `documents/03-planning/pr-logs/PR-*.json` | **180 ngày** | Git log creation date (`git log --diff-filter=A --format='%ad' --date=short -- <file>`) | `documents/07-archived/pr-logs-{year}/` |

### 2.1 Tuổi tính như thế nào (precedence)

1. **Frontmatter date field** (preferred — `created`, `closed_at`, `archived_at`)
2. **Date prefix trong filename** (`YYYY-MM-DD-*.md`) — pattern phổ biến của audit + session-handoff
3. **Git log creation date** (`git log --diff-filter=A`) — fallback cho PR-logs JSON + waves không có frontmatter date

### 2.2 Cadence tuning rationale

| Cadence | Lý do |
|---|---|
| 30 ngày (session-handoffs) | Session context lifetime ngắn; sau 30 ngày, info đã chuyển vào ROADMAP / memory / wave plans canonical |
| 60 ngày POST closure (wave plans) | Wave plans cần reference window 60 ngày cho retro + post-wave audit suite refresh; sau 60 ngày retro xong, archive |
| 90 ngày (audit reports) | Audit reports value cao cho quarterly retro + cross-wave trend; 90 ngày = 1 quarter coverage |
| 180 ngày (PR-logs) | PR-logs value tra cứu lịch sử merge; 180 ngày = 2 quarter, đủ cho compliance audit + incident RCA |

Re-evaluate cadence khi: (a) project phase transition (volume tăng 2-3x), (b) team grows beyond solo (cần reference window dài hơn), (c) compliance audit yêu cầu retention dài hơn.

---

## 3. Archive destination convention

### 3.1 Naming pattern

```
documents/04-quality/audits/{category}/closed/{year}-Q{N}/   # cho audits
documents/07-archived/planning-{year}/session-handoffs/      # cho session-handoffs
documents/07-archived/planning-{year}/waves/                 # cho wave plans
documents/07-archived/pr-logs-{year}/                        # cho PR-logs JSON
```

### 3.2 Quarter mapping

| Quarter | Tháng |
|---|---|
| Q1 | January, February, March |
| Q2 | April, May, June |
| Q3 | July, August, September |
| Q4 | October, November, December |

Ví dụ: audit file dated `2026-02-15` archive khi ≥90 ngày (2026-05-15+) vào `documents/04-quality/audits/quality/closed/2026-Q1/`.

### 3.3 Folder creation

Khi archive folder chưa tồn tại → tạo cùng `README.md` 1-line:

```markdown
# {Year}-Q{N} {Type} Archive

Closed artifacts từ Q{N} {year} theo `.claude/rules/docs-archival-cadence.md` §3.

Total files: <auto-count>
Archive date: <YYYY-MM-DD>
```

### 3.4 Cross-references preservation

Khi archive 1 file:
- Update internal links: `documents/04-quality/audits/quality/audit.md` → `documents/04-quality/audits/quality/closed/2026-Q1/audit.md`
- Search outbound references: `grep -rl "<original-path>" documents/ .claude/ README.md ROADMAP.md`
- Update top 5 high-value references (audits-index.csv, ROADMAP, related rules); accept link rot cho low-value references (one-off mentions trong old gaps)

---

## 4. Enforcement

### 4.1 Reviewer-checklist (active now)

Pre-merge review cho PR touching `documents/04-quality/audits/**`, `documents/03-planning/session-handoffs/**`, `documents/03-planning/waves/**`, `documents/03-planning/pr-logs/**`:

- [ ] PR thêm file mới — check folder có files quá tuổi theo §2 không (manual `find ... -mtime +N` hoặc filename date check)
- [ ] Nếu có ≥5 files quá tuổi → file follow-up gap "Q{N} {year} archive batch" + schedule trong wave hiện tại
- [ ] PR archive-batch (move files vào `closed/` hoặc `07-archived/`) — verify destination tuân §3 + README created + cross-references updated cho top 5 high-value

### 4.2 Cadence audit (quarterly retro)

Mỗi quarterly retro PHẢI run heuristic check:

```bash
# Audits >90d
find documents/04-quality/audits -type f -name "*.md" | while read f; do
  filedate=$(basename "$f" | grep -oE '^[0-9]{4}-[0-9]{2}-[0-9]{2}')
  [ -n "$filedate" ] && [[ "$filedate" < "$(date -d '90 days ago' +%Y-%m-%d)" ]] && echo "$f"
done | wc -l

# Session handoffs >30d
# Wave plans >60d post-closure (cần inspect frontmatter)
# PR-logs >180d (git log date)
```

Pattern stale count >20 files → file batch-archive gap trong wave kế tiếp.

### 4.3 CI detector script

Optional CI script `scripts/check-docs-archival-stale.sh` (<130 LOC bash, low FP risk, complements §2 cadence) — wire CI job `docs-scaling-detectors`:
- WARN-mode initially (existing files grandfathered; rule prospective)
- Override trailer: `DOCS_ARCHIVAL_OVERRIDE: <path> — <reason>` per §5
- HARD STOP target after 30-day grace period + first batch archive PR triages legacy violations

### 4.4 Memory auto-load (optional, deferred)

Memory entry reminding tại session start trước khi accumulating audit/session-handoff/wave. Defer per `incident-to-rule-pipeline.md` premature-rule guard ≥7 ngày; reviewer-checklist + worked self-test đủ cho v1.0.0.

---

## 5. Override mechanism

Genuine exception (artifact giá trị reference dài hạn vượt cadence — ví dụ landmark audit, milestone wave plan, compliance evidence):

```
git commit -m "...
DOCS_ARCHIVAL_OVERRIDE: <artifact path> — <reason — e.g. landmark milestone wave plan retain in-place cho cross-quarter trend reference; compliance evidence audit retain per retention policy>"
```

Trailer logged trong quarterly retro. Pattern frequency >10% artifacts override mỗi quý → meta-review thresholds (có thể cadence quá ngắn).

Common valid override cases:
- Milestone audit (e.g. release-landing audit) — retain in-place cho cross-quarter trend reference
- Compliance evidence (audit log, audit trail) — retain theo retention policy >180 ngày
- Active reference (rule cross-link tới a specific audit — retain cho rule lifetime)

---

## 6. Worked self-test — retroactive cadence check

Apply §2 cadence retroactively vào current project state. Illustrative numbers from a project with active history starting ~80 days before rule landing:

### 6.1 Baseline numbers

| Artifact type | Total files | Cadence threshold (today) | Files quá tuổi |
|---|---|---|---|
| Audit reports | 204 | (90 ngày) | **0** |
| Session handoffs | 11 | (30 ngày) | **0** |
| Wave plans | 107 (22 không có date filename) | (60 ngày) | **0 by filename heuristic** |
| PR-logs | 116 | (180 ngày) | **0 by git log date** |

### 6.2 Sample oldest per loại (sẽ hit cadence sớm nhất)

**Audits** — oldest file ~80 days old, sẽ hit 90d threshold trong ~9 ngày nữa.
**Session-handoffs** — mọi files hiện ≤4 ngày old; sẽ hit 30d threshold trong ~26 ngày.
**Wave plans** — oldest ~20d; 22 files no-date-filename cần manual frontmatter inspection.
**PR-logs** — oldest ~31d; sẽ hit 180d threshold trong ~149 ngày.

### 6.3 Verdict

**Self-test PASS ✅** — rule fires correctly:
- Baseline = 0 files quá tuổi vì project active history mới ~80 ngày
- Rule applies prospectively — first batch archive sẽ trigger khi oldest audit file hit 90d
- **Counterfactual**: nếu rule không tồn tại, accumulation projected ~200+ files giá trị low-reference chiếm cognitive load + grep noise trong 12 tháng

**Action signal:** prep first batch archive trong wave khi oldest audit file hit threshold.

---

## 7. Relationship to other rules

- **`docs-folder-structure.md`** §3 — folder layout convention cho `documents/`; rule này extend với lifecycle/cadence dimension
- **`docs-folder-volume-budget.md`** (Rule 3 of docs scaling pack) — volume-based trigger; time-bound folders gặp cap → archive cadence is the natural response
- **`docs-subfolder-maturity.md`** (Rule 2 of docs scaling pack) — subdir creation discipline
- **`docs-filename-prefix-convention.md`** (Rule 4 of docs scaling pack) — date-prefix Tier 2 artifacts drive cadence detection here
- **`audit-to-gap-pipeline.md`** — gap closure flow (gaps có separate archive pattern `documents/04-quality/gaps/closed/`); rule này NOT cover gaps (per scope clarification §Applies to)
- **`output-review-mandate.md`** §3 — row "Docs archival cadence"
- **`meta-gap-priority.md`** §3 — META P0 force-multiplier; rule này fix accumulation 1 lần → force-multiplier mọi artifact subsequent
- **`context-budget-mandate.md`** §3.1 — `paths:` frontmatter scope rule deferred-load only khi `documents/**` trong context; tránh per-session token cost
- **`rule-change-process.md`** §6.5 Enforcement Parity Mandate — rule + reviewer-checklist + worked self-test ship same PR; detector script defer per premature-rule guard
- **`incident-to-rule-pipeline.md`** — rule này direct output của a user-flagged docs scaling miss; 5-stage applied
- **Rule 2/3/4 cùng pack (docs scaling)** — sister rules: subdir maturity (Rule 2), per-folder volume cap (Rule 3), filename prefix taxonomy (Rule 4). Cadence (rule này) là Rule 1/4 foundation.

---

## 8. Log

- **2026-05-18 (v1.0.0):** Extracted into starter-kit from a real 200+ PR project. Rule 1/4 of the docs scaling pack — codifies age-based archival cadence (audits 90d / session-handoffs 30d / wave plans 60d post-closure / pr-logs 180d) so time-bound artifacts don't accumulate unbounded and bloat search + context.
