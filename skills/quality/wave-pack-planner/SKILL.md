---
name: wave-pack-planner
description: "Dùng khi user nói 'plan wave', 'cluster gaps', 'wave-pack', 'next wave', hoặc khi cần group ≥3 disjoint tasks/gaps thành 1 wave-pack chạy parallel agents. Output: wave plan markdown (foundation PR-ready) + file-overlap matrix + 3-5 agent prompts. Codifies cluster-then-spawn parallel-agent methodology (group disjoint work → spawn worktree-isolated agents → ~5x speedup vs serial PR queue)."
user-invocable: true
argument-hint: "[task-id ...] [--theme=<topic>]"
---

# /wave-pack-planner — Cluster-then-Spawn Methodology

Group các disjoint tasks (gaps) thành wave-pack rồi spawn 3-5 worktree-isolated agents parallel. Đóng nhiều tasks trong 1 session, không serial PR queue.

> **Portability note:** Đây là portable template. Adapt `{project}` placeholders. Nếu project dùng gap pipeline (`gap-architecture-v2.md` + `gap-done-discipline.md` + `documents/04-quality/gaps/gap-status.csv`) thì các bước gap-based áp dụng nguyên; nếu không, thay "gap" bằng "task/issue" của project và bỏ các bước CSV/gap-status.

## When to use

- Sau session-start báo "Wave-eligible: YES" (≥3 sub-tasks/gaps disjoint)
- Khi backlog có ≥5 tasks cùng theme (Observability, Admin, Frontend bundle, cleanup batch...)
- Trước khi "pick 1 task rồi serial" — luôn check cluster-eligible trước

## When NOT to use

- 1-2 tasks độc lập (overhead wave plan > save time)
- Tasks share migration version slot (V_n collide khi parallel)
- Tasks share single config file / single service file (rebase sequential)
- Foundation chưa ship (cần PR-0 trước)

## Process (5 steps, ~30-45 min planning + spawn)

### Step 1 — Identify candidate cluster (5 min)

Nếu project có gap backlog: đọc backlog/ROADMAP §"Active wave queue (clustered)". Cluster định sẵn → chọn cluster đầu queue. Nếu không có:
- Grep tasks cùng theme (vd `Grep pattern="Domain.*<theme>" path="documents/04-quality/gaps/"`)
- Output: 3-7 task IDs candidate

### Step 2 — File overlap analysis (10 min)

```bash
./scripts/analyze-overlap.sh GAP-117 GAP-118 GAP-119
```

Script parse "Files" / "Affects" / "Proposed Fix" sections → output matrix:

| File | Touched by | Conflict risk |
|------|-----------|:-------------:|
| ... | A only | None |
| `shared.yaml` | B + C | **SOFT** — different sections |
| `migration/V47__*.sql` | A + B | **HARD** — version collide → SERIALIZE |

**Decision rule:** ≥1 HARD conflict → either re-bucket tasks OR ship foundation PR first to defuse. Đọc `reference/file-overlap-algorithm.md` cho edge cases.

### Step 3 — Bucket assignment (5 min)

Mỗi disjoint subset → 1 agent. Choose agent template:
- Pure markdown/runbook task → `assets/agents/docs-only-agent.md`
- Skeleton-only doc cluster (sections + TODO markers, no content) → `assets/agents/docs-only-skeleton-agent.md`
- Backfill tests/fixtures → `assets/agents/test-only-agent.md`
- Dead code/unused/cleanup → `assets/agents/p3-cleanup-agent.md`
- Code change with TDD → `assets/agents/feature-tdd-agent.md`

Wave plan tự viết bằng `assets/agents/wave-coordinator-agent.md` runbook.

### Step 4 — Foundation PR (10 min)

Tạo wave plan markdown (vd `documents/03-planning/waves/wave-{date}-{theme}.md`). Dùng `reference/wave-plan-template.md`.

Nếu project có wave-plan validator (vd `scripts/check-wave-plan-completeness.sh` + canonical `_TEMPLATE.md`): wave plan PHẢI có đầy đủ numbered sections + frontmatter fields để pass validator — kể cả minimal stub cho next-session scope. Chạy validator local trước commit:

```bash
bash scripts/check-wave-plan-completeness.sh --paths documents/03-planning/waves/<file>.md
```

Ship qua PR (PR-first — wave plan ship qua PR trước khi spawn agents, không direct-push main).

Cập nhật backlog/ROADMAP: thêm cluster vào §"Active wave queue", mark IN_PROGRESS.

### Step 4.5 — Cross-layer check (api-contract first) — BẮT BUỘC

Per `.claude/rules/contract-first-for-cross-layer.md` — wave plan có FE+BE scope (cross-layer) PHẢI có Bucket 0 Foundation ship API contract (`documents/01-business/{domain}/api-contract.md` hoặc tương đương) TRƯỚC khi spawn FE bucket.

**Decision flow:**

1. Wave có cross-layer scope? (per rule §2 definition):
   - ≥1 bucket touch frontend AND ≥1 bucket touch backend → CROSS-LAYER
   - Single bucket touch CẢ FE+BE → CROSS-LAYER
   - FE bucket consume API mà BE bucket cùng wave tạo → CROSS-LAYER
   - FE bucket dùng mock/fixture cho endpoint chưa tồn tại → CROSS-LAYER (contract violation)
2. Nếu CROSS-LAYER:
   - Kiểm tra api-contract đã tồn tại + đủ endpoint? Có → skip foundation. Thiếu → add Bucket 0 Foundation vào §3 Scope FIRST
   - §4 State-Check Evidence: thêm row cho api-contract
   - FE bucket AC: "Endpoint consumption tuân thủ schema trong api-contract (Bucket 0 ship trước)"
   - BE bucket AC: "Controller signature + DTO match api-contract schema"
3. Spawn order: Bucket 0 merge FIRST → THEN FE+BE buckets parallel

**Anti-pattern signal:** wave plan có FE bucket + BE bucket nhưng KHÔNG có Bucket 0 Foundation row → STOP, add Bucket 0 hoặc justify exception qua commit trailer `CONTRACT_FIRST_OVERRIDE: <reason>`.

### Step 4.55 — Pre-walk simulation (optional, project-dependent)

Nếu project mandate pre-walk persona simulation cho user-facing flow (signup / auth / invite / payment / upload / email-driven), spawn 1 simulation agent return ≥5 failure modes TRƯỚC khi walk live, batch-fix high-confidence findings pre-walk. Add 1 row "Bucket 0 (Pre-walk)" vào §3 Scope khi áp dụng. Skip nếu project không có flow-walk discipline.

### Step 4.6 — Model tier calibration (per stake)

Classify wave stake → pick model tier cho parallel agents. Document choice trong wave plan §1 Brainstorm. Calibrate model tier to stake: agent thrash + skip-verification trên multi-file refactor đắt hơn token cost của model cao.

**Stake matrix:**

| Wave stake | Model tier | Rationale |
|---|---|---|
| **HIGH** — release-blocking, payment/lifecycle/security, multi-file refactor với strict compliance gates | **Opus full effort** | Lower-tier models crash mid-stream + skip verification trên multi-file refactor |
| **MEDIUM** — FE component ports theo established patterns, doc-heavy, single-file additions | **Opus medium effort** (experiment first) | Measure wall-clock + audit findings vs full Opus baseline; adopt default chỉ khi ship-clean parity |
| **LOW** — typo fix, doc sync, dep bump, cleanup | **Sonnet/Haiku OK** | Single-file low-complexity; no compliance-gate burden |

Per `.claude/rules/agent-model-opus-default.md` nếu project mandate Opus default cho non-trivial agents.

**Model-agnostic gates (mandatory regardless of tier):**
- Verification gate: PR body paste output test command xanh (vd `pnpm test --run <new-file>` + `mvn test -pl <module>`)
- AC Coverage table: PR body có table mapping mỗi AC line → file/test/verification
- Anti-pattern grep: PR body confirm grep checks (no `console.log`, no stray `TODO`, no scaffold strings)

**Anti-pattern signal:** wave plan §1 Brainstorm không document model tier choice → reviewer hỏi "stake assessment?" trước approve. Default fallback: Opus full effort (safer than under-spec).

### Step 4.7 — Pre-spawn stale-check

**BẮT BUỘC** (nếu project dùng gap pipeline) sau Step 4.6 và TRƯỚC Step 5 spawn agents. Mục tiêu: catch stale-OPEN gaps có code đã shipped wave trước → flip status inline → tránh waste agent spawn cost.

**Trigger:** mọi wave plan có gap-IDs trong §3 Scope.

**Quy trình (~5-10 min coordinator inline):**

1. **Batch state-check** mỗi gap-ID trong scope:
   ```bash
   for gap in <list GAP-IDs>; do
     csv_row=$(grep "^$gap," documents/04-quality/gaps/gap-status.csv)
     status=$(echo "$csv_row" | awk -F, '{print $4}')
     # grep code paths matching gap scope → if code exists matching all AC, flag potentially stale
   done
   ```

2. **Inline flip** stale gaps trước spawn:
   - Status OPEN/PARTIAL nhưng code shipped 100% → flip → DONE per `gap-done-discipline.md` + move to closed archive
   - Status OPEN/PARTIAL với code shipped một phần → reframe AC + update completion_pct
   - Status OPEN với code chưa shipped → leave; spawn agent will work normally

3. **Refine wave scope post-stale-check:** nếu N buckets flip stale → giảm spawn count tương ứng. Update §3 Scope table với note "Bucket X removed — GAP-NNN flipped DONE inline per pre-spawn stale-check".

4. **Document trong wave plan** §4 State-Check Evidence: list mỗi gap state-check finding (DONE inline / PARTIAL reframe / proceed normal).

**Anti-pattern:** spawn N agents → agent N+1 báo "code đã shipped, gap stale" → coordinator flip inline → waste agent N+1 spawn cost. Pre-spawn check eliminates this.

**Worked example (generic):** 4/5 buckets state-check tại spawn time phát hiện code đã shipped wave trước. Pre-spawn check sẽ catch 4 stale → only Bucket E (greenfield) cần spawn → save ~30 min × 4 agents wall-clock + agent spawn token cost.

Cross-reference: `audit-to-gap-pipeline.md` (fix-time state-check — this Step extends to wave-plan-time).

### Step 5 — Spawn agents (1 message, multiple Agent calls)

**BẮT BUỘC** single message với N Agent tool uses parallel. KHÔNG sequential spawn (mất parallel benefit). Spawn background per `.claude/rules/agent-background-spawn-default.md`.

```
Agent A: isolation=worktree, run_in_background=true, prompt từ docs-only-agent.md + GAP-XXX context
Agent B: isolation=worktree, run_in_background=true, prompt từ feature-tdd-agent.md + GAP-YYY context
Agent C: isolation=worktree, run_in_background=true, prompt từ docs-only-agent.md + GAP-ZZZ context
```

Sau khi agents xong → coordinator merge sequential (A → B → C), resolve SOFT conflicts manually, close wave per `reference/retrospective-checklist.md`.

### Step 5.5 — Pipeline next wave plan (during agent wait — eliminate dead-time)

**Khi nào:** ngay sau Step 5 (agents spawned background), trước khi merge starts.

**What:** Coordinator KHÔNG idle wait — propose Wave N+1 candidate (2-3 từ backlog/ROADMAP §Next Action) → user pick → draft Wave N+1 plan PR (state-check + brainstorm + scope + bucket allocation). Plan PR is docs-only, low conflict risk.

**Constraints:**
- Wave N+1 plan PR drafted but **NOT merged** until Wave N closure ships.
- Skip if coordinator already at high context (per `.claude/rules/context-budget-mandate.md`).
- Skip if Wave N has high failure risk (untested infra) — finish Wave N + lessons first.
- Skip if user wants to pause between waves — respect pacing.

Khi giảm số agent concurrent (rate-limit), lấp idle bằng inline disjoint bucket song song agent đang chạy — per `.claude/rules/agent-concurrency-budget-inline-hybrid.md`.

**Anti-pattern signal:** if coordinator says "agents working background, anything else?" instead of "while agents run, pick Wave N+1?" — pipeline missed.

## Skill contents

- `SKILL.md` — this file (entry point)
- `reference/cluster-pattern.md` — cluster-then-spawn methodology + decision tree
- `reference/file-overlap-algorithm.md` — overlap classification + edge cases
- `reference/agent-spawning-template.md` — how to write isolation:worktree prompts
- `reference/retrospective-checklist.md` — lessons-learned capture sau wave merge
- `reference/wave-plan-template.md` — markdown template cho wave plan
- `reference/background-loop-fleet.md` — documented `/loop` commands cho doc-sync, p3-sweeper, audit-cadence
- `assets/agents/` — 6 agent prompt templates (docs-only, docs-only-skeleton, test-only, p3-cleanup, feature-tdd, wave-coordinator)
- `scripts/analyze-overlap.sh` — file overlap detector
- `data/README.md` — schema doc cho append-only `wave-history.jsonl`

## Rules

- **Parallel spawn = 1 message, multiple Agent calls.** Sequential Agent spawns = anti-pattern (mất parallel benefit)
- **Foundation PR phải merge TRƯỚC khi spawn agents** — agents branch off main, không off feature branch
- Mỗi agent dùng `isolation: "worktree"` — không share working dir
- Branch naming: `feat/wave-{theme}-gap-{id-slug}` — coordinator dễ track
- Coordinator merge sequential (A → B → C) — KHÔNG batch merge (CI race)
- Sau merge, **bắt buộc** clean worktrees + remote branches (cleanup hygiene — per the parallel-agent strategy)
- Update `data/wave-history.jsonl` với wall-clock + lessons (data points cho future tuning)

## Gotchas

- **Worktree cross-contamination**: 2 agents sửa cùng 1 file (vd. `adr/README.md`) trong worktrees riêng → cuối khi merge git stash dance complex. Mitigation: file-overlap analysis (Step 2) phải catch — nếu HARD conflict, re-bucket
- **Worktree absolute-path bug**: nếu prompt cite absolute paths (`/home/.../scripts/foo.sh`), agent có thể `cd` ra khỏi worktree vào main checkout → Write/commits land SAI branch. Mitigation: prompt template (`assets/agents/*-agent.md`) bắt buộc dùng RELATIVE paths + agent verify `pwd | grep worktrees` trước Write/commit
- **Shared `values.yaml` / config section**: cùng file nhưng different sections → git auto-merge thường OK. Nhưng nếu 1 agent reformats whole file → conflict. Mitigation: agent prompt instruct "chỉ touch section X, đừng reformat file"
- **Stale wave plan trong `waves/`**: mtime fallback có thể chỉ vào wave đã ship. Mitigation: backlog/ROADMAP §"Active wave queue" là source of truth, không phải mtime
- **Sequential merge timing**: nếu Agent A's PR fail CI, đừng skip merge A để merge B trước — sẽ break dependency chain. Mitigation: wave plan ghi rõ merge order + rollback path
- **Agent prompt drift**: mỗi lần edit template → nhớ bump version + log entry. Otherwise next wave dùng stale template không match real workflow
- **Overlapping task closure timing**: nếu 2 agents close 2 tasks trong cùng PR description → backlog entry race. Mitigation: 1 PR = 1 task closure, coordinator wave-closure entry batch
- **Wall-clock metric noise**: wall-clock include user response delay (approve permissions, answer Qs). Đo agent-time riêng nếu cần benchmark thực

## Self-test

```bash
./scripts/analyze-overlap.sh GAP-121 GAP-143 GAP-144
# Expect output match wave plan "File overlap analysis" section
```

Nếu output diverge → script bug, fix trước khi dùng skill cho wave mới.

## Quality-target wave gate

Khi wave tag/goal chứa quality-target (score suffix như `-100`, hoặc goal định lượng "rubric ≥N"), plan §5 Verification Gates PHẢI khai báo metric + ngưỡng cụ thể + cam kết fix gaps surfaced trong wave TRƯỚC khi flip `status: complete` (defer cần user explicit approve). Tên wave là lời hứa — đặt `-100` thì closure gate phải tương xứng.

## Related

- Rule: `.claude/rules/contract-first-for-cross-layer.md` (Step 4.5 reference)
- Rule: `.claude/rules/agent-background-spawn-default.md` (background spawn default)
- Rule: `.claude/rules/agent-model-opus-default.md` (Step 4.6 model tier)
- Rule: `.claude/rules/agent-concurrency-budget-inline-hybrid.md` (Step 5.5 inline-hybrid)
- Rule: `.claude/rules/gap-done-discipline.md` (status-flip discipline at closure)
- Rule: `.claude/rules/gap-architecture-v2.md` (gap pipeline — if project uses it)
- Rule: `.claude/rules/post-wave-audit-mandate.md` (post-wave audit cadence)
- Rule: `.claude/rules/post-wave-cleanup.md` (worktree + branch cleanup)
- Skill: `.claude/skills/workflow/start-session` (wave-eligibility hint)
- Skill: `.claude/skills/core/{brainstorming-methodology,task-breakdown-guide,tdd-enforcement,two-stage-code-review}.md`

## Log

- **v1.0:** Skill created (portable kit version). Codifies cluster-then-spawn parallel-agent methodology: group ≥3 disjoint tasks → file-overlap analysis → foundation PR → spawn 3-5 worktree-isolated agents → sequential merge → retrospective. Early adoption demonstrated ~5x wall-clock speedup vs serial PR queue on a 3-task observability cluster — treat as demonstrated, not statistically proven; recalibrate heuristics from `data/wave-history.jsonl` as data accumulates.
