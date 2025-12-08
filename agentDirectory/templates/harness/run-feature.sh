#!/usr/bin/env sh
set -eu

# =============================================================================
# SDLC Agent Harness - Feature Test Runner
# =============================================================================
# Runs tests specific to a feature ID.
# Used by Coding Agent after implementing each feature task.
#
# Usage: ./harness/run-feature.sh <feature-id>
# =============================================================================

FEATURE_ID="${1:-}"

if [ -z "$FEATURE_ID" ]; then
    echo "Usage: $0 <feature-id>"
    echo ""
    echo "Examples:"
    echo "  $0 FEAT-123"
    echo "  $0 user-authentication"
    echo ""
    echo "The feature ID should match an entry in harness/feature-requirements.json"
    exit 1
fi

echo "[run-feature] ============================================"
echo "[run-feature] Running tests for feature: $FEATURE_ID"
echo "[run-feature] ============================================"

# -----------------------------------------------------------------------------
# 1. Look up feature in requirements
# -----------------------------------------------------------------------------
if [ -f "harness/feature-requirements.json" ]; then
    if command -v jq >/dev/null 2>&1; then
        FEATURE_MODULE=$(jq -r ".features[] | select(.id == \"$FEATURE_ID\") | .module" harness/feature-requirements.json 2>/dev/null || echo "")
        if [ -n "$FEATURE_MODULE" ] && [ "$FEATURE_MODULE" != "null" ]; then
            echo "[run-feature] Feature module: $FEATURE_MODULE"
        fi
    else
        echo "[run-feature] jq not available, running full test suite"
    fi
else
    echo "[run-feature] feature-requirements.json not found"
fi

# -----------------------------------------------------------------------------
# 2. Run tests based on build system
# -----------------------------------------------------------------------------
echo "[run-feature] Detecting build system and running tests..."

if [ -f "pom.xml" ]; then
    echo "[run-feature] Running Maven tests..."
    # Try to filter by module/package if available
    if [ -n "${FEATURE_MODULE:-}" ]; then
        mvn test -pl "$FEATURE_MODULE" -am 2>/dev/null || mvn test
    else
        mvn test
    fi
elif [ -f "build.gradle" ] || [ -f "build.gradle.kts" ]; then
    echo "[run-feature] Running Gradle tests..."
    if [ -n "${FEATURE_MODULE:-}" ]; then
        ./gradlew ":$FEATURE_MODULE:test" 2>/dev/null || ./gradlew test
    else
        ./gradlew test
    fi
elif [ -f "package.json" ]; then
    echo "[run-feature] Running npm tests..."
    npm test
elif [ -f "Cargo.toml" ]; then
    echo "[run-feature] Running cargo tests..."
    cargo test
elif [ -f "go.mod" ]; then
    echo "[run-feature] Running go tests..."
    go test ./...
else
    echo "[run-feature] No recognized build system found"
    echo "[run-feature] Please customize this script for your project"
    exit 1
fi

# -----------------------------------------------------------------------------
# 3. Summary
# -----------------------------------------------------------------------------
echo ""
echo "[run-feature] ============================================"
echo "[run-feature] Feature tests completed for: $FEATURE_ID"
echo "[run-feature] ============================================"
