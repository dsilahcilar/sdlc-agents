#!/usr/bin/env sh
set -eu

# =============================================================================
# TypeScript Madge - Stack Tool
# =============================================================================
# Detects circular dependencies using Madge.
# For detailed documentation: .sdlc-agents/tools/stack/ts/madge.md
# =============================================================================

SCAN_PATH="${1:-src}"

echo "[madge] Checking circular dependencies..."
echo "[madge] ============================================"
echo "[madge] Path: $SCAN_PATH"
echo "[madge] Extensions: ts,tsx,js,jsx"
echo ""

FAILURES=0

# Check if npx is available
if ! command -v npx >/dev/null 2>&1; then
    echo "[madge] Error: npx not found. Install Node.js to use this tool."
    exit 1
fi

# Run madge
RESULT=$(npx --yes madge --circular --extensions ts,tsx,js,jsx "$SCAN_PATH" 2>/dev/null) || FAILURES=1

if [ -n "$RESULT" ]; then
    echo "Circular dependencies found!"
    echo ""
    echo "$RESULT"
    FAILURES=1
fi

echo ""
echo "[madge] ============================================"
if [ $FAILURES -eq 0 ]; then
    echo "[madge] No circular dependencies found ✓"
else
    echo "[madge] FAILED: Circular dependencies detected"
fi

exit $FAILURES
