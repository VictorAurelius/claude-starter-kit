---
name: start-session
description: "Use when the user says 'start new session', 'bắt đầu session mới', '/start-session', 'what's the state?', 'tình trạng hiện tại', or when context must be reloaded after /clear. Loads: branch, open PRs, failing CI, recent commits, plus optional gap/wave/cloud sections when those artifacts exist. Output: single summary block. Also checks session-lock conflicts when running parallel agents."
user-invocable: true
argument-hint: "[--quick] [--no-lock] [--cloud|--refresh-cloud]"
---

# /start-session — Session Orchestration

Prepare a fresh session by loading the right context + detecting conflicts with concurrent sessions. Works in ANY project; project-specific sections (gap pipeline, wave history, cloud stack) degrade gracefully when absent.

## When to use

- Starting a new conversation in this repo
- After `/clear` or `/compact`
- Before critical work (wave merge, audit, release)
- When unsure "what next?" → run this instead of reading blindly

## Process

### Step 1 — Run the state collector

```bash
./.claude/skills/workflow/start-session/scripts/collect-state.sh
```

Output: active branch, open PR count + per-PR CI/merge state, repo health level, current wave (if any), top blocker gaps (if a gap pipeline exists), MCP server status, recent commits. Cloud stack is opt-in via `--cloud`.

### Step 2 — Read digest sources (context-aware — minimize auto-load)

Default to script/CSV queries over narrative file reads. Reading files under `documents/**` may trigger path-scoped rule auto-loads and inflate context (per `context-budget-mandate.md`).

Default flow (skip file reads):
1. **Branch / PRs / CI / blockers** — already in `collect-state.sh` output.
2. **Gap detail** (if project uses a gap pipeline) — query `gap-status.csv` instead of reading each gap file.
3. **Recent waves** (if project uses wave-pack methodology) — `tail -3 .claude/skills/quality/wave-pack-planner/data/wave-history.jsonl`.

Only `Read` files when the user explicitly asks OR the script output is insufficient for the task at hand. `CLAUDE.md` auto-loads every session — no need to re-read.

### Step 3 — Session-lock check (optional, `--no-lock` skips)

1. `ls .claude/session-locks/` — list active locks.
2. If a lock matches a branch/gap the user intends to touch → **WARN**: "Session X is editing branch Y / GAP-Z, continuing risks conflict."
3. User confirms → create own lock: `session-{timestamp}-{hostname}.lock`.
4. Lock content: YAML with `branch`, `gaps`, `started`, `intent`.

Schema + overlap rules: `reference/context-template.md` §Lock File Schema.

### Step 4 — Output summary block

Format per `reference/context-template.md`. Data sources (from `collect-state.sh`):

| Field | Source |
|-------|--------|
| Branch state | `git diff --name-only` |
| Open PRs | `gh pr list` (per-PR CI + mergeStateStatus) |
| Repo level | `scripts/repo-status.sh --json` `.level` if present, else CI-only |
| CVE / stale branches | same `--json` → `.security`, `.branches` (if repo-status.sh present) |
| Recent commits | `git log <default-branch> --since='3 days ago' --oneline` |
| **MCP servers** | `claude mcp list` → connected/total + failed names. Verify at session start per `mcp-first-with-fallback.md` §3 (avoid defaulting to CLI all session because MCP availability was never checked). |
| **Wave** (optional) | `wave-history.jsonl` tail — only when wave-pack methodology in use |
| **Blocker gaps** (optional) | `gap-status.csv` — only when a gap pipeline exists |
| **Cloud stack** (opt-in) | `--cloud` → read-only `aws sts/ec2/rds/cloudwatch describe`; cached 30m |

Example output (bilingual — labels in Vietnamese per kit convention; technical terms kept English):

```
## Ngữ cảnh session (2026-01-01 09:30)
**Nhánh:** main (clean) / worktrees: 0
**Mức repo:** GREEN (CI green, 0 CVE, 0 stale branches, 0 audit P0)
**PRs đang mở:** 0
**MCP servers:** 1/1 connected (github)
**Gaps blocker (top):** GAP-101, GAP-102   ← only if gap pipeline exists
**Wave hiện tại:** Wave example — shipped   ← only if wave methodology in use
**Sức khỏe context:** fresh session
**Đề xuất tiếp theo:** pick a blocker gap to fix OR /repo-status for a deeper triage
```

### Step 4 flags (collect-state.sh)

| Flag | Effect |
|---|---|
| `--quick` | One-line summary |
| `--json` | Structured JSON for hooks / other agents |
| `--no-lock` | Skip session-lock check / create |
| `--cloud` | Opt-in: probe cloud stack (AWS read-only) |
| `--refresh-cloud` | Bypass 30m cloud cache, fetch now |

### Step 4.5 — Parallel-eligibility hint (mandatory after determining "next action")

Whenever proposing a next action, scan whether it is wave-eligible. If yes → nudge the user toward a wave + parallel agents instead of serial PRs.

**Wave-eligible when:**
1. ≥3 clearly-divided sub-tasks (Phase 1/2/3, Sub-PR a/b/c, Layer 1/2/3…)
2. Files each sub-task touches are disjoint (no shared config, no shared migration version, no shared service class)
3. Each sub-task is a self-contained TDD/build cycle (no waiting on another)

**NOT wave-eligible when:** only 1-2 sub-tasks; sub-tasks share a migration version slot; sub-tasks share a single config file; or foundation hasn't shipped yet (PR-0 needs to ship shared interfaces first).

If wave-eligible → output:

```
**Wave-eligible:** YES — N disjoint sub-tasks. Suggest: wave plan + spawn 4-5 parallel agents (`isolation:worktree`, max 5).
Reference: `.claude/skills/quality/wave-pack-planner/SKILL.md`.
```

Else:

```
**Wave-eligible:** NO — {reason, e.g. "shared config file" / "1 sub-task"}. Serial PR is fine.
```

Rationale: picking a multi-phase task and shipping serial PRs is ~3x slower than parallel agents on disjoint scope.

### Step 5 — Handoff to next skill

User decides:
- **Wave plan** (if Step 4.5 says YES) — `.claude/skills/quality/wave-pack-planner/SKILL.md`
- `/repo-status` — deeper health check
- Single-gap PR flow — `.claude/skills/workflow/start-pr/SKILL.md`
- `/check-pr` / `/fix-pr` — audit / repair an in-flight PR

## Context-degradation heuristic

Flag the session **degraded** if ANY: turn count > ~40; last `/compact` > 2h ago; user reports output-quality drop; multiple retries on simple tasks.

**Action when degraded:** nudge user to `/clear` + re-run `/start-session`. Don't proceed with critical work (wave merge, production deploy) in a degraded session.

## Session lock convention

Directory: `.claude/session-locks/` (git-ignored, per-machine). File: `session-{YYYYMMDD-HHMMSS}-{hostname}.lock`. Schema: `reference/context-template.md` §Lock File Schema.

Lifecycle: created on `/start-session` (unless `--no-lock`); updated when switching branch/gap; removed on `/end-session` OR stale-purged after 4h. Lock is a HINT — git worktree isolation is the real conflict barrier.

## Rules

- LUÔN chạy `collect-state.sh` trước — không tự suy diễn status.
- If the script fails (gh unauthed, jq missing) → report it clearly, don't guess.
- **MCP status MUST appear in summary** — if MCP servers failed or 0/N connected, suggest fixing before critical work (GitHub MCP is needed for merge/PR ops); per `mcp-first-with-fallback.md` §3 fall back to CLI but know to swap back when fixed.
- **Step 4.5 is mandatory** — always emit a "Wave-eligible: YES/NO" line after the next-action suggestion.
- Gap / Wave / Cloud sections are OPTIONAL — only surface them when the artifact exists.

## Gotchas

- `collect-state.sh` needs `gh` authenticated for PR/CI fields — falls back gracefully otherwise.
- `.claude/session-locks/` and `.claude/session-cloud-cache/` MUST be git-ignored.
- Stale locks (>4h) auto-purged; a crash mid-session can leave an orphan — `--no-lock` or manual `rm` clears it.
- MCP transient connect failure: `claude mcp list` may show `✗ Failed` then `✓ Connected` on retry (Docker daemon starting / image pulling). On failure: verify daemon, restart server, re-list; if still failed, fall back to CLI per `mcp-first-with-fallback.md` §3.
- Cloud section is opt-in (`--cloud`) and read-only — never returns secret material (describe/list only). Cache is git-ignored.

## Skill contents

- `SKILL.md` — this file
- `reference/context-template.md` — output format + lock schema + examples
- `scripts/collect-state.sh` — state collector (full / `--quick` / `--json`; `--cloud` / `--refresh-cloud` / `--no-lock`)

## Related

- `.claude/skills/workflow/repo-status/SKILL.md` — deeper remote health
- `.claude/skills/workflow/end-session/SKILL.md` — symmetric counterpart (docs-sync + handoff + lock release)
- `.claude/skills/quality/wave-pack-planner/SKILL.md` — wave + parallel-agent methodology (Step 4.5 handoff)
- Rule: `.claude/rules/output-review-mandate.md` (sessions produce outputs)
- Rule: `.claude/rules/mcp-first-with-fallback.md` (MCP status check at session start)
- Rule: `.claude/rules/context-budget-mandate.md` (why Step 2 prefers queries over file reads)
