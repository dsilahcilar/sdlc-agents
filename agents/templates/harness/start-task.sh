#!/bin/bash
#
# start-task.sh - Mark a task as in_progress
#
# Usage: ./start-task.sh <task-file-path>
# Example: ./start-task.sh features/FEAT-001/tasks/T01-create-entity.md
#
# Updates the task's status from 'pending' to 'in_progress' in the frontmatter.
# Also updates the feature status to 'in_progress' if it was 'pending'.
#

set -e

TASK_FILE="$1"

if [ -z "$TASK_FILE" ]; then
    echo "[start-task] Usage: ./start-task.sh <task-file-path>"
    echo "[start-task] Example: ./start-task.sh features/FEAT-001/tasks/T01-create-entity.md"
    exit 1
fi

# Handle relative paths
if [[ ! "$TASK_FILE" = /* ]]; then
    if [ -f "./agent-context/$TASK_FILE" ]; then
        TASK_FILE="./agent-context/$TASK_FILE"
    fi
fi

if [ ! -f "$TASK_FILE" ]; then
    echo "[start-task] ERROR: Task file not found: $TASK_FILE"
    exit 1
fi

# Get current status
current_status=$(grep -E "^status:" "$TASK_FILE" 2>/dev/null | head -1 | sed 's/status: *//' | tr -d '[:space:]')

if [ "$current_status" = "in_progress" ]; then
    echo "[start-task] Task is already in progress: $TASK_FILE"
    exit 0
fi

if [ "$current_status" = "done" ]; then
    echo "[start-task] WARNING: Task is already done, not changing status"
    exit 0
fi

if [ "$current_status" = "blocked" ]; then
    echo "[start-task] Unblocking and starting task"
fi

# Update status to in_progress
if [[ "$OSTYPE" == "darwin"* ]]; then
    sed -i '' 's/^status: *.*/status: in_progress/' "$TASK_FILE"
else
    sed -i 's/^status: *.*/status: in_progress/' "$TASK_FILE"
fi

echo "[start-task] Started: $TASK_FILE"

# Update feature status to in_progress if it was pending
FEATURE_DIR=$(dirname "$(dirname "$TASK_FILE")")
FEATURE_FILE="$FEATURE_DIR/feature.md"

if [ -f "$FEATURE_FILE" ]; then
    feature_status=$(grep -E "^status:" "$FEATURE_FILE" 2>/dev/null | head -1 | sed 's/status: *//' | tr -d '[:space:]')
    if [ "$feature_status" = "pending" ]; then
        if [[ "$OSTYPE" == "darwin"* ]]; then
            sed -i '' 's/^status: *.*/status: in_progress/' "$FEATURE_FILE"
        else
            sed -i 's/^status: *.*/status: in_progress/' "$FEATURE_FILE"
        fi
        echo "[start-task] Updated feature status to 'in_progress'"
    fi
fi

# Show task summary
echo ""
echo "--- Task Summary ---"
grep -E "^# Task:" "$TASK_FILE" 2>/dev/null || true
echo ""
grep -A 5 "^## Objective" "$TASK_FILE" 2>/dev/null | head -5 || true
