---
paths:
  - "documents/04-quality/gaps/**"
  - "documents/04-quality/gaps/gap-status.csv"
---

# Gap Folder Organization — file location mirrors CSV phase (not status)

**Priority:** 🟠 MANDATORY — gap docs filesystem governance
**Version:** 2.0.0
**Created:** 2026-05-18
**Last-Reviewed:** 2026-05-18
**Reviewer-Approver:** @nguyenvankiet (starter-kit upstream maintainer)
**Supersedes:** v1.0.0 status-driven subdir taxonomy (one subdir per status)
**Applies to:** Every gap markdown file under `documents/04-quality/gaps/` AND every CSV row in `gap-status.csv` `filename` column. Scope = gap CRUD (creation, status flip = NO file move, phase reclassify = move, closure = move to `<phase>/closed/`). Out-of-scope: pre-existing orphan files in a legacy archive without a CSV row.

---

## 1. The Rule

> **A gap file's filesystem location MUST mirror its CSV row's `phase` column. Status changes (OPEN → PARTIAL → DONE) do NOT move files, except DONE which triggers move to `<phase>/closed/` one-way archive within the same phase folder.**

Design principle: **CSV is canonical for status** per `gap-architecture-v2.md` — filesystem should NOT duplicate that signal. **Phase is much more stable than status** (changes rarely on re-scope vs daily on status flips) — projecting phase onto filesystem is a reasonable browsability aid without daily churn.

Estimated file moves over a multi-month phase lifetime:
- v1.0.0 status-driven: ~10x more moves (every status flip + phase reclassify)
- **v2.0.0 phase-only + closed-archive: ~10x fewer moves** (only PARTIAL→DONE close events + rare phase re-scope)

---

## 2. The folder taxonomy + per-phase closed archive

```
documents/04-quality/gaps/
├── gap-status.csv             # canonical: status, phase, priority, completion_pct
├── ROADMAP.md
├── README.md
├── _TEMPLATE.md
├── phase-1/                   # active gaps with phase=phase-1 (any non-DONE status)
│   ├── README.md
│   ├── GAP-NNN-*.md           # OPEN / PARTIAL / IN_PROGRESS / PENDING / PLANNED / WONTFIX
│   └── closed/                # DONE archive (one-way; no move back)
│       └── GAP-NNN-*.md
├── phase-2/
│   ├── README.md
│   ├── GAP-NNN-*.md
│   └── closed/
├── phase-3/
│   ├── README.md
│   ├── GAP-NNN-*.md
│   └── closed/
├── unclassified/              # phase=n/a (meta gaps, foundation work, undetermined scope)
│   ├── README.md
│   ├── GAP-NNN-*.md
│   └── closed/
└── closed/                    # LEGACY archive — pre-CSV-migration orphan files (out-of-scope)
    └── README.md
```

> The exact phase names (`phase-1`, `phase-2`, …) are project-defined — match whatever `gap-status.csv` `phase` column uses. The rule only mandates that the folder mirror that column.

### 2.1 Subdir match conditions

| Subdir | Match condition | Source-of-truth column |
|---|---|---|
| `<phase>/` (root level) | `phase == <phase>` AND `status != DONE` | CSV `phase` |
| `<phase>/closed/` | `phase == <phase>` AND `status == DONE` | CSV `status` |
| `unclassified/` | `phase == n/a` AND `status != DONE` | CSV |
| `unclassified/closed/` | `phase == n/a` AND `status == DONE` | CSV |
| `closed/` (root, LEGACY) | Pre-existing orphan files (no CSV row) | N/A — grandfathered |

### 2.2 Why phase-only (not status-driven)

- **Phase changes rarely** — only on scope re-classification. Status changes daily.
- **CSV is already canonical for both** — projecting status onto filesystem duplicates the signal ("two caches for one source = textbook drift recipe"). Phase projection is a single-source browsability aid, not duplication.
- **Industry pattern** — issue trackers universally use storage-stable identifiers + status-as-metadata. Phase is closer to "project" or "milestone" in those tools.
- **ADR precedent** — ADRs use immutable filenames; status header changes, filename stable. v2.0.0 partially honors this (file moves only on DONE-archive + phase reclassify).
- **Wave batch closure ergonomics** — a milestone closing 5 DONE gaps = 5 small moves to `<phase>/closed/` (within same phase, single subdir target), not 5 moves across taxonomy boundaries.

### 2.3 Why per-phase `closed/` (not single root `closed/`)

- **Preserves phase scope semantic** — a DONE gap belongs to "what was done in phase-1" not generic archive
- **Volume cap satisfied** — a busy phase folder split into active + closed keeps both under any folder-volume budget (per `docs-folder-volume-budget.md`)
- **Retro queries** — `ls phase-1/closed/` answers "what shipped in phase 1?" cleanly
- **Root `closed/` reserved for LEGACY** — pre-CSV-migration orphan files stay there as historical archive; not active scope

---

## 3. Required actions per lifecycle event

### 3.1 New gap creation

1. File new gap → target subdir = `<phase>/` matching CSV `phase` value at creation
2. `git add documents/04-quality/gaps/<phase>/GAP-NNN-*.md`
3. Update `gap-status.csv` — set `filename` column to `<phase>/GAP-NNN-*.md`
4. CI verifies path matches `phase` column

### 3.2 Status flip OPEN → PARTIAL → PENDING → IN_PROGRESS → PLANNED → WONTFIX (any non-DONE transition)

**NO FILE MOVE.** Update CSV `status` + `completion_pct` columns only. File stays at `<phase>/GAP-NNN-*.md`.

### 3.3 Status flip → DONE (closure)

Same PR as gap closure per `gap-done-discipline.md` §2:

```bash
git mv documents/04-quality/gaps/phase-1/GAP-NNN-foo.md \
       documents/04-quality/gaps/phase-1/closed/GAP-NNN-foo.md
# Then update CSV row:
# Before: GAP-NNN,phase-1/GAP-NNN-foo.md,...,DONE,...
# After:  GAP-NNN,phase-1/closed/GAP-NNN-foo.md,...,DONE,...
```

One-way move. No reverse (no DONE → OPEN status revert; if regression, file NEW gap referencing closed one).

### 3.4 Phase reclassify (rare — scope re-prioritization)

When CSV `phase` column changes (e.g., `phase-2` → `phase-3`):

```bash
git mv documents/04-quality/gaps/phase-2/GAP-NNN-foo.md \
       documents/04-quality/gaps/phase-3/GAP-NNN-foo.md
# If DONE: phase-2/closed/ → phase-3/closed/
# Update CSV:
# phase column: phase-2 → phase-3
# filename column: matching new path
```

### 3.5 Status revert (rare edge case: DONE → OPEN regression)

NOT supported — per `gap-done-discipline.md` "🟢 DONE never re-opens — file a NEW gap if regression". So:
- DONE gap stays in `<phase>/closed/` permanently
- Regression filed as NEW `GAP-NNN+M` in `<phase>/` (root level, non-closed)
- New gap references closed sibling: `closed/GAP-NNN-original.md`

---

## 4. Anti-patterns

| ❌ Don't | ✅ Do |
|---|---|
| Move file on every status flip | Update CSV `status` column only; file stays put |
| Create `partial/`, `wontfix/`, status-named subdirs | Status is CSV metadata; no filesystem split by status (except DONE archive) |
| Move DONE gap back to active phase folder on reopen | DONE is one-way — file NEW gap for regression |
| Skip CSV `filename` sync after `git mv` | Same PR must update CSV column |
| Place new gap at root level | Must land in `<phase>/` matching CSV phase at creation |
| Reuse legacy `closed/` (root) for new DONE archives | New DONE → `<phase>/closed/`; root `closed/` is LEGACY only |
| Use symlinks across subdirs | Cross-link by `GAP-NNN` ID; resolver scripts walk subdirs |
| Bulk move orphans into per-phase closed/ without CSV rows | Out-of-scope; orphans grandfathered until separate cleanup gap |

---

## 5. Enforcement (per `rule-change-process.md` §6.5 Enforcement Parity)

### 5.1 CI script (active, WARN-mode initially)

`scripts/check-gap-folder-location.sh` validates:
- Each CSV row's `filename` matches expected path per §2.1 (phase + DONE-archive logic)
- File exists at CSV-specified path
- Orphan files in root `closed/` tolerated (LEGACY exemption)

Modes:
| Mode | CI behavior |
|---|---|
| `--strict` | Exit 1 on any mismatch (target after mass migration) |
| `--warn` | Print mismatches, exit 0 (initial rollout mode) |
| `--report-only` | Print full table + counts, exit 0 |

### 5.2 Reviewer-checklist (manual)

Pre-merge review for any gap-touching PR:
- New gap → file lives in `<phase-from-CSV>/GAP-NNN-*.md`?
- Status flip ≠ DONE → NO file move?
- Status flip = DONE → `git mv` to `<phase>/closed/`?
- Phase reclassify → `git mv` between phase folders?
- CSV `filename` column synced?

### 5.3 Override mechanism

For genuine exceptions (e.g., umbrella gap spanning 2 phases, custom archive scope):

```
git commit -m "...
GAP_FOLDER_OVERRIDE: <gap-id> — <reason>"
```

Trailer logged in quarterly retro. Pattern frequency >5% / quarter triggers meta-review.

### 5.4 Detector deferral

Per `incident-to-rule-pipeline.md` §3 premature-rule guard: pre-commit hook integration deferred. Reviewer-checklist + CI WARN sufficient for v2.0.0.

---

## 6. Self-test (worked example)

Run `bash scripts/check-gap-folder-location.sh --report-only` before a mass migration:

```
=== Gap folder location report ===
CSV rows total: N
Files at expected location: M
Files MISPLACED: K
  · should be in phase-1/        : ...
  · should be in phase-1/closed/ : ... (DONE currently in root)
  · should be in phase-2/        : ...
  · should be in unclassified/   : ... (non-DONE, phase=n/a)
Legacy orphans (root closed/, no CSV row): ... (rule §2.3 grandfathered)
```

Rule fires correctly — detects misplacement under v2.0.0 expected layout. Mass migration runs as a follow-up batch that moves every CSV-tracked file to its phase-mirroring path + updates the `filename` column + flips CI `--warn` → `--strict`.

---

## 7. Relationship to other rules

- **`gap-architecture-v2.md`** — CSV canonical for status+phase. v2.0.0 honors this fully: status NOT projected onto filesystem (eliminates duplication); phase projected (single-source browsability aid).
- **`gap-done-discipline.md`** §2 — DONE flip mechanics. v2.0.0 adds: same PR `git mv` to `<phase>/closed/`.
- **`docs-folder-volume-budget.md`** — active-folder volume cap. v2.0.0 satisfies cap per §2.3 (active split from closed).
- **`docs-subfolder-maturity.md`** — subdir threshold. Phase folders qualify by volume; per-phase `closed/` by sister-pattern (mirrors legacy `closed/` precedent).
- **`meta-csv-index-pattern.md`** — gap CSV is one of the meta indexes; `filename` column must stay synced.
- **`incident-to-rule-pipeline.md`** §3 — premature-rule guard; v1.0.0 → v2.0.0 revision shipped rule + CI + scaffolding revision same PR.
- **`audit-to-gap-pipeline.md`** — wave-plan state-check; this rule adds filesystem state-check at gap CRUD time.
- **`post-merge-sync-completeness.md`** — gap status flip → CSV row sync; v2.0.0 same invariant; file move also synced.
- **`output-review-mandate.md`** §3 — adds row "Gap folder organization" tracking this standard.
- **`rule-change-process.md`** §6.5 Enforcement Parity Mandate — rule + CI script + scaffolding all paired same PR.

---

## 8. Log

- **2026-05-18 (v2.0.0):** Extracted into starter-kit from a real 200+ PR project. Phase-only taxonomy (filesystem mirrors CSV `phase` column, never `status`, with a one-way per-phase `closed/` archive) replaces an earlier status-driven layout that forced a file move on every status flip — a documented anti-pattern that fought Git's natural model and duplicated the CSV's canonical status signal.
