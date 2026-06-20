# Context Template — Output Format + Lock Schema

Reference for `/start-session`. Read when formatting output OR managing locks.

**Language rule:** field labels + prose in Vietnamese per kit bilingual convention; keep English for technical terms (CI, CVE, PR, gap, wave, branch, main, merge — loanwords in dev context), file paths, command output, code.

## 1. Summary Block Format

Target: single fenced markdown block, ≤15 lines. Skip any empty field. Gap / Wave / Cloud rows appear ONLY when the corresponding artifact exists.

```
## Ngữ cảnh session ({ISO_TIMESTAMP})
**Nhánh:** {current git branch} ({clean|dirty|ahead-of-origin})
**Mức repo:** {GREEN|YELLOW|ORANGE|RED|BLACK or "(CI-only)"}
**PRs đang mở:** {count} ({top 3 #ids with 1-word status})
**CI:** {default branch} {green|red|unknown}
**MCP servers:** {connected}/{total}{ — FAILED: {list}}
**Wave hiện tại:** {wave id + short desc}            ← only if wave methodology in use
**Gaps blocker:** {top 3 P0/P1 gap IDs + 1-word topic} ← only if gap pipeline exists
**Cloud stack ({N}m cache):** {EC2/RDS/alarms summary}  ← only if --cloud passed
**Sức khỏe context:** {fresh|warm|degraded}
**Session locks đang active:** {N} ({list if conflict with intended work})
**Đề xuất tiếp theo:** {1-line next action}
```

> **MCP row:** if it reports failed servers or 0/N connected → suggest fixing before critical work. Missing GitHub MCP → PR/merge/check ops fall back to `gh` CLI per `mcp-first-with-fallback.md` §3 (works, but loses structured-output advantage). Name the failed server rather than silently falling back.

> **Cloud row (opt-in):** only when `--cloud` passed. Read-only describe/list calls, cached 30m in a git-ignored dir. If any alarm is in ALARM state, OR an instance expected-running is stopped → SURFACE it in "Đề xuất tiếp theo", not just the line.

### Vocabulary status

| Field | Values |
|-------|--------|
| nhánh | `clean` / `dirty` / `ahead` / `behind` / `diverged` |
| CI | `green` / `red` / `pending` / `unknown` |
| sức khỏe context | `fresh` (<20 turns) / `warm` (20-40) / `degraded` (>40 OR >2h since compact) |
| PR status | `review` / `draft` / `ci-fail` / `approved` / `conflicts` |
| MCP servers | `N/M` connected (e.g. `1/1` clean, `0/1 — FAILED: github`) |
| cloud status | `cached` / `fresh` (data OK) / `skipped` (no --cloud) / `no-cli` / `no-auth` / `error` |

## 2. Lock File Schema

**Path:** `.claude/session-locks/session-{YYYYMMDD-HHMMSS}-{hostname}.lock`

**Format:** YAML (editor-readable, `yq`-parseable).

```yaml
session_id: 20260101-143200-host
started: 2026-01-01T14:32:00+07:00
hostname: host
pid: 12345                    # optional, for stale-lock cleanup
branch: feat/example-feature
worktree: /home/user/projects/repo/.claude/worktrees/agent-a8fc490c
gaps:
  - GAP-101
  - GAP-102
intent: |
  Closing GAP-101 + GAP-102 — short description.
estimated_turns: 20
last_heartbeat: 2026-01-01T14:55:00+07:00   # update every ~10 turns
```

**Required:** `session_id`, `started`, `branch`, `gaps` (may be empty). **Optional:** `pid`, `worktree`, `intent`, `estimated_turns`, `last_heartbeat`.

## 3. Overlap Detection

When `/start-session` runs, scan existing locks:

| Condition | Action |
|-----------|--------|
| Another lock has the same `branch` | **BLOCK by default** — warn, ask confirm |
| Another lock has overlapping `gaps` | **WARN** — show the other session's intent, let user decide |
| Another lock shares the `worktree` path | **BLOCK** — worktree is single-session |
| Lock older than 4h (no heartbeat) | **Auto-purge** — stale, remove |
| No overlap | Create own lock, proceed |

## 4. Example Output

### 4.1 Fresh session, repo green
```
## Ngữ cảnh session (2026-01-01 09:00)
**Nhánh:** main (clean, up-to-date)
**PRs đang mở:** 0
**CI:** main green
**MCP servers:** 1/1 connected (github ✓)
**Sức khỏe context:** fresh (turn 1)
**Đề xuất tiếp theo:** pick next task OR /repo-status
```

### 4.2 Mid-wave, 3 parallel agents, 1 CI red
```
## Ngữ cảnh session (2026-01-01 15:40)
**Wave hiện tại:** example cluster (3 agents in flight)
**Nhánh:** main (clean)
**PRs đang mở:** 4 (#101 approved, #102 ci-fail, #103 review, #104 draft)
**CI:** main green, #102 red (test flake)
**Session locks đang active:** 3 (agent-B, agent-C — no overlap with intent)
**Đề xuất tiếp theo:** /fix-pr 102 to unblock OR continue agent task
```

### 4.3 Degraded session, user should clear
```
## Ngữ cảnh session (2026-01-01 22:10)
**Nhánh:** feat/example (dirty, uncommitted)
**PRs đang mở:** 2
**CI:** main green
**MCP servers:** 0/1 — FAILED: github (Docker daemon down?)
**Sức khỏe context:** DEGRADED (turn ~55, last compact 3h ago, quality drift likely)
**Đề xuất tiếp theo:** Fix MCP + commit WIP + /clear + re-run /start-session BEFORE critical merge
```

## 5. Minimal Output Mode (`--quick`)

Single line — `collect-state.sh --quick`:

```
Mức: GREEN · Nhánh: main (clean) · PRs: 0 · CVE H/C: 0/0 · MCP: 1/1 · Wave: n/a
```

Use when the user only needs a sanity check, not the full digest.

## 6. Integration with other skills

- `/repo-status` gives richer health signal; `/start-session` is faster for routine entry.
- `/end-session` consumes lock history for retrospective + writes a handoff note.

## 7. Anti-patterns

| ❌ Don't | ✅ Do |
|---------|------|
| Dump full CLAUDE.md into context | Digest — it auto-loads already |
| List all gaps in blockers | Top 3 P0/P1 only |
| Skip lock check because "solo session" | Check anyway — cheap, future-proof |
| Leave stale locks | Auto-purge >4h each run |
| Treat lock as hard enforcement | Hint only — git worktree isolation is the real barrier |
| Probe cloud every turn | Cloud is opt-in + cached 30m; only `--refresh-cloud` after an infra change |
