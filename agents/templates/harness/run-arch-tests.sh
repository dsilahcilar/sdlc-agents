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
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# shellcheck source=harness/lib/stack-detection.sh
. "$SCRIPT_DIR/lib/stack-detection.sh"

STACK=$(detect_stack "$PROJECT_ROOT")
echo "[arch-tests] Detected stack: $STACK"
echo "[arch-tests] Project root: $PROJECT_ROOT"

# -----------------------------------------------------------------------------
# Run stack-specific tests
# -----------------------------------------------------------------------------
case "$STACK" in
    java)
        # See: skills/stacks/java.md
        if grep -q "archunit" "$PROJECT_ROOT/pom.xml" "$PROJECT_ROOT"/build.gradle* 2>/dev/null; then
            echo "[arch-tests] Running ArchUnit..."
            if [ -f "$PROJECT_ROOT/pom.xml" ]; then
                (cd "$PROJECT_ROOT" && mvn test -Dtest="*Arch*" -DfailIfNoTests=false) || FAILURES=$((FAILURES + 1))
            else
                (cd "$PROJECT_ROOT" && ./gradlew test --tests "*Arch*") || FAILURES=$((FAILURES + 1))
            fi
        else
            echo "[arch-tests] No ArchUnit config found"
        fi
        ;;

    typescript)
        # See: skills/stacks/typescript.md
        if [ -f "$PROJECT_ROOT/.dependency-cruiser.js" ] || [ -f "$PROJECT_ROOT/.dependency-cruiser.cjs" ]; then
            echo "[arch-tests] Running Dependency Cruiser..."
            (cd "$PROJECT_ROOT" && npx depcruise src --config) || FAILURES=$((FAILURES + 1))
        fi
        echo "[arch-tests] Checking circular dependencies..."
        (cd "$PROJECT_ROOT" && npx --yes madge --circular --extensions ts,tsx,js,jsx src/) 2>/dev/null || FAILURES=$((FAILURES + 1))
        ;;

    python)
        # See: skills/stacks/python.md
        if [ -f "$PROJECT_ROOT/.importlinter" ] || grep -q "importlinter" "$PROJECT_ROOT/pyproject.toml" "$PROJECT_ROOT/setup.cfg" 2>/dev/null; then
            echo "[arch-tests] Running Import Linter..."
            (cd "$PROJECT_ROOT" && lint-imports 2>/dev/null || python -m importlinter) || FAILURES=$((FAILURES + 1))
        else
            echo "[arch-tests] No import-linter config found"
        fi
        ;;

    go)
        # See: skills/stacks/go.md
        if [ -f "$PROJECT_ROOT/.go-arch-lint.yaml" ] || [ -f "$PROJECT_ROOT/.go-arch-lint.yml" ]; then
            echo "[arch-tests] Running go-arch-lint..."
            (cd "$PROJECT_ROOT" && go-arch-lint check) || FAILURES=$((FAILURES + 1))
        fi
        echo "[arch-tests] Checking import cycles..."
        (cd "$PROJECT_ROOT" && go build ./...) 2>&1 | grep -q "import cycle" && FAILURES=$((FAILURES + 1))
        ;;

    rust)
        # See: skills/stacks/rust.md
        echo "[arch-tests] Running cargo check..."
        (cd "$PROJECT_ROOT" && cargo check) 2>&1 | grep -qi "cycle" && FAILURES=$((FAILURES + 1))
        echo "[arch-tests] Running clippy..."
        (cd "$PROJECT_ROOT" && cargo clippy -- -D warnings) || FAILURES=$((FAILURES + 1))
        ;;

    dotnet)
        # See: skills/stacks/dotnet.md
        if grep -r "ArchUnitNET" "$PROJECT_ROOT" --include="*.csproj" 2>/dev/null; then
            echo "[arch-tests] Running ArchUnitNET..."
            (cd "$PROJECT_ROOT" && dotnet test --filter "Category=Architecture") || FAILURES=$((FAILURES + 1))
        fi
        ;;

    ruby)
        # See: skills/stacks/ruby.md
        if [ -f "$PROJECT_ROOT/packwerk.yml" ]; then
            echo "[arch-tests] Running Packwerk..."
            (cd "$PROJECT_ROOT" && bin/packwerk check 2>/dev/null || bundle exec packwerk check) || FAILURES=$((FAILURES + 1))
        fi
        ;;

    php)
        # See: skills/stacks/php.md
        if [ -f "$PROJECT_ROOT/deptrac.yaml" ] || [ -f "$PROJECT_ROOT/deptrac.yml" ]; then
            echo "[arch-tests] Running Deptrac..."
            (cd "$PROJECT_ROOT" && ./vendor/bin/deptrac analyse 2>/dev/null || deptrac analyse) || FAILURES=$((FAILURES + 1))
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
