#!/usr/bin/env sh
set -eu

# =============================================================================
# SDLC Agent Harness - Project Initialization
# =============================================================================
# This script initializes the project environment and verifies baseline health.
# It should be idempotent - safe to run multiple times.
#
# Usage: ./harness/init-project.sh
# =============================================================================

echo "[init-project] Starting project initialization..."

# -----------------------------------------------------------------------------
# 1. Detect and install dependencies
# -----------------------------------------------------------------------------
echo "[init-project] Detecting build system..."

# Determine project root (go up two levels from harness directory)
PROJECT_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
echo "[init-project] Project root: $PROJECT_ROOT"

if [ -f "$PROJECT_ROOT/pom.xml" ]; then
    echo "[init-project] Detected Maven project"
    echo "[init-project] Running 'mvn -q -DskipTests compile'..."
    (cd "$PROJECT_ROOT" && mvn -q -DskipTests compile) || {
        echo "[init-project] WARNING: Maven compile failed"
    }
elif [ -f "$PROJECT_ROOT/build.gradle" ] || [ -f "$PROJECT_ROOT/build.gradle.kts" ]; then
    echo "[init-project] Detected Gradle project"
    echo "[init-project] Running './gradlew assemble'..."
    (cd "$PROJECT_ROOT" && ./gradlew assemble --quiet) || {
        echo "[init-project] WARNING: Gradle assemble failed"
    }
elif [ -f "$PROJECT_ROOT/package.json" ]; then
    echo "[init-project] Detected Node.js project"
    echo "[init-project] Running 'npm install'..."
    (cd "$PROJECT_ROOT" && npm install) || {
        echo "[init-project] WARNING: npm install failed"
    }
elif [ -f "$PROJECT_ROOT/Cargo.toml" ]; then
    echo "[init-project] Detected Rust project"
    echo "[init-project] Running 'cargo build'..."
    (cd "$PROJECT_ROOT" && cargo build --quiet) || {
        echo "[init-project] WARNING: cargo build failed"
    }
elif [ -f "$PROJECT_ROOT/go.mod" ]; then
    echo "[init-project] Detected Go project"
    echo "[init-project] Running 'go build ./...'..."
    (cd "$PROJECT_ROOT" && go build ./...) || {
        echo "[init-project] WARNING: go build failed"
    }
else
    echo "[init-project] No recognized build system found"
    echo "[init-project] Please customize this script for your project"
fi

# -----------------------------------------------------------------------------
# 2. Verify harness scripts exist
# -----------------------------------------------------------------------------
echo "[init-project] Verifying harness scripts..."

for script in run-feature.sh run-arch-tests.sh run-quality-gates.sh; do
    if [ -f "harness/$script" ]; then
        echo "[init-project] ✓ harness/$script exists"
        chmod +x "harness/$script"
    else
        echo "[init-project] ✗ harness/$script missing"
    fi
done

# -----------------------------------------------------------------------------
# 3. Run smoke tests
# -----------------------------------------------------------------------------
echo "[init-project] Running smoke tests..."

if [ -f "harness/run-arch-tests.sh" ]; then
    echo "[init-project] Running architecture tests..."
    ./harness/run-arch-tests.sh || {
        echo "[init-project] WARNING: Architecture tests had issues (may be expected on fresh project)"
    }
fi

# -----------------------------------------------------------------------------
# 4. Verify artifact directories
# -----------------------------------------------------------------------------
echo "[init-project] Verifying artifact directories..."

for dir in memory context features; do
    if [ -d "$dir" ]; then
        echo "[init-project] ✓ $dir/ exists"
    else
        echo "[init-project] Creating $dir/"
        mkdir -p "$dir"
    fi
done

# -----------------------------------------------------------------------------
# 5. Summary
# -----------------------------------------------------------------------------
echo ""
echo "[init-project] ============================================"
echo "[init-project] Initialization complete!"
echo "[init-project] ============================================"
echo ""
echo "[init-project] Next steps:"
echo "[init-project]   1. Create first feature in features/<feature-id>/"
echo "[init-project]   2. Customize harness scripts for your project"
echo "[init-project]   3. Add architecture tests to verify structure"
echo "[init-project]   4. Run ./harness/run-quality-gates.sh"
echo ""
