#!/bin/bash
# SpartanUI Smart Changelog Generator with AI Summaries
#
# This script generates an intelligent changelog that:
# - Detects alpha builds (unreleased commits on master)
# - Shows releases from the last month
# - Categorizes commits by type (Features, Fixes, Changes, etc.)
# - Generates two AI summaries: monthly overview and current release
#
# Usage: ./generate-changelog.sh [output_file]
#   output_file: Path to output changelog file (default: CHANGELOG.md)
#
# Environment variables:
#   GEMINI_API_KEY: Google Gemini API key for AI summaries
#   AI_PROVIDER: "gemini" or "openai" (default: gemini)
#   GITHUB_REF: GitHub ref (refs/tags/vX.Y.Z for tags, refs/heads/master for branch)

# Configuration
OUTPUT_FILE="${1:-CHANGELOG.md}"
AI_PROVIDER="${AI_PROVIDER:-gemini}"
MONTH_AGO_SECONDS=$((5 * 24 * 60 * 60)) # 30 days in seconds

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Logging functions (output to stderr)
log_info() { echo -e "${GREEN}[INFO]${NC} $1" >&2; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1" >&2; }
log_error() { echo -e "${RED}[ERROR]${NC} $1" >&2; }
log_debug() { echo -e "${BLUE}[DEBUG]${NC} $1" >&2; }

# JSON escape function
json_escape() {
    local input="$1"
    if command -v jq &> /dev/null; then
        echo "$input" | jq -Rs .
    else
        python -c "import json, sys; print(json.dumps(sys.stdin.read()))" <<< "$input"
    fi
}

# Function to categorize a commit message
categorize_commit() {
    local msg="$1"

    # Check for conventional commit patterns
    if [[ "$msg" =~ ^(feat|feature|enhancement|new)[:\ ] ]] || [[ "$msg" =~ ^NEW: ]]; then
        echo "feature"
    elif [[ "$msg" =~ ^(fix|bug|bugfix)[:\ ] ]] || [[ "$msg" =~ ^Fixes ]]; then
        echo "fix"
    elif [[ "$msg" =~ ^(chore|refactor|style|perf)[:\ ] ]]; then
        echo "change"
    elif [[ "$msg" =~ ^(docs|documentation)[:\ ] ]]; then
        echo "docs"
    elif [[ "$msg" =~ ^(breaking|BREAKING)[:\ ] ]]; then
        echo "breaking"
    else
        echo "other"
    fi
}

# Function to clean commit message (remove prefixes)
clean_commit_message() {
    local msg="$1"
    # Remove conventional commit prefixes
    msg=$(echo "$msg" | sed -E 's/^(feat|feature|fix|bug|bugfix|chore|refactor|style|perf|docs|documentation|breaking|BREAKING|NEW|enhancement|new):? ?//')
    echo "$msg"
}

# Function to call Gemini Flash API
generate_ai_summary_gemini() {
    local commits_text="$1"
    local prompt_type="$2" # "month" or "release"
    local api_key="$GEMINI_API_KEY"

    if [ -z "$api_key" ]; then
        log_warn "GEMINI_API_KEY not set, skipping AI summary"
        return 1
    fi

    # Create prompt based on type
    if [ "$prompt_type" = "month" ]; then
        local prompt="You are writing release notes for a World of Warcraft addon. Summarize the following changelog from the last month in 2-3 short sentences. Write for a 6th grade reading level. Focus on the most important changes users care about. Be concise and friendly.

Changes from last month:
$commits_text"
    else
        local prompt="You are writing release notes for a World of Warcraft addon. Summarize this specific release in 1-2 short sentences. Write for a 6th grade reading level. Focus on what changed in THIS release only. Be concise and friendly.

Changes in this release:
$commits_text"
    fi

    prompt=$(json_escape "$prompt")
    local json_request="{\"contents\":[{\"parts\":[{\"text\":$prompt}]}]}"
    local temp_request=$(mktemp)
    echo "$json_request" > "$temp_request"

    log_info "Calling Gemini API for $prompt_type summary..."
    local response=$(curl -s -w "\n%{http_code}" --max-time 30 \
        -H "Content-Type: application/json" \
        -d "@$temp_request" \
        "https://generativelanguage.googleapis.com/v1/models/gemini-2.5-flash:generateContent?key=$api_key")

    rm -f "$temp_request"

    local http_code=$(echo "$response" | tail -n1)
    local response_body=$(echo "$response" | head -n-1)

    if [ "$http_code" != "200" ]; then
        log_error "Gemini API returned HTTP $http_code"
        return 1
    fi

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

# Function to generate AI summary
generate_ai_summary() {
    local commits_text="$1"
    local prompt_type="$2"

    if [ "$AI_PROVIDER" = "openai" ]; then
        log_error "OpenAI not yet implemented"
        return 1
    else
        generate_ai_summary_gemini "$commits_text" "$prompt_type"
    fi
}

# Function to format categorized commits
format_categorized_commits() {
    local commit_file="$1"

    # Arrays for each category
    local -a features=() fixes=() changes=() docs=() breaking=() others=()

    # Read and categorize commits
    while IFS= read -r line || [ -n "$line" ]; do  # Handle files without trailing newline
        if [ -z "$line" ]; then continue; fi

        local category=$(categorize_commit "$line")
        local clean_msg=$(clean_commit_message "$line")

        case "$category" in
            feature) features+=("$clean_msg") ;;
            fix) fixes+=("$clean_msg") ;;
            change) changes+=("$clean_msg") ;;
            docs) docs+=("$clean_msg") ;;
            breaking) breaking+=("$clean_msg") ;;
            *) others+=("$clean_msg") ;;
        esac
    done < "$commit_file"

    # Output categorized commits directly (not building a string)
    if [ ${#breaking[@]} -gt 0 ]; then
        echo "### ⚠️ Breaking Changes"
        for item in "${breaking[@]}"; do
            echo "- $item"
        done
        echo ""
    fi

    if [ ${#features[@]} -gt 0 ]; then
        echo "### 🚀 Features"
        for item in "${features[@]}"; do
            echo "- $item"
        done
        echo ""
    fi

    if [ ${#fixes[@]} -gt 0 ]; then
        echo "### 🐛 Fixes"
        for item in "${fixes[@]}"; do
            echo "- $item"
        done
        echo ""
    fi

    if [ ${#changes[@]} -gt 0 ]; then
        echo "### 📝 Changes"
        for item in "${changes[@]}"; do
            echo "- $item"
        done
        echo ""
    fi

    if [ ${#docs[@]} -gt 0 ]; then
        echo "### 📚 Documentation"
        for item in "${docs[@]}"; do
            echo "- $item"
        done
        echo ""
    fi

    if [ ${#others[@]} -gt 0 ]; then
        echo "### 🔧 Other"
        for item in "${others[@]}"; do
            echo "- $item"
        done
        echo ""
    fi
}

# Main script execution
log_info "Generating smart changelog for SpartanUI..."
log_info "Output file: $OUTPUT_FILE"

# Check if we're in a git repository
if ! git rev-parse --git-dir > /dev/null 2>&1; then
    log_error "Not in a git repository!"
    exit 1
fi

# Detect if this is a tag release or alpha build
IS_TAG=false
CURRENT_TAG=""
if [[ "$GITHUB_REF" =~ ^refs/tags/ ]]; then
    IS_TAG=true
    CURRENT_TAG=$(echo "$GITHUB_REF" | sed 's|refs/tags/||')
    log_info "Detected tag release: $CURRENT_TAG"
else
    log_info "Detected alpha build (branch push)"
fi

# Get current timestamp
NOW=$(date +%s)
MONTH_AGO=$(($NOW - $MONTH_AGO_SECONDS))

# Initialize changelog file
echo "# SpartanUI Changelog" > "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"

# Placeholders for AI summaries
MONTH_SUMMARY_MARKER="<!-- MONTH_SUMMARY_PLACEHOLDER -->"
RELEASE_SUMMARY_MARKER="<!-- RELEASE_SUMMARY_PLACEHOLDER -->"

# Temp files for collecting commits
TEMP_MONTH_COMMITS=$(mktemp)
TEMP_RELEASE_COMMITS=$(mktemp)
TEMP_ALPHA_COMMITS=$(mktemp)

# Check for alpha build (unreleased commits)
if [ "$IS_TAG" = false ]; then
    # Get latest tag
    LATEST_TAG=$(git describe --tags --abbrev=0 2>/dev/null || echo "")

    if [ -n "$LATEST_TAG" ]; then
        log_info "Checking for unreleased commits since $LATEST_TAG..."

        # Get commits since last tag
        git log "$LATEST_TAG..HEAD" --pretty=format:"%s" --no-merges > "$TEMP_ALPHA_COMMITS"

        if [ -s "$TEMP_ALPHA_COMMITS" ]; then
            ALPHA_COUNT=$(grep -c "." "$TEMP_ALPHA_COMMITS" 2>/dev/null || echo "0")
            log_info "Found $ALPHA_COUNT unreleased commits"

            echo "## ⚡ Alpha Build - Unreleased Changes" >> "$OUTPUT_FILE"
            echo "" >> "$OUTPUT_FILE"
            echo "_These changes are not yet in a release. This is a development build._" >> "$OUTPUT_FILE"
            echo "" >> "$OUTPUT_FILE"
            echo "$RELEASE_SUMMARY_MARKER" >> "$OUTPUT_FILE"
            echo "" >> "$OUTPUT_FILE"

            # Format and add categorized commits
            format_categorized_commits "$TEMP_ALPHA_COMMITS" >> "$OUTPUT_FILE"
            echo "" >> "$OUTPUT_FILE"

            # Save for AI summary
            cat "$TEMP_ALPHA_COMMITS" > "$TEMP_RELEASE_COMMITS"
        fi
    fi
fi

# Add monthly summary section
echo "## 📅 Last Month Summary" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"
echo "$MONTH_SUMMARY_MARKER" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"

# Get all tags from the last month
log_info "Fetching tags from last month..."
ALL_TAGS=$(git tag --sort=-version:refname)

RECENT_TAGS=()
for tag in $ALL_TAGS; do
    TAG_DATE=$(git log -1 --format=%at "$tag" 2>/dev/null)
    if [ -n "$TAG_DATE" ] && [ "$TAG_DATE" -ge "$MONTH_AGO" ]; then
        RECENT_TAGS+=("$tag")
    fi
done

log_info "Found ${#RECENT_TAGS[@]} releases from last month"

# If this is a tag release and it's the latest, add "This Release" section
if [ "$IS_TAG" = true ] && [ "${RECENT_TAGS[0]}" = "$CURRENT_TAG" ]; then
    echo "## 🎯 This Release" >> "$OUTPUT_FILE"
    echo "" >> "$OUTPUT_FILE"
    echo "$RELEASE_SUMMARY_MARKER" >> "$OUTPUT_FILE"
    echo "" >> "$OUTPUT_FILE"
fi

# Build a full sorted tag list for proper previous tag lookup
ALL_TAGS_ARRAY=()
while IFS= read -r tag; do
    ALL_TAGS_ARRAY+=("$tag")
done <<< "$ALL_TAGS"

# Process each recent tag
for i in "${!RECENT_TAGS[@]}"; do
    TAG="${RECENT_TAGS[$i]}"
    TAG_DATE=$(git log -1 --format=%ai "$TAG" | cut -d' ' -f1)

    log_info "Processing version $TAG ($TAG_DATE)..."

    # Get previous tag by finding position in full sorted tag list
    PREV_TAG=""
    for j in "${!ALL_TAGS_ARRAY[@]}"; do
        if [ "${ALL_TAGS_ARRAY[$j]}" = "$TAG" ]; then
            # Next index in the sorted list is the previous version
            NEXT_IDX=$((j + 1))
            if [ $NEXT_IDX -lt ${#ALL_TAGS_ARRAY[@]} ]; then
                PREV_TAG="${ALL_TAGS_ARRAY[$NEXT_IDX]}"
            fi
            break
        fi
    done

    log_debug "Tag $TAG -> Previous tag: ${PREV_TAG:-NONE}"

    # Get commits for this range
    TEMP_TAG_COMMITS=$(mktemp)
    if [ -n "$PREV_TAG" ]; then
        git log "$PREV_TAG..$TAG" --pretty=format:"%s" --no-merges > "$TEMP_TAG_COMMITS"
    else
        # No previous tag found - this is the first tag ever, skip it to avoid years of history
        log_warn "No previous tag found for $TAG, skipping to avoid full history"
        echo "" > "$TEMP_TAG_COMMITS"
    fi

    # Check commit count (count non-empty lines, handles files without trailing newline)
    COMMIT_COUNT=$(grep -c "." "$TEMP_TAG_COMMITS" 2>/dev/null || echo "0")

    # Add to monthly commits
    cat "$TEMP_TAG_COMMITS" >> "$TEMP_MONTH_COMMITS"

    # If this is the current release tag, save for release summary
    if [ "$IS_TAG" = true ] && [ "$TAG" = "$CURRENT_TAG" ]; then
        cat "$TEMP_TAG_COMMITS" > "$TEMP_RELEASE_COMMITS"
    fi

    # Add version section
    echo "## Version $TAG ($TAG_DATE)" >> "$OUTPUT_FILE"
    echo "" >> "$OUTPUT_FILE"

    if [ -s "$TEMP_TAG_COMMITS" ]; then
        format_categorized_commits "$TEMP_TAG_COMMITS" >> "$OUTPUT_FILE"
    else
        echo "- No changes recorded" >> "$OUTPUT_FILE"
        echo "" >> "$OUTPUT_FILE"
    fi

    echo "" >> "$OUTPUT_FILE"

    rm -f "$TEMP_TAG_COMMITS"
done

# Generate AI summaries (only for tag releases)
if [ "$IS_TAG" = true ]; then
    log_info "Generating AI summaries for tag release..."

    # Monthly summary
    if [ -s "$TEMP_MONTH_COMMITS" ]; then
        MONTH_COMMITS=$(cat "$TEMP_MONTH_COMMITS")
        MONTH_SUMMARY=$(generate_ai_summary "$MONTH_COMMITS" "month") || MONTH_SUMMARY=""

        if [ -n "$MONTH_SUMMARY" ]; then
            log_info "Monthly summary generated!"
            sed -i "s|$MONTH_SUMMARY_MARKER|$MONTH_SUMMARY|g" "$OUTPUT_FILE"
        else
            sed -i "/$MONTH_SUMMARY_MARKER/d" "$OUTPUT_FILE"
        fi
    else
        sed -i "/$MONTH_SUMMARY_MARKER/d" "$OUTPUT_FILE"
    fi

    # Release summary (only if there are more than 3 changes)
    if [ -s "$TEMP_RELEASE_COMMITS" ]; then
        RELEASE_COMMIT_COUNT=$(grep -c "." "$TEMP_RELEASE_COMMITS" 2>/dev/null || echo "0")

        if [ "$RELEASE_COMMIT_COUNT" -gt 3 ]; then
            RELEASE_COMMITS=$(cat "$TEMP_RELEASE_COMMITS")
            RELEASE_SUMMARY=$(generate_ai_summary "$RELEASE_COMMITS" "release") || RELEASE_SUMMARY=""

            if [ -n "$RELEASE_SUMMARY" ]; then
                log_info "Release summary generated!"
                sed -i "s|$RELEASE_SUMMARY_MARKER|$RELEASE_SUMMARY|g" "$OUTPUT_FILE"
            else
                sed -i "/$RELEASE_SUMMARY_MARKER/d" "$OUTPUT_FILE"
            fi
        else
            log_info "Skipping release summary (only $RELEASE_COMMIT_COUNT changes)"
            sed -i "/$RELEASE_SUMMARY_MARKER/d" "$OUTPUT_FILE"
        fi
    else
        sed -i "/$RELEASE_SUMMARY_MARKER/d" "$OUTPUT_FILE"
    fi
else
    log_info "Skipping AI summaries for alpha build"
    sed -i "/$MONTH_SUMMARY_MARKER/d" "$OUTPUT_FILE"
    sed -i "/$RELEASE_SUMMARY_MARKER/d" "$OUTPUT_FILE"
fi

# Clean up
rm -f "$TEMP_MONTH_COMMITS" "$TEMP_RELEASE_COMMITS" "$TEMP_ALPHA_COMMITS"

log_info "Smart changelog generated successfully: $OUTPUT_FILE"
log_info "Preview (first 50 lines):"
head -n 50 "$OUTPUT_FILE"

exit 0
