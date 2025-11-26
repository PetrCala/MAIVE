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

# Check if version already exists in NEWS.md
if grep -q "^# MAIVE $VERSION" "$NEWS_FILE"; then
    echo "[INFO] Version $VERSION already exists in $NEWS_FILE, skipping update"
    exit 0
fi

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
    
    # Extract type and message
    if [[ "$commit" =~ ^feat(\(.+\))?:\ (.+)$ ]]; then
        msg="${BASH_REMATCH[2]}"
        FEATURES="${FEATURES}\n* ${msg^}"
    elif [[ "$commit" =~ ^fix(\(.+\))?:\ (.+)$ ]]; then
        msg="${BASH_REMATCH[2]}"
        FIXES="${FIXES}\n* ${msg^}"
    elif [[ "$commit" =~ ^docs(\(.+\))?:\ (.+)$ ]]; then
        msg="${BASH_REMATCH[2]}"
        DOCS="${DOCS}\n* ${msg^}"
    elif [[ "$commit" =~ ^(chore|build|ci|style|refactor|perf|test)(\(.+\))?:\ (.+)$ ]]; then
        msg="${BASH_REMATCH[3]}"
        CHORES="${CHORES}\n* ${msg^}"
    elif [[ "$commit" =~ ^[Bb]ump\ version ]]; then
        # Skip version bump commits
        continue
    else
        # Other commits (capitalize first letter)
        OTHER="${OTHER}\n* ${commit^}"
    fi
done <<< "$COMMITS"

# Build the NEWS entry
NEW_ENTRY="# MAIVE $VERSION

*Released: $DATE*"

# Add sections only if they have content
if [ -n "$FEATURES" ]; then
    NEW_ENTRY="${NEW_ENTRY}

## New Features
$(echo -e "$FEATURES")"
fi

if [ -n "$FIXES" ]; then
    NEW_ENTRY="${NEW_ENTRY}

## Bug Fixes
$(echo -e "$FIXES")"
fi

if [ -n "$DOCS" ]; then
    NEW_ENTRY="${NEW_ENTRY}

## Documentation
$(echo -e "$DOCS")"
fi

if [ -n "$CHORES" ]; then
    NEW_ENTRY="${NEW_ENTRY}

## Internal
$(echo -e "$CHORES")"
fi

if [ -n "$OTHER" ]; then
    NEW_ENTRY="${NEW_ENTRY}

## Other Changes
$(echo -e "$OTHER")"
fi

# If no commits found, add placeholder
if [ -z "$FEATURES" ] && [ -z "$FIXES" ] && [ -z "$DOCS" ] && [ -z "$CHORES" ] && [ -z "$OTHER" ]; then
    NEW_ENTRY="${NEW_ENTRY}

## Changes

* Minor updates and improvements"
fi

# Add separator
NEW_ENTRY="${NEW_ENTRY}

---

"

# Prepend new entry to NEWS.md
echo -e "$NEW_ENTRY" | cat - "$NEWS_FILE" > "$NEWS_FILE.tmp" && mv "$NEWS_FILE.tmp" "$NEWS_FILE"

echo "[OK] Updated $NEWS_FILE with version $VERSION"

# Show what was added
echo ""
echo "Added to NEWS.md:"
echo "─────────────────"
echo -e "$NEW_ENTRY" | head -30
