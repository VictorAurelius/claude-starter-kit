---
name: check-pr
description: "Dùng khi user runs `/check-pr` hoặc nói 'check PR', 'verify CI', 'kiểm tra PR', 'ready to merge?'. Monitor CI via project scripts or GitHub MCP, run local tests if available, output verdict (✅ ready / ❌ fix needed / ⚠️ conditional)."
user-invocable: true
argument-hint: "[PR-number|branch-name]"
---

# /check-pr — Monitor CI & Verify PR Quality

Portable workflow skill — adapt `{module}` / `{frontend-package}` + project script names.

## Usage

```
/check-pr 207              # Check PR #207
/check-pr feature/foo      # Check branch feature/foo
/check-pr                  # Check current branch
```

---

## Rules

1. **MCP-first** — dùng GitHub MCP nếu connected (`claude mcp list`), `gh` CLI làm fallback. Chi tiết: `.claude/rules/mcp-first-with-fallback.md`
2. **Prefer project scripts** — nếu repo có CI-check / test scripts, dùng chúng thay vì gõ `gh run list` ad-hoc
3. **Local verify khi có thể** — chạy E2E / unit / build tại local nếu môi trường cho phép; thiếu local ≠ block (CI là minimum gate)

---

## Step 1: Identify Target

```bash
# Nếu PR number:
PR_NUMBER=$ARGUMENTS
BRANCH=$(gh pr view $PR_NUMBER --json headRefName --jq '.headRefName')

# Nếu branch name:
BRANCH=$ARGUMENTS

# Nếu không có argument:
BRANCH=$(git branch --show-current)
```

---

## Step 2: Monitor CI

**Primary (MCP if connected):** dùng GitHub MCP `list_workflow_runs`, filter by branch + status.

**Fallback (CLI / project script):**

```bash
# Nếu project có CI-check script (vd scripts/check-ci.sh), dùng nó:
bash scripts/check-ci.sh $BRANCH        # poll, exit 0 nếu pass / 1 nếu fail

# Nếu không có script:
until gh run list --branch "$BRANCH" --limit 1 --json conclusion \
  --jq '.[0].conclusion' | grep -qE 'success|failure'; do sleep 30; done
```

**Lưu ý:** CI listing pick lên TẤT CẢ runs trên branch (kể cả cũ). Nếu thấy failure → check timestamp để phân biệt run cũ vs run hiện tại.

---

## Step 3: Analyze Failures (nếu CI fail)

```bash
# Tìm failed run ID
FAILED_RUN=$(gh run list --branch $BRANCH --limit 5 \
  --json databaseId,workflowName,conclusion \
  --jq '.[] | select(.conclusion=="failure") | .databaseId' | head -1)

# Xem log lỗi
gh run view $FAILED_RUN --log-failed 2>/dev/null | tail -30

# Tìm root cause
gh run view $FAILED_RUN --log-failed 2>/dev/null \
  | grep -E "ERROR|FAIL|Compilation|cannot find|Tests run.*Failures: [1-9]|Tests run.*Errors: [1-9]" \
  | head -10
```

---

## Step 4: Local Verification (TRƯỚC khi merge)

Chạy những cái áp dụng được; thiếu công cụ → mark `⏭️ skipped`, KHÔNG block.

### 4a. E2E / integration (nếu stack chạy được local)

```bash
# Check service health trước (project's health-check script nếu có)
bash scripts/wait-for-healthy.sh 2>/dev/null   # hoặc tương đương

# Chạy E2E (project's E2E test script)
bash scripts/test-api-e2e.sh 2>/dev/null

# Nếu stack down → ghi nhận: "⚠️ stack not running — E2E skipped, rely on CI"
```

### 4b. Unit tests (nếu toolchain available)

```bash
# Backend module (adapt build tool + module name)
JAVA_HOME=$JAVA_HOME ./mvnw clean test -pl {module} -am -q

# Frontend package
pnpm -F {frontend-package} test --run
```

### 4c. Frontend build

```bash
pnpm -F {frontend-package} build
```

**Note:** Nếu không thể chạy local → ghi nhận và rely on CI. KHÔNG block merge vì thiếu local test — CI là minimum.

---

## Step 5: Output Report

```markdown
## PR Check Report: #[number] ([branch])

### CI Status
- [ ] All workflows: ✅/❌
- Failed: [list if any]

### Local Verification
- [ ] E2E / integration: ✅/❌/⏭️ skipped
- [ ] Unit tests: ✅/❌/⏭️ skipped
- [ ] Frontend build: ✅/❌/⏭️ skipped

### Issues Found
[Any failures with root cause]

### Verdict
✅ Ready to merge
❌ Fix needed: [description]
⚠️ Conditional: CI pass but local not verified
```

---

## Step 6: Merge (CHỈ khi verdict = ✅)

**KHÔNG merge nếu verdict = ❌ hoặc ⚠️ chưa resolve.**

### 6a. Phân biệt merge target

```
User nói "merge" → merge feature PR(s) vào branch tích hợp (vd wave/integration branch)
User nói "merge vào main" → merge integration branch → main
KHÔNG BAO GIỜ tự suy diễn merge vào main
```

### 6b. Xác nhận user approve

**LUÔN hỏi trước khi merge:**
- PR → integration branch: "Merge N PR(s) vào <branch>?"
- Integration → main: "Check pass. Merge <branch> → main?"
- KHÔNG tự merge bất kỳ thứ gì mà không có confirm rõ ràng.

### 6c. Merge command

```bash
# Feature PR → integration branch (user đã confirm):
gh pr merge [number] --squash --delete-branch

# Integration → main (user đã confirm RÕ RÀNG "merge vào main"):
gh pr merge [number] --squash --delete-branch
git checkout main && git pull
```

### 6d. VIOLATION LOG (lesson from an early wave)
User nói "merge" → agent merge cả integration branch → main mà không hỏi.
Đúng ra: chỉ merge feature PRs vào integration branch, rồi HỎI user trước khi integration → main.

### 6e. Verify sau merge

```bash
git checkout [target-branch] && git pull
# Verify CI triggered trên target (MCP list_workflow_runs hoặc gh run list)
```

---

## Step 7: Cleanup (sau merge)

```bash
git remote prune origin
# Clean worktrees (per worktree-per-branch convention)
git worktree prune

echo "Open PRs:" && gh pr list --state open --json number --jq 'length'
```

---

## Integration với wave process

Nếu project dùng wave-pack methodology (`.claude/skills/quality/wave-pack-planner`):

```
Per PR:  /check-pr [PR-number]          ← Sau agent tạo PR
Wave:    /check-pr <integration-branch> ← Sau merge tất cả PRs vào branch
Main:    /check-pr main                 ← Sau merge → main
```

---

## Gotchas

- **`gh pr checks --json state` có thể trả null** — use `--json status` hoặc project's CI-check script instead; raw `state` field breaks polling loops silently
- **CI listing picks up STALE failures** — shows ALL runs on the branch including ancient ones; cross-check timestamps before declaring "CI red"
- **Stacked PR `--delete-branch` trap** — merging a stacked PR with `--delete-branch` auto-closes child PRs and they cannot be reopened; for stacks merge parent without `--delete-branch` first, then re-target child
- **"merge" never auto-promotes integration → main** — Step 6 is explicit but easy to skip: "merge" means feature PRs → integration branch ONLY; → main requires separate explicit confirmation (see §6d)
- **Local skip ≠ block** — if stack down or toolchain unset, mark E2E/unit `⏭️ skipped` and rely on CI; verdict can still be ✅ Ready; do NOT downgrade to ❌ just because local couldn't run
