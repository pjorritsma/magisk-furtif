#!/bin/bash

# MagiskFurtif Release Creation Script
# This script helps create a new release by creating and pushing a git tag

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🚀 MagiskFurtif Release Creation Script${NC}"
echo "=========================================="

# Check if we're in a git repository
if ! git rev-parse --git-dir > /dev/null 2>&1; then
    echo -e "${RED}❌ Error: Not in a git repository${NC}"
    exit 1
fi

# Check if there are uncommitted changes
if ! git diff-index --quiet HEAD --; then
    echo -e "${YELLOW}⚠️  Warning: You have uncommitted changes${NC}"
    echo "Please commit or stash your changes before creating a release."
    read -p "Do you want to continue anyway? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${RED}❌ Release creation cancelled${NC}"
        exit 1
    fi
fi

# Get current version from build.py
CURRENT_VERSION=$(grep 'frida_release = ' build.py | sed "s/.*frida_release = \"\(.*\)\".*/\1/")
echo -e "${BLUE}📋 Current version: ${CURRENT_VERSION}${NC}"

# Ask for new version
echo -e "${YELLOW}📝 Enter new version (e.g., 3.3):${NC}"
read -p "New version: " NEW_VERSION

if [ -z "$NEW_VERSION" ]; then
    echo -e "${RED}❌ Error: Version cannot be empty${NC}"
    exit 1
fi

# Validate version format (basic check)
if ! [[ $NEW_VERSION =~ ^[0-9]+\.[0-9]+$ ]]; then
    echo -e "${RED}❌ Error: Version must be in format X.Y (e.g., 3.3)${NC}"
    exit 1
fi

# Create tag name
TAG_NAME="v$NEW_VERSION"
echo -e "${BLUE}🏷️  Tag name: ${TAG_NAME}${NC}"

# Check if tag already exists
if git tag -l | grep -q "^$TAG_NAME$"; then
    echo -e "${RED}❌ Error: Tag $TAG_NAME already exists${NC}"
    exit 1
fi

# Confirm release creation
echo -e "${YELLOW}📋 Release Summary:${NC}"
echo "  Current version: $CURRENT_VERSION"
echo "  New version: $NEW_VERSION"
echo "  Tag: $TAG_NAME"
echo "  Repository: $(git remote get-url origin)"
echo
read -p "Do you want to create this release? (y/N): " -n 1 -r
echo

if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${RED}❌ Release creation cancelled${NC}"
    exit 1
fi

# Update version in build.py
echo -e "${BLUE}📝 Updating version in build.py...${NC}"
sed -i "s/frida_release = \"$CURRENT_VERSION\"/frida_release = \"$NEW_VERSION\"/" build.py

# Update version in updater.json
echo -e "${BLUE}📝 Updating version in updater.json...${NC}"
VERSION_CODE=$(echo $NEW_VERSION | sed 's/\.//g')
cat > updater.json << EOF
{
    "version": "$NEW_VERSION",
    "versionCode": $VERSION_CODE,
    "zipUrl": "https://github.com/$(git remote get-url origin | sed 's/.*github.com[:/]\([^.]*\).*/\1/')/releases/download/$TAG_NAME/MagiskFurtif-f3ger-$NEW_VERSION.zip"
}
EOF

# Update version in module.prop
echo -e "${BLUE}📝 Updating version in module.prop...${NC}"
sed -i "s/version=v$CURRENT_VERSION/version=v$NEW_VERSION/" base/module.prop
sed -i "s/versionCode=$((CURRENT_VERSION | sed 's/\.//g'))/versionCode=$VERSION_CODE/" base/module.prop

# Commit changes
echo -e "${BLUE}💾 Committing version changes...${NC}"
git add build.py updater.json base/module.prop
git commit -m "Bump version to $NEW_VERSION"

# Create and push tag
echo -e "${BLUE}🏷️  Creating tag $TAG_NAME...${NC}"
git tag -a "$TAG_NAME" -m "Release version $NEW_VERSION

## Changes in version $NEW_VERSION
- Enhanced monitoring service
- Improved Discord notifications
- Better error handling
- Updated workflow files"

echo -e "${BLUE}📤 Pushing changes and tag...${NC}"
git push origin main
git push origin "$TAG_NAME"

echo -e "${GREEN}✅ Release $TAG_NAME created successfully!${NC}"
echo -e "${BLUE}🔗 GitHub Actions will now build and create the release automatically${NC}"
echo -e "${YELLOW}📋 You can monitor the progress at:${NC}"
echo "   https://github.com/$(git remote get-url origin | sed 's/.*github.com[:/]\([^.]*\).*/\1/')/actions"
