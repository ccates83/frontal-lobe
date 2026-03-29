#!/usr/bin/env bash
# convert.sh — Convert agent, command, and skill markdown files between
#               Claude Code format and OpenCode format.
#
# Usage:
#   scripts/convert.sh --to-opencode              # Convert claude-code/ → opencode/
#   scripts/convert.sh --to-claude                 # Convert opencode/ → claude-code/
#   scripts/convert.sh --to-opencode --dry-run     # Preview only
#   scripts/convert.sh --to-opencode --file agents/web-builder.md  # Convert one file
#   scripts/convert.sh --help

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
${BOLD}Claude Code <-> OpenCode Config Converter${RESET}

Convert agent, command, and skill markdown files between
Claude Code format and OpenCode format.

${BOLD}Usage:${RESET}
  $(basename "$0") --to-opencode [options]    Convert claude-code/ -> opencode/
  $(basename "$0") --to-claude  [options]     Convert opencode/ -> claude-code/

${BOLD}Options:${RESET}
  --dry-run          Show what would be done without making changes.
  --file <path>      Convert a single file (relative to source dir,
                     e.g., agents/web-builder.md).
  --help             Show this help message and exit.

${BOLD}Examples:${RESET}
  $(basename "$0") --to-opencode                              # Full conversion
  $(basename "$0") --to-opencode --dry-run                    # Preview only
  $(basename "$0") --to-opencode --file agents/web-builder.md # Single file
  $(basename "$0") --to-claude                                # Reverse conversion
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
CLAUDE_DIR="${REPO_ROOT}/claude-code"
OPENCODE_DIR="${REPO_ROOT}/opencode"

# ---------------------------------------------------------------------------
# Parse arguments
# ---------------------------------------------------------------------------
DIRECTION=""
DRY_RUN=false
SINGLE_FILE=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        --help|-h)
            usage
            exit 0
            ;;
        --to-opencode)
            DIRECTION="to-opencode"
            shift
            ;;
        --to-claude)
            DIRECTION="to-claude"
            shift
            ;;
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        --file)
            if [[ -z "${2:-}" ]]; then
                err "--file requires a path argument"
                exit 1
            fi
            SINGLE_FILE="$2"
            shift 2
            ;;
        *)
            err "Unknown option: $1"
            usage
            exit 1
            ;;
    esac
done

if [[ -z "$DIRECTION" ]]; then
    err "You must specify --to-opencode or --to-claude"
    usage
    exit 1
fi

# ---------------------------------------------------------------------------
# Counters
# ---------------------------------------------------------------------------
COUNT_CONVERTED=0
COUNT_SKIPPED=0
COUNT_ERRORS=0

# ---------------------------------------------------------------------------
# Frontmatter parsing
#
# parse_frontmatter <file>
#   Reads a markdown file and outputs two sections separated by a line
#   containing only "---BODY---":
#     1. The YAML frontmatter lines (without the --- delimiters)
#     2. The body content after the closing ---
#
#   If the file has no frontmatter, outputs "---BODY---" immediately
#   followed by the entire file content.
# ---------------------------------------------------------------------------
parse_frontmatter() {
    local file="$1"
    local in_frontmatter=false
    local found_open=false
    local found_close=false
    local frontmatter=""
    local body=""
    local line_num=0

    while IFS= read -r line || [[ -n "$line" ]]; do
        line_num=$(( line_num + 1 ))
        if [[ $line_num -eq 1 ]] && [[ "$line" == "---" ]]; then
            found_open=true
            in_frontmatter=true
            continue
        fi
        if $in_frontmatter; then
            if [[ "$line" == "---" ]]; then
                found_close=true
                in_frontmatter=false
                continue
            fi
            if [[ -n "$frontmatter" ]]; then
                frontmatter="${frontmatter}
${line}"
            else
                frontmatter="${line}"
            fi
        else
            if [[ -n "$body" ]]; then
                body="${body}
${line}"
            else
                body="${line}"
            fi
        fi
    done < "$file"

    if $found_open && $found_close; then
        printf '%s\n' "$frontmatter"
        printf '%s\n' "---BODY---"
        printf '%s\n' "$body"
    else
        printf '%s\n' "---BODY---"
        # Re-read entire file as body
        cat "$file"
    fi
}

# ---------------------------------------------------------------------------
# get_field <fieldname> <frontmatter_text>
#   Extract a single YAML field value. Handles quoted strings (including
#   multiline with \n escapes). Returns empty string if not found.
# ---------------------------------------------------------------------------
get_field() {
    local field="$1"
    local fm="$2"
    local value=""

    # Try to match the field line (with optional leading whitespace for nested YAML)
    while IFS= read -r line; do
        if [[ "$line" =~ ^[[:space:]]*${field}:\ *(.*) ]]; then
            value="${BASH_REMATCH[1]}"
            # Strip leading/trailing whitespace
            value="${value#"${value%%[![:space:]]*}"}"
            value="${value%"${value##*[![:space:]]}"}"
            # Strip surrounding quotes if present
            if [[ "$value" =~ ^\"(.*)\"$ ]]; then
                value="${BASH_REMATCH[1]}"
            elif [[ "$value" =~ ^\'(.*)\'$ ]]; then
                value="${BASH_REMATCH[1]}"
            fi
            printf '%s' "$value"
            return
        fi
    done <<< "$fm"
    printf ''
}

# ---------------------------------------------------------------------------
# Tools parsing helpers
# ---------------------------------------------------------------------------

# has_tool <tools_csv> <tool_name>
#   Returns 0 (true) if the tool is in the comma-separated list.
has_tool() {
    local tools="$1"
    local tool="$2"
    # Normalize: remove spaces around commas
    local normalized
    normalized="$(printf '%s' "$tools" | sed 's/ *, */,/g')"
    local IFS=','
    for t in $normalized; do
        if [[ "$t" == "$tool" ]]; then
            return 0
        fi
    done
    return 1
}

# ---------------------------------------------------------------------------
# Body text conversion
# ---------------------------------------------------------------------------
convert_body_to_opencode() {
    local body="$1"
    # CLAUDE.md -> AGENTS.md
    body="$(printf '%s' "$body" | sed 's/CLAUDE\.md/AGENTS.md/g')"
    # claude --agent -> opencode
    body="$(printf '%s' "$body" | sed 's/claude --agent/opencode/g')"
    # the Agent tool -> the task tool (case variants)
    body="$(printf '%s' "$body" | sed 's/the Agent tool/the task tool/g')"
    body="$(printf '%s' "$body" | sed 's/the agent tool/the task tool/g')"
    body="$(printf '%s' "$body" | sed 's/The Agent tool/The task tool/g')"
    body="$(printf '%s' "$body" | sed 's/The agent tool/The task tool/g')"
    # ~/.claude/ -> ~/.config/opencode/
    body="$(printf '%s' "$body" | sed 's|~/\.claude/|~/.config/opencode/|g')"
    # claude-code/ -> opencode/ (path references)
    body="$(printf '%s' "$body" | sed 's|claude-code/|opencode/|g')"
    # Launch `agent-name` -> Use the task tool to invoke `@agent-name`
    body="$(printf '%s' "$body" | sed 's/Launch `\([^`]*\)`/Use the task tool to invoke `@\1`/g')"
    printf '%s' "$body"
}

convert_body_to_claude() {
    local body="$1"
    # AGENTS.md -> CLAUDE.md
    body="$(printf '%s' "$body" | sed 's/AGENTS\.md/CLAUDE.md/g')"
    # the task tool -> the Agent tool (must come before opencode replacement)
    body="$(printf '%s' "$body" | sed 's/the task tool/the Agent tool/g')"
    body="$(printf '%s' "$body" | sed 's/The task tool/The Agent tool/g')"
    # Use the task tool to invoke `@agent-name` -> Launch `agent-name`
    body="$(printf '%s' "$body" | sed 's/Use the task tool to invoke `@\([^`]*\)`/Launch `\1`/g')"
    # ~/.config/opencode/ -> ~/.claude/ (must come before generic opencode/ replacement)
    body="$(printf '%s' "$body" | sed 's|~/\.config/opencode/|~/.claude/|g')"
    # opencode/ (path references) -> claude-code/
    body="$(printf '%s' "$body" | sed 's|opencode/|claude-code/|g')"
    # opencode (standalone CLI references — not followed by / or preceded by /)
    # Replace backtick-wrapped `opencode` and space-delimited opencode
    body="$(printf '%s' "$body" | sed 's|`opencode |`claude --agent |g')"
    body="$(printf '%s' "$body" | sed 's|Run opencode|Run claude --agent|g')"
    body="$(printf '%s' "$body" | sed 's|run opencode|run claude --agent|g')"
    body="$(printf '%s' "$body" | sed 's|via opencode|via claude --agent|g')"
    printf '%s' "$body"
}

# ---------------------------------------------------------------------------
# Agent conversion: Claude Code -> OpenCode
# ---------------------------------------------------------------------------
convert_agent_to_opencode() {
    local src_file="$1"
    local dest_file="$2"
    local filename
    filename="$(basename "$src_file" .md)"

    # Parse the source file
    local parsed
    parsed="$(parse_frontmatter "$src_file")"

    # Split into frontmatter and body
    local fm=""
    local body=""
    local in_body=false
    while IFS= read -r line; do
        if [[ "$line" == "---BODY---" ]]; then
            in_body=true
            continue
        fi
        if $in_body; then
            if [[ -n "$body" ]]; then
                body="${body}
${line}"
            else
                body="${line}"
            fi
        else
            if [[ -n "$fm" ]]; then
                fm="${fm}
${line}"
            else
                fm="${line}"
            fi
        fi
    done <<< "$parsed"

    # Extract fields from frontmatter
    local description tools model color
    description="$(get_field "description" "$fm")"
    tools="$(get_field "tools" "$fm")"
    model="$(get_field "model" "$fm")"
    color="$(get_field "color" "$fm")"

    # Convert tools -> permission block
    local edit_perm="deny"
    local bash_perm="deny"
    local webfetch_perm="deny"
    local task_perm="deny"

    if has_tool "$tools" "Write" || has_tool "$tools" "Edit"; then
        edit_perm="allow"
    fi
    if has_tool "$tools" "Bash"; then
        bash_perm="allow"
    fi
    if has_tool "$tools" "WebFetch" || has_tool "$tools" "WebSearch"; then
        webfetch_perm="allow"
    fi
    if has_tool "$tools" "Agent" || has_tool "$tools" "TaskCreate" || \
       has_tool "$tools" "TaskUpdate" || has_tool "$tools" "TaskList" || \
       has_tool "$tools" "TaskGet"; then
        task_perm="allow"
    fi

    # Convert model
    local new_model
    case "$model" in
        opus)   new_model="anthropic/claude-sonnet-4-5" ;;
        sonnet) new_model="anthropic/claude-sonnet-4-5" ;;
        haiku)  new_model="anthropic/claude-haiku-4-5" ;;
        *)      new_model="anthropic/claude-sonnet-4-5" ;;
    esac

    # Determine mode
    local mode="subagent"
    if [[ "$filename" == "frontal-lobe" ]]; then
        mode="primary"
    fi

    # Convert body
    local new_body
    new_body="$(convert_body_to_opencode "$body")"

    # Build output
    local output="---
description: \"${description}\"
model: ${new_model}
permission:
  edit: ${edit_perm}
  bash: ${bash_perm}
  webfetch: ${webfetch_perm}
  task: ${task_perm}
color: ${color}
mode: ${mode}
---
${new_body}"

    if $DRY_RUN; then
        info "(dry-run) Would convert agent: $(basename "$src_file")"
        return
    fi

    # Ensure destination directory exists
    mkdir -p "$(dirname "$dest_file")"
    printf '%s\n' "$output" > "$dest_file"
    # Preserve permissions from source
    chmod --reference="$src_file" "$dest_file" 2>/dev/null || \
        chmod "$(stat -f '%Lp' "$src_file" 2>/dev/null || echo '644')" "$dest_file" 2>/dev/null || true
}

# ---------------------------------------------------------------------------
# Agent conversion: OpenCode -> Claude Code
# ---------------------------------------------------------------------------
convert_agent_to_claude() {
    local src_file="$1"
    local dest_file="$2"
    local filename
    filename="$(basename "$src_file" .md)"

    # Parse the source file
    local parsed
    parsed="$(parse_frontmatter "$src_file")"

    local fm=""
    local body=""
    local in_body=false
    while IFS= read -r line; do
        if [[ "$line" == "---BODY---" ]]; then
            in_body=true
            continue
        fi
        if $in_body; then
            if [[ -n "$body" ]]; then
                body="${body}
${line}"
            else
                body="${line}"
            fi
        else
            if [[ -n "$fm" ]]; then
                fm="${fm}
${line}"
            else
                fm="${line}"
            fi
        fi
    done <<< "$parsed"

    # Extract fields
    local description model color
    description="$(get_field "description" "$fm")"
    model="$(get_field "model" "$fm")"
    color="$(get_field "color" "$fm")"

    # Extract permission fields
    local edit_perm bash_perm webfetch_perm task_perm
    edit_perm="$(get_field "edit" "$fm")"
    bash_perm="$(get_field "bash" "$fm")"
    webfetch_perm="$(get_field "webfetch" "$fm")"
    task_perm="$(get_field "task" "$fm")"

    # Build tools list — Glob, Grep, Read are always included
    local tools_list="Glob, Grep, Read"

    if [[ "$edit_perm" == "allow" ]]; then
        tools_list="${tools_list}, Write, Edit"
    fi
    if [[ "$bash_perm" == "allow" ]]; then
        tools_list="${tools_list}, Bash"
    fi
    if [[ "$webfetch_perm" == "allow" ]]; then
        tools_list="${tools_list}, WebFetch, WebSearch"
    fi
    if [[ "$task_perm" == "allow" ]]; then
        tools_list="${tools_list}, Agent, TaskCreate, TaskUpdate, TaskList, TaskGet"
    fi

    # Convert model
    local new_model
    if [[ "$model" == *"haiku"* ]]; then
        new_model="haiku"
    elif [[ "$edit_perm" == "allow" ]] || [[ "$task_perm" == "allow" ]]; then
        new_model="opus"
    else
        new_model="sonnet"
    fi

    # Convert body
    local new_body
    new_body="$(convert_body_to_claude "$body")"

    # Build output
    local output="---
name: ${filename}
description: \"${description}\"
tools: ${tools_list}
model: ${new_model}
color: ${color}
---
${new_body}"

    if $DRY_RUN; then
        info "(dry-run) Would convert agent: $(basename "$src_file")"
        return
    fi

    mkdir -p "$(dirname "$dest_file")"
    printf '%s\n' "$output" > "$dest_file"
    chmod --reference="$src_file" "$dest_file" 2>/dev/null || \
        chmod "$(stat -f '%Lp' "$src_file" 2>/dev/null || echo '644')" "$dest_file" 2>/dev/null || true
}

# ---------------------------------------------------------------------------
# Command conversion: Claude Code -> OpenCode
# ---------------------------------------------------------------------------
convert_command_to_opencode() {
    local src_file="$1"
    local dest_file="$2"
    local filename
    filename="$(basename "$src_file" .md)"

    local parsed
    parsed="$(parse_frontmatter "$src_file")"

    local fm=""
    local body=""
    local in_body=false
    while IFS= read -r line; do
        if [[ "$line" == "---BODY---" ]]; then
            in_body=true
            continue
        fi
        if $in_body; then
            if [[ -n "$body" ]]; then
                body="${body}
${line}"
            else
                body="${line}"
            fi
        else
            if [[ -n "$fm" ]]; then
                fm="${fm}
${line}"
            else
                fm="${line}"
            fi
        fi
    done <<< "$parsed"

    local description
    description="$(get_field "description" "$fm")"

    # Determine agent assignment based on command type
    local agent="frontal-lobe"

    # Build/test/run commands
    case "$filename" in
        *-build|*-test|commit|xcode-cleanup)
            agent="build"
            ;;
        *-review|*-audit)
            agent="plan"
            ;;
        *-new-feature|*-refactor|brainstorm|docs-write|docs-prd|docs-epic|docs-adr|docs-changelog|api-design|data-model|data-migrate|devops-new-service|macos-distribute|gh-*)
            agent="frontal-lobe"
            ;;
    esac

    # Convert body
    local new_body
    new_body="$(convert_body_to_opencode "$body")"
    # Additional command-specific: Launch `agent-name` already handled in convert_body_to_opencode

    # Build output — if there was frontmatter, write new frontmatter
    local output
    if [[ -n "$fm" ]]; then
        output="---
description: \"${description}\"
agent: ${agent}
---
${new_body}"
    else
        # No frontmatter in source (like commit.md) — add minimal frontmatter
        # Use first line as description if available
        local first_line
        first_line="$(printf '%s' "$new_body" | head -1)"
        output="---
description: \"${first_line}\"
agent: ${agent}
---
${new_body}"
    fi

    if $DRY_RUN; then
        info "(dry-run) Would convert command: $(basename "$src_file")"
        return
    fi

    mkdir -p "$(dirname "$dest_file")"
    printf '%s\n' "$output" > "$dest_file"
    chmod --reference="$src_file" "$dest_file" 2>/dev/null || \
        chmod "$(stat -f '%Lp' "$src_file" 2>/dev/null || echo '644')" "$dest_file" 2>/dev/null || true
}

# ---------------------------------------------------------------------------
# Command conversion: OpenCode -> Claude Code
# ---------------------------------------------------------------------------
convert_command_to_claude() {
    local src_file="$1"
    local dest_file="$2"

    local parsed
    parsed="$(parse_frontmatter "$src_file")"

    local fm=""
    local body=""
    local in_body=false
    while IFS= read -r line; do
        if [[ "$line" == "---BODY---" ]]; then
            in_body=true
            continue
        fi
        if $in_body; then
            if [[ -n "$body" ]]; then
                body="${body}
${line}"
            else
                body="${line}"
            fi
        else
            if [[ -n "$fm" ]]; then
                fm="${fm}
${line}"
            else
                fm="${line}"
            fi
        fi
    done <<< "$parsed"

    local description
    description="$(get_field "description" "$fm")"

    # Generate argument-hint: check if body references $ARGUMENTS
    local arg_hint=""
    if printf '%s' "$body" | grep -q '\$ARGUMENTS'; then
        # Try to extract hint from description or use generic
        arg_hint="Provide your input"
    fi

    # Convert body
    local new_body
    new_body="$(convert_body_to_claude "$body")"

    # Build output
    local output
    if [[ -n "$arg_hint" ]]; then
        output="---
description: \"${description}\"
argument-hint: \"${arg_hint}\"
---
${new_body}"
    elif [[ -n "$fm" ]]; then
        output="---
description: \"${description}\"
---
${new_body}"
    else
        # No frontmatter at all — just write converted body
        output="${new_body}"
    fi

    if $DRY_RUN; then
        info "(dry-run) Would convert command: $(basename "$src_file")"
        return
    fi

    mkdir -p "$(dirname "$dest_file")"
    printf '%s\n' "$output" > "$dest_file"
    chmod --reference="$src_file" "$dest_file" 2>/dev/null || \
        chmod "$(stat -f '%Lp' "$src_file" 2>/dev/null || echo '644')" "$dest_file" 2>/dev/null || true
}

# ---------------------------------------------------------------------------
# Skill conversion: Claude Code -> OpenCode
# ---------------------------------------------------------------------------
convert_skill_to_opencode() {
    local src_file="$1"
    local dest_file="$2"

    local parsed
    parsed="$(parse_frontmatter "$src_file")"

    local fm=""
    local body=""
    local in_body=false
    while IFS= read -r line; do
        if [[ "$line" == "---BODY---" ]]; then
            in_body=true
            continue
        fi
        if $in_body; then
            if [[ -n "$body" ]]; then
                body="${body}
${line}"
            else
                body="${line}"
            fi
        else
            if [[ -n "$fm" ]]; then
                fm="${fm}
${line}"
            else
                fm="${line}"
            fi
        fi
    done <<< "$parsed"

    if [[ -z "$fm" ]]; then
        # No frontmatter — just do body conversion
        local new_body
        new_body="$(convert_body_to_opencode "$body")"
        if $DRY_RUN; then
            info "(dry-run) Would convert skill: $(basename "$src_file")"
            return
        fi
        mkdir -p "$(dirname "$dest_file")"
        printf '%s\n' "$new_body" > "$dest_file"
        return
    fi

    local name description
    name="$(get_field "name" "$fm")"
    description="$(get_field "description" "$fm")"

    local new_body
    new_body="$(convert_body_to_opencode "$body")"

    # Rebuild frontmatter with compatibility field
    local output="---
name: ${name}
description: \"${description}\"
compatibility: opencode
---
${new_body}"

    if $DRY_RUN; then
        info "(dry-run) Would convert skill: $(basename "$src_file")"
        return
    fi

    mkdir -p "$(dirname "$dest_file")"
    printf '%s\n' "$output" > "$dest_file"
    chmod --reference="$src_file" "$dest_file" 2>/dev/null || \
        chmod "$(stat -f '%Lp' "$src_file" 2>/dev/null || echo '644')" "$dest_file" 2>/dev/null || true
}

# ---------------------------------------------------------------------------
# Skill conversion: OpenCode -> Claude Code
# ---------------------------------------------------------------------------
convert_skill_to_claude() {
    local src_file="$1"
    local dest_file="$2"

    local parsed
    parsed="$(parse_frontmatter "$src_file")"

    local fm=""
    local body=""
    local in_body=false
    while IFS= read -r line; do
        if [[ "$line" == "---BODY---" ]]; then
            in_body=true
            continue
        fi
        if $in_body; then
            if [[ -n "$body" ]]; then
                body="${body}
${line}"
            else
                body="${line}"
            fi
        else
            if [[ -n "$fm" ]]; then
                fm="${fm}
${line}"
            else
                fm="${line}"
            fi
        fi
    done <<< "$parsed"

    if [[ -z "$fm" ]]; then
        local new_body
        new_body="$(convert_body_to_claude "$body")"
        if $DRY_RUN; then
            info "(dry-run) Would convert skill: $(basename "$src_file")"
            return
        fi
        mkdir -p "$(dirname "$dest_file")"
        printf '%s\n' "$new_body" > "$dest_file"
        return
    fi

    local name description
    name="$(get_field "name" "$fm")"
    description="$(get_field "description" "$fm")"

    local new_body
    new_body="$(convert_body_to_claude "$body")"

    # Rebuild frontmatter without compatibility field
    local output="---
name: ${name}
description: \"${description}\"
---
${new_body}"

    if $DRY_RUN; then
        info "(dry-run) Would convert skill: $(basename "$src_file")"
        return
    fi

    mkdir -p "$(dirname "$dest_file")"
    printf '%s\n' "$output" > "$dest_file"
    chmod --reference="$src_file" "$dest_file" 2>/dev/null || \
        chmod "$(stat -f '%Lp' "$src_file" 2>/dev/null || echo '644')" "$dest_file" 2>/dev/null || true
}

# ---------------------------------------------------------------------------
# Process a single file — dispatch to the right converter
# ---------------------------------------------------------------------------
process_file() {
    local rel_path="$1"   # e.g., agents/web-builder.md
    local src_dir="$2"    # Source base directory
    local dest_dir="$3"   # Destination base directory
    local direction="$4"  # to-opencode or to-claude

    local src_file="${src_dir}/${rel_path}"
    local dest_file="${dest_dir}/${rel_path}"

    if [[ ! -f "$src_file" ]]; then
        err "Source file not found: ${src_file}"
        (( COUNT_ERRORS++ )) || true
        return
    fi

    # Determine category from path
    local category
    category="$(dirname "$rel_path")"
    # Handle nested skill paths like skills/web-patterns/SKILL.md
    if [[ "$category" == skills/* ]] || [[ "$category" == "skills" ]]; then
        category="skills"
    fi

    case "$category" in
        agents)
            if [[ "$direction" == "to-opencode" ]]; then
                convert_agent_to_opencode "$src_file" "$dest_file"
            else
                convert_agent_to_claude "$src_file" "$dest_file"
            fi
            ;;
        commands)
            if [[ "$direction" == "to-opencode" ]]; then
                convert_command_to_opencode "$src_file" "$dest_file"
            else
                convert_command_to_claude "$src_file" "$dest_file"
            fi
            ;;
        skills)
            if [[ "$direction" == "to-opencode" ]]; then
                convert_skill_to_opencode "$src_file" "$dest_file"
            else
                convert_skill_to_claude "$src_file" "$dest_file"
            fi
            ;;
        *)
            warn "Skipping unknown category: ${rel_path}"
            (( COUNT_SKIPPED++ )) || true
            return
            ;;
    esac

    (( COUNT_CONVERTED++ )) || true
}

# ---------------------------------------------------------------------------
# Collect all convertible files from a source directory
# ---------------------------------------------------------------------------
collect_files() {
    local src_dir="$1"
    # Outputs file paths to stdout, one per line. Caller captures with readarray.

    # Agents
    if [[ -d "${src_dir}/agents" ]]; then
        while IFS= read -r -d '' f; do
            printf '%s\n' "${f#"${src_dir}/"}"
        done < <(find "${src_dir}/agents" -maxdepth 1 -name '*.md' -type f -print0 2>/dev/null | sort -z)
    fi

    # Commands
    if [[ -d "${src_dir}/commands" ]]; then
        while IFS= read -r -d '' f; do
            printf '%s\n' "${f#"${src_dir}/"}"
        done < <(find "${src_dir}/commands" -maxdepth 1 -name '*.md' -type f -print0 2>/dev/null | sort -z)
    fi

    # Skills — all .md files recursively
    if [[ -d "${src_dir}/skills" ]]; then
        while IFS= read -r -d '' f; do
            printf '%s\n' "${f#"${src_dir}/"}"
        done < <(find "${src_dir}/skills" -name '*.md' -type f -print0 2>/dev/null | sort -z)
    fi
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------
if [[ "$DIRECTION" == "to-opencode" ]]; then
    SRC_DIR="$CLAUDE_DIR"
    DEST_DIR="$OPENCODE_DIR"
    header "Converting: Claude Code -> OpenCode"
else
    SRC_DIR="$OPENCODE_DIR"
    DEST_DIR="$CLAUDE_DIR"
    header "Converting: OpenCode -> Claude Code"
fi

echo ""
info "Source:      ${SRC_DIR}"
info "Destination: ${DEST_DIR}"
if $DRY_RUN; then
    info "Dry run:     enabled (no changes will be made)"
fi
echo ""

# Validate source exists
if [[ ! -d "$SRC_DIR" ]]; then
    err "Source directory not found: ${SRC_DIR}"
    exit 1
fi

# Warn about config files
warn "Settings files (settings.json, settings.local.json, opencode.jsonc) are NOT"
warn "auto-converted — their structures are too different. Convert manually if needed."
echo ""

if [[ -n "$SINGLE_FILE" ]]; then
    # Single file mode
    header "Converting single file"
    process_file "$SINGLE_FILE" "$SRC_DIR" "$DEST_DIR" "$DIRECTION"
else
    # Full conversion
    declare -a all_files=()
    while IFS= read -r line; do
        [[ -n "$line" ]] && all_files+=("$line")
    done < <(collect_files "$SRC_DIR")

    if [[ ${#all_files[@]} -eq 0 ]]; then
        warn "No .md files found in ${SRC_DIR}"
        exit 0
    fi

    # Process agents
    header "Agents"
    for f in "${all_files[@]}"; do
        if [[ "$f" == agents/* ]]; then
            ok "$(basename "$f")"
            process_file "$f" "$SRC_DIR" "$DEST_DIR" "$DIRECTION"
        fi
    done

    # Process commands
    header "Commands"
    for f in "${all_files[@]}"; do
        if [[ "$f" == commands/* ]]; then
            ok "$(basename "$f")"
            process_file "$f" "$SRC_DIR" "$DEST_DIR" "$DIRECTION"
        fi
    done

    # Process skills
    header "Skills"
    for f in "${all_files[@]}"; do
        if [[ "$f" == skills/* ]]; then
            ok "$f"
            process_file "$f" "$SRC_DIR" "$DEST_DIR" "$DIRECTION"
        fi
    done
fi

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------
header "Summary"
echo ""
ok "Converted:  ${COUNT_CONVERTED}"
if [[ $COUNT_SKIPPED -gt 0 ]]; then
    warn "Skipped:    ${COUNT_SKIPPED}"
fi
if [[ $COUNT_ERRORS -gt 0 ]]; then
    err "Errors:     ${COUNT_ERRORS}"
fi
echo ""

if $DRY_RUN; then
    info "Dry run complete. No changes were made."
fi
