#!/usr/bin/env sh
# =============================================================================
# Stack Detection Utility
# =============================================================================
# Detects the technology stack based on marker files in the project.
# See: skills/stack-detection.md for detailed detection rules.
#
# Usage:
#   source "$(dirname "$0")/lib/stack-detection.sh"
#   STACK=$(detect_stack)              # Scans current directory
#   STACK=$(detect_stack "/path/to/project")  # Scans specified directory
#
# Returns: java, typescript, python, go, rust, dotnet, ruby, php, or unknown
# =============================================================================

detect_stack() {
    local base_dir="${1:-.}"  # Default to current directory if not specified
    
    if [ -f "$base_dir/pom.xml" ] || [ -f "$base_dir/build.gradle" ] || [ -f "$base_dir/build.gradle.kts" ]; then
        echo "java"
    elif [ -f "$base_dir/tsconfig.json" ]; then
        echo "typescript"
    elif [ -f "$base_dir/package.json" ]; then
        # Treat JavaScript/TypeScript projects as the shared TypeScript skill family.
        echo "typescript"
    elif [ -f "$base_dir/pyproject.toml" ] || [ -f "$base_dir/setup.py" ] || [ -f "$base_dir/requirements.txt" ]; then
        echo "python"
    elif [ -f "$base_dir/go.mod" ]; then
        echo "go"
    elif [ -f "$base_dir/Cargo.toml" ]; then
        echo "rust"
    elif ls "$base_dir"/*.csproj >/dev/null 2>&1 || ls "$base_dir"/*.sln >/dev/null 2>&1; then
        echo "dotnet"
    elif [ -f "$base_dir/Gemfile" ]; then
        echo "ruby"
    elif [ -f "$base_dir/composer.json" ]; then
        echo "php"
    else
        echo "unknown"
	    fi
	}

dir_has_typescript_files() {
    local base_dir="$1"

    find "$base_dir" -type f \( -name "*.ts" -o -name "*.tsx" -o -name "*.js" -o -name "*.jsx" \) \
        ! -path "*/node_modules/*" \
        ! -path "*/dist/*" \
        ! -path "*/build/*" \
        ! -path "*/coverage/*" \
        ! -path "*/.next/*" \
        ! -path "*/.turbo/*" \
        ! -path "*/.git/*" \
        -print -quit 2>/dev/null | grep -q .
}

detect_typescript_source_target() {
    local base_dir="${1:-.}"
    local candidate
    local found_any="false"

    for candidate in src app lib server client packages apps; do
        if [ -d "$base_dir/$candidate" ] && dir_has_typescript_files "$base_dir/$candidate"; then
            printf '%s\n' "$candidate"
            found_any="true"
        fi
    done

    if [ "$found_any" = "true" ]; then
        return 0
    fi

    if dir_has_typescript_files "$base_dir"; then
        printf '.\n'
        return 0
    fi

    # Fall back to the project root so architecture tools can still load config-only projects.
    printf '.\n'
}
