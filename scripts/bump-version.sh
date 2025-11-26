#!/usr/bin/env bash
# Bump package version, commit, tag, and push to GitHub
# Usage: ./scripts/bump-version.sh <patch|minor|major>

set -e

TYPE="${1:-patch}"

if [[ ! "$TYPE" =~ ^(patch|minor|major)$ ]]; then
    echo "[ERROR] Invalid version type: $TYPE"
    echo "Usage: $0 <patch|minor|major>"
    exit 1
fi

# Check for unstaged changes
if [ -n "$(git status --porcelain)" ]; then
    echo "[ERROR] Working directory is not clean."
    echo "Please commit or stash your changes before bumping the version."
    echo ""
    git status --short
    exit 1
fi

# Get current version
current=$(grep '^Version:' DESCRIPTION | sed 's/Version: //')
major=$(echo "$current" | cut -d. -f1)
minor=$(echo "$current" | cut -d. -f2)
patch=$(echo "$current" | cut -d. -f3)

# Calculate new version
case "$TYPE" in
    patch) new="$major.$minor.$((patch + 1))" ;;
    minor) new="$major.$((minor + 1)).0" ;;
    major) new="$((major + 1)).0.0" ;;
esac

# Validate new version is not empty
if [ -z "$new" ] || [ "$new" = ".." ]; then
    echo "[ERROR] Failed to calculate new version."
    echo "Current version '$current' may be malformed."
    echo "Expected format: X.Y.Z (e.g., 0.1.4)"
    exit 1
fi

echo "Updating version: $current -> $new"

# Update DESCRIPTION
if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS requires empty string for -i
    sed -i '' "s/^Version: .*/Version: $new/" DESCRIPTION
else
    sed -i "s/^Version: .*/Version: $new/" DESCRIPTION
fi

# Update NEWS.md
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
"$SCRIPT_DIR/update-news.sh" "$new"

# Commit the version bump
echo "[*] Committing version bump..."
git add DESCRIPTION NEWS.md
git commit -m "chore: bump version to $new"

# Create tag
echo "[*] Creating tag v$new..."
git tag "v$new"

# Push to GitHub
echo "[*] Pushing to GitHub..."
git push origin HEAD
git push origin "v$new"

echo ""
echo "╔════════════════════════════════════════════════════════════════╗"
echo "║              ✅ VERSION BUMP COMPLETE                          ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""
echo "  Version: $current -> $new"
echo "  Tag:     v$new"
echo ""
echo "The tag push will trigger the CRAN submission workflow."
echo "Monitor the workflow at: https://github.com/meta-analysis-es/maive/actions"
echo ""

