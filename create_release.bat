@echo off
REM MagiskFurtif Release Creation Script for Windows
REM This script helps create a new release by creating and pushing a git tag

setlocal enabledelayedexpansion

echo 🚀 MagiskFurtif Release Creation Script
echo ==========================================

REM Check if we're in a git repository
git rev-parse --git-dir >nul 2>&1
if errorlevel 1 (
    echo ❌ Error: Not in a git repository
    exit /b 1
)

REM Check if there are uncommitted changes
git diff-index --quiet HEAD --
if errorlevel 1 (
    echo ⚠️  Warning: You have uncommitted changes
    echo Please commit or stash your changes before creating a release.
    set /p continue="Do you want to continue anyway? (y/N): "
    if /i not "!continue!"=="y" (
        echo ❌ Release creation cancelled
        exit /b 1
    )
)

REM Get current version from build.py
for /f "tokens=2 delims= " %%a in ('findstr "frida_release = " build.py') do set CURRENT_VERSION=%%a
set CURRENT_VERSION=!CURRENT_VERSION:"=!
echo 📋 Current version: !CURRENT_VERSION!

REM Ask for new version
set /p NEW_VERSION="📝 Enter new version (e.g., 3.3): "

if "!NEW_VERSION!"=="" (
    echo ❌ Error: Version cannot be empty
    exit /b 1
)

REM Create tag name
set TAG_NAME=v!NEW_VERSION!
echo 🏷️  Tag name: !TAG_NAME!

REM Check if tag already exists
git tag -l | findstr /x "!TAG_NAME!" >nul
if not errorlevel 1 (
    echo ❌ Error: Tag !TAG_NAME! already exists
    exit /b 1
)

REM Confirm release creation
echo 📋 Release Summary:
echo   Current version: !CURRENT_VERSION!
echo   New version: !NEW_VERSION!
echo   Tag: !TAG_NAME!
echo   Repository: 
git remote get-url origin
echo.
set /p confirm="Do you want to create this release? (y/N): "

if /i not "!confirm!"=="y" (
    echo ❌ Release creation cancelled
    exit /b 1
)

REM Update version in build.py
echo 📝 Updating version in build.py...
powershell -Command "(Get-Content build.py) -replace 'frida_release = \"!CURRENT_VERSION!\"', 'frida_release = \"!NEW_VERSION!\"' | Set-Content build.py"

REM Update version in updater.json
echo 📝 Updating version in updater.json...
set VERSION_CODE=!NEW_VERSION:.=!
echo {> updater.json
echo     "version": "!NEW_VERSION!",>> updater.json
echo     "versionCode": !VERSION_CODE!,>> updater.json
echo     "zipUrl": "https://github.com/%%REPO%%/releases/download/!TAG_NAME!/MagiskFurtif-f3ger-!NEW_VERSION!.zip">> updater.json
echo }>> updater.json

REM Update version in module.prop
echo 📝 Updating version in module.prop...
powershell -Command "(Get-Content base/module.prop) -replace 'version=v!CURRENT_VERSION!', 'version=v!NEW_VERSION!' | Set-Content base/module.prop"
powershell -Command "(Get-Content base/module.prop) -replace 'versionCode=!CURRENT_VERSION:.=!', 'versionCode=!VERSION_CODE!' | Set-Content base/module.prop"

REM Commit changes
echo 💾 Committing version changes...
git add build.py updater.json base/module.prop
git commit -m "Bump version to !NEW_VERSION!"

REM Create and push tag
echo 🏷️  Creating tag !TAG_NAME!...
git tag -a "!TAG_NAME!" -m "Release version !NEW_VERSION!

## Changes in version !NEW_VERSION!
- Enhanced monitoring service
- Improved Discord notifications
- Better error handling
- Updated workflow files"

echo 📤 Pushing changes and tag...
git push origin main
git push origin "!TAG_NAME!"

echo ✅ Release !TAG_NAME! created successfully!
echo 🔗 GitHub Actions will now build and create the release automatically
echo 📋 You can monitor the progress at:
git remote get-url origin
echo /actions
