#!/usr/bin/env sh
set -eu

# =============================================================================
# Find Imports - Discovery Tool
# =============================================================================
# Finds import statements to understand module dependencies.
# For detailed documentation: .github/tools/discovery/find-imports.md
# =============================================================================

SCAN_PATH="${1:-src}"
PATTERN="${2:-}"

if [ ! -d "$SCAN_PATH" ]; then
    echo "[imports] Error: Directory '$SCAN_PATH' not found"
    exit 1
fi

echo "[imports] Scanning: $SCAN_PATH"
[ -n "$PATTERN" ] && echo "[imports] Filter pattern: $PATTERN"
echo "[imports] ============================================"

# Detect stack and find imports accordingly
if [ -f "pom.xml" ] || [ -f "build.gradle" ] || [ -f "build.gradle.kts" ]; then
    # Java/Kotlin
    if [ -n "$PATTERN" ]; then
        grep -rn "^import $PATTERN" "$SCAN_PATH" --include="*.java" --include="*.kt" 2>/dev/null || true
    else
        grep -rn "^import " "$SCAN_PATH" --include="*.java" --include="*.kt" 2>/dev/null | head -100
    fi
elif [ -f "package.json" ]; then
    # TypeScript/JavaScript
    if [ -n "$PATTERN" ]; then
        grep -rn "from ['\"].*$PATTERN" "$SCAN_PATH" --include="*.ts" --include="*.tsx" --include="*.js" --include="*.jsx" 2>/dev/null || true
    else
        grep -rn "from ['\"]" "$SCAN_PATH" --include="*.ts" --include="*.tsx" --include="*.js" --include="*.jsx" 2>/dev/null | head -100
    fi
elif [ -f "pyproject.toml" ] || [ -f "setup.py" ] || [ -f "requirements.txt" ]; then
    # Python
    if [ -n "$PATTERN" ]; then
        grep -rn "^from $PATTERN\|^import $PATTERN" "$SCAN_PATH" --include="*.py" 2>/dev/null || true
    else
        grep -rn "^from \|^import " "$SCAN_PATH" --include="*.py" 2>/dev/null | head -100
    fi
elif [ -f "go.mod" ]; then
    # Go
    if [ -n "$PATTERN" ]; then
        grep -rn "\"$PATTERN" "$SCAN_PATH" --include="*.go" 2>/dev/null || true
    else
        grep -rn "^import\|^\t\"" "$SCAN_PATH" --include="*.go" 2>/dev/null | head -100
    fi
else
    echo "[imports] Unknown stack - scanning for common import patterns..."
    grep -rn "^import\|^from\|^#include\|^use\|^require" "$SCAN_PATH" 2>/dev/null | head -100
fi

echo ""
echo "[imports] ============================================"
echo "[imports] (Output limited to 100 lines. Use pattern filter for focused results)"

exit 0
