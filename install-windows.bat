@echo off
REM Yall Installation Script for Windows

echo.
echo ===========================================
echo  Installing Yall - Multi-Platform Poster
echo ===========================================
echo.

REM Check if build exists
if not exist "build\windows\x64\runner\Release\yall.exe" (
    echo ERROR: Windows build not found. Please run 'flutter build windows' first
    pause
    exit /b 1
)

REM Create installation directory
set INSTALL_DIR=%LOCALAPPDATA%\Yall
echo Creating installation directory: %INSTALL_DIR%
if not exist "%INSTALL_DIR%" mkdir "%INSTALL_DIR%"

REM Copy files
echo Copying application files...
xcopy "build\windows\x64\runner\Release\*" "%INSTALL_DIR%\" /E /I /Y > nul

REM Create Start Menu shortcut
echo Creating Start Menu shortcut...
set SHORTCUT_PATH=%APPDATA%\Microsoft\Windows\Start Menu\Programs\Yall.lnk
powershell -Command "$WshShell = New-Object -comObject WScript.Shell; $Shortcut = $WshShell.CreateShortcut('%SHORTCUT_PATH%'); $Shortcut.TargetPath = '%INSTALL_DIR%\yall.exe'; $Shortcut.WorkingDirectory = '%INSTALL_DIR%'; $Shortcut.Description = 'Message to Nostr, Bluesky, and Mastodon from one place'; $Shortcut.Save()"

REM Create Desktop shortcut
echo Creating Desktop shortcut...
set DESKTOP_SHORTCUT=%USERPROFILE%\Desktop\Yall.lnk
powershell -Command "$WshShell = New-Object -comObject WScript.Shell; $Shortcut = $WshShell.CreateShortcut('%DESKTOP_SHORTCUT%'); $Shortcut.TargetPath = '%INSTALL_DIR%\yall.exe'; $Shortcut.WorkingDirectory = '%INSTALL_DIR%'; $Shortcut.Description = 'Message to Nostr, Bluesky, and Mastodon from one place'; $Shortcut.Save()"

echo.
echo ========================================
echo  Installation Complete!
echo ========================================
echo.
echo Yall has been installed to: %INSTALL_DIR%
echo.
echo You can now:
echo • Find 'Yall' in your Start Menu
echo • Use the Desktop shortcut
echo • Pin it to your Taskbar
echo.
echo To uninstall, simply delete:
echo • %INSTALL_DIR%
echo • %SHORTCUT_PATH%
echo • %DESKTOP_SHORTCUT%
echo.
pause
