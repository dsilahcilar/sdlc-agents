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
# Returns: java, typescript, javascript, python, go, rust, dotnet, ruby, php, or unknown
# =============================================================================

detect_stack() {
    local base_dir="${1:-.}"  # Default to current directory if not specified
    
    if [ -f "$base_dir/pom.xml" ] || [ -f "$base_dir/build.gradle" ] || [ -f "$base_dir/build.gradle.kts" ]; then
        echo "java"
    elif [ -f "$base_dir/tsconfig.json" ]; then
        echo "typescript"
    elif [ -f "$base_dir/package.json" ]; then
        echo "javascript"
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
