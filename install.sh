#!/bin/sh
#
# SDLC Agents Master Install Script
# Installs SDLC Agents for one or more AI coding assistants
#
# Usage:
#   ./install.sh --ghcp --target /path/to/project
#   ./install.sh --claude --target /path/to/project
#   ./install.sh --cursor --target /path/to/project
#   ./install.sh --windsurf --target /path/to/project
#   ./install.sh --aider --target /path/to/project
#   ./install.sh --all --target /path/to/project
#

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

log_info() { printf "${GREEN}[INFO]${NC} %s\n" "$1"; }
log_warn() { printf "${YELLOW}[WARN]${NC} %s\n" "$1"; }
log_error() { printf "${RED}[ERROR]${NC} %s\n" "$1"; }
log_header() { printf "\n${CYAN}%s${NC}\n" "$1"; }

usage() {
    echo ""
    echo "SDLC Agents - Multi-Assistant Installer"
    echo ""
    echo "Usage: $0 <tool-flags> --target <project-path> [options]"
    echo ""
    echo "Tool Flags (at least one required):"
    echo "  --ghcp            Install for GitHub Copilot"
    echo "  --claude          Install for Claude Code"
    echo "  --cursor          Install for Cursor"
    echo "  --windsurf        Install for Windsurf"
    echo "  --aider           Install for Aider"
    echo "  --all             Install for all tools"
    echo ""
    echo "Required:"
    echo "  --target <path>   Target project directory"
    echo ""
    echo "Options:"
    echo "  --copy            Copy agents instead of symlinking"
    echo "  -h, --help        Show this help"
    echo ""
    echo "Examples:"
    echo "  $0 --ghcp --target ./my-project"
    echo "  $0 --claude --cursor --target ./my-project"
    echo "  $0 --all --target ./my-project --copy"
    echo ""
    exit 1
}

# Resolve script directory
SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)

# Parse arguments
TARGET=""
COPY_FLAG=""
INSTALL_GHCP=false
INSTALL_CLAUDE=false
INSTALL_CURSOR=false
INSTALL_WINDSURF=false
INSTALL_AIDER=false

while [ $# -gt 0 ]; do
    case "$1" in
        --target) TARGET="$2"; shift 2 ;;
        --copy) COPY_FLAG="--copy"; shift ;;
        --ghcp) INSTALL_GHCP=true; shift ;;
        --claude) INSTALL_CLAUDE=true; shift ;;
        --cursor) INSTALL_CURSOR=true; shift ;;
        --windsurf) INSTALL_WINDSURF=true; shift ;;
        --aider) INSTALL_AIDER=true; shift ;;
        --all)
            INSTALL_GHCP=true
            INSTALL_CLAUDE=true
            INSTALL_CURSOR=true
            INSTALL_WINDSURF=true
            INSTALL_AIDER=true
            shift
            ;;
        -h|--help) usage ;;
        *) log_error "Unknown option: $1"; usage ;;
    esac
done

# Validate arguments
if [ -z "$TARGET" ]; then
    log_error "Missing required --target argument"
    usage
fi

# Check at least one tool selected
if [ "$INSTALL_GHCP" = false ] && \
   [ "$INSTALL_CLAUDE" = false ] && \
   [ "$INSTALL_CURSOR" = false ] && \
   [ "$INSTALL_WINDSURF" = false ] && \
   [ "$INSTALL_AIDER" = false ]; then
    log_error "No tool selected. Use --ghcp, --claude, --cursor, --windsurf, --aider, or --all"
    usage
fi

# Validate target exists
if [ ! -d "$TARGET" ]; then
    log_error "Target directory does not exist: $TARGET"
    exit 1
fi

TARGET=$(cd "$TARGET" && pwd)

echo ""
echo "╔═══════════════════════════════════════════╗"
echo "║     SDLC Agents - Multi-Tool Install      ║"
echo "╠═══════════════════════════════════════════╣"
echo "║  Target: $(printf '%-32s' "$TARGET")║"
echo "║  Mode:   $(printf '%-32s' "$([ -n "$COPY_FLAG" ] && echo 'copy' || echo 'symlink')")║"
echo "╚═══════════════════════════════════════════╝"

# Track results
INSTALLED=""
FAILED=""

# GitHub Copilot
if [ "$INSTALL_GHCP" = true ]; then
    log_header "Installing for GitHub Copilot..."
    if "$SCRIPT_DIR/tools/github-copilot/install.sh" --target "$TARGET" $COPY_FLAG; then
        INSTALLED="$INSTALLED ghcp"
    else
        FAILED="$FAILED ghcp"
    fi
fi

# Claude
if [ "$INSTALL_CLAUDE" = true ]; then
    log_header "Installing for Claude Code..."
    if "$SCRIPT_DIR/tools/claude/install.sh" --target "$TARGET" $COPY_FLAG; then
        INSTALLED="$INSTALLED claude"
    else
        FAILED="$FAILED claude"
    fi
fi

# Cursor
if [ "$INSTALL_CURSOR" = true ]; then
    log_header "Installing for Cursor..."
    if "$SCRIPT_DIR/tools/cursor/install.sh" --target "$TARGET" $COPY_FLAG; then
        INSTALLED="$INSTALLED cursor"
    else
        FAILED="$FAILED cursor"
    fi
fi

# Windsurf
if [ "$INSTALL_WINDSURF" = true ]; then
    log_header "Installing for Windsurf..."
    if "$SCRIPT_DIR/tools/windsurf/install.sh" --target "$TARGET" $COPY_FLAG; then
        INSTALLED="$INSTALLED windsurf"
    else
        FAILED="$FAILED windsurf"
    fi
fi

# Aider
if [ "$INSTALL_AIDER" = true ]; then
    log_header "Installing for Aider..."
    if "$SCRIPT_DIR/tools/aider/install.sh" --target "$TARGET" $COPY_FLAG; then
        INSTALLED="$INSTALLED aider"
    else
        FAILED="$FAILED aider"
    fi
fi

# Summary
echo ""
echo "╔═══════════════════════════════════════════╗"
echo "║              Install Summary              ║"
echo "╠═══════════════════════════════════════════╣"
if [ -n "$INSTALLED" ]; then
    printf "║  ${GREEN}✓ Installed:${NC}%-28s║\n" "$INSTALLED"
fi
if [ -n "$FAILED" ]; then
    printf "║  ${RED}✗ Failed:${NC}%-31s║\n" "$FAILED"
fi
echo "╚═══════════════════════════════════════════╝"
echo ""

if [ -n "$FAILED" ]; then
    exit 1
fi

log_info "Installation complete!"
echo ""
echo "Next steps:"
echo "  1. Open your project in your preferred AI coding tool"
echo "  2. Run the initializer agent to set up project structure"
echo "  3. Start with the planning agent for your first feature"
echo ""
