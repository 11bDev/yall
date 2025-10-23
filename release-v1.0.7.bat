@echo off
REM Automated release script for Yall v1.0.7 - Android APK Support
REM This script will build the APK, commit changes, create a tag, and push to GitHub

echo ============================================
echo Yall v1.0.7 Release Automation Script
echo ============================================
echo.

echo [1/6] Getting Flutter dependencies...
call flutter pub get
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: Failed to get dependencies
    pause
    exit /b 1
)
echo.

echo [2/6] Building Android APK (Release)...
echo This may take a few minutes...
call flutter build apk --release
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: Failed to build APK
    pause
    exit /b 1
)
echo.
echo APK built successfully at: build\app\outputs\flutter-apk\app-release.apk
echo.

echo [3/6] Staging all changes for commit...
git add .
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: Failed to stage changes
    pause
    exit /b 1
)
echo.

echo [4/6] Committing changes...
git commit -m "Release v1.0.7 - Android APK support"
if %ERRORLEVEL% NEQ 0 (
    echo WARNING: Commit failed - possibly no changes to commit
    echo Continuing anyway...
)
echo.

echo [5/6] Pushing to GitHub (main branch)...
git push origin main
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: Failed to push to GitHub
    echo Please check your Git credentials and network connection
    pause
    exit /b 1
)
echo.

echo [6/6] Creating and pushing Git tag v1.0.7...
git tag v1.0.7
git push origin v1.0.7
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: Failed to push tag
    echo The tag may already exist. Delete it with: git tag -d v1.0.7
    pause
    exit /b 1
)
echo.

echo [7/7] Creating GitHub Release with APK...
echo Checking if APK exists...
if not exist "build\app\outputs\flutter-apk\app-release.apk" (
    echo ERROR: APK not found at build\app\outputs\flutter-apk\app-release.apk
    pause
    exit /b 1
)
echo.
echo Creating release on GitHub...
gh release create v1.0.7 ^
    --title "Release v1.0.7 - Android APK Support" ^
    --notes-file RELEASE_NOTES_1.0.7.md ^
    build\app\outputs\flutter-apk\app-release.apk#yall-v1.0.7.apk

if %ERRORLEVEL% NEQ 0 (
    echo ERROR: Failed to create GitHub release
    echo Make sure you have GitHub CLI (gh) installed and authenticated
    echo Run: gh auth login
    pause
    exit /b 1
)
echo.

echo ============================================
echo SUCCESS! Release v1.0.7 published!
echo ============================================
echo.
echo Release created at: https://github.com/timappledotcom/yall/releases/tag/v1.0.7
echo APK uploaded as: yall-v1.0.7.apk
echo.
echo Users can now download and install the Android APK!
echo.
pause

