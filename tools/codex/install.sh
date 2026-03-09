#!/bin/sh
#
# Codex Install Script
# Installs SDLC skills into a Codex skills home and project support bundle.
#
# Usage: ./install.sh --codex-home /path/to/skills --target /path/to/project [--copy]
#

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() { printf "${GREEN}[INFO]${NC} %s\n" "$1"; }
log_warn() { printf "${YELLOW}[WARN]${NC} %s\n" "$1"; }
log_error() { printf "${RED}[ERROR]${NC} %s\n" "$1"; }

usage() {
    echo "Usage: $0 --codex-home <skills-path> --target <project-path> [--copy]"
    echo ""
    echo "Options:"
    echo "  --codex-home <p>  Codex skills directory (required)"
    echo "  --target <path>   Project directory for .sdlc-agents support assets (required)"
    echo "  --copy            Copy support assets instead of symlinking"
    echo "  -h, --help        Show this help"
    exit 1
}

CODEX_HOME=""
TARGET=""
COPY_MODE=false

while [ $# -gt 0 ]; do
    case "$1" in
        --codex-home) CODEX_HOME="$2"; shift 2 ;;
        --target) TARGET="$2"; shift 2 ;;
        --copy) COPY_MODE=true; shift ;;
        -h|--help) usage ;;
        *) log_error "Unknown option: $1"; usage ;;
    esac
done

if [ -z "$CODEX_HOME" ] || [ -z "$TARGET" ]; then
    log_error "Missing required --codex-home or --target argument"
    usage
fi

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
SDLC_AGENTS=$(cd "$SCRIPT_DIR/../.." && pwd)
. "$SDLC_AGENTS/tools/lib/install-skills.sh"

mkdir -p "$CODEX_HOME"
CODEX_HOME=$(cd "$CODEX_HOME" && pwd)
TARGET=$(cd "$TARGET" 2>/dev/null && pwd) || {
    log_error "Target directory does not exist: $TARGET"
    exit 1
}

echo ""
echo "========================================"
echo "  SDLC Agents - Codex Setup"
echo "========================================"
echo "  Source:      $SDLC_AGENTS"
echo "  Codex Home:  $CODEX_HOME"
echo "  Target:      $TARGET"
echo "  Mode:        $([ "$COPY_MODE" = true ] && echo 'copy' || echo 'symlink')"
echo "========================================"
echo ""

install_codex_skills "$SDLC_AGENTS" "$CODEX_HOME"
install_support_bundle "$SDLC_AGENTS" "$TARGET" "$COPY_MODE"

echo ""
log_info "Codex setup complete!"
echo ""
echo "Installed SDLC role skills into: $CODEX_HOME"
echo "Installed project support bundle into: $TARGET/.sdlc-agents"
echo ""
