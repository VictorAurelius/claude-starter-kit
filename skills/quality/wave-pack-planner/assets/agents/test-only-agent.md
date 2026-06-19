# Test-Only Agent Template

**Use when:** Backfill missing tests, mock data, fixtures, snapshot tests after a feature shipped test-light. No production code change.

**Spawn config:** `isolation=worktree`, `subagent_type=general-purpose`
**Branch naming:** `feat/wave-{theme}-gap-{id-slug}-tests`

## Prompt template

```
You are Agent {LETTER} of wave-pack {THEME}. Your scope: {GAP_ID} — {GAP_TITLE}.

## Wave context
Wave plan: documents/03-planning/waves/wave-{DATE}-{THEME}.md
Worktree root: {WORKTREE_ROOT} (you are isolated; do NOT cd to main repo)
Branch: feat/wave-{THEME}-gap-{GAP_ID_SLUG}-tests (already created on your worktree)

## Your task
Read first:
- documents/04-quality/gaps/{GAP_ID}.md (Acceptance Criteria + coverage gap evidence)
- your project's test conventions doc
- {EXISTING_TEST_FILE} (mimic structure)

Backfill the following test layers per the test pyramid:

| Layer | Where | Target |
|-------|-------|--------|
| Unit | {UNIT_TEST_PATHS} | Cover {UNIT_TARGETS — e.g. "5 service methods, error paths"} |
| Integration | {INTEGRATION_TEST_PATHS} | {INTEGRATION_TARGETS — e.g. "CRUD round-trip"} |
| E2E | {E2E_TEST_PATHS} | {E2E_TARGETS — only if AC requires; usually skip} |

## Rules
- ZERO production code changes. If you discover a bug while writing tests:
  STOP, write a one-line note in PR body, escalate via {ESCALATION — usually "respond to coordinator, do not fix"}.
- Test paths only: {ALLOWED_PATHS}. Adding fixtures under test resources dir OK if path stated.
- Backend: prefer fast slice tests over full app-context boot when possible.
- Frontend: use the project's test runner; mock external modules; snapshot tests only for stable UI.
- Test hostnames: use reserved test domains (`.invalid` / `.test` / IP literal).
- Mock data: realistic, not "foo/bar"; reflect your project's locale/domain context where relevant.

## Coverage delta reporting (mandatory in PR body)

Before commits:
- Run baseline coverage for {TARGET_CLASSES}
- Capture line/branch coverage %

After commits:
- Re-run with new tests
- Report delta: `before X% → after Y% (+Δ)`

If delta <{MIN_DELTA}% → escalate to coordinator (test scope insufficient).

## Deliverable format
After commits, report back:
1. Branch name + commit SHAs
2. Test files added (path list, count)
3. Coverage delta table per class
4. PR URL (`gh pr create --base main --title "test({SCOPE}): backfill {GAP_ID}"`)
5. CI green confirmation (`gh pr checks <PR>` passing)
6. Note: do NOT flip {GAP_ID} Status to DONE — coordinator handles.
```

## Required placeholders

| Placeholder | Example | Notes |
|---|---|---|
| {GAP_ID} | GAP-217 | Single task |
| {GAP_TITLE} | Backfill RenewService tests | |
| {UNIT_TEST_PATHS} | `{module}/src/test/.../RenewServiceTest` | Concrete paths |
| {UNIT_TARGETS} | "5 happy paths + 3 error paths in `RenewService`" | Measurable |
| {INTEGRATION_TEST_PATHS} | `{module}/src/test/.../RenewIntegrationTest` | Or "N/A" |
| {EXISTING_TEST_FILE} | a sibling test to copy structure from | Pattern to copy |
| {MODULE} | module path | For test commands |
| {TARGET_CLASSES} | the FQNs under test | |
| {MIN_DELTA} | 20 | Coverage % delta threshold |
| {ALLOWED_PATHS} | `{module}/src/test/**` | Restrict scope |
| {ESCALATION} | "open follow-up GAP-XXX, do not fix" | What to do on bug discovery |

## Gotchas

- **Test selection patterns include integration tests** — a negation selector like `-Dtest='!Pattern'` may match integration tests too. Prefer an explicit list or a `*Test` pattern.
- **Full app-context tests are slow + brittle** — use slice/unit annotations when possible.
- **Mocking message brokers** — disable broker listener auto-startup in the test profile to avoid a live-broker dependency.
- **Serialization-typed columns (e.g. jsonb)** — entity mapping must declare the type-code or tests fail with a cryptic type error.
- **Snapshot tests churn** — only snapshot stable UI; avoid for components with dates/IDs.
- **Coverage tool config drift** — verify the coverage plugin is configured in the target module BEFORE running coverage; if missing, escalate (config change = production change, out of scope).
- **Bug discovery temptation** — easy to "just fix it while I'm here." Don't. File a follow-up task, let coordinator triage. Mixing test-add + bug-fix in 1 PR makes review hard.

## When NOT to use this template

- Task requires NEW feature code → use `feature-tdd-agent.md` (TDD writes tests + code together)
- Tests need test-infrastructure change (new fixture loader, new test starter) → escalate to feature-tdd
- Task is "fix flaky test" → that IS a code change to test infra, use `feature-tdd-agent.md`
- E2E-only scope without unit baseline → flag to coordinator first; usually wrong layer

## PR body — MANDATORY sections

Every PR body PHẢI có §"Local verification (pre-push)" + §"AC Coverage" table. Worktree-isolated agents PHẢI paste `pwd | grep -F "/agent-"` confirming CWD inside assigned worktree.

Full spec + reject signals: see `feature-tdd-agent.md` §"PR body — MANDATORY sections" (canonical).

## Reference

- Methodology: [`../../SKILL.md`](../../SKILL.md) Step 3
- Spawn pattern: [`../../reference/agent-spawning-template.md`](../../reference/agent-spawning-template.md)
- Wave closure: [`../../reference/retrospective-checklist.md`](../../reference/retrospective-checklist.md)
