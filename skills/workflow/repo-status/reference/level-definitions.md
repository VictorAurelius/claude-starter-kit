# Repo Status Levels — Detailed Definitions

## Overview

5 levels assessing remote-repo health across **4 factors**:
- **F1:** CI status on the default branch
- **F2:** Open PRs + stale remote branches
- **F3:** Audit gaps without a corresponding PR fix (optional — only if the project runs audits)
- **F4:** GitHub Security — Dependabot + code-scanning + secret-scanning alerts

---

## Level Definitions

### GREEN — Healthy

**Conditions (ALL must hold):**
- F1: CI green on the default branch (all workflows pass)
- F2: 0 open PRs + 0 stale branches
- F3: 0 unfixed P0/P1 gaps from the latest audit (or no audit pipeline)
- F4: 0 critical/HIGH CVE, 0 secret alerts, 0 code-scanning warnings, Dependabot **enabled**

**Action:** continue development per plan.

---

### YELLOW — Minor Issues

**Conditions (ANY):**
- F1: CI green + minor audit gaps (P2/P3 only)
- F2: 1-2 stale branches OR 1-2 active open PRs
- F3: only P2/P3 gaps, no P0/P1
- F4: 1-2 code-scanning warnings (MEDIUM) OR 1+ medium Dependabot alerts, Dependabot enabled

**Action:** fix when convenient.

---

### ORANGE — Needs Attention

**Conditions (ANY):**
- F1: CI green but P1 audit gaps unfixed
- F2: >2 stale branches OR >2 open PRs
- F3: P1 gaps without a corresponding PR fix
- F4: **Dependabot disabled** (silent-drift risk) OR ≥3 code-scanning warnings

**Action:** fix BEFORE opening new feature PRs. Prioritize cleanup. If Dependabot disabled — enable it (repo Settings → Code security and analysis).

---

### RED — Degraded

**Conditions (ANY):**
- F1: CI red on default branch (≤7 days)
- F3: unfixed P0 gaps
- F4: ≥1 HIGH CVE (Dependabot `high` OR code-scanning `error`)

**Action:** fix now. Security + CI fixes are top priority. No new PRs until fixed.

---

### BLACK — Broken

**Conditions (ANY):**
- F1: CI red on default branch >7 days
- F4: ≥1 **CRITICAL** CVE OR ≥1 **secret-scanning alert** (credential actively leaked)
- Default branch does not build

**Action:** stop all other work. Secret leak = rotate credentials NOW + audit access log. CRITICAL CVE = hotfix PR within 24h.

---

## Decision Matrix

```
CI green? ─── No ──→ How long? ─── >7 days ──→ BLACK
   │                     │
   │                     └── ≤7 days ──→ RED
   Yes
   │
   ├── Secret alert? ─── Yes ──→ BLACK
   ├── CRITICAL CVE? ─── Yes ──→ BLACK
   ├── HIGH CVE / code-scan error? ─── Yes ──→ RED
   ├── P0 gaps? ─── Yes ──→ RED
   ├── Dependabot disabled? ─── Yes ──→ ORANGE
   ├── ≥3 code-scan warnings? ─── Yes ──→ ORANGE
   ├── P1 gaps? ─── Yes ──→ ORANGE
   ├── >2 stale items? ─── Yes ──→ ORANGE
   ├── 1-2 stale / P2 gaps / any warnings? ─── Yes ──→ YELLOW
   └── All clean ──→ GREEN
```

---

## Factor Details

### F1: CI Status

**Checked by:** `gh run list --branch <default>` (or a project CI helper).

**Metrics:** workflows passing/failing (deduped by name, latest run only); days since last green; root cause (`gh run view --log-failed`).

**Gotchas:** check only the default branch, not feature branches; `in_progress` runs aren't failures — wait; one workflow passing while another fails = CI still failing.

### F2: PRs & Branches

**Checked by:** `gh pr list --state open` + `git branch -r --no-merged origin/<default>`.

**Metrics:** open PR count (active/draft/stale); remote branches unmerged into default; age of each (commit date).

**Gotchas:** a branch may be valid WIP — check commit date before recommending delete; squash-merge workflows hide "merged" branches from `--merged` — cross-check `gh pr list --state merged`; draft PRs count as open; `origin/HEAD` doesn't count.

### F3: Audit Gaps (optional)

**Checked by:** parse the latest audit report under `documents/04-quality/audits/**` (if the project runs audits).

**Metrics:** P0/P1/P2 items in "Remaining Gaps" / "Action Items"; audit freshness (>30 days = re-audit); cross-reference: gap already fixed by a merged PR?

**Gotchas:** an audit report is a point-in-time snapshot — gaps may be fixed but not re-audited; format-specific parse may need adapting per project; if gaps from an old audit (>30 days) already have fixing PRs → re-audit rather than trusting the stale report. Skip this factor entirely if the project has no audit pipeline.

### F4: GitHub Security

**Checked by:** `gh api` calls to 3 endpoints:
- `repos/{owner}/{repo}/dependabot/alerts?state=open`
- `repos/{owner}/{repo}/code-scanning/alerts?state=open`
- `repos/{owner}/{repo}/secret-scanning/alerts?state=open`

**Metrics:** Dependabot severity breakdown (`disabled` if HTTP 403); code-scanning severity (error/warning/note — errors = HIGH); secret-scanning count (any alert = BLACK).

**Disabled detection:** use a jq type-check (`type=="array"` = enabled; object with a `message` field = disabled). Do NOT grep the response body — CVE descriptions may contain "disabled" and cause false positives.

**Gotchas:** Dependabot must be enabled at repo Settings → Code security and analysis; disabled = silent drift; secret scanning requires public repo or Enterprise; code-scanning only populates with a CodeQL/Trivy/SARIF upload workflow; `gh auth token` needs `repo` + `security_events` scopes for private repos.

---

## Upgrade Path (how to get back to GREEN)

| From → To | Actions |
|-----------|---------|
| BLACK → RED | Rotate leaked credentials + fix CRITICAL CVE (dep bump) OR fix default-branch CI build |
| RED → ORANGE | Fix CI + fix P0 gaps + bump HIGH-severity deps |
| ORANGE → YELLOW | Fix P1 gaps + clean branches >2 + **enable Dependabot** if disabled |
| YELLOW → GREEN | Fix P2 gaps + clean all branches + resolve code-scanning warnings |
