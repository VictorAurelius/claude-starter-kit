---
name: repo-status
description: "Use when the user says 'status', 'repo status', 'tình trạng repo', 'health check', 'is the repo OK?', 'security', 'CVE', 'vuln', or when starting a conversation that needs a quick remote-repo assessment. Checks: CI, PRs/branches, audit gaps, GitHub Security (Dependabot + code-scanning + secret-scanning) → output level GREEN/YELLOW/ORANGE/RED/BLACK."
user-invocable: true
argument-hint: "[--quick]"
---

# /repo-status — Remote Repo Health Check

**Usage:** `/repo-status` or `/repo-status --quick`

Assess remote-repo health across **4 factors**, output a **status level**.

---

## Instructions

### Step 1: Gather data

If the project provides a helper script `scripts/repo-status.sh`, use it:

```bash
./scripts/repo-status.sh          # full report
./scripts/repo-status.sh --json   # JSON for parsing
./scripts/repo-status.sh --level  # level only (quick check)
```

If no such script exists, gather the 4 factors directly with `gh` / `git` (Steps below). **If `--quick`:** report the level in one line and stop.

### Step 2: Analyze the 4 factors

**Factor 1 — CI:** if CI is failing on the default branch, find root cause:
```bash
DEFAULT=$(git symbolic-ref --quiet --short refs/remotes/origin/HEAD | sed 's@^origin/@@'); DEFAULT=${DEFAULT:-main}
FAILED_RUN=$(gh run list --branch "$DEFAULT" --limit 5 \
  --json databaseId,workflowName,conclusion \
  --jq '.[] | select(.conclusion=="failure") | .databaseId' | head -1)
gh run view "$FAILED_RUN" --log-failed 2>/dev/null | tail -30
```

**Factor 2 — PRs/Branches:** check whether stale branches are WIP or abandoned:
```bash
git for-each-ref --sort=-committerdate \
  --format='%(refname:short) %(committerdate:relative)' refs/remotes/ \
  | grep -vE "main|master|HEAD"
```

**Factor 3 — Audit Gaps (optional — only if the project runs audits):** read the latest audit report under `documents/04-quality/audits/**` (if present) to understand gap context. Cross-check: do gaps already have a merged PR fix? (compare against `gh pr list --state merged` since the audit date). If the project has no audit pipeline, skip this factor.

**Factor 4 — GitHub Security:** 3 endpoints via `gh api`:
```bash
REPO=$(gh repo view --json nameWithOwner --jq .nameWithOwner)
gh api "repos/$REPO/dependabot/alerts?state=open"       # → 403 if disabled
gh api "repos/$REPO/code-scanning/alerts?state=open"    # → [] if no scanner
gh api "repos/$REPO/secret-scanning/alerts?state=open"  # → public/enterprise only
```

Severity mapping:
- Dependabot `critical` → BLACK; `high` → RED; `medium` → YELLOW
- Code scanning `error` → HIGH (counts as CVE); `warning` → MEDIUM; `note` → LOW
- Any secret-scanning alert → BLACK (credential exposure)
- Dependabot **disabled** (HTTP 403) → minimum ORANGE (silent-drift risk)

If Dependabot is disabled, **prompt the user to enable** it (repo Settings → Code security and analysis).

### Step 3: Output Report

```markdown
## Repo Status: [LEVEL] — [Label]

**Date:** [date]
**Branch:** [default] @ [commit hash]

### Factor 1: CI
- Status: ✅/❌ [details]
- Days since green: [N]
- Root cause (if fail): [description]

### Factor 2: PRs & Branches
- Open PRs: [N]
- Stale branches: [N]
- Details: [list]

### Factor 3: Audit Gaps   (omit if no audit pipeline)
- Latest audit: [date] — [score]
- Unfixed P0/P1/P2: [counts]

### Factor 4: GitHub Security
- Dependabot: enabled/disabled — [critical/high/medium/low counts]
- Code scanning: [N errors / N warnings / N notes] — top finding: [rule.id + file]
- Secret scanning: [N open alerts] (BLACK if >0)

### Recommended Actions
1. [Highest priority]
2. [Next]
```

### Step 4: Recommend actions

| Level | Action |
|-------|--------|
| **GREEN** | Continue normal development |
| **YELLOW** | Note minor items, fix when convenient |
| **ORANGE** | Fix before opening new PRs |
| **RED** | Fix now — top priority |
| **BLACK** | Stop all work, fix CI/security first |

---

## Level Definitions

Detail: `reference/level-definitions.md`

| Level | Label | Trigger |
|-------|-------|---------|
| **GREEN** | Healthy | CI green + 0 open PRs/stale branches + 0 P0/P1 gaps + **0 CVE + Dependabot enabled** |
| **YELLOW** | Minor Issues | CI green + minor gaps (P2/P3) OR 1-2 stale branches OR code-scan warnings |
| **ORANGE** | Needs Attention | CI green + P1 gaps, OR >2 stale items, OR **Dependabot disabled**, OR ≥3 warnings |
| **RED** | Degraded | CI red on default branch OR unfixed P0 gaps OR **≥1 HIGH CVE** |
| **BLACK** | Broken | CI red >7 days OR **CRITICAL CVE** OR **secret-scanning alert** |

---

## Rules

- Run the helper script first if it exists — don't infer status by hand.
- LUÔN giao tiếp tiếng Việt (per kit bilingual convention).
- If a check fails (GitHub API unavailable) → report it, don't guess.
- Cross-reference audit gaps with merged PRs — a gap may already be fixed but not re-audited.
- Recommended actions must be actionable (PR scope, estimate).

## Gotchas

- All checks need `gh` authenticated (`gh auth status`).
- `ci_days_red` is based on last-success date, not first-failure date.
- Audit gaps (Factor 3) parse via P0/P1/P2 markers — if a project's report format differs, adapt the parse.
- Stale branches = unmerged into default branch, may be valid WIP — check commit date before recommending delete.
- **Security factor (F4):** `gh api` security endpoints return 403 if Dependabot disabled. Use a jq type-check (`type=="array"` = enabled) to distinguish a disabled object from an empty-but-enabled array. Do NOT grep the response body — CVE descriptions may contain the word "disabled" and cause false positives.
- Secret-scanning endpoint is only available for public repos or GitHub Enterprise — returns 404 for private repos → treat as "disabled".
- Code-scanning alerts only populate when a CodeQL/Trivy/SARIF upload workflow runs. No scanner = empty `[]`, not disabled.

## Skill contents

- `SKILL.md` — this file
- `reference/level-definitions.md` — 5-level definitions + decision matrix + per-factor detail

## Related

- `.claude/skills/workflow/start-session/SKILL.md` — faster routine entry (consumes repo level)
- `.claude/rules/mcp-first-with-fallback.md` — prefer GitHub MCP over `gh` CLI when connected
- `.claude/rules/output-review-mandate.md` — health reports are reviewable outputs
