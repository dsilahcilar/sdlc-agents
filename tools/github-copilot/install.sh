#!/bin/sh
#
# GitHub Copilot Install Script
# Installs SDLC skills into project skill directories and links support assets.
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

. "$SDLC_AGENTS/tools/lib/install-skills.sh"
install_skill_catalog "$SDLC_AGENTS" "$TARGET"
install_support_bundle "$SDLC_AGENTS" "$TARGET" "$COPY_MODE"

echo ""
log_info "GitHub Copilot setup complete!"
echo ""
echo "✓ Installed skills into .github/skills/, .claude/skills/, and .agents/skills/"
echo "✓ Linked .sdlc-agents/ support bundle for templates, tools, and guardrails"
echo ""
echo "Next steps:"
echo "  1. Open GitHub Copilot Chat in VS Code"
echo "  2. Pick the installed SDLC skill from .github/skills/"
echo "  3. Start with: 'Use the initializer-agent skill to bootstrap this project'"
echo "  4. Continue with: 'Use the planning-agent skill to create a plan for [feature description]'"
echo ""
