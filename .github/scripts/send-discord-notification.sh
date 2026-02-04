#!/bin/bash
# SpartanUI Discord Release Notification
#
# Sends a rich Discord embed notification for releases with:
# - Changelog content (truncated for Discord limits)
# - Download links (CurseForge, Wago, GitHub)
# - Support links (Discord, Issues, Roadmap)
#
# Usage: ./send-discord-notification.sh [changelog_file]
#
# Environment variables:
#   DISCORD_WEBHOOK_URL: Discord webhook URL (required)
#   GITHUB_REF: GitHub ref for version detection

set -e

# === CONFIGURATION ===
CHANGELOG_FILE="${1:-CHANGELOG.md}"
MAX_DESC_LENGTH=1800  # Discord limit is 2048, leave buffer for formatting

# Project URLs
CF_URL="https://www.curseforge.com/wow/addons/spartan-ui"
WAGO_URL="https://addons.wago.io/addons/vEGPqeN1"
GH_RELEASES="https://github.com/Wutname1/SpartanUI/releases"
GH_ISSUES="https://github.com/Wutname1/SpartanUI/issues"
GH_PROJECT="https://github.com/users/Wutname1/projects/2"
DISCORD_SUPPORT="https://discord.gg/Qc9TRBv"

# Colors (decimal values for Discord embeds)
COLOR_STABLE=5763719   # Green (#57F287)
COLOR_BETA=16776960    # Yellow (#FFFF00)

# Logging
log_info() { echo "[INFO] $1" >&2; }
log_error() { echo "[ERROR] $1" >&2; }

# === HELPER FUNCTIONS ===

# Escape string for JSON
json_escape() {
    local input="$1"
    python3 -c "import json,sys; print(json.dumps(sys.stdin.read()))" <<< "$input"
}

# Convert Unicode emojis to Discord shortcodes
convert_emojis_to_shortcodes() {
    local input="$1"
    python3 -c "
import sys
text = sys.stdin.read()
replacements = {
    '\U0001F3AF': ':dart:',      # 🎯
    '\U0001F680': ':rocket:',    # 🚀
    '\U0001F41B': ':bug:',       # 🐛
    '\U0001F4DD': ':memo:',      # 📝
    '\u26A0\uFE0F': ':warning:', # ⚠️
    '\u26A0': ':warning:',       # ⚠ (without variation selector)
    '\U0001F4DA': ':books:',     # 📚
    '\U0001F527': ':wrench:',    # 🔧
    '\u26A1': ':zap:',           # ⚡
    '\U0001F4C5': ':calendar:',  # 📅
}
for emoji, shortcode in replacements.items():
    text = text.replace(emoji, shortcode)
print(text, end='')
" <<< "$input"
}

# === VERSION DETECTION ===
detect_version() {
    if [[ "$GITHUB_REF" =~ ^refs/tags/ ]]; then
        VERSION=$(echo "$GITHUB_REF" | sed 's|refs/tags/||')
        # Check if this is a beta release (e.g., 1.2.3-Beta1, 1.2.3-beta2)
        if [[ "$VERSION" =~ -[Bb]eta ]]; then
            IS_BETA=true
            log_info "Detected beta release: $VERSION"
        else
            IS_BETA=false
            log_info "Detected stable release: $VERSION"
        fi
    else
        # This shouldn't happen since we only run on tags, but handle it gracefully
        VERSION="unknown"
        IS_BETA=false
        log_info "Warning: Not a tag push, unexpected ref: $GITHUB_REF"
    fi
}

# === CHANGELOG PROCESSING ===

# Extract the "This Release" or "Alpha Build" section content
extract_current_release_content() {
    local in_section=false
    local content=""

    while IFS= read -r line; do
        # Start capturing at "This Release" or "Alpha Build" section
        if [[ "$line" =~ ^##.*This\ Release ]] || [[ "$line" =~ ^##.*Alpha\ Build ]]; then
            in_section=true
            continue
        fi

        # Stop at next major section (## but not ###)
        if [[ "$in_section" == true ]] && [[ "$line" =~ ^##[^#] ]]; then
            break
        fi

        # Capture content
        if [[ "$in_section" == true ]]; then
            content+="$line"$'\n'
        fi
    done < "$CHANGELOG_FILE"

    echo "$content"
}

# Extract the AI-generated summary line if present
extract_ai_summary() {
    local content="$1"
    # Look for lines that appear to be AI summaries (not starting with - or #)
    echo "$content" | grep -v "^-" | grep -v "^#" | grep -v "^_" | grep -v "^$" | head -3
}

# Extract categorized sections (Features, Fixes, Changes)
extract_sections() {
    local content="$1"
    local sections=""

    # Process each section type
    for section in "Breaking Changes" "Features" "Fixes" "Changes"; do
        local section_content=$(echo "$content" | sed -n "/^### .*$section/,/^###/{/^### .*$section/d;/^###/d;p}" | head -10)
        if [ -n "$section_content" ]; then
            # Get the emoji header
            local header=$(echo "$content" | grep "^### .*$section" | head -1)
            if [ -n "$header" ]; then
                sections+="$header"$'\n'
                sections+="$section_content"$'\n'
            fi
        fi
    done

    echo "$sections"
}

# Truncate content to fit Discord's limits
truncate_content() {
    local content="$1"
    local max_len="$2"

    # If content fits, return as-is
    if [ ${#content} -le $max_len ]; then
        echo "$content"
        return
    fi

    # Truncate and find a good break point
    local truncated="${content:0:$max_len}"

    # Try to break at a newline
    local last_newline=$(echo "$truncated" | grep -bo $'\n' | tail -1 | cut -d: -f1)
    if [ -n "$last_newline" ] && [ "$last_newline" -gt $((max_len / 2)) ]; then
        truncated="${truncated:0:$last_newline}"
    fi

    # Add truncation notice with link to full changelog
    echo "$truncated"$'\n\n'"*... [View full changelog]($GH_RELEASES)*"
}

# Build the description for the Discord embed (using Python for proper UTF-8 handling)
build_description() {
    python3 << PYEOF
import sys

# Read the changelog file with proper encoding
with open("$CHANGELOG_FILE", 'r', encoding='utf-8') as f:
    content = f.read()

# Emoji replacements
replacements = {
    '\U0001F3AF': ':dart:',      # 🎯
    '\U0001F680': ':rocket:',    # 🚀
    '\U0001F41B': ':bug:',       # 🐛
    '\U0001F4DD': ':memo:',      # 📝
    '\u26A0\uFE0F': ':warning:', # ⚠️
    '\u26A0': ':warning:',       # ⚠
    '\U0001F4DA': ':books:',     # 📚
    '\U0001F527': ':wrench:',    # 🔧
    '\u26A1': ':zap:',           # ⚡
    '\U0001F4C5': ':calendar:',  # 📅
}

# Extract "This Release" or "Alpha Build" section
lines = content.split('\n')
in_section = False
section_content = []

for line in lines:
    if '## ' in line and ('This Release' in line or 'Alpha Build' in line):
        in_section = True
        continue
    if in_section and line.startswith('## ') and not line.startswith('### '):
        break
    if in_section:
        section_content.append(line)

description = '\n'.join(section_content).strip()

# Apply emoji replacements
for emoji, shortcode in replacements.items():
    description = description.replace(emoji, shortcode)

# Truncate if needed
max_len = $MAX_DESC_LENGTH
if len(description) > max_len:
    description = description[:max_len]
    # Find last newline
    last_nl = description.rfind('\n')
    if last_nl > max_len // 2:
        description = description[:last_nl]
    description += '\n\n*... [View full changelog]($GH_RELEASES)*'

# Default message if empty
if not description.strip():
    description = "A new version has been released! Check the changelog for details."

print(description)
PYEOF
}

# === BUILD JSON PAYLOAD ===
build_payload() {
    local description=$(build_description)
    local desc_json=$(json_escape "$description")

    # Determine color and title based on release type
    local color=$COLOR_STABLE
    local title="SpartanUI $VERSION Released!"
    local title_url="$CF_URL"

    if [ "$IS_BETA" = true ]; then
        color=$COLOR_BETA
        title="SpartanUI $VERSION (Beta)"
        # Beta releases still go to CurseForge
    fi

    # Get current timestamp
    local timestamp=$(date -u +%Y-%m-%dT%H:%M:%S.000Z)

    # Build the JSON payload
    cat << EOJSON
{
  "embeds": [{
    "title": "$title",
    "url": "$title_url",
    "description": $desc_json,
    "color": $color,
    "fields": [
      {
        "name": "Download",
        "value": "[CurseForge]($CF_URL) (Recommended)\\n[Wago Addons]($WAGO_URL)\\n[GitHub Releases]($GH_RELEASES)",
        "inline": true
      },
      {
        "name": "Support",
        "value": "[Discord]($DISCORD_SUPPORT)\\n[Report Issues]($GH_ISSUES)\\n[Roadmap]($GH_PROJECT)",
        "inline": true
      }
    ],
    "footer": {
      "text": "SpartanUI - World of Warcraft"
    },
    "timestamp": "$timestamp"
  }]
}
EOJSON
}

# === SEND WEBHOOK ===
send_notification() {
    local payload="$1"

    if [ -z "$DISCORD_WEBHOOK_URL" ]; then
        log_error "DISCORD_WEBHOOK_URL not set!"
        exit 1
    fi

    log_info "Sending Discord notification..."

    # Send the webhook request
    local response=$(curl -s -w "\n%{http_code}" \
        -H "Content-Type: application/json" \
        -d "$payload" \
        "$DISCORD_WEBHOOK_URL")

    local http_code=$(echo "$response" | tail -n1)
    local response_body=$(echo "$response" | head -n-1)

    if [ "$http_code" != "200" ] && [ "$http_code" != "204" ]; then
        log_error "Discord webhook failed with HTTP $http_code"
        log_error "Response: $response_body"
        exit 1
    fi

    log_info "Discord notification sent successfully!"
}

# === MAIN ===
main() {
    log_info "Starting Discord release notification..."

    # Detect version from GitHub ref
    detect_version

    # Verify changelog exists
    if [ ! -f "$CHANGELOG_FILE" ]; then
        log_error "Changelog file not found: $CHANGELOG_FILE"
        exit 1
    fi

    log_info "Reading changelog from: $CHANGELOG_FILE"

    # Build and send the notification
    local payload=$(build_payload)

    # Debug: show payload (optional, remove in production)
    log_info "Payload preview:"
    echo "$payload" | head -30 >&2

    send_notification "$payload"

    log_info "Done!"
}

main "$@"
