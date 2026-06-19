# Feature TDD Agent Template

**Use when:** Code change requires full methodology — brainstorm + task breakdown + test-first + implement + self-review (per your project's core engineering skills).

**Spawn config:** `isolation=worktree`, `subagent_type=general-purpose`
**Branch naming:** `feat/wave-{theme}-gap-{id-slug}`

## Prompt template

```
You are Agent {LETTER} of wave-pack {THEME}. Your scope: {GAP_ID} — {GAP_TITLE}.

## Wave context
Wave plan: documents/03-planning/waves/wave-{DATE}-{THEME}.md
Worktree root: {WORKTREE_ROOT} (you are isolated; do NOT cd to main repo)
Branch: feat/wave-{THEME}-gap-{GAP_ID_SLUG}

## Reserved resources (from wave plan — do NOT exceed)
- Migration version slot(s): {MIGRATION_VERSIONS — e.g. "V47, V48"}
- Task ID range: {GAP_RANGE — for follow-up tasks}
- Config key prefix: {CONFIG_PREFIX — e.g. "myapp.alerting.*"}
- Allowed paths: {ALLOWED_PATHS}

## Mandatory process — TDD methodology

### Phase 1 — Brainstorm (5-10 min)
- Read documents/04-quality/gaps/{GAP_ID}.md — Acceptance Criteria + Proposed Fix
- Read related docs: {RELATED_DOCS}
- Identify scope, edge cases, dependencies, blockers
- Output: 1-paragraph plan in PR body draft

### Phase 2 — Task breakdown (5-10 min)
- Decompose into 3-7 concrete tasks
- Use task-tracking tool to track in agent session
- Estimate effort per task

### Phase 3 — TDD (RED → GREEN → REFACTOR per task)
- Write failing test FIRST (RED)
- Minimal impl to pass (GREEN)
- Refactor with tests still green
- One commit per RED-GREEN cycle preferred

### Phase 4 — Implementation
- Follow `.claude/rules/design-patterns.md` (e.g. cross-service events through an event-emitter
  abstraction not direct broker calls; no status switch/if cascades — use state machine;
  no external API types in domain — use adapter; strategy for ≥2 implementations)
- Follow `.claude/rules/logs-format-standard.md` for any new log statement (no PII, structured)

### Phase 5 — Self-review (per `.claude/skills/core/two-stage-code-review.md`)
- Stage 1: re-read your diff
- Stage 2: pretend you're a hostile reviewer

## Migration awareness (if you add DB migrations)
- ONLY use slots {MIGRATION_VERSIONS} reserved in wave plan
- Naming: `V{N}__{snake_case_description}.sql`
- Test on a dev/test profile explicitly; do not rely on prod schema autogen

## Verification before commit
- Run unit tests for your module — green (e.g. `mvn test -pl {MODULE}` or `pnpm test --run`)
- Run integration tests if they exist
- Infra/manifest change? render + lint locally to inspect output before push
- IDE warnings check: unused imports, deprecated APIs

## Deliverable format
After commits, report back:
1. Branch name + commit SHAs (one per RED-GREEN cycle ideal)
2. Files added/modified (path list)
3. Test pyramid coverage: unit + integration (+ E2E if AC requires)
4. Design pattern compliance: 1-line per pattern applied
5. Migration slots consumed (if any)
6. PR URL (`gh pr create --base main --title "feat({SCOPE}): {GAP_ID} — ..."`)
7. CI green confirmation
8. Note: do NOT flip {GAP_ID} Status to DONE — coordinator handles per gap-done-discipline.md

## PR body — MANDATORY sections
Every PR body PHẢI có 2 sections sau (BLOCK merge nếu thiếu):

### §"Local verification (pre-push)"
Paste literal command output:
```
$ <typecheck cmd>          # e.g. pnpm exec tsc --noEmit OR mvn test -pl {MODULE}
<output showing PASS / 0 errors>

$ <test cmd>               # e.g. pnpm test --run <changed-files> OR mvn verify
Test Files  N passed (N)
Tests  M passed (M)

$ <build cmd>              # FE only, e.g. pnpm build
✓ Compiled successfully
```

### §"AC Coverage"
Table mapping mỗi AC line trong task → file/test/verification evidence:

| AC | Status | Evidence |
|----|:-:|---|
| <AC line từ task> | ✅ | `path/to/file.ts:42` + test name |
| <AC line khác> | ✅ | `path/to/test.spec.ts` |

Status values: ✅ DONE, 🟡 PARTIAL (with `// TODO(GAP-XXX)` + follow-up task link), ❌ NOT DONE (block merge).

**Anti-pattern signals (auto-reject by reviewer):**
- §"Local verification" missing OR shows skipped tests without plan-level deferral
- §"AC Coverage" table absent OR has "TBD" entries
- Mock-as-implementation without `// TODO(GAP-XXX)` + filed follow-up task (per `gap-done-discipline.md`)
- CWD verification missed (worktree-isolated agents): paste `pwd | grep -F "/agent-"` confirming you're inside the assigned worktree, NOT main repo
```

## Required placeholders

| Placeholder | Example | Notes |
|---|---|---|
| {GAP_ID} | GAP-144 | Single task |
| {GAP_TITLE} | Alerting production receivers | |
| {MIGRATION_VERSIONS} | V47, V48 | Pre-assigned, NEVER auto-pick |
| {GAP_RANGE} | GAP-260..GAP-265 | For follow-up tasks if needed |
| {CONFIG_PREFIX} | `myapp.alerting.*` | Avoid key collision with peer agents |
| {ALLOWED_PATHS} | `infrastructure/.../templates/`, `infrastructure/.../values.yaml` (Alerting section ONLY) | Be explicit |
| {RELATED_DOCS} | `documents/02-architecture/adr/ADR-022-alerting.md` | Context |
| {MODULE} | module path | For test commands |
| {SCOPE} | infra | Conventional-commit scope |

## Gotchas

- **Worktree drift:** if you `cd` to main repo by mistake, your changes will collide with peer agents. Use `pwd` checks.
- **Worktree absolute-path bug:** if coordinator's prompt cites absolute paths (`/home/.../scripts/foo.sh`), agent may bypass worktree cwd → Write lands in MAIN repo, commits land on WRONG branch. **Mitigation:** verify cwd before every Write/Edit: `pwd | grep -q "\.claude/worktrees/agent-" || { echo "NOT IN WORKTREE — abort"; exit 1; }`. Use RELATIVE paths in your own commands. Verify branch before commit: `git branch --show-current | grep -E "^(worktree-agent-|feat/wave-)"`.
- **Shared config files:** if {ALLOWED_PATHS} mentions `application.yml` or `values.yaml`, edit ONLY your assigned section — do NOT reformat whole file (causes SOFT merge conflicts; coordinator pays cost).
- **Migration version race:** auto-picking next free V_n ALWAYS collides with peer agents. Use only reserved slot.
- **Event-emitter bypass:** if you add a direct broker call (e.g. `rabbitTemplate.convertAndSend(...)`), cite the design-pattern exception in a code comment, otherwise audit blocks PR.
- **Test profile escape hatch:** security/CSRF/auth components often need a test-profile bypass or every integration test breaks.
- **Manifest tests:** render + lint infra manifests before commit; PR CI also runs but local catches faster.
- **Config-file validation:** if PR touches CI workflow YAML, validate locally first (`python3 -c "import yaml; yaml.safe_load(open('...'))"`) — colon-space in unquoted strings parses to mapping silently.

## When NOT to use this template

- Pure docs work → `docs-only-agent.md`
- Skeleton-only doc cluster → `docs-only-skeleton-agent.md`
- Pure test backfill → `test-only-agent.md`
- Cleanup/dead-code → `p3-cleanup-agent.md`
- Foundation PR (wave plan itself) → coordinator writes directly, not via agent
- Migration-only PR with no app code → still use this template; migration IS code

## Reference

- Methodology: [`../../SKILL.md`](../../SKILL.md) Step 3
- Spawn pattern: [`../../reference/agent-spawning-template.md`](../../reference/agent-spawning-template.md)
- Core skills: `.claude/skills/core/{brainstorming-methodology,task-breakdown-guide,tdd-enforcement,two-stage-code-review}.md`
- Worked example: Agent C of an observability cluster (alerting receivers in infra manifests + ExternalSecret + ADR; test asserts on rendered manifest)
