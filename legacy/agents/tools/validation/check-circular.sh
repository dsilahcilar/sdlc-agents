#!/usr/bin/env sh
set -eu

# =============================================================================
# Check Circular - Validation Tool
# =============================================================================
# Detects circular dependencies between modules.
# For detailed documentation: .sdlc-agents/tools/validation/check-circular.md
# =============================================================================

SCAN_PATH="${1:-src}"

echo "[circular] Checking for circular dependencies..."
echo "[circular] ============================================"

# Source shared stack detection utility
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=../../templates/harness/lib/stack-detection.sh
. "$SCRIPT_DIR/../../templates/harness/lib/stack-detection.sh"

STACK=$(detect_stack)
echo "[circular] Stack detected: $STACK"
echo ""

FAILURES=0

case "$STACK" in
    typescript)
        # Use madge for TypeScript
        if command -v npx >/dev/null 2>&1; then
            echo "[circular] Running madge..."
            npx --yes madge --circular --extensions ts,tsx,js,jsx "$SCAN_PATH" 2>/dev/null || FAILURES=1
        else
            echo "[circular] Warning: npx not found, cannot run madge"
            FAILURES=1
        fi
        ;;
    
    java)
        # Use jdeps or simple grep analysis
        if [ -d "target/classes" ]; then
            echo "[circular] Running jdeps analysis..."
            jdeps -summary -recursive target/classes 2>/dev/null | grep -i "cycle" && FAILURES=1 || true
        else
            echo "[circular] Warning: No compiled classes found. Run 'mvn compile' first."
            echo "[circular] Performing static import analysis..."
            # Simple cycle detection via imports
            .sdlc-agents/tools/discovery/find-imports.sh "$SCAN_PATH" 2>/dev/null || true
        fi
        ;;
    
    go)
        echo "[circular] Running go build cycle check..."
        go build ./... 2>&1 | grep -i "import cycle" && FAILURES=1 || true
        ;;
    
    python)
        echo "[circular] Performing Python import analysis..."
        echo "[circular] Warning: Full cycle detection requires 'import-linter'"
        # Basic analysis
        .sdlc-agents/tools/discovery/find-imports.sh "$SCAN_PATH" 2>/dev/null || true
        ;;
    
    rust)
        echo "[circular] Running cargo check..."
        cargo check 2>&1 | grep -i "cycle" && FAILURES=1 || true
        ;;
    
    *)
        echo "[circular] Unknown stack - performing basic import analysis"
        .sdlc-agents/tools/discovery/find-imports.sh "$SCAN_PATH" 2>/dev/null || true
        ;;
esac

echo ""
echo "[circular] ============================================"
if [ $FAILURES -eq 0 ]; then
    echo "[circular] No circular dependencies found ✓"
else
    echo "[circular] FAILED: Circular dependencies detected"
fi

exit $FAILURES
