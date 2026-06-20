# Wave Coordinator Runbook

**Use when:** You (parent Claude session) are running a wave-pack — orchestrating 3-5 isolated agents from foundation PR through closure.

**Format:** Checklist/runbook for human-in-the-loop coordinator (NOT a prompt to feed Agent tool). Coordinator is the parent session; subagents are spawned via `Agent` tool with templates from siblings in this folder.

**Branch naming convention enforced:** all sub-PRs `feat|chore|test|docs/wave-{theme}-gap-{id-slug}[-suffix]`

## Coordinator phase checklist

### Phase 0 — Pre-flight (5 min)
- [ ] `claude mcp list` — verify GitHub MCP connected (per `.claude/rules/mcp-first-with-fallback.md`)
- [ ] `git checkout main && git pull --ff-only`
- [ ] Confirm wave plan exists: `documents/03-planning/waves/wave-{date}-{theme}.md`
- [ ] Confirm backlog/ROADMAP §"Active wave queue" lists this cluster as IN_PROGRESS
- [ ] Verify reserved migration slots noted in wave plan (if applicable)
- [ ] Verify task IDs in scope have Status `🔵 OPEN` or `🟡 PARTIAL` (not already DONE)

### Phase 1 — Foundation PR (10 min) — wave plan itself
- [ ] Branch: `wave/{theme}-plan` or `docs/wave-{theme}-plan` (NOT direct push — PR-first)
- [ ] PR title: `wave: {theme} cluster plan ({n} tasks)`
- [ ] PR body: link tasks, file-overlap matrix, deferred items
- [ ] Squash merge after CI green
- [ ] `git pull --ff-only` after merge

### Phase 2 — Spawn agents (1 message, multiple Agent calls)
- [ ] Pre-create worktrees: `git worktree add <worktree-path>/wave-{theme}-{role} main`
- [ ] Pre-create branches in each worktree
- [ ] **Single message** with N Agent tool uses in parallel (NOT sequential)
- [ ] Each Agent: `isolation=worktree`, `run_in_background=true`, `subagent_type=general-purpose`
- [ ] Pass concrete worktree path in prompt (agents drift to main repo otherwise)
- [ ] Cap: max 5 concurrent agents (the parallel-agent strategy)
- [ ] Model tier per stake (per `.claude/rules/agent-model-opus-default.md`)

### Phase 3 — Monitor + collect (variable, ~30-60 min)
- [ ] Each agent reports back: branch, PR URL, scope summary
- [ ] If agent silent + transcript mtime stale → respawn with same prompt
- [ ] If agent reports SOFT conflict expected (shared config file section) → note for Phase 4
- [ ] If agent escalates (e.g. p3-cleanup found non-trivial issue) → triage: defer to next wave OR re-scope
- [ ] While agents run, draft next wave plan inline (don't idle — per `.claude/rules/agent-concurrency-budget-inline-hybrid.md`)

### Phase 4 — Sequential merge (NOT batch — CI race risk)

For each agent's PR (in dependency order, typically A → B → C):
- [ ] `gh pr checks <PR>` — green
- [ ] Verify branch is up-to-date with main; if not, `gh pr update-branch <PR>`
- [ ] Resolve SOFT conflicts manually:
  - Whole-file reformats: prefer the agent's section, drop reformat
  - Shared config sections (values.yaml, application.yml): merge both sections, keep alphabetical
  - Backlog/ROADMAP races: coordinator owns; agents must NOT touch backlog index
- [ ] `gh pr merge <PR> --squash` (NOT `--delete-branch` — see Gotchas)
- [ ] `git checkout main && git pull --ff-only`
- [ ] Verify merge clean (`git log --oneline -3`)

### Phase 5 — Per-task status flips (per `.claude/rules/gap-done-discipline.md`)

For each closed task:
- [ ] Verify ALL Acceptance Criteria checkboxes `- [x]` in task file
- [ ] Verify NO banned phrases in DONE-flip Log entry: `deferred`, `defer to`, `manual run`, `out of scope`, `infra block`, `local can't`, `partial` (when status is DONE)
- [ ] If any AC unchecked → status stays `🟡 PARTIAL`, file follow-up task
- [ ] If all AC checked → flip Status to `🟢 DONE` with PR refs in Log
- [ ] Commit: `chore(gap): {GAP_ID} → DONE post-wave-{theme}`

### Phase 6 — Wave closure
- [ ] Backlog/ROADMAP §"Current Status Snapshot" — append wave-closure entry:
  - Wave name + date
  - Tasks closed (with PR refs)
  - Wall-clock metric (foundation PR → final merge)
  - Lessons-learned 1-liner
- [ ] Backlog/ROADMAP §"Active wave queue" — rotate cluster out, advance next
- [ ] Append to `data/wave-history.jsonl`:
  ```json
  {"wave":"{theme}","date":"YYYY-MM-DD","tasks":["GAP-X","GAP-Y"],"prs":[N1,N2],"wall_clock_min":75,"agents":3,"soft_conflicts":1,"hard_conflicts":0,"lessons":"..."}
  ```
- [ ] Commit: `chore(wave): close {theme} — N tasks, ~M min wall-clock`

### Phase 7 — Worktree cleanup (mandatory — per `.claude/rules/post-wave-cleanup.md`)

Manual sequence (each `gh pr merge --delete-branch` would fail with worktree referencing branch):
- [ ] `git worktree remove <worktree-path>/wave-{theme}-A` (repeat per agent)
- [ ] `git branch -D feat/wave-{theme}-gap-{id}-A` (repeat)
- [ ] `git push origin --delete feat/wave-{theme}-gap-{id}-A` (repeat)
- [ ] `git stash list` — drop any agent-stash entries (verify `git diff stash@{N}` matches what shipped)
- [ ] `git worktree prune`

### Phase 8 — Post-wave audit (per `.claude/rules/post-wave-audit-mandate.md`)
- [ ] Identify required audits per file patterns changed (UI / Business Logic / Security / Ops / Performance / API Contract)
- [ ] Schedule within the audit window (per rule)
- [ ] If touching `pom.xml`/`package.json` → security audit MUST run
- [ ] If touching `infrastructure/` → ops-readiness MUST run

## Gotchas

- **`--delete-branch` trap:** merging stacked PRs with `--delete-branch` auto-closes child PRs unrecoverable. NEVER use `--delete-branch` in wave merge. Manual cleanup in Phase 7.
- **Parent cwd drift:** after agent push + `gh pr merge`, parent cwd may end on agent's branch. Always prefix `cd <main-repo-path> && git checkout main`.
- **Stash dance:** if agents leak into main repo working copy, `git stash push -m "agent-X-stash" -- <files>` to preserve before switching context. Drop after verifying ship.
- **Sequential merge timing:** if Agent A's PR fails CI, do NOT skip to merge B/C — breaks dependency chain. Either fix A or abort wave.
- **Config-file validation:** if foundation PR or any agent touches CI workflow YAML, validate locally before push.
- **Banned-phrase check** is the most-missed step. Build a habit: open task file BEFORE flipping Status, scan Log entry text against `gap-done-discipline.md` banned list.
- **`data/wave-history.jsonl` append** is easy to forget — it's the only persistent record of wave wall-clock for tuning future waves.
- **Worktree absolute-path contamination:** when writing agent prompts (Step 5 spawn), use RELATIVE paths (`documents/04-quality/gaps/GAP-XXX.md`) NOT absolute (`/home/.../documents/...`). Otherwise agents bypass their worktree cwd, Write lands in MAIN repo, commits land on WRONG branch. **Post-spawn verification (mandatory):** check each PR's commit list for cross-task contamination: `for pr in $PR_LIST; do gh pr view $pr --json commits --jq '.commits[] | {sha: .oid[:8], msg: .messageHeadline}'; done`. If any PR has commits from another task → recovery plan: merge clean PRs first, locally rebase contaminated PR onto new main (git auto-skips duplicate commits), force-push, then merge.

## When NOT to use this runbook

- Single-task PR (not a wave) — use `.claude/skills/workflow/start-pr` skill instead
- 1-2 disjoint tasks — overhead of wave > benefit (per SKILL.md "When NOT to use")
- Hot-fix wave (production incident) — skip Phases 0-1, jump to Phase 2; document override
- Audit-driven wave (catch-up audits) — different methodology, see `post-wave-audit-mandate.md` runbook

## Reference

- Methodology: [`../../SKILL.md`](../../SKILL.md)
- Spawn pattern: [`../../reference/agent-spawning-template.md`](../../reference/agent-spawning-template.md)
- Wave closure detail: [`../../reference/retrospective-checklist.md`](../../reference/retrospective-checklist.md)
- File overlap analysis: [`../../reference/file-overlap-algorithm.md`](../../reference/file-overlap-algorithm.md)
- Rule: `.claude/rules/gap-done-discipline.md` (status-flip discipline)
- Rule: `.claude/rules/post-wave-audit-mandate.md` (post-wave audit cadence)
- Rule: `.claude/rules/post-wave-cleanup.md` (worktree + branch cleanup)
- Rule: `.claude/rules/admin-merge-discipline.md` (no `--admin` shortcut)
