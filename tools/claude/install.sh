#!/bin/sh
#
# Claude Code Install Script
# Creates CLAUDE.md and .claude/ configuration
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

# Create CLAUDE.md from template
CLAUDE_FILE="$TARGET/CLAUDE.md"
TEMPLATE_FILE="$SCRIPT_DIR/CLAUDE.md.template"

if [ -f "$CLAUDE_FILE" ]; then
    log_warn "File exists, skipping: $CLAUDE_FILE"
else
    cp "$TEMPLATE_FILE" "$CLAUDE_FILE"
    log_info "Created: $CLAUDE_FILE"
fi

# Create .claude directory
CLAUDE_DIR="$TARGET/.claude"
mkdir -p "$CLAUDE_DIR"

# Create settings.local.json if it doesn't exist
SETTINGS_FILE="$CLAUDE_DIR/settings.local.json"
if [ -f "$SETTINGS_FILE" ]; then
    log_warn "File exists, skipping: $SETTINGS_FILE"
else
    cat > "$SETTINGS_FILE" << 'EOF'
{
  "permissions": {
    "allow": [
      "Bash(tree:*)",
      "Bash(mkdir:*)",
      "Bash(chmod:*)",
      "Bash(ls:*)",
      "Bash(find:*)",
      "Bash(grep:*)"
    ],
    "deny": []
  }
}
EOF
    log_info "Created: $SETTINGS_FILE"
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
log_info "Claude Code setup complete!"
echo ""
echo "Next steps:"
echo "  1. Ask Claude to read agents/initializer-agent.md"
echo "  2. Start planning with agents/planning-agent.md"
echo ""
