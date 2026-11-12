#!/usr/bin/env sh
set -eu

# =============================================================================
# Count Files - Discovery Tool
# =============================================================================
# Counts source files per directory to understand codebase distribution.
# For detailed documentation: .sdlc-agents/tools/discovery/count-files.md
# =============================================================================

SCAN_PATH="${1:-src}"
EXTENSION="${2:-}"

if [ ! -d "$SCAN_PATH" ]; then
    echo "[count] Error: Directory '$SCAN_PATH' not found"
    exit 1
fi

echo "[count] Scanning: $SCAN_PATH"
[ -n "$EXTENSION" ] && echo "[count] Extension filter: *.$EXTENSION"
echo "[count] ============================================"
echo "[count] File distribution (sorted by count):"
echo ""

if [ -n "$EXTENSION" ]; then
    find "$SCAN_PATH" -name "*.$EXTENSION" -type f \
        ! -path "*/node_modules/*" \
        ! -path "*/.git/*" \
        ! -path "*/target/*" \
        ! -path "*/build/*" \
        2>/dev/null | \
        sed 's|/[^/]*$||' | sort | uniq -c | sort -rn
    
    TOTAL=$(find "$SCAN_PATH" -name "*.$EXTENSION" -type f \
        ! -path "*/node_modules/*" \
        ! -path "*/.git/*" \
        ! -path "*/target/*" \
        ! -path "*/build/*" \
        2>/dev/null | wc -l | tr -d ' ')
    
    echo ""
    echo "[count] Total: $TOTAL $EXTENSION files"
else
    # Auto-detect common source extensions
    find "$SCAN_PATH" -type f \
        \( -name "*.java" -o -name "*.kt" -o -name "*.scala" \
           -o -name "*.ts" -o -name "*.tsx" -o -name "*.js" -o -name "*.jsx" \
           -o -name "*.py" \
           -o -name "*.go" \
           -o -name "*.rs" \
           -o -name "*.cs" \
           -o -name "*.rb" \
           -o -name "*.php" \) \
        ! -path "*/node_modules/*" \
        ! -path "*/.git/*" \
        ! -path "*/target/*" \
        ! -path "*/build/*" \
        2>/dev/null | \
        sed 's|/[^/]*$||' | sort | uniq -c | sort -rn
    
    TOTAL=$(find "$SCAN_PATH" -type f \
        \( -name "*.java" -o -name "*.kt" -o -name "*.scala" \
           -o -name "*.ts" -o -name "*.tsx" -o -name "*.js" -o -name "*.jsx" \
           -o -name "*.py" \
           -o -name "*.go" \
           -o -name "*.rs" \
           -o -name "*.cs" \
           -o -name "*.rb" \
           -o -name "*.php" \) \
        ! -path "*/node_modules/*" \
        ! -path "*/.git/*" \
        ! -path "*/target/*" \
        ! -path "*/build/*" \
        2>/dev/null | wc -l | tr -d ' ')
    
    echo ""
    echo "[count] Total: $TOTAL source files"
fi

echo "[count] ============================================"

exit 0
