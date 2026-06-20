# Session Handoff Template

Template cho `documents/03-planning/session-handoffs/YYYY-MM-DD-{wave-or-scope}.md` per `/end-session` Step 2.5.

Loaded khi skill Step 2.5 fires. SKILL.md body giữ tight; detailed template ở đây.

Sections tham chiếu gap/wave artifacts degrade gracefully — nếu project không dùng gap pipeline hoặc wave-pack methodology, dùng "(none)" / "(n/a)".

---

## Template (copy + fill)

```markdown
---
title: Session handoff — <Wave name OR scope summary>
date: YYYY-MM-DD
session_scope: ~Xh
context_at_end: NN%
session_type: <fresh / continuation / hotfix / planning>
---

# Session handoff — YYYY-MM-DD <Wave/scope>

## Scope shipped

| Wave / Bucket | PRs merged | Status |
|---|---|---|
| <scope-1> | #NNNN, #NNNN | ✅ done / ❌ aborted / 🟡 partial |
| ... | ... | ... |

## Gaps DONE (N)        <!-- skip section if no gap pipeline -->

- **GAP-NNN** Title — `<phase>/closed/`
- ...

## Gaps improved (PARTIAL bumps)

- **GAP-NNN** Title: X% → Y% + reason

## Gaps NEW filed

- **GAP-NNN** Title (Priority) — root cause / context
- ...

## Lessons captured (session-internal)

1. Pattern lesson — not rule-class (rule-class = file via `incident-to-rule-pipeline.md`)
2. ...

## Stack state

- Local stack: <N/N services healthy> via `<command>`
- ⚠️ Known bugs (manual workarounds documented):
  - **GAP-NNN / issue:** brief description + workaround command
- Remote/cloud env: <stopped/running per project mode>

## Pickup for next session

**Next scope ready (M buckets parallel — per active plan):**

| Bucket | Gap / item | Scope | Module |
|---|---|---|---|
| A | GAP-NNN | scope summary | module |
| ... | ... | ... | ... |

**Active blockers:** <list with gap/issue refs>
**Queued next:** <item list>

## Start next session

\`\`\`
/start-session
# Then fire next wave manually OR continue per active plan
\`\`\`

## References

- Plan: `documents/03-planning/plans/<active-plan>.md`
- Prior handoff: <link to previous session-handoff if continuation>
- Wave history: `.claude/skills/quality/wave-pack-planner/data/wave-history.jsonl` (if project uses wave-pack methodology)
```

---

## Section requirements

| Section | Mandatory? | Skip when |
|---|---|---|
| Scope shipped (PR/wave table) | YES | Session = read-only / planning-only |
| Gaps DONE / improved / NEW | YES | No gap pipeline → "(n/a)"; no gap-state changes → "(none)" |
| Lessons captured | YES | Use "(none)" if truly nothing learned |
| Stack state | YES | Always — even if "no change" |
| Pickup for next session | YES | Even if "fresh slate" — say so |
| Start next session commands | YES | Concrete commands save next-session time |

---

## Filename slug convention

- `YYYY-MM-DD-wave-{name}-{closure|continuation}.md` — wave-scoped session
- `YYYY-MM-DD-{topic}.md` — non-wave session (vd `hotfix-prod-incident`, `audit-suite`)
- `YYYY-MM-DD-eod-{N}-wave-shipped.md` — multi-wave end-of-day summary

---

## Examples

See `documents/03-planning/session-handoffs/` for prior sessions. Sample slugs:

- `YYYY-MM-DD-wave-feature-x-continuation.md` — multi-wave continuation
- `YYYY-MM-DD-wave-cleanup-closure.md` — wave closure
- `YYYY-MM-DD-eod-rollup.md` — end-of-day rollup
