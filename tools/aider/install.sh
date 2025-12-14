#!/bin/sh
#
# Aider Install Script
# Creates .aider.conf.yml with agent context files
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
echo "  SDLC Agents - Aider Setup"
echo "========================================"
echo "  Source:  $SDLC_AGENTS"
echo "  Target:  $TARGET"
echo "  Mode:    $([ "$COPY_MODE" = true ] && echo 'copy' || echo 'symlink')"
echo "========================================"
echo ""

# Create .aider.conf.yml
CONFIG_FILE="$TARGET/.aider.conf.yml"
if [ -f "$CONFIG_FILE" ]; then
    log_warn "File exists, skipping: $CONFIG_FILE"
else
    cat > "$CONFIG_FILE" <<'EOF'
# SDLC Agents Configuration for Aider
# These files are loaded as read-only context

read:
  # Core agents
  - .agents/planning-agent.md
  - .agents/coding-agent.md
  - .agents/architect-agent.md
  - .agents/codereview-agent.md
  - .agents/retro-agent.md
  - .agents/curator-agent.md
  - .agents/initializer-agent.md

# Note: For large projects, you may want to comment out agents
# you don't need to reduce context size. The planning and coding
# agents are typically sufficient for most tasks.
EOF
    log_info "Created: $CONFIG_FILE"
fi

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
log_info "Aider setup complete!"
echo ""
echo "✓ Created/updated .gitignore to exclude .agents/"
echo ""
echo "Next steps:"
echo "  1. Run: aider"
echo "  2. Ask: Follow the initializer agent instructions"
echo ""
