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
| Planning | @.sdlc-agents/planning-agent.md | Creates structured plans |
| Coding | @.sdlc-agents/coding-agent.md | Implements changes |
| Architect | @.sdlc-agents/architect-agent.md | Validates architecture |
| Code Review | @.sdlc-agents/codereview-agent.md | Reviews for quality |
| Retro | @.sdlc-agents/retro-agent.md | Captures lessons |
| Initializer | @.sdlc-agents/initializer-agent.md | Sets up project |

## Workflow

1. **Initialize**: Use @.sdlc-agents/initializer-agent.md for first-time setup
2. **Plan**: Use @.sdlc-agents/planning-agent.md to create feature plans
3. **Architect**: Have @.sdlc-agents/architect-agent.md review plans
4. **Code**: Use @.sdlc-agents/coding-agent.md to implement tasks
5. **Review**: Run @.sdlc-agents/codereview-agent.md on changes
6. **Learn**: Use @.sdlc-agents/retro-agent.md to capture lessons
EOF
    log_info "Created: $RULES_FILE"
fi

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
log_info "Cursor setup complete!"
echo ""
echo "✓ Created/updated .gitignore to exclude .sdlc-agents/"
echo ""
echo "Next steps:"
echo "  1. Open your project in Cursor"
echo "  2. Run the initializer agent by typing:"
echo "     '@.sdlc-agents/initializer-agent.md follow the instructions in this file'"
echo "  3. Start planning features with:"
echo "     '@.sdlc-agents/planning-agent.md create a plan for [feature description]'"
echo ""
