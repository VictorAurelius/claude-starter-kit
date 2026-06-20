# worktree-only-branch-work — Worked self-tests

Companion to `.claude/rules/worktree-only-branch-work.md` §6. Body moved here (deferred-load) per `context-budget-mandate.md` §3.2 — keeps the always-load rule body under the always-load byte ceiling.

---

## Self-test — main-tree checkout-swap incident

**Scenario:** Phiên này khởi động trên `wave/branding-fix` (HEAD `e7444b45`). Giữa lúc đang điều tra nhiều PR, một phiên song song chạy `git checkout feature/some-other-work` trong **cùng main working tree** → main tree HEAD đột ngột nhảy sang `91352f74` dưới chân phiên này.

**Apply rule retroactively (counterfactual):** Phiên song song lẽ ra chạy
`git worktree add ../wt-other feature/some-other-work`
thay vì checkout → main tree **giữ nguyên** `wave/branding-fix` cho phiên này; cả hai phiên làm song song không đè nhau.

| Metric | Without rule | With rule |
|---|---|---|
| Main tree branch ổn định cho phiên đang chạy | ❌ bị swap giữa chừng | ✅ giữ nguyên |
| Rủi ro đè dirty edits chưa commit | CAO | ~0 (cô lập) |
| Build/test context nhất quán | ❌ đổi giữa chừng | ✅ |
| Cost | confusion + re-orient | ~200ms worktree add |

→ Rule fires đúng trên chính incident sinh ra nó. Self-test PASS ✅

---

## Self-test — duplicate-rule-load incident (in-repo worktree)

**Scenario:** Phiên fix tạo worktree IN-REPO `.claude/worktrees/wt-fix/`. Khi đọc/sửa file dưới `wt-fix/...`, harness auto-load THÊM `wt-fix/.claude/CLAUDE.md` + ~30 `wt-fix/.claude/rules/*.md` — chồng lên bản main tree đã load (screenshot ~30 dòng `Loaded .claude/worktrees/wt-fix/.claude/rules/...`).

**Apply rule retroactively (counterfactual):** Tạo worktree SIBLING `../wt-fix` (ngoài repo root) thay vì in-repo → `.claude/` worktree KHÔNG nested dưới main → harness load 1 bộ rules theo cây file đang thao tác, KHÔNG chồng main → 0 duplicate.

| Metric | In-repo `.claude/worktrees/` | Sibling `../wt-` |
|---|---|---|
| Bộ rules auto-load | 2× (main + worktree) | 1× |
| CLAUDE.md auto-load | 2× | 1× |
| Context phình | ~2× rule footprint | baseline |
| Cost | context budget regression | ~0 |

→ Rule fires đúng trên chính incident sinh ra nó. Self-test PASS ✅

### Detector self-test — worktree-path check

Synthetic fixture — feed các lệnh vào PreToolUse detector, expect verdict:

| Command | Expect |
|---|---|
| `git worktree add .claude/worktrees/wt-x feat/x` | 🛑 BLOCK (in-repo) |
| `git worktree add -b new .claude/worktrees/wt-new origin/main` | 🛑 BLOCK (in-repo `-b` form) |
| `git worktree add /abs/path/inside/repo/tmp-wt feat/x` | 🛑 BLOCK (absolute path inside repo root) |
| `git worktree add ../wt-x feat/x` | ✅ ALLOW (sibling outside repo) |
| `git worktree add -b new ../wt-new origin/main` | ✅ ALLOW (sibling `-b` form) |
| `git worktree remove ../wt-x` | ✅ ALLOW (not `add`) |
| `git worktree list` | ✅ ALLOW (not `add`) |

Detector fires correctly on the in-repo pattern (block) + allows the corrected sibling pattern. Self-test PASS ✅
