# Docs-Only Skeleton Agent Template

**Use when:** Phase 1 skeleton-only doc cluster (3-4 disjoint policy/spec/BRD docs, ~200-400 LOC each, no content fill — section structure + cross-refs + TODO markers only). Variant of `docs-only-agent.md` specialized for skeleton work where Phase 2 content (expert review, stakeholder sign-off, regulatory/spec specifics) is intentionally deferred.

**Spawn config:** `isolation=worktree`, `subagent_type=general-purpose`
**Branch naming:** `feat/wave-{theme}-gap-{id-slug}-{topic}-skeleton`
**Wall-clock budget:** ~5 min/agent (skeleton work scales with prompt clarity, not section count)

## When to use vs base `docs-only-agent.md`

| Situation | Template |
|-----------|---------|
| Skeleton-only Phase-1 cluster (sections + TODO markers, no content) | **THIS template** |
| Full content fill, runbooks, ADRs ready to ship | `docs-only-agent.md` (base) |
| Mixed skeleton + partial content | Use this template, drop the §"Phase 2 TODO marker" rule per file |
| Code change required | `feature-tdd-agent.md` |
| Pure test backfill | `test-only-agent.md` |
| Dead-code/cleanup | `p3-cleanup-agent.md` |

The split exists because skeleton work is **deterministic and bounded by section count**, not content depth. Agent wall-clock scales with prompt clarity, not section count — a 22-section skeleton can finish in the same window as a 9-section one.

## Prompt template

```
You are Agent {LETTER} of wave-pack {THEME}. Your scope: {GAP_ID} — {GAP_TITLE}.

## Wave context
Wave plan: documents/03-planning/waves/wave-{DATE}-{THEME}.md
Worktree root: {WORKTREE_ROOT} (you are isolated; do NOT cd to main repo)
Branch: feat/wave-{THEME}-gap-{GAP_ID_SLUG}-{TOPIC}-skeleton (already created on your worktree)

## Your task — Phase 1 skeleton ONLY
Read first:
- documents/04-quality/gaps/{GAP_ID}.md (full Acceptance Criteria + Proposed Fix)
- {ANY_REFERENCE_DOCS} (existing skeleton patterns to mimic — usually a sibling skeleton already shipped)

Deliverable: 1 new file at {ALLOWED_PATHS} containing:
- {SECTION_COUNT} sections per task §Scope (numbered, consistent with sibling skeletons)
- Section structure + headings + TODO markers, NOT content
- Frontmatter (match the folder's convention — copy from most recent neighbor file)
- Cross-references to sibling docs: {SISTER_SKELETONS}
- Basis citations (where applicable): {BASIS}
- Phase 2 content deferred (placeholder markers per section below)

## Phase 2 TODO marker pattern

For every section requiring expert / stakeholder / regulatory content, insert inline HTML-comment placeholder:

    ## 5. Refund Process

    <!-- Phase 2: Refund Process — deferred, see {UMBRELLA_GAP} -->

    (Placeholder — Phase 2 content blocked on review per {UMBRELLA_GAP}.)

Rationale: HTML-comment retrospective anchor lets future search/grep find all Phase-2-pending sections in one pass.

## Cross-link verification rules

- **Sibling skeletons that exist on main** (post-wave foundation merge): use RELATIVE paths
    See [Privacy Policy section 16](privacy-policy.md#16-retention).
- **Sibling skeletons NOT yet shipped** (deferred to follow-up wave): use placeholder text — do NOT write broken markdown links
    See Refund + Dispute Resolution Policy (planned — see GAP-XXX).
- **Rules / skills cross-refs**: relative path from your file location

Verify before commit: every `.md)` link resolves OR is intentionally a "(planned — see GAP-XXX)" placeholder.

## Frontmatter style

Use the style of sibling docs in the target folder (markdown-header style OR YAML — match neighbors). Example markdown-header style:

    # {Doc Title}

    **Status:** 🔵 SKELETON
    **Owner:** {Owner role(s)}
    **Reviewer:** {Reviewer role(s) — Phase 2}
    **Last-Updated:** {DATE}
    **Tracking:** {GAP_ID} → {UMBRELLA_GAP}
    **Basis:** {BASIS}
    **Phase 1 scope:** Skeleton (sections + TODO markers); Phase 2 content deferred per {UMBRELLA_GAP}

    ---

Check parent folder's README before committing — some folders use YAML frontmatter. When in doubt, copy frontmatter style from the most recent file in the same folder.

## Rules
- Files MUST live under: {ALLOWED_PATHS}. Do NOT touch anything else.
- **DO NOT touch README** — foundation PR owns directory map updates centrally. If you think README needs updating, leave a note in PR body for coordinator.
- Cross-link verification: every link to another doc MUST resolve OR be a "(planned — see GAP-XXX)" placeholder.
- Phase 2 TODO markers inline per section requiring deferred content (HTML-comment + placeholder paragraph pattern).
- Match folder's doc language; technical identifiers in English.
- NO emojis except functional ones in tables/status indicators (e.g. 🔵 SKELETON, 🟡 PARTIAL).
- **Status flip is NOT in your scope.** Do NOT modify {GAP_ID} Status field. Coordinator owns status flip per `gap-done-discipline.md` PARTIAL exit-ramp (Phase 2 deferred = stay 🟡 PARTIAL).

## Worktree verify (boilerplate — run before EVERY Write/Edit)

A skeleton agent's Write tool can land a file at the MAIN worktree path instead of the agent's isolated worktree when absolute paths leak into the prompt. Mitigation:

    # Before every Write/Edit
    pwd | grep -q "\.claude/worktrees/agent-" || { echo "NOT IN WORKTREE — abort"; exit 1; }
    git branch --show-current | grep -E "^(worktree-agent-|feat/wave-)" || { echo "WRONG BRANCH — abort"; exit 1; }

    # Use RELATIVE paths in commands — never absolute (/home/.../documents/...)
    ls documents/00-brd/  # relative — OK

Absolute paths in coordinator prompts cause Write to land in main repo. RELATIVE paths in your own commands prevent recurrence.

## Deliverable format

After commits, report back:
1. Branch name + commit SHA
2. Files added (path list — should be exactly 1 NEW file)
3. PR URL (`gh pr create --base main --title "docs({SCOPE}): {GAP_ID} {short-title} skeleton"`)
4. File LOC: `wc -l {your-file}` (target ~200-400 LOC)
5. Section count vs task §Scope: paste your `## N. <heading>` headings
6. Cross-link check: `grep -n "\.md)" {your-file}` proving links resolve OR are "(planned)" placeholders
7. Frontmatter check: `head -15 {your-file}` confirming required fields
8. Phase 2 TODO marker count: `grep -c "<!-- Phase 2:" {your-file}`
9. Note: do NOT flip {GAP_ID} Status — coordinator handles 🔵 OPEN → 🟡 PARTIAL per `gap-done-discipline.md`

## Skip (not in scope)

- TDD section (no code = no unit tests; cross-link check IS the test)
- Migration version reservation (no DB)
- Pattern audit (no source code)
- Status flip in task file (coordinator owns)
- README directory map update (foundation PR owns)
- Sibling-doc content (other agents own)
```

## Required placeholders

| Placeholder | Example | Notes |
|---|---|---|
| {LETTER} | A | Agent label per wave plan |
| {THEME} | policy-1 | Short theme slug |
| {GAP_ID} | GAP-186 | Single task per agent |
| {GAP_TITLE} | Data Retention Policy | Match task file H1 |
| {DATE} | 2026-04-29 | Wave date |
| {WORKTREE_ROOT} | (auto-assigned by harness) | Coordinator does NOT cite absolute path |
| {GAP_ID_SLUG} | 186-data-retention | Lowercase, dash |
| {TOPIC} | data-retention | Short suffix for branch name |
| {ALLOWED_PATHS} | `documents/00-brd/data-retention-policy.md` (NEW) | Single new file path; relative to repo root |
| {SECTION_COUNT} | 8 | Per task §Scope mandated section count |
| {SISTER_SKELETONS} | `terms-of-service.md`, `privacy-policy.md` | Existing siblings on main (relative paths) |
| {BASIS} | Relevant statute / spec / standard citations | For frontmatter |
| {ANY_REFERENCE_DOCS} | a sibling doc (frontmatter style) | Patterns to mimic |
| {SCOPE} | brd | Conventional-commit scope |
| {UMBRELLA_GAP} | GAP-154 | Parent task tracking Phase 2 |

## Gotchas

- **Worktree absolute-path bug:** coordinator prompts citing absolute paths make agents bypass worktree cwd → Write lands in MAIN repo, commits land on WRONG branch. **Mitigation:** verify cwd before every Write/Edit (boilerplate above). Use RELATIVE paths in your own commands. Verify branch before commit.
- **Frontmatter drift across folder conventions:** different folders use different frontmatter styles. Check the folder's README + most recent neighbor file before picking style.
- **Cross-link rot to sibling skeletons in same wave:** if Agent A's deliverable references Agent B's deliverable file (both not yet on main), use "(planned — see GAP-XXX)" placeholder. After foundation PR merges siblings, these become resolvable in follow-up tasks.
- **Phase 2 TODO markers vs banned phrases:** the banned-phrase scan in gap-closure discipline looks at task file Log entries when Status flips → DONE. Your skeleton file's `<!-- Phase 2: ... -->` markers do NOT trip this — they're in the policy doc, not the task Log. But coordinator MUST keep task Status at 🟡 PARTIAL until Phase 2 ships.
- **Section-count drift from task §Scope:** copy task §Scope's mandated section list into your headings 1:1. If you think a section should split or merge, leave a note in PR body — don't unilaterally restructure (breaks sibling cross-refs).
- **Wall-clock estimate vs reality:** skeleton work scales with prompt clarity, not section count. If you're spending >10 min on a skeleton, you're likely filling content (reframe and stop). Coordinator should re-spawn with tighter scope.
- **Banned phrases inside policy doc body** (different concern from task Log): your skeleton may legitimately use "deferred", "blocked on", "Phase 2" etc. inside placeholder paragraphs. These are policy-doc text, not Log entries — the banned-phrase scan applies only when coordinator updates task file Log on Status flip.
- **Foundation PR README dependency:** if the folder README directory map doesn't yet show your skeleton's row, the foundation PR is incomplete. Do NOT add the row yourself — flag in PR body for coordinator.

## When NOT to use this template

- **Full content fill:** if Phase 2 ships in same PR (review ready, citations finalized), use base `docs-only-agent.md` instead — the §"Phase 2 TODO marker" pattern would be misapplied
- **Mixed scope:** docs + code change → `feature-tdd-agent.md` (treat docs as side artifact)
- **Code-only change:** → `feature-tdd-agent.md`
- **Test backfill:** → `test-only-agent.md`
- **Cleanup/dead-code:** → `p3-cleanup-agent.md`
- **Single-doc work** (1 task, no cluster): probably overkill to use wave-pack pattern — see `SKILL.md` §"When NOT to use"

## PR body — MANDATORY sections

Every PR body PHẢI có §"Local verification (pre-push)" + §"AC Coverage" table. Worktree-isolated agents PHẢI paste `pwd | grep -F "/agent-"` confirming CWD inside assigned worktree.

Full spec + reject signals: see `feature-tdd-agent.md` §"PR body — MANDATORY sections" (canonical).

## Reference

- Methodology: [`../../SKILL.md`](../../SKILL.md) Step 3
- Base template: [`docs-only-agent.md`](docs-only-agent.md)
- Spawn pattern: [`../../reference/agent-spawning-template.md`](../../reference/agent-spawning-template.md)
- Wave closure: [`../../reference/retrospective-checklist.md`](../../reference/retrospective-checklist.md) §"4+-agent local-state hazards"
- Status discipline: `.claude/rules/gap-done-discipline.md` PARTIAL exit-ramp
- Deferred-content source category: `.claude/rules/business-logic-review.md`
