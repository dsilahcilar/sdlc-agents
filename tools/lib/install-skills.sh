#!/bin/sh

set -e

copy_tree() {
    src="$1"
    dest="$2"

    if [ ! -d "$src" ]; then
        log_error "Source directory not found: $src"
        return 1
    fi

    mkdir -p "$dest"

    (
        cd "$src" || exit 1

        find . -type d | while IFS= read -r rel_dir; do
            rel_dir=${rel_dir#./}
            if [ -n "$rel_dir" ]; then
                mkdir -p "$dest/$rel_dir"
            fi
        done

        find . -type f | while IFS= read -r rel_file; do
            rel_file=${rel_file#./}
            mkdir -p "$dest/$(dirname "$rel_file")"
            if [ -f "$dest/$rel_file" ]; then
                if cmp -s "$src/$rel_file" "$dest/$rel_file"; then
                    continue
                fi
                log_warn "Preserving customized file: $dest/$rel_file"
                continue
            fi
            cp "$src/$rel_file" "$dest/$rel_file"
        done
    )
}

install_skill_catalog() {
    repo_root="$1"
    target_root="$2"

    for skill_base in \
        "$target_root/.github/skills" \
        "$target_root/.claude/skills" \
        "$target_root/.agents/skills"
    do
        mkdir -p "$skill_base"
        for skill_dir in "$repo_root/skills/roles"/*; do
            skill_name=$(basename "$skill_dir")
            copy_tree "$skill_dir" "$skill_base/$skill_name"
            log_info "Installed skill: $skill_base/$skill_name"
        done
    done
}

install_support_bundle() {
    repo_root="$1"
    target_root="$2"
    copy_mode="$3"

    bundle_target="$target_root/.sdlc-agents"
    if [ -e "$bundle_target" ]; then
        log_warn "Support bundle exists, skipping: $bundle_target"
        return 0
    fi

    if [ "$copy_mode" = true ]; then
        cp -r "$repo_root/agents" "$bundle_target"
        log_info "Copied support bundle to: $bundle_target"
    else
        ln -s "$repo_root/agents" "$bundle_target"
        log_info "Symlinked support bundle to: $bundle_target"
    fi
}

install_codex_skills() {
    repo_root="$1"
    codex_home="$2"

    mkdir -p "$codex_home"
    for skill_dir in "$repo_root/skills/roles"/*; do
        skill_name=$(basename "$skill_dir")
        copy_tree "$skill_dir" "$codex_home/$skill_name"
        log_info "Installed Codex skill: $codex_home/$skill_name"
    done
}
