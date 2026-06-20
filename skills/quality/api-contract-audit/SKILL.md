---
name: api-contract-audit
description: "Dùng khi user nói 'api audit', 'contract check', 'kiểm tra API', 'endpoint match docs?', 'breaking change?', hoặc trước release. Verify API endpoints match api-contract.md /100."
user-invocable: true
---

# /api-contract-audit — API ↔ Documentation Sync

Score /100. Verify every controller endpoint is documented and every documented endpoint exists in code. Adapt `<module>` / `<modules>` placeholders to your project layout.

## Process

### 1. Extract Endpoints from Code

```bash
# Controllers in a single module
grep -rn "@GetMapping\|@PostMapping\|@PutMapping\|@DeleteMapping\|@PatchMapping\|@RequestMapping" \
  --include="*.java" src/main/ | grep -v test

# Controllers across all modules (multi-module project)
grep -rn "@GetMapping\|@PostMapping\|@PutMapping\|@DeleteMapping" \
  --include="*.java" <modules>/*/src/main/ | grep -v test
```

### 2. Extract Endpoints from Docs

```bash
# API contract docs (3-layer business docs convention)
grep -rn "^### \|^## \|GET \|POST \|PUT \|DELETE \|PATCH " \
  documents/01-business/*/api-contract.md | head -50
```

### 3. Primacy: bug-finding > scoring (BLOCKING)

> **An audit's purpose is to surface API-contract drift BEFORE consumers (mobile app, third-party integrations, partners) hit it. A `/100` score with hidden undocumented endpoints is WORSE than a low score listing each with `Controller.java:line` evidence.** Per `.claude/rules/audit-skill-rubric-api-contract-audit.md` §4 (mirror of the security-audit bug-finding-primacy pattern).

Rules for every audit run:
1. Enumerate ALL §4 sub-checks per category. NEVER skip "obviously fine."
2. Each sub-check returns: PASS / FAIL / N/A-with-reason / `❓ UNCHECKED`. No partial credit.
3. Final output starts with **bug list** (every undocumented/drifted endpoint with `file:line` + severity) BEFORE the score.
4. Score is descriptive only; audit-level verdict = FAIL if ANY P0 sub-check FAILS.
5. If audit time-budget runs out, mark `❓ UNCHECKED` — do NOT default to PASS.

### 4. Score 5 Categories with per-check rubric

Every category binds to a per-check pass/fail rule.

| # | Category (20pts) | Per-check rubric file |
|---|-----------------|-----------------------|
| 1 | **Endpoint Coverage** | **`.claude/rules/audit-skill-rubric-api-contract-audit.md` §2.1 (6 sub-checks)** |
| 2 | **Request/Response Match** | **`.claude/rules/audit-skill-rubric-api-contract-audit.md` §2.2 (6 sub-checks)** |
| 3 | **Error Code Consistency** | **`.claude/rules/audit-skill-rubric-api-contract-audit.md` §2.3 (5 sub-checks)** |
| 4 | **Versioning & Deprecation** | **`.claude/rules/audit-skill-rubric-api-contract-audit.md` §2.4 (5 sub-checks)** |
| 5 | **Integration Test Coverage** | **`.claude/rules/audit-skill-rubric-api-contract-audit.md` §2.5 (5 sub-checks)** |

#### Per-check scoring (all 5 categories)

For each Category N:
1. Walk through every §2 sub-check in the bound rule.
2. Mark each sub-check PASS / FAIL / N/A-with-reason / `❓ UNCHECKED`.
3. Score = `20 - (failed_P0_count * 6) - (failed_P1_count * 3) - (failed_P2_count * 1)`, floor 0; cap 20 if all PASS.
4. If ANY P0 sub-check fails → category total CAPPED at 16/20 AND audit-level verdict = FAIL.
5. Each FAIL surfaces in bug list per §3 primacy.

Legacy scoring narrative: `reference/scoring-guide.md` retained for backward-compat only.

### 5. Output

Save to `documents/audits/api-contract-audit-[date].md`

Format: 2-column table per domain — Code endpoints | Doc endpoints — highlight mismatches.

## Context Management

Token budget ~30-45K. Multi-microservice projects có thể tạo output rất lớn. Kiểm soát:

1. **Grep output limiting** — LUÔN `| head -30` per service. Tổng controller grep cho nhiều services nếu không limit = 200+ lines.
2. **Per-service delegation** — Nếu >4 microservices, chia subagent theo nhóm service:
   - Agent 1: core module (1 service)
   - Agent 2: remaining services
   - Mỗi agent: extract endpoints → compare với api-contract.md → trả mismatch list
3. **Diff-based audit** — Sau baseline, chỉ check endpoints trong files changed since last audit:
   ```bash
   git diff main --name-only | grep -E 'Controller\.java|api-contract\.md'
   ```
4. **Mismatch-first output** — KHÔNG list tất cả endpoints khớp. Chỉ output mismatches + summary count.

## Gotchas

- Gateway routes (`/api/v1/**`) proxy to backend services — check gateway config for actual public paths
- Multi-microservice projects — check ALL service controllers, not just one
- Public endpoints (no auth): `/public/**` — documented differently from authenticated ones
- Websocket/SSE endpoints may not follow REST pattern — document separately
- Controller grep output for many services rất lớn — LUÔN limit per service
- **Multi-module scope** — single-module greps miss controllers in sibling modules. If adding a new service module, update grep paths OR switch to broad `--include="*.java"` from repo root.

## Skill Contents

- `reference/scoring-guide.md` — Detailed rubric per category
