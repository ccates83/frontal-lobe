#!/usr/bin/env bash
# sync.sh — Sync local Claude Code configuration (~/.claude/) into this repository.
#
# Usage: scripts/sync.sh [--dry-run] [--help]
#
# This script compares the user's local ~/.claude/ configuration with the
# repo's claude-code/ directory and offers to mirror changes into the repo.

set -euo pipefail

# ---------------------------------------------------------------------------
# Color setup (gracefully degrade when stdout is not a terminal)
# ---------------------------------------------------------------------------
if [[ -t 1 ]] && command -v tput &>/dev/null && [[ $(tput colors 2>/dev/null || echo 0) -ge 8 ]]; then
    RED=$(tput setaf 1)
    GREEN=$(tput setaf 2)
    YELLOW=$(tput setaf 3)
    CYAN=$(tput setaf 6)
    BOLD=$(tput bold)
    DIM=$(tput dim)
    RESET=$(tput sgr0)
else
    RED="" GREEN="" YELLOW="" CYAN="" BOLD="" DIM="" RESET=""
fi

# ---------------------------------------------------------------------------
# Globals
# ---------------------------------------------------------------------------
DRY_RUN=false
SOURCE_DIR="${HOME}/.claude"

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------
info()    { printf "%s[info]%s  %s\n" "${CYAN}" "${RESET}" "$*"; }
success() { printf "%s[ok]%s    %s\n" "${GREEN}" "${RESET}" "$*"; }
warn()    { printf "%s[warn]%s  %s\n" "${YELLOW}" "${RESET}" "$*"; }
error()   { printf "%s[error]%s %s\n" "${RED}" "${RESET}" "$*" >&2; }
header()  { printf "\n%s%s%s\n" "${BOLD}" "$*" "${RESET}"; }

# Print a colored file path with a status label.
#   status_line <color> <label> <path>
status_line() {
    local color="$1" label="$2" path="$3"
    printf "  %s%-10s%s %s\n" "${color}" "${label}" "${RESET}" "${path}"
}

# Show the first N lines of a unified diff, with basic coloring.
condensed_diff() {
    local file_a="$1" file_b="$2" max_lines="${3:-8}"
    diff -u "$file_a" "$file_b" 2>/dev/null | head -n "$((max_lines + 3))" | while IFS= read -r line; do
        case "$line" in
            ---*|+++*) printf "%s%s%s\n" "${BOLD}" "$line" "${RESET}" ;;
            @@*)       printf "%s%s%s\n" "${CYAN}" "$line" "${RESET}" ;;
            +*)        printf "%s%s%s\n" "${GREEN}" "$line" "${RESET}" ;;
            -*)        printf "%s%s%s\n" "${RED}" "$line" "${RESET}" ;;
            *)         printf "%s%s%s\n" "${DIM}" "$line" "${RESET}" ;;
        esac
    done
}

# ---------------------------------------------------------------------------
# Usage / help
# ---------------------------------------------------------------------------
usage() {
    cat <<EOF
${BOLD}sync.sh${RESET} — Sync local Claude Code config into this repository.

${BOLD}USAGE${RESET}
    scripts/sync.sh [OPTIONS]

${BOLD}OPTIONS${RESET}
    --dry-run   Show what would change without applying anything.
    --help      Show this help message and exit.

${BOLD}WHAT GETS SYNCED${RESET}
    ~/.claude/agents/           ->  claude-code/agents/       (*.md files)
    ~/.claude/commands/         ->  claude-code/commands/      (*.md files)
    ~/.claude/skills/           ->  claude-code/skills/        (entire tree, excl. __pycache__/*.pyc)
    ~/.claude/settings.json     ->  claude-code/settings.json
    ~/.claude/settings.local.json -> claude-code/settings.local.json

EOF
    exit 0
}

# ---------------------------------------------------------------------------
# Argument parsing
# ---------------------------------------------------------------------------
for arg in "$@"; do
    case "$arg" in
        --dry-run) DRY_RUN=true ;;
        --help|-h) usage ;;
        *)
            error "Unknown option: $arg"
            printf "Run with --help for usage.\n" >&2
            exit 1
            ;;
    esac
done

# ---------------------------------------------------------------------------
# Resolve repo root
# ---------------------------------------------------------------------------
# Prefer git if we are inside a work tree; fall back to script location.
if git rev-parse --show-toplevel &>/dev/null; then
    REPO_ROOT="$(git rev-parse --show-toplevel)"
else
    REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
fi

DEST_DIR="${REPO_ROOT}/claude-code"

# ---------------------------------------------------------------------------
# Banner
# ---------------------------------------------------------------------------
header "Claude Code Config Sync"
info "Source:      ${SOURCE_DIR}/"
info "Destination: ${DEST_DIR}/"
if $DRY_RUN; then
    warn "Dry-run mode — no changes will be applied."
fi

# ---------------------------------------------------------------------------
# Pre-flight checks
# ---------------------------------------------------------------------------
if [[ ! -d "${SOURCE_DIR}" ]]; then
    error "Source directory ${SOURCE_DIR}/ does not exist."
    error "Make sure Claude Code has been configured at least once."
    exit 1
fi

if [[ ! -d "${DEST_DIR}" ]]; then
    error "Destination directory ${DEST_DIR}/ does not exist in the repo."
    exit 1
fi

# ---------------------------------------------------------------------------
# Collect file lists for each category
# ---------------------------------------------------------------------------
# We build arrays of relative paths for new / modified / deleted files per
# category, then render them in the diff preview.

declare -a new_files=()
declare -a mod_files=()
declare -a del_files=()

# Total counters for the summary line.
total_new=0
total_mod=0
total_del=0

# compare_md_dir <label> <src_subdir> <dest_subdir>
#   Compare two directories that should contain only *.md files.
compare_md_dir() {
    local label="$1" src="$2" dest="$3"

    local -a cat_new=() cat_mod=() cat_del=()

    # New & modified: files present in source.
    if [[ -d "$src" ]]; then
        while IFS= read -r -d '' f; do
            local rel="${f#"${src}/"}"
            if [[ ! -f "${dest}/${rel}" ]]; then
                cat_new+=("${rel}")
            elif ! diff -q "$f" "${dest}/${rel}" &>/dev/null; then
                cat_mod+=("${rel}")
            fi
        done < <(find "$src" -name '*.md' -type f -print0 2>/dev/null || true)
    fi

    # Deleted: files present in dest but not in source.
    if [[ -d "$dest" ]]; then
        while IFS= read -r -d '' f; do
            local rel="${f#"${dest}/"}"
            if [[ ! -f "${src}/${rel}" ]]; then
                cat_del+=("${rel}")
            fi
        done < <(find "$dest" -name '*.md' -type f -print0 2>/dev/null || true)
    fi

    # Render
    if (( ${#cat_new[@]} + ${#cat_mod[@]} + ${#cat_del[@]} > 0 )); then
        header "${label}"
        for f in "${cat_new[@]+"${cat_new[@]}"}"; do
            status_line "$GREEN" "[new]" "$f"
            new_files+=("${label}/${f}")
        done
        for f in "${cat_mod[@]+"${cat_mod[@]}"}"; do
            status_line "$YELLOW" "[modified]" "$f"
            mod_files+=("${label}/${f}")
            condensed_diff "${dest}/${f}" "${src}/${f}"
        done
        for f in "${cat_del[@]+"${cat_del[@]}"}"; do
            status_line "$RED" "[deleted]" "$f"
            del_files+=("${label}/${f}")
        done
    fi

    total_new=$(( total_new + ${#cat_new[@]} ))
    total_mod=$(( total_mod + ${#cat_mod[@]} ))
    total_del=$(( total_del + ${#cat_del[@]} ))
}

# compare_skills <label> <src_subdir> <dest_subdir>
#   Like compare_md_dir but includes all files, excluding __pycache__ and *.pyc.
compare_skills() {
    local label="$1" src="$2" dest="$3"

    local -a cat_new=() cat_mod=() cat_del=()

    if [[ -d "$src" ]]; then
        while IFS= read -r -d '' f; do
            local rel="${f#"${src}/"}"
            if [[ ! -f "${dest}/${rel}" ]]; then
                cat_new+=("${rel}")
            elif ! diff -q "$f" "${dest}/${rel}" &>/dev/null; then
                cat_mod+=("${rel}")
            fi
        done < <(find "$src" -type f \
            -not -path '*/__pycache__/*' \
            -not -name '*.pyc' \
            -print0 2>/dev/null || true)
    fi

    if [[ -d "$dest" ]]; then
        while IFS= read -r -d '' f; do
            local rel="${f#"${dest}/"}"
            # Skip .gitkeep — those are repo scaffolding, not config.
            [[ "$rel" == ".gitkeep" ]] && continue
            if [[ ! -f "${src}/${rel}" ]]; then
                cat_del+=("${rel}")
            fi
        done < <(find "$dest" -type f \
            -not -path '*/__pycache__/*' \
            -not -name '*.pyc' \
            -print0 2>/dev/null || true)
    fi

    if (( ${#cat_new[@]} + ${#cat_mod[@]} + ${#cat_del[@]} > 0 )); then
        header "${label}"
        for f in "${cat_new[@]+"${cat_new[@]}"}"; do
            status_line "$GREEN" "[new]" "$f"
            new_files+=("${label}/${f}")
        done
        for f in "${cat_mod[@]+"${cat_mod[@]}"}"; do
            status_line "$YELLOW" "[modified]" "$f"
            mod_files+=("${label}/${f}")
            condensed_diff "${dest}/${f}" "${src}/${f}"
        done
        for f in "${cat_del[@]+"${cat_del[@]}"}"; do
            status_line "$RED" "[deleted]" "$f"
            del_files+=("${label}/${f}")
        done
    fi

    total_new=$(( total_new + ${#cat_new[@]} ))
    total_mod=$(( total_mod + ${#cat_mod[@]} ))
    total_del=$(( total_del + ${#cat_del[@]} ))
}

# compare_file <label> <src_file> <dest_file>
#   Compare a single settings file.
compare_file() {
    local label="$1" src="$2" dest="$3"

    if [[ ! -f "$src" ]]; then
        # Source does not exist. If dest exists, treat as a deletion.
        if [[ -f "$dest" ]]; then
            header "${label}"
            status_line "$RED" "[deleted]" "$(basename "$dest")"
            del_files+=("${label}")
            total_del=$(( total_del + 1 ))
        fi
        return
    fi

    if [[ ! -f "$dest" ]]; then
        header "${label}"
        status_line "$GREEN" "[new]" "$(basename "$src")"
        new_files+=("${label}")
        total_new=$(( total_new + 1 ))
        return
    fi

    if ! diff -q "$src" "$dest" &>/dev/null; then
        header "${label}"
        status_line "$YELLOW" "[modified]" "$(basename "$src")"
        mod_files+=("${label}")
        total_mod=$(( total_mod + 1 ))
        condensed_diff "$dest" "$src"
    fi
}

# ---------------------------------------------------------------------------
# Source summary (file counts per category)
# ---------------------------------------------------------------------------
header "Source file counts"

count_md() {
    local dir="$1"
    if [[ -d "$dir" ]]; then
        find "$dir" -name '*.md' -type f 2>/dev/null | wc -l | tr -d ' '
    else
        echo 0
    fi
}

count_skills() {
    local dir="$1"
    if [[ -d "$dir" ]]; then
        find "$dir" -type f -not -path '*/__pycache__/*' -not -name '*.pyc' 2>/dev/null | wc -l | tr -d ' '
    else
        echo 0
    fi
}

info "agents/   $(count_md "${SOURCE_DIR}/agents") .md file(s)"
info "commands/ $(count_md "${SOURCE_DIR}/commands") .md file(s)"
info "skills/   $(count_skills "${SOURCE_DIR}/skills") file(s) (excl. __pycache__/*.pyc)"
info "settings.json       $(if [[ -f "${SOURCE_DIR}/settings.json" ]]; then echo "found"; else echo "not found"; fi)"
info "settings.local.json $(if [[ -f "${SOURCE_DIR}/settings.local.json" ]]; then echo "found"; else echo "not found"; fi)"

# ---------------------------------------------------------------------------
# Diff preview
# ---------------------------------------------------------------------------
header "Diff preview"

compare_md_dir  "agents"   "${SOURCE_DIR}/agents"   "${DEST_DIR}/agents"
compare_md_dir  "commands" "${SOURCE_DIR}/commands"  "${DEST_DIR}/commands"
compare_skills  "skills"   "${SOURCE_DIR}/skills"    "${DEST_DIR}/skills"
compare_file    "settings.json"       "${SOURCE_DIR}/settings.json"       "${DEST_DIR}/settings.json"
compare_file    "settings.local.json" "${SOURCE_DIR}/settings.local.json" "${DEST_DIR}/settings.local.json"

# ---------------------------------------------------------------------------
# Totals
# ---------------------------------------------------------------------------
total=$(( total_new + total_mod + total_del ))

if (( total == 0 )); then
    printf "\n%sEverything is up to date.%s\n" "${GREEN}" "${RESET}"
    exit 0
fi

printf "\n%sSummary:%s " "${BOLD}" "${RESET}"
printf "%s%d new%s, " "${GREEN}" "$total_new" "${RESET}"
printf "%s%d modified%s, " "${YELLOW}" "$total_mod" "${RESET}"
printf "%s%d deleted%s " "${RED}" "$total_del" "${RESET}"
printf "(%d total)\n" "$total"

# In dry-run mode, stop here.
if $DRY_RUN; then
    printf "\n%sDry-run complete. No changes were applied.%s\n" "${CYAN}" "${RESET}"
    exit 0
fi

# ---------------------------------------------------------------------------
# Prompt for confirmation
# ---------------------------------------------------------------------------
printf "\nApply these changes? [y/N] "
read -r answer
if [[ ! "$answer" =~ ^[Yy]$ ]]; then
    info "Aborted. No changes were made."
    exit 0
fi

# ---------------------------------------------------------------------------
# Apply changes
# ---------------------------------------------------------------------------
header "Applying changes..."

applied=0

# sync_md_dir <src> <dest>
#   Mirror a directory of .md files. Uses rsync if available, otherwise
#   manual cp + delete.
sync_md_dir() {
    local src="$1" dest="$2"

    # Ensure destination exists.
    mkdir -p "$dest"

    if [[ ! -d "$src" ]]; then
        # Source directory missing — delete all .md in dest to mirror.
        find "$dest" -name '*.md' -type f -delete 2>/dev/null || true
        return
    fi

    if command -v rsync &>/dev/null; then
        rsync -a --delete --include='*.md' --exclude='*' "${src}/" "${dest}/"
    else
        # Manual mirror: copy all .md from src, then delete .md in dest that
        # are not in src.
        find "$src" -name '*.md' -type f -print0 | while IFS= read -r -d '' f; do
            local rel="${f#"${src}/"}"
            local target_dir
            target_dir="$(dirname "${dest}/${rel}")"
            mkdir -p "$target_dir"
            cp "$f" "${dest}/${rel}"
        done

        find "$dest" -name '*.md' -type f -print0 | while IFS= read -r -d '' f; do
            local rel="${f#"${dest}/"}"
            if [[ ! -f "${src}/${rel}" ]]; then
                rm "$f"
            fi
        done
    fi
}

# sync_skills <src> <dest>
#   Mirror the skills directory, excluding __pycache__ and *.pyc.
sync_skills() {
    local src="$1" dest="$2"

    mkdir -p "$dest"

    if [[ ! -d "$src" ]]; then
        # Remove everything except .gitkeep.
        find "$dest" -type f -not -name '.gitkeep' -delete 2>/dev/null || true
        find "$dest" -mindepth 1 -type d -empty -delete 2>/dev/null || true
        return
    fi

    if command -v rsync &>/dev/null; then
        rsync -a --delete \
            --exclude='__pycache__/' \
            --exclude='*.pyc' \
            "${src}/" "${dest}/"
    else
        # Copy files from src, excluding __pycache__ and *.pyc.
        find "$src" -type f \
            -not -path '*/__pycache__/*' \
            -not -name '*.pyc' \
            -print0 | while IFS= read -r -d '' f; do
            local rel="${f#"${src}/"}"
            local target_dir
            target_dir="$(dirname "${dest}/${rel}")"
            mkdir -p "$target_dir"
            cp "$f" "${dest}/${rel}"
        done

        # Delete files in dest that are not in src.
        find "$dest" -type f \
            -not -path '*/__pycache__/*' \
            -not -name '*.pyc' \
            -not -name '.gitkeep' \
            -print0 | while IFS= read -r -d '' f; do
            local rel="${f#"${dest}/"}"
            if [[ ! -f "${src}/${rel}" ]]; then
                rm "$f"
            fi
        done

        # Clean up empty directories.
        find "$dest" -mindepth 1 -type d -empty -delete 2>/dev/null || true
    fi
}

# sync_file <src> <dest>
sync_file() {
    local src="$1" dest="$2"

    if [[ -f "$src" ]]; then
        cp "$src" "$dest"
    elif [[ -f "$dest" ]]; then
        rm "$dest"
    fi
}

# --- agents ---
sync_md_dir "${SOURCE_DIR}/agents" "${DEST_DIR}/agents"
success "agents/ synced"
applied=$(( applied + 1 ))

# --- commands ---
sync_md_dir "${SOURCE_DIR}/commands" "${DEST_DIR}/commands"
success "commands/ synced"
applied=$(( applied + 1 ))

# --- skills ---
sync_skills "${SOURCE_DIR}/skills" "${DEST_DIR}/skills"
success "skills/ synced"
applied=$(( applied + 1 ))

# --- settings.json ---
sync_file "${SOURCE_DIR}/settings.json" "${DEST_DIR}/settings.json"
success "settings.json synced"
applied=$(( applied + 1 ))

# --- settings.local.json ---
sync_file "${SOURCE_DIR}/settings.local.json" "${DEST_DIR}/settings.local.json"
success "settings.local.json synced"
applied=$(( applied + 1 ))

# ---------------------------------------------------------------------------
# Done
# ---------------------------------------------------------------------------
printf "\n%sDone.%s %d categories synced, %d change(s) applied.\n" \
    "${GREEN}" "${RESET}" "$applied" "$total"
