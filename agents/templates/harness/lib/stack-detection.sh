#!/usr/bin/env sh
# =============================================================================
# Stack Detection Utility
# =============================================================================
# Detects the technology stack based on marker files in the project.
# See: skills/stack-detection.md for detailed detection rules.
#
# Usage:
#   source "$(dirname "$0")/lib/stack-detection.sh"
#   STACK=$(detect_stack)
#
# Returns: java, typescript, python, go, rust, dotnet, ruby, php, or unknown
# =============================================================================

detect_stack() {
    if [ -f "pom.xml" ] || [ -f "build.gradle" ] || [ -f "build.gradle.kts" ]; then
        echo "java"
    elif [ -f "package.json" ]; then
        echo "typescript"
    elif [ -f "pyproject.toml" ] || [ -f "setup.py" ] || [ -f "requirements.txt" ]; then
        echo "python"
    elif [ -f "go.mod" ]; then
        echo "go"
    elif [ -f "Cargo.toml" ]; then
        echo "rust"
    elif ls ./*.csproj >/dev/null 2>&1 || ls ./*.sln >/dev/null 2>&1; then
        echo "dotnet"
    elif [ -f "Gemfile" ]; then
        echo "ruby"
    elif [ -f "composer.json" ]; then
        echo "php"
    else
        echo "unknown"
    fi
}
