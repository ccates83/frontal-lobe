#!/usr/bin/env bash
# install.sh — Install Claude Code configs from this repo to the local machine via symlinks.
#
# Usage:
#   scripts/install.sh                  # Install to ~/.claude/ (root-level config)
#   scripts/install.sh --project <path> # Install to <path>/.claude/ (project-level config)
#   scripts/install.sh --dry-run        # Show what would be done without making changes
#   scripts/install.sh --help           # Show usage information
#
# Root-level install symlinks: agents/, commands/, skills/, settings.json, settings.local.json
# Project-level install symlinks: agents/, commands/, skills/ only (no settings files)

set -euo pipefail

# ---------------------------------------------------------------------------
# Color support (disable if stdout is not a terminal or TERM is dumb)
# ---------------------------------------------------------------------------
if [[ -t 1 ]] && [[ "${TERM:-dumb}" != "dumb" ]]; then
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[0;33m'
    BLUE='\033[0;34m'
    CYAN='\033[0;36m'
    BOLD='\033[1m'
    RESET='\033[0m'
else
    RED='' GREEN='' YELLOW='' BLUE='' CYAN='' BOLD='' RESET=''
fi

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------
info()    { printf "${BLUE}[info]${RESET}  %s\n" "$*"; }
ok()      { printf "${GREEN}[ok]${RESET}    %s\n" "$*"; }
warn()    { printf "${YELLOW}[warn]${RESET}  %s\n" "$*"; }
err()     { printf "${RED}[error]${RESET} %s\n" "$*" >&2; }
header()  { printf "\n${BOLD}${CYAN}%s${RESET}\n" "$*"; }

usage() {
    cat <<EOF
${BOLD}Claude Code Config Installer${RESET}

Install Claude Code configurations from this repo to the local machine
by creating symlinks from the repo's claude-code/ directory.

${BOLD}Usage:${RESET}
  $(basename "$0") [options]

${BOLD}Options:${RESET}
  --project <path>   Install to <path>/.claude/ (project-level config).
                     Only installs agents/, commands/, and skills/ (no settings).
  --dry-run          Show what would be done without making any changes.
  --help             Show this help message and exit.

${BOLD}Examples:${RESET}
  $(basename "$0")                          # Root-level install to ~/.claude/
  $(basename "$0") --project ~/my-project   # Project-level install
  $(basename "$0") --dry-run                # Preview changes
EOF
}

# ---------------------------------------------------------------------------
# Resolve repo root
# ---------------------------------------------------------------------------
resolve_repo_root() {
    # Try git first, fall back to resolving relative to this script's location.
    if git rev-parse --show-toplevel &>/dev/null; then
        git rev-parse --show-toplevel
    else
        local script_dir
        script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
        # Script lives in <repo>/scripts/, so repo root is one level up.
        dirname "$script_dir"
    fi
}

REPO_ROOT="$(resolve_repo_root)"
SOURCE_DIR="${REPO_ROOT}/claude-code"

# ---------------------------------------------------------------------------
# Parse arguments
# ---------------------------------------------------------------------------
DRY_RUN=false
PROJECT_PATH=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        --help|-h)
            usage
            exit 0
            ;;
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        --project)
            if [[ -z "${2:-}" ]]; then
                err "--project requires a path argument"
                exit 1
            fi
            PROJECT_PATH="$2"
            shift 2
            ;;
        *)
            err "Unknown option: $1"
            usage
            exit 1
            ;;
    esac
done

# ---------------------------------------------------------------------------
# Validate source directory exists
# ---------------------------------------------------------------------------
if [[ ! -d "$SOURCE_DIR" ]]; then
    err "claude-code/ directory not found at: ${SOURCE_DIR}"
    err "Run sync.sh first to populate the claude-code/ directory."
    exit 1
fi

# ---------------------------------------------------------------------------
# Determine target directory and install mode
# ---------------------------------------------------------------------------
IS_PROJECT=false
if [[ -n "$PROJECT_PATH" ]]; then
    IS_PROJECT=true
    # Resolve to absolute path
    if [[ "$PROJECT_PATH" != /* ]]; then
        PROJECT_PATH="$(cd "$PROJECT_PATH" 2>/dev/null && pwd)" || {
            err "Project path does not exist: $PROJECT_PATH"
            exit 1
        }
    fi
    TARGET_DIR="${PROJECT_PATH}/.claude"
else
    TARGET_DIR="${HOME}/.claude"
fi

# ---------------------------------------------------------------------------
# Counters for the summary
# ---------------------------------------------------------------------------
COUNT_LINKED=0
COUNT_SKIPPED=0
COUNT_BACKED_UP=0
COUNT_ALREADY=0

# Global "apply to all" choice: empty means ask each time.
# Values: backup, overwrite, skip
APPLY_ALL=""

# ---------------------------------------------------------------------------
# Conflict resolution — prompt user for action on an existing target
# ---------------------------------------------------------------------------
resolve_conflict() {
    local target="$1"
    local source="$2"

    # If a global choice has been made, use it.
    if [[ -n "$APPLY_ALL" ]]; then
        echo "$APPLY_ALL"
        return
    fi

    warn "Conflict: ${target} already exists"
    if [[ -L "$target" ]]; then
        local current_link
        current_link="$(readlink "$target")"
        warn "  Current symlink → ${current_link}"
    elif [[ -d "$target" ]]; then
        warn "  Existing directory"
    else
        warn "  Existing file"
    fi
    warn "  Desired link   → ${source}"
    printf "\n  Choose: [b]ackup  [o]verwrite  [s]kip  |  [B]ackup all  [O]verwrite all  [S]kip all\n  > "

    local choice
    read -r choice
    case "$choice" in
        b) echo "backup" ;;
        o) echo "overwrite" ;;
        s) echo "skip" ;;
        B) APPLY_ALL="backup";    echo "backup" ;;
        O) APPLY_ALL="overwrite"; echo "overwrite" ;;
        S) APPLY_ALL="skip";      echo "skip" ;;
        *)
            warn "Invalid choice, skipping."
            echo "skip"
            ;;
    esac
}

# ---------------------------------------------------------------------------
# Create a single symlink with conflict handling
# ---------------------------------------------------------------------------
create_symlink() {
    local source="$1"   # Absolute path to source file/dir in the repo
    local target="$2"   # Absolute path where the symlink should be created
    local label="$3"    # Human-readable label for display

    # Ensure the parent directory exists.
    local parent_dir
    parent_dir="$(dirname "$target")"

    if $DRY_RUN; then
        if [[ -L "$target" ]]; then
            local current
            current="$(readlink "$target")"
            if [[ "$current" == "$source" ]]; then
                ok "(dry-run) Already linked: ${label}"
                (( COUNT_ALREADY++ )) || true
            else
                info "(dry-run) Would resolve conflict: ${label}"
            fi
        elif [[ -e "$target" ]]; then
            info "(dry-run) Would resolve conflict: ${label}"
        else
            info "(dry-run) Would link: ${label} → ${source}"
            (( COUNT_LINKED++ )) || true
        fi
        return
    fi

    # Create parent directories if needed.
    if [[ ! -d "$parent_dir" ]]; then
        mkdir -p "$parent_dir"
        info "Created directory: ${parent_dir}"
    fi

    # Check what exists at the target path.
    if [[ -L "$target" ]]; then
        local current
        current="$(readlink "$target")"
        if [[ "$current" == "$source" ]]; then
            ok "Already linked: ${label}"
            (( COUNT_ALREADY++ )) || true
            return
        fi
        # Symlink exists but points elsewhere — conflict.
        local action
        action="$(resolve_conflict "$target" "$source")"
        case "$action" in
            backup)
                local backup="${target}.bak.$(date +%s)"
                mv "$target" "$backup"
                info "Backed up: ${target} → ${backup}"
                ln -s "$source" "$target"
                ok "Linked: ${label}"
                (( COUNT_BACKED_UP++ )) || true
                (( COUNT_LINKED++ )) || true
                ;;
            overwrite)
                rm -rf "$target"
                ln -s "$source" "$target"
                ok "Linked (overwritten): ${label}"
                (( COUNT_LINKED++ )) || true
                ;;
            skip)
                warn "Skipped: ${label}"
                (( COUNT_SKIPPED++ )) || true
                ;;
        esac
    elif [[ -e "$target" ]]; then
        # Regular file or directory exists — conflict.
        local action
        action="$(resolve_conflict "$target" "$source")"
        case "$action" in
            backup)
                local backup="${target}.bak.$(date +%s)"
                mv "$target" "$backup"
                info "Backed up: ${target} → ${backup}"
                ln -s "$source" "$target"
                ok "Linked: ${label}"
                (( COUNT_BACKED_UP++ )) || true
                (( COUNT_LINKED++ )) || true
                ;;
            overwrite)
                rm -rf "$target"
                ln -s "$source" "$target"
                ok "Linked (overwritten): ${label}"
                (( COUNT_LINKED++ )) || true
                ;;
            skip)
                warn "Skipped: ${label}"
                (( COUNT_SKIPPED++ )) || true
                ;;
        esac
    else
        # Nothing exists — create the symlink.
        ln -s "$source" "$target"
        ok "Linked: ${label}"
        (( COUNT_LINKED++ )) || true
    fi
}

# ---------------------------------------------------------------------------
# Main install logic
# ---------------------------------------------------------------------------
header "Claude Code Config Installer"
echo ""
info "Repo root:  ${REPO_ROOT}"
info "Source:     ${SOURCE_DIR}"
info "Target:    ${TARGET_DIR}"
if $IS_PROJECT; then
    info "Mode:      project-level (agents, commands, skills only)"
else
    info "Mode:      root-level (agents, commands, skills, settings)"
fi
if $DRY_RUN; then
    info "Dry run:   enabled (no changes will be made)"
fi
echo ""

# --- Agents: symlink each .md file individually ---
header "Agents"
agent_files=()
while IFS= read -r -d '' f; do
    agent_files+=("$f")
done < <(find "${SOURCE_DIR}/agents" -maxdepth 1 -name '*.md' -print0 2>/dev/null || true)

if [[ ${#agent_files[@]} -eq 0 ]]; then
    info "No agent .md files found in ${SOURCE_DIR}/agents/"
else
    for src in "${agent_files[@]}"; do
        filename="$(basename "$src")"
        create_symlink "$src" "${TARGET_DIR}/agents/${filename}" "agents/${filename}"
    done
fi

# --- Commands: symlink each .md file individually ---
header "Commands"
command_files=()
while IFS= read -r -d '' f; do
    command_files+=("$f")
done < <(find "${SOURCE_DIR}/commands" -maxdepth 1 -name '*.md' -print0 2>/dev/null || true)

if [[ ${#command_files[@]} -eq 0 ]]; then
    info "No command .md files found in ${SOURCE_DIR}/commands/"
else
    for src in "${command_files[@]}"; do
        filename="$(basename "$src")"
        create_symlink "$src" "${TARGET_DIR}/commands/${filename}" "commands/${filename}"
    done
fi

# --- Skills: symlink each skill subdirectory ---
header "Skills"
skill_dirs=()
while IFS= read -r -d '' d; do
    skill_dirs+=("$d")
done < <(find "${SOURCE_DIR}/skills" -mindepth 1 -maxdepth 1 -type d -print0 2>/dev/null || true)

if [[ ${#skill_dirs[@]} -eq 0 ]]; then
    info "No skill directories found in ${SOURCE_DIR}/skills/"
else
    for src in "${skill_dirs[@]}"; do
        dirname_part="$(basename "$src")"
        create_symlink "$src" "${TARGET_DIR}/skills/${dirname_part}" "skills/${dirname_part}"
    done
fi

# --- Settings files (root-level only) ---
if ! $IS_PROJECT; then
    header "Settings"

    if [[ -f "${SOURCE_DIR}/settings.json" ]]; then
        create_symlink "${SOURCE_DIR}/settings.json" "${TARGET_DIR}/settings.json" "settings.json"
    else
        info "No settings.json found in source, skipping."
    fi

    if [[ -f "${SOURCE_DIR}/settings.local.json" ]]; then
        create_symlink "${SOURCE_DIR}/settings.local.json" "${TARGET_DIR}/settings.local.json" "settings.local.json"
    else
        info "No settings.local.json found in source, skipping."
    fi
fi

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------
header "Summary"
echo ""
ok "Linked:      ${COUNT_LINKED}"
ok "Already OK:  ${COUNT_ALREADY}"
if [[ $COUNT_BACKED_UP -gt 0 ]]; then
    info "Backed up:   ${COUNT_BACKED_UP}"
fi
if [[ $COUNT_SKIPPED -gt 0 ]]; then
    warn "Skipped:     ${COUNT_SKIPPED}"
fi
echo ""

if $DRY_RUN; then
    info "Dry run complete. No changes were made."
fi
