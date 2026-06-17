#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
# Beatrice — Universal bootstrap (detects OS, downloads and runs installer)
# This is the script invoked by the one-paste curl command.
# ─────────────────────────────────────────────────────────────────────────────

REPO_RAW_URL="${BEATRICE_RAW_URL:-https://raw.githubusercontent.com/lovegold120221-dot/turbo-dollop/main}"
REPO_BRANCH="${BEATRICE_BRANCH:-main}"

echo "▶ Beatrice — One-paste installer bootstrap"
echo "  Detecting OS..."

UNAME="$(uname -s 2>/dev/null || echo unknown)"

case "$UNAME" in
  Darwin)
    echo "  ✓ macOS detected"
    curl -fsSL "${REPO_RAW_URL}/install.sh" -o /tmp/beatrice-install.sh
    bash /tmp/beatrice-install.sh
    ;;
  Linux)
    if [ -f /etc/os-release ]; then
      . /etc/os-release
      echo "  ✓ Linux detected: $ID $VERSION_ID"
    else
      echo "  ✓ Linux detected (no /etc/os-release)"
    fi
    curl -fsSL "${REPO_RAW_URL}/install.sh" -o /tmp/beatrice-install.sh
    bash /tmp/beatrice-install.sh
    ;;
  *)
    echo "  ✗ Unsupported OS: $UNAME"
    echo "  For Windows, run this in PowerShell as Administrator:"
    echo "    irm https://raw.githubusercontent.com/lovegold120221-dot/turbo-dollop/main/install.ps1 | iex"
    exit 1
    ;;
esac
