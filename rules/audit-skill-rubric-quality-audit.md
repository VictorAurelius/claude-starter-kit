---
paths:
  - "documents/audits/quality/**"
---

# Audit Skill Rubric — quality-audit (11 categories, per-check pass/fail)

**Priority:** 🟠 MANDATORY — audit primacy + per-check rubric for `quality-audit` skill
**Version:** 1.0.0
**Created:** 2026-05-14
**Last-Reviewed:** 2026-05-14
**Reviewer-Approver:** @nguyenvankiet (starter-kit upstream maintainer)
**Applies to:** Every invocation of `skills/quality-audit/SKILL.md` (the /110 top-of-funnel quality audit covering all 11 categories: E2E, Security, BE Tests, FE Tests, CI/CD, UI/UX, DevOps, Docs, Code Quality, PM, Persona Coverage)

---

## 1. The Rule

> **`quality-audit` skill must score every category by per-check pass/fail (no averaging within a 10-pt or /10 category that hides P0 sub-check failures). Any P0/P1 sub-check FAIL caps category total ≤ (max - 4) AND audit-level verdict = FAIL regardless of total score. The bug list (every FAIL) is the deliverable; the score is descriptive only.**

Averaging sub-checks within a /10 category lets P0 gaps hide (e.g., an audit scoring `87/100` on security while missing 5 P0 OWASP gaps because averaging hid them). Per-check pass/fail eliminates that masquerade.

---

## 2. Mandatory per-check enumeration (5+ checks per category)

Every Category N's score derives from explicit per-check rolldown. The skill body §"Bước 2" `quality-audit/SKILL.md` already enumerates most via its `| Tiêu chí | Điểm | Check |` rows — those tables ARE the per-check rubric. This rule binds them to per-check pass/fail semantics + provides concrete sample checks.

### 2.1 Category 1 — E2E Functionality (P0/P1 split)

| # | Check | Severity | Pass criterion |
|---|---|---|---|
| 1.1 | E2E API test suite returns 100% pass | P0 | Exit 0; no failures |
| 1.2 | E2E pass on FIRST run (no cold-start flake) | P1 | First run = green; not "green on retry" |
| 1.3 | Critical flows manual-walked: Register→Login→Dashboard→core action | P0 | Each step result captured |
| 1.4 | External integrations hit real provider (not mock) | P1 | provider config ≠ `mock`; verify via curl |
| 1.5 | E2E covers ≥1 negative path (invalid input → 400) | P1 | grep `assertStatus(400` or equiv |

### 2.2 Category 2 — Security (P0 for hardcoded secrets, P1 for rest)

| # | Check | Severity | Pass criterion |
|---|---|---|---|
| 2.1 | Auth implemented: token + email verify + (captcha OR rate-limit) | P0 | auth filter + email-verification service present |
| 2.2 | Rate limiting active on auth + sensitive endpoints | P0 | gateway/edge rate-limiter config present |
| 2.3 | Zero hardcoded secrets in source code | P0 | `grep -rE 'password\s*=\s*"[^${]\|api[_-]?key\s*=\s*"[^${]' --include='*.java' --include='*.yml'` returns 0 |
| 2.4 | CORS configured (not `*` wildcard in prod) | P1 | allowed-origins is specific list |
| 2.5 | Input validation present on all DTOs | P1 | `grep -l '@Valid' --include='*.java'` per controller |

### 2.3 Category 3 — Backend Tests (P0 build, P1 coverage)

| # | Check | Severity | Pass criterion |
|---|---|---|---|
| 3.1 | All modules test suite pass (0 errors, 0 failures) | P0 | Exit 0 each module |
| 3.2 | 0 `@Disabled` / `@Ignore` in production tests | P1 | grep returns 0 |
| 3.3 | Coverage ≥70% on changed modules | P1 | coverage report `LINE` ≥70 |
| 3.4 | Integration tests exist for every critical service | P1 | `*IT.java` count ≥1 per service module |
| 3.5 | Test fixtures isolated (Testcontainers OR @DirtiesContext) | P2 | grep `@Testcontainers\|@DirtiesContext` |

### 2.4 Category 4 — Frontend Tests (P0 build, P1 coverage)

| # | Check | Severity | Pass criterion |
|---|---|---|---|
| 4.1 | FE unit/component tests pass with <10% skipped | P0 | Exit 0; skipped count <10% |
| 4.2 | FE production build pass (no broken pages) | P0 | Exit 0 |
| 4.3 | Component tests for ≥80% of critical pages | P1 | grep `.test.tsx\|.spec.tsx` count vs page count |
| 4.4 | E2E browser tests (Playwright) present | P1 | `e2e/` folder exists with ≥1 spec |
| 4.5 | No lockfile drift between local + CI | P1 | `git diff --quiet <lockfile>` |

### 2.5 Category 5 — CI/CD (P0 green, P1 hygiene)

| # | Check | Severity | Pass criterion |
|---|---|---|---|
| 5.1 | All required CI workflows green on `main` HEAD | P0 | `gh run list --branch main --limit 10` all `success` |
| 5.2 | Zero stale feature branches >30 days | P1 | `git branch -r --merged main` filtered |
| 5.3 | Zero open PRs stale >14 days | P1 | `gh pr list --state open --json updatedAt` |
| 5.4 | CI history under retention cap | P1 | `gh run list --limit 200 \| wc -l` |
| 5.5 | Required status checks defined on `main` branch protection | P0 | `gh api repos/.../branches/main/protection` |

### 2.6 Category 6 — UI/UX (P0 a11y, P1 design system)

| # | Check | Severity | Pass criterion |
|---|---|---|---|
| 6.1 | All pages use design-system tokens (no inline hex in `.tsx`) | P1 | `grep -E '#[0-9a-fA-F]{6}' src/app --include='*.tsx'` returns ≤5 |
| 6.2 | Theme system: theme override changes visible color | P1 | Manual or screenshot test |
| 6.3 | Responsive breakpoints: 320/768/1024/1440 all render | P1 | `ui-review` screenshots at 4 widths |
| 6.4 | Onboarding/empty states present for top-3 user flows | P1 | grep `<EmptyState\|wizard\|tooltip` |
| 6.5 | a11y basics: every interactive element has aria-label OR semantic tag | P0 | axe-core scan: 0 critical violations |

### 2.7 Category 7 — DevOps/Infrastructure (P0 containers, P1 docs)

| # | Check | Severity | Pass criterion |
|---|---|---|---|
| 7.1 | All containers healthy via `docker compose ps` | P0 | All services `running (healthy)` |
| 7.2 | Production IaC plan documented + reviewed | P0 | infra dir has plan output committed for last apply |
| 7.3 | Backup strategy documented | P0 | db-backup runbook exists |
| 7.4 | Monitoring + alerting active (metrics scraping + dashboard) | P0 | metrics endpoint 200 + dashboard exists |
| 7.5 | Secrets management runbook present | P1 | secrets-rotation runbook exists |

### 2.8 Category 8 — Documentation (P0 business docs, P1 architecture)

| # | Check | Severity | Pass criterion |
|---|---|---|---|
| 8.1 | Business docs exist for ALL implemented domains | P0 | every service module has `{rules,use-cases,api-contract}.md` |
| 8.2 | Business docs code-sync: config keys in rules.md match config files | P0 | business-docs verifier exit 0 |
| 8.3 | README + project instructions last-updated ≤30 days | P1 | grep `Last Updated` |
| 8.4 | Architecture ADRs current (last ≤60 days) | P1 | ADR index newest `created` ≤60 days |
| 8.5 | Plans + roadmap reflect current state | P1 | roadmap status snapshot last commit ≤7 days |

### 2.9 Category 9 — Code Quality (P0 anti-pattern, P1 polish)

| # | Check | Severity | Pass criterion |
|---|---|---|---|
| 9.1 | Zero TODO/FIXME/HACK in `src/main/` + `src/app/` | P1 | `grep -rE 'TODO\|FIXME\|HACK' --include='*.java' --include='*.tsx'` returns 0 |
| 9.2 | Zero IDE warnings (Java compile + TS strict) | P1 | `tsc --noEmit` exit 0; compile -Werror exit 0 |
| 9.3 | Lint config enforced (ESLint + Checkstyle) via pre-commit | P1 | pre-commit hook runs both |
| 9.4 | No God Services (>500 lines OR >15 public methods) per `design-patterns.md` | P0 | `find -size +20k *Service.java` returns 0 |
| 9.5 | Outbox pattern applied (no direct event publish outside dispatcher) per `design-patterns.md` | P0 | grep returns 0 sites without reliability-net marker |

### 2.10 Category 10 — Project Management (P1 governance)

| # | Check | Severity | Pass criterion |
|---|---|---|---|
| 10.1 | All plans have status: complete OR active (no orphan plans) | P1 | grep `status:` in planning docs |
| 10.2 | PRs follow team methodology (brainstorm/breakdown/TDD/review sections) | P1 | last 10 PRs sampled |
| 10.3 | Commit messages follow conventional commits | P2 | `git log --oneline -20` pattern match |
| 10.4 | Gap status tracker in sync with markdown frontmatter | P0 | gap-status verifier exit 0 |
| 10.5 | Roadmap next-action references active gap IDs (not stale) | P1 | grep gap IDs cross-ref to gap tracker |

### 2.11 Category 11 — Persona Coverage (P1 review cadence)

| # | Check | Severity | Pass criterion |
|---|---|---|---|
| 11.1 | All Tier 1 personas have review report ≤90 days old | P0 | every Tier 1 persona → review file exists + date check |
| 11.2 | Zero 🔴 critical (blocking-launch) gaps in Tier 1 reports | P0 | each report's "Coverage Analysis" table |
| 11.3 | Quarterly cadence respected (latest report ≤current quarter) | P1 | EOQ window check |
| 11.4 | Persona catalog `next_review` frontmatter not overdue | P1 | grep `next_review:` |
| 11.5 | Audit-driven persona gaps tracked in roadmap | P1 | cross-ref persona-* gap IDs |

---

## 3. Banned shortcuts

| ❌ Banned | ✅ Required |
|---|---|
| "Cat 6 UI/UX 7/10 — averaged design + a11y + responsive" | Each sub-check pass/fail; lowest sub-check pulls category |
| "Score 8/10, only minor gaps" without listing the gaps | Bug list MUST enumerate every FAIL before computing score |
| Skip Cat 11 because "data pending" | Cat 11 stays 5/10 baseline but P0 sub-checks (Tier 1 reviews exist) MUST be evaluated honestly |
| "Total 85/110, B+ grade" while Cat 8 has P0 fail | Audit-level verdict = FAIL when ANY P0 sub-check FAILS; total is descriptive only |
| Score subagents return aggregated category score only | Subagents MUST return per-check evidence list |
| Use "audit pending CI" as excuse to skip Cat 5 | If CI in_progress — mark Cat 5 ❓ UNCHECKED + retry, do not assume |

---

## 4. Bug-finding > scoring primacy (BLOCKING)

> **A `quality-audit` run's purpose is to surface bugs the dev team cannot trust other layers (CI, code review, per-domain skills) to catch. A high `/110` score with hidden P0 bugs is WORSE than a low score that lists every finding honestly.**

Rules for every `quality-audit` run:

1. **Enumerate ALL §2 sub-checks across 11 categories.** NEVER skip "obviously fine."
2. **Each sub-check returns** `PASS` / `FAIL` / `N/A-with-reason` / `❓ UNCHECKED`. No partial credit.
3. **Final output starts with bug list** (every FAIL surfaces with severity + evidence) BEFORE the score table.
4. **Score is descriptive only.** Audit-level verdict (`PASS` / `FAIL`) is the deliverable. FAIL if ANY P0 sub-check FAILS regardless of total.
5. **If audit time-budget runs out**, leave remaining sub-checks `❓ UNCHECKED` — do NOT mark PASS by default.

---

## 5. Enforcement (per `rule-change-process.md` §6.5)

### 5.1 quality-audit/SKILL.md rubric extension (paired same PR)

`skills/quality-audit/SKILL.md` Bước 2 cites this rule. Each Category's `| Tiêu chí | Điểm | Check |` table is the per-check rubric; FAIL semantics per §1 apply.

### 5.2 Pre-promotion gate

Before any release tag, `quality-audit` run MUST report ZERO P0 FAILs across §2.1-§2.11. Manual checklist suffices; script detector deferred per `incident-to-rule-pipeline.md` premature-rule guard.

### 5.3 Reviewer checklist

PR reviewer for any `quality-audit` output:
- [ ] Bug list precedes score table?
- [ ] Each Category lists per-check verdicts (not aggregated)?
- [ ] If any P0 FAIL: audit-level verdict marked FAIL?

### 5.4 Override mechanism

```
git commit -m "...
QUALITY_AUDIT_RUBRIC_DEFER: <check ID + reason>
QUALITY_AUDIT_RUBRIC_FOLLOWUP: <gap link with completion date>"
```

Trailer logged. Pattern frequency >2 defers per audit = meta-review of rubric.

### 5.5 Detector (deferred)

Future detector parses audit report markdown + verifies bug list precedes score + every Category has per-check breakdown. Defer until 2nd recurrence of averaging-hide incident.

---

## 6. Log

- Ported into starter-kit from an internal project's audit-rubric pack. Genericized: removed project-specific paths, module/script names, scores, and incident history. Methodology (11-category per-check pass/fail, P0/P1/P2 severity, bug-finding primacy, scoring caps) preserved intact.
