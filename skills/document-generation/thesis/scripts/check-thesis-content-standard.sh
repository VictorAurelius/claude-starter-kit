#!/usr/bin/env bash
# check-thesis-content-standard.sh — heuristic grep validator for thesis-content-standard.md §3 banned patterns
#
# Usage:
#   bash .claude/skills/document-generation/thesis/scripts/check-thesis-content-standard.sh \
#     --chapters documents/<thesis-dir>/chapters/
#
# Exit codes:
#   0 = all checks pass (or WARN-only mode)
#   1 = at least one HARD-FAIL pattern found

set -euo pipefail

CHAPTERS_DIR=""
MODE="warn"  # warn | strict

for arg in "$@"; do
  case "$arg" in
    --chapters=*) CHAPTERS_DIR="${arg#*=}" ;;
    --chapters) shift; CHAPTERS_DIR="${1:-}" ;;
    --strict) MODE="strict" ;;
    -h|--help)
      sed -n '2,15p' "$0" | sed 's/^# \?//'
      exit 0
      ;;
  esac
done

if [ -z "$CHAPTERS_DIR" ] || [ ! -d "$CHAPTERS_DIR" ]; then
  echo "ERROR: --chapters DIR required and must exist" >&2
  exit 2
fi

FAIL=0
warn() {
  echo "⚠️  $1" >&2
  [ "$MODE" = "strict" ] && FAIL=1
}

# C5 — project-internal references
echo "=== C5 Project-internal scrub ==="
if grep -rnEH "\bClaude\b|Wave [0-9]+|Phase [0-9]+ BETA|GAP-[0-9]+|\.claude/" "$CHAPTERS_DIR"/*.md 2>/dev/null; then
  warn "Project-internal references found — strip per thesis-content-standard.md §3 + §C5"
else
  echo "  ✓ no project-internal references"
fi

# C5 — Cursor / Copilot
if grep -rnEH "\bCursor\b|\bCopilot\b" "$CHAPTERS_DIR"/*.md 2>/dev/null; then
  warn "AI assistant references found — strip per §C5"
else
  echo "  ✓ no AI assistant references"
fi

# C6 — draft markers
echo "=== C6 Draft-marker scrub ==="
if grep -rnEH "## TL;DR|## TLDR|TODO|FIXME|\[placeholder\]|\[stub\]|XXX" "$CHAPTERS_DIR"/*.md 2>/dev/null; then
  warn "Draft markers found — strip per §C6"
else
  echo "  ✓ no draft markers"
fi

# C6 — date-prefix in heading
if grep -rnEH "^#.*Cập nhật lần cuối|^#.*v0\.[0-9]|^#.*beta" "$CHAPTERS_DIR"/*.md 2>/dev/null; then
  warn "Date/version markers in heading — strip per §C6"
else
  echo "  ✓ no date/version markers in headings"
fi

# C4 — banned word "đối thủ"
echo "=== C4 Academic tone ==="
if grep -rnH "đối thủ" "$CHAPTERS_DIR"/*.md 2>/dev/null; then
  warn "\"đối thủ\" found — replace with \"đối tượng tham khảo\" / \"công trình liên quan\" per §C4"
else
  echo "  ✓ no 'đối thủ' usage"
fi

# C4 — emoji
if grep -rnPH "[\x{1F300}-\x{1F9FF}]|✅|❌|⚠️|🎉|🚀|📅|🆘|🔴|🟢|🟡|🟠" "$CHAPTERS_DIR"/*.md 2>/dev/null; then
  warn "Emoji found — strip per §C4 No-icon principle"
else
  echo "  ✓ no emoji"
fi

# C4 — "bạn" / "chúng ta" in narrative
if grep -rnH "\bbạn\b\|\bchúng ta\b\|\bchúng tôi\b" "$CHAPTERS_DIR"/*.md 2>/dev/null; then
  warn "\"bạn\" / \"chúng ta\" / \"chúng tôi\" found — replace với \"em\" / \"tác giả\" per §C4 pronoun discipline"
else
  echo "  ✓ pronoun discipline OK"
fi

# S2 — chapter intro/summary sections
echo "=== §S2 Chapter intro/summary ban ==="
if grep -rnEH "^## [0-9]+\.0 |^## (Giới thiệu|Tóm tắt|Mục đích) chương" "$CHAPTERS_DIR"/*.md 2>/dev/null; then
  warn "Chapter intro/summary sections found — drop per §S2"
else
  echo "  ✓ no chapter intro/summary sections"
fi

# C9 — compliance "vi phạm" admission
echo "=== C9 Compliance + legal ==="
if grep -rnEH "vi phạm|compliance debt được chấp nhận" "$CHAPTERS_DIR"/*.md 2>/dev/null; then
  warn "Explicit 'vi phạm' admission found — rewrite mềm per §C9"
else
  echo "  ✓ no compliance violation admission"
fi

echo ""
if [ "$FAIL" -eq 1 ]; then
  echo "FAIL: at least one HARD pattern found" >&2
  exit 1
fi

echo "PASS (WARN-only mode — see warnings above)"
exit 0
