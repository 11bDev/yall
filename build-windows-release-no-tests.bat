@echo off
REM YaLL Windows Release Build Script (No Tests)
REM Builds Windows release package without running tests

setlocal

set VERSION=%1
if "%VERSION%"=="" (
    echo Usage: %0 ^<version^>
    echo Example: %0 1.0.6
    exit /b 1
)

echo Building YaLL Windows version %VERSION%...

REM Clean previous builds
echo Cleaning previous builds...
call flutter clean
call flutter pub get

REM Build for Windows
echo Building Windows application...
call flutter build windows --release
if %errorlevel% neq 0 (
    echo Windows build failed!
    exit /b 1
)

REM Create release directory
set RELEASE_DIR=releases\v%VERSION%
if not exist "%RELEASE_DIR%" mkdir "%RELEASE_DIR%"

REM Copy built application
echo Creating release package...
set RELEASE_NAME=yall-%VERSION%-windows-x64
if exist "%RELEASE_DIR%\%RELEASE_NAME%" rmdir /s /q "%RELEASE_DIR%\%RELEASE_NAME%"
xcopy "build\windows\x64\runner\Release" "%RELEASE_DIR%\%RELEASE_NAME%\" /E /I /Y

REM Copy additional files
copy "README.md" "%RELEASE_DIR%\%RELEASE_NAME%\" > nul
copy "LICENSE" "%RELEASE_DIR%\%RELEASE_NAME%\" > nul
copy "install-windows.bat" "%RELEASE_DIR%\%RELEASE_NAME%\" > nul

REM Create zip archive
echo Creating zip archive...
cd "%RELEASE_DIR%"
powershell -Command "Compress-Archive -Path '%RELEASE_NAME%' -DestinationPath '%RELEASE_NAME%.zip' -Force"
cd ..\..

echo.
echo ========================================
echo  Release %VERSION% built successfully!
echo ========================================
echo Location: %RELEASE_DIR%
echo Archive: %RELEASE_DIR%\%RELEASE_NAME%.zip
echo.
echo Ready for distribution!
