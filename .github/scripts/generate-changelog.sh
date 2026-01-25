#!/bin/bash
# SpartanUI Hybrid Changelog Generator with AI Summary
#
# This script generates a hybrid changelog that combines:
# - AI-generated TLDR summary of all changes
# - Categorized changelog for the latest version (from release-changelog-builder)
# - Simplified commit lists for older versions
#
# Usage: ./generate-changelog.sh [output_file] [num_versions]
#   output_file: Path to output changelog file (default: CHANGELOG.md)
#   num_versions: Number of versions to include (default: 5)
#
# Environment variables:
#   GEMINI_API_KEY: Google Gemini API key for AI summaries
#   OPENAI_API_KEY: OpenAI API key (fallback)
#   AI_PROVIDER: "gemini" or "openai" (default: gemini)
#   LATEST_CHANGELOG: Pre-generated categorized changelog for latest version (from release-changelog-builder)

# Note: We don't use 'set -e' because we want to continue even if AI summary fails

# Configuration
OUTPUT_FILE="${1:-CHANGELOG.md}"
NUM_VERSIONS="${2:-5}"
AI_PROVIDER="${AI_PROVIDER:-gemini}"

# Colors for output (if terminal supports it)
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Logging functions (output to stderr so they don't interfere with command substitution)
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1" >&2
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1" >&2
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

# JSON escape function - works with or without jq
json_escape() {
    local input="$1"

    # Try jq first if available
    if command -v jq &> /dev/null; then
        echo "$input" | jq -Rs .
    else
        # Fallback: use Python
        python -c "import json, sys; print(json.dumps(sys.stdin.read()))" <<< "$input"
    fi
}

# JSON parse function - works with or without jq
json_parse() {
    local json="$1"
    local path="$2"

    # Try jq first if available
    if command -v jq &> /dev/null; then
        echo "$json" | jq -r "$path // empty" 2>/dev/null
    else
        # Fallback: use Python
        python -c "import json, sys; data = json.load(sys.stdin); print(eval('$path'.replace('//','or').replace('[0]','[0]').replace('.','[')).get('text','') if isinstance(eval('$path'.replace('//','or').replace('[0]','[0]').replace('.','['))  , dict) else '')" <<< "$json" 2>/dev/null || echo ""
    fi
}

# Function to call Gemini Flash API
generate_ai_summary_gemini() {
    local commits_text="$1"
    local api_key="$GEMINI_API_KEY"

    if [ -z "$api_key" ]; then
        log_warn "GEMINI_API_KEY not set, skipping AI summary"
        return 1
    fi

    # Prepare the prompt
    local prompt="Summarize the following SpartanUI addon changelog in 2-3 sentences as a TLDR for users. Focus on the most important features, fixes, and breaking changes. Be concise and user-friendly.

Changelog:
$commits_text"

    # Escape JSON special characters in prompt
    prompt=$(json_escape "$prompt")

    # Build JSON request and write to temp file (to avoid "Argument list too long")
    local json_request="{\"contents\":[{\"parts\":[{\"text\":$prompt}]}]}"
    local temp_request=$(mktemp)
    echo "$json_request" > "$temp_request"

    # Call Gemini API (using gemini-2.5-flash)
    log_info "Calling Gemini Flash API for summary..."
    local response=$(curl -s -w "\n%{http_code}" --max-time 30 \
        -H "Content-Type: application/json" \
        -d "@$temp_request" \
        "https://generativelanguage.googleapis.com/v1/models/gemini-2.5-flash:generateContent?key=$api_key")

    # Clean up temp file
    rm -f "$temp_request"

    # Extract HTTP status code (last line)
    local http_code=$(echo "$response" | tail -n1)
    local response_body=$(echo "$response" | head -n-1)

    if [ "$http_code" != "200" ]; then
        log_error "Gemini API returned HTTP $http_code"
        log_error "Response: $response_body"
        return 1
    fi

    # Parse response and extract summary using Python
    local summary=$(python -c "
import json, sys
try:
    data = json.loads(sys.stdin.read())
    print(data['candidates'][0]['content']['parts'][0]['text'])
except (KeyError, IndexError, json.JSONDecodeError):
    pass
" <<< "$response_body" 2>/dev/null)

    if [ -z "$summary" ]; then
        log_error "Failed to parse Gemini API response"
        return 1
    fi

    echo "$summary"
    return 0
}

# Function to call OpenAI GPT-4o Mini API
generate_ai_summary_openai() {
    local commits_text="$1"
    local api_key="$OPENAI_API_KEY"

    if [ -z "$api_key" ]; then
        log_warn "OPENAI_API_KEY not set, skipping AI summary"
        return 1
    fi

    # Prepare the prompt
    local prompt="Summarize the following SpartanUI addon changelog in 2-3 sentences as a TLDR for users. Focus on the most important features, fixes, and breaking changes. Be concise and user-friendly.

Changelog:
$commits_text"

    # Escape JSON special characters
    prompt=$(json_escape "$prompt")

    # Build JSON request
    local json_request="{\"model\":\"gpt-4o-mini\",\"messages\":[{\"role\":\"user\",\"content\":$prompt}],\"temperature\":0.7,\"max_tokens\":200}"

    # Call OpenAI API
    log_info "Calling OpenAI GPT-4o Mini API for summary..."
    local response=$(curl -s -w "\n%{http_code}" --max-time 30 \
        -H "Content-Type: application/json" \
        -H "Authorization: Bearer $api_key" \
        -d "$json_request" \
        "https://api.openai.com/v1/chat/completions")

    # Extract HTTP status code
    local http_code=$(echo "$response" | tail -n1)
    local response_body=$(echo "$response" | head -n-1)

    if [ "$http_code" != "200" ]; then
        log_error "OpenAI API returned HTTP $http_code"
        log_error "Response: $response_body"
        return 1
    fi

    # Parse response and extract summary using Python
    local summary=$(python -c "
import json, sys
try:
    data = json.loads(sys.stdin.read())
    print(data['choices'][0]['message']['content'])
except (KeyError, IndexError, json.JSONDecodeError):
    pass
" <<< "$response_body" 2>/dev/null)

    if [ -z "$summary" ]; then
        log_error "Failed to parse OpenAI API response"
        return 1
    fi

    echo "$summary"
    return 0
}

# Main AI summary function that tries the selected provider
generate_ai_summary() {
    local commits_text="$1"

    if [ "$AI_PROVIDER" = "openai" ]; then
        generate_ai_summary_openai "$commits_text"
    else
        generate_ai_summary_gemini "$commits_text"
    fi
}

# Main script execution
log_info "Generating hybrid changelog for SpartanUI..."
log_info "Output file: $OUTPUT_FILE"
log_info "Number of versions: $NUM_VERSIONS"
log_info "AI Provider: $AI_PROVIDER"

# Check if we're in a git repository
if ! git rev-parse --git-dir > /dev/null 2>&1; then
    log_error "Not in a git repository!"
    exit 1
fi

# Get the last N+1 tags (sorted by version) - we need one extra for the range of the oldest version
log_info "Fetching last $NUM_VERSIONS tags..."
ALL_TAGS=$(git tag --sort=-version:refname | head -n "$((NUM_VERSIONS + 1))")

if [ -z "$ALL_TAGS" ]; then
    log_error "No tags found in repository!"
    exit 1
fi

# Split into array
ALL_TAGS_ARRAY=($ALL_TAGS)

# Tags to display (first N)
TAGS=$(echo "$ALL_TAGS" | head -n "$NUM_VERSIONS")

# Temporary file for collecting all commits
TEMP_COMMITS=$(mktemp)

# Start building the changelog
log_info "Building hybrid changelog..."

# Initialize changelog file
echo "# SpartanUI Changelog" > "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"

# Placeholder for TLDR
TLDR_MARKER="<!-- TLDR_PLACEHOLDER -->"
echo "$TLDR_MARKER" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"

# Process each tag
TAG_ARRAY=($TAGS)
for i in "${!TAG_ARRAY[@]}"; do
    TAG="${TAG_ARRAY[$i]}"

    # Get tag date
    TAG_DATE=$(git log -1 --format=%ai "$TAG" | cut -d' ' -f1)

    # Get previous tag for this tag's range
    # Use the ALL_TAGS_ARRAY which has N+1 tags to ensure we have a previous tag for the oldest one
    if [ $i -lt ${#ALL_TAGS_ARRAY[@]} ] && [ -n "${ALL_TAGS_ARRAY[$((i + 1))]}" ]; then
        PREV_TAG="${ALL_TAGS_ARRAY[$((i + 1))]}"
        COMMIT_RANGE="$PREV_TAG..$TAG"
        COMMITS=$(git log "$COMMIT_RANGE" --pretty=format:"- %s" --no-merges 2>/dev/null || echo "")
    else
        # First tag ever - show all commits up to this tag
        COMMITS=$(git log "$TAG" --pretty=format:"- %s" --no-merges 2>/dev/null || echo "")
    fi

    if [ -n "$COMMITS" ]; then
        echo "$COMMITS" >> "$TEMP_COMMITS"
    fi

    # For the LATEST version (first tag), use the pre-generated categorized changelog
    if [ $i -eq 0 ]; then
        log_info "Adding categorized changelog for latest version $TAG ($TAG_DATE)..."

        echo "## Version $TAG ($TAG_DATE)" >> "$OUTPUT_FILE"
        echo "" >> "$OUTPUT_FILE"

        # Use the pre-generated categorized changelog if available
        if [ -n "$LATEST_CHANGELOG" ] && [ "$LATEST_CHANGELOG" != "null" ] && [ "$LATEST_CHANGELOG" != "" ]; then
            echo "$LATEST_CHANGELOG" >> "$OUTPUT_FILE"
        else
            # Fallback: simple commit list if release-changelog-builder didn't run
            log_warn "LATEST_CHANGELOG not provided, using simple format"
            if [ -n "$COMMITS" ]; then
                echo "$COMMITS" >> "$OUTPUT_FILE"
            else
                echo "- No changes recorded" >> "$OUTPUT_FILE"
            fi
        fi

        echo "" >> "$OUTPUT_FILE"
        echo "" >> "$OUTPUT_FILE"
    else
        # For OLDER versions, use simple commit list
        log_info "Adding simple changelog for version $TAG ($TAG_DATE)..."

        echo "## Version $TAG ($TAG_DATE)" >> "$OUTPUT_FILE"
        echo "" >> "$OUTPUT_FILE"

        if [ -n "$COMMITS" ]; then
            echo "$COMMITS" >> "$OUTPUT_FILE"
        else
            echo "- No changes recorded" >> "$OUTPUT_FILE"
        fi

        echo "" >> "$OUTPUT_FILE"
        echo "" >> "$OUTPUT_FILE"
    fi
done

# Generate AI summary from all collected commits
ALL_COMMITS=$(cat "$TEMP_COMMITS")

if [ -n "$ALL_COMMITS" ]; then
    AI_SUMMARY=$(generate_ai_summary "$ALL_COMMITS") || AI_SUMMARY=""

    if [ -n "$AI_SUMMARY" ]; then
        log_info "AI summary generated successfully!"

        # Create TLDR section
        TLDR_SECTION="## TLDR\n\n$AI_SUMMARY\n"

        # Replace placeholder with TLDR
        if [[ "$OSTYPE" == "darwin"* ]]; then
            # macOS sed syntax
            sed -i '' "s|$TLDR_MARKER|$TLDR_SECTION|g" "$OUTPUT_FILE"
        else
            # Linux/Git Bash sed syntax
            sed -i "s|$TLDR_MARKER|$TLDR_SECTION|g" "$OUTPUT_FILE"
        fi
    else
        log_warn "Failed to generate AI summary, proceeding without TLDR section"
        # Remove the placeholder
        if [[ "$OSTYPE" == "darwin"* ]]; then
            sed -i '' "/$TLDR_MARKER/d" "$OUTPUT_FILE"
        else
            sed -i "/$TLDR_MARKER/d" "$OUTPUT_FILE"
        fi
    fi
else
    log_warn "No commits found, skipping AI summary"
    if [[ "$OSTYPE" == "darwin"* ]]; then
        sed -i '' "/$TLDR_MARKER/d" "$OUTPUT_FILE"
    else
        sed -i "/$TLDR_MARKER/d" "$OUTPUT_FILE"
    fi
fi

# Clean up
rm -f "$TEMP_COMMITS"

log_info "Hybrid changelog generated successfully: $OUTPUT_FILE"

# Show a preview of the file
log_info "Preview (first 30 lines):"
head -n 30 "$OUTPUT_FILE"

exit 0
