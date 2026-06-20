# P3 Cleanup Agent Template

**Use when:** Dead code removal, unused imports/variables, orphan files, low-priority TODO sweeps. Conservative scope — agent escalates anything non-trivial.

**Spawn config:** `isolation=worktree`, `subagent_type=general-purpose`
**Branch naming:** `chore/wave-{theme}-gap-{id-slug}-cleanup`

## Prompt template

```
You are Agent {LETTER} of wave-pack {THEME}. Your scope: {GAP_ID} — {GAP_TITLE}.

## Wave context
Wave plan: documents/03-planning/waves/wave-{DATE}-{THEME}.md
Worktree root: {WORKTREE_ROOT} (you are isolated; do NOT cd to main repo)
Branch: chore/wave-{THEME}-gap-{GAP_ID_SLUG}-cleanup

## Your task — CONSERVATIVE SWEEP ONLY

Read first:
- documents/04-quality/gaps/{GAP_ID}.md (cleanup target list)

Allowed cleanup operations:
1. Delete confirmed-orphan files (not imported anywhere — verify with grep)
2. Remove unused imports (IDE-detectable, no behavior change)
3. Remove unused private fields/vars (compiler-detectable)
4. Delete commented-out code blocks (>90 days old per git blame)
5. Resolve TODO comments tagged "P3-sweep" with explicit removal action

Detection commands you should run:
{DETECTION_COMMANDS — e.g.
  grep -rL "from.*calendar" a-frontend/src     # find unreferenced
  grep -rn "// TODO: P3" a-frontend/src
  <compile cmd> 2>&1 | grep "unused"
}

## Hard limits
- Max **5 small fixes per file** in single PR (avoid bundling unrelated)
- Max **20 files touched** total (cap blast radius)
- Allowed paths: {ALLOWED_PATHS}

## STOP and escalate (do NOT proceed) if you find:
- A file marked "unused" but referenced via dynamic import / reflection / DI scanning / config string
- Dead code that suggests a missing test (task should be test-only-agent, not cleanup)
- TODO that requires design decision (escalate to feature-tdd)
- Anything that touches: business logic, public API, migrations, config keys
- Any change that breaks compile / build
- Suspicion of "non-trivial" — when in doubt, leave it

Escalation format: STOP work, return to coordinator with:
- File path
- Line range
- Why you stopped (1 sentence)
- Recommendation: "needs feature-tdd agent" / "needs design discussion" / "skip this item"

## Verification (MANDATORY before commit)
- Compile / build — must pass
- Run module tests — must pass
- `git diff --stat` — verify file count + line count under hard limits

## Deliverable format
After commits, report back:
1. Branch name + commit SHAs
2. Files deleted/modified (path list with delta lines)
3. Detection command outputs (proof items were truly unused)
4. Build + test pass evidence
5. PR URL (`gh pr create --base main --title "chore({SCOPE}): {GAP_ID} cleanup — N files"`)
6. List of items SKIPPED with reasons (escalation log)
7. Note: do NOT flip {GAP_ID} Status — coordinator handles.
```

## Required placeholders

| Placeholder | Example | Notes |
|---|---|---|
| {GAP_ID} | GAP-246 | |
| {GAP_TITLE} | Orphan calendar component + 4 unused imports | |
| {DETECTION_COMMANDS} | `grep -rL "calendar" a-frontend/src/components` | Concrete grep/build cmds |
| {MODULE} | `a-frontend` | For build verify |
| {ALLOWED_PATHS} | `a-frontend/src/components/ui/`, `a-frontend/src/lib/` | Restrict scope |
| {SCOPE} | frontend | Conventional-commit scope |

## Gotchas

- **Dynamic imports invisible to grep** — `dynamic(() => import("..."))`, `React.lazy(...)`, DI component scanning, expression-language strings, YAML config refs. ALWAYS check before deleting "unused" component.
- **Reflection in tests** — a mock referencing a class by type; class may look unused but tests need it. Run tests before delete.
- **i18n keys in non-source files** — translation JSON, email templates reference vars; a "unused string" in source may be an i18n key.
- **Auto-configuration / classpath scanning** — class with no explicit registration but loaded via classpath scanning or an auto-config manifest is NOT dead.
- **5-fixes-per-file cap is real** — bundling 20 unrelated import-removals in 1 file makes review impossible. Prefer 4 PRs of 5 fixes than 1 PR of 20.
- **Compile-passes ≠ correct** — compile doesn't run tests. Always run tests too.
- **Orphan-component case study:** a UI primitive shipped in an earlier wave but never imported. Safe to delete after `grep -rL "from.*<name>"` confirms zero refs in src/. Small delete; 1 PR.

## When NOT to use this template

- Refactor that changes signatures → `feature-tdd-agent.md` (semantic change)
- Renaming things across codebase → `feature-tdd-agent.md` (high blast radius)
- "Cleanup" that touches >20 files → split into multiple tasks OR escalate as feature work
- Migration removal (drop column, drop table) → never P3, always feature-tdd
- Config key removal → never P3 (downstream services may consume), always feature-tdd

## PR body — MANDATORY sections

Every PR body PHẢI có §"Local verification (pre-push)" + §"AC Coverage" table. Worktree-isolated agents PHẢI paste `pwd | grep -F "/agent-"` confirming CWD inside assigned worktree.

Full spec + reject signals: see `feature-tdd-agent.md` §"PR body — MANDATORY sections" (canonical).

## Reference

- Methodology: [`../../SKILL.md`](../../SKILL.md) Step 3
- Spawn pattern: [`../../reference/agent-spawning-template.md`](../../reference/agent-spawning-template.md)
- Wave closure: [`../../reference/retrospective-checklist.md`](../../reference/retrospective-checklist.md)
