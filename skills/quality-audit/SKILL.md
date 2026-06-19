---
name: quality-audit
description: "Dùng khi user nói 'audit', 'quality check', 'kiểm tra chất lượng', 'điểm chất lượng', 'ready to merge?', 'persona coverage', hoặc trước khi merge một wave/feature lớn vào main. Chấm điểm 11 categories /110 điểm (10 tech + 1 persona coverage)."
user-invocable: true
---

# /quality-audit — Đánh giá chất lượng toàn diện

**Usage:** `/quality-audit [<module>|all]`

**Default:** `all` (đánh giá toàn bộ project)

Top-of-funnel audit /110. Cho cái nhìn tổng quan; để đánh giá sâu từng domain, dùng các specialized audit ở §"Specialized Audits".

---

## Instructions

Khi user invoke `/quality-audit`:

### Bước 1: Thu thập dữ liệu tự động

Chạy các lệnh sau **song song** để thu thập metrics. Thay placeholder bằng script/đường dẫn của project:

```bash
# 1. Git & PR stats
git log --oneline --since="30 days ago" | wc -l
gh pr list --state merged --limit 200 --json number --jq 'length'
gh pr list --state open --json number --jq 'length'
git branch -r | grep -v "main\|HEAD" | wc -l

# 2. CI status — dùng project's CI helper script nếu có
#    Audit mode: đọc kết quả, KHÔNG đợi (--status / read-only)
scripts/check-ci.sh --status   # hoặc: gh run list --branch main --limit 10 --json conclusion

# 3. Backend + Frontend tests — dùng project test runner script
scripts/test-local.sh <module> all   # KHÔNG chạy mvnw/vitest/eslint ad-hoc

# 4. E2E tests — script có sẵn của project
scripts/test-e2e.sh

# 5. Docker / runtime status
scripts/status.sh   # hoặc: docker compose ps

# 6. Code stats (grep/find OK vì chỉ đếm, không execute)
find . -name "*.java" -path "*/src/main/*" | wc -l
find . -name "*Test.java" | wc -l
find . -name "*.tsx" -o -name "*.ts" | grep -v node_modules | wc -l

# 7. Security scan (grep OK — chỉ scan)
grep -rn "TODO\|FIXME\|HACK\|XXX" --include="*.java" src 2>/dev/null | wc -l

# 8. Documentation
find documents -name "*.md" | wc -l

# 9. Monitoring / health
scripts/monitor.sh health   # hoặc health endpoint check
```

**CRITICAL: KHÔNG chạy lệnh ad-hoc cho:**
- Tests → project test runner script
- CI monitoring → project CI helper script
- Docker / runtime → project status script
- Monitoring → project monitor script

(Lý do: scripts encapsulate đúng flags/profiles; ad-hoc dễ sai môi trường.)

### Bước 2: Chấm điểm 11 categories (110 điểm)

> **Per-check scoring:** Mọi category dưới đây dùng per-check pass/fail rubric per `rules/audit-skill-rubric-quality-audit.md` §2 (5+ sub-checks per category, severity P0/P1/P2). Bất kỳ P0 sub-check FAIL → cap category total ≤ (max - 4) AND audit-level verdict = FAIL bất kể tổng điểm. **Bug list (mọi FAIL) đứng TRƯỚC bảng điểm.** Xem bound rule để có primacy + enumeration cụ thể.

> **Scale:** Cat 11 (Persona Coverage) là category /10 thứ 11, nâng max từ 100 → 110. 10 tech categories giữ nguyên trọng số; Cat 11 thêm business-correctness signal mà tech-only audit bỏ sót. Shorthand điểm dùng dạng `X/110`.

#### 1. E2E Functionality (10 điểm)

| Tiêu chí | Điểm | Check |
|----------|------|-------|
| E2E API tests pass 100% | 4 | E2E test results |
| E2E pass ngay lần đầu (no cold start issue) | 2 | Chạy 1 lần duy nhất |
| Critical flows hoạt động: Register→Login→Dashboard→core action | 2 | Manual hoặc E2E |
| External integrations hoạt động (không chỉ mock) | 2 | Check provider config |

#### 2. Security (10 điểm)

| Tiêu chí | Điểm | Check |
|----------|------|-------|
| Authentication: token + email verify + captcha/rate-limit | 3 | Code review |
| Rate limiting hoạt động | 2 | Gateway/edge config |
| Không có secrets hardcode trong code | 2 | `grep -r` sensitive patterns |
| CORS configured đúng (không wildcard prod) | 1 | Gateway CORS config |
| Input validation trên tất cả endpoints | 2 | DTO annotations |

#### 3. Backend Tests (10 điểm)

| Tiêu chí | Điểm | Check |
|----------|------|-------|
| Tất cả modules build + test pass (0 errors) | 4 | Test runner |
| 0 skipped tests | 2 | Check skipped count |
| Test coverage >70% | 2 | Coverage report nếu có |
| Integration tests cho critical paths | 2 | Check `*IT.java` files |

#### 4. Frontend Tests (10 điểm)

| Tiêu chí | Điểm | Check |
|----------|------|-------|
| Unit/component tests pass, <10% skipped | 3 | Test runner results |
| Production build pass (all pages) | 2 | `build` command |
| Component tests cho critical pages | 3 | Count test files |
| E2E browser tests (Playwright/Cypress) | 2 | Check `e2e/` folder |

#### 5. CI/CD (10 điểm)

| Tiêu chí | Điểm | Check |
|----------|------|-------|
| Tất cả CI workflows green trên main | 4 | `gh run list` |
| 0 stale branches | 2 | `git branch -r` count |
| 0 open PRs không hoạt động | 2 | `gh pr list --state open` |
| CI history sạch (không spam failed runs) | 2 | `gh run list` count |

#### 6. UI/UX (10 điểm)

| Tiêu chí | Điểm | Check |
|----------|------|-------|
| Tất cả pages có consistent design system | 3 | Check design tokens, shared components |
| Theme system hoạt động (đổi màu visual) | 2 | Test theme override |
| Responsive (mobile-friendly) | 2 | Check breakpoints |
| Onboarding/guidance cho new users | 2 | Wizard, checklist, tooltips |
| Accessibility (a11y basics) | 1 | aria-labels, semantic HTML |

#### 7. DevOps/Infrastructure (10 điểm)

| Tiêu chí | Điểm | Check |
|----------|------|-------|
| Tất cả containers healthy | 3 | `docker compose ps` |
| Production deployment plan có (IaC) | 2 | Check infra/ folder |
| Backup strategy documented | 2 | Check docs |
| Monitoring/alerting | 2 | Check dashboard/alerts |
| Secrets management documented | 1 | Secrets runbook |

#### 8. Documentation (10 điểm)

> **Business docs ở `documents/` là SOURCE OF TRUTH. Score 0 cho category này nếu không có business docs cho các domain đã implement.**

| Tiêu chí | Điểm | Check |
|----------|------|-------|
| Business docs exist for all implemented domains | 3 | Mỗi service có business logic phải có `rules/use-cases/api-contract` doc |
| Business docs match code — config keys, rules | 2 | Cross-check config keys trong code vs business doc |
| Architecture + guides + README up-to-date | 3 | Check planning docs, README, project instructions |
| Plans up to date with completion tracking | 2 | Check ✅/⬜ trong plans |

#### 9. Code Quality (10 điểm)

| Tiêu chí | Điểm | Check |
|----------|------|-------|
| 0 TODO/FIXME/HACK trong production code | 1 | `grep -r` |
| 0 IDE warnings (TypeScript + Java) | 1 | Compiler/linter |
| Consistent coding style (ESLint, Checkstyle) | 1 | Pre-commit hooks |
| No dead code / unused imports | 1 | Linter results |
| Framework dependencies trên latest patch | 1 | Check manifest |
| **Design patterns applied correctly** (no anti-patterns) | 3 | `rules/design-patterns.md` + `quality/design-pattern-audit` |
| Pattern choice documented (javadoc/comment) | 1 | Spot check key services |
| No God Services (>500 lines / >15 methods) | 1 | `find -size +20k *Service.java` |

**Design patterns check (generic):**
- No God Service trong các service chính
- Status transitions via State Pattern (not nested switch)
- External APIs wrapped by Adapter
- Events via Outbox (check outbox table + publisher)
- External calls có Circuit Breaker + fallback
- No primitive obsession (value objects cho structured types)

**Document Generation Quality check (khi document-rendering code thay đổi):**
- Non-ASCII / Unicode text round-trip qua MỌI export format (PDF/DOCX/XLSX) — verified bởi diacritics/Unicode round-trip tests
- Locale-specific number/currency formatting đúng locale config
- Branding-aware outputs (header/logo/displayName) derive từ branding config, fall back gracefully khi keys absent
- WCAG contrast khi branding color paints fill (foreground tự switch readable)
- Filename trong `Content-Disposition` dùng RFC-5987 UTF-8 encoding
- Cross-format consistency có integration test; thêm format mới → extend test trước khi merge

#### 10. Project Management (10 điểm)

| Tiêu chí | Điểm | Check |
|----------|------|-------|
| Tất cả plans có completion status | 3 | Review plan docs |
| PRs follow team methodology (brainstorm/breakdown/TDD/review) | 3 | Check recent PR descriptions |
| Commit messages clean + meaningful | 2 | `git log` review |
| Issues/gaps tracked và prioritized | 2 | Check gap reports |

#### 11. Persona Coverage (10 điểm)

> **Source of truth:** latest reports dưới `documents/persona-reviews/` produced via persona review process (quarterly cadence). Nếu chưa có report cho ≥1 persona Tier 1 → score `5/10` (mid-baseline) annotate "data pending".

> **Data-pending policy:** không có report cho ≥1 Tier 1 persona → score Cat 11 = `5/10`. KHÔNG score 0 (no data ≠ no coverage); KHÔNG score 10 (không claim full coverage nếu thiếu evidence). Baseline 5/10 giữ tới khi reports ship.

| Tiêu chí | Điểm | Check |
|----------|------|-------|
| Tất cả Tier 1 personas có review report ≤90 ngày | 3 | `ls -lt documents/persona-reviews/*.md` + match từng persona |
| Mỗi report có zero 🔴 critical (blocking-launch) gap | 3 | Read verdict + critical-gap section |
| Quarterly cadence respected (latest review ≤ current quarter) | 2 | So sánh report date vs EOQ |
| Persona catalog có `next_review` field không overdue | 1 | grep `next_review:` frontmatter |
| Audit-driven persona gaps tracked (không stale) | 1 | grep persona-* gaps trong roadmap/gap tracker |

**Scoring guidance:**
- 9-10/10: Tất cả Tier 1 reports current, zero critical gap, cadence on track
- 7-8/10: Reports exist nhưng ≥1 có open critical gap, HOẶC cadence slipping ≤1 quarter
- 5/10: **Data pending** — default neutral score
- 3-4/10: Reports cho một số personas, HOẶC cadence overdue ≥2 quarters
- 1-2/10: Reports exist nhưng nhiều critical gaps, no remediation
- 0/10: Feature completeness <30% cho ≥1 Tier 1 persona (system unusable at scale)

### Bước 3: Output Report

```markdown
# Quality Audit Report: [<module>/All]

**Ngày:** [date]
**Người đánh giá:** Claude Code
**Version:** [latest commit hash]

---

## Bug List (mọi FAIL — đứng TRƯỚC bảng điểm)

| Severity | Category | Sub-check | Evidence (file:line) |
|----------|----------|-----------|----------------------|
| 🔴 P0 | ... | ... | ... |

**Audit-level verdict:** PASS / FAIL (FAIL nếu có ANY P0 sub-check FAIL)

---

## Overall Score

| # | Category | Score | Max | Grade |
|---|----------|-------|-----|-------|
| 1 | E2E Functionality | X | 10 | ✅/⚠️/❌ |
| 2 | Security | X | 10 | ✅/⚠️/❌ |
| 3 | Backend Tests | X | 10 | ✅/⚠️/❌ |
| 4 | Frontend Tests | X | 10 | ✅/⚠️/❌ |
| 5 | CI/CD | X | 10 | ✅/⚠️/❌ |
| 6 | UI/UX | X | 10 | ✅/⚠️/❌ |
| 7 | DevOps/Infra | X | 10 | ✅/⚠️/❌ |
| 8 | Documentation | X | 10 | ✅/⚠️/❌ |
| 9 | Code Quality | X | 10 | ✅/⚠️/❌ |
| 10 | Project Management | X | 10 | ✅/⚠️/❌ |
| 11 | Persona Coverage | X | 10 | ✅/⚠️/❌ |
| **Total** | | **X** | **110** | **Grade** |

### Grade Scale (/110)

- 105-110: A+ (Production Excellence)
- 99-104: A (Production Ready)
- 94-98: B+ (Near Production)
- 88-93: B (Good, needs polish)
- 77-87: C (Acceptable, significant gaps)
- <77: D (Major work needed)

(Thresholds = prior /100 thresholds × 1.1, rounded.)

---

## Detailed Findings

### ✅ Strengths (8+/10)
### ⚠️ Needs Improvement (5-7/10)
### ❌ Critical Issues (<5/10)

---

## Improvement Roadmap

### Quick Wins (1-2 hours each)
### Medium Effort (0.5-1 day)
### Major Effort (2+ days)

---

## Comparison with Previous Audit

| Category | Previous | Current | Change |
|----------|----------|---------|--------|
| ... | ... | ... | +X/-X |

(Nếu không có audit trước, ghi "First audit")

---

## Action Items

| Priority | Item | Estimated Score | Effort |
|----------|------|-----------------|--------|
| 🔴 P0 | ... | +X | ... |
```

### Bước 4: Lưu kết quả

- Save report to `documents/audits/quality/quality-audit-[date].md`
- Update quality plan nếu phát hiện gaps mới
- So sánh với audit trước nếu có

---

## Context Management (CRITICAL)

Quality-audit là skill tốn context nhất (60-100K+ tokens). **Compaction giữa audit = scores sai.** Tuân thủ:

### Staged Execution — 3 Phases

**Phase 1: Automated metrics** (run in parent, ~15K tokens)
- Git stats, CI status, runtime status, code counts
- Test execution (via scripts — output có thể lớn, LUÔN `| tail -30`)
- KHÔNG đọc source files trong phase này

**Phase 2: Parallel deep-dive** (delegate to subagents, ~20K each)
- Agent 1: Categories 1-3 (E2E, Security, Backend Tests)
- Agent 2: Categories 4-6 (Frontend Tests, CI/CD, UI/UX)
- Agent 3: Categories 7-10 (DevOps, Docs, Code Quality, PM)
- Mỗi agent trả JSON summary: `{category, score, evidence: [1-line each], issues: []}`

**Phase 3: Aggregate** (parent, ~5K tokens)
- Collect subagent results → compile report → compare with previous audit

### Output Limiting Rules

| Command | Limit |
|---------|-------|
| backend test runner | `\| tail -30` (chỉ summary) |
| frontend test runner | `\| tail -20` |
| build | `\| tail -25` (route table only) |
| `gh run list` | `--limit 10` |
| `git log` | `--oneline -20` |
| `grep -r` | `\| head -20` per pattern |
| `find ... \| wc -l` | OK (single number) |

### Subagent Return Format

```json
{
  "categories": [
    {"id": 1, "name": "E2E Functionality", "score": 8, "max": 10, "evidence": ["E2E pass 12/12", "cold start OK"], "issues": []}
  ]
}
```

Parent KHÔNG cần re-verify — trust subagent evidence. Chỉ sanity-check nếu score bất thường (0 hoặc 10).

## Rules

- LUÔN chạy tests thật (không đoán)
- LUÔN giao tiếp tiếng Việt
- Chấm điểm dựa trên evidence (test output, code check), không cảm tính
- Nếu E2E fail lần 1 do cold start, chạy lần 2 nhưng GHI NHẬN cold start issue (-2 điểm)
- Nếu không thể chạy test (runtime down, etc.), ghi 0 điểm cho category đó + note lý do
- **KHÔNG chạy tất cả trong 1 context** — PHẢI dùng staged execution + subagents

### CRITICAL: CI phải hoàn thành trước khi chấm điểm

**KHÔNG BAO GIỜ** kết luận CI/CD score hoặc Backend Tests score khi CI còn `in_progress`.

**Quy trình bắt buộc:**
1. Thu thập data → kiểm tra `gh run list` status
2. Nếu có run `in_progress` liên quan target (branch/PR):
   - Dùng project CI helper script (read mode) để kiểm tra — KHÔNG đoán
   - Nếu còn `in_progress` → đợi hoặc đánh dấu PENDING
   - **PHẢI** báo user: "CI đang chạy, đợi kết quả trước khi chấm điểm CI/CD"
3. Chỉ sau khi CI completed → chấm điểm: CI/CD, Backend Tests, E2E
4. Nếu user yêu cầu audit gấp → ghi "CI/CD: PENDING (chưa có kết quả)" thay vì đoán

**Lý do:** Đoán CI pass khi thực tế đang chạy làm sai lệch kết quả + có thể dẫn đến merge PR lỗi.

### Specialized Audits (for deeper analysis)

Quality-audit cho cái nhìn tổng quan /110. Để đánh giá sâu từng domain:

| Audit | Skill | Khi nào |
|-------|-------|---------|
| Business Logic | `/business-logic-audit` | Code ↔ rules.md sync |
| Security | `/security-audit` | Deep security assessment |
| Performance | `/performance-audit` | Bottleneck + baseline |
| API Contract | `/api-contract-audit` | Endpoint ↔ docs sync |
| Ops Readiness | `/ops-readiness-audit` | Production deploy readiness |
| Design Patterns | `/design-pattern-audit` | Anti-pattern detection /100 |
| UI/UX | `/ui-review` | Per-screen visual /128 |
| Persona Coverage | persona review process | Quarterly role-play per Tier 1 persona — feeds Cat 11 |

Thêm section "Specialized Audit Scores" vào report nếu có kết quả từ audit chuyên sâu.

---

## Gotchas

- **Self-audit overstates 15-20 pts vs specialist** — không trust standalone score; luôn compute delta vs prior baseline, không phải absolute number
- **Audit grep scope phải include sub-modules** — multi-module projects đặt classes/config trong submodule dirs; narrow scope tạo false-positive issue counts (xem `quality/business-logic-audit` "Grep Scope")
- **Targeted re-audit only after fix** — full re-audit chỉ khi release / major refactor; re-score chỉ categories bị ảnh hưởng bởi fix
- **First-run baseline is NOT a regression** — scoring category chưa từng audit, low score là honest baseline, không phải drift
- **Always use CI helper script (read mode)** cho audit data; `gh pr checks` field `state` đôi khi null và break polling
- **Cat 11 defaults to 5/10** cho tới khi persona reports ship — không score 0 hay 10
- **Comparing legacy /100 vs /110 audits** — convert old `X/100` to `(X × 1.1)/110` trước khi delta

---

## Skill Contents

- `rules/audit-skill-rubric-quality-audit.md` — per-check pass/fail rubric (11 categories) bound to this skill

## Log

- Ported into starter-kit from an internal project's audit-suite pack. Genericized: removed project-specific module/script names, scores, audit dates, and incident history. Methodology (11 categories /110, staged execution, per-check rubric binding, CI-completion gate) preserved intact.
