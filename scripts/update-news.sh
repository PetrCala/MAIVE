#!/usr/bin/env bash
# Update NEWS.md with changes since the last version tag
# Usage: ./scripts/update-news.sh <new_version>

set -e

VERSION="${1}"

if [ -z "$VERSION" ]; then
    echo "[ERROR] Version is required"
    echo "Usage: $0 <version>"
    exit 1
fi

NEWS_FILE="NEWS.md"

if [ ! -f "$NEWS_FILE" ]; then
    echo "[ERROR] $NEWS_FILE not found"
    exit 1
fi

# A hand-written entry for the upcoming release may sit under a provisional
# version heading (for example 0.2.7 when the bump turns out to be minor).
# If the newest entry is still "*Unreleased*", rename its heading to $VERSION
# so the date stamp below lands on it instead of leaving it orphaned.
FIRST_HEADING=$(grep -m1 "^# MAIVE " "$NEWS_FILE" | sed 's/^# MAIVE //')
if [ -n "$FIRST_HEADING" ] && [ "$FIRST_HEADING" != "$VERSION" ] && \
   awk '/^# MAIVE /{h++} h==1 && /^\*Unreleased\*/{found=1} END{exit !found}' "$NEWS_FILE"; then
    awk -v old="$FIRST_HEADING" -v new="$VERSION" '
        !done && $0 == "# MAIVE " old { $0 = "# MAIVE " new; done = 1 }
        { print }
    ' "$NEWS_FILE" > "$NEWS_FILE.tmp" && mv "$NEWS_FILE.tmp" "$NEWS_FILE"
    echo "[OK] Renamed the unreleased $FIRST_HEADING entry in $NEWS_FILE to $VERSION"
fi

# Check if version already exists in NEWS.md. A hand-written entry may carry an
# "*Unreleased*" placeholder instead of a date; stamp today's date into it.
if grep -q "^# MAIVE $VERSION" "$NEWS_FILE"; then
    DATE=$(date +%Y-%m-%d)
    if grep -q "^\*Unreleased\*" "$NEWS_FILE"; then
        # Replace only the first placeholder (the newest entry); portable across BSD and GNU
        awk -v date="$DATE" '
            !done && /^\*Unreleased\*/ { sub(/^\*Unreleased\*/, "*Released: " date "*"); done = 1 }
            { print }
        ' "$NEWS_FILE" > "$NEWS_FILE.tmp" && mv "$NEWS_FILE.tmp" "$NEWS_FILE"
        echo "[OK] Stamped release date $DATE on the existing $VERSION entry in $NEWS_FILE"
    else
        echo "[INFO] Version $VERSION already exists in $NEWS_FILE, skipping update"
    fi
    exit 0
fi

# Function to capitalize first letter (portable)
capitalize() {
    echo "$1" | awk '{print toupper(substr($0,1,1)) substr($0,2)}'
}

# Get the last version tag
LAST_TAG=$(git describe --tags --abbrev=0 2>/dev/null || echo "")

# Get commits since last tag (or all commits if no tag exists)
if [ -n "$LAST_TAG" ]; then
    echo "[INFO] Getting commits since $LAST_TAG..."
    COMMITS=$(git log "$LAST_TAG"..HEAD --pretty=format:"%s" --no-merges 2>/dev/null || echo "")
else
    echo "[INFO] No previous tag found, getting recent commits..."
    COMMITS=$(git log --pretty=format:"%s" --no-merges -20 2>/dev/null || echo "")
fi

# Get current date
DATE=$(date +%Y-%m-%d)

# Initialize change categories
FEATURES=""
FIXES=""
DOCS=""
CHORES=""
OTHER=""

# Parse commits by conventional commit type
while IFS= read -r commit; do
    [ -z "$commit" ] && continue
    
    # Skip version bump commits
    if echo "$commit" | grep -qi "bump version"; then
        continue
    fi
    
    # Extract type and message using sed (portable)
    if echo "$commit" | grep -qE "^feat(\(.+\))?:"; then
        msg=$(echo "$commit" | sed -E 's/^feat(\([^)]+\))?:[[:space:]]*//')
        msg=$(capitalize "$msg")
        FEATURES="${FEATURES}* ${msg}
"
    elif echo "$commit" | grep -qE "^fix(\(.+\))?:"; then
        msg=$(echo "$commit" | sed -E 's/^fix(\([^)]+\))?:[[:space:]]*//')
        msg=$(capitalize "$msg")
        FIXES="${FIXES}* ${msg}
"
    elif echo "$commit" | grep -qE "^docs(\(.+\))?:"; then
        msg=$(echo "$commit" | sed -E 's/^docs(\([^)]+\))?:[[:space:]]*//')
        msg=$(capitalize "$msg")
        DOCS="${DOCS}* ${msg}
"
    elif echo "$commit" | grep -qE "^(chore|build|ci|style|refactor|perf|test)(\(.+\))?:"; then
        msg=$(echo "$commit" | sed -E 's/^(chore|build|ci|style|refactor|perf|test)(\([^)]+\))?:[[:space:]]*//')
        msg=$(capitalize "$msg")
        CHORES="${CHORES}* ${msg}
"
    else
        msg=$(capitalize "$commit")
        OTHER="${OTHER}* ${msg}
"
    fi
done <<< "$COMMITS"

# Build the NEWS entry
NEW_ENTRY="# MAIVE $VERSION

*Released: $DATE*"

# Add sections only if they have content
if [ -n "$FEATURES" ]; then
    NEW_ENTRY="${NEW_ENTRY}

## New Features

${FEATURES}"
fi

if [ -n "$FIXES" ]; then
    NEW_ENTRY="${NEW_ENTRY}

## Bug Fixes

${FIXES}"
fi

if [ -n "$DOCS" ]; then
    NEW_ENTRY="${NEW_ENTRY}

## Documentation

${DOCS}"
fi

if [ -n "$CHORES" ]; then
    NEW_ENTRY="${NEW_ENTRY}

## Internal

${CHORES}"
fi

if [ -n "$OTHER" ]; then
    NEW_ENTRY="${NEW_ENTRY}

## Other Changes

${OTHER}"
fi

# If no commits found, add placeholder
if [ -z "$FEATURES" ] && [ -z "$FIXES" ] && [ -z "$DOCS" ] && [ -z "$CHORES" ] && [ -z "$OTHER" ]; then
    NEW_ENTRY="${NEW_ENTRY}

## Changes

* Minor updates and improvements
"
fi

# Add separator
NEW_ENTRY="${NEW_ENTRY}
---

"

# Prepend new entry to NEWS.md
echo "$NEW_ENTRY" | cat - "$NEWS_FILE" > "$NEWS_FILE.tmp" && mv "$NEWS_FILE.tmp" "$NEWS_FILE"

echo "[OK] Updated $NEWS_FILE with version $VERSION"

# Show what was added
echo ""
echo "Added to NEWS.md:"
echo "─────────────────"
echo "$NEW_ENTRY" | head -30
