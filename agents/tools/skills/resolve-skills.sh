#!/bin/bash
# Resolve skill names to file paths using skill-index.yaml
# Usage: resolve-skills.sh [--agent <role>] <skill-name> [<skill-name>...]
# Output: Skill file paths (one per line), warnings to stderr
#
# Examples:
#   resolve-skills.sh java
#   → /path/to/agents/skills/stacks/java.md
#
#   resolve-skills.sh --agent planning spec-driven
#   → /path/to/agents/skills/patterns/spec-driven/_index.md
#   → /path/to/agents/skills/patterns/spec-driven/planning.md
#
#   resolve-skills.sh unknown
#   → WARNING: Skill 'unknown' not found in skill-index.yaml
#
# Resolution order:
#   1. Custom skills (extensions/skills/skill-index.yaml)
#   2. Core skills (agents/skills/skill-index.yaml)
#
# Agent roles: planning, architect, coding, review
#
# Note: Uses grep-based parsing for portability (no yq/python required)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CORE_SKILLS_DIR="${SCRIPT_DIR}/../../skills"
CORE_INDEX="${CORE_SKILLS_DIR}/skill-index.yaml"

# Project root can be overridden via PROJECT_ROOT env var
PROJECT_ROOT="${PROJECT_ROOT:-$(pwd)}"
CUSTOM_INDEX="${PROJECT_ROOT}/agent-context/extensions/skills/skill-index.yaml"

# Agent role (empty = return all files for multi-file skills)
AGENT_ROLE=""

# Valid agent roles
VALID_ROLES=("planning" "architect" "coding" "review")

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

# Expand skill path based on whether it's a file or directory
# For directories (multi-file skills): return _index.md + role-specific file
# For files (single-file skills): return the file
expand_skill_path() {
  local skill_path="$1"
  
  # Check if path is a directory (multi-file skill)
  if [[ -d "$skill_path" ]]; then
    # Always output _index.md if it exists
    if [[ -f "${skill_path}/_index.md" ]]; then
      echo "${skill_path}/_index.md"
    fi
    
    if [[ -n "$AGENT_ROLE" ]]; then
      # Agent-specific: return only role file
      local role_file="${skill_path}/${AGENT_ROLE}.md"
      if [[ -f "$role_file" ]]; then
        echo "$role_file"
      else
        echo "WARNING: No ${AGENT_ROLE}.md found in multi-file skill: $skill_path" >&2
      fi
    else
      # No agent specified: return all role files
      for role in "${VALID_ROLES[@]}"; do
        local role_file="${skill_path}/${role}.md"
        if [[ -f "$role_file" ]]; then
          echo "$role_file"
        fi
      done
    fi
  elif [[ -f "$skill_path" ]]; then
    # Single-file skill: return as-is
    echo "$skill_path"
  elif [[ -f "${skill_path}.md" ]]; then
    # Path without .md extension, try adding it
    echo "${skill_path}.md"
  else
    echo "WARNING: Skill path not found: $skill_path" >&2
    return 1
  fi
}

resolve_skill() {
  local name="$1"
  name=$(echo "$name" | tr '[:upper:]' '[:lower:]')
  
  local skill_path=""
  
  # Check custom index first (if exists)
  if skill_path=$(find_skill_path "$CUSTOM_INDEX" "$name" "${PROJECT_ROOT}/agent-context/extensions/skills"); then
    # Log if this overrides a core skill
    if find_skill_path "$CORE_INDEX" "$name" "$CORE_SKILLS_DIR" >/dev/null 2>&1; then
      echo "INFO: Custom skill '$name' overrides core skill" >&2
    fi
    expand_skill_path "$skill_path"
    return 0
  fi
  
  # Check core index
  if skill_path=$(find_skill_path "$CORE_INDEX" "$name" "$CORE_SKILLS_DIR"); then
    expand_skill_path "$skill_path"
    return 0
  fi
  
  # Not found - output warning to stderr (warn and continue)
  echo "WARNING: Skill '$name' not found in skill-index.yaml" >&2
  return 1
}

# Parse arguments
show_usage() {
  echo "Usage: resolve-skills.sh [--agent <role>] <skill-name> [<skill-name>...]" >&2
  echo "" >&2
  echo "Options:" >&2
  echo "  --agent <role>  Load only files for specified agent role" >&2
  echo "                  Valid roles: ${VALID_ROLES[*]}" >&2
  echo "" >&2
  echo "For multi-file skills (directories):" >&2
  echo "  With --agent:    Returns _index.md + <role>.md" >&2
  echo "  Without --agent: Returns _index.md + all role files" >&2
}

# If no arguments, exit
if [[ $# -eq 0 ]]; then
  show_usage
  exit 0
fi

# Parse --agent flag
SKILLS=()
while [[ $# -gt 0 ]]; do
  case $1 in
    --agent)
      if [[ $# -lt 2 ]]; then
        echo "ERROR: --agent requires a role argument" >&2
        exit 1
      fi
      AGENT_ROLE=$(echo "$2" | tr '[:upper:]' '[:lower:]')
      # Validate role
      valid=false
      for role in "${VALID_ROLES[@]}"; do
        if [[ "$AGENT_ROLE" == "$role" ]]; then
          valid=true
          break
        fi
      done
      if [[ "$valid" != "true" ]]; then
        echo "WARNING: Unknown agent role '$AGENT_ROLE'. Valid roles: ${VALID_ROLES[*]}" >&2
      fi
      shift 2
      ;;
    --help|-h)
      show_usage
      exit 0
      ;;
    *)
      SKILLS+=("$1")
      shift
      ;;
  esac
done

# Resolve each skill, continue on failure (warn and continue behavior)
for skill in "${SKILLS[@]}"; do
  resolve_skill "$skill" || true
done
