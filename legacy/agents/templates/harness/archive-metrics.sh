#!/usr/bin/env sh
set -eu

# =============================================================================
# SDLC Agent Harness - Metrics Archival
# =============================================================================
# Archives current metrics to history directory with timestamp.
# Implements retention policy to prevent unbounded growth.
#
# Retention Policy:
#   - Keep last 30 snapshots
#   - Older snapshots are automatically deleted
#
# Usage: ./harness/archive-metrics.sh
# =============================================================================

echo "[metrics] Archiving current metrics..."

# Determine project root
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
METRICS_DIR="$PROJECT_ROOT/agent-context/metrics"
HISTORY_DIR="$METRICS_DIR/history"
CURRENT_FILE="$METRICS_DIR/current.json"

# Check if current metrics exist
if [ ! -f "$CURRENT_FILE" ]; then
    echo "[metrics] ✗ WARNING: current.json not found. Nothing to archive."
    exit 0
fi

# Create history directory if it doesn't exist
mkdir -p "$HISTORY_DIR"

# Generate timestamp for snapshot filename
TIMESTAMP=$(date -u +"%Y-%m-%d-%H%M%S")
SNAPSHOT_FILE="$HISTORY_DIR/$TIMESTAMP.json"

# Copy current to history
cp "$CURRENT_FILE" "$SNAPSHOT_FILE"
echo "[metrics] ✓ Archived to: $SNAPSHOT_FILE"

# Implement retention policy - keep last 30 snapshots
SNAPSHOT_COUNT=$(ls -1 "$HISTORY_DIR"/*.json 2>/dev/null | wc -l | tr -d ' ')
RETENTION_LIMIT=30

if [ "$SNAPSHOT_COUNT" -gt "$RETENTION_LIMIT" ]; then
    SNAPSHOTS_TO_DELETE=$((SNAPSHOT_COUNT - RETENTION_LIMIT))
    echo "[metrics] Retention policy: keeping last $RETENTION_LIMIT snapshots, removing $SNAPSHOTS_TO_DELETE old snapshot(s)"
    
    # Delete oldest snapshots
    ls -t "$HISTORY_DIR"/*.json | tail -n "$SNAPSHOTS_TO_DELETE" | xargs rm -f
    echo "[metrics] ✓ Cleaned up old snapshots"
fi

echo "[metrics] Archive complete. Total snapshots: $(ls -1 "$HISTORY_DIR"/*.json 2>/dev/null | wc -l | tr -d ' ')"
