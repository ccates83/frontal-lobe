#!/usr/bin/env bash
# sync.sh — Unified config sync for Claude Code and OpenCode.
#
# Pulls live configuration from ~/.claude/ and ~/.config/opencode/ back into
# the repo (claude-code/ and opencode/ respectively), then cross-converts
# changed files so both tools stay in sync.
#
# Usage:
#   scripts/sync.sh                    # Sync both tools + cross-convert
#   scripts/sync.sh --claude           # Sync Claude Code only + convert to OpenCode
#   scripts/sync.sh --opencode         # Sync OpenCode only + convert to Claude Code
#   scripts/sync.sh --no-convert       # Sync without cross-conversion
#   scripts/sync.sh --dry-run          # Preview changes only
#   scripts/sync.sh --help

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
SYNC_CLAUDE=false
SYNC_OPENCODE=false
NO_CONVERT=false
YES=false
PREFER=""

CLAUDE_SOURCE="${HOME}/.claude"
OPENCODE_SOURCE="${HOME}/.config/opencode"

# Change counters
claude_changes=0
opencode_changes=0
convert_to_opencode=0
convert_to_claude=0

# Track which files changed for cross-conversion
declare -a claude_changed_files=()
declare -a opencode_changed_files=()

# Conflict tracking
declare -a conflict_files=()
# Global conflict resolution: "" means ask each time, c/o/s means apply to all
conflict_resolve_all=""

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------
info()    { printf "%s[info]%s  %s\n" "${CYAN}" "${RESET}" "$*"; }
success() { printf "%s[ok]%s    %s\n" "${GREEN}" "${RESET}" "$*"; }
warn()    { printf "%s[warn]%s  %s\n" "${YELLOW}" "${RESET}" "$*"; }
error()   { printf "%s[error]%s %s\n" "${RED}" "${RESET}" "$*" >&2; }
header()  { printf "\n%s%s%s\n" "${BOLD}" "$*" "${RESET}"; }

status_line() {
    local color="$1" label="$2" path="$3"
    printf "  %s%-10s%s %s\n" "${color}" "${label}" "${RESET}" "${path}"
}

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
${BOLD}sync.sh${RESET} — Unified Config Sync for Claude Code + OpenCode.

${BOLD}USAGE${RESET}
    scripts/sync.sh [OPTIONS]

${BOLD}OPTIONS${RESET}
    --claude      Sync Claude Code only (+ convert to OpenCode).
    --opencode    Sync OpenCode only (+ convert to Claude Code).
    --no-convert  Sync without cross-conversion.
    --dry-run     Show what would change without applying anything.
    --yes, -y     Apply changes without prompting for confirmation.
    --prefer X    Auto-resolve conflicts (X = claude, opencode, or skip).
                  Implies --yes.
    --help        Show this help message and exit.

    Default (no flags): sync both tools and cross-convert.

${BOLD}WHAT GETS SYNCED${RESET}
    Claude Code:
      ~/.claude/agents/              -> claude-code/agents/
      ~/.claude/commands/            -> claude-code/commands/
      ~/.claude/skills/              -> claude-code/skills/
      ~/.claude/settings.json        -> claude-code/settings.json
      ~/.claude/settings.local.json  -> claude-code/settings.local.json

    OpenCode:
      ~/.config/opencode/agents/     -> opencode/agents/
      ~/.config/opencode/commands/   -> opencode/commands/
      ~/.config/opencode/skills/     -> opencode/skills/

${BOLD}CROSS-CONVERSION${RESET}
    After syncing, changed files are automatically converted between
    formats using scripts/convert.sh, so edits in either tool propagate
    to the other.

EOF
    exit 0
}

# ---------------------------------------------------------------------------
# Argument parsing
# ---------------------------------------------------------------------------
while (( $# > 0 )); do
    case "$1" in
        --claude)     SYNC_CLAUDE=true ;;
        --opencode)   SYNC_OPENCODE=true ;;
        --no-convert) NO_CONVERT=true ;;
        --dry-run)    DRY_RUN=true ;;
        --yes|-y)     YES=true ;;
        --prefer)
            shift
            case "${1:-}" in
                claude|opencode|skip)
                    PREFER="$1"
                    ;;
                *)
                    error "--prefer requires: claude, opencode, or skip"
                    exit 1
                    ;;
            esac
            ;;
        --help|-h)    usage ;;
        *)
            error "Unknown option: $1"
            printf "Run with --help for usage.\n" >&2
            exit 1
            ;;
    esac
    shift
done

# --prefer implies --yes
if [[ -n "$PREFER" ]]; then
    YES=true
fi

# Default: sync both if neither specified
if ! $SYNC_CLAUDE && ! $SYNC_OPENCODE; then
    SYNC_CLAUDE=true
    SYNC_OPENCODE=true
fi

# ---------------------------------------------------------------------------
# Resolve repo root
# ---------------------------------------------------------------------------
if git rev-parse --show-toplevel &>/dev/null; then
    REPO_ROOT="$(git rev-parse --show-toplevel)"
else
    REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
fi

CLAUDE_DEST="${REPO_ROOT}/claude-code"
OPENCODE_DEST="${REPO_ROOT}/opencode"

# ---------------------------------------------------------------------------
# Banner
# ---------------------------------------------------------------------------
header "Unified Config Sync -- Claude Code + OpenCode"
echo ""
if $SYNC_CLAUDE; then
    info "Sources:       ${CLAUDE_SOURCE}/ (Claude Code)"
fi
if $SYNC_OPENCODE; then
    info "               ${OPENCODE_SOURCE}/ (OpenCode)"
fi
if $SYNC_CLAUDE; then
    info "Destinations:  ${CLAUDE_DEST}/ (repo)"
fi
if $SYNC_OPENCODE; then
    info "               ${OPENCODE_DEST}/ (repo)"
fi
if $NO_CONVERT; then
    info "Cross-convert: disabled"
else
    info "Cross-convert: enabled"
fi
if $DRY_RUN; then
    warn "Dry-run mode -- no changes will be applied."
fi
if $YES; then
    info "Auto-apply:    enabled (--yes)"
fi
if [[ -n "$PREFER" ]]; then
    info "Prefer:        ${PREFER} (--prefer)"
fi

# ---------------------------------------------------------------------------
# Pre-flight checks
# ---------------------------------------------------------------------------
if $SYNC_CLAUDE && [[ ! -d "${CLAUDE_SOURCE}" ]]; then
    warn "Claude Code source ${CLAUDE_SOURCE}/ does not exist. Skipping."
    SYNC_CLAUDE=false
fi

if $SYNC_OPENCODE && [[ ! -d "${OPENCODE_SOURCE}" ]]; then
    warn "OpenCode source ${OPENCODE_SOURCE}/ does not exist. Skipping."
    SYNC_OPENCODE=false
fi

if ! $SYNC_CLAUDE && ! $SYNC_OPENCODE; then
    error "No source directories found. Nothing to sync."
    exit 1
fi

# ---------------------------------------------------------------------------
# Counting helpers
# ---------------------------------------------------------------------------
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

# ---------------------------------------------------------------------------
# Compare functions — reused from original sync.sh
#
# These populate per-tool arrays and track changes.
# ---------------------------------------------------------------------------

# compare_md_dir <label> <src_subdir> <dest_subdir> <tool_name>
compare_md_dir() {
    local label="$1" src="$2" dest="$3" tool="$4"

    local -a cat_new=() cat_mod=() cat_del=()

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

    if [[ -d "$dest" ]]; then
        while IFS= read -r -d '' f; do
            local rel="${f#"${dest}/"}"
            if [[ ! -f "${src}/${rel}" ]]; then
                cat_del+=("${rel}")
            fi
        done < <(find "$dest" -name '*.md' -type f -print0 2>/dev/null || true)
    fi

    if (( ${#cat_new[@]} + ${#cat_mod[@]} + ${#cat_del[@]} > 0 )); then
        printf "  %s%s/%s\n" "${BOLD}" "${label}" "${RESET}"
        for f in "${cat_new[@]+"${cat_new[@]}"}"; do
            status_line "$GREEN" "[new]" "$f"
            if [[ "$tool" == "claude" ]]; then
                claude_changed_files+=("${label}/${f}")
            else
                opencode_changed_files+=("${label}/${f}")
            fi
        done
        for f in "${cat_mod[@]+"${cat_mod[@]}"}"; do
            status_line "$YELLOW" "[modified]" "$f"
            condensed_diff "${dest}/${f}" "${src}/${f}"
            if [[ "$tool" == "claude" ]]; then
                claude_changed_files+=("${label}/${f}")
            else
                opencode_changed_files+=("${label}/${f}")
            fi
        done
        for f in "${cat_del[@]+"${cat_del[@]}"}"; do
            status_line "$RED" "[deleted]" "$f"
            if [[ "$tool" == "claude" ]]; then
                claude_changed_files+=("${label}/${f}")
            else
                opencode_changed_files+=("${label}/${f}")
            fi
        done
    fi

    local count=$(( ${#cat_new[@]} + ${#cat_mod[@]} + ${#cat_del[@]} ))
    if [[ "$tool" == "claude" ]]; then
        claude_changes=$(( claude_changes + count ))
    else
        opencode_changes=$(( opencode_changes + count ))
    fi
}

# compare_skills <label> <src_subdir> <dest_subdir> <tool_name>
compare_skills() {
    local label="$1" src="$2" dest="$3" tool="$4"

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
        printf "  %s%s/%s\n" "${BOLD}" "${label}" "${RESET}"
        for f in "${cat_new[@]+"${cat_new[@]}"}"; do
            status_line "$GREEN" "[new]" "$f"
            if [[ "$tool" == "claude" ]]; then
                claude_changed_files+=("${label}/${f}")
            else
                opencode_changed_files+=("${label}/${f}")
            fi
        done
        for f in "${cat_mod[@]+"${cat_mod[@]}"}"; do
            status_line "$YELLOW" "[modified]" "$f"
            condensed_diff "${dest}/${f}" "${src}/${f}"
            if [[ "$tool" == "claude" ]]; then
                claude_changed_files+=("${label}/${f}")
            else
                opencode_changed_files+=("${label}/${f}")
            fi
        done
        for f in "${cat_del[@]+"${cat_del[@]}"}"; do
            status_line "$RED" "[deleted]" "$f"
            if [[ "$tool" == "claude" ]]; then
                claude_changed_files+=("${label}/${f}")
            else
                opencode_changed_files+=("${label}/${f}")
            fi
        done
    fi

    local count=$(( ${#cat_new[@]} + ${#cat_mod[@]} + ${#cat_del[@]} ))
    if [[ "$tool" == "claude" ]]; then
        claude_changes=$(( claude_changes + count ))
    else
        opencode_changes=$(( opencode_changes + count ))
    fi
}

# compare_file <label> <src_file> <dest_file> <tool_name>
compare_file() {
    local label="$1" src="$2" dest="$3" tool="$4"

    if [[ ! -f "$src" ]]; then
        if [[ -f "$dest" ]]; then
            printf "  %s%s%s\n" "${BOLD}" "${label}" "${RESET}"
            status_line "$RED" "[deleted]" "$(basename "$dest")"
            if [[ "$tool" == "claude" ]]; then
                claude_changes=$(( claude_changes + 1 ))
                claude_changed_files+=("${label}")
            else
                opencode_changes=$(( opencode_changes + 1 ))
                opencode_changed_files+=("${label}")
            fi
        fi
        return
    fi

    if [[ ! -f "$dest" ]]; then
        printf "  %s%s%s\n" "${BOLD}" "${label}" "${RESET}"
        status_line "$GREEN" "[new]" "$(basename "$src")"
        if [[ "$tool" == "claude" ]]; then
            claude_changes=$(( claude_changes + 1 ))
            claude_changed_files+=("${label}")
        else
            opencode_changes=$(( opencode_changes + 1 ))
            opencode_changed_files+=("${label}")
        fi
        return
    fi

    if ! diff -q "$src" "$dest" &>/dev/null; then
        printf "  %s%s%s\n" "${BOLD}" "${label}" "${RESET}"
        status_line "$YELLOW" "[modified]" "$(basename "$src")"
        condensed_diff "$dest" "$src"
        if [[ "$tool" == "claude" ]]; then
            claude_changes=$(( claude_changes + 1 ))
            claude_changed_files+=("${label}")
        else
            opencode_changes=$(( opencode_changes + 1 ))
            opencode_changed_files+=("${label}")
        fi
    fi
}

# ---------------------------------------------------------------------------
# Diff preview
# ---------------------------------------------------------------------------
if $SYNC_CLAUDE; then
    header "=== Claude Code (~/.claude/) ==="
    compare_md_dir  "agents"   "${CLAUDE_SOURCE}/agents"   "${CLAUDE_DEST}/agents"   "claude"
    compare_md_dir  "commands" "${CLAUDE_SOURCE}/commands"  "${CLAUDE_DEST}/commands" "claude"
    compare_skills  "skills"   "${CLAUDE_SOURCE}/skills"    "${CLAUDE_DEST}/skills"   "claude"
    compare_file    "settings.json"       "${CLAUDE_SOURCE}/settings.json"       "${CLAUDE_DEST}/settings.json"       "claude"
    compare_file    "settings.local.json" "${CLAUDE_SOURCE}/settings.local.json" "${CLAUDE_DEST}/settings.local.json" "claude"

    if (( claude_changes == 0 )); then
        info "No changes detected."
    fi
fi

if $SYNC_OPENCODE; then
    header "=== OpenCode (~/.config/opencode/) ==="
    compare_md_dir  "agents"   "${OPENCODE_SOURCE}/agents"   "${OPENCODE_DEST}/agents"   "opencode"
    compare_md_dir  "commands" "${OPENCODE_SOURCE}/commands"  "${OPENCODE_DEST}/commands" "opencode"
    compare_skills  "skills"   "${OPENCODE_SOURCE}/skills"    "${OPENCODE_DEST}/skills"   "opencode"

    if (( opencode_changes == 0 )); then
        info "No changes detected."
    fi
fi

# ---------------------------------------------------------------------------
# Conflict detection
# ---------------------------------------------------------------------------
if $SYNC_CLAUDE && $SYNC_OPENCODE && (( ${#claude_changed_files[@]} > 0 )) && (( ${#opencode_changed_files[@]} > 0 )); then
    # Find files changed in BOTH tools
    for cf in "${claude_changed_files[@]}"; do
        for of in "${opencode_changed_files[@]}"; do
            if [[ "$cf" == "$of" ]]; then
                conflict_files+=("$cf")
            fi
        done
    done

    if (( ${#conflict_files[@]} > 0 )); then
        header "Conflicts detected"
        warn "The following files were modified in BOTH ~/.claude/ and ~/.config/opencode/:"
        for f in "${conflict_files[@]}"; do
            printf "  %s%s%s %s\n" "${RED}${BOLD}" "[conflict]" "${RESET}" "$f"
        done
        echo ""
    fi
fi

# ---------------------------------------------------------------------------
# Totals
# ---------------------------------------------------------------------------
total=$(( claude_changes + opencode_changes ))

if (( total == 0 )); then
    printf "\n%sEverything is up to date.%s\n" "${GREEN}" "${RESET}"
    exit 0
fi

printf "\n%sSummary:%s " "${BOLD}" "${RESET}"
if $SYNC_CLAUDE; then
    printf "Claude Code: %s%d change(s)%s  " "${CYAN}" "$claude_changes" "${RESET}"
fi
if $SYNC_OPENCODE; then
    printf "OpenCode: %s%d change(s)%s  " "${CYAN}" "$opencode_changes" "${RESET}"
fi
if (( ${#conflict_files[@]} > 0 )); then
    printf "%s%d conflict(s)%s" "${RED}" "${#conflict_files[@]}" "${RESET}"
fi
echo ""

# In dry-run mode, stop here.
if $DRY_RUN; then
    printf "\n%sDry-run complete. No changes were applied.%s\n" "${CYAN}" "${RESET}"
    exit 0
fi

# ---------------------------------------------------------------------------
# Prompt for confirmation
# ---------------------------------------------------------------------------
# If stdin is not a terminal and --yes wasn't passed, abort gracefully
if ! $YES && ! [[ -t 0 ]]; then
    warn "Non-interactive mode detected. Use --yes to auto-apply or --dry-run to preview."
    exit 1
fi

if ! $YES; then
    printf "\nApply %d changes? [y/N] " "$total"
    read -r answer
    if [[ ! "$answer" =~ ^[Yy]$ ]]; then
        info "Aborted. No changes were made."
        exit 0
    fi
fi

# ---------------------------------------------------------------------------
# Resolve conflicts interactively
# ---------------------------------------------------------------------------
# Returns: "claude", "opencode", or "skip"
resolve_conflict() {
    local file="$1"

    # If --prefer was specified, use it automatically
    if [[ -n "$PREFER" ]]; then
        echo "$PREFER"
        return
    fi

    # If user already chose "apply to all", use that
    if [[ -n "$conflict_resolve_all" ]]; then
        case "$conflict_resolve_all" in
            c) echo "claude" ;;
            o) echo "opencode" ;;
            s) echo "skip" ;;
        esac
        return
    fi

    printf "\n%sConflict:%s %s\n" "${YELLOW}${BOLD}" "${RESET}" "$file"
    printf "  Both ~/.claude/ and ~/.config/opencode/ have different versions.\n"
    printf "  [c]laude   — Use Claude Code version, convert to OpenCode\n"
    printf "  [o]pencode — Use OpenCode version, convert to Claude Code\n"
    printf "  [s]kip     — Don't sync this file\n"
    printf "  [C/O/S]    — Apply choice to ALL remaining conflicts\n"
    printf "  Choice: "
    read -r choice

    case "$choice" in
        c) echo "claude" ;;
        o) echo "opencode" ;;
        s) echo "skip" ;;
        C) conflict_resolve_all="c"; echo "claude" ;;
        O) conflict_resolve_all="o"; echo "opencode" ;;
        S) conflict_resolve_all="s"; echo "skip" ;;
        *) warn "Invalid choice, skipping."; echo "skip" ;;
    esac
}

# Build a set of conflict resolutions
declare -A conflict_resolutions=()
if (( ${#conflict_files[@]} > 0 )); then
    header "Resolving conflicts..."
    for f in "${conflict_files[@]}"; do
        resolution="$(resolve_conflict "$f")"
        conflict_resolutions["$f"]="$resolution"
        info "$f -> $resolution"
    done
fi

# ---------------------------------------------------------------------------
# Sync functions
# ---------------------------------------------------------------------------

# sync_md_dir <src> <dest>
sync_md_dir() {
    local src="$1" dest="$2"
    mkdir -p "$dest"

    if [[ ! -d "$src" ]]; then
        find "$dest" -name '*.md' -type f -delete 2>/dev/null || true
        return
    fi

    if command -v rsync &>/dev/null; then
        rsync -a --delete --include='*.md' --exclude='*' "${src}/" "${dest}/"
    else
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
sync_skills() {
    local src="$1" dest="$2"
    mkdir -p "$dest"

    if [[ ! -d "$src" ]]; then
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

# is_conflicted <relative_path>
#   Returns 0 if the file is in the conflict list.
is_conflicted() {
    local path="$1"
    for cf in "${conflict_files[@]+"${conflict_files[@]}"}"; do
        if [[ "$cf" == "$path" ]]; then
            return 0
        fi
    done
    return 1
}

# should_sync_for_tool <relative_path> <tool_name>
#   Returns 0 if this file should be synced for the given tool.
#   For conflicts, checks the resolution.
should_sync_for_tool() {
    local path="$1" tool="$2"

    if ! is_conflicted "$path"; then
        return 0
    fi

    local resolution="${conflict_resolutions[$path]:-skip}"
    if [[ "$resolution" == "$tool" ]]; then
        return 0
    fi
    return 1
}

# ---------------------------------------------------------------------------
# Apply changes
# ---------------------------------------------------------------------------
header "Applying changes..."

claude_synced=0
opencode_synced=0

# Track which tool had real changes (for cross-conversion)
claude_had_changes=false
opencode_had_changes=false

# --- Claude Code sync ---
if $SYNC_CLAUDE && (( claude_changes > 0 )); then
    header "Syncing Claude Code..."

    # For conflicts, we need selective syncing. If there are no conflicts,
    # do a full mirror. If there are conflicts, we still do a full mirror
    # but then handle conflicts by overwriting specific files afterward.
    has_claude_conflicts=false
    if (( ${#conflict_files[@]} > 0 )); then
        for cf in "${conflict_files[@]}"; do
            resolution="${conflict_resolutions[$cf]:-skip}"
            if [[ "$resolution" != "claude" ]]; then
                has_claude_conflicts=true
                break
            fi
        done
    fi

    # Always sync Claude Code dirs
    sync_md_dir "${CLAUDE_SOURCE}/agents" "${CLAUDE_DEST}/agents"
    success "agents/ synced"

    sync_md_dir "${CLAUDE_SOURCE}/commands" "${CLAUDE_DEST}/commands"
    success "commands/ synced"

    sync_skills "${CLAUDE_SOURCE}/skills" "${CLAUDE_DEST}/skills"
    success "skills/ synced"

    sync_file "${CLAUDE_SOURCE}/settings.json" "${CLAUDE_DEST}/settings.json"
    success "settings.json synced"

    sync_file "${CLAUDE_SOURCE}/settings.local.json" "${CLAUDE_DEST}/settings.local.json"
    success "settings.local.json synced"

    claude_synced=$claude_changes
    claude_had_changes=true

    # Handle conflicts: if a conflict was resolved as "opencode" or "skip",
    # revert that file in claude-code/ back to the repo version (via git checkout).
    if $has_claude_conflicts; then
        for cf in "${conflict_files[@]}"; do
            resolution="${conflict_resolutions[$cf]:-skip}"
            if [[ "$resolution" == "opencode" ]] || [[ "$resolution" == "skip" ]]; then
                local_file="${CLAUDE_DEST}/${cf}"
                if git show "HEAD:claude-code/${cf}" &>/dev/null 2>&1; then
                    git show "HEAD:claude-code/${cf}" > "$local_file" 2>/dev/null || true
                    warn "Reverted ${cf} (conflict resolved as ${resolution})"
                    claude_synced=$(( claude_synced - 1 ))
                fi
            fi
        done
    fi
fi

# --- OpenCode sync ---
if $SYNC_OPENCODE && (( opencode_changes > 0 )); then
    header "Syncing OpenCode..."

    has_opencode_conflicts=false
    if (( ${#conflict_files[@]} > 0 )); then
        for cf in "${conflict_files[@]}"; do
            resolution="${conflict_resolutions[$cf]:-skip}"
            if [[ "$resolution" != "opencode" ]]; then
                has_opencode_conflicts=true
                break
            fi
        done
    fi

    # Ensure opencode dest dirs exist
    mkdir -p "${OPENCODE_DEST}"

    sync_md_dir "${OPENCODE_SOURCE}/agents" "${OPENCODE_DEST}/agents"
    success "agents/ synced"

    sync_md_dir "${OPENCODE_SOURCE}/commands" "${OPENCODE_DEST}/commands"
    success "commands/ synced"

    sync_skills "${OPENCODE_SOURCE}/skills" "${OPENCODE_DEST}/skills"
    success "skills/ synced"

    opencode_synced=$opencode_changes
    opencode_had_changes=true

    # Handle conflicts: revert files resolved as "claude" or "skip"
    if $has_opencode_conflicts; then
        for cf in "${conflict_files[@]}"; do
            resolution="${conflict_resolutions[$cf]:-skip}"
            if [[ "$resolution" == "claude" ]] || [[ "$resolution" == "skip" ]]; then
                local_file="${OPENCODE_DEST}/${cf}"
                if git show "HEAD:opencode/${cf}" &>/dev/null 2>&1; then
                    git show "HEAD:opencode/${cf}" > "$local_file" 2>/dev/null || true
                    warn "Reverted ${cf} (conflict resolved as ${resolution})"
                    opencode_synced=$(( opencode_synced - 1 ))
                fi
            fi
        done
    fi
fi

# ---------------------------------------------------------------------------
# Cross-conversion
# ---------------------------------------------------------------------------
if ! $NO_CONVERT && [[ -f "${REPO_ROOT}/scripts/convert.sh" ]]; then
    header "Cross-converting..."

    if $claude_had_changes; then
        info "Converting Claude Code changes -> OpenCode..."
        if "${REPO_ROOT}/scripts/convert.sh" --to-opencode; then
            # Count how many agent/command/skill .md files are in claude changes
            for f in "${claude_changed_files[@]+"${claude_changed_files[@]}"}"; do
                # Only count files that are agents/commands/skills (not settings)
                case "$f" in
                    agents/*|commands/*|skills/*) convert_to_opencode=$(( convert_to_opencode + 1 )) ;;
                esac
            done
            success "Claude Code -> OpenCode conversion complete"
        else
            warn "Cross-conversion (Claude Code -> OpenCode) had errors."
        fi
    fi

    if $opencode_had_changes; then
        info "Converting OpenCode changes -> Claude Code..."
        if "${REPO_ROOT}/scripts/convert.sh" --to-claude; then
            for f in "${opencode_changed_files[@]+"${opencode_changed_files[@]}"}"; do
                case "$f" in
                    agents/*|commands/*|skills/*) convert_to_claude=$(( convert_to_claude + 1 )) ;;
                esac
            done
            success "OpenCode -> Claude Code conversion complete"
        else
            warn "Cross-conversion (OpenCode -> Claude Code) had errors."
        fi
    fi

    # Handle conflict-resolved conversions
    for cf in "${conflict_files[@]+"${conflict_files[@]}"}"; do
        resolution="${conflict_resolutions[$cf]:-skip}"
        case "$resolution" in
            claude)
                # Claude won: convert this specific file to opencode
                if "${REPO_ROOT}/scripts/convert.sh" --to-opencode --file "$cf" 2>/dev/null; then
                    info "Conflict-resolved: ${cf} (Claude Code -> OpenCode)"
                fi
                ;;
            opencode)
                # OpenCode won: convert this specific file to claude
                if "${REPO_ROOT}/scripts/convert.sh" --to-claude --file "$cf" 2>/dev/null; then
                    info "Conflict-resolved: ${cf} (OpenCode -> Claude Code)"
                fi
                ;;
        esac
    done

elif ! $NO_CONVERT; then
    warn "scripts/convert.sh not found. Skipping cross-conversion."
fi

# ---------------------------------------------------------------------------
# Final summary
# ---------------------------------------------------------------------------
header "Sync complete."
if $SYNC_CLAUDE; then
    printf "  Claude Code: %s%d change(s) synced%s\n" "${GREEN}" "$claude_synced" "${RESET}"
fi
if $SYNC_OPENCODE; then
    printf "  OpenCode:    %s%d change(s) synced%s\n" "${GREEN}" "$opencode_synced" "${RESET}"
fi
if ! $NO_CONVERT; then
    if (( convert_to_opencode > 0 )); then
        printf "  Cross-converted: %s%d file(s)%s (Claude Code -> OpenCode)\n" "${CYAN}" "$convert_to_opencode" "${RESET}"
    fi
    if (( convert_to_claude > 0 )); then
        printf "  Cross-converted: %s%d file(s)%s (OpenCode -> Claude Code)\n" "${CYAN}" "$convert_to_claude" "${RESET}"
    fi
    if (( convert_to_opencode == 0 )) && (( convert_to_claude == 0 )); then
        printf "  Cross-converted: %s0 files%s\n" "${DIM}" "${RESET}"
    fi
fi
if (( ${#conflict_files[@]} > 0 )); then
    local_skipped=0
    for cf in "${conflict_files[@]}"; do
        if [[ "${conflict_resolutions[$cf]:-skip}" == "skip" ]]; then
            local_skipped=$(( local_skipped + 1 ))
        fi
    done
    if (( local_skipped > 0 )); then
        printf "  Conflicts skipped: %s%d%s\n" "${YELLOW}" "$local_skipped" "${RESET}"
    fi
fi
echo ""
