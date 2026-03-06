#!/usr/bin/env sh
#
# list-features.sh - List all features and their status
#
# Usage: ./list-features.sh
#

set -eu

SCRIPT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
if [ -d "$SCRIPT_DIR/../features" ]; then
  FEATURES_DIR="$SCRIPT_DIR/../features"
elif [ -d "./agent-context/features" ]; then
  FEATURES_DIR="./agent-context/features"
else
  echo "[list-features] ERROR: Cannot find features directory"
  exit 1
fi

echo "=== Feature Status ==="
echo ""

total_features=0
pending_features=0
in_progress_features=0
passing_features=0
blocked_features=0

for feature_dir in "$FEATURES_DIR"/*; do
  [ -d "$feature_dir" ] || continue

  feature_file="$feature_dir/feature.md"
  tasks_dir="$feature_dir/tasks"

  [ -f "$feature_file" ] || continue
  total_features=$((total_features + 1))

  feature_id=$(grep -E '^id:' "$feature_file" 2>/dev/null | head -1 | sed 's/id: *//')
  title=$(grep -E '^title:' "$feature_file" 2>/dev/null | head -1 | sed 's/title: *//')
  status=$(grep -E '^status:' "$feature_file" 2>/dev/null | head -1 | sed 's/status: *//' | tr -d '[:space:]')
  risk=$(grep -E '^risk_level:' "$feature_file" 2>/dev/null | head -1 | sed 's/risk_level: *//' | tr -d '[:space:]')

  done_tasks=0
  pending_tasks=0
  in_progress_tasks=0
  blocked_tasks=0
  total_tasks=0

  if [ -d "$tasks_dir" ]; then
    for task_file in "$tasks_dir"/*.md; do
      [ -f "$task_file" ] || continue
      total_tasks=$((total_tasks + 1))
      task_status=$(grep -E '^status:' "$task_file" 2>/dev/null | head -1 | sed 's/status: *//' | tr -d '[:space:]')
      case "$task_status" in
        done) done_tasks=$((done_tasks + 1)) ;;
        pending) pending_tasks=$((pending_tasks + 1)) ;;
        in_progress) in_progress_tasks=$((in_progress_tasks + 1)) ;;
        blocked) blocked_tasks=$((blocked_tasks + 1)) ;;
      esac
    done
  fi

  case "$status" in
    pending)
      pending_features=$((pending_features + 1))
      status_icon="⏳"
      ;;
    in_progress)
      in_progress_features=$((in_progress_features + 1))
      status_icon="🔄"
      ;;
    passing)
      passing_features=$((passing_features + 1))
      status_icon="✅"
      ;;
    blocked)
      blocked_features=$((blocked_features + 1))
      status_icon="🚫"
      ;;
    *)
      status_icon="❓"
      ;;
  esac

  case "$risk" in
    high) risk_icon="🔴" ;;
    medium) risk_icon="🟡" ;;
    low) risk_icon="🟢" ;;
    *) risk_icon="⚪" ;;
  esac

  echo "$status_icon $feature_id: $title"
  echo "   Status: $status | Risk: $risk_icon $risk"
  echo "   Tasks: $done_tasks/$total_tasks done | $pending_tasks pending | $in_progress_tasks in progress | $blocked_tasks blocked"
  echo ""
done

if [ "$total_features" -eq 0 ]; then
  echo "No features found in $FEATURES_DIR"
  exit 0
fi

echo "=== Summary ==="
echo "Total: $total_features features"
echo "  ⏳ Pending: $pending_features"
echo "  🔄 In Progress: $in_progress_features"
echo "  ✅ Passing: $passing_features"
echo "  🚫 Blocked: $blocked_features"
