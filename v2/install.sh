#!/bin/sh
#
# Installs sdlc-agents version 2 into a repository by copying files.
# Nothing is linked back to this checkout, so the install works the same on a laptop, in CI and in a
# cloud session.
#
# Usage: v2/install.sh --target /path/to/repository [--force]
#
#   --force   overwrite the files this installer owns (roles, gate, templates) when they differ.
#             Your rules and lessons are never overwritten.

set -eu

usage() {
    sed -n '3,11p' "$0" | sed 's/^# \{0,1\}//'
    exit "${1:-1}"
}

TARGET=""
FORCE=false
while [ $# -gt 0 ]; do
    case "$1" in
        --target) [ $# -ge 2 ] || usage; TARGET="$2"; shift 2 ;;
        --force) FORCE=true; shift ;;
        -h|--help) usage 0 ;;
        *) echo "Unknown option: $1" >&2; usage ;;
    esac
done
[ -n "$TARGET" ] || usage
[ -d "$TARGET" ] || { echo "Target directory does not exist: $TARGET" >&2; exit 1; }

SOURCE=$(cd "$(dirname "$0")" && pwd)
TARGET=$(cd "$TARGET" && pwd)

# A file this installer owns: copied when missing, replaced only with --force when it differs.
owned() {
    src="$SOURCE/$1"; dst="$TARGET/$2"
    mkdir -p "$(dirname "$dst")"
    if [ ! -e "$dst" ]; then
        cp "$src" "$dst"; echo "  added    $2"
    elif cmp -s "$src" "$dst"; then
        echo "  same     $2"
    elif [ "$FORCE" = true ]; then
        cp "$src" "$dst"; echo "  replaced $2"
    else
        echo "  kept     $2 (differs; run again with --force to replace it)"
    fi
}

# A file the repository owns once it exists: copied only when missing.
yours() {
    src="$SOURCE/$1"; dst="$TARGET/$2"
    mkdir -p "$(dirname "$dst")"
    if [ -e "$dst" ]; then
        echo "  kept     $2 (yours)"
    else
        cp "$src" "$dst"; echo "  added    $2"
    fi
}

echo "sdlc-agents version 2 -> $TARGET"

owned roles/reviewer.md .claude/agents/reviewer.md
owned roles/architect.md .claude/agents/architect.md
owned gate/handover_gate.py .sdlc/gate/handover_gate.py
owned templates/brief.md .sdlc/templates/brief.md
owned templates/pull_request_template.md .sdlc/templates/pull_request_template.md
owned templates/CLAUDE.snippet.md .sdlc/templates/CLAUDE.snippet.md
owned ci/handover-gate.yml .sdlc/templates/handover-gate.yml
yours templates/rules.json .sdlc/rules.json
yours templates/lessons/reviewer.md .sdlc/lessons/reviewer.md
yours templates/lessons/architect.md .sdlc/lessons/architect.md
yours templates/lessons/security.md .sdlc/lessons/security.md

# Which commit this install came from, so an upgrade can be told from a local edit.
COMMIT=$(git -C "$SOURCE" rev-parse --short HEAD 2>/dev/null || echo unknown)
printf 'sdlc-agents v2 %s\n' "$COMMIT" > "$TARGET/.sdlc/VERSION"
echo "  wrote    .sdlc/VERSION ($COMMIT)"

if [ -e "$TARGET/.sdlc-agents" ] || [ -L "$TARGET/.sdlc-agents" ]; then
    echo ""
    echo "Note: this repository still has a version 1 install (.sdlc-agents and its seven agent files in"
    echo ".claude/agents/). Nothing was removed. See v2/docs/migrating-from-v1.md."
fi

cat <<'EOF'

Next:
  1. Edit .sdlc/rules.json: the path patterns are guesses, point them at where things live here.
  2. Paste .sdlc/templates/CLAUDE.snippet.md into your CLAUDE.md.
  3. Try it: python3 .sdlc/gate/handover_gate.py --base origin/main
  4. Optional: copy .sdlc/templates/handover-gate.yml to .github/workflows/ to print the result on every
     pull request. It blocks nothing.
EOF
