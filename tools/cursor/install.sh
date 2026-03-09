#!/bin/sh
#
# Cursor Install Script
# Creates a Cursor rule and installs SDLC skills plus support assets.
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

## Available Skills

Role skills live in `.agents/skills/` and are mirrored to `.github/skills/` and `.claude/skills/`.

| Skill | File | Purpose |
|-------|------|---------|
| Planning | @.agents/skills/planning-agent/SKILL.md | Creates structured plans |
| Coding | @.agents/skills/coding-agent/SKILL.md | Implements changes |
| Architect | @.agents/skills/architect-agent/SKILL.md | Validates architecture |
| Code Review | @.agents/skills/codereview-agent/SKILL.md | Reviews for quality |
| Retro | @.agents/skills/retro-agent/SKILL.md | Captures lessons |
| Initializer | @.agents/skills/initializer-agent/SKILL.md | Sets up project |

## Workflow

1. **Initialize**: Use @.agents/skills/initializer-agent/SKILL.md for first-time setup
2. **Plan**: Use @.agents/skills/planning-agent/SKILL.md to create feature plans
3. **Architect**: Have @.agents/skills/architect-agent/SKILL.md review plans
4. **Code**: Use @.agents/skills/coding-agent/SKILL.md to implement tasks
5. **Review**: Run @.agents/skills/codereview-agent/SKILL.md on changes
6. **Learn**: Use @.agents/skills/retro-agent/SKILL.md to capture lessons
EOF
    log_info "Created: $RULES_FILE"
fi

install_skill_catalog "$SDLC_AGENTS" "$TARGET"
install_support_bundle "$SDLC_AGENTS" "$TARGET" "$COPY_MODE"

echo ""
log_info "Cursor setup complete!"
echo ""
echo "Next steps:"
echo "  1. Open your project in Cursor"
echo "  2. Start with: '@.agents/skills/initializer-agent/SKILL.md bootstrap this project'"
echo "  3. Continue with: '@.agents/skills/planning-agent/SKILL.md create a plan for [feature description]'"
echo ""
