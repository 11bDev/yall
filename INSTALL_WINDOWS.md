# Yall v1.0.6 Windows Installation Guide

## Quick Install (Recommended)

1. **Download** the latest release:
   - Go to: https://github.com/PlebOne/yall/releases/tag/v1.0.6
   - Download: `yall-1.0.6-windows-x64.zip` (15.3 MB)

2. **Extract** the zip file to any folder (e.g., `C:\Apps\Yall\`)

3. **Install** by running the installer:
   - Right-click `install-windows.bat` 
   - Select "Run as administrator" (recommended)
   - Follow the prompts

4. **Launch** from Start Menu or Desktop shortcut

## Manual Install (Portable)

1. **Download and extract** as above
2. **Run** `yall.exe` directly from the extracted folder
3. **Optional**: Create shortcuts manually

## What Gets Installed

- **Application**: Yall executable and dependencies
- **Start Menu**: "Yall" shortcut 
- **Desktop**: Yall shortcut
- **Location**: `%LOCALAPPDATA%\Yall\` (e.g., `C:\Users\YourName\AppData\Local\Yall\`)

## System Requirements

- **OS**: Windows 10 or Windows 11 (64-bit)
- **RAM**: 512 MB minimum, 1 GB recommended
- **Disk**: 50 MB free space
- **Network**: Internet connection for social media posting

## Features

- **Mastodon**: OAuth login support
- **Nostr**: Local keys, remote signers, NIP-46 bunker support  
- **Bluesky**: App password authentication
- **Multi-posting**: Send to multiple platforms simultaneously
- **System Tray**: Minimize to tray, quick access
- **Themes**: Light and dark mode support

## Uninstall

### If installed via installer:
- Delete the installation folder: `%LOCALAPPDATA%\Yall\`
- Delete shortcuts from Start Menu and Desktop

### If running portable:
- Simply delete the extracted folder

## Troubleshooting

**App won't start:**
- Ensure you have the latest Windows updates
- Try running as administrator
- Check Windows Defender/antivirus isn't blocking it

**Can't connect to platforms:**
- Check your internet connection
- Verify your account credentials
- Check platform-specific requirements

**Window too small/large:**
- Default size is now 760x575 pixels
- Resize manually and the app will remember your preference
- Minimum: 600x500, Maximum: 1200x800

## Support

- **Issues**: https://github.com/PlebOne/yall/issues
- **Discussions**: https://github.com/PlebOne/yall/discussions
- **Documentation**: https://github.com/PlebOne/yall/blob/main/README.md
