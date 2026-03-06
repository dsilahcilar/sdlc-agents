#!/bin/bash
# Parse skill directives from a user prompt
# Usage: parse-skill-directives.sh "<prompt>"
# Output: JSON with includes, excludes, only_mode

set -euo pipefail

PROMPT="${1:-}"

if [[ -z "$PROMPT" ]]; then
  echo '{"error": "No prompt provided", "includes": [], "excludes": [], "only_mode": false}' >&2
  exit 1
fi

if ! command -v jq >/dev/null 2>&1; then
  echo '{"error": "jq is required but not installed"}' >&2
  exit 1
fi

validate_skill_name() {
  local name="$1"
  if [[ ! "$name" =~ ^[a-zA-Z][a-zA-Z0-9_-]*$ ]]; then
    echo "ERROR: Invalid skill name '$name' (must start with letter, alphanumeric + dash/underscore only)" >&2
    return 1
  fi
}

append_csv() {
  local current="$1"
  local value="$2"
  if [[ -z "$current" ]]; then
    printf '%s' "$value"
  else
    printf '%s,%s' "$current" "$value"
  fi
}

to_json_array() {
  local input="$1"
  if [[ -z "$input" ]]; then
    echo "[]"
    return 0
  fi

  local normalized=()
  local raw=()
  local skill=""
  IFS=',' read -r -a raw <<< "$input"

  for skill in "${raw[@]}"; do
    skill=$(echo "$skill" | xargs)
    if [[ -z "$skill" ]]; then
      continue
    fi

    validate_skill_name "$skill" || exit 1
    normalized+=("$(echo "$skill" | tr '[:upper:]' '[:lower:]')")
  done

  if [[ ${#normalized[@]} -eq 0 ]]; then
    echo "[]"
    return 0
  fi

  printf '%s\n' "${normalized[@]}" | sort -u | jq -R . | jq -s .
}

ONLY_MODE=false
ONLY_FULL=""
ONLY_SKILLS=""

if [[ "$PROMPT" =~ \#only: ]]; then
  if [[ "$PROMPT" =~ \#only:([a-zA-Z][a-zA-Z0-9_-]*(,[[:space:]]*[a-zA-Z][a-zA-Z0-9_-]*)*) ]]; then
    ONLY_MODE=true
    ONLY_FULL="${BASH_REMATCH[0]}"
    ONLY_SKILLS="${BASH_REMATCH[1]}"
  else
    echo '{"error": "Malformed #only directive. Use #only:Skill1,Skill2"}' >&2
    exit 1
  fi
fi

INCLUDES=""
WORK_PROMPT="$PROMPT"
if [[ -n "$ONLY_FULL" ]]; then
  WORK_PROMPT="${WORK_PROMPT/"$ONLY_FULL"/ }"
fi

include_guard=0
while [[ "$WORK_PROMPT" =~ \#([a-zA-Z][a-zA-Z0-9_-]*(,[[:space:]]*[a-zA-Z][a-zA-Z0-9_-]*)*) ]]; do
  MATCH="${BASH_REMATCH[1]}"
  FULL_MATCH="${BASH_REMATCH[0]}"
  INCLUDES=$(append_csv "$INCLUDES" "$MATCH")
  WORK_PROMPT="${WORK_PROMPT/"$FULL_MATCH"/ }"
  include_guard=$((include_guard + 1))
  if [[ "$include_guard" -gt 100 ]]; then
    echo '{"error": "Failed to parse includes safely (loop guard triggered)"}' >&2
    exit 1
  fi
done

EXCLUDES=""
EXCLUDE_PROMPT="$PROMPT"
if [[ -n "$ONLY_FULL" ]]; then
  EXCLUDE_PROMPT="${EXCLUDE_PROMPT/"$ONLY_FULL"/ }"
fi

exclude_guard=0
while [[ "$EXCLUDE_PROMPT" =~ \!([a-zA-Z][a-zA-Z0-9_-]*(,[[:space:]]*[a-zA-Z][a-zA-Z0-9_-]*)*) ]]; do
  MATCH="${BASH_REMATCH[1]}"
  FULL_MATCH="${BASH_REMATCH[0]}"
  EXCLUDES=$(append_csv "$EXCLUDES" "$MATCH")
  EXCLUDE_PROMPT="${EXCLUDE_PROMPT/"$FULL_MATCH"/ }"
  exclude_guard=$((exclude_guard + 1))
  if [[ "$exclude_guard" -gt 100 ]]; then
    echo '{"error": "Failed to parse excludes safely (loop guard triggered)"}' >&2
    exit 1
  fi
done

if [[ "$ONLY_MODE" == "true" ]]; then
  INCLUDES_JSON=$(to_json_array "$ONLY_SKILLS")
else
  INCLUDES_JSON=$(to_json_array "$INCLUDES")
fi
EXCLUDES_JSON=$(to_json_array "$EXCLUDES")

jq -n \
  --argjson includes "$INCLUDES_JSON" \
  --argjson excludes "$EXCLUDES_JSON" \
  --argjson only_mode "$ONLY_MODE" \
  '{includes: $includes, excludes: $excludes, only_mode: $only_mode}'
