#!/bin/sh
#
# SDLC Agents Setup Script
# Copies all template files to project workspace
#
# Usage: ./setup.sh <sdlc-agents-path> <project-root>
#
# This script is idempotent - safe to run multiple times.
# Existing files will NOT be overwritten (use -f to force).
#

set -e

# Colors for output (POSIX-compatible)
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

#######################################
# Print usage information
#######################################
usage() {
    echo "Usage: $0 [-f] <project-root> [sdlc-agents-path]"
    echo ""
    echo "Arguments:"
    echo "  project-root      Path to the target project root"
    echo "  sdlc-agents-path  (Optional) Path to the sdlc-agents repository"
    echo "                    If not provided, will auto-discover from current directory"
    echo ""
    echo "Options:"
    echo "  -f                Force overwrite existing files"
    echo "  -h                Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 /path/to/my-project"
    echo "  $0 /path/to/my-project /path/to/sdlc-agents"
    exit 1
}

#######################################
# Print colored message
#######################################
log_info() {
    printf "${GREEN}[INFO]${NC} %s\n" "$1"
}

log_warn() {
    printf "${YELLOW}[WARN]${NC} %s\n" "$1"
}

log_error() {
    printf "${RED}[ERROR]${NC} %s\n" "$1"
}

#######################################
# Copy directory with optional overwrite
# Arguments:
#   $1 - source directory
#   $2 - destination directory
#   $3 - force flag (true/false)
#######################################
copy_directory() {
    src="$1"
    dest="$2"
    force="$3"
    
    if [ ! -d "$src" ]; then
        log_error "Source directory not found: $src"
        return 1
    fi
    
    if [ -d "$dest" ] && [ "$force" != "true" ]; then
        log_warn "Directory exists, skipping: $dest"
        return 0
    fi
    
    mkdir -p "$dest"
    cp -r "$src"/* "$dest"/ 2>/dev/null || true
    log_info "Copied: $src -> $dest"
}

#######################################
# Copy file with optional overwrite
# Arguments:
#   $1 - source file
#   $2 - destination file
#   $3 - force flag (true/false)
#######################################
copy_file() {
    src="$1"
    dest="$2"
    force="$3"
    
    if [ ! -f "$src" ]; then
        log_error "Source file not found: $src"
        return 1
    fi
    
    if [ -f "$dest" ] && [ "$force" != "true" ]; then
        log_warn "File exists, skipping: $dest"
        return 0
    fi
    
    dest_dir=$(dirname "$dest")
    mkdir -p "$dest_dir"
    cp "$src" "$dest"
    log_info "Copied: $src -> $dest"
}

#######################################
# Make scripts executable
# Arguments:
#   $1 - directory containing scripts
#######################################
make_executable() {
    dir="$1"
    if [ -d "$dir" ]; then
        find "$dir" -name "*.sh" -type f -exec chmod +x {} \;
        log_info "Made scripts executable in: $dir"
    fi
}

#######################################
# Main
#######################################

FORCE="false"

# Parse options
while getopts "fh" opt; do
    case $opt in
        f) FORCE="true" ;;
        h) usage ;;
        *) usage ;;
    esac
done
shift $((OPTIND - 1))

# Validate arguments
if [ $# -eq 1 ]; then
    # Only project root provided, auto-discover sdlc-agents
    PROJECT_ROOT="$1"
    log_info "Auto-discovering sdlc-agents directory..."
    SDLC_AGENTS=$(dirname "$(find . -name "initializer-agent.md" 2>/dev/null | head -1)")
    if [ -z "$SDLC_AGENTS" ]; then
        log_error "Could not find sdlc-agents directory. Please provide it explicitly."
        usage
    fi
elif [ $# -eq 2 ]; then
    PROJECT_ROOT="$1"
    SDLC_AGENTS="$2"
else
    log_error "Invalid number of arguments"
    usage
fi

# Resolve to absolute paths
SDLC_AGENTS_PATH=$(cd "$SDLC_AGENTS" 2>/dev/null && pwd) || {
    log_error "Invalid sdlc-agents path: $SDLC_AGENTS"
    exit 1
}
PROJECT_ROOT=$(cd "$PROJECT_ROOT" 2>/dev/null && pwd) || {
    log_error "Invalid project root: $2"
    exit 1
}

TEMPLATES_PATH="$SDLC_AGENTS_PATH/templates"

# Verify templates directory exists
if [ ! -d "$TEMPLATES_PATH" ]; then
    log_error "Templates directory not found: $TEMPLATES_PATH"
    exit 1
fi

echo ""
echo "=========================================="
echo "  SDLC Agents Setup"
echo "=========================================="
echo "  Source:  $TEMPLATES_PATH"
echo "  Target:  $PROJECT_ROOT"
echo "  Force:   $FORCE"
echo "=========================================="
echo ""

# Create agent-context directory
AGENT_CONTEXT="$PROJECT_ROOT/agent-context"
mkdir -p "$AGENT_CONTEXT"

# Step 1: Copy harness templates
log_info "Step 1/5: Copying harness templates..."
copy_directory "$TEMPLATES_PATH/harness" "$AGENT_CONTEXT/harness" "$FORCE"
make_executable "$AGENT_CONTEXT/harness"

# Step 2: Copy memory templates
log_info "Step 2/5: Copying memory templates..."
copy_directory "$TEMPLATES_PATH/memory" "$AGENT_CONTEXT/memory" "$FORCE"

# Step 3: Copy context templates
log_info "Step 3/5: Copying context templates..."
copy_directory "$TEMPLATES_PATH/context" "$AGENT_CONTEXT/context" "$FORCE"

# Step 4: Copy features templates
log_info "Step 4/5: Copying features templates..."
mkdir -p "$AGENT_CONTEXT/features"
copy_file "$TEMPLATES_PATH/features/README.md" "$AGENT_CONTEXT/features/README.md" "$FORCE"
copy_file "$TEMPLATES_PATH/features/feature-template.md" "$AGENT_CONTEXT/features/feature-template.md" "$FORCE"
mkdir -p "$AGENT_CONTEXT/features/tasks"
copy_file "$TEMPLATES_PATH/features/tasks/task-template.md" "$AGENT_CONTEXT/features/tasks/task-template.md" "$FORCE"

# Step 5: Copy extensions templates (for custom instructions)
log_info "Step 5/5: Copying extensions templates..."
copy_directory "$TEMPLATES_PATH/extensions" "$AGENT_CONTEXT/extensions" "$FORCE"

# Summary
echo ""
echo "=========================================="
echo "  Setup Complete!"
echo "=========================================="
echo ""
echo "Created structure:"
echo "  $PROJECT_ROOT/agent-context/"
echo "  ├── harness/           (scripts + task tracking)"
echo "  ├── memory/            (learning + retrieval)"
echo "  ├── context/           (domain heuristics)"
echo "  ├── features/          (feature specs + tasks)"
echo "  │   ├── feature-template.md"
echo "  │   └── tasks/"
echo "  │       └── task-template.md"
echo "  └── extensions/        (custom instructions)"
echo "      ├── _all-agents/   (global rules)"
echo "      └── <agent-name>/  (agent-specific)"
echo ""
echo "Next steps for the LLM:"
echo "  1. Detect stack and customize harness scripts"
echo "  2. Create first feature using features/feature-template.md"
echo "  3. Run architecture discovery (if legacy project)"
echo "  4. Verify health: init-project.sh, run-arch-tests.sh"
echo "  5. Commit changes"
echo ""
