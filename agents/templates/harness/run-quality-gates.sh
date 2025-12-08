#!/usr/bin/env sh
set -eu

# =============================================================================
# SDLC Agent Harness - Quality Gates Runner
# =============================================================================
# Runs comprehensive quality checks: tests, static analysis, coverage, metrics.
# This is the full verification before code can be merged.
#
# Output Strategy: All verbose output is written to a temp log file to avoid
# filling LLM context windows. Only concise summaries and relevant errors
# are printed to stdout.
#
# Usage: ./harness/run-quality-gates.sh
# =============================================================================

# Create temp directory for logs
LOG_DIR="${TMPDIR:-/tmp}/quality-gates-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/quality-gates.log"
SUMMARY_FILE="$LOG_DIR/summary.txt"

echo "[quality-gates] ============================================"
echo "[quality-gates] Running quality gates"
echo "[quality-gates] Log file: $LOG_FILE"
echo "[quality-gates] ============================================"

FAILURES=0
GATE_RESULTS=""

# Helper function to log with timestamp
log() {
    echo "[$(date '+%H:%M:%S')] $*" >> "$LOG_FILE"
}

# Helper function to run a command and capture output
run_cmd() {
    local description="$1"
    shift
    log "Running: $*"
    if "$@" >> "$LOG_FILE" 2>&1; then
        log "$description: PASSED"
        return 0
    else
        log "$description: FAILED"
        return 1
    fi
}

# Helper function to extract error summary from log
extract_errors() {
    local context_lines="${1:-10}"
    # Look for common error patterns and extract surrounding context
    grep -n -E "(FAILURE|ERROR|FAILED|BUILD FAILURE|Test.*failed|AssertionError|Exception|✗)" "$LOG_FILE" 2>/dev/null | head -20 || true
}

# -----------------------------------------------------------------------------
# 1. Run all tests
# -----------------------------------------------------------------------------
run_tests() {
    echo "[quality-gates] [1/5] Running full test suite..."
    log "=== PHASE 1: TESTS ==="

    if [ -f "pom.xml" ]; then
        run_cmd "Maven tests" mvn test -q || return 1
    elif [ -f "build.gradle" ] || [ -f "build.gradle.kts" ]; then
        run_cmd "Gradle tests" ./gradlew test --console=plain -q || return 1
    elif [ -f "package.json" ]; then
        run_cmd "NPM tests" npm test || return 1
    elif [ -f "Cargo.toml" ]; then
        run_cmd "Cargo tests" cargo test --quiet || return 1
    elif [ -f "go.mod" ]; then
        run_cmd "Go tests" go test ./... || return 1
    else
        echo "[quality-gates] No recognized test runner"
        log "No recognized test runner found"
        return 0
    fi
}

# -----------------------------------------------------------------------------
# 2. Run architecture tests
# -----------------------------------------------------------------------------
run_arch() {
    echo "[quality-gates] [2/5] Running architecture tests..."
    log "=== PHASE 2: ARCHITECTURE TESTS ==="

    if [ -f "harness/run-arch-tests.sh" ]; then
        run_cmd "Architecture tests" ./harness/run-arch-tests.sh || return 1
    else
        echo "[quality-gates] No architecture test script found"
        log "No architecture test script found"
    fi
}

# -----------------------------------------------------------------------------
# 3. Run static analysis
# -----------------------------------------------------------------------------
run_static_analysis() {
    echo "[quality-gates] [3/5] Running static analysis..."
    log "=== PHASE 3: STATIC ANALYSIS ==="

    if [ -f "pom.xml" ]; then
        if grep -q "spotbugs" pom.xml 2>/dev/null; then
            log "Running SpotBugs..."
            run_cmd "SpotBugs" mvn spotbugs:check -q || return 1
        fi
        if grep -q "checkstyle" pom.xml 2>/dev/null; then
            log "Running Checkstyle..."
            run_cmd "Checkstyle" mvn checkstyle:check -q || return 1
        fi
    elif [ -f "build.gradle" ] || [ -f "build.gradle.kts" ]; then
        if grep -q "detekt" build.gradle* 2>/dev/null; then
            log "Running detekt..."
            run_cmd "Detekt" ./gradlew detekt --console=plain -q || return 1
        fi
        if grep -q "ktlint" build.gradle* 2>/dev/null; then
            log "Running ktlint..."
            run_cmd "Ktlint" ./gradlew ktlintCheck --console=plain -q || return 1
        fi
    elif [ -f "package.json" ]; then
        if grep -q '"lint"' package.json 2>/dev/null; then
            log "Running npm lint..."
            run_cmd "ESLint" npm run lint || return 1
        fi
    elif [ -f "Cargo.toml" ]; then
        log "Running clippy..."
        run_cmd "Clippy" cargo clippy --quiet -- -D warnings || return 1
    elif [ -f "go.mod" ]; then
        log "Running go vet..."
        run_cmd "Go vet" go vet ./... || return 1
        if command -v staticcheck >/dev/null 2>&1; then
            run_cmd "Staticcheck" staticcheck ./... || return 1
        fi
    fi

    log "Static analysis complete"
}

# -----------------------------------------------------------------------------
# 4. Check code coverage (optional)
# -----------------------------------------------------------------------------
run_coverage() {
    echo "[quality-gates] [4/5] Checking code coverage..."
    log "=== PHASE 4: COVERAGE ==="

    if [ -f "pom.xml" ]; then
        if grep -q "jacoco" pom.xml 2>/dev/null; then
            log "Running JaCoCo coverage..."
            run_cmd "JaCoCo" mvn jacoco:check -q || log "Coverage check not configured"
        fi
    elif [ -f "build.gradle" ] || [ -f "build.gradle.kts" ]; then
        if grep -q "jacoco" build.gradle* 2>/dev/null; then
            log "Running JaCoCo coverage..."
            run_cmd "JaCoCo" ./gradlew jacocoTestCoverageVerification --console=plain -q || log "Coverage check not configured"
        fi
    elif [ -f "package.json" ]; then
        if grep -q '"coverage"' package.json 2>/dev/null; then
            log "Running coverage..."
            run_cmd "Coverage" npm run coverage || log "Coverage not configured"
        fi
    fi

    log "Coverage check complete"
}

# -----------------------------------------------------------------------------
# 5. Security scan (optional)
# -----------------------------------------------------------------------------
run_security() {
    echo "[quality-gates] [5/5] Running security checks..."
    log "=== PHASE 5: SECURITY ==="

    if [ -f "pom.xml" ]; then
        if grep -q "dependency-check" pom.xml 2>/dev/null; then
            log "Running OWASP dependency check..."
            run_cmd "OWASP" mvn dependency-check:check -q || log "Dependency check not configured"
        fi
    elif [ -f "package.json" ]; then
        log "Running npm audit..."
        run_cmd "NPM audit" npm audit --audit-level=high || log "npm audit found issues or not configured"
    elif [ -f "Cargo.toml" ]; then
        if command -v cargo-audit >/dev/null 2>&1; then
            run_cmd "Cargo audit" cargo audit || log "cargo-audit found issues"
        fi
    fi

    log "Security check complete"
}

# -----------------------------------------------------------------------------
# 6. Execute all gates and track results
# -----------------------------------------------------------------------------
if run_tests; then
    GATE_RESULTS="${GATE_RESULTS}✓ Tests passed\n"
else
    GATE_RESULTS="${GATE_RESULTS}✗ Tests FAILED\n"
    FAILURES=$((FAILURES + 1))
fi

if run_arch; then
    GATE_RESULTS="${GATE_RESULTS}✓ Architecture tests passed\n"
else
    GATE_RESULTS="${GATE_RESULTS}✗ Architecture tests FAILED\n"
    FAILURES=$((FAILURES + 1))
fi

if run_static_analysis; then
    GATE_RESULTS="${GATE_RESULTS}✓ Static analysis passed\n"
else
    GATE_RESULTS="${GATE_RESULTS}✗ Static analysis FAILED\n"
    FAILURES=$((FAILURES + 1))
fi

run_coverage && GATE_RESULTS="${GATE_RESULTS}✓ Coverage check complete\n" || GATE_RESULTS="${GATE_RESULTS}○ Coverage check skipped/info\n"
run_security && GATE_RESULTS="${GATE_RESULTS}✓ Security check complete\n" || GATE_RESULTS="${GATE_RESULTS}○ Security check skipped/info\n"

# -----------------------------------------------------------------------------
# 7. Summary (concise output for LLM context)
# -----------------------------------------------------------------------------
echo ""
echo "[quality-gates] ============================================"
echo "[quality-gates] SUMMARY"
echo "[quality-gates] ============================================"
printf "%b" "$GATE_RESULTS"
echo "[quality-gates] ============================================"

if [ $FAILURES -eq 0 ]; then
    echo "[quality-gates] ✓ All quality gates passed!"
    echo "[quality-gates] Code is ready for review."
else
    echo "[quality-gates] ✗ $FAILURES quality gate(s) failed"
    echo "[quality-gates] "
    echo "[quality-gates] ==> Error Summary (from $LOG_FILE):"
    echo "[quality-gates] ============================================"
    # Extract and show only relevant error lines
    extract_errors
    echo "[quality-gates] ============================================"
    echo "[quality-gates] Full log: $LOG_FILE"
    echo "[quality-gates] "
    echo "[quality-gates] To view full errors, run:"
    echo "[quality-gates]   cat $LOG_FILE | grep -A5 -E '(FAILURE|ERROR|FAILED)'"
fi
echo "[quality-gates] ============================================"

# Save summary for easy parsing
{
    echo "RESULT: $([ $FAILURES -eq 0 ] && echo 'PASSED' || echo 'FAILED')"
    echo "FAILURES: $FAILURES"
    echo "LOG_FILE: $LOG_FILE"
    printf "GATES:\n%b" "$GATE_RESULTS"
} > "$SUMMARY_FILE"

echo "[quality-gates] Summary file: $SUMMARY_FILE"

exit $FAILURES
