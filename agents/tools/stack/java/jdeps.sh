#!/usr/bin/env sh
set -eu

# =============================================================================
# Java JDeps - Stack Tool
# =============================================================================
# Analyzes JVM class dependencies using jdeps.
# For detailed documentation: .sdlc-agents/tools/stack/java/jdeps.md
# =============================================================================

TARGET="${1:-target/classes}"

echo "[jdeps] Analyzing dependencies..."
echo "[jdeps] ============================================"
echo "[jdeps] Target: $TARGET"
echo ""

# Check if jdeps is available
if ! command -v jdeps >/dev/null 2>&1; then
    echo "[jdeps] Error: jdeps not found. Install JDK to use this tool."
    exit 1
fi

# Check if target exists
if [ ! -d "$TARGET" ]; then
    echo "[jdeps] Error: Target directory '$TARGET' not found"
    echo "[jdeps] Run 'mvn compile' or 'gradle build' first"
    exit 1
fi

# Run jdeps with summary
echo "[jdeps] Package-level dependency summary:"
echo ""
jdeps -summary -recursive "$TARGET" 2>/dev/null || true

echo ""
echo "[jdeps] ============================================"
echo "[jdeps] For detailed output, run:"
echo "  jdeps -verbose:class $TARGET"
echo ""
echo "[jdeps] For dot graph output, run:"
echo "  jdeps -dotoutput deps $TARGET"

exit 0
