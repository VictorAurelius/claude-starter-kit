---
name: start-pr
description: "Dùng khi user runs `/start-pr` (check current PR artifacts) hoặc `/start-pr PR-X.Y feature-name` (start new PR). Verifies methodology artifacts (brainstorm, task breakdown, TDD compliance, tests, docs) and either reports status or kicks off a new feature with the methodology scaffolding."
disable-model-invocation: true
---

# Start PR / Check PR Quality

Portable workflow skill — adapt `{frontend-package}` placeholders + project audit suite.

**Usage:**
- `/start-pr` - Check PR hiện tại (verify artifacts, quality)
- `/start-pr PR-5.9 feature-description` - Bắt đầu PR mới

**Tool preference:** GitHub MCP if connected (`claude mcp list`), else `gh` CLI. See `.claude/rules/mcp-first-with-fallback.md`.

---

## Instructions

Khi user invoke `/start-pr $ARGUMENTS`:

### Mode 1: Check PR hiện tại (không có argument)

**Bước 1: Detect context**
```bash
git branch --show-current
git status --short
```

**Bước 2: Verify methodology artifacts**

Kiểm tra và báo cáo trạng thái của từng item:

1. **Brainstorm Document**
   - Tìm trong: PR description, commit messages, hoặc file riêng
   - Phải có: scope, risks, edge cases, alternatives considered
   - Status: ✅ Có / ❌ Thiếu / ⚠️ Không đầy đủ

2. **Task Breakdown**
   - Tìm trong: PR description, commit messages, hoặc file riêng
   - Phải có: list tasks cụ thể với estimates
   - Status: ✅ Có / ❌ Thiếu / ⚠️ Không đầy đủ

3. **TDD Compliance**
   - Kiểm tra git log: test commits trước implementation commits?
   - Kiểm tra file timestamps nếu cần
   - Status: ✅ Tests trước / ❌ Code trước / ⚠️ Không rõ

4. **Code Review**
   - Đã self-review theo `.claude/skills/core/two-stage-code-review.md`?
   - Status: ✅ Đã review / ❌ Chưa review

**Bước 3: Output Report**

```markdown
## PR Quality Check: [branch-name]

### Methodology Compliance

| Step | Status | Notes |
|------|--------|-------|
| 1. Brainstorm | ✅/❌/⚠️ | [details] |
| 2. Task Breakdown | ✅/❌/⚠️ | [details] |
| 3. TDD (Tests First) | ✅/❌/⚠️ | [details] |
| 4. Code Review | ✅/❌/⚠️ | [details] |

### Actions Required

[List items cần fix trước khi merge]

### Recommendations

[Suggestions to improve PR quality]
```

---

### Mode 2: Bắt đầu PR mới (có argument)

**Input:** `/start-pr PR-5.9 admin-analytics`

**Bước 1: Tạo Feature Branch**
```bash
git checkout main
git pull origin main
git checkout -b feature/PR-5.9-admin-analytics
```

**Bước 2: Quick Brainstorm (output to console)**

Thực hiện brainstorm theo `.claude/skills/core/brainstorming-methodology.md`:

```markdown
## Quick Brainstorm: PR-5.9 admin-analytics

### Scope
- [What features/changes are included]
- [What is explicitly OUT of scope]

### Risks
- [Technical risks]
- [Integration risks]
- [Performance risks]

### Edge Cases
- [Edge case 1]
- [Edge case 2]

### Dependencies
- [Other PRs this depends on]
- [External services/APIs needed]

### Alternatives Considered
- [Option A - why/why not]
- [Option B - why/why not]

### Decision
[Chosen approach with brief rationale]
```

**Bước 3: Task Breakdown (output to console)**

Thực hiện breakdown theo `.claude/skills/core/task-breakdown-guide.md`:

```markdown
## Task Breakdown: PR-5.9 admin-analytics

### Tasks

| # | Task | Estimate | Type |
|---|------|----------|------|
| 1 | [Task description] | 30 min | Test |
| 2 | [Task description] | 1 hour | Implementation |
| 3 | [Task description] | 30 min | Test |
| ... | ... | ... | ... |

### Total Estimate: X hours

### Test Files to Create First (TDD)
- [ ] `src/.../Feature.test.tsx`
- [ ] `src/.../Feature.spec.ts`

### Implementation Order
1. Write tests (RED)
2. Implement to pass tests (GREEN)
3. Refactor if needed (REFACTOR)
4. Self-review before commit
```

**Bước 4: Required Audits (auto-detect từ scope)**

Dựa trên files sẽ thay đổi, liệt kê audits cần chạy TRƯỚC merge (chỉ những audit project có trong audit suite):

```markdown
## Required Audits

| Files Changed | Likely Audit | Command |
|--------------|--------------|---------|
| {frontend-package}/** | UI Review | `/ui-review` |
| Controller / DTO / endpoint code | API Contract audit | per project audit suite |
| dependency manifests (pom.xml, package.json) | Security audit | per project audit suite |
| infrastructure / Dockerfile | Ops Readiness audit | per project audit suite |
| broad change → merge gate | Quality audit /110 | `/quality-audit` |

**Applicable for this PR:** [list based on scope from brainstorm]
```

Nếu project có audit-gate hook, nó sẽ nhắc lại khi merge nếu audit bị miss (per `post-wave-audit-mandate.md`).

**Bước 5: TDD Reminder**

```markdown
## TDD Workflow Reminder

1. **RED**: Write failing tests first
2. **GREEN**: Write minimal code to pass
3. **REFACTOR**: Clean up while tests pass

### Commands
- Run tests: `pnpm test` (frontend) or project test script (`scripts/test-local.sh`)
- Watch mode: `pnpm test --watch`

### KHÔNG được:
- ❌ Viết implementation trước tests
- ❌ Commit code không có tests
- ❌ Skip code review
```

---

## Related Skills

- `.claude/skills/core/brainstorming-methodology.md` - Full brainstorm process
- `.claude/skills/core/task-breakdown-guide.md` - Detailed breakdown guide
- `.claude/skills/core/tdd-enforcement.md` - TDD patterns
- `.claude/skills/core/two-stage-code-review.md` - Self-review checklist

---

## Gotchas

- **Mode 1 TDD detection is heuristic, not authoritative** — git log timestamps lie when commits are squashed/amended; if Mode 1 reports "⚠️ Không rõ" treat it as ❌ until tests are confirmed via filename pattern (`*Test.java`, `*.test.tsx`)
- **Mode 2 Bước 4 audit list is SCOPE-DEPENDENT, not exhaustive** — the project's audit-gate hook (if present) is the source of truth; a PR touching a lockfile can trigger a Security audit even if you didn't edit the manifest directly (per `post-wave-audit-mandate.md` §2.1 file-pattern matrix)
- **Mode 2 brainstorm output goes to console, NOT file** — per Bước 2/3 the brainstorm + breakdown render to stdout for the user to paste into the PR description; storing them as standalone planning docs is only right when the work is wave-scope
- **Brainstorm "out of scope" section must list deferred work concretely** — if the project uses a gap pipeline, deferred items announced here become follow-up gaps later (per `gap-done-discipline.md` §3 PARTIAL exit ramp), so write them with file paths + AC bullets, not vaguely ("polish later")
- **Required-audits list runs BEFORE merge, not after PR creation** — audit gates block at merge time per `post-wave-audit-mandate.md` §3, so Bước 4 list must drive an actual audit run during the PR cycle, not just sit in the PR description as documentation
