---
paths:
  - "documents/**/README.md"
---

# Docs Subfolder Maturity — chỉ tạo subdir khi thresholds match

**Priority:** 🟠 MANDATORY — folder structure discipline preventing subdir sprawl
**Version:** 1.0.0
**Created:** 2026-05-18
**Last-Reviewed:** 2026-05-18
**Reviewer-Approver:** @nguyenvankiet (starter-kit upstream maintainer)
**Applies to:** Mọi PR thêm subdirectory mới (hoặc nested subdirectory) dưới `documents/**`. Scope = subdir creation discipline; KHÔNG cover file placement bên trong subdir (đó là `docs-folder-structure.md` §file-placement-rules).

---

## 1. The Rule

> **Subdirectory chỉ được tạo dưới `documents/**` khi MỘT trong các threshold §2 thỏa.** Single-file subdir = ANTI-PATTERN — tăng cognitive load điều hướng folder mà không add navigation value. Mặc định: place file in-place tại parent folder cho tới khi threshold reached.

Force-multiplier rationale: khi một guides folder có nhiều subdir mà mỗi subdir chỉ có 1-2 files = reader phải mở folder, đọc README/list files, rồi mới biết "à chỉ có 1 file". Trade-off cognitive load > organization value. YAGNI principle (per `design-patterns.md` §1.1) applies — đừng pre-emptive organize "for future".

---

## 2. Threshold criteria (subdir allowed when ANY satisfied)

Subdir creation chỉ được phép khi **ít nhất MỘT** criterion sau thỏa:

| Criterion | Detail | Cách verify |
|---|---|---|
| **Volume** | ≥5 files trong scope HOẶC ≥5 files planned trong 30 ngày tới | Count current files + cite planned wave items / gap files / queue items |
| **Cross-author** | ≥2 distinct contributors trong scope | `git log --format=%an documents/<subdir>/ \| sort -u \| wc -l` ≥ 2 |
| **Reviewer approval** | Lead/architect explicit OK trong PR body với rationale | PR description includes "subdir maturity override: <reason>" + reviewer-approver |
| **Sister-pattern** | Mirror existing subdir convention rõ ràng | Existing parallel subdir đã có ≥5 files (vd: `dev/` đã có → `professional-manual/` cho dev audience parallel OK khi planned ≥5 files) |

**Quyết định decision flow:**

1. Bạn muốn tạo `documents/<parent>/<new-subdir>/`?
2. Đếm files sẽ thuộc `<new-subdir>` (hiện tại + planned 30 ngày). Nếu ≥5 → ✅ Volume criterion → tạo subdir.
3. Nếu <5 files → check cross-author / reviewer approval / sister-pattern.
4. Nếu KHÔNG criterion nào thỏa → ❌ Place file in-place tại `documents/<parent>/<filename>.md` thay vì tạo subdir.

---

## 3. Anti-patterns

| ❌ Don't | ✅ Do |
|---|---|
| Tạo `documents/05-guides/<topic>/` cho 1 file `<topic>.md` | Place file at `documents/05-guides/<topic>.md` (in-place) cho tới khi reach ≥5 files |
| Pre-emptive subdir "for future organization" (planned files chưa scoped cụ thể) | YAGNI per `design-patterns.md` §1.1 — create subdir khi đã có ≥5 files OR concrete plan ≤30 ngày |
| Subdir cho transient artifact (audit reports, retro notes) | Time-bound artifacts dùng date-prefix trong shared dir: `documents/04-quality/audits/2026-05-18-<topic>.md` |
| Tạo nested subdir `documents/05-guides/user-manual/owner/onboarding/` khi `onboarding/` chỉ có 1 file | In-place `documents/05-guides/user-manual/owner/onboarding.md` cho tới khi reach threshold |
| Subdir "vì sister-pattern có" mà không match volume/criterion | Sister-pattern criterion yêu cầu sister subdir đã ≥5 files (proven pattern, không phải aspirational) |
| Single-file subdir để "tách concern" | Concern separation trong markdown = `## H2 section` headings, không phải folder split |

---

## 4. Migration path (existing single-file subdirs)

Rule **applies prospectively**. Existing single-file subdirs grandfathered per `rule-change-process.md` convention — KHÔNG migrate retroactively trong rule landing PR.

**Khi nào migrate existing single-file subdir:**

- **Khi subdir đã grandfathered + Volume criterion vẫn fail sau 30+ ngày** → file follow-up gap "Flatten <subdir> back to in-place" (P2 priority, batch với cleanup wave)
- **Khi user/reviewer flag explicit** → migrate trong sweep PR (cùng cleanup batch)
- **Tự nhiên consolidate khi reach threshold** → subdir matures (≥5 files) → no migration needed
- **KHÔNG migrate** trong PR landing rule này — separate scope, avoid scope creep

**Migration mechanics (when triggered):**

```bash
# Flatten subdir back to parent với prefix rename
git mv documents/<parent>/<subdir>/<file>.md \
       documents/<parent>/<subdir>-<file>.md
rmdir documents/<parent>/<subdir>/
# Update inbound links via grep + Edit tool
```

---

## 5. Enforcement (per `rule-change-process.md` §6.5)

### 5.1 Reviewer-checklist (active immediately)

Pre-merge review cho PR thêm subdirectory mới dưới `documents/**`:

- [ ] PR thêm directory mới (path ending `/`) under `documents/**`?
- [ ] Nếu CÓ → đếm files trong new subdir (hiện tại + planned ≤30 ngày trong PR description / wave plan):
  - ≥5 files → ✅ Volume criterion thỏa
  - <5 files → check §2 criteria khác
- [ ] Nếu KHÔNG criterion nào thỏa → request rewrite: "place file in-place tại parent folder thay vì tạo subdir"
- [ ] Subdir creation phải có inline rationale trong PR body cite §2 criterion nào thỏa

### 5.2 PR template (active — extend existing checklist)

Thêm row vào `.github/PULL_REQUEST_TEMPLATE.md` Output Review Checklist:

```markdown
- [ ] **Docs subfolder maturity** — nếu PR thêm new subdirectory under `documents/**`, MỘT trong §2 thresholds thỏa (Volume ≥5 files / cross-author ≥2 / reviewer approval / sister-pattern) per `.claude/rules/docs-subfolder-maturity.md`
```

### 5.3 CI detector script

Optional CI script `scripts/check-docs-subfolder-maturity.sh` (~115 LOC bash, low FP risk) — wire CI job `docs-scaling-detectors`:
- WARN-mode initially (existing grandfathered subdirs surface — rule prospective)
- Excludes `archived/`, `closed/`, `07-archived/` per §2 exemptions
- Override trailer: `DOCS_SUBFOLDER_MATURITY_OVERRIDE: <subdir> — <reason>`
- HARD STOP target after consolidation pass for grandfathered violations

### 5.4 Memory auto-load (optional, deferred)

Memory entry reminding session start trước khi tạo subdir. Defer per `incident-to-rule-pipeline.md` premature-rule guard ≥7 ngày; path-scoped auto-load + reviewer-checklist + worked self-test đủ cho v1.0.0.

### 5.5 Override mechanism

Genuine exception ngoài §2 criteria:

```
git commit -m "...
DOCS_SUBFOLDER_MATURITY_OVERRIDE: <subdir-path> — <reason — vd 'isolated scope cho legal compliance docs, độc lập với parent shared concerns'>"
```

Trailer logged. Pattern frequency >5%/quarter triggers meta-review.

---

## 6. Override mechanism (detailed)

Khi nào dùng override:

| Case | Why exempt |
|---|---|
| Legal/compliance isolation | Subdir riêng cho compliance docs để audit trail clear, dù chỉ 1-2 files |
| Vendor-specific scope | Subdir cho từng vendor (vd `vendor-cloud/`, `vendor-dns/`) khi clearly partitioned ownership |
| Generated artifact scope | Subdir cho auto-generated docs (vd `generated/`) — clearly distinct từ hand-written |
| Phase boundary | Subdir cho `phase-2/` content được phát triển isolated trước cutover |

Documenting override:
- Inline trong PR body với rationale rõ ràng
- Plus commit trailer `DOCS_SUBFOLDER_MATURITY_OVERRIDE: <path> — <reason>`
- Reviewer xác nhận inline trong PR review

---

## 7. Worked self-test — retroactive apply trên a guides folder with 17 subdirs

Apply rule retroactively (rule **prospective only** — không migrate; chỉ để verify rule fires correctly):

### 7.1 Subdir verdicts

| # | Subdir | Files | Verdict | §2 criterion |
|---|---|:---:|:---:|---|
| 1 | `account-prep/` | 10 | ✅ PASS | Volume ≥5 |
| 2 | `branding/` | 3 | ❌ FAIL threshold | None — should be in-place OR grow to ≥5 |
| 3 | `contributing/` | 4 | ❌ FAIL threshold | <5, borderline; check planned items |
| 4 | `deploy/` | 28 | ✅ PASS | Volume ≥5 |
| 5 | `dev/` | 5 | ✅ PASS | Volume ≥5 (exactly threshold) |
| 6 | `infrastructure/` | 4 | ❌ FAIL threshold | <5, borderline |
| 7 | `local-dev/` | 6 | ✅ PASS | Volume ≥5 |
| 8 | `monitoring/` | 5 | ✅ PASS | Volume ≥5 (exactly threshold) |
| 9 | `operations/` | 28 | ✅ PASS | Volume ≥5 |
| 10 | `remote-access/` | 3 | ❌ FAIL threshold | <5 |
| 11 | `pilot/` | 2 | ❌ FAIL threshold | <5; transient pilot artifact — should consolidate hoặc archive |
| 12 | `scripts/` | 0 + 1 nested | ❌ FAIL threshold | Empty parent — files only in nested dir; should flatten |
| 13 | `security/` | 1 | ❌ FAIL threshold | Classic single-file subdir anti-pattern |
| 14 | `templates/` | 2 | ❌ FAIL threshold | <5; sister-pattern check needed |
| 15 | `lifecycle/` | 3 | ❌ FAIL threshold | <5 |
| 16 | `user-manual/` | 1 + 4 nested persona dirs | ✅ PASS | Sister-pattern (persona split) + planned Volume ≥5 each persona |
| 17 | `localization/` | 8 | ✅ PASS | Volume ≥5 |

### 7.2 Verdict summary

- **8/17 PASS** — Volume criterion thỏa hoặc sister-pattern justified
- **9/17 FAIL threshold** retroactive — would have been blocked by rule if applied at creation time

### 7.3 Sample 5 violations (retroactive — grandfathered, not migrated)

Top 5 candidates cho future consolidation pass (P2 priority, batch với cleanup wave):

| # | Subdir | Files | Recommendation |
|---|---|:---:|---|
| 1 | `documents/05-guides/security/` | 1 | Flatten → `documents/05-guides/security-<topic>.md` in-place |
| 2 | `documents/05-guides/pilot/` | 2 | Archive nếu pilot done → `documents/07-archived/pilot/` |
| 3 | `documents/05-guides/scripts/` | 0 (empty parent) | Flatten nested files lên parent OR rename parent từ `scripts/` thành descriptive name |
| 4 | `documents/05-guides/templates/` | 2 | Check sister-pattern OR flatten |
| 5 | `documents/05-guides/branding/` | 3 | Borderline — check planned files; nếu <5 in 30 ngày → flatten |

### 7.4 Counterfactual

Nếu rule áp dụng từ đầu khi guides folder đầu tiên được structure:

- 9 subdirs trên đã KHÔNG được tạo → 9 single-file/single-purpose docs in-place tại `documents/05-guides/<topic>.md`
- Reader cognitive load giảm: từ "17 subdirs scattered" xuống "8 mature subdirs + 9 in-place top-level docs"
- File discoverability via `ls documents/05-guides/` reveals immediate file names thay vì nested folder names

→ **Rule fires correctly trên retroactive sample.** 9/17 subdirs would have been rejected by §2 criteria. Self-test PASS ✅

---

## 8. Relationship to other rules

- **`docs-folder-structure.md`** §3 README Template — sister rule covering shape OF folder (README mandatory + 4 sections); THIS rule covers WHEN to create folder. Both apply: §2 thresholds thỏa → create subdir → MUST also create README per docs-folder-structure.md
- **`docs-folder-volume-budget.md`** (Rule 3 of docs scaling pack) — per-folder cap; sub-split decisions reference §2 thresholds here
- **`docs-archival-cadence.md`** (Rule 1 of docs scaling pack) — time-bound artifacts use date-prefix in shared dir not subdir
- **`docs-filename-prefix-convention.md`** (Rule 4 of docs scaling pack) — filename taxonomy
- **`design-patterns.md`** §1.1 YAGNI — codify "don't pre-emptive organize"; THIS rule áp dụng YAGNI vào folder structure decisions
- **`docs-only-pr-auto-merge.md`** — auto-merge eligible khi diff docs-only; rule này check applies tới subdir creation PRs (auto-merge OK nếu §2 criterion documented in PR body)
- **`rule-change-process.md`** §6.5 Enforcement Parity Mandate — rule + reviewer-checklist + PR template + worked self-test all ship same PR
- **`incident-to-rule-pipeline.md`** — rule này là direct output của a user-flagged subdir-sprawl miss applied through 5-stage pipeline
- **`output-review-mandate.md`** §3 — review standard preserved cho docs scope; THIS rule adds gate at subdir-creation moment
- **`meta-gap-priority.md`** §3 — Meta-P0 force-multiplier (folder structure decisions affect mọi future reader navigation)

---

## 9. Log

- **2026-05-18 (v1.0.0):** Extracted into starter-kit from a real 200+ PR project. Rule 2/4 of the docs scaling pack — codifies maturity thresholds (≥5 files / ≥2 contributors / reviewer approval / proven sister-pattern) so subdirectories are created only when they add navigation value, preventing single-file subdir sprawl.
