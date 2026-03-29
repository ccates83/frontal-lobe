#!/usr/bin/env bash
# install.sh — Unified installer for Claude Code and OpenCode configs via symlinks.
#
# Usage:
#   scripts/install.sh                          # Install both (root-level)
#   scripts/install.sh --claude                 # Install Claude Code only
#   scripts/install.sh --opencode               # Install OpenCode only
#   scripts/install.sh --project /path/to/proj  # Install both to project (project-level)
#   scripts/install.sh --project /path --claude  # Install Claude Code to project only
#   scripts/install.sh --dry-run                # Preview changes
#   scripts/install.sh --help                   # Show usage information
#
# Root-level install symlinks:
#   Claude Code: claude-code/{agents,commands,skills}/*.md → ~/.claude/, plus settings.json, settings.local.json
#   OpenCode:    opencode/{agents,commands,skills}/*.md → ~/.config/opencode/, plus opencode.jsonc
#
# Project-level install symlinks:
#   Claude Code: → <project>/.claude/{agents,commands,skills}/  (no settings)
#   OpenCode:    → <project>/.opencode/{agents,commands,skills}/ (no settings)

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
${BOLD}Unified Config Installer — Claude Code + OpenCode${RESET}

Install Claude Code and OpenCode configurations from this repo to the
local machine by creating symlinks.

${BOLD}Usage:${RESET}
  $(basename "$0") [options]

${BOLD}Options:${RESET}
  --claude             Install Claude Code configs only.
  --opencode           Install OpenCode configs only.
  --project <path>     Install to <path>/.claude/ and/or <path>/.opencode/
                       (project-level config, no settings files).
  --dry-run            Show what would be done without making any changes.
  --help               Show this help message and exit.

${BOLD}Examples:${RESET}
  $(basename "$0")                              # Install both (root-level)
  $(basename "$0") --claude                     # Claude Code only
  $(basename "$0") --opencode                   # OpenCode only
  $(basename "$0") --project ~/my-project       # Both to project
  $(basename "$0") --project ~/my-project --claude  # Claude Code to project only
  $(basename "$0") --dry-run                    # Preview changes
EOF
}

# ---------------------------------------------------------------------------
# Resolve repo root
# ---------------------------------------------------------------------------
resolve_repo_root() {
    if git rev-parse --show-toplevel &>/dev/null; then
        git rev-parse --show-toplevel
    else
        local script_dir
        script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
        dirname "$script_dir"
    fi
}

REPO_ROOT="$(resolve_repo_root)"

# ---------------------------------------------------------------------------
# Parse arguments
# ---------------------------------------------------------------------------
DRY_RUN=false
PROJECT_PATH=""
INSTALL_CLAUDE=false
INSTALL_OPENCODE=false

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
        --claude)
            INSTALL_CLAUDE=true
            shift
            ;;
        --opencode)
            INSTALL_OPENCODE=true
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

# If neither --claude nor --opencode specified, install both.
if ! $INSTALL_CLAUDE && ! $INSTALL_OPENCODE; then
    INSTALL_CLAUDE=true
    INSTALL_OPENCODE=true
fi

# ---------------------------------------------------------------------------
# Determine project path (if any)
# ---------------------------------------------------------------------------
IS_PROJECT=false
if [[ -n "$PROJECT_PATH" ]]; then
    IS_PROJECT=true
    if [[ "$PROJECT_PATH" != /* ]]; then
        PROJECT_PATH="$(cd "$PROJECT_PATH" 2>/dev/null && pwd)" || {
            err "Project path does not exist: $PROJECT_PATH"
            exit 1
        }
    fi
fi

# ---------------------------------------------------------------------------
# Global counters for summary
# ---------------------------------------------------------------------------
COUNT_LINKED=0
COUNT_SKIPPED=0
COUNT_BACKED_UP=0
COUNT_ALREADY=0

# Per-tool counters
CLAUDE_LINKED=0
CLAUDE_ALREADY=0
OPENCODE_LINKED=0
OPENCODE_ALREADY=0

# Global "apply to all" choice: empty means ask each time.
# Values: backup, overwrite, skip
APPLY_ALL=""

# ---------------------------------------------------------------------------
# Conflict resolution — prompt user for action on an existing target
# ---------------------------------------------------------------------------
resolve_conflict() {
    local target="$1"
    local source="$2"

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

    local parent_dir
    parent_dir="$(dirname "$target")"

    if $DRY_RUN; then
        if [[ -L "$target" ]]; then
            local current
            current="$(readlink "$target")"
            if [[ "$current" == "$source" ]]; then
                ok "(dry-run) Already linked: ${label}"
                (( COUNT_ALREADY++ )) || true
                return 0  # already
            else
                info "(dry-run) Would resolve conflict: ${label}"
                return 1  # conflict, count as neither
            fi
        elif [[ -e "$target" ]]; then
            info "(dry-run) Would resolve conflict: ${label}"
            return 1
        else
            info "(dry-run) Would link: ${label} → ${source}"
            (( COUNT_LINKED++ )) || true
            return 2  # linked
        fi
    fi

    if [[ ! -d "$parent_dir" ]]; then
        mkdir -p "$parent_dir"
        info "Created directory: ${parent_dir}"
    fi

    if [[ -L "$target" ]]; then
        local current
        current="$(readlink "$target")"
        if [[ "$current" == "$source" ]]; then
            ok "Already linked: ${label}"
            (( COUNT_ALREADY++ )) || true
            return 0
        fi
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
                return 2
                ;;
            overwrite)
                rm -rf "$target"
                ln -s "$source" "$target"
                ok "Linked (overwritten): ${label}"
                (( COUNT_LINKED++ )) || true
                return 2
                ;;
            skip)
                warn "Skipped: ${label}"
                (( COUNT_SKIPPED++ )) || true
                return 1
                ;;
        esac
    elif [[ -e "$target" ]]; then
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
                return 2
                ;;
            overwrite)
                rm -rf "$target"
                ln -s "$source" "$target"
                ok "Linked (overwritten): ${label}"
                (( COUNT_LINKED++ )) || true
                return 2
                ;;
            skip)
                warn "Skipped: ${label}"
                (( COUNT_SKIPPED++ )) || true
                return 1
                ;;
        esac
    else
        ln -s "$source" "$target"
        ok "Linked: ${label}"
        (( COUNT_LINKED++ )) || true
        return 2
    fi
}

# ---------------------------------------------------------------------------
# install_tool — Install configs for a single tool
#
# Arguments:
#   $1  source_dir      Absolute path to source directory in repo (e.g., .../claude-code)
#   $2  target_dir      Absolute path to target directory (e.g., ~/.claude)
#   $3  tool_name       Human-readable name (e.g., "Claude Code")
#   $4  is_project      "true" or "false" — whether this is a project-level install
#   $5+ settings_files  Settings filenames to symlink (root-level only)
#
# Returns via global variables:
#   Sets TOOL_LINKED and TOOL_ALREADY for per-tool subtotals.
# ---------------------------------------------------------------------------
install_tool() {
    local source_dir="$1"
    local target_dir="$2"
    local tool_name="$3"
    local is_project="$4"
    shift 4
    local settings_files=("$@")

    # Track counts before this tool runs.
    local before_linked=$COUNT_LINKED
    local before_already=$COUNT_ALREADY

    if [[ ! -d "$source_dir" ]]; then
        warn "${tool_name}: source directory not found at ${source_dir}, skipping."
        TOOL_LINKED=0
        TOOL_ALREADY=0
        return
    fi

    header "${tool_name}"
    info "Source:  ${source_dir}"
    info "Target:  ${target_dir}"
    echo ""

    # --- Agents: symlink each .md file individually ---
    header "  Agents"
    local agent_files=()
    while IFS= read -r -d '' f; do
        agent_files+=("$f")
    done < <(find "${source_dir}/agents" -maxdepth 1 -name '*.md' -print0 2>/dev/null || true)

    if [[ ${#agent_files[@]} -eq 0 ]]; then
        info "No agent .md files found in ${source_dir}/agents/"
    else
        for src in "${agent_files[@]}"; do
            local filename
            filename="$(basename "$src")"
            create_symlink "$src" "${target_dir}/agents/${filename}" "${tool_name} > agents/${filename}" || true
        done
    fi

    # --- Commands: symlink each .md file individually ---
    header "  Commands"
    local command_files=()
    while IFS= read -r -d '' f; do
        command_files+=("$f")
    done < <(find "${source_dir}/commands" -maxdepth 1 -name '*.md' -print0 2>/dev/null || true)

    if [[ ${#command_files[@]} -eq 0 ]]; then
        info "No command .md files found in ${source_dir}/commands/"
    else
        for src in "${command_files[@]}"; do
            local filename
            filename="$(basename "$src")"
            create_symlink "$src" "${target_dir}/commands/${filename}" "${tool_name} > commands/${filename}" || true
        done
    fi

    # --- Skills: symlink each skill subdirectory ---
    header "  Skills"
    local skill_dirs=()
    while IFS= read -r -d '' d; do
        skill_dirs+=("$d")
    done < <(find "${source_dir}/skills" -mindepth 1 -maxdepth 1 -type d -print0 2>/dev/null || true)

    if [[ ${#skill_dirs[@]} -eq 0 ]]; then
        info "No skill directories found in ${source_dir}/skills/"
    else
        for src in "${skill_dirs[@]}"; do
            local dirname_part
            dirname_part="$(basename "$src")"
            create_symlink "$src" "${target_dir}/skills/${dirname_part}" "${tool_name} > skills/${dirname_part}" || true
        done
    fi

    # --- Settings files (root-level only) ---
    if [[ "$is_project" == "false" ]] && [[ ${#settings_files[@]} -gt 0 ]]; then
        header "  Settings"
        for settings_file in "${settings_files[@]}"; do
            if [[ -f "${source_dir}/${settings_file}" ]]; then
                create_symlink "${source_dir}/${settings_file}" "${target_dir}/${settings_file}" "${tool_name} > ${settings_file}" || true
            else
                info "No ${settings_file} found in source, skipping."
            fi
        done
    fi

    # Calculate per-tool subtotals.
    TOOL_LINKED=$(( COUNT_LINKED - before_linked ))
    TOOL_ALREADY=$(( COUNT_ALREADY - before_already ))
}

# ---------------------------------------------------------------------------
# Banner
# ---------------------------------------------------------------------------
header "Unified Config Installer — Claude Code + OpenCode"
echo ""
info "Repo root:    ${REPO_ROOT}"

# Build target descriptions for the banner.
BANNER_TARGETS=()
if $INSTALL_CLAUDE; then
    if $IS_PROJECT; then
        BANNER_TARGETS+=("${PROJECT_PATH}/.claude/ (Claude Code)")
    else
        BANNER_TARGETS+=("~/.claude/ (Claude Code)")
    fi
fi
if $INSTALL_OPENCODE; then
    if $IS_PROJECT; then
        BANNER_TARGETS+=("${PROJECT_PATH}/.opencode/ (OpenCode)")
    else
        BANNER_TARGETS+=("~/.config/opencode/ (OpenCode)")
    fi
fi

for i in "${!BANNER_TARGETS[@]}"; do
    if [[ $i -eq 0 ]]; then
        info "Targets:      ${BANNER_TARGETS[$i]}"
    else
        info "              ${BANNER_TARGETS[$i]}"
    fi
done

if $IS_PROJECT; then
    info "Mode:         project-level (agents, commands, skills only)"
else
    info "Mode:         root-level (agents, commands, skills, settings)"
fi
if $DRY_RUN; then
    info "Dry run:      enabled (no changes will be made)"
fi

# ---------------------------------------------------------------------------
# Run installs
# ---------------------------------------------------------------------------
CLAUDE_LINKED=0
CLAUDE_ALREADY=0
OPENCODE_LINKED=0
OPENCODE_ALREADY=0

if $INSTALL_CLAUDE; then
    if $IS_PROJECT; then
        install_tool "${REPO_ROOT}/claude-code" "${PROJECT_PATH}/.claude" "Claude Code" "true"
    else
        install_tool "${REPO_ROOT}/claude-code" "${HOME}/.claude" "Claude Code" "false" "settings.json" "settings.local.json"
    fi
    CLAUDE_LINKED=$TOOL_LINKED
    CLAUDE_ALREADY=$TOOL_ALREADY
fi

if $INSTALL_OPENCODE; then
    if $IS_PROJECT; then
        install_tool "${REPO_ROOT}/opencode" "${PROJECT_PATH}/.opencode" "OpenCode" "true"
    else
        install_tool "${REPO_ROOT}/opencode" "${HOME}/.config/opencode" "OpenCode" "false" "opencode.jsonc"
    fi
    OPENCODE_LINKED=$TOOL_LINKED
    OPENCODE_ALREADY=$TOOL_ALREADY
fi

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------
header "Summary"
echo ""

if $INSTALL_CLAUDE; then
    ok "Claude Code:  ${CLAUDE_LINKED} linked, ${CLAUDE_ALREADY} already OK"
fi
if $INSTALL_OPENCODE; then
    ok "OpenCode:     ${OPENCODE_LINKED} linked, ${OPENCODE_ALREADY} already OK"
fi

if $INSTALL_CLAUDE && $INSTALL_OPENCODE; then
    ok "Total:        ${COUNT_LINKED} linked, ${COUNT_ALREADY} already OK"
fi

if [[ $COUNT_BACKED_UP -gt 0 ]]; then
    info "Backed up:    ${COUNT_BACKED_UP}"
fi
if [[ $COUNT_SKIPPED -gt 0 ]]; then
    warn "Skipped:      ${COUNT_SKIPPED}"
fi
echo ""

if $DRY_RUN; then
    info "Dry run complete. No changes were made."
fi
