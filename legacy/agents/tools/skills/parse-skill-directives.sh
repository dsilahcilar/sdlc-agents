#!/bin/bash
# Parse skill directives from a user prompt
# Usage: parse-skill-directives.sh "<prompt>"
# Output: JSON with includes, excludes, only_mode
#
# Examples:
#   parse-skill-directives.sh "Implement auth #TDD,Security !Kafka"
#   → {"includes": ["tdd", "security"], "excludes": ["kafka"], "only_mode": false}
#
#   parse-skill-directives.sh "Write tests #only:TDD"
#   → {"includes": ["tdd"], "excludes": [], "only_mode": true}

set -euo pipefail

PROMPT="${1:-}"

if [[ -z "$PROMPT" ]]; then
  echo '{"error": "No prompt provided", "includes": [], "excludes": [], "only_mode": false}'
  exit 1
fi

# Check for jq dependency
if ! command -v jq &> /dev/null; then
  echo '{"error": "jq is required but not installed"}' >&2
  exit 1
fi

# Validate skill name syntax
validate_skill_name() {
  local name="$1"
  if [[ ! "$name" =~ ^[a-zA-Z][a-zA-Z0-9_-]*$ ]]; then
    echo "ERROR: Invalid skill name '$name' (must start with letter, alphanumeric + dash/underscore only)" >&2
    return 1
  fi
}

# Extract #only: directive (disables auto-detection)
ONLY_MODE=false
ONLY_SKILLS=""
if [[ "$PROMPT" =~ \#only:([a-zA-Z0-9_,-]+) ]]; then
  ONLY_MODE=true
  ONLY_SKILLS="${BASH_REMATCH[1]}"
fi

# Extract regular includes (#Skill or #Skill1,Skill2)
# Exclude #only: matches
INCLUDES=""
TEMP_PROMPT="$PROMPT"
while [[ "$TEMP_PROMPT" =~ \#([a-zA-Z][a-zA-Z0-9_,-]*) ]]; do
  MATCH="${BASH_REMATCH[1]}"
  # Skip if it's an #only: directive
  if [[ ! "$MATCH" =~ ^only: ]]; then
    if [[ -n "$INCLUDES" ]]; then
      INCLUDES="$INCLUDES,$MATCH"
    else
      INCLUDES="$MATCH"
    fi
  fi
  # Remove matched portion to find next
  TEMP_PROMPT="${TEMP_PROMPT//#$MATCH/}"
done

# Extract excludes (!Skill or !Skill1,Skill2)
EXCLUDES=""
TEMP_PROMPT="$PROMPT"
while [[ "$TEMP_PROMPT" =~ \!([a-zA-Z][a-zA-Z0-9_,-]*) ]]; do
  MATCH="${BASH_REMATCH[1]}"
  if [[ -n "$EXCLUDES" ]]; then
    EXCLUDES="$EXCLUDES,$MATCH"
  else
    EXCLUDES="$MATCH"
  fi
  TEMP_PROMPT="${TEMP_PROMPT//!$MATCH/}"
done

# Convert comma-separated to JSON arrays (lowercase, deduplicated)
to_json_array() {
  local input="$1"
  if [[ -z "$input" ]]; then
    echo "[]"
  else
    # Split on commas and validate each skill name
    local skills
    IFS=',' read -ra skills <<< "$input"
    for skill in "${skills[@]}"; do
      # Trim whitespace
      skill=$(echo "$skill" | xargs)
      validate_skill_name "$skill" || exit 1
    done
    # Convert to JSON array (lowercase, deduplicated)
    echo "$input" | tr ',' '\n' | tr '[:upper:]' '[:lower:]' | sort -u | jq -R . | jq -s .
  fi
}

# Build output JSON
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
