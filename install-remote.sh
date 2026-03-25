#!/bin/bash
# install-remote.sh — Install/upgrade starter-kit from remote git repo
#
# Usage:
#   # Install from GitHub
#   curl -sSL https://raw.githubusercontent.com/VictorAurelius/claude-starter-kit/main/install-remote.sh | bash -s /path/to/project
#
#   # Or clone and run
#   git clone https://github.com/VictorAurelius/claude-starter-kit.git /tmp/kit
#   bash /tmp/kit/install-remote.sh /path/to/project
#
#   # With specific version
#   bash install-remote.sh /path/to/project --version 1.1.1

set -uo pipefail

TARGET="${1:?Usage: $0 /path/to/project [--version X.Y.Z]}"
VERSION_PIN=""

for arg in "${@:2}"; do
    case "$arg" in
        --version) shift; VERSION_PIN="$1" ;;
    esac
done

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_URL="https://github.com/VictorAurelius/claude-starter-kit.git"

echo "═══════════════════════════════════════════════"
echo "  Starter Kit Remote Install"
echo "═══════════════════════════════════════════════"

# If running from curl pipe, we need to clone first
if [ ! -f "$SCRIPT_DIR/VERSION" ]; then
    echo "Cloning starter-kit from $REPO_URL..."
    TEMP_DIR=$(mktemp -d)
    if [ -n "$VERSION_PIN" ]; then
        git clone --depth 1 --branch "v$VERSION_PIN" "$REPO_URL" "$TEMP_DIR" 2>/dev/null || \
        git clone --depth 1 "$REPO_URL" "$TEMP_DIR"
    else
        git clone --depth 1 "$REPO_URL" "$TEMP_DIR"
    fi
    SCRIPT_DIR="$TEMP_DIR"
    trap "rm -rf $TEMP_DIR" EXIT
fi

KIT_VERSION=$(cat "$SCRIPT_DIR/VERSION" 2>/dev/null | tr -d '[:space:]')
echo "  Kit version: v$KIT_VERSION"
echo "  Target: $TARGET"

# Check if target has existing kit
INSTALLED_VERSION="none"
if [ -f "$TARGET/.claude/.starter-kit-version" ]; then
    INSTALLED_VERSION=$(cat "$TARGET/.claude/.starter-kit-version" | tr -d '[:space:]')
fi
echo "  Installed: v$INSTALLED_VERSION"
echo ""

if [ "$INSTALLED_VERSION" = "$KIT_VERSION" ]; then
    echo "Already on latest version (v$KIT_VERSION). Nothing to do."
    exit 0
fi

# Delegate to upgrade-project.sh
if [ -f "$SCRIPT_DIR/upgrade-project.sh" ]; then
    echo "Running upgrade..."
    bash "$SCRIPT_DIR/upgrade-project.sh" "$TARGET" --force
else
    echo "ERROR: upgrade-project.sh not found in kit"
    exit 1
fi

echo ""
echo "═══════════════════════════════════════════════"
echo "  Installed v$KIT_VERSION"
echo "═══════════════════════════════════════════════"
echo ""
echo "To update in the future:"
echo "  git clone $REPO_URL /tmp/kit"
echo "  bash /tmp/kit/install-remote.sh $TARGET"
