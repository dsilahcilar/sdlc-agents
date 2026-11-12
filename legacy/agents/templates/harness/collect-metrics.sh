#!/usr/bin/env sh
set -eu

# =============================================================================
# SDLC Agent Harness - Metrics Collection
# =============================================================================
# Collects architectural metrics from the project and outputs to JSON.
# Supports multiple stacks with stack-specific metrics collection.
#
# Output: agent-context/metrics/current.json
# Usage: ./harness/collect-metrics.sh
# =============================================================================

echo "[metrics] ============================================"
echo "[metrics] Collecting project metrics"
echo "[metrics] ============================================"

# Determine project root (go up from harness directory)
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
METRICS_DIR="$PROJECT_ROOT/agent-context/metrics"
OUTPUT_FILE="$METRICS_DIR/current.json"

# Create metrics directory if it doesn't exist
mkdir -p "$METRICS_DIR"

# Source shared stack detection
# shellcheck source=harness/lib/stack-detection.sh
. "$SCRIPT_DIR/lib/stack-detection.sh"

STACK=$(detect_stack)
echo "[metrics] Detected stack: $STACK"

# -----------------------------------------------------------------------------
# Universal Metrics Collection (all stacks)
# -----------------------------------------------------------------------------
collect_universal_metrics() {
    echo "[metrics] Collecting universal metrics..."
    
    # Count total files and directories (excluding common ignore patterns)
    TOTAL_FILES=$(find "$PROJECT_ROOT" -type f \
        -not -path "*/node_modules/*" \
        -not -path "*/.git/*" \
        -not -path "*/target/*" \
        -not -path "*/build/*" \
        -not -path "*/dist/*" \
        -not -path "*/.idea/*" \
        -not -path "*/.vscode/*" \
        2>/dev/null | wc -l | tr -d ' ')
    
    TOTAL_DIRS=$(find "$PROJECT_ROOT" -type d \
        -not -path "*/node_modules/*" \
        -not -path "*/.git/*" \
        -not -path "*/target/*" \
        -not -path "*/build/*" \
        -not -path "*/dist/*" \
        2>/dev/null | wc -l | tr -d ' ')
    
    # Calculate max directory depth
    MAX_DEPTH=$(find "$PROJECT_ROOT" -type d \
        -not -path "*/node_modules/*" \
        -not -path "*/.git/*" \
        -not -path "*/target/*" \
        -not -path "*/build/*" \
        2>/dev/null | \
        awk -F/ '{print NF}' | sort -rn | head -1)
    
    # Calculate relative depth from project root
    ROOT_DEPTH=$(echo "$PROJECT_ROOT" | awk -F/ '{print NF}')
    MAX_DEPTH=$((MAX_DEPTH - ROOT_DEPTH))
    
    # Average files per directory
    if [ "$TOTAL_DIRS" -gt 0 ]; then
        AVG_FILES_PER_DIR=$(echo "scale=2; $TOTAL_FILES / $TOTAL_DIRS" | bc 2>/dev/null || echo "0")
    else
        AVG_FILES_PER_DIR="0"
    fi
    
    echo "[metrics]   Total files: $TOTAL_FILES"
    echo "[metrics]   Total directories: $TOTAL_DIRS"
    echo "[metrics]   Max directory depth: $MAX_DEPTH"
}

# -----------------------------------------------------------------------------
# Cyclomatic Complexity Analysis (using Lizard)
# -----------------------------------------------------------------------------
collect_complexity_metrics() {
    echo "[metrics] Collecting cyclomatic complexity metrics..."
    
    # Check if Lizard is installed
    if ! command -v lizard >/dev/null 2>&1; then
        echo "[metrics]   ⚠ Lizard not installed (optional) - Cyclomatic complexity analysis skipped"
        echo "[metrics]   "
        echo "[metrics]   To enable complexity metrics, install Lizard (language-agnostic analyzer):"
        echo "[metrics]   "
        echo "[metrics]   Option 1 (Recommended - isolated environment):"
        echo "[metrics]     brew install pipx && pipx install lizard"
        echo "[metrics]   "
        echo "[metrics]   Option 2 (Direct pip install):"
        echo "[metrics]     pip3 install --user lizard"
        echo "[metrics]   "
        echo "[metrics]   Option 3 (System-wide, if permitted):"
        echo "[metrics]     pip3 install lizard --break-system-packages"
        echo "[metrics]   "
        echo "[metrics]   Verify: lizard --version"
        echo "[metrics]   "
        # Set default values
        AVG_CCN="0"
        MAX_CCN="0"
        FUNCTIONS_OVER_15="0"
        AVG_NLOC="0"
        MAX_NLOC="0"
        return 0
    fi
    
    # Run Lizard with CSV output for easier parsing
    # Exclude common directories and focus on source code
    LIZARD_OUTPUT=$(lizard "$PROJECT_ROOT" \
        --exclude "*/node_modules/*" \
        --exclude "*/.git/*" \
        --exclude "*/target/*" \
        --exclude "*/build/*" \
        --exclude "*/dist/*" \
        --exclude "*/vendor/*" \
        --exclude "*/venv/*" \
        --exclude "*/__pycache__/*" \
        --csv 2>/dev/null || echo "")
    
    if [ -z "$LIZARD_OUTPUT" ]; then
        echo "[metrics]   ⚠ No complexity data collected"
        AVG_CCN="0"
        MAX_CCN="0"
        FUNCTIONS_OVER_15="0"
        AVG_NLOC="0"
        MAX_NLOC="0"
        return 0
    fi
    
    # Parse CSV output (columns: NLOC, CCN, token, PARAM, length, location, file, function, etc.)
    # Skip header line and calculate metrics
    
    # Extract CCN (Cyclomatic Complexity Number) - column 2
    CCN_VALUES=$(echo "$LIZARD_OUTPUT" | tail -n +2 | cut -d',' -f2 | grep -E '^[0-9]+$' || echo "")
    
    if [ -n "$CCN_VALUES" ]; then
        # Calculate average CCN
        TOTAL_CCN=$(echo "$CCN_VALUES" | awk '{sum+=$1} END {print sum}')
        COUNT_CCN=$(echo "$CCN_VALUES" | wc -l | tr -d ' ')
        if [ "$COUNT_CCN" -gt 0 ]; then
            AVG_CCN=$(echo "scale=2; $TOTAL_CCN / $COUNT_CCN" | bc 2>/dev/null || echo "0")
        else
            AVG_CCN="0"
        fi
        
        # Find max CCN
        MAX_CCN=$(echo "$CCN_VALUES" | sort -rn | head -1 || echo "0")
        
        # Count functions with CCN > 15 (high complexity threshold)
        FUNCTIONS_OVER_15=$(echo "$CCN_VALUES" | awk '$1 > 15' | wc -l | tr -d ' ')
    else
        AVG_CCN="0"
        MAX_CCN="0"
        FUNCTIONS_OVER_15="0"
    fi
    
    # Extract NLOC (Non-comment Lines of Code) - column 1
    NLOC_VALUES=$(echo "$LIZARD_OUTPUT" | tail -n +2 | cut -d',' -f1 | grep -E '^[0-9]+$' || echo "")
    
    if [ -n "$NLOC_VALUES" ]; then
        # Calculate average function length
        TOTAL_NLOC=$(echo "$NLOC_VALUES" | awk '{sum+=$1} END {print sum}')
        COUNT_NLOC=$(echo "$NLOC_VALUES" | wc -l | tr -d ' ')
        if [ "$COUNT_NLOC" -gt 0 ]; then
            AVG_NLOC=$(echo "scale=2; $TOTAL_NLOC / $COUNT_NLOC" | bc 2>/dev/null || echo "0")
        else
            AVG_NLOC="0"
        fi
        
        # Find max function length
        MAX_NLOC=$(echo "$NLOC_VALUES" | sort -rn | head -1 || echo "0")
    else
        AVG_NLOC="0"
        MAX_NLOC="0"
    fi
    
    echo "[metrics]   Average cyclomatic complexity: $AVG_CCN"
    echo "[metrics]   Max cyclomatic complexity: $MAX_CCN"
    echo "[metrics]   Functions over CCN 15: $FUNCTIONS_OVER_15"
    echo "[metrics]   Average function length (NLOC): $AVG_NLOC"
    echo "[metrics]   Max function length (NLOC): $MAX_NLOC"
}

# -----------------------------------------------------------------------------
# Stack-Specific Metrics Collection
# -----------------------------------------------------------------------------
collect_java_metrics() {
    echo "[metrics] Collecting Java/Kotlin metrics..."
    
    # Count circular dependencies from ArchUnit test output (if available)
    CIRCULAR_DEPS=0
    ARCH_VIOLATIONS=0
    
    # Run ArchUnit tests in quiet mode and parse output
    if [ -f "pom.xml" ]; then
        TEST_OUTPUT=$(mvn test -Dtest="*Arch*" -DfailIfNoTests=false 2>&1 || true)
    elif [ -f "build.gradle" ] || [ -f "build.gradle.kts" ]; then
        TEST_OUTPUT=$(./gradlew test --tests "*Arch*" 2>&1 || true)
    else
        TEST_OUTPUT=""
    fi
    
    # Parse violations (this is a simple heuristic)
    if echo "$TEST_OUTPUT" | grep -qi "cycle"; then
        CIRCULAR_DEPS=$(echo "$TEST_OUTPUT" | grep -i "cycle" | wc -l | tr -d ' ')
    fi
    
    if echo "$TEST_OUTPUT" | grep -qi "violation"; then
        ARCH_VIOLATIONS=$(echo "$TEST_OUTPUT" | grep -i "violation" | wc -l | tr -d ' ')
    fi
    
    echo "[metrics]   Circular dependencies: $CIRCULAR_DEPS"
    echo "[metrics]   Architecture violations: $ARCH_VIOLATIONS"
}

collect_typescript_metrics() {
    echo "[metrics] Collecting TypeScript metrics..."
    
    # Check for circular dependencies using madge
    CIRCULAR_DEPS=0
    if command -v npx >/dev/null 2>&1; then
        CIRCULAR_OUTPUT=$(npx --yes madge --circular --extensions ts,tsx,js,jsx src/ 2>/dev/null || echo "")
        if [ -n "$CIRCULAR_OUTPUT" ]; then
            CIRCULAR_DEPS=$(echo "$CIRCULAR_OUTPUT" | grep -c "→" || echo "0")
        fi
    fi
    
    echo "[metrics]   Circular dependencies: $CIRCULAR_DEPS"
}

collect_python_metrics() {
    echo "[metrics] Collecting Python metrics..."
    # Placeholder for Python-specific metrics
    echo "[metrics]   (Python metrics collection not yet implemented)"
}

collect_generic_metrics() {
    echo "[metrics] Collecting generic metrics (no stack-specific tools available)"
}

# -----------------------------------------------------------------------------
# Test Metrics Collection
# -----------------------------------------------------------------------------
collect_test_metrics() {
    echo "[metrics] Collecting test metrics..."
    
    # Count test files (heuristic based on common patterns)
    TEST_FILES=$(find "$PROJECT_ROOT" -type f \
        \( -name "*Test.*" -o -name "*test.*" -o -name "*.test.*" -o -name "*.spec.*" \) \
        -not -path "*/node_modules/*" \
        -not -path "*/.git/*" \
        -not -path "*/target/*" \
        -not -path "*/build/*" \
        2>/dev/null | wc -l | tr -d ' ')
    
    # Calculate test-to-code ratio
    if [ "$TOTAL_FILES" -gt 0 ]; then
        TEST_RATIO=$(echo "scale=3; $TEST_FILES / $TOTAL_FILES" | bc 2>/dev/null || echo "0")
    else
        TEST_RATIO="0"
    fi
    
    # Coverage - attempt to extract from recent reports
    COVERAGE=0
    # JaCoCo (Java)
    if [ -f "target/site/jacoco/index.html" ]; then
        COVERAGE=$(grep -oP 'Total.*?(\d+)%' target/site/jacoco/index.html | grep -oP '\d+' | head -1 || echo "0")
    # Istanbul/NYC (JS/TS)
    elif [ -f "coverage/coverage-summary.json" ]; then
        COVERAGE=$(grep -oP '"total".*?"pct":\s*(\d+)' coverage/coverage-summary.json | grep -oP '\d+' | head -1 || echo "0")
    fi
    
    echo "[metrics]   Test files: $TEST_FILES"
    echo "[metrics]   Test-to-code ratio: $TEST_RATIO"
    echo "[metrics]   Coverage: $COVERAGE%"
}

# -----------------------------------------------------------------------------
# Execute collection
# -----------------------------------------------------------------------------
collect_universal_metrics
collect_complexity_metrics
collect_test_metrics

# Collect stack-specific metrics
case "$STACK" in
    java)
        collect_java_metrics
        ;;
    typescript)
        collect_typescript_metrics
        ;;
    python)
        collect_python_metrics
        ;;
    *)
        collect_generic_metrics
        ;;
esac

# -----------------------------------------------------------------------------
# Generate JSON output
# -----------------------------------------------------------------------------
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%S%z")

cat > "$OUTPUT_FILE" <<EOF
{
  "timestamp": "$TIMESTAMP",
  "snapshot_type": "current",
  "stack": "$STACK",
  "metrics": {
    "architecture": {
      "total_files": $TOTAL_FILES,
      "total_directories": $TOTAL_DIRS,
      "max_directory_depth": $MAX_DEPTH,
      "average_files_per_directory": $AVG_FILES_PER_DIR
    },
    "complexity": {
      "average_cyclomatic_complexity": $AVG_CCN,
      "max_cyclomatic_complexity": $MAX_CCN,
      "functions_over_threshold": $FUNCTIONS_OVER_15,
      "average_function_length": $AVG_NLOC,
      "max_function_length": $MAX_NLOC
    },
    "coupling": {
      "circular_dependencies": ${CIRCULAR_DEPS:-0},
      "architecture_violations": ${ARCH_VIOLATIONS:-0}
    },
    "testing": {
      "total_test_files": $TEST_FILES,
      "test_to_code_ratio": $TEST_RATIO,
      "coverage_percent": $COVERAGE
    }
  }
}
EOF

echo "[metrics] ✓ Metrics written to: $OUTPUT_FILE"
echo "[metrics] ============================================"
