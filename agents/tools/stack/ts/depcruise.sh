#!/usr/bin/env sh
set -eu

# =============================================================================
# TypeScript Dependency Cruiser - Stack Tool
# =============================================================================
# Runs Dependency Cruiser for TypeScript/JavaScript projects.
# For detailed documentation: .github/tools/stack/ts/depcruise.md
# =============================================================================

SCAN_PATH="${1:-src}"

echo "[depcruise] Running Dependency Cruiser..."
echo "[depcruise] ============================================"
echo "[depcruise] Path: $SCAN_PATH"
echo ""

FAILURES=0

# Check if config exists
if [ -f ".dependency-cruiser.js" ] || [ -f ".dependency-cruiser.cjs" ]; then
    CONFIG=$([ -f ".dependency-cruiser.js" ] && echo ".dependency-cruiser.js" || echo ".dependency-cruiser.cjs")
    echo "[depcruise] Config: $CONFIG"
    echo ""
    
    # Check if npx is available
    if command -v npx >/dev/null 2>&1; then
        npx depcruise "$SCAN_PATH" --config "$CONFIG" || FAILURES=1
    else
        echo "[depcruise] Error: npx not found. Install Node.js to use this tool."
        FAILURES=1
    fi
else
    echo "[depcruise] Warning: No .dependency-cruiser.js config found"
    echo ""
    echo "[depcruise] To set up Dependency Cruiser:"
    echo "  1. npm install --save-dev dependency-cruiser"
    echo "  2. npx depcruise --init"
    echo ""
    
    # Try to run without config (basic mode)
    if command -v npx >/dev/null 2>&1; then
        echo "[depcruise] Running basic analysis without config..."
        npx --yes depcruise "$SCAN_PATH" --output-type text 2>/dev/null || FAILURES=1
    else
        FAILURES=1
    fi
fi

echo ""
echo "[depcruise] ============================================"
if [ $FAILURES -eq 0 ]; then
    echo "[depcruise] Architecture rules validated ✓"
else
    echo "[depcruise] Validation FAILED or not configured"
fi

exit $FAILURES
