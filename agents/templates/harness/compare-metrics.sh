#!/usr/bin/env sh
set -eu

# =============================================================================
# SDLC Agent Harness - Metrics Comparison
# =============================================================================
# Compares current metrics against thresholds and previous snapshots.
# Uses exit codes to indicate pass/warn/fail status.
#
# Exit Codes:
#   0 = All metrics within thresholds
#   1 = Warnings (approaching thresholds, 80-100%)
#   2 = Failures (exceeds thresholds)
#
# Usage: ./harness/compare-metrics.sh
# =============================================================================

echo "[metrics] ============================================"
echo "[metrics] METRIC COMPARISON REPORT"
echo "[metrics] ============================================"

# Determine project root
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
METRICS_DIR="$PROJECT_ROOT/agent-context/metrics"
CURRENT_FILE="$METRICS_DIR/current.json"
THRESHOLD_FILE="$METRICS_DIR/thresholds.json"

# Check if files exist
if [ ! -f "$CURRENT_FILE" ]; then
    echo "[metrics] ✗ ERROR: current.json not found. Run collect-metrics.sh first."
    exit 2
fi

if [ ! -f "$THRESHOLD_FILE" ]; then
    echo "[metrics] ⚠ WARNING: thresholds.json not found. Using permissive defaults."
    # Continue with checks but no failures
    THRESHOLD_FILE=""
fi

WARNINGS=0
FAILURES=0

# Helper to extract JSON values (simple grep-based, works without jq)
get_json_value() {
    local file="$1"
    local path="$2"
    grep -oP "\"$path\":\s*\K[0-9.]+" "$file" 2>/dev/null | head -1 || echo "0"
}

# Extract current metrics
TOTAL_FILES=$(get_json_value "$CURRENT_FILE" "total_files")
MAX_DEPTH=$(get_json_value "$CURRENT_FILE" "max_directory_depth")
CIRCULAR_DEPS=$(get_json_value "$CURRENT_FILE" "circular_dependencies")
ARCH_VIOLATIONS=$(get_json_value "$CURRENT_FILE" "architecture_violations")
COVERAGE=$(get_json_value "$CURRENT_FILE" "coverage_percent")
TEST_RATIO=$(get_json_value "$CURRENT_FILE" "test_to_code_ratio")

echo "[metrics] Current Metrics:"
echo "[metrics]   Total files: $TOTAL_FILES"
echo "[metrics]   Max directory depth: $MAX_DEPTH"
echo "[metrics]   Circular dependencies: $CIRCULAR_DEPS"
echo "[metrics]   Architecture violations: $ARCH_VIOLATIONS"
echo "[metrics]   Test coverage: $COVERAGE%"
echo "[metrics]   Test-to-code ratio: $TEST_RATIO"
echo "[metrics] "

# If thresholds exist, compare
if [ -n "$THRESHOLD_FILE" ] && [ -f "$THRESHOLD_FILE" ]; then
    echo "[metrics] Threshold Comparison:"
    
    # Max files check
    MAX_FILES=$(get_json_value "$THRESHOLD_FILE" "max_total_files")
    if [ "$MAX_FILES" -gt 0 ]; then
        FILE_PERCENT=$((TOTAL_FILES * 100 / MAX_FILES))
        if [ "$FILE_PERCENT" -ge 100 ]; then
            echo "[metrics]   ✗ Total files: $TOTAL_FILES / $MAX_FILES (EXCEEDS)"
            FAILURES=$((FAILURES + 1))
        elif [ "$FILE_PERCENT" -ge 80 ]; then
            echo "[metrics]   ⚠ Total files: $TOTAL_FILES / $MAX_FILES (${FILE_PERCENT}% - approaching limit)"
            WARNINGS=$((WARNINGS + 1))
        else
            echo "[metrics]   ✓ Total files: $TOTAL_FILES / $MAX_FILES (${FILE_PERCENT}%)"
        fi
    fi
    
    # Max depth check
    MAX_DEPTH_THRESHOLD=$(get_json_value "$THRESHOLD_FILE" "max_directory_depth")
    if [ "$MAX_DEPTH_THRESHOLD" -gt 0 ]; then
        if [ "$MAX_DEPTH" -gt "$MAX_DEPTH_THRESHOLD" ]; then
            echo "[metrics]   ✗ Directory depth: $MAX_DEPTH / $MAX_DEPTH_THRESHOLD (EXCEEDS)"
            FAILURES=$((FAILURES + 1))
        elif [ "$MAX_DEPTH" -eq "$MAX_DEPTH_THRESHOLD" ]; then
            echo "[metrics]   ⚠ Directory depth: $MAX_DEPTH / $MAX_DEPTH_THRESHOLD (at limit)"
            WARNINGS=$((WARNINGS + 1))
        else
            echo "[metrics]   ✓ Directory depth: $MAX_DEPTH / $MAX_DEPTH_THRESHOLD"
        fi
    fi
    
    # Circular dependencies (should be 0)
    MAX_CIRCULAR=$(get_json_value "$THRESHOLD_FILE" "max_circular_dependencies")
    if [ "$CIRCULAR_DEPS" -gt "$MAX_CIRCULAR" ]; then
        echo "[metrics]   ✗ Circular dependencies: $CIRCULAR_DEPS (EXCEEDS threshold of $MAX_CIRCULAR)"
        FAILURES=$((FAILURES + 1))
    else
        echo "[metrics]   ✓ Circular dependencies: $CIRCULAR_DEPS"
    fi
    
    # Architecture violations (should be 0)
    if [ "$ARCH_VIOLATIONS" -gt 0 ]; then
        echo "[metrics]   ✗ Architecture violations: $ARCH_VIOLATIONS (should be 0)"
        FAILURES=$((FAILURES + 1))
    else
        echo "[metrics]   ✓ Architecture violations: $ARCH_VIOLATIONS"
    fi
    
    # Cyclomatic complexity checks
    AVG_CCN=$(get_json_value "$CURRENT_FILE" "average_cyclomatic_complexity")
    MAX_CCN_CURRENT=$(get_json_value "$CURRENT_FILE" "max_cyclomatic_complexity")
    FUNCTIONS_OVER_15=$(get_json_value "$CURRENT_FILE" "functions_over_threshold")
    
    MAX_CCN_THRESHOLD=$(get_json_value "$THRESHOLD_FILE" "max_cyclomatic_complexity")
    WARN_CCN_THRESHOLD=$(get_json_value "$THRESHOLD_FILE" "warn_cyclomatic_complexity")
    MAX_FUNCTIONS_THRESHOLD=$(get_json_value "$THRESHOLD_FILE" "max_functions_over_threshold")
    
    if [ "$MAX_CCN_THRESHOLD" -gt 0 ]; then
        if [ "$MAX_CCN_CURRENT" -gt "$MAX_CCN_THRESHOLD" ]; then
            echo "[metrics]   ✗ Max cyclomatic complexity: $MAX_CCN_CURRENT (EXCEEDS threshold of $MAX_CCN_THRESHOLD)"
            FAILURES=$((FAILURES + 1))
        elif [ "$MAX_CCN_CURRENT" -ge "$WARN_CCN_THRESHOLD" ]; then
            echo "[metrics]   ⚠ Max cyclomatic complexity: $MAX_CCN_CURRENT (approaching threshold of $MAX_CCN_THRESHOLD)"
            WARNINGS=$((WARNINGS + 1))
        else
            echo "[metrics]   ✓ Max cyclomatic complexity: $MAX_CCN_CURRENT (threshold: $MAX_CCN_THRESHOLD)"
        fi
    fi
    
    if [ "$MAX_FUNCTIONS_THRESHOLD" -gt 0 ] && [ "$FUNCTIONS_OVER_15" -gt "$MAX_FUNCTIONS_THRESHOLD" ]; then
        echo "[metrics]   ⚠ Functions with high complexity: $FUNCTIONS_OVER_15 / $MAX_FUNCTIONS_THRESHOLD (review recommended)"
        WARNINGS=$((WARNINGS + 1))
    elif [ "$FUNCTIONS_OVER_15" -gt 0 ]; then
        echo "[metrics]   ⚠ Functions with CCN >15: $FUNCTIONS_OVER_15 (consider refactoring)"
        WARNINGS=$((WARNINGS + 1))
    else
        echo "[metrics]   ✓ High complexity functions: 0"
    fi
    
    # Coverage check
    MIN_COVERAGE=$(get_json_value "$THRESHOLD_FILE" "min_coverage_percent")
    if [ "$MIN_COVERAGE" -gt 0 ]; then
        COVERAGE_INT=${COVERAGE%.*}  # Remove decimal part
        if [ "$COVERAGE_INT" -lt "$MIN_COVERAGE" ]; then
            echo "[metrics]   ⚠ Test coverage: ${COVERAGE}% (below ${MIN_COVERAGE}%)"
            WARNINGS=$((WARNINGS + 1))
        else
            echo "[metrics]   ✓ Test coverage: ${COVERAGE}%"
        fi
    fi
    
else
    echo "[metrics] (No threshold comparison - thresholds.json not found)"
fi

# Find most recent historical snapshot for trend analysis
LATEST_SNAPSHOT=$(ls -t "$METRICS_DIR/history/"*.json 2>/dev/null | head -1 || echo "")

if [ -n "$LATEST_SNAPSHOT" ] && [ -f "$LATEST_SNAPSHOT" ]; then
    echo "[metrics] "
    echo "[metrics] Trend Analysis:"
    
    PREV_FILES=$(get_json_value "$LATEST_SNAPSHOT" "total_files")
    PREV_DEPTH=$(get_json_value "$LATEST_SNAPSHOT" "max_directory_depth")
    PREV_CIRCULAR=$(get_json_value "$LATEST_SNAPSHOT" "circular_dependencies")
    
    if [ "$TOTAL_FILES" -gt "$PREV_FILES" ]; then
        DELTA=$((TOTAL_FILES - PREV_FILES))
        echo "[metrics]   ↑ Total files: +$DELTA since last snapshot"
    elif [ "$TOTAL_FILES" -lt "$PREV_FILES" ]; then
        DELTA=$((PREV_FILES - TOTAL_FILES))
        echo "[metrics]   ↓ Total files: -$DELTA since last snapshot"
    else
        echo "[metrics]   → Total files: stable"
    fi
    
    if [ "$CIRCULAR_DEPS" -gt "$PREV_CIRCULAR" ]; then
        DELTA=$((CIRCULAR_DEPS - PREV_CIRCULAR))
        echo "[metrics]   ↑ Circular dependencies: +$DELTA (CONCERNING)"
        WARNINGS=$((WARNINGS + 1))
    elif [ "$CIRCULAR_DEPS" -lt "$PREV_CIRCULAR" ]; then
        DELTA=$((PREV_CIRCULAR - CIRCULAR_DEPS))
        echo "[metrics]   ↓ Circular dependencies: -$DELTA (improved)"
    else
        echo "[metrics]   → Circular dependencies: stable"
    fi
fi

# Summary
echo "[metrics] ============================================"
if [ $FAILURES -gt 0 ]; then
    echo "[metrics] ✗ FAILED: $FAILURES metric(s) exceed thresholds"
    echo "[metrics] ⚠ WARNINGS: $WARNINGS"
    exit 2
elif [ $WARNINGS -gt 0 ]; then
    echo "[metrics] ⚠ WARNING: $WARNINGS metric(s) approaching thresholds"
    exit 1
else
    echo "[metrics] ✓ PASSED: All metrics within acceptable ranges"
    exit 0
fi
