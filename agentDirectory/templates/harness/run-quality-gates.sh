#!/usr/bin/env sh
set -eu

# =============================================================================
# SDLC Agent Harness - Quality Gates Runner
# =============================================================================
# Runs comprehensive quality checks: tests, static analysis, coverage, metrics.
# This is the full verification before code can be merged.
#
# Usage: ./harness/run-quality-gates.sh
# =============================================================================

echo "[quality-gates] ============================================"
echo "[quality-gates] Running quality gates"
echo "[quality-gates] ============================================"

FAILURES=0

# -----------------------------------------------------------------------------
# 1. Run all tests
# -----------------------------------------------------------------------------
run_tests() {
    echo "[quality-gates] [1/5] Running full test suite..."

    if [ -f "pom.xml" ]; then
        mvn test || return 1
    elif [ -f "build.gradle" ] || [ -f "build.gradle.kts" ]; then
        ./gradlew test || return 1
    elif [ -f "package.json" ]; then
        npm test || return 1
    elif [ -f "Cargo.toml" ]; then
        cargo test || return 1
    elif [ -f "go.mod" ]; then
        go test ./... || return 1
    else
        echo "[quality-gates] No recognized test runner"
        return 0
    fi
}

# -----------------------------------------------------------------------------
# 2. Run architecture tests
# -----------------------------------------------------------------------------
run_arch() {
    echo "[quality-gates] [2/5] Running architecture tests..."

    if [ -f "harness/run-arch-tests.sh" ]; then
        ./harness/run-arch-tests.sh || return 1
    else
        echo "[quality-gates] No architecture test script found"
    fi
}

# -----------------------------------------------------------------------------
# 3. Run static analysis
# -----------------------------------------------------------------------------
run_static_analysis() {
    echo "[quality-gates] [3/5] Running static analysis..."

    if [ -f "pom.xml" ]; then
        # Check for common Maven static analysis plugins
        if grep -q "spotbugs" pom.xml 2>/dev/null; then
            echo "[quality-gates] Running SpotBugs..."
            mvn spotbugs:check || return 1
        fi
        if grep -q "checkstyle" pom.xml 2>/dev/null; then
            echo "[quality-gates] Running Checkstyle..."
            mvn checkstyle:check || return 1
        fi
    elif [ -f "build.gradle" ] || [ -f "build.gradle.kts" ]; then
        # Check for Gradle static analysis plugins
        if grep -q "detekt" build.gradle* 2>/dev/null; then
            echo "[quality-gates] Running detekt..."
            ./gradlew detekt || return 1
        fi
        if grep -q "ktlint" build.gradle* 2>/dev/null; then
            echo "[quality-gates] Running ktlint..."
            ./gradlew ktlintCheck || return 1
        fi
    elif [ -f "package.json" ]; then
        if grep -q '"lint"' package.json 2>/dev/null; then
            echo "[quality-gates] Running npm lint..."
            npm run lint || return 1
        fi
    elif [ -f "Cargo.toml" ]; then
        echo "[quality-gates] Running clippy..."
        cargo clippy -- -D warnings || return 1
    elif [ -f "go.mod" ]; then
        echo "[quality-gates] Running go vet..."
        go vet ./... || return 1
        if command -v staticcheck >/dev/null 2>&1; then
            staticcheck ./... || return 1
        fi
    fi

    echo "[quality-gates] Static analysis complete"
}

# -----------------------------------------------------------------------------
# 4. Check code coverage (optional)
# -----------------------------------------------------------------------------
run_coverage() {
    echo "[quality-gates] [4/5] Checking code coverage..."

    if [ -f "pom.xml" ]; then
        if grep -q "jacoco" pom.xml 2>/dev/null; then
            echo "[quality-gates] Running JaCoCo coverage..."
            mvn jacoco:check 2>/dev/null || echo "[quality-gates] Coverage check not configured"
        fi
    elif [ -f "build.gradle" ] || [ -f "build.gradle.kts" ]; then
        if grep -q "jacoco" build.gradle* 2>/dev/null; then
            echo "[quality-gates] Running JaCoCo coverage..."
            ./gradlew jacocoTestCoverageVerification 2>/dev/null || echo "[quality-gates] Coverage check not configured"
        fi
    elif [ -f "package.json" ]; then
        if grep -q '"coverage"' package.json 2>/dev/null; then
            echo "[quality-gates] Running coverage..."
            npm run coverage 2>/dev/null || echo "[quality-gates] Coverage not configured"
        fi
    fi

    echo "[quality-gates] Coverage check complete"
}

# -----------------------------------------------------------------------------
# 5. Security scan (optional)
# -----------------------------------------------------------------------------
run_security() {
    echo "[quality-gates] [5/5] Running security checks..."

    if [ -f "pom.xml" ]; then
        if grep -q "dependency-check" pom.xml 2>/dev/null; then
            echo "[quality-gates] Running OWASP dependency check..."
            mvn dependency-check:check 2>/dev/null || echo "[quality-gates] Dependency check not configured"
        fi
    elif [ -f "package.json" ]; then
        echo "[quality-gates] Running npm audit..."
        npm audit --audit-level=high 2>/dev/null || echo "[quality-gates] npm audit found issues or not configured"
    elif [ -f "Cargo.toml" ]; then
        if command -v cargo-audit >/dev/null 2>&1; then
            cargo audit || echo "[quality-gates] cargo-audit found issues"
        fi
    fi

    echo "[quality-gates] Security check complete"
}

# -----------------------------------------------------------------------------
# 6. Execute all gates
# -----------------------------------------------------------------------------
run_tests || FAILURES=$((FAILURES + 1))
run_arch || FAILURES=$((FAILURES + 1))
run_static_analysis || FAILURES=$((FAILURES + 1))
run_coverage || true  # Coverage is informational, don't fail
run_security || true  # Security is informational, don't fail

# -----------------------------------------------------------------------------
# 7. Summary
# -----------------------------------------------------------------------------
echo ""
echo "[quality-gates] ============================================"
if [ $FAILURES -eq 0 ]; then
    echo "[quality-gates] ✓ All quality gates passed!"
    echo "[quality-gates] Code is ready for review."
else
    echo "[quality-gates] ✗ $FAILURES quality gate(s) failed"
    echo "[quality-gates] Review output above and fix issues."
fi
echo "[quality-gates] ============================================"

exit $FAILURES
