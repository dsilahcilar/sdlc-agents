#!/usr/bin/env sh
#
# complete-task.sh - Mark a task as done
#
# Usage: ./complete-task.sh <task-file-path>
#

set -eu

TASK_FILE="${1:-}"

if [ -z "$TASK_FILE" ]; then
  echo "[complete-task] Usage: ./complete-task.sh <task-file-path>"
  echo "[complete-task] Example: ./complete-task.sh features/FEAT-001/tasks/T01-create-entity.md"
  exit 1
fi

sed_in_place() {
  file="$1"
  expr="$2"
  if sed --version >/dev/null 2>&1; then
    sed -i "$expr" "$file"
  else
    sed -i '' "$expr" "$file"
  fi
}

case "$TASK_FILE" in
  /*) ;;
  *)
    if [ -f "./agent-context/$TASK_FILE" ]; then
      TASK_FILE="./agent-context/$TASK_FILE"
    fi
    ;;
esac

if [ ! -f "$TASK_FILE" ]; then
  echo "[complete-task] ERROR: Task file not found: $TASK_FILE"
  exit 1
fi

current_status=$(grep -E '^status:' "$TASK_FILE" 2>/dev/null | head -1 | sed 's/status: *//' | tr -d '[:space:]')

if [ "$current_status" = "done" ]; then
  echo "[complete-task] Task is already done: $TASK_FILE"
  exit 0
fi

if [ "$current_status" = "blocked" ]; then
  echo "[complete-task] WARNING: Task is blocked, marking as done anyway"
fi

sed_in_place "$TASK_FILE" 's/^status: *.*/status: done/'

echo "[complete-task] Marked as done: $TASK_FILE"

FEATURE_DIR=$(dirname "$(dirname "$TASK_FILE")")
TASKS_DIR="$FEATURE_DIR/tasks"

if [ -d "$TASKS_DIR" ]; then
  done_count=0
  total_count=0

  for task in "$TASKS_DIR"/*.md; do
    [ -f "$task" ] || continue
    total_count=$((total_count + 1))
    status=$(grep -E '^status:' "$task" 2>/dev/null | head -1 | sed 's/status: *//' | tr -d '[:space:]')
    if [ "$status" = "done" ]; then
      done_count=$((done_count + 1))
    fi
  done

  echo "[complete-task] Feature progress: $done_count/$total_count tasks done"

  if [ "$total_count" -gt 0 ] && [ "$done_count" -eq "$total_count" ]; then
    echo "[complete-task] All tasks complete! Updating feature status to 'passing'"
    FEATURE_FILE="$FEATURE_DIR/feature.md"
    if [ -f "$FEATURE_FILE" ]; then
      sed_in_place "$FEATURE_FILE" 's/^status: *.*/status: passing/'
    fi
  fi
fi
