#!/usr/bin/env sh
set -eu

# =============================================================================
# SDLC Agent Harness - Architecture Test Runner
# =============================================================================
# Detects technology stack and runs the appropriate architecture validation.
#
# For detailed stack-specific information, see: skills/stacks/<stack>.md
#
# Usage: ./harness/run-arch-tests.sh
# =============================================================================

echo "[arch-tests] ============================================"
echo "[arch-tests] Running architecture tests"
echo "[arch-tests] ============================================"

FAILURES=0

# -----------------------------------------------------------------------------
# Stack Detection (see skills/stack-detection.md for details)
# -----------------------------------------------------------------------------
# Source shared stack detection utility
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=harness/lib/stack-detection.sh
. "$SCRIPT_DIR/lib/stack-detection.sh"

STACK=$(detect_stack)
echo "[arch-tests] Detected stack: $STACK"

# -----------------------------------------------------------------------------
# Run stack-specific tests
# -----------------------------------------------------------------------------
case "$STACK" in
    java)
        # See: skills/stacks/java.md
        if grep -q "archunit" pom.xml build.gradle* 2>/dev/null; then
            echo "[arch-tests] Running ArchUnit..."
            if [ -f "pom.xml" ]; then
                mvn test -Dtest="*Arch*" -DfailIfNoTests=false || FAILURES=$((FAILURES + 1))
            else
                ./gradlew test --tests "*Arch*" || FAILURES=$((FAILURES + 1))
            fi
        else
            echo "[arch-tests] No ArchUnit config found"
        fi
        ;;

    typescript)
        # See: skills/stacks/typescript.md
        if [ -f ".dependency-cruiser.js" ] || [ -f ".dependency-cruiser.cjs" ]; then
            echo "[arch-tests] Running Dependency Cruiser..."
            npx depcruise src --config || FAILURES=$((FAILURES + 1))
        fi
        echo "[arch-tests] Checking circular dependencies..."
        npx --yes madge --circular --extensions ts,tsx,js,jsx src/ 2>/dev/null || FAILURES=$((FAILURES + 1))
        ;;

    python)
        # See: skills/stacks/python.md
        if [ -f ".importlinter" ] || grep -q "importlinter" pyproject.toml setup.cfg 2>/dev/null; then
            echo "[arch-tests] Running Import Linter..."
            lint-imports 2>/dev/null || python -m importlinter || FAILURES=$((FAILURES + 1))
        else
            echo "[arch-tests] No import-linter config found"
        fi
        ;;

    go)
        # See: skills/stacks/go.md
        if [ -f ".go-arch-lint.yaml" ] || [ -f ".go-arch-lint.yml" ]; then
            echo "[arch-tests] Running go-arch-lint..."
            go-arch-lint check || FAILURES=$((FAILURES + 1))
        fi
        echo "[arch-tests] Checking import cycles..."
        go build ./... 2>&1 | grep -q "import cycle" && FAILURES=$((FAILURES + 1))
        ;;

    rust)
        # See: skills/stacks/rust.md
        echo "[arch-tests] Running cargo check..."
        cargo check 2>&1 | grep -qi "cycle" && FAILURES=$((FAILURES + 1))
        echo "[arch-tests] Running clippy..."
        cargo clippy -- -D warnings || FAILURES=$((FAILURES + 1))
        ;;

    dotnet)
        # See: skills/stacks/dotnet.md
        if grep -r "ArchUnitNET" . --include="*.csproj" 2>/dev/null; then
            echo "[arch-tests] Running ArchUnitNET..."
            dotnet test --filter "Category=Architecture" || FAILURES=$((FAILURES + 1))
        fi
        ;;

    ruby)
        # See: skills/stacks/ruby.md
        if [ -f "packwerk.yml" ]; then
            echo "[arch-tests] Running Packwerk..."
            bin/packwerk check 2>/dev/null || bundle exec packwerk check || FAILURES=$((FAILURES + 1))
        fi
        ;;

    php)
        # See: skills/stacks/php.md
        if [ -f "deptrac.yaml" ] || [ -f "deptrac.yml" ]; then
            echo "[arch-tests] Running Deptrac..."
            ./vendor/bin/deptrac analyse 2>/dev/null || deptrac analyse || FAILURES=$((FAILURES + 1))
        fi
        ;;

    *)
        echo "[arch-tests] Unknown stack - no tests to run"
        echo "[arch-tests] See skills/stack-detection.md for supported stacks"
        ;;
esac

# -----------------------------------------------------------------------------
# Summary
# -----------------------------------------------------------------------------
echo ""
echo "[arch-tests] ============================================"
if [ $FAILURES -eq 0 ]; then
    echo "[arch-tests] All architecture tests passed!"
else
    echo "[arch-tests] Tests completed with $FAILURES issue(s)"
fi
echo "[arch-tests] ============================================"

exit $FAILURES
