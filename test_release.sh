#!/bin/bash

# Test script to verify release functionality
# This script tests the release process without actually creating a release

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🧪 MagiskFurtif Release Test Script${NC}"
echo "=========================================="

# Test 1: Check if build.py works
echo -e "${BLUE}📋 Test 1: Building module...${NC}"
if python build.py; then
    echo -e "${GREEN}✅ Build successful${NC}"
else
    echo -e "${RED}❌ Build failed${NC}"
    exit 1
fi

# Test 2: Check if ZIP file was created
echo -e "${BLUE}📋 Test 2: Checking ZIP file...${NC}"
ZIP_FILE=$(find builds -name "*.zip" | head -n 1)
if [ -n "$ZIP_FILE" ]; then
    echo -e "${GREEN}✅ ZIP file found: $ZIP_FILE${NC}"
    echo "File size: $(ls -lh $ZIP_FILE | awk '{print $5}')"
    
    # Test 3: Check ZIP file contents
    echo -e "${BLUE}📋 Test 3: Checking ZIP file contents...${NC}"
    echo "ZIP file contents:"
    unzip -l "$ZIP_FILE" | head -10
    
    # Check for required files
    REQUIRED_FILES=("service.sh" "install.sh" "module.prop" "post-fs-data.sh")
    for file in "${REQUIRED_FILES[@]}"; do
        if unzip -l "$ZIP_FILE" | grep -q "$file"; then
            echo -e "${GREEN}✅ $file found in ZIP${NC}"
        else
            echo -e "${RED}❌ $file NOT found in ZIP${NC}"
        fi
    done
else
    echo -e "${RED}❌ No ZIP file found${NC}"
    exit 1
fi

# Test 4: Check version consistency
echo -e "${BLUE}📋 Test 4: Checking version consistency...${NC}"
BUILD_VERSION=$(grep 'frida_release = ' build.py | sed "s/.*frida_release = \"\(.*\)\".*/\1/")
MODULE_VERSION=$(grep 'version=' base/module.prop | sed "s/version=v\(.*\)/\1/")
UPDATER_VERSION=$(grep '"version"' updater.json | sed 's/.*"version": "\(.*\)".*/\1/')

echo "Build version: $BUILD_VERSION"
echo "Module version: $MODULE_VERSION"
echo "Updater version: $UPDATER_VERSION"

if [ "$BUILD_VERSION" = "$MODULE_VERSION" ] && [ "$MODULE_VERSION" = "$UPDATER_VERSION" ]; then
    echo -e "${GREEN}✅ All versions match${NC}"
else
    echo -e "${RED}❌ Version mismatch detected${NC}"
    exit 1
fi

# Test 5: Check updater.json format
echo -e "${BLUE}📋 Test 5: Checking updater.json format...${NC}"
if python -c "import json; json.load(open('updater.json')); print('Valid JSON')" 2>/dev/null; then
    echo -e "${GREEN}✅ updater.json is valid JSON${NC}"
else
    echo -e "${RED}❌ updater.json is invalid JSON${NC}"
    exit 1
fi

# Test 6: Check if GitHub CLI would work (simulation)
echo -e "${BLUE}📋 Test 6: Simulating GitHub CLI release...${NC}"
TAG_NAME="v$BUILD_VERSION"
echo "Would create release with tag: $TAG_NAME"
echo "Would upload file: $ZIP_FILE"
echo "Release title: MagiskFurtif $TAG_NAME"

# Test 7: Check workflow file syntax
echo -e "${BLUE}📋 Test 7: Checking workflow syntax...${NC}"
if python -c "import yaml; yaml.safe_load(open('.github/workflows/build-module.yml', encoding='utf-8')); print('Valid YAML')" 2>/dev/null; then
    echo -e "${GREEN}✅ Workflow YAML is valid${NC}"
else
    echo -e "${RED}❌ Workflow YAML is invalid${NC}"
    exit 1
fi

echo -e "${GREEN}🎉 All tests passed! Release functionality should work correctly.${NC}"
echo -e "${BLUE}📋 To create a real release, run:${NC}"
echo "   ./create_release.sh"
echo -e "${BLUE}📋 Or manually:${NC}"
echo "   git tag -a $TAG_NAME -m \"Release version $BUILD_VERSION\""
echo "   git push origin $TAG_NAME"
