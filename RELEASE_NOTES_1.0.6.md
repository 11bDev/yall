# Yall v1.0.6 Release Notes

## 🎯 New Features & Improvements

### Window Management
- **Updated Default Window Size**: Changed from 900x650 to 760x575 pixels for better desktop fit
- **Fixed Dialog Overflow Issues**: Added height constraints to prevent dialog content overflow
- **Improved UI Responsiveness**: Enhanced layout handling for various window sizes

### OAuth & Account Management  
- **Enhanced Nostr Support**: Added support for remote signers and NIP-46 bunker protocol
- **Improved OAuth Flow**: Fixed Mastodon OAuth dialog closure and removed non-functional Bluesky OAuth
- **Better Validation**: Enhanced credential validation for all supported platforms

### User Interface
- **Overflow Prevention**: Fixed horizontal and vertical overflow issues in multi-platform selector
- **Better Dialog Sizing**: Implemented scrollable dialogs with proper height constraints
- **Enhanced Account Selection**: Improved signer type selection for Nostr accounts

## 🐛 Bug Fixes

- Fixed platform selector overflow when platform names were too long
- Resolved dialog height issues that caused content to be cut off
- Improved window state management for better user experience
- Fixed text overflow in various UI components

## 📦 What's Included

### Windows Release Package
- **Executable**: `yall.exe` - Ready to run Windows application  
- **Installer**: `install-windows.bat` - Automated installation script
- **Documentation**: README.md and LICENSE files
- **Dependencies**: All required DLL files included

### Installation Options
1. **Quick Install**: Run `install-windows.bat` for automatic setup
2. **Manual Install**: Extract files and run `yall.exe` directly
3. **Portable**: No installation required, runs from any folder

## 🚀 Getting Started

1. Download `yall-1.0.6-windows-x64.zip`
2. Extract the archive to your desired location
3. Run `install-windows.bat` for system-wide installation, or
4. Run `yall.exe` directly for portable usage

## 🔧 Technical Details

- **Default Window Size**: 760x575 pixels
- **Minimum Size**: 600x500 pixels  
- **Maximum Size**: 1200x800 pixels
- **Platform Support**: Windows 10/11 (x64)
- **Dependencies**: .NET Framework (included)

## 📋 Platform Support

- ✅ **Mastodon**: Full OAuth support with proper dialog handling
- ✅ **Nostr**: Local keys, remote signers, and NIP-46 bunker support  
- ✅ **Bluesky**: Manual app password authentication
- ❌ **X/Twitter**: Not supported (API limitations)

## 🆕 Since v1.0.5

- New compact 760x575 default window size
- Enhanced Nostr signer type selection
- Fixed OAuth dialog behavior
- Improved overflow handling
- Better window state management
- Added Windows build automation scripts

---

**Full Changelog**: https://github.com/PlebOne/yall/compare/v1.0.5...v1.0.6
