#!/bin/sh
#
# Aider Install Script
# Creates .aider.conf.yml and installs SDLC skills plus support assets.
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
. "$SDLC_AGENTS/tools/lib/install-skills.sh"
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
  # Core SDLC role skills
  - .agents/skills/planning-agent/SKILL.md
  - .agents/skills/coding-agent/SKILL.md
  - .agents/skills/architect-agent/SKILL.md
  - .agents/skills/codereview-agent/SKILL.md
  - .agents/skills/retro-agent/SKILL.md
  - .agents/skills/curator-agent/SKILL.md
  - .agents/skills/initializer-agent/SKILL.md

# Note: For large projects, you may want to comment out agents
# you don't need to reduce context size. The planning and coding
# agents are typically sufficient for most tasks.
EOF
    log_info "Created: $CONFIG_FILE"
fi

install_skill_catalog "$SDLC_AGENTS" "$TARGET"
install_support_bundle "$SDLC_AGENTS" "$TARGET" "$COPY_MODE"

echo ""
log_info "Aider setup complete!"
echo ""
echo "✓ Created .aider.conf.yml with skill instructions"
echo ""
echo "Next steps:"
echo "  1. Run: aider"
echo "  2. Type: 'Use the initializer-agent skill to bootstrap this project'"
echo "  3. Start planning features with:"
echo "     'Use the planning-agent skill to create a plan for [feature description]'"
echo ""
