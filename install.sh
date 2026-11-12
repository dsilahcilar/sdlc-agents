#!/bin/sh
#
# Installs sdlc-agents into a repository by copying files.
# Nothing is linked back to this checkout, so the install works the same on a laptop, in CI and in a
# cloud session.
#
# Usage: install.sh --target /path/to/repository [--force]
#
#   --force   overwrite the files this installer owns (roles, gate, risk report, templates) when they
#             differ. Your rules, lessons and fixes file are never overwritten.

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

# How many owned files were left as they are although they differ from this version.
KEPT=0

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
        KEPT=$((KEPT + 1))
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

echo "sdlc-agents -> $TARGET"

owned roles/reviewer.md .claude/agents/reviewer.md
owned roles/architect.md .claude/agents/architect.md
owned roles/retro.md .claude/agents/retro.md
owned gate/handover_gate.py .sdlc/gate/handover_gate.py
owned retro/risk_report.py .sdlc/retro/risk_report.py
owned templates/brief.md .sdlc/templates/brief.md
owned templates/pull_request_template.md .sdlc/templates/pull_request_template.md
owned templates/CLAUDE.snippet.md .sdlc/templates/CLAUDE.snippet.md
owned ci/handover-gate.yml .sdlc/templates/handover-gate.yml
yours templates/rules.json .sdlc/rules.json
yours templates/fixes.json .sdlc/retro/fixes.json
yours templates/lessons/reviewer.md .sdlc/lessons/reviewer.md
yours templates/lessons/architect.md .sdlc/lessons/architect.md
yours templates/lessons/security.md .sdlc/lessons/security.md

# Which commit this install came from, so an upgrade can be told from a local edit. Written only when every
# owned file is at this version: with files kept as they were, the install is not at this commit.
COMMIT=$(git -C "$SOURCE" rev-parse --short HEAD 2>/dev/null || echo unknown)
if [ "$KEPT" -eq 0 ]; then
    printf 'sdlc-agents %s\n' "$COMMIT" > "$TARGET/.sdlc/VERSION"
    echo "  wrote    .sdlc/VERSION ($COMMIT)"
else
    echo "  kept     .sdlc/VERSION ($KEPT of the files above differ from $COMMIT, so this install is not at it)"
fi

if [ -e "$TARGET/.sdlc-agents" ] || [ -L "$TARGET/.sdlc-agents" ]; then
    echo ""
    echo "Note: this repository still has the earlier seven-agent pipeline installed (.sdlc-agents and its"
    echo "agent files in .claude/agents/). Nothing was removed. See docs/migrating.md in sdlc-agents."
fi

cat <<'EOF'

Next:
  1. Edit .sdlc/rules.json: the path patterns are guesses, point them at where things live here.
  2. Paste .sdlc/templates/CLAUDE.snippet.md into your CLAUDE.md.
  3. Try it: python3 .sdlc/gate/handover_gate.py --base origin/main
  4. Copy .sdlc/templates/handover-gate.yml to .github/workflows/. The job prints the result on every pull
     request and is red while something the change owes is not there. Require the check before a merge to
     make it binding. To only report for a while, set ENFORCE to "false" in that file.
  5. Later, with some merged history: python3 .sdlc/retro/risk_report.py shows where changes went wrong,
     and whether the reviewer needs to read every change. See docs/risk.md in sdlc-agents.
EOF
