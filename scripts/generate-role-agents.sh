#!/bin/sh

set -eu

usage() {
    cat <<'EOF'
Usage: ./scripts/generate-role-agents.sh [--check]

Generate compatibility `agents/*-agent.md` files from canonical
`skills/roles/*/SKILL.md` role definitions.

Options:
  --check   Verify generated output matches checked-in agent files
  -h        Show this help
EOF
}

MODE="write"

while [ $# -gt 0 ]; do
    case "$1" in
        --check)
            MODE="check"
            shift
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            echo "Unknown option: $1" >&2
            usage >&2
            exit 1
            ;;
    esac
done

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname "$0")" && pwd)
REPO_ROOT=$(CDPATH= cd -- "$SCRIPT_DIR/.." && pwd)
SKILLS_DIR="$REPO_ROOT/skills/roles"
AGENTS_DIR="$REPO_ROOT/agents"

if [ ! -d "$SKILLS_DIR" ]; then
    echo "Skills directory not found: $SKILLS_DIR" >&2
    exit 1
fi

if [ ! -d "$AGENTS_DIR" ]; then
    echo "Agents directory not found: $AGENTS_DIR" >&2
    exit 1
fi

extract_body() {
    skill_file="$1"

    awk '
        NR == 1 {
            if ($0 != "---") {
                print "Missing YAML frontmatter start in " FILENAME > "/dev/stderr"
                exit 1
            }
            in_frontmatter = 1
            next
        }
        in_frontmatter && $0 == "---" {
            in_frontmatter = 0
            skip_leading_blank = 1
            next
        }
        skip_leading_blank && $0 == "" {
            skip_leading_blank = 0
            next
        }
        !in_frontmatter {
            skip_leading_blank = 0
            print
        }
    ' "$skill_file"
}

rewrite_for_compat() {
    rewrite_input_file="$1"
    rewrite_output_file="$2"

    sed \
        -e 's|\.\./\.\./\.\./agents/|.sdlc-agents/|g' \
        -e 's|"\.\./\.\./\.\./agents"|".sdlc-agents"|g' \
        "$rewrite_input_file" > "$rewrite_output_file"
}

status=0

for skill_file in "$SKILLS_DIR"/*/SKILL.md; do
    role_dir=$(basename "$(dirname "$skill_file")")
    output_file="$AGENTS_DIR/$role_dir.md"

    if [ ! -f "$output_file" ]; then
        echo "Expected agent file not found: $output_file" >&2
        status=1
        continue
    fi

    body_file=$(mktemp)
    tmp_file=$(mktemp)
    trap 'rm -f "$body_file" "$tmp_file"' EXIT HUP INT TERM
    extract_body "$skill_file" > "$body_file"
    rewrite_for_compat "$body_file" "$tmp_file"

    if [ "$MODE" = "check" ]; then
        if ! cmp -s "$tmp_file" "$output_file"; then
            echo "Out of sync: $output_file" >&2
            diff -u "$output_file" "$tmp_file" || true
            status=1
        fi
    else
        if ! cmp -s "$tmp_file" "$output_file"; then
            cp "$tmp_file" "$output_file"
            echo "Updated $output_file"
        else
            echo "Unchanged $output_file"
        fi
    fi

    rm -f "$body_file"
    rm -f "$tmp_file"
    trap - EXIT HUP INT TERM
done

exit "$status"
