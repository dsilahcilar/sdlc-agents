#!/bin/bash
#
# next-task.sh - Find the next pending task for a feature
#
# Usage: ./next-task.sh <feature-id>
# Example: ./next-task.sh FEAT-001
#
# Returns the path to the next pending task file, or exits with error if none found.
#

set -e

FEATURE_ID="$1"

if [ -z "$FEATURE_ID" ]; then
    echo "[next-task] Usage: ./next-task.sh <feature-id>"
    echo "[next-task] Example: ./next-task.sh FEAT-001"
    exit 1
fi

# Find features directory (handle both harness location and project root)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -d "$SCRIPT_DIR/../features" ]; then
    FEATURES_DIR="$SCRIPT_DIR/../features"
elif [ -d "./agent-context/features" ]; then
    FEATURES_DIR="./agent-context/features"
else
    echo "[next-task] ERROR: Cannot find features directory"
    exit 1
fi

FEATURE_DIR="$FEATURES_DIR/$FEATURE_ID"
TASKS_DIR="$FEATURE_DIR/tasks"

if [ ! -d "$FEATURE_DIR" ]; then
    echo "[next-task] ERROR: Feature directory not found: $FEATURE_DIR"
    exit 1
fi

if [ ! -d "$TASKS_DIR" ]; then
    echo "[next-task] ERROR: Tasks directory not found: $TASKS_DIR"
    exit 1
fi

# Find first task with status: pending (sorted by filename for priority)
for task_file in $(ls "$TASKS_DIR"/*.md 2>/dev/null | sort); do
    if [ -f "$task_file" ]; then
        # Check if status is pending in frontmatter
        status=$(grep -E "^status:" "$task_file" 2>/dev/null | head -1 | sed 's/status: *//' | tr -d '[:space:]')
        if [ "$status" = "pending" ]; then
            echo "$task_file"
            exit 0
        fi
    fi
done

# Check if all tasks are done
done_count=0
total_count=0
for task_file in $(ls "$TASKS_DIR"/*.md 2>/dev/null); do
    if [ -f "$task_file" ]; then
        total_count=$((total_count + 1))
        status=$(grep -E "^status:" "$task_file" 2>/dev/null | head -1 | sed 's/status: *//' | tr -d '[:space:]')
        if [ "$status" = "done" ]; then
            done_count=$((done_count + 1))
        fi
    fi
done

if [ "$done_count" -eq "$total_count" ] && [ "$total_count" -gt 0 ]; then
    echo "[next-task] All $total_count tasks are done for $FEATURE_ID"
    exit 0
fi

echo "[next-task] No pending tasks found for $FEATURE_ID"
echo "[next-task] Tasks: $done_count done, $((total_count - done_count)) in other states"
exit 1
