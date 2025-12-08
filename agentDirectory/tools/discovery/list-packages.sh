#!/usr/bin/env sh
set -eu

# =============================================================================
# List Packages - Discovery Tool
# =============================================================================
# Lists all packages/directories in the codebase.
# For detailed documentation: .github/tools/discovery/list-packages.md
# =============================================================================

SCAN_PATH="${1:-src}"

if [ ! -d "$SCAN_PATH" ]; then
    echo "[packages] Error: Directory '$SCAN_PATH' not found"
    exit 1
fi

echo "[packages] Scanning: $SCAN_PATH"
echo "[packages] ============================================"

# Find all directories, excluding common non-source dirs
PACKAGES=$(find "$SCAN_PATH" -type d \
    ! -path "*/node_modules/*" \
    ! -path "*/.git/*" \
    ! -path "*/target/*" \
    ! -path "*/build/*" \
    ! -path "*/__pycache__/*" \
    ! -path "*/.gradle/*" \
    2>/dev/null | sort)

COUNT=$(echo "$PACKAGES" | grep -c '^' || echo "0")

echo "[packages] Found $COUNT packages/directories:"
echo ""
echo "$PACKAGES"
echo ""
echo "[packages] ============================================"

exit 0
