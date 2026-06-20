# Wave Plan Template

> Markdown template cho `documents/03-planning/waves/wave-{date}-{theme}.md` (adapt path tới project convention).
>
> Nếu project có wave-plan validator (vd `scripts/check-wave-plan-completeness.sh` đọc required sections từ canonical `_TEMPLATE.md`): canonical `_TEMPLATE.md` thắng khi drift. Reference này là mirror + thêm File-overlap + Lessons-learned scaffolding cho rich plans. **Stubs cũng phải có đủ numbered sections + frontmatter fields** (`title`/`status`/`created`/`waves`) ngay cả khi `## 3. Scope` để TBD — nếu không validator fail + revision-PR cost.

Copy block dưới, fill `{placeholders}`. Ship qua PR (PR-first) BEFORE spawning agents.

## Frontmatter (required)

```yaml
---
title: Wave {Theme} — {1-line summary}
status: active
created: {YYYY-MM-DD}
updated: {YYYY-MM-DD}
tasks: [GAP-XXX, GAP-YYY, GAP-ZZZ]
deferred_to_next_wave: [GAP-AAA]
deferred_separate_track: [GAP-BBB]
---
```

Fields:
- `status`: `active` (during wave) → `complete` (after merge) → `superseded` (if rewritten)
- `tasks`: list of task/gap IDs IN this wave
- `deferred_to_next_wave`: tasks in same theme but deferred for race-risk reasons
- `deferred_separate_track`: tasks in different scope (multi-PR migration etc.)

## Body template

```markdown
# Wave {Theme} — Cluster Pack {N}

**Wave date:** {YYYY-MM-DD} (kicked off {YYYY-MM-DD HH:MM})
**Cluster theme:** {1-2 sentence theme description}
**Strategy reference:** {link to earlier wave + rationale}
**Stake tier (per SKILL.md §Step 4.6):** {HIGH | MEDIUM | LOW} → model tier: {Opus full | Opus medium | Sonnet/Haiku}
**Cross-layer? (per SKILL.md §Step 4.5):** {YES → Bucket 0 Foundation required | NO → skip foundation}

## 1. Brainstorm

{Scope, risks, edge cases, dependencies. Document model-tier choice + rationale here.}

## 2. Task breakdown

{Decompose into buckets; one disjoint scope per agent.}

## 3. Scope (compact schema — one row per bucket)

Only one row per bucket. Task details live in their task files. Strategy:
- compact: one row per bucket, files glob-only
- cross-layer: if cross-layer=YES, Bucket 0 Foundation row FIRST per `contract-first-for-cross-layer.md`

| # | Bucket | Task(s) | Priority | Files (glob) | Spawn order |
|:-:|--------|--------|:--------:|--------------|:-----------:|
| 0 | **Foundation** | (contract + mock infra) | 🟠 P1 | `documents/01-business/{domain}/api-contract.md` + `{frontend}/src/test/msw/handlers/{domain}.ts` | **MERGE FIRST** |
| 1 | **A** | {GAP-XXX} | {priority} | {file glob} | parallel after Bucket 0 |
| 2 | **B** | {GAP-YYY} | {priority} | {file glob} | parallel after Bucket 0 |
| 3 | **C** | {GAP-ZZZ} | {priority} | {file glob} | parallel after Bucket 0 |

**Cross-layer foundation bucket pattern** (skip if cross-layer=NO):

### Bucket 0 — Foundation (Contract + Mock Infrastructure)

- **Files:** api-contract doc (CREATE/UPDATE)
  - List mọi endpoint mà FE+BE buckets trong wave consume
  - Mỗi endpoint: method + path + request/response schema + error codes
- **Mock infra (nếu wave dùng MSW handlers):** `{frontend}/src/test/msw/handlers/{domain}.ts` setup
- **Acceptance:** api-contract tồn tại + list đủ endpoints; mock handlers consumable
- **Spawn order:** MERGE FIRST trước FE+BE buckets

## 4. State-Check Evidence

{Per pre-spawn stale-check (SKILL.md §Step 4.7): list mỗi task state-check finding — DONE inline / PARTIAL reframe / proceed normal. Include api-contract existence row if cross-layer.}

## Deferred (next wave)

- **{GAP-AAA}** — {1-line title}. Deferred because {race-risk reason}.

## Deferred (separate track)

- **{GAP-BBB}** — {1-line title}. Tracked separately because {multi-service migration / multi-PR scope / etc.}.

## File overlap analysis

Run via `./scripts/analyze-overlap.sh {GAP-XXX} {GAP-YYY} {GAP-ZZZ}`.

| File | Touched by | Conflict risk |
|------|-----------|:-------------:|
| `{path/to/file-1}` | A only | None |
| `{path/to/file-2}` (NEW) | B only | None |
| `{path/to/shared-file}` | B + C | **SOFT** — {section/key disjoint, git auto-merges} |
| `{path/to/another-shared}` | A + C | **HARD** — {reason} → SERIALIZE A→C OR re-bucket |

Net: {summary of overlap state}.

## Agent workflow

1. Each agent gets `isolation: "worktree"` (separate git checkout)
2. Branches off main (after this foundation PR merges)
3. Commits + creates own PR — branch naming: `feat/wave-{theme}-{task-id-slug}`
4. Reports back PR number + scope summary
5. Coordinator merges sequentially: A → B → C
6. Conflict resolution: {who resolves which file at merge}
7. Wave closure backlog/ROADMAP entry after all {N} merge

## 5. Verification Gates (wave-level acceptance)

- [ ] {N} PRs merged (one per task) with green CI
- [ ] All {N} task files transitioned per `gap-done-discipline.md`
- [ ] Backlog/ROADMAP "Current Status Snapshot" gets wave-closure entry (counts updated, queue rotated)
- [ ] No conflicts left unresolved on main
- [ ] Worktrees + branches cleaned post-merge
- [ ] `data/wave-history.jsonl` entry appended
- [ ] Lessons-learned section filled below
- [ ] (If quality-target wave) metric re-scored ≥ threshold per SKILL.md §Quality-target wave gate

## Wall-clock target

- Foundation PR (this doc + backlog entry): ~10 min
- {N} parallel agents: ~{X-Y} min wall (each ~{P-Q} min agent-time, parallel)
- Sequential merge + conflict resolution: ~{Z} min
- Closure (backlog + cleanup + retrospective): ~10 min
- **Total wave: ~{TOTAL} min**

## Lessons-learned ({wave-name}, completed {YYYY-MM-DD})

(Filled AFTER wave merges — copy template from `reference/retrospective-checklist.md`)

## 8. Log

- {YYYY-MM-DD} — Wave plan created. Foundation PR will land this doc + backlog active-wave callout. After merge, {N} agents spawn from main.
- {YYYY-MM-DD} — {Status update entry per stage}.
- {YYYY-MM-DD} — Wave SHIPPED: {summary}, lessons-learned filled.
```

## Naming convention

Filename: `wave-{YYYY-MM-DD}-{theme-slug}.md`
- `theme-slug`: lowercase, kebab-case, ≤3 words (e.g. `observability`, `dr-backup`, `admin`)
- Date = wave KICKOFF date, not merge date

Branch for foundation PR: `wave/{date}-{theme}-plan`

## Related

- [SKILL.md](../SKILL.md) — entry point Step 4
- [cluster-pattern.md](cluster-pattern.md) — eligibility before drafting plan
- [file-overlap-algorithm.md](file-overlap-algorithm.md) — fills overlap matrix
- [agent-spawning-template.md](agent-spawning-template.md) — agent prompts post-merge
- [retrospective-checklist.md](retrospective-checklist.md) — fills Lessons-learned section
- Rule `.claude/rules/docs-folder-structure.md` — folder placement
- Rule `.claude/rules/contract-first-for-cross-layer.md` — Bucket 0 foundation
