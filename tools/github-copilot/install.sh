#!/bin/sh
#
# GitHub Copilot Install Script
# Creates .github/copilot-instructions.md and symlinks agents/
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

# Create .github directory
GITHUB_DIR="$TARGET/.github"
mkdir -p "$GITHUB_DIR"

# Create copilot-instructions.md
INSTRUCTIONS_FILE="$GITHUB_DIR/copilot-instructions.md"
if [ -f "$INSTRUCTIONS_FILE" ]; then
    log_warn "File exists, skipping: $INSTRUCTIONS_FILE"
else
    cat > "$INSTRUCTIONS_FILE" << 'EOF'
# SDLC Agents

This project uses SDLC Agents for structured, architecture-aware development.

## Available Agents

| Agent | Purpose |
|-------|---------|
| @planning-agent | Creates structured, implementable plans |
| @coding-agent | Implements code following approved plans |
| @architect-agent | Validates architectural decisions |
| @codereview-agent | Reviews code for quality and debt |
| @retro-agent | Extracts lessons learned |
| @curator-agent | Maintains knowledge quality |
| @initializer-agent | Sets up project structure |

## How to Use

1. Start with the **Initializer Agent** to set up project structure
2. Use **Planning Agent** to create feature plans
3. Have **Architect Agent** review plans
4. Use **Coding Agent** to implement tasks
5. Run **Code Review Agent** on changes
6. Use **Retro Agent** after completing features

## Agent Files

See `agents/` directory for detailed agent instructions.
EOF
    log_info "Created: $INSTRUCTIONS_FILE"
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
log_info "GitHub Copilot setup complete!"
echo ""
echo "Next steps:"
echo "  1. Run the initializer agent: @initializer-agent"
echo "  2. Start planning: @planning-agent"
echo ""
