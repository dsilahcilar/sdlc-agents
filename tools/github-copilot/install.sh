#!/bin/sh
#
# GitHub Copilot Install Script
# Creates .github/agents/*.agent.md files and symlinks .agents/
#
# Usage: ./install.sh --target /path/to/project [--copy]
#

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() { printf "${GREEN}[INFO]${NC} %s\n" "$1"; }
log_warn() { printf "${YELLOW}[WARN]${NC} %s\n" "$1"; }
log_error() { printf "${RED}[ERROR]${NC} %s\n" "$1"; }

usage() {
    echo "Usage: $0 --target <project-path> [--copy]"
    echo ""
    echo "Options:"
    echo "  --target <path>   Target project directory (required)"
    echo "  --copy            Copy agents instead of symlinking"
    echo "  -h, --help        Show this help"
    exit 1
}

# Parse arguments
TARGET=""
COPY_MODE=false

while [ $# -gt 0 ]; do
    case "$1" in
        --target) TARGET="$2"; shift 2 ;;
        --copy) COPY_MODE=true; shift ;;
        -h|--help) usage ;;
        *) log_error "Unknown option: $1"; usage ;;
    esac
done

if [ -z "$TARGET" ]; then
    log_error "Missing required --target argument"
    usage
fi

# Resolve paths
SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
SDLC_AGENTS=$(cd "$SCRIPT_DIR/../.." && pwd)
TARGET=$(cd "$TARGET" 2>/dev/null && pwd) || {
    log_error "Target directory does not exist: $TARGET"
    exit 1
}

echo ""
echo "========================================"
echo "  SDLC Agents - GitHub Copilot Setup"
echo "========================================"
echo "  Source:  $SDLC_AGENTS"
echo "  Target:  $TARGET"
echo "  Mode:    $([ "$COPY_MODE" = true ] && echo 'copy' || echo 'symlink')"
echo "========================================"
echo ""

# Create .github/agents directory
AGENTS_DIR="$TARGET/.github/agents"
mkdir -p "$AGENTS_DIR"

# Helper function to create agent file
create_agent_file() {
    local agent_name="$1"
    local agent_title="$2"
    local agent_desc="$3"
    local agent_file="$AGENTS_DIR/${agent_name}.agent.md"
    
    if [ -f "$agent_file" ]; then
        log_warn "File exists, skipping: $agent_file"
        return
    fi
    
    cat > "$agent_file" <<EOF
---
name: ${agent_name}
description: ${agent_desc}
---

# ${agent_title}

This agent is part of the SDLC Agents system for structured, architecture-aware development.

## Instructions

The complete instructions for this agent are located in:
\`.agents/${agent_name}.md\`

Please read and follow those instructions carefully.

## Agent Context

This agent operates within the SDLC Agents workflow:
- **Input**: Receives context from previous agents or user requests
- **Process**: Follows the workflow defined in \`.agents/${agent_name}.md\`
- **Output**: Produces artifacts for downstream agents or final deliverables

## Extensions

Check for project-specific customizations:
1. **Global rules**: \`agent-context/extensions/_all-agents/*.md\`
2. **Agent-specific**: \`agent-context/extensions/${agent_name}/*.md\`

Custom instructions take precedence over core behavior.
EOF
    
    log_info "Created: $agent_file"
}

# Create individual agent files
create_agent_file "planning-agent" "Planning Agent" "Transforms requests into structured, architecture-aware plans with isolated tasks"
create_agent_file "coding-agent" "Coding Agent" "Implements ONE task at a time from a self-contained task file"
create_agent_file "architect-agent" "Architect Agent" "Evaluates feature plans for structural integrity, modularity, and maintainability"
create_agent_file "codereview-agent" "Code Review Agent" "Reviews code for quality, debt, and architectural violations"
create_agent_file "retro-agent" "Retro Agent" "Extracts lessons learned from completed work"
create_agent_file "curator-agent" "Curator Agent" "Maintains knowledge quality and prevents playbook bloat"
create_agent_file "initializer-agent" "Initializer Agent" "Sets up project structure and discovers existing architecture"

# Link or copy .agents directory (hidden)
AGENTS_TARGET="$TARGET/.agents"
if [ -e "$AGENTS_TARGET" ]; then
    log_warn ".agents directory exists, skipping: $AGENTS_TARGET"
else
    if [ "$COPY_MODE" = true ]; then
        cp -r "$SDLC_AGENTS/agents" "$AGENTS_TARGET"
        log_info "Copied agents to: $AGENTS_TARGET"
    else
        ln -s "$SDLC_AGENTS/agents" "$AGENTS_TARGET"
        log_info "Symlinked agents to: $AGENTS_TARGET"
    fi
fi

# Update .gitignore to exclude .agents directory
GITIGNORE_FILE="$TARGET/.gitignore"
if [ -f "$GITIGNORE_FILE" ]; then
    if grep -q "^\.agents/?$" "$GITIGNORE_FILE" 2>/dev/null; then
        log_info ".gitignore already contains .agents entry"
    else
        echo "" >> "$GITIGNORE_FILE"
        echo "# SDLC Agents (symlinked directory)" >> "$GITIGNORE_FILE"
        echo ".agents/" >> "$GITIGNORE_FILE"
        log_info "Added .agents/ to .gitignore"
    fi
else
    cat > "$GITIGNORE_FILE" <<'EOF'
# SDLC Agents (symlinked directory)
.agents/
EOF
    log_info "Created .gitignore with .agents/ entry"
fi

echo ""
log_info "GitHub Copilot setup complete!"
echo ""
echo "✓ Created .github/agents/ with individual agent files"
echo "✓ Created/updated .gitignore to exclude .agents/"
echo "✓ Agents are accessible via VS Code UI agent picker"
echo ""
echo "Next steps:"
echo "  1. Open GitHub Copilot Chat in VS Code"
echo "  2. Click the agent picker (@ icon) to select an agent"
echo "  3. Start with initializer-agent to set up project structure"
echo ""
