#!/usr/bin/env sh
set -eu

# =============================================================================
# Check Layers - Validation Tool
# =============================================================================
# Validates that layer dependencies follow architectural rules.
# For detailed documentation: .github/tools/validation/check-layers.md
# =============================================================================

SCAN_PATH="${1:-src}"

echo "[layers] Validating layer dependencies..."
echo "[layers] ============================================"

VIOLATIONS=0
RULES_CHECKED=0

# Check if domain imports infrastructure (violation)
check_violation() {
    FROM_LAYER="$1"
    TO_LAYER="$2"
    
    RULES_CHECKED=$((RULES_CHECKED + 1))
    
    echo ""
    echo "Checking: $FROM_LAYER -> $TO_LAYER (SHOULD NOT EXIST)"
    
    # Find violations
    FOUND=$(find "$SCAN_PATH" -path "*/$FROM_LAYER/*" -type f \
        \( -name "*.java" -o -name "*.kt" -o -name "*.ts" -o -name "*.py" -o -name "*.go" \) \
        -exec grep -l "$TO_LAYER" {} \; 2>/dev/null | wc -l | tr -d ' ')
    
    if [ "$FOUND" -gt 0 ]; then
        echo "  ⚠ $FOUND potential violations found:"
        find "$SCAN_PATH" -path "*/$FROM_LAYER/*" -type f \
            \( -name "*.java" -o -name "*.kt" -o -name "*.ts" -o -name "*.py" -o -name "*.go" \) \
            -exec grep -l "$TO_LAYER" {} \; 2>/dev/null | head -5 | sed 's/^/  - /'
        if [ "$FOUND" -gt 5 ]; then
            echo "  ... and $((FOUND - 5)) more"
        fi
        VIOLATIONS=$((VIOLATIONS + FOUND))
    else
        echo "  ✓ No violations"
    fi
}

# Common layer violation checks
# Domain should not import infrastructure
check_violation "domain" "infrastructure"
check_violation "domain" "controller"
check_violation "domain" "repository"

# Service should not import controller
check_violation "service" "controller"

# Entity should not import anything above
check_violation "entity" "service"
check_violation "entity" "controller"

# Model should be pure
check_violation "model" "controller"
check_violation "model" "repository"

echo ""
echo "[layers] ============================================"
echo "[layers] Summary:"
echo "  Rules checked: $RULES_CHECKED"
echo "  Violations: $VIOLATIONS"
echo ""

if [ $VIOLATIONS -eq 0 ]; then
    echo "[layers] All layer dependencies are valid ✓"
    exit 0
else
    echo "[layers] FAILED: $VIOLATIONS layer violations found"
    echo ""
    echo "[layers] Tip: Use stack-specific tools for more detailed analysis:"
    echo "  - Java: .github/tools/stack/java/archunit.sh"
    echo "  - TypeScript: .github/tools/stack/ts/depcruise.sh"
    exit 1
fi
