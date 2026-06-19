# Cluster Pattern — When and How to Group Tasks

Detail cho Step 1 + Step 3 trong [SKILL.md](../SKILL.md). Đọc khi cần quyết định "có nên cluster cái này không?".

## Definition

**Cluster** = 3-7 OPEN tasks (gaps) cùng theme/domain mà files chạm vào DISJOINT (hoặc chỉ overlap SOFT). Cluster là đơn vị plan của 1 wave-pack.

- <3 tasks: overhead wave plan > save time → ship 1-2 single PRs
- 3-5 tasks: sweet spot, 1 wave-pack với 3-5 parallel agents
- 6-7 tasks: max range, đặt agent cap 5 (max 5 concurrent agents per the parallel-agent strategy), buckets 2 tasks/agent OK
- >7 tasks: split thành 2 waves, không stuff cluster

## Decision tree

```
Có ≥3 OPEN tasks đang trên backlog/ROADMAP queue?
├─ NO  → /wave-pack-planner không phù hợp; pick 1 task + single-task PR workflow
└─ YES → tiếp tục
   │
   Các tasks có cùng theme (Observability / Admin / Business / cleanup / ...)?
   ├─ NO  → defer; chờ backlog tích đủ theme
   └─ YES → tiếp tục
      │
      File-overlap matrix: ≥1 HARD conflict (migration version, single service file)?
      ├─ YES → re-bucket (defer 1-2 tasks OR ship foundation defuse PR trước)
      └─ NO  → CLUSTER ELIGIBLE → tiếp tục Step 2
```

## Cluster theme examples (illustrative)

| Theme | Example tasks | Notes |
|-------|------|--------|
| Observability | dashboards + alert rules + runbooks | Files thường disjoint per concern |
| Admin features | 3 admin endpoints + screens | Watch shared layout/route files |
| Business correctness | rules + use-cases + acceptance criteria docs | Mostly docs — low conflict |
| Import/data flows | parser + mapper + fixtures | Watch shared model files |
| Cleanup batch | 5 dead-code / unused-import sweeps | OK nếu files truly disjoint; dùng `p3-cleanup-agent.md` |

**Note:** Backlog/ROADMAP queue là source of truth. Khi đọc skill này, refresh cluster list từ project backlog — các cluster có thể đã shift.

## Anti-cluster patterns

| Anti-pattern | Symptom | Mitigation |
|--------------|---------|-----------|
| **Forced cluster** | Tasks đẩy chung chỉ vì "cùng priority / cùng tuần" | Defer; chờ thực sự cùng theme |
| **Oversized** (>7 tasks) | Buckets >2 tasks/agent, agent prompts dài >300 LOC | Split 2 waves; cap 5 agents/wave |
| **Shared-state cluster** | 2+ tasks muốn migration version V_n cùng lúc | Pre-assign V_n / V_n+1 / V_n+2 trong wave plan, OR defer |
| **Single-config-file cluster** | 3 tasks cùng đụng một config file (`application.yml` / `values.yaml`) | Defer 2; lead-owns shared file (per the parallel-agent strategy) |
| **Hidden chain** | Task-A blocks Task-B blocks Task-C | Không cluster; serial OK với chain explicit |
| **Cross-service migration** | Task touches all services (vd logging) | Separate track; multi-PR per service, không 1 wave |
| **Audit-driven cleanup batch** | 5+ "remove dead code" tasks | OK to cluster nếu files truly disjoint; dùng `p3-cleanup-agent.md` template |

## Cluster eligibility checklist

Trước khi commit cluster, verify TẤT CẢ:

- [ ] ≥3 tasks cùng theme, backlog/ROADMAP queue confirms
- [ ] File-overlap matrix run, ≤1 SOFT conflict, 0 HARD
- [ ] Foundation PR (interfaces/shared lib/api-contract) đã merge — hoặc không cần
- [ ] Agent buckets defined: mỗi agent có disjoint scope (≤2 tasks/agent)
- [ ] Migration version slots pre-assigned nếu ≥2 tasks add migrations
- [ ] Wave plan ready để PR (PR-first before spawning agents)
- [ ] Wall-clock target documented (60-120 min cho 3-5 agents)

Nếu BẤT KỲ unchecked → pause cluster, fix task, re-evaluate.

## Sample size disclaimer (HONEST)

Methodology này có ít data points ban đầu — early adoption demonstrated ~5x speedup trên một observability cluster (3 tasks, ~75 min wall-clock vs ~6h serial estimate).

**Treat as "demonstrated, not proven":**
- 5x speedup là measure-on-few-runs, chưa qua repeat trials đủ lớn
- Cluster theme heuristic dựa trên few successful clusters — chưa biết "shared-file SOFT conflict auto-merges" đúng đến đâu cross theme
- Agent prompt drift, worktree contamination, wall-clock noise — đều là known unknowns

**Framework should evolve based on `data/wave-history.jsonl`:**
- Mỗi wave append entry với `{wave, date, tasks, agents, wall_clock_min, lessons[]}`
- Sau ~5 wave entries → recalibrate decision tree (vd "themes A/B work well, theme C needs different bucketing")
- Sau ~10 wave entries → consider promoting tuned heuristics vào rule (`.claude/rules/`)

Cross-link: [retrospective-checklist.md](retrospective-checklist.md) capture lessons; [agent-spawning-template.md](agent-spawning-template.md) calibrate prompt quality; [file-overlap-algorithm.md](file-overlap-algorithm.md) tune classification.

## Related

- [SKILL.md](../SKILL.md) — entry point
- [file-overlap-algorithm.md](file-overlap-algorithm.md) — Step 2 mechanics
- [wave-plan-template.md](wave-plan-template.md) — Step 4 template
- [retrospective-checklist.md](retrospective-checklist.md) — within-cluster lessons + data logging
