---
name: end-session
description: "Dùng khi user nói 'end session', 'đóng session', 'kết thúc session', '/end-session', 'finish work', 'wrap up', hoặc trước khi /clear cho session quan trọng. Working-tree clean + sync gate + docs-sync (gap-status / ROADMAP / wave-history / MEMORY / session-handoff) + auto-write handoff note + archive session-lock + 1-line summary. Symmetric counterpart cho /start-session."
user-invocable: true
argument-hint: "[--check-only] [--allow-dirty] [--keep-lock] [--summary-only] [--skip-handoff] [--no-pr]"
---

# /end-session — Docs-Sync + Handoff + Lock Release

Portable workflow skill. Đóng session hiện tại: working-tree clean gate → docs-sync verify → auto-write handoff note → archive lock → 1-line summary. Symmetric counterpart cho `/start-session`.

Đảm bảo next session pickup clean state (không miss wave/gap/memory drift). Các bước tham chiếu gap/wave artifacts **degrade gracefully** khi project không dùng gap pipeline hoặc wave-pack methodology — skip target tương ứng.

## When to use

- Trước khi `/clear` cho session đã chạy ≥30 turns hoặc có critical work
- Khi switch sang task khác hoàn toàn
- Trước khi handoff cho session khác
- Khi parallel-agent xong task (tự release lock thay vì chờ stale-purge)

## Process

### Step 0a — Working-tree clean + sync gate (BLOCKING precondition)

Chạy TRƯỚC mọi bước khác. Mục tiêu: next session KHÔNG pickup vào dirty / uncommitted / unsynced state. Skip chỉ khi `--allow-dirty` (rare, document lý do).

```bash
bash .claude/skills/workflow/end-session/scripts/end-session.sh --check-only   # gate report
```

1. **Main tree clean** — `git status --porcelain` PHẢI empty. Nếu dirty:
   - File thuộc task hiện tại → commit vào branch (use git worktree per branch) + push + PR. KHÔNG để dangling uncommitted.
   - File rác/experiment → revert HOẶC `git stash push -m "<lý do>"` (note rõ để next session biết).
2. **Orphan worktrees** — `git worktree list`; mỗi worktree ≠ main tree: `git -C <wt> status --porcelain` PHẢI empty. Dirty worktree = landmine cho next session → commit+push, HOẶC `git worktree remove <wt>` nếu branch đã merged.
3. **Sync state** — `git fetch origin main`; `git rev-list --count main..origin/main`. Nếu >0 → main tree behind (fast-forward nếu đang trên main + clean; note nếu đang trên branch khác).
4. **Decision — end CHỈ được phép khi working tree clean AND một trong:**
   - **(a) Clean-slate:** tất cả session branch đã merged + main synced (rev-list 0). HOẶC
   - **(b) In-flight-handed-off:** branch dở dang đã `commit` + `push` lên remote + session-handoff note (Step 2.5) §Pickup trỏ đúng branch name + §Start-next-session có lệnh `git worktree add ../wt-<slug> <branch>` để next session tiếp tục.

   Nếu KHÔNG thỏa (a) hoặc (b) → **KHÔNG propose end**; resolve trước. Đây là gate cứng: dirty/unsynced + no-handoff = session sau mất phương hướng.

### Step 0 — Docs-sync verify (up to 5 targets)

Verify các target áp dụng được sync trước khi propose end. Target nào không tồn tại trong project → skip (graceful degrade):

| # | Target | Verify command | Skip when |
|---|---|---|---|
| 1 | `documents/04-quality/gaps/gap-status.csv` | gap-status check script PASS + recent gap flips reflected | project không dùng gap pipeline |
| 2 | `ROADMAP.md` §Current Status Snapshot | `grep` returns recent session ships (wave/gap/PR refs) | no ROADMAP |
| 3 | wave-history log (`.claude/skills/quality/wave-pack-planner/data/wave-history.jsonl`) | `tail -3` shows session's waves | project không dùng wave-pack methodology |
| 4 | `MEMORY.md` index | `tail -5` shows new memory entries (if any created) | no new memory entries |
| 5 | `documents/03-planning/session-handoffs/YYYY-MM-DD-*.md` | `ls -t … \| head -1` = today's date | — (always; Step 2.5 writes it) |

**Decision:** ANY applicable target stale → fix BEFORE propose end (bundle vào docs-only PR per `docs-only-pr-auto-merge.md` auto-merge eligible). KHÔNG defer "next session" — context flush = lose track.

### Step 1 — Resolve session id + active lock

```bash
SESSION_ID="${CLAUDE_SESSION_ID:-$(whoami)@$(hostname):ppid-$$}"
LOCK_DIR=".claude/session-locks"
```

Tìm lock file matching `session_id: $SESSION_ID`. Nếu không có lock → output "no active lock for this session" và exit (vẫn in summary).

### Step 2 — Build summary

Best-effort gather:

| Field | Source |
|-------|--------|
| Branch | `git branch --show-current` |
| PRs merged this session | `git log --since="$started" --grep="Merge pull request\|(#" main --oneline` |
| Gaps touched | `git log --since="$started" --name-only -- documents/04-quality/gaps/ \| grep GAP-` (skip if no gap pipeline) |
| Turn count | `$CLAUDE_TURN_COUNT` nếu có |
| Elapsed | `now() - lock.started` |

### Step 2.5 — Auto-write session-handoff note

Skip nếu `--skip-handoff` OR target #5 already present today.

Template: `.claude/skills/workflow/end-session/reference/handoff-template.md` (load on activation).

Path: `documents/03-planning/session-handoffs/YYYY-MM-DD-{wave-or-scope-slug}.md`

Required sections (6):
1. `## Scope shipped` — PRs + waves table
2. `## Gaps DONE / improved / NEW filed` (or "(no gap pipeline)" if N/A)
3. `## Lessons captured` — session-internal patterns (non-rule-class)
4. `## Stack state` — local stack health + known bugs
5. `## Pickup for next session` — next-wave queue + active blockers
6. `## Start next session` — concrete commands

### Step 2.6 — Append wave-history if waves shipped

Chỉ khi project dùng wave-pack methodology + có wave-level work shipped this session:

```bash
cat >> .claude/skills/quality/wave-pack-planner/data/wave-history.jsonl <<EOF
{"wave":"<name>","completed_at":"$(date +%Y-%m-%d)","outcome":"<1-line summary + PR refs>"}
EOF
```

One entry per wave completed. Skip nếu no wave-level work (gap-only / ad-hoc fixes).

### Step 3 — Archive the lock

```bash
DATE=$(date +%Y-%m-%d)
ARCHIVE_DIR="$LOCK_DIR/archived/$DATE"
mkdir -p "$ARCHIVE_DIR"
```

Append summary block vào cuối lock content (preserve original YAML), then `mv` vào `$ARCHIVE_DIR/`.

Skip archive nếu `--keep-lock` (rare — chỉ khi user muốn manual cleanup sau).

### Step 4 — Output 1-line summary (Vietnamese)

```
✓ Session {SID} archived → {archive-path}. {N} PRs merged, {M} gaps touched, {turns} turns, {elapsed} elapsed.
```

Nếu thiếu data → omit field gracefully.

### Step 5 — Open docs-only PR + propose /clear

Skip nếu `--no-pr` OR no docs changes made (Steps 0/2.5/2.6 all clean OR skipped).

Branch + commit + push per `docs-only-pr-auto-merge.md` — auto-merge eligible khi CI green (chỉ docs jobs run).

Sau khi PR merged → propose `/clear` cho user (clean handoff confirmed). KHÔNG auto-execute `/clear`.

## Helper script

Dùng `scripts/end-session.sh` (kèm theo skill) để one-shot — nhưng skill có thể compose từ shell commands trực tiếp nếu cần.

## Rules

- **TUYỆT ĐỐI tiếng Việt** trong output user-facing (theo project communication convention)
- Archive directory `.claude/session-locks/archived/` nên được `.gitignore` cover — verify bằng `git check-ignore .claude/session-locks/archived/foo.lock`
- Retention: archived locks giữ ~30 ngày, sau đó prune. Manual prune: `find .claude/session-locks/archived -type d -mtime +30 -exec rm -rf {} +`
- Nếu lock file không tồn tại → KHÔNG báo lỗi, chỉ in summary

## Gotchas

- `$CLAUDE_TURN_COUNT` chưa expose qua harness mặc định — best-effort, omit nếu không có
- `git log --since` cần ISO date format; lock `started:` field phải parse đúng
- WSL2: `hostname` có thể trả về khác nhau giữa shells — luôn dùng `$CLAUDE_SESSION_ID` nếu set
- Không archive nếu lock file đã bị session khác overwrite (race condition rare) — detect bằng compare session_id sau khi đọc
- Archive directory path phải RELATIVE từ repo root — agent worktree paths khác nhau

## Skill contents

- `SKILL.md` — this file (process entry-point)
- `scripts/end-session.sh` — helper one-shot lock archive + Step 0a gate
- `reference/handoff-template.md` — 6-section session-handoff template (loaded when Step 2.5 fires)

## Related

- `/start-session` (sister) — `.claude/skills/workflow/start-session/SKILL.md`
- session-lock guard hook (if present) — enforcement that this skill complements
- `.claude/rules/post-merge-sync-completeness.md` §2 — 4-target sync framework (handoff = target #5 extension)
- `.claude/rules/docs-only-pr-auto-merge.md` — handoff PR auto-merge eligibility
- `.claude/session-locks/README.md` — lock convention + retention policy (if present)

## Log

- **v1.0.0:** Skill ported into starter-kit — working-tree clean + sync gate (Step 0a), docs-sync verify (Step 0, up to 5 targets, degrades gracefully without gap/wave artifacts), auto-write session-handoff note (Step 2.5), wave-history append (Step 2.6, conditional), lock archive + 1-line summary (Steps 1-4), docs-only PR open (Step 5).
