#!/bin/sh
#
# Claude Code Install Script
# Creates .claude/agents/ subagents
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
echo "  SDLC Agents - Claude Code Setup"
echo "========================================"
echo "  Source:  $SDLC_AGENTS"
echo "  Target:  $TARGET"
echo "  Mode:    $([ "$COPY_MODE" = true ] && echo 'copy' || echo 'symlink')"
echo "========================================"
echo ""

# Create .claude/agents directory
AGENTS_DIR="$TARGET/.claude/agents"
mkdir -p "$AGENTS_DIR"

# Helper function to create subagent file
create_subagent() {
    local agent_name="$1"
    local agent_desc="$2"
    local agent_file="$AGENTS_DIR/${agent_name}.md"
    
    if [ -f "$agent_file" ]; then
        log_warn "File exists, skipping: $agent_file"
        return
    fi
    
    cat > "$agent_file" <<EOF
---
name: ${agent_name}
description: ${agent_desc}
---

Read and follow the instructions in \`.sdlc-agents/${agent_name}.md\`.

This agent is part of the SDLC Agents system for structured, architecture-aware development.
EOF
    
    log_info "Created subagent: $agent_file"
}

# Create individual subagent files
create_subagent "planning-agent" "Use to create structured, architecture-aware plans with isolated tasks"
create_subagent "coding-agent" "Use to implement ONE task at a time from a self-contained task file"
create_subagent "architect-agent" "Use to evaluate feature plans for structural integrity and maintainability"
create_subagent "codereview-agent" "Use proactively after code changes to review for quality, debt, and violations"
create_subagent "retro-agent" "Use after completing features to extract lessons learned"
create_subagent "curator-agent" "Use to maintain knowledge quality and prevent playbook bloat"
create_subagent "initializer-agent" "Use for first-time project setup to discover architecture"

# Link or copy .sdlc-agents directory (hidden)
AGENTS_TARGET="$TARGET/.sdlc-agents"
if [ -e "$AGENTS_TARGET" ]; then
    log_warn ".sdlc-agents directory exists, skipping: $AGENTS_TARGET"
else
    if [ "$COPY_MODE" = true ]; then
        cp -r "$SDLC_AGENTS/agents" "$AGENTS_TARGET"
        log_info "Copied agents to: $AGENTS_TARGET"
    else
        ln -s "$SDLC_AGENTS/agents" "$AGENTS_TARGET"
        log_info "Symlinked agents to: $AGENTS_TARGET"
    fi
fi

# Update .gitignore to exclude .sdlc-agents directory
GITIGNORE_FILE="$TARGET/.gitignore"
if [ -f "$GITIGNORE_FILE" ]; then
    if grep -q "^\.sdlc-agents/?$" "$GITIGNORE_FILE" 2>/dev/null; then
        log_info ".gitignore already contains .sdlc-agents entry"
    else
        echo "" >> "$GITIGNORE_FILE"
        echo "# SDLC Agents (symlinked directory)" >> "$GITIGNORE_FILE"
        echo ".sdlc-agents/" >> "$GITIGNORE_FILE"
        log_info "Added .sdlc-agents/ to .gitignore"
    fi
else
    cat > "$GITIGNORE_FILE" <<'EOF'
# SDLC Agents (symlinked directory)
.sdlc-agents/
EOF
    log_info "Created .gitignore with .sdlc-agents/ entry"
fi

echo ""
log_info "Claude Code setup complete!"
echo ""
echo "✓ Created .claude/agents/ with 7 subagents"
echo "✓ Created/updated .gitignore to exclude .sdlc-agents/"
echo ""
echo "Next steps:"
echo "  1. Run: /agents to see all available subagents"
echo "  2. Run the initializer agent by typing:"
echo "     'Follow the instructions in the .sdlc-agents/initializer-agent.md file'"
echo "  3. Start planning features with:"
echo "     '@agent-planning-agent create a plan for [feature description]'"
echo ""
