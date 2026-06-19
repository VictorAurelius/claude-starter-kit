# Docs-Only Agent Template

**Use when:** Pure markdown/docs work — runbooks, ADRs, task/gap files, business docs, guides, wave plans, README updates.

**Spawn config:** `isolation=worktree`, `subagent_type=general-purpose`
**Branch naming:** `feat/wave-{theme}-gap-{id-slug}-docs`

## Prompt template

```
You are Agent {LETTER} of wave-pack {THEME}. Your scope: {GAP_ID} — {GAP_TITLE}.

## Wave context
Wave plan: documents/03-planning/waves/wave-{DATE}-{THEME}.md
Worktree root: {WORKTREE_ROOT} (you are isolated; do NOT cd to main repo)
Branch: feat/wave-{THEME}-gap-{GAP_ID_SLUG}-docs (already created on your worktree)

## Your task
Read first:
- documents/04-quality/gaps/{GAP_ID}.md (full Acceptance Criteria + Proposed Fix)
- {ANY_REFERENCE_DOCS} (existing patterns to follow)

Deliverables (all docs, no code):
{DELIVERABLE_LIST — e.g. "8 runbook files under documents/05-guides/operations/runbooks/, one per alert"}

## Rules
- Files MUST live under: {ALLOWED_PATHS}. Do NOT touch anything else.
- Folder structure + frontmatter compliance per .claude/rules/docs-folder-structure.md.
  Check the folder's README for folder-specific conventions.
- Cross-link verification: every link to another doc MUST resolve (test with file existence).
- Match surrounding doc language (project may be bilingual — narrative in project language,
  technical identifiers in English).
- NO emojis except functional ones in tables/status indicators.

## Deliverable format
After commits, report back:
1. Branch name + commit SHAs
2. Files added/modified (path list)
3. PR URL (create with `gh pr create --base main --title "docs({SCOPE}): {GAP_ID} — ..."`)
4. Cross-link check: paste output of `grep -rn "\.md)" <your-files> | head -20` proving links resolve
5. Frontmatter check: `head -10` of each new file confirming required fields present
6. Note: do NOT flip {GAP_ID} Status to DONE in this PR — coordinator handles status flip per
   gap-done-discipline.md after wave merge

## Skip
- TDD section (no code = no unit tests; cross-link check IS the test)
- Migration version reservation (you don't touch DB)
- Pattern audit (no source code)
```

## Required placeholders

| Placeholder | Example | Notes |
|---|---|---|
| {LETTER} | A | Agent label per wave plan |
| {THEME} | obs | Short theme slug |
| {GAP_ID} | GAP-121 | Single task per agent |
| {GAP_TITLE} | Per-alert runbooks library | Match task file H1 |
| {DATE} | 2026-04-29 | Wave date |
| {WORKTREE_ROOT} | (auto-assigned by harness — do NOT cite absolute path) | Coordinator-assigned |
| {GAP_ID_SLUG} | 121-runbooks | Lowercase, dash |
| {ALLOWED_PATHS} | `documents/05-guides/operations/runbooks/` | List explicit paths |
| {ANY_REFERENCE_DOCS} | a sibling doc / template to mimic | Patterns to mimic |
| {DELIVERABLE_LIST} | "8 runbook .md files (one per alert)" | Concrete count |
| {SCOPE} | runbooks | Conventional-commit scope |

## Gotchas

- **Frontmatter drift:** waves/ + plans/ often require YAML frontmatter; other folders allow markdown-header style. Check parent folder's README before committing.
- **Cross-link rot:** if you reference a doc that doesn't exist yet (because it's another wave-pack agent's deliverable), use `(see {THEME} wave plan §Scope)` instead of broken link.
- **Folder README sync:** if you create a new subdir under `documents/`, update that folder's README per `docs-folder-structure.md` — coordinator catches but better in agent PR.
- **Language match:** match surrounding doc's language. New docs default to the project's primary doc language.
- **Banned phrases in commit body:** if your work is partial, say so honestly in PR body — but do NOT pre-write the task-DONE flip Log entry (coordinator owns that per `gap-done-discipline.md`).
- **Worktree absolute-path bug:** if coordinator's prompt cites absolute paths (`/home/.../documents/04-quality/...`), agent may bypass worktree cwd → Write lands in MAIN repo, commits land on WRONG branch. **Mitigation:** verify cwd before every Write/Edit: `pwd | grep -q "\.claude/worktrees/agent-" || { echo "NOT IN WORKTREE — abort"; exit 1; }`. Use RELATIVE paths in your own commands. Verify branch before commit: `git branch --show-current | grep -E "^(worktree-agent-|feat/wave-)"`.

## When NOT to use this template

- Task requires code change → use `feature-tdd-agent.md`
- Task is skeleton-only doc cluster (sections + TODO markers) → use `docs-only-skeleton-agent.md`
- Task is dead-code/cleanup → use `p3-cleanup-agent.md`
- Task requires test backfill → use `test-only-agent.md`
- Task mixes docs + code (e.g. ADR + helm chart) → split into 2 sub-tasks OR use `feature-tdd-agent.md` (treat docs as side artifact)

## PR body — MANDATORY sections

Every PR body PHẢI có §"Local verification (pre-push)" with literal command output paste + §"AC Coverage" table (mapping mỗi AC line → file/test/verification evidence). Worktree-isolated agents PHẢI paste `pwd | grep -F "/agent-"` confirming CWD inside assigned worktree.

Full spec + reject signals: see `feature-tdd-agent.md` §"PR body — MANDATORY sections" (canonical).

## Reference

- Methodology: [`../../SKILL.md`](../../SKILL.md) Step 3
- Spawn pattern: [`../../reference/agent-spawning-template.md`](../../reference/agent-spawning-template.md)
- Wave closure: [`../../reference/retrospective-checklist.md`](../../reference/retrospective-checklist.md)
- Worked example: Agent A of an observability cluster (1 task → 8 runbooks under `documents/05-guides/operations/runbooks/`)
