#!/bin/sh
#
# Cursor Install Script
# Creates .cursor/rules/sdlc-agents.mdc
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
echo "  SDLC Agents - Cursor Setup"
echo "========================================"
echo "  Source:  $SDLC_AGENTS"
echo "  Target:  $TARGET"
echo "  Mode:    $([ "$COPY_MODE" = true ] && echo 'copy' || echo 'symlink')"
echo "========================================"
echo ""

# Create .cursor/rules directory
RULES_DIR="$TARGET/.cursor/rules"
mkdir -p "$RULES_DIR"

# Create sdlc-agents.mdc rule file
RULES_FILE="$RULES_DIR/sdlc-agents.mdc"
if [ -f "$RULES_FILE" ]; then
    log_warn "File exists, skipping: $RULES_FILE"
else
    cat > "$RULES_FILE" << 'EOF'
---
description: SDLC Agents - Structured development workflow agents
globs: ["**/*"]
alwaysApply: true
---
# SDLC Agents

This project uses SDLC Agents for structured, architecture-aware development.

## Available Agents

Reference these agent files for specialized workflows:

| Agent | File | Purpose |
|-------|------|---------|
| Planning | @agents/planning-agent.md | Creates structured plans |
| Coding | @agents/coding-agent.md | Implements changes |
| Architect | @agents/architect-agent.md | Validates architecture |
| Code Review | @agents/codereview-agent.md | Reviews for quality |
| Retro | @agents/retro-agent.md | Captures lessons |
| Initializer | @agents/initializer-agent.md | Sets up project |

## Workflow

1. **Initialize**: Use @agents/initializer-agent.md for first-time setup
2. **Plan**: Use @agents/planning-agent.md to create feature plans
3. **Architect**: Have @agents/architect-agent.md review plans
4. **Code**: Use @agents/coding-agent.md to implement tasks
5. **Review**: Run @agents/codereview-agent.md on changes
6. **Learn**: Use @agents/retro-agent.md to capture lessons
EOF
    log_info "Created: $RULES_FILE"
fi

# Link or copy agents directory
AGENTS_TARGET="$TARGET/agents"
if [ -e "$AGENTS_TARGET" ]; then
    log_warn "Agents directory exists, skipping: $AGENTS_TARGET"
else
    if [ "$COPY_MODE" = true ]; then
        cp -r "$SDLC_AGENTS/agents" "$AGENTS_TARGET"
        log_info "Copied agents to: $AGENTS_TARGET"
    else
        ln -s "$SDLC_AGENTS/agents" "$AGENTS_TARGET"
        log_info "Symlinked agents to: $AGENTS_TARGET"
    fi
fi

echo ""
log_info "Cursor setup complete!"
echo ""
echo "Next steps:"
echo "  1. Reference @agents/initializer-agent.md to set up"
echo "  2. Use @agents/planning-agent.md to start planning"
echo ""
