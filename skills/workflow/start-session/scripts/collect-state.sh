#!/usr/bin/env bash
# collect-state.sh — gather session-start context for the /start-session skill.
#
# Designed to work in ANY Claude Code project: it always reports branch, open
# PRs, CI health, and recent commits. Project-specific sections (gap pipeline,
# wave history, cloud stack) are GRACEFULLY DEGRADED — each is probed for and
# shown only when the corresponding artifact / config exists. A project with
# none of those still gets a useful summary.
#
# Output: human-readable summary to stdout; errors to stderr.
#
# Usage:
#   ./collect-state.sh                 # full report
#   ./collect-state.sh --quick         # one-line summary
#   ./collect-state.sh --json          # structured JSON for hooks/agents
#   ./collect-state.sh --no-lock       # skip session-lock check
#   ./collect-state.sh --cloud         # opt-in: probe cloud stack (AWS) read-only
#   ./collect-state.sh --refresh-cloud # ignore cloud cache, fetch now
#
# Optional integration points (all OPTIONAL — script degrades if absent):
#   - Gap pipeline:  documents/04-quality/gaps/gap-status.csv
#                    (CSV cols incl. id, file, status, priority; see gap-architecture-v2 rule)
#   - Wave history:  .claude/skills/quality/wave-pack-planner/data/wave-history.jsonl
#   - Repo health:   scripts/repo-status.sh --json  (emits {level, ci, security, ...})
#   - Cloud stack:   `aws` CLI + credentials (only when --cloud passed)

set -u

MODE="full"
CLOUD_ENABLED=false
CLOUD_REFRESH=false
LOCK_ENABLED=true
for arg in "$@"; do
  case "$arg" in
    --quick)         MODE="quick" ;;
    --json)          MODE="json"  ;;
    --cloud)         CLOUD_ENABLED=true ;;
    --refresh-cloud) CLOUD_ENABLED=true; CLOUD_REFRESH=true ;;
    --no-lock)       LOCK_ENABLED=false ;;
  esac
done

TS="$(date -Iseconds)"
REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
cd "$REPO_ROOT" || exit 1

BRANCH="$(git branch --show-current 2>/dev/null || echo unknown)"
DEFAULT_BRANCH="$(git symbolic-ref --quiet --short refs/remotes/origin/HEAD 2>/dev/null | sed 's@^origin/@@')"
[ -z "$DEFAULT_BRANCH" ] && DEFAULT_BRANCH="main"

# Dirty check
DIRTY_FILES="$(git diff --name-only 2>/dev/null; git diff --cached --name-only 2>/dev/null)"
DIRTY_FILES="$(echo "$DIRTY_FILES" | sort -u | grep -v '^$' || true)"
if [ -z "$DIRTY_FILES" ]; then
  DIRTY_COUNT=0
else
  DIRTY_COUNT="$(printf '%s\n' "$DIRTY_FILES" | grep -c .)"
fi
if [ "$DIRTY_COUNT" = "0" ]; then
  BRANCH_STATE="clean"
else
  BRANCH_STATE="dirty ($DIRTY_COUNT file(s))"
fi

# Open PRs (gh required — gracefully skip if not authed)
OPEN_PRS="?"
TOP_PRS=""
TOP_PRS_LINES=""
if command -v gh >/dev/null 2>&1 && gh auth status >/dev/null 2>&1; then
  PR_JSON="$(gh pr list --state open --limit 5 \
    --json number,title,mergeStateStatus,statusCheckRollup 2>/dev/null || echo '[]')"
  OPEN_PRS="$(echo "$PR_JSON" | jq 'length' 2>/dev/null || echo '?')"
  if command -v jq >/dev/null 2>&1 && [ "$OPEN_PRS" != "?" ] && [ "$OPEN_PRS" != "0" ]; then
    while IFS=$'\t' read -r num title merge_state fail_count pend_count; do
      [ -z "$num" ] && continue
      if [ "${fail_count:-0}" -gt 0 ]; then
        ci_icon="${fail_count}x-fail"
      elif [ "${pend_count:-0}" -gt 0 ]; then
        ci_icon="${pend_count}-pending"
      else
        ci_icon="ok"
      fi
      title_short="$(echo "$title" | head -c 60)"
      TOP_PRS_LINES+="
  - #${num} [${merge_state:-?} ${ci_icon}] ${title_short}"
      TOP_PRS+="#${num} [${merge_state:-?} ${ci_icon}] ${title_short};"
    done < <(echo "$PR_JSON" | jq -r '.[] | [
      .number,
      .title,
      (.mergeStateStatus // "?"),
      ([.statusCheckRollup[]? | select((.conclusion // .state) == "FAILURE")] | length),
      ([.statusCheckRollup[]? | select((.conclusion // .state) == "PENDING" or (.conclusion // .state) == "IN_PROGRESS" or (.conclusion // .state) == "QUEUED")] | length)
    ] | @tsv' 2>/dev/null)
  fi
fi

# Repo health — OPTIONAL scripts/repo-status.sh; else derive light CI signal from gh.
RS_LEVEL="unknown"
RS_CI="?"
RS_CVE_HIGH="?"
RS_CVE_CRIT="?"
RS_STALE_BRANCHES="?"
RS_AUDIT_P0="?"
if [ -f scripts/repo-status.sh ]; then
  # cold-cache/race can emit >1 JSON doc on the stream — keep only the first.
  RS_JSON="$(bash scripts/repo-status.sh --json 2>/dev/null | jq -cs '.[0] // {}' 2>/dev/null || echo '{}')"
  if command -v jq >/dev/null 2>&1; then
    RS_LEVEL="$(echo "$RS_JSON" | jq -r '.level // "unknown"' 2>/dev/null || echo unknown)"
    RS_CI="$(echo "$RS_JSON" | jq -r '.ci.status // "unknown"' 2>/dev/null || echo unknown)"
    RS_CVE_HIGH="$(echo "$RS_JSON" | jq -r '(.security.high // 0) + (.security.code_scan_errors // 0)' 2>/dev/null || echo 0)"
    RS_CVE_CRIT="$(echo "$RS_JSON" | jq -r '.security.critical // 0' 2>/dev/null || echo 0)"
    RS_STALE_BRANCHES="$(echo "$RS_JSON" | jq -r '.branches.stale_branches // 0' 2>/dev/null || echo 0)"
    RS_AUDIT_P0="$(echo "$RS_JSON" | jq -r '.audit.p0 // 0' 2>/dev/null || echo 0)"
  fi
elif command -v gh >/dev/null 2>&1 && gh auth status >/dev/null 2>&1; then
  # Fallback: latest CI conclusion on default branch.
  RS_CI="$(gh run list --branch "$DEFAULT_BRANCH" --limit 1 \
    --json conclusion --jq '.[0].conclusion // "unknown"' 2>/dev/null || echo unknown)"
  RS_LEVEL="(no repo-status.sh — CI-only)"
fi

# Current wave — OPTIONAL wave-pack-planner history.
CURRENT_WAVE=""
WAVE_HISTORY=".claude/skills/quality/wave-pack-planner/data/wave-history.jsonl"
if [ -f "$WAVE_HISTORY" ] && command -v jq >/dev/null 2>&1; then
  CURRENT_WAVE="$(tail -1 "$WAVE_HISTORY" 2>/dev/null \
    | jq -r '"Wave \(.wave) — \(.outcome // .theme // "")[0:80]"' 2>/dev/null \
    | head -c 140 || echo '')"
fi

# Session locks (per-machine; git-ignored).
LOCK_DIR=".claude/session-locks"
ACTIVE_LOCKS=0
LOCK_LIST=""
if [ -d "$LOCK_DIR" ]; then
  ACTIVE_LOCKS="$(find "$LOCK_DIR" -name 'session-*.lock' -mmin -240 2>/dev/null | wc -l | tr -d ' ')"
  LOCK_LIST="$(find "$LOCK_DIR" -name 'session-*.lock' -mmin -240 2>/dev/null \
    -exec basename {} \; | tr '\n' ';')"
  # Auto-purge stale locks (>4h).
  find "$LOCK_DIR" -name 'session-*.lock' -mmin +240 -delete 2>/dev/null || true
fi

# Worktree husks under .claude/worktrees/ (agent-scratch; should be pruned post-wave).
WT_HUSK_COUNT=0
if [ -d ".claude/worktrees" ]; then
  WT_HUSK_COUNT="$(git worktree list 2>/dev/null \
    | awk '$1 ~ /\/\.claude\/worktrees\// {print}' \
    | wc -l | tr -d ' ')"
fi

# Blocker gaps — OPTIONAL gap-status.csv (canonical per gap-architecture-v2 rule).
# Skip entirely if the project has no gap pipeline.
GAP_CSV="documents/04-quality/gaps/gap-status.csv"
HAS_GAPS=false
BLOCKERS=""
if [ -f "$GAP_CSV" ]; then
  HAS_GAPS=true
  # Heuristic CSV layout: col1=id, col4=status, col5=priority. Adjust to project schema if different.
  BLOCKERS="$(awk -F, '/^GAP-/ && $5=="P0" && ($4=="OPEN" || $4=="PARTIAL" || $4=="IN_PROGRESS") {print $1}' "$GAP_CSV" \
    | head -6 | tr '\n' ';' || echo '')"
fi

# Recent commits — last 5 on default branch in past 3 days.
RECENT_MERGES=""
if command -v git >/dev/null 2>&1; then
  RECENT_MERGES="$(git log "$DEFAULT_BRANCH" --since='3 days ago' --oneline 2>/dev/null \
    | head -5 | tr '\n' '§' || echo '')"
fi

# MCP servers — prefer MCP if connected (per mcp-first-with-fallback rule).
MCP_TOTAL=0
MCP_CONNECTED=0
MCP_FAILED=""
if command -v claude >/dev/null 2>&1; then
  MCP_RAW="$(claude mcp list 2>/dev/null || true)"
  # grep -c always prints a count (0 on no match); the non-zero exit is harmless under set -u.
  MCP_TOTAL="$(printf '%s\n' "$MCP_RAW" | grep -cE '^[a-zA-Z0-9_-]+:.*-[[:space:]]*[✓✗]')" || true
  MCP_CONNECTED="$(printf '%s\n' "$MCP_RAW" | grep -cE '✓[[:space:]]*Connected')" || true
  MCP_FAILED="$(printf '%s\n' "$MCP_RAW" | grep -E '✗' \
    | sed -E 's/^([a-zA-Z0-9_-]+):.*$/\1/' | tr '\n' ',' | sed 's/,$//' || true)"
  MCP_TOTAL="${MCP_TOTAL:-0}"; MCP_CONNECTED="${MCP_CONNECTED:-0}"
fi

# ── Cloud stack snapshot (OPT-IN via --cloud) — AWS read-only, gracefully degraded ──
# Disabled by default so the script is useful in projects with no cloud stack.
# Uses only read-only describe/list calls. Cached 30 min (gitignored).
CLOUD_CACHE_DIR=".claude/session-cloud-cache"
CLOUD_CACHE_FILE="$CLOUD_CACHE_DIR/snapshot.json"
CLOUD_CACHE_TTL_SEC=1800
CLOUD_STATUS="skipped"   # skipped | no-cli | no-auth | cached | fresh | error
CLOUD_REGION_OUT="?"

cloud_collect() {
  if [ "$CLOUD_ENABLED" != "true" ]; then CLOUD_STATUS="skipped"; return; fi
  if ! command -v aws >/dev/null 2>&1; then CLOUD_STATUS="no-cli"; return; fi
  if ! command -v jq >/dev/null 2>&1; then CLOUD_STATUS="error"; return; fi

  local now cache_ts cache_age
  now="$(date +%s)"; cache_ts=0
  [ -f "$CLOUD_CACHE_FILE" ] && cache_ts="$(jq -r '.timestamp_epoch // 0' "$CLOUD_CACHE_FILE" 2>/dev/null || echo 0)"
  cache_age=$(( now - cache_ts ))
  if [ "$CLOUD_REFRESH" != "true" ] && [ "$cache_age" -lt "$CLOUD_CACHE_TTL_SEC" ] && [ -s "$CLOUD_CACHE_FILE" ]; then
    CLOUD_STATUS="cached"
    CLOUD_REGION_OUT="$(jq -r '.region // "?"' "$CLOUD_CACHE_FILE" 2>/dev/null || echo '?')"
    return
  fi

  # Auth check (uses the active AWS_PROFILE / default profile — read-only).
  local identity
  identity="$(timeout 5 aws sts get-caller-identity --output json 2>/dev/null || true)"
  if [ -z "$identity" ]; then CLOUD_STATUS="no-auth"; return; fi

  local region
  region="$(aws configure get region 2>/dev/null || echo "${AWS_REGION:-?}")"
  CLOUD_REGION_OUT="$region"

  local ec2 rds alarms
  ec2="$(timeout 8 aws ec2 describe-instances \
    --query 'Reservations[].Instances[].{id:InstanceId,state:State.Name,name:Tags[?Key==`Name`]|[0].Value}' \
    --output json 2>/dev/null || echo '[]')"
  rds="$(timeout 8 aws rds describe-db-instances \
    --query 'DBInstances[].{id:DBInstanceIdentifier,state:DBInstanceStatus}' \
    --output json 2>/dev/null || echo '[]')"
  alarms="$(timeout 8 aws cloudwatch describe-alarms --state-value ALARM \
    --query 'MetricAlarms[].AlarmName' --output json 2>/dev/null || echo '[]')"

  mkdir -p "$CLOUD_CACHE_DIR"
  jq -n \
    --arg ts "$(date -Iseconds)" --argjson tsep "$now" --arg region "$region" \
    --argjson identity "$identity" --argjson ec2 "$ec2" --argjson rds "$rds" --argjson alarms "$alarms" \
    '{timestamp:$ts, timestamp_epoch:$tsep, region:$region, identity:$identity, ec2:$ec2, rds:$rds, alarms_in_alarm:$alarms}' \
    > "$CLOUD_CACHE_FILE"
  CLOUD_STATUS="fresh"
}

cloud_render_lines() {
  case "$CLOUD_STATUS" in
    skipped)  echo "  - (skipped — pass --cloud to probe AWS read-only)"; return ;;
    no-cli)   echo "  - (aws CLI not installed — skipping)"; return ;;
    no-auth)  echo "  - (aws not authenticated — run 'aws sts get-caller-identity')"; return ;;
    error)    echo "  - (jq missing or unexpected error)"; return ;;
  esac
  [ ! -s "$CLOUD_CACHE_FILE" ] && { echo "  - (no cache data)"; return; }
  local account ec2_running ec2_stopped rds_summary alarm_count alarm_list cache_age_min cache_ts now
  account="$(jq -r '.identity.Account // "?"' "$CLOUD_CACHE_FILE")"
  ec2_running="$(jq '[.ec2[] | select(.state=="running")] | length' "$CLOUD_CACHE_FILE")"
  ec2_stopped="$(jq '[.ec2[] | select(.state=="stopped")] | length' "$CLOUD_CACHE_FILE")"
  rds_summary="$(jq -r '[.rds[] | "\(.id)=\(.state)"] | join(", ")' "$CLOUD_CACHE_FILE")"
  alarm_count="$(jq '.alarms_in_alarm | length' "$CLOUD_CACHE_FILE")"
  alarm_list="$(jq -r '.alarms_in_alarm | join(", ")' "$CLOUD_CACHE_FILE")"
  cache_ts="$(jq -r '.timestamp_epoch // 0' "$CLOUD_CACHE_FILE")"; now="$(date +%s)"
  cache_age_min=$(( (now - cache_ts) / 60 ))
  cat <<EOS
  - Account/Region: $account / $CLOUD_REGION_OUT
  - EC2:           $ec2_running running, $ec2_stopped stopped
  - RDS:           ${rds_summary:-<none>}
  - Alarms ALARM:  $alarm_count$([ "$alarm_count" -gt 0 ] && echo "  WARN  $alarm_list")
  - Cache:         ${CLOUD_STATUS} (age ${cache_age_min}m, TTL 30m)
EOS
}

cloud_collect

if [ "$MODE" = "json" ]; then
  cat <<EOF
{
  "timestamp": "$TS",
  "branch": "$BRANCH",
  "branch_state": "$BRANCH_STATE",
  "open_prs": "$OPEN_PRS",
  "top_prs": "$TOP_PRS",
  "repo_status_level": "$RS_LEVEL",
  "ci_default_branch": "$RS_CI",
  "cve_critical": "$RS_CVE_CRIT",
  "cve_high": "$RS_CVE_HIGH",
  "stale_branches": "$RS_STALE_BRANCHES",
  "audit_p0": "$RS_AUDIT_P0",
  "current_wave": "$CURRENT_WAVE",
  "has_gap_pipeline": $HAS_GAPS,
  "active_locks": $ACTIVE_LOCKS,
  "lock_files": "$LOCK_LIST",
  "blocker_gaps": "$BLOCKERS",
  "recent_commits": "$RECENT_MERGES",
  "mcp_total": $MCP_TOTAL,
  "mcp_connected": $MCP_CONNECTED,
  "mcp_failed": "$MCP_FAILED",
  "cloud_status": "$CLOUD_STATUS",
  "cloud_region": "$CLOUD_REGION_OUT"
}
EOF
  exit 0
fi

if [ "$MODE" = "quick" ]; then
  CLOUD_QUICK=""
  case "$CLOUD_STATUS" in
    cached|fresh)
      if [ -s "$CLOUD_CACHE_FILE" ] && command -v jq >/dev/null 2>&1; then
        ec2r="$(jq '[.ec2[] | select(.state=="running")] | length' "$CLOUD_CACHE_FILE" 2>/dev/null || echo ?)"
        alarms="$(jq '.alarms_in_alarm | length' "$CLOUD_CACHE_FILE" 2>/dev/null || echo ?)"
        CLOUD_QUICK=" · Cloud: ${ec2r} EC2 / ${alarms} alarms ($CLOUD_STATUS)"
      fi ;;
    skipped) CLOUD_QUICK="" ;;
    *) CLOUD_QUICK=" · Cloud: $CLOUD_STATUS" ;;
  esac
  echo "Mức: $RS_LEVEL · Nhánh: $BRANCH ($BRANCH_STATE) · PRs: $OPEN_PRS · CVE H/C: $RS_CVE_HIGH/$RS_CVE_CRIT · MCP: $MCP_CONNECTED/$MCP_TOTAL${CLOUD_QUICK} · Wave: ${CURRENT_WAVE:-n/a}"
  exit 0
fi

# Full output (bilingual — Vietnamese labels per kit convention; English technical terms kept).
cat <<EOF
# Trạng thái session @ $TS

Nhánh:             $BRANCH ($BRANCH_STATE)
Mức repo:          $RS_LEVEL
  - CI ($DEFAULT_BRANCH): $RS_CI
  - CVE:           $RS_CVE_CRIT critical, $RS_CVE_HIGH high
  - Branches cũ:   $RS_STALE_BRANCHES
  - Audit P0:      $RS_AUDIT_P0
PRs đang mở:       $OPEN_PRS${TOP_PRS_LINES}
MCP servers:       $MCP_CONNECTED/$MCP_TOTAL connected${MCP_FAILED:+ (FAILED: $MCP_FAILED — see note below)}
EOF

# Gap section — only when the project has a gap pipeline.
if [ "$HAS_GAPS" = "true" ]; then
  cat <<EOF
Gaps blocker:      ${BLOCKERS:-<none>}
EOF
fi

# Wave section — only when wave-pack history exists.
if [ -n "$CURRENT_WAVE" ]; then
  cat <<EOF
Wave hiện tại:     $CURRENT_WAVE
EOF
fi

cat <<EOF
Session locks:     $ACTIVE_LOCKS  [$LOCK_LIST]
Worktree husks:    $WT_HUSK_COUNT (.claude/worktrees/)$([ "$WT_HUSK_COUNT" -ge 3 ] && echo "  WARN  >=3 → prune merged worktrees (post-wave-cleanup rule)")

Cloud stack (read-only, opt-in via --cloud):
$(cloud_render_lines)

Commits gần đây (3 ngày, $DEFAULT_BRANCH):
$(echo "${RECENT_MERGES:-<none>}" | tr '§' '\n' | sed 's/^/  - /')

Ghi chú:
  - Branch / PRs / CI / commits luôn có. Gap / Wave / Cloud sections chỉ hiện khi artifact tồn tại.
  - Repo level qua scripts/repo-status.sh --json (nếu có) — else CI-only fallback.
  - Gap pipeline: documents/04-quality/gaps/gap-status.csv (per gap-architecture-v2 rule).
  - Wave history: .claude/skills/quality/wave-pack-planner/data/wave-history.jsonl.
  - Lock dir: $LOCK_DIR (auto-purge sau 4h stale).
  - MCP failed → reconnect (e.g. 'docker ps' + restart server + 'claude mcp list').
    Per mcp-first-with-fallback rule §3: MCP unavailable → fallback CLI; swap back when fixed.
  - Cloud snapshot cached 30m at $CLOUD_CACHE_DIR/ (gitignore it). Read-only describe/list calls only.
  - Wave-eligibility: trước khi pick next action, check action có >=3 sub-tasks disjoint không.
    Nếu YES → wave plan + parallel agents (wave-pack-planner skill) thay vì serial PRs.
EOF
