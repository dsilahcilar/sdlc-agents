#!/bin/bash
# Resolve skill names to file paths using skill-index.yaml
# Usage: resolve-skills.sh <skill-name> [<skill-name>...]
# Output: Skill file paths (one per line), warnings to stderr
#
# Examples:
#   resolve-skills.sh java
#   → /path/to/agents/skills/stacks/java.md
#
#   resolve-skills.sh unknown
#   → WARNING: Skill 'unknown' not found in skill-index.yaml
#
# Resolution order:
#   1. Custom skills (extensions/skills/skill-index.yaml)
#   2. Core skills (agents/skills/skill-index.yaml)
#
# Note: Uses grep-based parsing for portability (no yq/python required)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CORE_SKILLS_DIR="${SCRIPT_DIR}/../../skills"
CORE_INDEX="${CORE_SKILLS_DIR}/skill-index.yaml"

# Project root can be overridden via PROJECT_ROOT env var
PROJECT_ROOT="${PROJECT_ROOT:-$(pwd)}"
CUSTOM_INDEX="${PROJECT_ROOT}/agent-context/extensions/skills/skill-index.yaml"

# Simple YAML parser for our specific format
# Returns path for a skill name (direct match or alias)
find_skill_path() {
  local index_file="$1"
  local skill_name="$2"
  local base_dir="$3"
  
  if [[ ! -f "$index_file" ]]; then
    return 1
  fi
  
  skill_name=$(echo "$skill_name" | tr '[:upper:]' '[:lower:]')
  
  # Look for direct skill name match
  # Format: "  skillname:\n    path: something"
  local in_skill=false
  local current_skill=""
  local found_path=""
  
  while IFS= read -r line; do
    # Check for skill name (2 spaces + name + colon)
    if [[ "$line" =~ ^[[:space:]]{2}([a-z0-9_-]+):$ ]]; then
      in_skill=true
      current_skill="${BASH_REMATCH[1]}"
      found_path=""
    elif [[ "$line" =~ ^[[:space:]]{4}path:[[:space:]]*(.+)$ ]] && [[ "$in_skill" == "true" ]]; then
      found_path="${BASH_REMATCH[1]}"
      # Direct match
      if [[ "$current_skill" == "$skill_name" ]]; then
        echo "${base_dir}/${found_path}"
        return 0
      fi
    elif [[ "$line" =~ ^[[:space:]]{4}aliases:[[:space:]]*\[(.+)\]$ ]] && [[ "$in_skill" == "true" ]]; then
      local aliases="${BASH_REMATCH[1]}"
      # Check if skill_name is in aliases
      if echo "$aliases" | tr -d ' "' | tr ',' '\n' | grep -qx "$skill_name"; then
        if [[ -n "$found_path" ]]; then
          echo "${base_dir}/${found_path}"
          return 0
        fi
      fi
    fi
  done < "$index_file"
  
  return 1
}

resolve_skill() {
  local name="$1"
  name=$(echo "$name" | tr '[:upper:]' '[:lower:]')
  
  # Check custom index first (if exists)
  if local custom_path=$(find_skill_path "$CUSTOM_INDEX" "$name" "${PROJECT_ROOT}/agent-context/extensions/skills"); then
    echo "$custom_path"
    # Log if this overrides a core skill
    if find_skill_path "$CORE_INDEX" "$name" "$CORE_SKILLS_DIR" >/dev/null 2>&1; then
      echo "INFO: Custom skill '$name' overrides core skill" >&2
    fi
    return 0
  fi
  
  # Check core index
  if find_skill_path "$CORE_INDEX" "$name" "$CORE_SKILLS_DIR"; then
    return 0
  fi
  
  # Not found - output warning to stderr (warn and continue)
  echo "WARNING: Skill '$name' not found in skill-index.yaml" >&2
  return 1
}

# If no arguments, exit
if [[ $# -eq 0 ]]; then
  echo "Usage: resolve-skills.sh <skill-name> [<skill-name>...]" >&2
  exit 0
fi

# Resolve each skill, continue on failure (warn and continue behavior)
for skill in "$@"; do
  resolve_skill "$skill" || true
done
