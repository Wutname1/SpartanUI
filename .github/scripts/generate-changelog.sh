#!/bin/bash
# SpartanUI Changelog Generator with AI Summary
#
# Usage: ./generate-changelog.sh [output_file] [num_versions]
#   output_file: Path to output changelog file (default: CHANGELOG.md)
#   num_versions: Number of versions to include (default: 5)
#
# Environment variables:
#   GEMINI_API_KEY: Google Gemini API key for AI summaries
#   OPENAI_API_KEY: OpenAI API key (fallback)
#   AI_PROVIDER: "gemini" or "openai" (default: gemini)

set -e  # Exit on error

# Configuration
OUTPUT_FILE="${1:-CHANGELOG.md}"
NUM_VERSIONS="${2:-5}"
AI_PROVIDER="${AI_PROVIDER:-gemini}"

# Colors for output (if terminal supports it)
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
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
    prompt=$(echo "$prompt" | jq -Rs .)

    # Build JSON request
    local json_request="{\"contents\":[{\"parts\":[{\"text\":$prompt}]}]}"

    # Call Gemini API
    log_info "Calling Gemini Flash API for summary..."
    local response=$(curl -s -w "\n%{http_code}" --max-time 30 \
        -H "Content-Type: application/json" \
        -d "$json_request" \
        "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash-exp:generateContent?key=$api_key")

    # Extract HTTP status code (last line)
    local http_code=$(echo "$response" | tail -n1)
    local response_body=$(echo "$response" | head -n-1)

    if [ "$http_code" != "200" ]; then
        log_error "Gemini API returned HTTP $http_code"
        log_error "Response: $response_body"
        return 1
    fi

    # Parse response and extract summary
    local summary=$(echo "$response_body" | jq -r '.candidates[0].content.parts[0].text // empty' 2>/dev/null)

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
    prompt=$(echo "$prompt" | jq -Rs .)

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

    # Parse response and extract summary
    local summary=$(echo "$response_body" | jq -r '.choices[0].message.content // empty' 2>/dev/null)

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
log_info "Generating changelog for SpartanUI..."
log_info "Output file: $OUTPUT_FILE"
log_info "Number of versions: $NUM_VERSIONS"
log_info "AI Provider: $AI_PROVIDER"

# Check if we're in a git repository
if ! git rev-parse --git-dir > /dev/null 2>&1; then
    log_error "Not in a git repository!"
    exit 1
fi

# Get the last N tags (sorted by version)
log_info "Fetching last $NUM_VERSIONS tags..."
TAGS=$(git tag --sort=-version:refname | head -n "$NUM_VERSIONS")

if [ -z "$TAGS" ]; then
    log_error "No tags found in repository!"
    exit 1
fi

# Temporary file for collecting all commits
TEMP_COMMITS=$(mktemp)

# Start building the changelog
log_info "Building changelog sections..."

# Initialize changelog file
echo "# SpartanUI Changelog" > "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"

# We'll add TLDR section later, so save space for it
TLDR_MARKER="<!-- TLDR_PLACEHOLDER -->"
echo "$TLDR_MARKER" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"

# Process each tag
TAG_ARRAY=($TAGS)
for i in "${!TAG_ARRAY[@]}"; do
    TAG="${TAG_ARRAY[$i]}"

    # Get tag date
    TAG_DATE=$(git log -1 --format=%ai "$TAG" | cut -d' ' -f1)

    log_info "Processing version $TAG ($TAG_DATE)..."

    # Add version header
    echo "## Version $TAG ($TAG_DATE)" >> "$OUTPUT_FILE"
    echo "" >> "$OUTPUT_FILE"

    # Get previous tag for this tag's range
    if [ $i -lt $((${#TAG_ARRAY[@]} - 1)) ]; then
        PREV_TAG="${TAG_ARRAY[$((i + 1))]}"
        COMMIT_RANGE="$PREV_TAG..$TAG"
    else
        # For the oldest tag in our list, get all commits up to that tag
        COMMIT_RANGE="$TAG"
    fi

    # Get commits for this range (exclude merge commits)
    COMMITS=$(git log "$COMMIT_RANGE" --pretty=format:"- %s" --no-merges 2>/dev/null || echo "- Initial release")

    if [ -n "$COMMITS" ]; then
        echo "$COMMITS" >> "$OUTPUT_FILE"
        echo "$COMMITS" >> "$TEMP_COMMITS"
    else
        echo "- No changes recorded" >> "$OUTPUT_FILE"
    fi

    echo "" >> "$OUTPUT_FILE"
    echo "" >> "$OUTPUT_FILE"
done

# Generate AI summary from all collected commits
ALL_COMMITS=$(cat "$TEMP_COMMITS")

if [ -n "$ALL_COMMITS" ]; then
    AI_SUMMARY=$(generate_ai_summary "$ALL_COMMITS" 2>&1) || AI_SUMMARY=""

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

log_info "Changelog generated successfully: $OUTPUT_FILE"

# Show a preview of the file
log_info "Preview (first 20 lines):"
head -n 20 "$OUTPUT_FILE"

exit 0
