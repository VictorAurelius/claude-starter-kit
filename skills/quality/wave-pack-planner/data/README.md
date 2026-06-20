# `data/` — wave-pack runtime state

This folder holds the append-only log of executed waves. The runtime file (`wave-history.jsonl`) is created by the project as waves ship — it is **NOT** included in the kit (each project accumulates its own history). This README documents the schema only.

## `wave-history.jsonl`

Append-only **JSON-lines** file: one JSON object per line, no array wrapper, no pretty-print. One line per completed wave. It is the only persistent record of wave wall-clock + lessons used to recalibrate the cluster/overlap heuristics (per `reference/cluster-pattern.md` §Sample size disclaimer).

### Append

Append a new line at wave closure (per `reference/retrospective-checklist.md` §Where to log):

```bash
cat >> ./data/wave-history.jsonl <<'EOF'
{"wave":"observability-1","date":"2026-04-28","theme":"observability","tasks":["GAP-121","GAP-143","GAP-144"],"agents":3,"wall_clock_min":75,"estimated_serial_min":360,"speedup_ratio":4.8,"clarification_rounds":[0,0,1],"predicted_conflicts":{"soft":["values.yaml"],"hard":[]},"actual_conflicts":{"soft":[],"hard":[]},"lessons":["values.yaml SOFT auto-merged","Agent C 1 clarification round"]}
EOF
```

### Schema (per object / line)

| Field | Type | Required | Description |
|-------|------|:--------:|-------------|
| `wave` | string | ✅ | Wave identifier (e.g. `observability-1`) |
| `date` | string (ISO `YYYY-MM-DD`) | ✅ | Wave ship date |
| `theme` | string | ✅ | Cluster theme slug |
| `tasks` | string[] | ✅ | Task/gap IDs closed in this wave |
| `agents` | int | ✅ | Number of parallel agents spawned |
| `agent_roles` | string[] | ➖ | Template per agent (`docs-only` / `feature-tdd` / `test-only` / `p3-cleanup` / `docs-only-skeleton`) |
| `wall_clock_min` | int | ✅ | Actual wall-clock minutes (foundation PR → final merge) |
| `estimated_serial_min` | int | ➖ | Estimated minutes if done serially |
| `speedup_ratio` | float | ➖ | `estimated_serial_min / wall_clock_min` |
| `tokens_total` | int | ➖ | Sum of agent transcripts + coordinator tokens |
| `tokens_per_task` | int | ➖ | `tokens_total / len(tasks)` |
| `clarification_rounds` | int[] | ➖ | Per-agent clarification-round count (0 = self-contained prompt ✅) |
| `predicted_conflicts` | `{soft: string[], hard: string[]}` | ➖ | File-overlap matrix prediction at plan time |
| `actual_conflicts` | `{soft: string[], hard: string[]}` | ➖ | Conflicts that materialized at merge |
| `prs` | int[] | ➖ | Merged PR numbers |
| `soft_conflicts` / `hard_conflicts` | int | ➖ | Conflict counts (alternative to the structured form above) |
| `lessons` | string[] | ➖ | Lessons-learned bullets |
| `follow_up_tasks_filed` | string[] | ➖ | Follow-up task IDs filed for PARTIAL items |
| `novel_pattern_memory` | string \| null | ➖ | Pointer to a memory/lesson entry if a novel pattern emerged |

### Worked example object

```json
{
  "wave": "observability-1",
  "date": "2026-04-28",
  "theme": "observability",
  "tasks": ["GAP-121", "GAP-143", "GAP-144"],
  "agents": 3,
  "agent_roles": ["docs-only", "feature-tdd", "feature-tdd"],
  "wall_clock_min": 75,
  "estimated_serial_min": 360,
  "speedup_ratio": 4.8,
  "clarification_rounds": [0, 0, 1],
  "predicted_conflicts": {"soft": ["values.yaml"], "hard": []},
  "actual_conflicts": {"soft": [], "hard": []},
  "lessons": [
    "values.yaml SOFT predicted but auto-merged cleanly",
    "Agent C had 1 clarification round — feature-tdd template missing 'wait for green CI' criterion"
  ],
  "follow_up_tasks_filed": [],
  "novel_pattern_memory": null
}
```

### Query recipes

```bash
# All waves on a theme
jq 'select(.theme == "observability")' data/wave-history.jsonl

# Average speedup across all waves
jq -s 'map(.speedup_ratio // empty) | add / length' data/wave-history.jsonl

# Waves where a HARD conflict materialized (calibration miss)
jq 'select((.actual_conflicts.hard // []) | length > 0)' data/wave-history.jsonl
```

### Recalibration cadence

- After ~5 entries → revisit the cluster decision tree in `reference/cluster-pattern.md`
- After ~10 entries → consider promoting tuned heuristics into a `.claude/rules/` rule

### Notes

- Append-only — never rewrite past lines (history is the calibration record)
- If a field is absent on older lines, treat as unknown — queries use `// empty` / `// []` fallbacks
- Keep the field set stable; add new optional fields rather than renaming existing ones
