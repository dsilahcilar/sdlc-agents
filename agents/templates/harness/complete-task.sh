#!/bin/bash
#
# complete-task.sh - Mark a task as done
#
# Usage: ./complete-task.sh <task-file-path>
# Example: ./complete-task.sh features/FEAT-001/tasks/T01-create-entity.md
#
# Updates the task's status from 'in_progress' to 'done' in the frontmatter.
#

set -e

TASK_FILE="$1"

if [ -z "$TASK_FILE" ]; then
    echo "[complete-task] Usage: ./complete-task.sh <task-file-path>"
    echo "[complete-task] Example: ./complete-task.sh features/FEAT-001/tasks/T01-create-entity.md"
    exit 1
fi

# Handle relative paths
if [[ ! "$TASK_FILE" = /* ]]; then
    if [ -f "./agent-context/$TASK_FILE" ]; then
        TASK_FILE="./agent-context/$TASK_FILE"
    fi
fi

if [ ! -f "$TASK_FILE" ]; then
    echo "[complete-task] ERROR: Task file not found: $TASK_FILE"
    exit 1
fi

# Get current status
current_status=$(grep -E "^status:" "$TASK_FILE" 2>/dev/null | head -1 | sed 's/status: *//' | tr -d '[:space:]')

if [ "$current_status" = "done" ]; then
    echo "[complete-task] Task is already done: $TASK_FILE"
    exit 0
fi

if [ "$current_status" = "blocked" ]; then
    echo "[complete-task] WARNING: Task is blocked, marking as done anyway"
fi

# Update status to done
if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS
    sed -i '' 's/^status: *.*/status: done/' "$TASK_FILE"
else
    # Linux
    sed -i 's/^status: *.*/status: done/' "$TASK_FILE"
fi

echo "[complete-task] Marked as done: $TASK_FILE"

# Check if all tasks in feature are done
FEATURE_DIR=$(dirname "$(dirname "$TASK_FILE")")
TASKS_DIR="$FEATURE_DIR/tasks"

if [ -d "$TASKS_DIR" ]; then
    done_count=0
    total_count=0
    for task in $(ls "$TASKS_DIR"/*.md 2>/dev/null); do
        if [ -f "$task" ]; then
            total_count=$((total_count + 1))
            status=$(grep -E "^status:" "$task" 2>/dev/null | head -1 | sed 's/status: *//' | tr -d '[:space:]')
            if [ "$status" = "done" ]; then
                done_count=$((done_count + 1))
            fi
        fi
    done
    
    echo "[complete-task] Feature progress: $done_count/$total_count tasks done"
    
    if [ "$done_count" -eq "$total_count" ]; then
        echo "[complete-task] All tasks complete! Updating feature status to 'passing'"
        FEATURE_FILE="$FEATURE_DIR/feature.md"
        if [ -f "$FEATURE_FILE" ]; then
            if [[ "$OSTYPE" == "darwin"* ]]; then
                sed -i '' 's/^status: *.*/status: passing/' "$FEATURE_FILE"
            else
                sed -i 's/^status: *.*/status: passing/' "$FEATURE_FILE"
            fi
        fi
    fi
fi
